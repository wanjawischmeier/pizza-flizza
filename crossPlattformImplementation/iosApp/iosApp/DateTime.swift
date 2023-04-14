//
//  DateTime.swift
//  iosApp
//
//  Created by Wanja Wischmeier on 14.04.23.
//  Copyright © 2023 wanjawischmeier. All rights reserved.
//

import Foundation
import shared

class DateTimeUtility {
    static func initPlatform() {
        Time.companion.timeImplementation = getTimeIntervalSince1970
    }
    
    static func getTimeIntervalSince1970() -> KotlinDouble {
        return KotlinDouble(double: Date().timeIntervalSince1970.magnitude)
    }
}
