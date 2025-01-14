//
//  ChatInspector.swift
//  GPTalks
//
//  Created by Zabir Raihan on 19/07/2024.
//

import SwiftUI
import SwiftData

struct ChatInspector: View {
    @Environment(\.dismiss) var dismiss
    var session: Session
    var providers: [Provider]
    
    @State private var selectedTab: Tab = .basic
    
    var body: some View {
        NavigationStack {
            Group {
                switch selectedTab {
                case .basic:
                    BasicChatInspector(session: session, providers: providers)
                case .advanced:
                    AdvancedChatInspector(session: session)
                }
            }
            #if os(macOS)
            .frame(height: 610)
            .safeAreaInset(edge: .top, spacing: 0) {
                ZStack(alignment: .trailing) {
                    HStack {
                        Spacer()
                        
                        picker
                        
                        Spacer()
                    }
                    
                    DismissButton() {
                        dismiss()
                    }
                    .imageScale(.large)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.bar)
            }
            #else
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    picker
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    DismissButton()
                        .buttonStyle(.plain)
                }
            }
            #endif
        }
    }
    
    var picker: some View {
        Picker("Tab", selection: $selectedTab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Text(tab.rawValue)
            }
        }
        .fixedSize()
        .pickerStyle(.segmented)
        .labelsHidden()
    }
    
    enum Tab: String, CaseIterable {
        case basic = "Basic"
        case advanced = "Advanced"
    }
}


#Preview {
    let providers: [Provider] = []
    
    ChatInspector(session: Session(config: SessionConfig()), providers: providers)
        .modelContainer(for: Provider.self, inMemory: true)
        .formStyle(.grouped)
        .frame(width: 400, height: 700)
}
