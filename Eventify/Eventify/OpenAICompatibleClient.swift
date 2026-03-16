//
//  OpenAICompatibleClient.swift
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

final class OpenAICompatibleClient: AIClient {
    
    // MARK: - Properties
    // TODO: Replace with your real API Key, request URL, and model name (Supports any OpenAI compatible format)
    private let apiKey = "YOUR_API_KEY_HERE"
    private let baseURL = "https://api.openai.com/v1" // e.g. https://api.openai.com/v1 or your proxy address
    private let model = "gpt-3.5-turbo" // e.g. gpt-4o, gpt-3.5-turbo, or other open-source model names
    
    // MARK: - AIClient Protocol
    
    func extractEvents(fromText text: String, now: Date, localeIdentifier: String) async throws -> ParsedEventsResponse {
        print("🤖 AI parsing started, input text: \(text)")
        
        let prompt = createPrompt(for: text, now: now)
        print("🤖 Generated prompt: \(prompt)")
        
        do {
            let response = try await sendRequest(prompt: prompt)
            print("🤖 AI Raw Response: \(response)")
            
            let result = parseAIResponse(response)
            print("🤖 Parsing Result: \(result.events.count) events")
            
            return result
        } catch {
            print("🤖 AI Parsing Failed: \(error)")
            throw AIClientError.networkError(error)
        }
    }
    
    func extractEvents(fromImage imageData: Data, now: Date, localeIdentifier: String) async throws -> ParsedEventsResponse {
        // AI model might not support images, verify your provider
        throw AIClientError.apiError("Image recognition not supported by this AI model")
    }
    
    // MARK: - Private Methods
    
    private func createPrompt(for text: String, now: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let currentDate = dateFormatter.string(from: now)
        
        let isChinese = Locale.current.language.languageCode?.identifier == "zh"
        
        let instructions = isChinese ? """
        请分析以下文本，提取其中的时间安排和事件信息，并以JSON格式返回。
        当前日期：\(currentDate)
        """ : """
        Analyze the following text to extract schedules and event information. Return the results in JSON format.
        Current Date: \(currentDate)
        """
        
        let formatInstructions = isChinese ? """
        请按照以下JSON格式返回结果：
        {
            "events": [
                {
                    "title": "事件标题",
                    "startDate": "2024-01-15T14:00:00",
                    "endDate": "2024-01-15T16:00:00",
                    "location": "地点（可选）",
                    "notes": "备注（可选）",
                    "isAllDay": false
                }
            ]
        }
        """ : """
        Please return the results in the following JSON format:
        {
            "events": [
                {
                    "title": "Event Title",
                    "startDate": "2024-01-15T14:00:00",
                    "endDate": "2024-01-15T16:00:00",
                    "location": "Location (Optional)",
                    "notes": "Notes (Optional)",
                    "isAllDay": false
                }
            ]
        }
        """
        
        let rules = isChinese ? """
        规则：
        1. 如果文本中没有明确的时间信息，请根据上下文推断合理的时间
        2. 如果没有结束时间，请根据事件类型推断合理的持续时间
        3. 时间格式使用ISO 8601标准
        4. 如果无法提取任何事件，返回空的events数组
        5. 只返回JSON，不要包含其他文字说明
        """ : """
        Rules:
        1. If no specific time information is present, infer a reasonable time from context.
        2. If no end time is provided, infer a reasonable duration based on the event type.
        3. Use ISO 8601 standard for time formats.
        4. If no events can be extracted, return an empty "events" array.
        5. Return ONLY JSON, no other text or explanation.
        """
        
        return """
        \(instructions)
        
        \(isChinese ? "输入文本：" : "Input Text:")
        \(text)
        
        \(formatInstructions)
        
        \(rules)
        
        \(isChinese ? "请开始分析：" : "Start Analysis:")
        """
    }
    
    private func sendRequest(prompt: String) async throws -> String {
        print("🌐 Sending API request to: \(baseURL)/chat/completions")
        
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AIClientError.apiError("Invalid API URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.1,
            "max_tokens": 2000
        ]
        
        print("🌐 Request body: \(requestBody)")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print("🌐 Response status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        print("🌐 Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIClientError.apiError("API request failed")
        }
        
        let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = jsonResponse?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIClientError.invalidResponse
        }
        
        return content
    }
    
    private func parseAIResponse(_ response: String) -> ParsedEventsResponse {
        print("🔍 Starting to parse AI response: \(response)")
        
        // Clean response text, extract JSON part
        let cleanedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try to find JSON part
        let jsonStart = cleanedResponse.range(of: "{")
        let jsonEnd = cleanedResponse.range(of: "}", options: .backwards)
        
        guard let start = jsonStart?.lowerBound,
              let end = jsonEnd?.upperBound else {
            print("❌ JSON format not found")
            return ParsedEventsResponse(
                events: [],
                warnings: ["AI response format error, unable to parse"]
            )
        }
        
        let jsonString = String(cleanedResponse[start..<end])
        print("🔍 Extracted JSON: \(jsonString)")
        
        do {
            guard let jsonData = jsonString.data(using: .utf8) else {
                throw AIClientError.invalidResponse
            }
            
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
            guard let eventsArray = jsonObject?["events"] as? [[String: Any]] else {
                print("❌ No events array found in JSON")
                return ParsedEventsResponse(events: [], warnings: ["No event data found in AI response"])
            }
            
            print("🔍 Found \(eventsArray.count) events")
            
            var events: [EventCandidate] = []
            
            for (index, eventDict) in eventsArray.enumerated() {
                print("🔍 Parsing event \(index + 1): \(eventDict)")
                if let event = parseEventFromDict(eventDict) {
                    events.append(event)
                    print("✅ Event \(index + 1) parsed successfully")
                } else {
                    print("❌ Event \(index + 1) parsing failed")
                }
            }
            
            print("🔍 Finally parsed \(events.count) valid events")
            return ParsedEventsResponse(events: events, warnings: nil)
            
        } catch {
            print("❌ JSON parsing failed: \(error)")
            return ParsedEventsResponse(
                events: [],
                warnings: ["AI response parsing failed: \(error.localizedDescription)"]
            )
        }
    }
    
    private func parseEventFromDict(_ dict: [String: Any]) -> EventCandidate? {
        print("🔍 Parsing event dictionary: \(dict)")
        
        guard let title = dict["title"] as? String,
              let startDateString = dict["startDate"] as? String else {
            print("❌ Missing required fields: title or startDate")
            return nil
        }
        
        // Use flexible date parser
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        
        guard let startDate = dateFormatter.date(from: startDateString) else {
            print("❌ Unable to parse start date: \(startDateString)")
            return nil
        }
        
        var endDate: Date?
        if let endDateString = dict["endDate"] as? String {
            endDate = dateFormatter.date(from: endDateString)
            if endDate == nil {
                print("❌ Unable to parse end date: \(endDateString)")
            }
        }
        
        let location = dict["location"] as? String
        let notes = dict["notes"] as? String
        let isAllDay = dict["isAllDay"] as? Bool ?? false
        
        let event = EventCandidate(
            title: title,
            notes: notes,
            location: location,
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay
        )
        
        print("✅ Successfully created event: \(title) at \(startDate)")
        return event
    }
}
