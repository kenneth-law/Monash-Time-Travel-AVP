//
//  Monash_Time_Travel_AVPApp.swift
//  Monash Time Travel AVP
//
//  Created by Ken Law on 11/3/2026.
//

import SwiftUI

@main
struct Monash_Time_Travel_AVPApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        #if os(visionOS)
        ImmersiveSpace(id: "game-space", for: MenuScene.self) { selectedScene in
            ImmersiveGameView(selectedScene: selectedScene.wrappedValue ?? .hongKong)
        }
        .immersionStyle(selection: .constant(.full), in: .full)
        #endif
    }
}
