//
//  WorkoutWidgetBundle.swift
//  WorkoutWidget
//

import WidgetKit
import SwiftUI

@main
struct WorkoutWidgetBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            WorkoutWidgetLiveActivity()
        }
    }
}
