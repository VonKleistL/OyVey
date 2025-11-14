//
//  ContentView.swift
//  OyVey
//
//  Created by Luke Edgar on 12/11/2025.
//

import SwiftUI
import WebKit

struct ContentView: View {
    var body: some View {
        TwitchWebView()
            .frame(minWidth: 800, minHeight: 600)
            .background(Color.black)
    }
}

#Preview {
    ContentView()
}
