//
//  Provider.swift
//  GPTalks
//
//  Created by Zabir Raihan on 04/07/2024.
//

import Foundation
import SwiftData
import OpenAI
import GoogleGenerativeAI

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
    
    @Relationship(deleteRule: .cascade)
    var chatModel: AIModel
    @Relationship(deleteRule: .cascade)
    var quickChatModel: AIModel
    @Relationship(deleteRule: .cascade)
    var titleModel: AIModel
    @Relationship(deleteRule: .cascade)
    var imageModel: AIModel
    
    @Relationship(deleteRule: .cascade)
    var chatModels: [AIModel] = []
    
    @Relationship(deleteRule: .cascade)
    var imageModels: [AIModel] = []

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
                chatModels: [AIModel] = [],
                imageModels: [AIModel] = []) {
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
        self.chatModels = chatModels
        self.imageModels = imageModels
    }
    
    
    private init() {
        let demoModel = AIModel.getDemoModel()
        
        self.chatModel = demoModel
        self.quickChatModel = demoModel
        self.titleModel = demoModel
        self.imageModel = demoModel
        self.type = .openai
    }
    
    static func factory(type: ProviderType, isDummy: Bool = false) -> Provider {
        let provider = Provider()
        provider.type = type
        provider.name = type.name
        provider.host = type.defaultHost
        provider.chatModels = type.getDefaultModels()
        provider.imageModels = type.getDefaultModels()
        provider.color = type.defaultColor
        
        if let first = provider.chatModels.first {
            provider.chatModel = first
            provider.quickChatModel = first
            provider.titleModel = first
        }
        
        if let first = provider.imageModels.first {
            provider.imageModel = first
        }
        
        if isDummy {
            provider.isEnabled = false
        }
        
        return provider
    }
}

extension Provider {
    @MainActor
    func refreshModels() async {
         let refreshedModels: [AIModel]

         switch type {
         case .openai, .local:
             let config = OpenAI.Configuration(
                 token: apiKey,
                 host: host,
                 scheme: type.scheme
             )
             
             let service = OpenAI(configuration: config)
             
             if let models = try? await service.models() {
                 refreshedModels = models.data.map {
                     AIModel(code: $0.id, name: $0.name)
                 }
             } else {
                 refreshedModels = []
             }
         case .google:
             let service = GenerativeAIService(apiKey: apiKey, urlSession: .shared)
             
             do {
                 let models = try await service.listModels()
                 
                 refreshedModels = models.models.map {
                     AIModel(code: $0.name, name: $0.displayName ?? $0.name)
                 }
      
             } catch {
                 print(error.localizedDescription)
                 refreshedModels = []
             }
        
         case .anthropic:
             refreshedModels = type.getDefaultModels()
         case .vertex:
             refreshedModels = type.getDefaultModels()
         }

         for model in refreshedModels {
             if !chatModels.contains(where: { $0.code == model.code }) {
                 chatModels.append(model)
             }
         }
     }
    
    func addOpenAIModels() {
        for model in AIModel.getOpenaiModels() {
            if !chatModels.contains(where: { $0.code == model.code }) {
                chatModels.append(model)
            }
        }
    }
    
    func addClaudeModels() {
        for model in AIModel.getAnthropicModels() {
            if !chatModels.contains(where: { $0.code == model.code }) {
                chatModels.append(model)
            }
        }
    }
    
    func addGoogleModels() {
        for model in AIModel.getGoogleModels() {
            if !chatModels.contains(where: { $0.code == model.code }) {
                chatModels.append(model)
            }
        }
    }
}

extension Provider {
    func models(for type: ModelType) -> [AIModel] {
        switch type {
        case .chat:
            return chatModels
        case .image:
            return imageModels
        // Add more cases here as you add more model types
        }
    }

    func setModels(_ models: [AIModel], for type: ModelType) {
        switch type {
        case .chat:
            chatModels = models
        case .image:
            imageModels = models
        // Add more cases here as you add more model types
        }
    }

    func addModel(_ model: AIModel, for type: ModelType) {
        switch type {
        case .chat:
            chatModels.append(model)
        case .image:
            imageModels.append(model)
        // Add more cases here as you add more model types
        }
    }

    func removeModel(_ model: AIModel, for type: ModelType) {
        switch type {
        case .chat:
            chatModels.removeAll { $0.id == model.id }
        case .image:
            imageModels.removeAll { $0.id == model.id }
        // Add more cases here as you add more model types
        }
    }
}
