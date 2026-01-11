//
//  SetDeckWatchWidgetBundle.swift
//  SetDeck Watch Widget
//
//  Created by Nick Molargik on 1/10/26.
//
//  Widget bundle for Watch complications.
//

import WidgetKit
import SwiftUI

@main
struct SetDeckWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        WorkoutComplication()
    }
}
