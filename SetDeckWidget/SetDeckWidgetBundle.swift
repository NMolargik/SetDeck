//
//  SetDeckWidgetBundle.swift
//  SetDeckWidget
//
//  Created by Nick Molargik on 12/2/25.
//

import WidgetKit
import SwiftUI

@main
struct SetDeckWidgetBundle: WidgetBundle {
    var body: some Widget {
        WaterWidgetOZ()
        WaterWidgetLiter()
        EnergyWidget()
    }
}
