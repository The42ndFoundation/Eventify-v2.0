//
//  ConfirmEventsView.swift
//  Eventify
//
//  Copyright © 2026 The42nd Foundation. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//

import SwiftUI
import EventKit

struct ConfirmEventsView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel: ConfirmEventsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    @State private var eventToDelete: EventCandidate?
    @State private var showingCompletionAlert = false
    
    // Completion callback
    let onCompletion: () -> Void
    
    // MARK: - Initialization
    init(parsedResponse: ParsedEventsResponse, originalText: String = "", onCompletion: @escaping () -> Void = {}) {
        self._viewModel = StateObject(wrappedValue: ConfirmEventsViewModel(parsedResponse: parsedResponse, originalText: originalText))
        self.onCompletion = onCompletion
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // Warning message
                if !viewModel.warnings.isEmpty {
                    warningsSection
                }
                
                // Event list
                eventsList
                
                // Bottom action area
                bottomActions
            }
            .navigationTitle(L10n.Confirm.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Confirm.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Confirm.save) {
                        Task {
                            let success = await viewModel.saveToCalendar()
                            // Show completion alert after successful save
                            if success {
                                showingCompletionAlert = true
                            }
                        }
                    }
                    .disabled(viewModel.events.isEmpty || viewModel.isWriting)
                }
            }
            .alert(L10n.Event.delete, isPresented: $showingDeleteAlert) {
                Button(L10n.Event.delete, role: .destructive) {
                    if let event = eventToDelete,
                       let index = viewModel.events.firstIndex(where: { $0.id == event.id }) {
                        viewModel.deleteEvent(at: IndexSet([index]))
                    }
                }
                Button(L10n.Confirm.cancel, role: .cancel) { }
            } message: {
                Text(L10n.General.deleteConfirm)
            }
            .alert(L10n.Result.title, isPresented: Binding(
                get: { viewModel.showingResult },
                set: { _ in viewModel.dismissResult() }
            )) {
                Button(L10n.Result.confirm) {
                    viewModel.dismissResult()
                    if viewModel.writeResult?.contains("✅") == true { // Replaced "成功" with "✅" as per instruction's suggestion
                        dismiss()
                    }
                }
            } message: {
                if let result = viewModel.writeResult {
                    Text(result)
                }
            }
            .alert(L10n.Result.title, isPresented: $showingCompletionAlert) {
                Button(L10n.Result.confirm) {
                    onCompletion() // Call completion callback
                    dismiss()
                }
            } message: {
                Text(L10n.Calendar.success(viewModel.events.count))
            }
            .onChange(of: showingCompletionAlert) { _, newValue in
                if newValue {
                    // Automatically close the alert after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        showingCompletionAlert = false
                        onCompletion() // Call completion callback
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Warnings Section
    private var warningsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(L10n.Confirm.warnings)
                    .font(.headline)
                    .foregroundStyle(.orange)
            }
            
            ForEach(viewModel.warnings, id: \.self) { warning in
                Text("• \(warning)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Events List
    private var eventsList: some View {
        List {
            ForEach($viewModel.events) { $event in
                EventRowView(event: $event) {
                    eventToDelete = event
                    showingDeleteAlert = true
                }
            }
            .onDelete { indexSet in
                viewModel.deleteEvent(at: indexSet)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Bottom Actions
    private var bottomActions: some View {
        VStack(spacing: 12) {
            Divider()
            
            HStack(spacing: 12) {
                Button {
                    viewModel.addNewEvent()
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text(L10n.Confirm.addEvent)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                }
                
                // AI re-parse button
                if !viewModel.originalText.isEmpty {
                    Button {
                        Task {
                            await viewModel.aiReparse()
                        }
                    } label: {
                        HStack {
                            if viewModel.isReparsing {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(viewModel.isReparsing ? L10n.Confirm.aiReparsing : L10n.Confirm.aiReparse)
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                    }
                    .disabled(viewModel.isReparsing)
                }
                
                Spacer()
                
                Button {
                    Task {
                        let success = await viewModel.saveToCalendar()
                        // Show completion alert after successful save
                        if success {
                            showingCompletionAlert = true
                        }
                    }
                } label: {
                    HStack {
                        if viewModel.isWriting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "calendar.badge.plus")
                        }
                        
                        Text(viewModel.isWriting ? L10n.Confirm.saving : L10n.Confirm.saveToCalendar)
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(viewModel.isWriting ? Color(.systemGray4) : Color("ChelseaBlue"))
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                }
                .disabled(viewModel.events.isEmpty || viewModel.isWriting)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Event Row View
struct EventRowView: View {
    
    @Binding var event: EventCandidate
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Title
            Section(L10n.Event.title) {
                TextField(L10n.Event.title, text: $event.title)
            }
            
            // All Day Toggle
            Toggle(L10n.Event.allDay, isOn: $event.isAllDay)
            
            // Time Selection
            Section(L10n.Event.startTime) {
                DatePicker("", selection: $event.startDate, displayedComponents: event.isAllDay ? [.date] : [.date, .hourAndMinute])
                    .datePickerStyle(CompactDatePickerStyle())
            }
            
            if !event.isAllDay {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.Event.endTime)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    DatePicker("",
                               selection: Binding(
                                get: { event.endDate ?? event.startDate.addingTimeInterval(3600) },
                                set: { event.endDate = $0 }
                               ),
                               displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(CompactDatePickerStyle())
                }
            }
            
            // Location
            Section(L10n.Event.location) {
                TextField(L10n.Event.location, text: Binding($event.location, default: ""))
            }
            
            // Notes
            Section(L10n.Event.notes) {
                TextField(L10n.Event.notes, text: Binding($event.notes, default: ""), axis: .vertical)
                    .lineLimit(3...5)
            }
            
            // Delete button
            Section {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    HStack {
                        Spacer()
                        Text(L10n.Event.delete)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    let sampleResponse = ParsedEventsResponse(
        events: [
            EventCandidate(
                title: "Math Class",
                notes: "Advanced Mathematics Chapter 3",
                location: "Science Building 101",
                startDate: Date(),
                endDate: Date().addingTimeInterval(7200)
            ),
            EventCandidate(
                title: "Team Meeting",
                location: "Meeting Room A",
                startDate: Date().addingTimeInterval(86400),
                endDate: Date().addingTimeInterval(86400 + 3600)
            )
        ],
        warnings: ["Time inference: No end time specified, set to 1 hour"]
    )
    
    return ConfirmEventsView(parsedResponse: sampleResponse)
}
