//
//  GoogleService.swift
//  GPTalks
//
//  Created by Zabir Raihan on 30/07/2024.
//

import Foundation
import SwiftUI
import GoogleGenerativeAI

struct GoogleService: AIService {
    typealias ConvertedType = ModelContent
    
    static func refreshModels(provider: Provider) async -> [AIModel] {
        let service = GenerativeAIService(apiKey: provider.apiKey, urlSession: .shared)
        
        do {
            let models = try await service.listModels()
            return models.models.map { AIModel(code: $0.name, name: $0.displayName ?? $0.name) }
        } catch {
            print(error.localizedDescription)
            return []
        }
    }
    
    static func convert(conversation: Conversation) -> GoogleGenerativeAI.ModelContent {
        var parts: [ModelContent.Part] = [.text(conversation.content)]
        
        for dataFile in conversation.dataFiles {
            if dataFile.fileType.conforms(to: .text) {
                parts.insert(.text(String(data: dataFile.data, encoding: .utf8) ?? ""), at: 0)
            } else {
                parts.insert(.data(mimetype: dataFile.mimeType, dataFile.data), at: 0)
            }
        }
        
        // TODO: see if can send image here
        if let response = conversation.toolResponse {
            parts.append(.functionResponse(.init(name: response.tool.rawValue, response: .init(dictionaryLiteral: ("content", .string(response.processedContent))))))
        }
        
        return ModelContent(
            role: conversation.role.toGoogleRole(),
            parts: parts
        )
    }
    
    static func streamResponse(from conversations: [Conversation], config: SessionConfig) -> AsyncThrowingStream<StreamResponse, Error> {
        let (model, messages) = createModelAndMessages(from: conversations, config: config)
        return streamGoogleResponse(model: model, messages: messages)
    }
    
    static func nonStreamingResponse(from conversations: [Conversation], config: SessionConfig) async throws -> StreamResponse {
        let (model, messages) = createModelAndMessages(from: conversations, config: config)
        return try await nonStreamingGoogleResponse(model: model, messages: messages)
    }
    
    static private func createModelAndMessages(from conversations: [Conversation], config: SessionConfig) -> (GenerativeModel, [ModelContent]) {
        let systemPrompt = ModelContent(role: "system", parts: [.text(config.systemPrompt)])
        
        let genConfig = GenerationConfig(
            temperature: config.temperature.map { Float($0) },
            topP: config.topP.map { Float($0) },
            maxOutputTokens: config.maxTokens
        )
        
        let tools = config.tools.enabledTools.map { $0.google }
        
        let model = GenerativeModel(
            name: config.model.code,
            apiKey: config.provider.apiKey,
            generationConfig: genConfig,
            tools: tools.isEmpty ? nil : tools,
            systemInstruction: systemPrompt)
        
        let messages = conversations.map { convert(conversation: $0) }
        
        return (model, messages)
    }
    
    static private func streamGoogleResponse(model: GenerativeModel, messages: [ModelContent]) -> AsyncThrowingStream<StreamResponse, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let responseStream = model.generateContentStream(messages)
                    
                    for try await response in responseStream {
                        if let content = response.text {
                            continuation.yield(.content(content))
                        }
                        
                        let content = response.functionCalls
                        if !content.isEmpty {
                            let functionCalls = response.functionCalls
                            
                            let calls: [ToolCall] = functionCalls.map {
                                ToolCall(toolCallId: "", tool: ChatTool(rawValue: $0.name)!, arguments: encodeJSONObjectToString($0.args))
                            }

                            continuation.yield(.toolCalls(calls))
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    static private func nonStreamingGoogleResponse(model: GenerativeModel, messages: [ModelContent]) async throws -> StreamResponse {
        let response = try await model.generateContent(messages)
        return .content(response.text ?? "")
//        return response.text ?? ""
    }
    
    static func testModel(provider: Provider, model: AIModel) async -> Bool {
        let model = GenerativeModel(name: model.code, apiKey: provider.apiKey)
        
        do {
            let response = try await model.generateContent(String.testPrompt)
            return response.text != nil
        } catch {
            return false
        }
    }
}

func encodeJSONObjectToString(_ jsonObject: JSONObject) -> String {
    let encoder = JSONEncoder()
    do {
        let data = try encoder.encode(jsonObject)
        if let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        } else {
            return "{}" // Return empty object as fallback
        }
    } catch {
        print("Error encoding JSON: \(error)")
        return "{}" // Return empty object in case of error
    }
}
