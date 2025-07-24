//
//  Item.swift
//  EEG EQUIPMENT ASSIST
//
//  Created by Abhay Kadambi on 7/23/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
