//
//  TextCapitalization.swift
//  windsurf classroom app
//
//  Created by Cascade on 2026/06/09.
//

import SwiftUI

/// A binding modifier that auto-capitalizes the first letter of each word after the first word.
/// This handles surnames and middle names, including multi-word surnames.
func autoCapitalizeBinding(_ binding: Binding<String>) -> Binding<String> {
    Binding<String>(
        get: { binding.wrappedValue },
        set: { newValue in
            let words = newValue.split(separator: " ", omittingEmptySubsequences: false)
            var capitalizedWords: [String] = []
            
            for (index, word) in words.enumerated() {
                if index == 0 {
                    // First word: keep as-is (user can type lowercase if they want)
                    capitalizedWords.append(String(word))
                } else if !word.isEmpty {
                    // All subsequent words: capitalize first letter
                    let firstChar = word.prefix(1).capitalized
                    let rest = word.dropFirst().lowercased()
                    capitalizedWords.append(firstChar + rest)
                } else {
                    // Preserve empty strings (multiple spaces)
                    capitalizedWords.append(String(word))
                }
            }
            
            binding.wrappedValue = capitalizedWords.joined(separator: " ")
        }
    )
}
