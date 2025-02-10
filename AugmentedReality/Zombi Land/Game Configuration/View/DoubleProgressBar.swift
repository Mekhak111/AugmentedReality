//
//  DoubleProgressBar.swift
//  AugmentedReality
//
//  Created by Mekhak Ghapantsyan on 1/30/25.
//


import SwiftUI

struct ProgressBarView: View {
  
  @Binding var progress: CGFloat
  var colors: [Color]
  
  var body: some View {
    ZStack(alignment: .leading) {
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.gray.opacity(0.3))
        .frame(height: 20)
      RoundedRectangle(cornerRadius: 12)
        .fill(LinearGradient(
          gradient: Gradient(colors: colors),
          startPoint: .leading,
          endPoint: .trailing
        ))
        .frame(width: progress * 300, height: 20)
        .animation(.easeInOut(duration: 0.3), value: progress)
    } 
    .frame(width: 300)
    .padding()
  }
  
}
