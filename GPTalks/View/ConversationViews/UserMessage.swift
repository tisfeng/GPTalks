//
//  UserMessage.swift
//  GPTalks
//
//  Created by Zabir Raihan on 04/07/2024.
//

import SwiftUI

struct UserMessage: View {
    var conversation: Conversation
    @State var isHovered: Bool = false
    
    @State var maxHeight: CGFloat = 400
    @State var labelSize: CGSize = CGSize()
    @State var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if !conversation.imagePaths.isEmpty {
                imageList
            }
            
            Text(conversation.content)
                .textSelection(.enabled)
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
                .contextMenu {
                    if let group = conversation.group {
                        ConversationMenu(group: group, labelSize: labelSize, toggleMaxHeight: toggleMaxHeight, isExpanded: isExpanded)
                    }
                }
            
            #if os(macOS)
            if let group = conversation.group {
                ConversationMenu(group: group, labelSize: labelSize, toggleMaxHeight: toggleMaxHeight, isExpanded: isExpanded)
                    .opacity(isHovered ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: isHovered)
            }
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: maxHeight, alignment: .trailing)
        .padding(.leading, 160)
        .onHover { isHovered in
            self.isHovered = isHovered
        }
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
#if !os(macOS)
#endif
    }
    
    var indexOfConversationGroup: Int {
        conversation.group?.session?.groups.firstIndex(where: { $0 == conversation.group }) ?? 0
    }
    
    var imageList: some View {
        ScrollView {
            HStack {
                ForEach(conversation.imagePaths, id: \.self) { imagePath in
                    ImageViewer(imagePath: imagePath, maxWidth: 200, maxHeight: 200, radius: 9, isCrossable: false) {
                            print("Should not be removed like this")
                    }
                }
            }
        }
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
