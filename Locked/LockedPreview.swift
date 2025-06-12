//
//  LockedPreview.swift
//  Locked
//
//  Created by Brandon Scott on 2025-06-11.
//

import Foundation
import SwiftUI

struct LockedPreview: PreviewProvider {
    static var previews: some View {
        LockedView()
            .environmentObject(AppLocker())
            .environmentObject(ProfileManager())
    }
}
