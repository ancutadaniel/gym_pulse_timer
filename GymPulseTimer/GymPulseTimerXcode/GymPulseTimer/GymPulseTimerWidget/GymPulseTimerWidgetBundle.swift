//
//  GymPulseTimerWidgetBundle.swift
//  GymPulseTimerWidget
//
//  Created by web3bit on 26.01.26.
//

import WidgetKit
import SwiftUI

@main
struct GymPulseTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        GymPulseTimerWidget()
        GymPulseTimerLiveActivityWidget()
    }
}
