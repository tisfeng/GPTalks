//
//  SettingsView.swift
//  GPTalks
//
//  Created by Zabir Raihan on 04/07/2024.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettings()
                .padding(.horizontal, 80)
                .frame(width: 700, height: 200)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            #if os(macOS)
            QuickPanelSettings()
                .padding(.horizontal, 80)
                .frame(width: 700, height: 140)
                .tabItem {
                    Label("Quick Panel", systemImage: "bolt.fill")
                }
            #endif
            
            ParameterSettings()
                .padding(.horizontal, 80)
                .frame(width: 700, height: 300)
                .tabItem {
                    Label("Parameters", systemImage: "slider.horizontal.3")
                }
            
            ProviderList()
                .frame(width: 700, height: 400)
                .tabItem {
                    Label("Providers", systemImage: "cpu")
                }
        }
    }
}

#Preview {
    SettingsView()
}
