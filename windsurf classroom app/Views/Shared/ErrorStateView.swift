//
//  ErrorStateView.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/02.
//

import SwiftUI

struct ErrorStateView: View {
    let title: String
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(.largeTitle, design: .default))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange.opacity(0.7), .red.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .accessibilityLabel("Error icon")
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("error-title")
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .padding(.horizontal, 32)
                    .accessibilityIdentifier("error-message")
            }
            
            Button(action: retryAction) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16))
                    
                    Text("Try Again")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.blue)
                )
                .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 40)
            .padding(.top, 8)
            .accessibilityIdentifier("error-retry-button")
            .accessibilityLabel("Try again")
            .accessibilityHint("Retries the failed operation")
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    ErrorStateView(
        title: "Something Went Wrong",
        message: "We couldn't load your data. Please check your connection and try again.",
        retryAction: {}
    )
}
