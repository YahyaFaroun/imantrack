//
//  ImanTrackerTests.swift
//  ImanTrackerTests
//
//  Created by Yahya Faroun on 21.04.26.
//

import Testing
import UIKit
@testable import ImanTrack

struct ImanTrackerTests {

    @Test func logFonts() async throws {
        print("--- START REGISTERED FONTS ---")
        for family in UIFont.familyNames {
            let names = UIFont.fontNames(forFamilyName: family)
            for name in names {
                print("Font: \(name) (Family: \(family))")
            }
        }
        print("--- END REGISTERED FONTS ---")
    }

}
