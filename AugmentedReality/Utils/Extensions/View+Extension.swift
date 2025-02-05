//
//  View+Extension.swift
//  AugmentedReality
//
//  Created by Mekhak Ghapantsyan on 2/5/25.
//

import Foundation
import SwiftUI

extension View {
  
  func onLoad(perform action: (() -> Void)? = nil) -> some View {
    modifier(ViewDidLoadModifier(perform: action))
  }
  
}
