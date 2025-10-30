//
//  FoccaWidgetLiveBundle.swift
//  FoccaWidgetLive
//
//  Created by Fiasco on 30/10/25.
//

import WidgetKit
import SwiftUI

@main
struct FoccaWidgetLiveBundle: WidgetBundle {
    var body: some Widget {
        FoccaWidgetLive()
        FoccaWidgetLiveControl()
        FoccaWidgetLiveLiveActivity()
    }
}
