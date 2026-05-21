//
//  Item.swift
//  geometry
//
//  Created by Robert Karapetyan on 5/21/26.
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
