//
//  MapView.swift
//  AugmentedReality
//
//  Created by Mekhak Ghapantsyan on 2/4/25.
//

import SwiftUI

struct MapView: View {
  
  @Binding var locationXY: (Float, Float)
  
  var body: some View {
    ZStack {
      Circle()
      Rectangle()
        .frame(maxWidth: 3)
        .foregroundStyle(.green)
      Rectangle()
        .frame(maxHeight: 3)
        .foregroundStyle(.green)
      Circle()
        .frame(maxWidth: 8)
        .foregroundStyle(.red)
        .padding(.leading,locationXY.0 > 0 ? 50 : 0)
        .padding(.bottom, locationXY.1 > 0  ? 50 : 0)
        .padding(.trailing, locationXY.0 < 0 ? 50 : 0)
        .padding(.top, locationXY.1 < 0 ? 50 : 0)
    }
    .frame(maxWidth: 100, maxHeight: 100)
  }
  
}

#Preview {
  MapView(locationXY: .constant((10,1)))
}
