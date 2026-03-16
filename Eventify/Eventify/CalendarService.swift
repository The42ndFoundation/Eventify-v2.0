//
//  CalendarService.swift
//  Eventify
//
//  Copyright © 2026 The42nd Foundation. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//

import EventKit
import Foundation

final class CalendarService {
    
    // MARK: - Properties
    private let store = EKEventStore()
    
    // MARK: - Public Methods
    
    /// Request calendar access permission
    func requestAccessIfNeeded() async throws {
        // Check current authorization status
        let status = EKEventStore.authorizationStatus(for: .event)
        print("📅 Checking permission status: \(status)")
        
        switch status {
        case .authorized, .fullAccess:
            // Already permitted
            print("✅ Already authorized")
            return
        case .notDetermined:
            // Request permission
            print("📅 Requesting permission...")
            
            // Use better compatible way to request access
            let granted = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
                store.requestAccess(to: .event) { granted, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
            
            print("📅 Permission request result: \(granted)")
            guard granted else {
                throw CalendarError.accessDenied
            }
            
        case .denied, .restricted:
            print("❌ Permission denied or restricted")
            throw CalendarError.accessDenied
        case .writeOnly:
            // iOS 17+ writeOnly status can be used for adding events
            print("✅ writeOnly permission available for adding events")
            return
        @unknown default:
            print("❌ Unknown permission status")
            throw CalendarError.accessDenied
        }
    }
    
    /// Get default calendar
    func defaultCalendar() -> EKCalendar? {
        return store.defaultCalendarForNewEvents
    }
    
    /// Get all available calendars
    func availableCalendars() -> [EKCalendar] {
        return store.calendars(for: .event)
            .filter { $0.allowsContentModifications }
    }
    
    /// Add events to calendar
    func add(events: [EventCandidate], to calendar: EKCalendar? = nil) throws {
        // First check permission status
        let status = EKEventStore.authorizationStatus(for: .event)
        print("📅 Current permission status: \(status)")
        
        let targetCalendar = calendar ?? defaultCalendar()
        guard let calendar = targetCalendar else {
            print("❌ Unable to get default calendar")
            throw CalendarError.noCalendar
        }
        
        print("📅 Using calendar: \(calendar.title)")
        
        // Validate event data
        for candidate in events {
            try validateEvent(candidate)
        }
        
        print("📅 Preparing to save \(events.count) events")
        
        // Start transaction
        do {
            let ekEvents = events.map { createEKEvent(from: $0, calendar: calendar) }
            for (index, event) in ekEvents.enumerated() {
                print("📅 Saving event \(index + 1): \(event.title ?? "No title")")
                try store.save(event, span: .thisEvent, commit: false)
            }
            try store.commit()
            print("✅ All events saved successfully")
        } catch {
            // If failed, rollback transaction
            store.reset()
            print("❌ Save failed: \(error)")
            throw CalendarError.saveFailed(error)
        }
    }
    
    /// Add single event to calendar
    func add(event: EventCandidate, to calendar: EKCalendar? = nil) throws {
        try add(events: [event], to: calendar)
    }
    
    // MARK: - Private Methods
    
    private func validateEvent(_ event: EventCandidate) throws {
        // Validate time range
        if let endDate = event.endDate {
            if endDate < event.startDate {
                throw CalendarError.invalidDateRange
            }
        }
        
        // Validate title
        if event.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw CalendarError.invalidDateRange // Reuse error type, should be invalid event data
        }
        
        // Validate date range (not too far in past or future)
        let now = Date()
        let fiveYearsAgo = Calendar.current.date(byAdding: .year, value: -5, to: now) ?? now
        let tenYearsLater = Calendar.current.date(byAdding: .year, value: 10, to: now) ?? now
        
        if event.startDate < fiveYearsAgo || event.startDate > tenYearsLater {
            throw CalendarError.invalidDateRange
        }
    }
    
    private func createEKEvent(from candidate: EventCandidate, calendar: EKCalendar) -> EKEvent {
        let event = EKEvent(eventStore: store)
        event.calendar = calendar
        event.title = candidate.title
        event.location = candidate.location
        event.notes = candidate.notes
        event.isAllDay = candidate.isAllDay
        event.startDate = candidate.startDate
        
        // Set end time
        if let endDate = candidate.endDate {
            event.endDate = endDate
        } else if candidate.isAllDay {
            // All-day event defaults to 24 hours
            event.endDate = Calendar.current.date(byAdding: .day, value: 1, to: candidate.startDate) ?? candidate.startDate
        } else {
            // Regular event defaults to 1 hour
            event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: candidate.startDate) ?? candidate.startDate
        }
        
        // Set alert (optional)
        let reminder = EKAlarm(relativeOffset: -900) // 15 mins before
        event.addAlarm(reminder)
        
        return event
    }
}

// MARK: - Convenience Extensions
extension CalendarService {
    
    /// Check permission status
    var authorizationStatus: EKAuthorizationStatus {
        return EKEventStore.authorizationStatus(for: .event)
    }
    
    /// Whether app has permission
    var hasPermission: Bool {
        if #available(iOS 17.0, *) {
            return authorizationStatus == .fullAccess
        } else {
            return authorizationStatus == .authorized
        }
    }
    
    /// Permission description
    var permissionDescription: String {
        if #available(iOS 17.0, *) {
            switch authorizationStatus {
            case .fullAccess:
                return "Authorized"
            case .writeOnly:
                return "Write Only"
            case .notDetermined:
                return "Not Determined"
            case .denied:
                return "Denied"
            case .restricted:
                return "Restricted"
            @unknown default:
                return "Unknown"
            }
        } else {
            switch authorizationStatus {
            case .authorized:
                return "Authorized"
            case .notDetermined:
                return "Not Determined"
            case .denied:
                return "Denied"
            case .restricted:
                return "Restricted"
            @unknown default:
                return "Unknown"
            }
        }
    }
}
