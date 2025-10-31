//
//  FoccaWidgetLiveAttributes.swift
//  FoccaWidgetLive
//
//  Created by iamjoaovytor on 30/10/25.
//

import Foundation
import ActivityKit

public struct FoccaWidgetLiveAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var startDate: Date
        public var isActive: Bool

        public init(startDate: Date, isActive: Bool) {
            self.startDate = startDate
            self.isActive = isActive
        }
    }

    public init() {}
}
