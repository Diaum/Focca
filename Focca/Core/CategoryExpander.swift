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
        if !selection.applicationTokens.isEmpty {
            store.shield.applications = selection.applicationTokens
        }

        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
        }

        if !selection.webDomainTokens.isEmpty {
            store.shield.webDomains = selection.webDomainTokens
        }
    }

    static func unblockAll(store: ManagedSettingsStore = ManagedSettingsStore()) {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }

    static func totalItemCount(_ selection: FamilyActivitySelection) -> Int {
        return selection.applicationTokens.count +
               selection.categoryTokens.count +
               selection.webDomainTokens.count
    }
}
