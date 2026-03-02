//
//  PulseTrainerApp.swift
//  PulseTrainer
//
//  Created by Kenichi Takahama on 2026/02/26.
//

import SwiftUI
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

@main
struct PulseTrainerApp: App {
    init() {
        AdMobBootstrap.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

private enum AdMobBootstrap {
    static func start() {
        #if canImport(GoogleMobileAds)
        guard let appID = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String,
              !appID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("AdMob disabled: missing GADApplicationIdentifier in Info.plist")
            return
        }
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        #endif
    }
}
