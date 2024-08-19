//
//  ConversationConverter.swift
//  GPTalks
//
//  Created by Zabir Raihan on 18/08/2024.
//

import Foundation
import OpenAI
import GoogleGenerativeAI
import SwiftAnthropic

extension Conversation {
    func toOpenAI() -> ChatQuery.ChatCompletionMessageParam {
        if self.dataFiles.isEmpty {
            return ChatQuery.ChatCompletionMessageParam(
                role: self.role.toOpenAIRole(),
                content: self.content
            )!
        } else {
            var visionContent: [ChatQuery.ChatCompletionMessageParam.ChatCompletionUserMessageParam.Content.VisionContent] = []
            
            for dataFile in self.dataFiles {
                if dataFile.fileType.conforms(to: .image) {
                    visionContent.append(.init(chatCompletionContentPartImageParam: .init(imageUrl: .init(url: dataFile.data, detail: .auto))))
                } else {
                    // TODO: do RAG conversion here
                    visionContent.append(.init(chatCompletionContentPartTextParam: .init(text: "\(dataFile.fileExtension.uppercased()) files are not supported yet. Notify the user.")))
                }
            }
            
            visionContent.append(.init(chatCompletionContentPartTextParam: .init(text: self.content)))

            return ChatQuery.ChatCompletionMessageParam(
                role: self.role.toOpenAIRole(),
                content: visionContent
            )!
        }
    }

    func toGoogle() -> ModelContent {
        // TODO: add video support
        var parts: [ModelContent.Part] = [.text(content)]
        
        for dataFile in self.dataFiles {
            parts.insert(.data(mimetype: dataFile.mimeType, dataFile.data), at: 0)
        }
        
        return ModelContent(
            role: role.toGoogleRole(),
            parts: parts
        )
    }
    
    func toClaude() -> MessageParameter.Message {
        var contentObjects: [MessageParameter.Message.Content.ContentObject] = []
        
        for dataFile in dataFiles {
            if dataFile.fileType.conforms(to: .image) {
                let imageSource = MessageParameter.Message.Content.ImageSource(
                    type: .base64,
                    mediaType: .init(rawValue: dataFile.mimeType) ?? .jpeg,
                    data: dataFile.data.base64EncodedString()
                )
                contentObjects.append(.image(imageSource))
            } else {
                // TODO: do RAG conversion here. shouldnt reach here atm
                contentObjects.append(.text("\(dataFile.fileExtension.uppercased()) files are not supported yet. Notify the user."))
            }
        }
        
        contentObjects.append(.text(self.content))
        
        let finalContent: MessageParameter.Message = .init(
            role: self.role.toClaudeRole(),
            content: .list(contentObjects)
        )
        
        return finalContent
    }
}