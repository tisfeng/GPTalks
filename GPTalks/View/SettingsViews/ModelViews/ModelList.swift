//
//  ModelList.swift
//  GPTalks
//
//  Created by Zabir Raihan on 23/07/2024.
//


import SwiftUI

struct ModelListView: View {
    @Environment(\.modelContext) var modelContext
    #if !os(macOS)
    @Environment(\.editMode) var editMode
    #endif
    @Bindable var provider: Provider
    let type: ModelType

    @State var showAdder = false
    @State var selections: Set<AIModel> = []
    @State var searchText = ""
    @State var isRefreshing = false
    
    var body: some View {
        Group {
            #if os(macOS)
            macOSContent
            #else
            iOSContent
            #endif
        }
        .sheet(isPresented: $showAdder) {
            ModelAdder(provider: provider, type: type)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                addButton
            }
        }
        .searchable(text: $searchText, placement: searchPlacement)
//        .searchPresentationToolbarBehavior(.avoidHidingContent) // only does sth on ios
    }
    
    var searchPlacement: SearchFieldPlacement {
        #if os(macOS)
        return .toolbar
        #else
        return .navigationBarDrawer(displayMode: .always)
        #endif
    }
    
    var filteredModels: [AIModel] {
        let models = provider.models(for: type)
        
        let filtered = searchText.isEmpty ? models : models.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.code.localizedCaseInsensitiveContains(searchText) }
        return filtered.sorted { $0.order < $1.order }
    }
}

// MARK: - common foreach
extension ModelListView {
    var collectiom: some View {
        ForEach(filteredModels) { model in
            ModelRow(model: model, provider: provider) {
                reorderModels()
            }
            .tag(model)
            #if os(macOS)
                .contextMenu { contextMenuItems(for: model) }
            #endif
        }
        .onDelete(perform: deleteItems)
        .onMove(perform: moveItems)
        .moveDisabled(!searchText.isEmpty)
    }
}

// MARK: - macOS Specific Views
#if os(macOS)
extension ModelListView {
    var macOSContent: some View {
        Form {
            List(selection: $selections) {
                Section(header: sectionHeader) {
                    collectiom
                }
            }
            .labelsHidden()
            .alternatingRowBackgrounds()
        }
        .formStyle(.grouped)
    }
    
    var sectionHeader: some View {
        HStack(spacing: 0) {
            Text("Show")
                .frame(maxWidth: 42, alignment: .leading)
            Text("Code")
                .frame(maxWidth: 300, alignment: .leading)
            Text("Name")
                .frame(maxWidth: 205, alignment: .leading)
            Text("Test")
                .frame(maxWidth: 35, alignment: .center)
        }
    }
}
#endif

// MARK: - iOS Specific Views
#if !os(macOS)
extension ModelListView {
    var iOSContent: some View {
        List(selection: $selections) {
            collectiom
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                HStack {
                    EditButton()
                    Spacer()
                    if editMode?.wrappedValue == .active {
                        editMenu
                    }
                }
            }
        }
    }
}
#endif

// MARK: - Shared Components
extension ModelListView {
    @ViewBuilder
    var addButton: some View {
        if isRefreshing {
            Button(action: {}) {
                Label("Refreshing", systemImage: "arrow.trianglehead.2.counterclockwise.rotate.90")
            }
            .symbolEffect(.rotate, isActive: isRefreshing)
            .disabled(true)
        } else {
            Menu {
                Button {
                    Task {
                        await refreshModels()
                    }
                } label: {
                    Label("Refresh Models", systemImage: "arrow.trianglehead.2.counterclockwise.rotate.90")
                }
                
                Section {
                    Button(action: { showAdder = true }) {
                        Label("Add Custom Model", systemImage: "plus")
                    }
                }
            } label: {
                Label("Add", systemImage: "plus")
            }
        }
    }
    
    var editMenu: some View {
        Menu {
            Section {
                commonMenuItems(for: Array(selections))
            }
            
            Section {
                Button(action: { selections = Set(filteredModels) }) {
                    Label("Select All", systemImage: "checkmark.circle.fill")
                }
                
                Button(action: { selections.removeAll() }) {
                    Label("Deselect All", systemImage: "xmark.circle")
                }
            }
            
            Section {
                Button(role: .destructive, action: deleteSelectedModels) {
                    Label("Delete Selected", systemImage: "trash")
                }
            }
        } label: {
            Label("Actions", systemImage: "ellipsis.circle")
                .labelStyle(.iconOnly)
        }
    }
    
    func contextMenuItems(for model: AIModel) -> some View {
        commonMenuItems(for: selections.isEmpty ? [model] : Array(selections))
    }
    
    func commonMenuItems(for models: [AIModel]) -> some View {
        Group {
            Button(action: { toggleEnabled(for: models) }) {
                Label("Toggle Enabled", systemImage: "power")
            }
            
            Button(action: { toggleModelType(for: models) }) {
                Label("Toggle Chat/Image", systemImage: "arrow.triangle.2.circlepath")
            }
        }
    }
}


#Preview {
    let provider = Provider.factory(type: .openai)
    
    ModelListView(provider: provider, type: .chat)
}
