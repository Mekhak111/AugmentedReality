//
//  ViewDidLoadModifier.swift
//  AugmentedReality
//
//  Created by Mekhak Ghapantsyan on 2/5/25.
//

import SwiftUI

struct ViewDidLoadModifier: ViewModifier {
  
  @State private var didLoad = false
  private let action: (() -> Void)?
  
  init(perform action: (() -> Void)? = nil) {
    self.action = action
  }
  
  func body(content: Content) -> some View {
    content.onAppear {
      if didLoad == false {
        didLoad = true
        action?()
      }
    }
  }
  
}
