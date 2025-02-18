//
//  ContentView.swift
//  GPTalks
//
//  Created by Zabir Raihan on 25/06/2024.
//

import SwiftUI
import SwiftData
import KeyboardShortcuts

struct ContentView: View {
    @Query(filter: #Predicate { $0.isEnabled }, sort: [SortDescriptor(\Provider.order, order: .forward)])
    var providers: [Provider]
    
    var body: some View {
        NavigationSplitView {
            SessionListSidebar(providers: providers)
            #if os(macOS)
                .navigationSplitViewColumnWidth(min: 240, ideal: 250, max: 300)
            #endif
        } detail: {
            ConversationListDetail(providers: providers)
        }
        #if os(macOS)
        .frame(minWidth: 600, minHeight: 400)
        #endif
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Session.self, inMemory: true)
        .environment(SessionVM())
}
