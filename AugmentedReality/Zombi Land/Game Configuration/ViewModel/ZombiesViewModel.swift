//
//  ZombiesViewModel.swift
//  AugmentedReality
//
//  Created by Mekhak Ghapantsyan on 1/24/25.
//

import Foundation
import RealityKit

final class ZombiesViewModel: ObservableObject {
  
  @Published var modelEntities: [Entity] = []
  @Published var anchor: AnchorEntity?
  
  let positions: [SIMD3<Float>] = [
    [0, 0, -12],
    [-2, 0, -12],
    [2, 0, -12],
    [0, 0, -14],
    [-1, 0, -14],
    [1, 0, -14],
    [-3, 0, -12],
    [3, 0, -12],
    [-4, 0, -14],
    [4, 0, -14]
  ]
  
  func playAnimation(for entity: Entity) {
    if let animation = entity.availableAnimations.first {
      entity.playAnimation(animation.repeat(), transitionDuration: 0.3)
      let targetPosition = SIMD3<Float>(0, 0, -0.1)
      entity.move(to: Transform(scale: entity.transform.scale,
                                rotation: entity.transform.rotation,
                                translation: targetPosition),
                  relativeTo: entity.parent,
                  duration: 15.0)
    } else {
      print("Animation not found.")
    }
  }
  
}
