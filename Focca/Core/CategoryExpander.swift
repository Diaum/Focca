//
//  CategoryExpander.swift
//  Focca
//
//  Created by iamjoaovytor on 01/11/25.
//

import Foundation
import FamilyControls
import ManagedSettings

struct CategoryExpander {

    static func blockSelection(_ selection: FamilyActivitySelection, store: ManagedSettingsStore = ManagedSettingsStore()) {

        // Block applications - makes them INVISIBLE (completely hidden from home screen)
        if !selection.applicationTokens.isEmpty {
            let apps = Set(selection.applicationTokens.compactMap { Application(token: $0) })
            store.application.blockedApplications = apps
        }

        // Block categories - Note: categories can only use shield (gray icon with lock)
        // There's no API to make category apps completely invisible
        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
        }

        // Block web domains
        if !selection.webDomainTokens.isEmpty {
            store.shield.webDomains = selection.webDomainTokens
        }
    }

    static func unblockAll(store: ManagedSettingsStore = ManagedSettingsStore()) {
        store.application.blockedApplications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }

    static func totalItemCount(_ selection: FamilyActivitySelection) -> Int {
        return selection.applicationTokens.count +
               selection.categoryTokens.count +
               selection.webDomainTokens.count
    }
}
