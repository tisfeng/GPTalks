//
//  QuickPanel.swift
//  GPTalks
//
//  Created by Zabir Raihan on 12/07/2024.
//

import SwiftUI
import SwiftData

#if os(macOS)
struct QuickPanel: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismissWindow) var dismissWindow
    @Environment(\.openWindow) var openWindow
    @Environment(SessionVM.self) private var sessionVM
    
    @Bindable var session: Session
    @Binding var showAdditionalContent: Bool
    
    @State var prompt: String = ""
    @FocusState private var isFocused: Bool
    
    @Query(filter: #Predicate { $0.isEnabled }, sort: [SortDescriptor(\Provider.order, order: .forward)])
    var providers: [Provider]
    
    @State var selections: Set<Session> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Button("Paste Image") {
                    session.inputManager.handlePaste(supportedFileTypes: session.config.provider.type.supportedFileTypes)
                    showAdditionalContent = true
                }
                .hidden()
                .keyboardShortcut("b")
                
                Button("Focus Field") {
                    isFocused = true
                }
                .hidden()
                .keyboardShortcut("l")
                
                textfieldView
                    .padding(15)
                    .padding(.leading, 1)
            }
            
            if showAdditionalContent {
                Divider()
                
                if !session.inputManager.dataFiles.isEmpty {
                    DataFileView(dataFiles: $session.inputManager.dataFiles, isCrossable: true, edge: .center)
                        .safeAreaPadding(.horizontal)
                        .safeAreaPadding(.vertical, 10)
                } else {
                    EmptyView()
                }
                
                ConversationList(session: session, providers: providers)
                    .navigationTitle("Quick Panel")
                    .scrollContentBackground(.hidden)
                
                bottomView
            }
        }
        .onAppear {
            selections = sessionVM.selections
            sessionVM.selections = []
            isFocused = true
            if !session.groups.isEmpty {
                showAdditionalContent = true
            }
        }
        .onDisappear {
            sessionVM.selections = selections
        }
        .onChange(of: isFocused) {
            isFocused = true
        }
    }
    
    @ViewBuilder
    var textfieldView: some View {
        HStack(spacing: 12) {
            Menu {
                ProviderPicker(
                    provider: $session.config.provider,
                    providers: providers,
                    onChange: { newProvider in
                        session.config.model = newProvider.quickChatModel
                    }
                )

                ModelPicker(model: $session.config.model, models: session.config.provider.chatModels, label: "Model")
                
                Menu {
                    ToolsController(tools: $session.config.tools)
                } label: {
                    Label("Tools", systemImage: "hammer")
                }
                
            } label: {
                Image(systemName: "magnifyingglass")
                    .resizable()
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            
            TextField("Ask Anything...", text: $prompt, axis: .vertical)
                .focused($isFocused)
                .font(.system(size: 25))
                .textFieldStyle(.plain)
                .allowsHitTesting(false)
            
            if session.isReplying {
                StopButton(size: 28) {
                    session.stopStreaming()
                }
            } else {
                SendButton(size: 28) {
                    send()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
    }
    
    private var bottomView: some View {
        HStack {
            Group {
                Button {
                    resetChat()
                } label: {
                    Image(systemName: "delete.left")
                        .imageScale(.medium)
                }
                .keyboardShortcut(.delete, modifiers: [.command, .shift])
                
                Group {
                    Text(session.config.provider.name.uppercased())
                    
                    Text(session.config.model.name)
                    
                    ForEach(session.config.tools.enabledTools) { tool in
                        Image(systemName: tool.icon)
                    }
                }
                .font(.caption)
                
                Spacer()
                
                Button {
                    addToDB()
                } label: {
                    Image(systemName: "plus.square.on.square")
                        .imageScale(.medium)
                }
                .disabled(session.groups.isEmpty)
                .keyboardShortcut("N", modifiers: [.command])
                
            }
            .foregroundStyle(.secondary)
            .buttonStyle(.plain)
            .padding(7)
        }
        .background(.regularMaterial)
    }
    
    private func resetChat() {
        showAdditionalContent = false
        session.deleteAllConversations()
        session.inputManager.dataFiles.removeAll()
        let oldConfig = session.config
        if let quickProvider = ProviderManager.shared.getQuickProvider(providers: providers) {
            session.config = .init(provider: quickProvider, purpose: .quick)
        }
        modelContext.delete(oldConfig)
    }
    
    private func addToDB() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.keyWindow?.makeKeyAndOrderFront(nil)
        
        let newSession = session.copy(purpose: .quick)
        sessionVM.fork(session: newSession, modelContext: modelContext)
        resetChat()
        
        showAdditionalContent = false
        dismissWindow(id: "quick")
        openWindow(id: "main")
    }
    
    private func send() {
        if prompt.isEmpty {
            return
        }
        
        session.config.systemPrompt = AppConfig.shared.quickSystemPrompt
        
        showAdditionalContent = true
        
        session.inputManager.prompt = prompt
        
        Task {
            await session.sendInput()
        }
        
        prompt = ""
    }
}

#Preview {
    let showAdditionalContent = Binding.constant(true)
    
    QuickPanel(session: Session(config: .init()), showAdditionalContent: showAdditionalContent)
}
#endif
