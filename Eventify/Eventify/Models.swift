//
//  Models.swift
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
import EventKit

/// Candidate event extracted from text or images
struct EventCandidate: Identifiable, Codable {
    let id: UUID
    var title: String
    var notes: String?
    var location: String?
    var startDate: Date
    var endDate: Date?
    var isAllDay: Bool

    init(id: UUID = UUID(),
         title: String,
         notes: String? = nil,
         location: String? = nil,
         startDate: Date,
         endDate: Date? = nil,
         isAllDay: Bool = false) {
        self.id = id
        self.title = title
        self.notes = notes
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
    }
}

/// Parsing result returned by the whole logic layer
struct ParsedEventsResponse: Codable {
    var events: [EventCandidate]
    var warnings: [String]?
}

/// Common interface for parsing logic (Local or AI)
protocol AIClient {
    func extractEvents(fromText text: String, now: Date, localeIdentifier: String) async throws -> ParsedEventsResponse
    func extractEvents(fromImage imageData: Data, now: Date, localeIdentifier: String) async throws -> ParsedEventsResponse
}

/// Errors related to calendar operations
enum CalendarError: Error, LocalizedError {
    case accessDenied
    case noCalendar
    case invalidDateRange
    case saveFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return L10n.Calendar.accessDenied
        case .noCalendar:
            return L10n.Calendar.noCalendar
        case .invalidDateRange:
            return L10n.Calendar.invalidDate
        case .saveFailed(let error):
            return L10n.Calendar.saveFailed(error.localizedDescription)
        }
    }
}

/// Errors related to AI client operations
enum AIClientError: Error, LocalizedError {
    case networkError(Error)
    case invalidResponse
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return L10n.Error.parseFailed(error.localizedDescription)
        case .invalidResponse:
            return L10n.Error.noEvents
        case .apiError(let message):
            return L10n.Error.parseFailed(message)
        }
    }
}
