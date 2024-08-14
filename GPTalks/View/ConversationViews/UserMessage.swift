//
//  UserMessage.swift
//  GPTalks
//
//  Created by Zabir Raihan on 04/07/2024.
//

import SwiftUI

struct UserMessage: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var config = AppConfig.shared
    
    var conversation: Conversation
    @State var isHovered: Bool = false
    
    @State var maxHeight: CGFloat = 400
    @State var labelSize: CGSize = CGSize()
    @State var isExpanded: Bool = false
    @State var showingTextSelection = false
    
    var body: some View {
        if config.listView {
            content
                .frame(maxWidth: .infinity, alignment: .trailing)
        } else {
            content
                .frame(maxWidth: .infinity, maxHeight: maxHeight, alignment: .trailing)
                .background {
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                updateLabelSize(geometry.size)
                            }
                            .onChange(of: geometry.size) {
                                updateLabelSize(geometry.size)
                            }
                    }
                }
        }
        

//        .frame(maxWidth: .infinity, maxHeight: maxHeight, alignment: .trailing)
//        .padding(.leading, leadingPadding)
//        .background {
//            GeometryReader { geometry in
//                Color.clear
//                    .onAppear {
//                        updateLabelSize(geometry.size)
//                    }
//                    .onChange(of: geometry.size) {
//                        updateLabelSize(geometry.size)
//                    }
//            }
//        }
    }
    
    var content: some View {
        VStack(alignment: .trailing, spacing: 7) {
            if !conversation.imagePaths.isEmpty {
                imageList
            }
            
            HighlightedText(text: conversation.content, highlightedText: conversation.group?.session?.searchText.count ?? 0 > 3 ? conversation.group?.session?.searchText : nil)
                .padding(.vertical, 8)
                .padding(.horizontal, 11)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                    #if os(macOS)
                        .fill(.background.quinary)
                    #else
                        .fill(.background.secondary)
                    #endif
                        .fill(conversation.group?.session?.inputManager.editingIndex == indexOfConversationGroup ? Color.accentColor.opacity(0.1) : .clear)
                )
            
            #if os(macOS)
            if let group = conversation.group {
                ConversationMenu(group: group, labelSize: labelSize, toggleMaxHeight: toggleMaxHeight, isExpanded: isExpanded)
                    .symbolEffect(.appear, isActive: !isHovered)
            }
            #endif
        }
        .padding(.leading, leadingPadding)
        #if !os(macOS)
        .contextMenu {
            if let group = conversation.group {
                ConversationMenu(group: group, labelSize: labelSize, toggleMaxHeight: toggleMaxHeight, isExpanded: isExpanded, toggleTextSelection: toggleTextSelection)
            }
        } preview: {
            Text("User Message")
                .padding()
        }
        .sheet(isPresented: $showingTextSelection) {
            TextSelectionView(content: conversation.content)
        }
        #else
        .onHover { isHovered in
            self.isHovered = isHovered
        }
        #endif
    }
    
    func toggleTextSelection() {
        showingTextSelection.toggle()
    }
    
    var leadingPadding: CGFloat {
        #if os(macOS)
        160
        #else
        60
        #endif
    }
    
    var indexOfConversationGroup: Int {
        conversation.group?.session?.groups.firstIndex(where: { $0 == conversation.group }) ?? 0
    }
    
    var imageList: some View {
        ScrollView {
            HStack {
                ForEach(conversation.imagePaths, id: \.self) { imagePath in
                    ImageViewer(imagePath: imagePath, maxWidth: maxImageSize, maxHeight: maxImageSize, radius: 9, isCrossable: false) {
                            print("Should not be removed from here")
                    }
                }
            }
        }
    }
    
    private var maxImageSize: CGFloat {
        300
    }
    
    func updateLabelSize(_ size: CGSize) {
        DispatchQueue.main.async {
            if self.labelSize != size {
                self.labelSize = size
            }
        }
    }
    
    func toggleMaxHeight() {
        withAnimation {
            if maxHeight == 400 {
                maxHeight = .infinity
                isExpanded = true
            } else {
                maxHeight = 400
                isExpanded = false
            }
        }
    }
}

#Preview {
    let conversation = Conversation(
        role: .user, content: "Hello, World! who are you and how are you")

    UserMessage(conversation: conversation)
        .frame(width: 500, height: 300)
}
