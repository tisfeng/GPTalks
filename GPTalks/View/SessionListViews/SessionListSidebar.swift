//
//  SessionListSidebar.swift
//  GPTalks
//
//  Created by Zabir Raihan on 09/07/2024.
//

import SwiftUI

struct SessionListSidebar: View {
    @Environment(SessionVM.self) private var sessionVM
    
    var body: some View {
        @Bindable var sessionVM = sessionVM
        
        SessionSearch("Search", text: $sessionVM.searchText) {
            sessionVM.searchText = ""
        }
        .padding(.horizontal, 10)
        
        SessionListCards()
            .padding(.horizontal, 10)
        
        SessionList(searchString: sessionVM.searchText)
    }
}

#Preview {
    SessionListSidebar()
}
