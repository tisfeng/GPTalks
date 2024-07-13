//
//  ConversationTrailingPopup.swift
//  GPTalks
//
//  Created by Zabir Raihan on 06/07/2024.
//

import SwiftUI

struct ConversationTrailingPopup: View {
    @Bindable var session: Session
    @FocusState private var isFocused: Bool

    var body: some View {
        Form {
            Section("Title") {
                TextEditor(text: $session.title)
                    .font(.body)
                    .focused($isFocused)
                    .onAppear {
                        DispatchQueue.main.async {
                            isFocused = false
                        }
                    }
            }

            Section("System Prompt") {
                TextEditor(text: $session.config.systemPrompt)
                    .font(.body)
                    .onChange(of: session.config.systemPrompt) {
                        session.config.systemPrompt = String(
                            session.config.systemPrompt.trimmingCharacters(
                                in: .whitespacesAndNewlines))
                    }
            }
        }
        .textEditorStyle(.plain)
        .formStyle(.grouped)
        #if os(macOS)
            .frame(width: 400, height: 250)
        #endif
    }
}

#Preview {
    let session = Session()
    ConversationTrailingPopup(session: session)
        .padding()
}
