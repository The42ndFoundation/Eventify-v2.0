//
//  HomeView.swift
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
import PhotosUI

struct HomeView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel: EventParsingViewModel
    
    // MARK: - Initialization
    init() {
        // Use local text parser, no API key required
        let localParser = LocalTextParser()
        self._viewModel = StateObject(wrappedValue: EventParsingViewModel(aiClient: localParser))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 24) {
                    
                    // Header Area
                    headerSection
                    
                    // Input Area
                    inputSection
                    
                    // Image Selection Area
                    imageSection
                    
                    // Parse Button
                    parseButton
                    
                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        errorSection(errorMessage)
                    }
                    
                    // Ensure enough bottom space
                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 50)
            }
            .navigationTitle(L10n.App.title)
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $viewModel.showingConfirmView) {
                if let parsedResponse = viewModel.parsedResponse {
                    ConfirmEventsView(parsedResponse: parsedResponse, originalText: viewModel.inputText) {
                        // Clear input after saving
                        viewModel.clearInput()
                    }
                }
            }
            .onChange(of: viewModel.photoItem) { _, _ in
                viewModel.handleImageSelection()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(Color("ChelseaBlue"))
            
            Text(L10n.App.subtitle)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(L10n.App.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Input Section
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Input.title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            TextEditor(text: $viewModel.inputText)
                .frame(minHeight: 120, maxHeight: 200)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .scrollContentBackground(.hidden)
            
            Text(L10n.Input.placeholder)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Image Section
    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Image.title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            PhotosPicker(
                selection: $viewModel.photoItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(Color("ChelseaBlue"))
                    Text(L10n.Image.button)
                        .font(.headline)
                        .foregroundStyle(Color("ChelseaBlue"))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            }
            
            // Show selected image
            if let selectedImage = viewModel.selectedImage {
                selectedImageView(selectedImage)
            }
        }
    }
    
    // MARK: - Selected Image View
    private func selectedImageView(_ image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Image.selected)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 80)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Image.ready)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(L10n.Image.instruction)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(L10n.Image.delete) {
                    viewModel.selectedImage = nil
                    viewModel.photoItem = nil
                }
                .font(.caption)
                .foregroundStyle(.red)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Parse Button
    private var parseButton: some View {
        Button {
            Task {
                await viewModel.parseEvents()
            }
        } label: {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "brain.head.profile")
                        .font(.headline)
                }
                
                Text(viewModel.isLoading ? L10n.Parse.loading : L10n.Parse.button)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                viewModel.isLoading ? 
                Color(.systemGray4) : 
                Color("ChelseaBlue")
            )
            .foregroundStyle(.white)
            .cornerRadius(12)
        }
        .disabled(viewModel.isLoading || (viewModel.inputText.isEmpty && viewModel.selectedImage == nil))
    }
    
    // MARK: - Error Section
    private func errorSection(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Button(L10n.General.retry) {
                viewModel.errorMessage = nil
            }
            .font(.caption)
            .foregroundStyle(Color("ChelseaBlue"))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange, lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    HomeView()
}
