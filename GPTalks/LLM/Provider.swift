//
//  Provider.swift
//  GPTalks
//
//  Created by Zabir Raihan on 04/07/2024.
//

import Foundation
import SwiftData

@Model
class Provider {
    var id: UUID = UUID()
    var date: Date = Date()
    var order: Int = 0
    
    var name: String = ""
    var host: String = ""
    @Attribute(.allowsCloudEncryption)
    var apiKey: String = ""
    
    var type: ProviderType
    
    var color: String = "#00947A"
    var isEnabled: Bool = true
    
    @Relationship(deleteRule: .nullify)
    var chatModel: AIModel
    @Relationship(deleteRule: .nullify)
    var quickChatModel: AIModel
    @Relationship(deleteRule: .nullify)
    var titleModel: AIModel
    @Relationship(deleteRule: .nullify)
    var imageModel: AIModel
    
    @Relationship(deleteRule: .nullify)
    var models =  [AIModel]()
    
    var sortedModels: [AIModel] {
        models.sorted(by: { $0.order < $1.order })
    }
    
    var chatModels: [AIModel] {
        get {
            return models.filter { $0.modelType == .chat}
        }
        set {
            models = newValue + imageModels
        }
    }
    
    var imageModels: [AIModel] {
        get {
            return models.filter { $0.modelType == .image}
        }
        set {
            models = chatModels + newValue
        }
    }

    public init(id: UUID = UUID(),
                date: Date = Date(),
                order: Int = 0,
                name: String,
                host: String,
                apiKey: String,
                type: ProviderType,
                color: String,
                isEnabled: Bool,
                chatModel: AIModel,
                quickChatModel: AIModel,
                titleModel: AIModel,
                imageModel: AIModel,
                models: [AIModel] = []) {
        self.id = id
        self.date = date
        self.order = order
        self.name = name
        self.host = host
        self.apiKey = apiKey
        self.type = type
        self.color = color
        self.isEnabled = isEnabled
        self.chatModel = chatModel
        self.quickChatModel = quickChatModel
        self.titleModel = titleModel
        self.imageModel = imageModel
        self.models = models
    }
    
    
    private init() {
        let demoModel = AIModel.getDemoModel()
        
        self.chatModel = demoModel
        self.quickChatModel = demoModel
        self.titleModel = demoModel
        self.imageModel = demoModel
        self.type = .openai
    }
    
    static func factory(type: ProviderType) -> Provider {
        let provider = Provider()
        provider.type = type
        provider.name = type.name
        provider.host = type.defaultHost
        provider.models = type.getDefaultModels()
        provider.color = type.defaultColor
        
        if let first = provider.chatModels.first {
            provider.chatModel = first
            provider.quickChatModel = first
            provider.titleModel = first
        }
        
        if let first = provider.imageModels.first {
            provider.imageModel = first
        }
        
        return provider
    }

    @MainActor
    func refreshModels() async {
        let refreshModels = await type.refreshModels(provider: self)
        
        for model in refreshModels {
            if !models.contains(where: { $0.code == model.code }) {
                models.append(model)
            }
        }
    }
    
    func addOpenAIModels() {
        for model in AIModel.getOpenaiModels() {
            if !models.contains(where: { $0.code == model.code }) {
                models.append(model)
            }
        }
    }
    
    func addClaudeModels() {
        for model in AIModel.getAnthropicModels() {
            if !models.contains(where: { $0.code == model.code }) {
                models.append(model)
            }
        }
    }
    
    func addGoogleModels() {
        for model in AIModel.getGoogleModels() {
            if !models.contains(where: { $0.code == model.code }) {
                models.append(model)
            }
        }
    }
}
