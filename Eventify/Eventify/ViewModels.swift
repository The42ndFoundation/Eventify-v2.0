//
//  ViewModels.swift
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
import SwiftUI
import PhotosUI
import Combine
import EventKit

// MARK: - Event Parsing ViewModel
@MainActor
final class EventParsingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var inputText: String = ""
    @Published var selectedImage: UIImage?
    @Published var photoItem: PhotosPickerItem?
    @Published var isLoading: Bool = false
    @Published var parsedResponse: ParsedEventsResponse?
    @Published var errorMessage: String?
    @Published var showingConfirmView: Bool = false
    
    // MARK: - Private Properties
    private let aiClient: AIClient
    
    // MARK: - Initialization
    init(aiClient: AIClient) {
        self.aiClient = aiClient
    }
    
    // MARK: - Public Methods
    
    /// Start parsing events
    func parseEvents() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        do {
            let textToParse = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // If there's an image but no text, use image parsing
            if textToParse.isEmpty, let image = selectedImage {
                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                    errorMessage = L10n.Error.imageProcessing
                    return
                }
                parsedResponse = try await aiClient.extractEvents(
                    fromImage: imageData,
                    now: Date(),
                    localeIdentifier: Locale.current.identifier
                )
            }
            // If there's text, use text parsing
            else if !textToParse.isEmpty {
                parsedResponse = try await aiClient.extractEvents(
                    fromText: textToParse,
                    now: Date(),
                    localeIdentifier: Locale.current.identifier
                )
            }
            // If none, show error
            else {
                errorMessage = L10n.Error.noInput
                return
            }
            
            // Check parsing result
            if let response = parsedResponse {
                if response.events.isEmpty {
                    // Show the first warning (e.g. AI error) if available, otherwise generic error
                    if let firstWarning = response.warnings?.first {
                        errorMessage = firstWarning
                    } else {
                        errorMessage = L10n.Error.noEvents
                    }
                } else {
                    showingConfirmView = true
                }
            }
            
        } catch {
            errorMessage = L10n.Error.parseFailed(error.localizedDescription)
        }
    }
    
    /// Clear all input
    func clearInput() {
        inputText = ""
        selectedImage = nil
        photoItem = nil
        parsedResponse = nil
        errorMessage = nil
    }
    
    /// Handle image selection
    func handleImageSelection() {
        Task {
            if let item = photoItem {
                do {
                    if let data = try await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                } catch {
                    errorMessage = L10n.Error.loadImageFailed(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Calendar Write ViewModel
@MainActor
final class CalendarWriteViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var writeResultMessage: String?
    @Published var isWriting: Bool = false
    @Published var showingResult: Bool = false
    
    // MARK: - Private Properties
    private let calendarService = CalendarService()
    
    // MARK: - Public Methods
    
    /// Write events to calendar
    func writeEvents(_ events: [EventCandidate], to calendar: EKCalendar? = nil) async -> Bool {
        guard !isWriting else { return false }
        
        isWriting = true
        writeResultMessage = nil
        
        defer {
            isWriting = false
        }
        
        do {
            // Request permission
            try await calendarService.requestAccessIfNeeded()
            
            // Write events
            try calendarService.add(events: events, to: calendar)
            
            // Success message
            let count = events.count
            writeResultMessage = L10n.Calendar.success(count)
            showingResult = true
            return true
            
        } catch {
            writeResultMessage = L10n.Calendar.failed(error.localizedDescription)
            showingResult = true
            return false
        }
    }
    
    /// Write a single event to calendar
    func writeEvent(_ event: EventCandidate, to calendar: EKCalendar? = nil) async -> Bool {
        return await writeEvents([event], to: calendar)
    }
    
    /// Check calendar permission status
    var permissionStatus: EKAuthorizationStatus {
        return calendarService.authorizationStatus
    }
    
    /// Whether app has calendar permission
    var hasPermission: Bool {
        return calendarService.hasPermission
    }
}

// MARK: - Confirm Events ViewModel
@MainActor
final class ConfirmEventsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var events: [EventCandidate]
    @Published var warnings: [String]
    @Published var isReparsing: Bool = false
    
    // MARK: - Private Properties
    private let calendarWriteVM = CalendarWriteViewModel()
    let originalText: String
    
    // MARK: - Initialization
    init(parsedResponse: ParsedEventsResponse, originalText: String = "") {
        self.events = parsedResponse.events
        self.warnings = parsedResponse.warnings ?? []
        self.originalText = originalText
    }
    
    // MARK: - Public Methods
    
    /// Delete event
    func deleteEvent(at indexSet: IndexSet) {
        events.remove(atOffsets: indexSet)
    }
    
    /// Add new event
    func addNewEvent() {
        let newEvent = EventCandidate(
            title: L10n.Event.newEvent,
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600)
        )
        events.append(newEvent)
    }
    
    /// Save to calendar
    func saveToCalendar() async -> Bool {
        return await calendarWriteVM.writeEvents(events)
    }
    
    /// Get write result message
    var writeResult: String? {
        return calendarWriteVM.writeResultMessage
    }
    
    /// Whether writing is in progress
    var isWriting: Bool {
        return calendarWriteVM.isWriting
    }
    
    /// Whether to show result alert
    var showingResult: Bool {
        return calendarWriteVM.showingResult
    }
    
    /// Dismiss result alert
    func dismissResult() {
        calendarWriteVM.showingResult = false
        calendarWriteVM.writeResultMessage = nil
    }
    
    /// AI Re-parse
    func aiReparse() async {
        guard !originalText.isEmpty, !isReparsing else { return }
        
        isReparsing = true
        defer { isReparsing = false }
        
        do {
            let aiClient = OpenAICompatibleClient()
            let response = try await aiClient.extractEvents(
                fromText: originalText,
                now: Date(),
                localeIdentifier: Locale.current.identifier
            )
            
            if !response.events.isEmpty {
                self.events = response.events
                self.warnings = response.warnings ?? []
            } else {
                self.warnings = [L10n.Confirm.aiNoEvents]
            }
        } catch {
            self.warnings = [L10n.Confirm.aiReparseFailed(error.localizedDescription)]
        }
    }
}

// MARK: - Binding Extensions for Optional Strings
extension Binding where Value == String {
    init(_ source: Binding<String?>, default defaultValue: String) {
        self.init(
            get: { source.wrappedValue ?? defaultValue },
            set: { source.wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }
}
