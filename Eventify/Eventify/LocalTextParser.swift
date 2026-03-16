//
//  LocalTextParser.swift
//  Eventify
//
//  Copyright © 2026 The42nd Foundation. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//

import Foundation
import UIKit

// MARK: - Local Text Parser
final class LocalTextParser: AIClient {
    
    // MARK: - Properties
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    // MARK: - Day Mapping
    private let dayMap: [String: Int] = [
        "Su": 0, "Mo": 1, "Tu": 2, "We": 3, "Th": 4, "Fr": 5, "Sa": 6,
        "Sun": 0, "Mon": 1, "Tue": 2, "Wed": 3, "Thu": 4, "Fri": 5, "Sat": 6,
        "周日": 0, "周一": 1, "周二": 2, "周三": 3, "周四": 4, "周五": 5, "周六": 6,
        "星期日": 0, "星期一": 1, "星期二": 2, "星期三": 3, "星期四": 4, "星期五": 5, "星期六": 6
    ]
    
    // MARK: - AIClient Implementation
    func extractEvents(fromText text: String, now: Date, localeIdentifier: String) async throws -> ParsedEventsResponse {
        print("🔍 Starting text parsing: \(text)")
        
        // 1. Attempt local structured parsing first (Rigid format)
        print("🔍 Attempting local structured parsing...")
        var allEvents = parseStructuredTimetable(text: text)
        
        // 2. Attempt simple single-line parsing (Flexible format)
        if allEvents.isEmpty {
            print("🔍 Attempting simple single-line parsing...")
            allEvents = parseSimpleSingleLineEvent(text: text)
        }
        
        if !allEvents.isEmpty {
            print("✅ Local parsing successful, found \(allEvents.count) events")
            return ParsedEventsResponse(events: allEvents, warnings: nil)
        }
        
        // 2. Direct fallback to AI for natural language
        print("🤖 No structured format detected, falling back to AI parsing...")
        return try await forceAIParsing(text: text, now: now, localeIdentifier: localeIdentifier)
    }
    
    private func forceAIParsing(text: String, now: Date, localeIdentifier: String) async throws -> ParsedEventsResponse {
        do {
            let aiClient = OpenAICompatibleClient()
            let aiResponse = try await aiClient.extractEvents(fromText: text, now: now, localeIdentifier: localeIdentifier)
            
            if !aiResponse.events.isEmpty {
                print("✅ AI parsing successful, found \(aiResponse.events.count) events")
                return aiResponse
            } else {
                print("❌ AI parsing returned empty result")
                return ParsedEventsResponse(
                    events: [],
                    warnings: [L10n.Confirm.aiNoEvents]
                )
            }
        } catch {
            print("❌ AI parsing failed: \(error)")
            return ParsedEventsResponse(
                events: [],
                warnings: [L10n.Confirm.aiReparseFailed(error.localizedDescription)]
            )
        }
    }
    
    func extractEvents(fromImage imageData: Data, now: Date, localeIdentifier: String) async throws -> ParsedEventsResponse {
        // Image parsing not supported in local version
        return ParsedEventsResponse(
            events: [],
            warnings: ["Image recognition not supported in local version, please use text description"]
        )
    }
    
    private func parseSimpleSingleLineEvent(text: String) -> [EventCandidate] {
        var events: [EventCandidate] = []
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            
            // Regex for: [Title] [Date] [Start]-[End]
            // Example: meeting with A 3.18 2:00-4:00
            // Group 1: Title, Group 2: month, Group 3: day, Group 4: Start, Group 5: End
            let pattern = """
            (?xi)
            ^(.*?)\\s+                                      # Title
            (\\d{1,2})[/\\.](\\d{1,2})\\s*                   # Date (M.D or M/D)
            (?:\\s+)?                                       # Optional space
            (\\d{1,2}:\\d{2}\\s*(?:AM|PM)?)\\s*[\\-–—~至]\\s* # Start Time
            (\\d{1,2}:\\d{2}\\s*(?:AM|PM)?)                  # End Time
            """
            
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { continue }
            let nsLine = trimmed as NSString
            if let match = regex.firstMatch(in: trimmed, range: NSRange(location: 0, length: nsLine.length)) {
                let title = nsLine.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespaces)
                let monthStr = nsLine.substring(with: match.range(at: 2))
                let dayStr = nsLine.substring(with: match.range(at: 3))
                let startTimeStr = nsLine.substring(with: match.range(at: 4))
                let endTimeStr = nsLine.substring(with: match.range(at: 5))
                
                // Construct Date
                let calendar = Calendar.current
                var components = calendar.dateComponents([.year], from: Date()) // Use current year
                components.month = Int(monthStr)
                components.day = Int(dayStr)
                
                guard let baseDate = calendar.date(from: components),
                      let startTime = convertTo24Hour(timeStr: startTimeStr),
                      let endTime = convertTo24Hour(timeStr: endTimeStr) else { continue }
                
                var startComps = calendar.dateComponents([.year, .month, .day], from: baseDate)
                startComps.hour = startTime.hour
                startComps.minute = startTime.minute
                
                var endComps = calendar.dateComponents([.year, .month, .day], from: baseDate)
                endComps.hour = endTime.hour
                endComps.minute = endTime.minute
                
                if let startDate = calendar.date(from: startComps),
                   let endDate = calendar.date(from: endComps) {
                    events.append(EventCandidate(
                        title: title,
                        location: nil,
                        startDate: startDate,
                        endDate: endDate,
                        isAllDay: false
                    ))
                }
            }
        }
        
        return events
    }
    
    // MARK: - Structured Timetable Parsing
    private func parseStructuredTimetable(text: String) -> [EventCandidate] {
        var events: [EventCandidate] = []
        
        // Course Name
        // Mo 10:15AM-12:05PM
        // Room 101
        // 01/01/2024 - 15/05/2024
        
        // Match course code line: e.g. COMP 1234 - Programming (Flexible hyphen/spacing)
        let coursePattern = "(?m)^([A-Z]{2,4}\\s*\\d{3,4})\\s*[\\-–—~至]?.*$"
        
        // Split text into course blocks
        let courseBlocks = splitTextByPattern(text: text, pattern: coursePattern)
        
        for rawBlock in courseBlocks {
            let block = rawBlock.trimmingCharacters(in: .whitespacesAndNewlines)
            if block.isEmpty { continue }
            
            // Extract course code from the first line of the block
            let lines = block.components(separatedBy: .newlines)
            guard let firstLine = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) else { continue }
            
            let nsFirstLine = firstLine as NSString
            let codeRegex = try? NSRegularExpression(pattern: "^([A-Z]{2,4}\\s*\\d{3,4})", options: [])
            guard let codeMatch = codeRegex?.firstMatch(in: firstLine, range: NSRange(location: 0, length: nsFirstLine.length)) else {
                continue
            }
            
            let courseCode = nsFirstLine.substring(with: codeMatch.range(at: 1)).replacingOccurrences(of: " ", with: "")
            
            // Parse sessions using regex (Flexible for spacing, separators, and languages)
            // Group 1: Day(s), Group 2: StartTime, Group 3: EndTime, Group 4: Location/Notes block, Group 5: StartDate, Group 6: EndDate
            let sessionPattern = """
            (?xi)
            ([^\\d\\n\\r]+?)\\s+                              # Day (English or Chinese)
            (\\d{1,2}:\\d{2}\\s*(?:AM|PM)?)\\s*[\\-–—~至]\\s*    # StartTime
            (\\d{1,2}:\\d{2}\\s*(?:AM|PM)?)\\s*              # EndTime
            [\\r\\n]+                                        # Newline sequence
            ([\\s\\S]*?)                                      # Location block (multi-line)
            (\\d{1,2}[/\\-\\.]\\d{1,2}[/\\-\\.]\\d{2,4})       # StartDate (flexible separator/year)
            \\s*[\\-–—~至]\\s*                                 # Separator (with optional spaces)
            (\\d{1,2}[/\\-\\.]\\d{1,2}[/\\-\\.]\\d{2,4})       # EndDate
            """
            
            do {
                let regex = try NSRegularExpression(pattern: sessionPattern, options: [.anchorsMatchLines])
                let matches = regex.matches(in: block, range: NSRange(block.startIndex..., in: block))
                
                for match in matches {
                    guard match.numberOfRanges >= 7 else { continue }
                    
                    let nsBlock = block as NSString
                    let day = nsBlock.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespaces)
                    let startTimeStr = nsBlock.substring(with: match.range(at: 2))
                    let endTimeStr = nsBlock.substring(with: match.range(at: 3))
                    let locationText = nsBlock.substring(with: match.range(at: 4))
                    let startDateStr = nsBlock.substring(with: match.range(at: 5))
                    let endDateStr = nsBlock.substring(with: match.range(at: 6))
                    
                    // Parse location
                    let location = extractLocation(from: locationText)
                    
                    // Parse dates
                    guard let startDate = dateFormatter.date(from: startDateStr),
                          let endDate = dateFormatter.date(from: endDateStr) else {
                        continue
                    }
                    
                    // Convert times to 24-hour format
                    guard let startTime = convertTo24Hour(timeStr: startTimeStr),
                          let endTime = convertTo24Hour(timeStr: endTimeStr) else {
                        continue
                    }
                    
                    // Generate recurring events
                    let recurringEvents = generateRecurringEvents(
                        courseCode: courseCode,
                        day: day,
                        startTime: startTime,
                        endTime: endTime,
                        location: location,
                        startDate: startDate,
                        endDate: endDate
                    )
                    
                    events.append(contentsOf: recurringEvents)
                }
            } catch {
                print("Regex error: \(error)")
                continue
            }
        }
        
        return events
    }
    
    // MARK: - Helper Methods
    private func splitTextByPattern(text: String, pattern: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            
            var blocks: [String] = []
            var lastIndex = text.startIndex
            
            for match in matches {
                let matchRange = Range(match.range, in: text)!
                let block = String(text[lastIndex..<matchRange.lowerBound])
                if !block.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    blocks.append(block)
                }
                lastIndex = matchRange.lowerBound
            }
            
            // Add the last block
            let lastBlock = String(text[lastIndex...])
            if !lastBlock.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                blocks.append(lastBlock)
            }
            
            return blocks
        } catch {
            print("Pattern split error: \(error)")
            return [text]
        }
    }
    
    private func extractLocation(from text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty && trimmed.lowercased() != "staff" {
                return trimmed
            }
        }
        return L10n.Event.unknownLocation
    }
    
    private func convertTo24Hour(timeStr: String) -> (hour: Int, minute: Int)? {
        let cleaned = timeStr.trimmingCharacters(in: .whitespaces).uppercased()
        let pattern = "(\\d{1,2}):(\\d{2})\\s*(AM|PM)?"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let match = regex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned))
            
            guard let match = match,
                  match.numberOfRanges >= 3 else {
                return nil
            }
            
            let nsCleaned = cleaned as NSString
            let hourStr = nsCleaned.substring(with: match.range(at: 1))
            let minuteStr = nsCleaned.substring(with: match.range(at: 2))
            
            let hour = Int(hourStr) ?? 0
            let minute = Int(minuteStr) ?? 0
            
            var adjustedHour = hour
            
            let ampmRange = match.range(at: 3)
            if ampmRange.location != NSNotFound {
                let ampm = nsCleaned.substring(with: ampmRange).uppercased()
                if ampm == "PM" && hour != 12 {
                    adjustedHour = hour + 12
                } else if ampm == "AM" && hour == 12 {
                    adjustedHour = 0
                }
            }
            
            return (hour: adjustedHour, minute: minute)
        } catch {
            print("Time conversion error: \(error)")
            return nil
        }
    }
    
    private func generateRecurringEvents(
        courseCode: String,
        day: String,
        startTime: (hour: Int, minute: Int),
        endTime: (hour: Int, minute: Int),
        location: String,
        startDate: Date,
        endDate: Date
    ) -> [EventCandidate] {
        var events: [EventCandidate] = []
        
        // Find matching day index from dayMap
        var dayOfWeek: Int? = nil
        let trimmedDay = day.trimmingCharacters(in: .whitespaces)
        
        // Check for direct match or substring match (e.g. "Monday" matches "Mon")
        for (key, value) in dayMap {
            if trimmedDay.contains(key) || key.contains(trimmedDay) {
                dayOfWeek = value
                break
            }
        }
        
        guard let dayOfWeek = dayOfWeek else {
            print("⚠️ Could not map day: \(day)")
            return events
        }
        
        var currentDate = startDate
        let calendar = Calendar.current
        
        // Find first occurrence of the target day
        while calendar.component(.weekday, from: currentDate) - 1 != dayOfWeek {
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        // Generate events for each week
        while currentDate <= endDate {
            var startComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)
            startComponents.hour = startTime.hour
            startComponents.minute = startTime.minute
            startComponents.timeZone = TimeZone.current
            
            var endComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)
            endComponents.hour = endTime.hour
            endComponents.minute = endTime.minute
            endComponents.timeZone = TimeZone.current
            
            if let eventStartDate = calendar.date(from: startComponents),
               let eventEndDate = calendar.date(from: endComponents) {
                
                let event = EventCandidate(
                    title: courseCode,
                    location: location,
                    startDate: eventStartDate,
                    endDate: eventEndDate,
                    isAllDay: false
                )
                
                events.append(event)
            }
            
            // Move to next week
            currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
        }
        
        return events
    }
}

// MARK: - Convenience Extension
extension LocalTextParser {
    func extractEvents(fromImage image: UIImage, now: Date, localeIdentifier: String) async throws -> ParsedEventsResponse {
        // Convert UIImage to Data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw AIClientError.apiError(L10n.Error.imageProcessing)
        }
        
        return try await extractEvents(fromImage: imageData, now: now, localeIdentifier: localeIdentifier)
    }
}
