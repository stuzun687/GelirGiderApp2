//
//  Item.swift
//  GelirGiderApp2
//
//  Created by Semih Tüzün on 9.01.2025.
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
