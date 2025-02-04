//
//  ZombieModel.swift
//  AugmentedReality
//
//  Created by Mekhak Ghapantsyan on 1/30/25.
//

import Foundation
import RealityFoundation
import SwiftUI

struct ZombieModel {
  
  let name: String
  weak var entity: ModelEntity?
  var primaryLife: Double
  @Binding var lifeRemaining: CGFloat
  
}
