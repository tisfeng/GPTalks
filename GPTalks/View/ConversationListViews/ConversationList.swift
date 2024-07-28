//
//  ConversationList.swift
//  GPTalks
//
//  Created by Zabir Raihan on 25/06/2024.
//

import SwiftUI
import UniformTypeIdentifiers

struct ConversationList: View {
    var session: Session
    var isQuick: Bool = false
    
    @Environment(\.modelContext) var modelContext
    @Environment(SessionVM.self) private var sessionVM
    
    @State private var hasUserScrolled = false
    @State var showingInspector: Bool = false
    
    @State private var isExportingJSON = false
    @State private var isExportingMarkdown = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: spacing) {
                    ForEach(session.groups, id: \.self) { group in
                        ConversationGroupView(group: group)
                    }

                    ErrorMessageView(session: session)
                    
                    GeometryReader { geometry in
                        Color.clear
                            .frame(height: spacerHeight)
                            .id(String.bottomID)
                        #if !os(macOS)
                            .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .global).minY)
                        #endif
                    }
                }
                .padding()
                .padding(.top, -5)
            }
            .onAppear {
                session.proxy = proxy
            }
            #if os(macOS)
            .navigationSubtitle( session.config.systemPrompt.trimmingCharacters(in: .newlines).truncated(to: 45))
            .navigationTitle(session.title)
            .toolbar {
                ConversationListToolbar(session: session)
            }
            #else
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                let bottomReached = value > UIScreen.main.bounds.height
                hasUserScrolled = bottomReached
            }
            .onTapGesture {
                showingInspector = false
            }
            .toolbar {
                showInspector
            }
            .toolbarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle(session.config.model.name)
            .toolbarTitleMenu {
                exportButtons
            }
            #endif
            .applyObservers(proxy: proxy, session: session, hasUserScrolled: $hasUserScrolled)
            .scrollContentBackground(.visible)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !isQuick {
                    ChatInputView(session: session)
                } else {
                    EmptyView()
                }
            }
            #if !os(macOS)
            .inspector(isPresented: $showingInspector) {
                InspectorView(showingInspector: $showingInspector)
                    .presentationBackground(.thinMaterial)
            }
            #endif
            .onDrop(of: [UTType.image.identifier], isTargeted: nil) { providers -> Bool in
                session.inputManager.handleImageDrop(providers)
                return true
            }
        }
    }
    
    @ViewBuilder
    var exportButtons: some View {
        Button {
            isExportingJSON = true
        } label: {
            Label("Export JSON", systemImage: "ellipsis.curlybraces")
        }
        
        Button {
            isExportingMarkdown = true
        } label: {
            Label("Export Markdown", systemImage: "richtext.page")
        }
    }
    
    private var showInspector: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showingInspector.toggle()
            } label: {
                Label("Show Inspector", systemImage: "info.circle")
            }
        }
    }
    
    var spacerHeight: CGFloat {
        #if os(macOS)
        20
        #else
        10
        #endif
    }
    
    var spacing: CGFloat {
        #if os(macOS)
        0
        #else
        15
        #endif
    }
    
    var navSubtitle: String {
        "Tokens: "
        + session.tokenCounter.formatToK()
        + " • " + session.config.systemPrompt.trimmingCharacters(in: .newlines).truncated(to: 45)
    }
}

#Preview {
    let config = SessionConfig()
    let session = Session(config: config)
    
    ConversationList(session: session)
        .environment(SessionVM())
}
