//
//  ZombiesViewModel.swift
//  AugmentedReality
//
//  Created by Mekhak Ghapantsyan on 1/24/25.
//

import Foundation
import RealityKit
import RealityFoundation
import _RealityKit_SwiftUI

final class ZombiesViewModel: ObservableObject {
  
  @Published var modelEntities: [Entity] = []
  @Published var anchor: AnchorEntity?
  @Published var zombies: [ZombieModel] = []
  
  let positions: [SIMD3<Float>] = [
    [0, 3, 0],
    //    [-2, 0, -12],
    //    [2, 0, -12],
    //    [0, 0, -14],
    //    [-1, 0, -14],
    //    [1, 0, -14],
    //    [-3, 0, -12],
    //    [3, 0, -12],
    //    [-4, 0, -14],
    //    [4, 0, -14]
  ]
  
  func playAnimation(for entity: Entity) {
    if let animation = entity.availableAnimations.first {
      entity.playAnimation(animation.repeat(), transitionDuration: 0.3)
      let targetPosition = SIMD3<Float>(0, 0, 0)
      entity.move(
        to: Transform(
          scale: entity.transform.scale,
          rotation: entity.transform.rotation,
          translation: targetPosition
        ),
        relativeTo: entity.parent,
        duration: 15.0
      )
      entity.generateCollisionShapes(recursive: true)
    } else {
      print("Animation not found.")
    }
  }
  
  func killZombi(_ entity: ModelEntity) {
    entity.removeFromParent()
  }
  
  func shoot(from position: SIMD3<Float>) -> ModelEntity {
    let bullet = ModelEntity(mesh: .generateSphere(radius: 0.1))
    bullet.position = position
    bullet.model?.materials = [
      SimpleMaterial(color: .black, isMetallic: true)
    ]
    bullet.physicsBody = PhysicsBodyComponent(
      massProperties: .default,
      material: .default,
      mode: .dynamic
    )
    bullet.generateCollisionShapes(recursive: true)
    
    return bullet
  }
  
  func applyForce(to entity: ModelEntity, direction: SIMD3<Float>, magnitude: Float) {
    guard let _ = entity.physicsBody else {
      print("Physics body not found.")
      return
    }
    let force = direction * magnitude
    entity.addForce(force, relativeTo: entity.parent)
  }
  
  func loadModels(
    into content: RealityViewCameraContent
  ) -> ModelEntity {
    let newAnchor = AnchorEntity(
      .plane(
        .horizontal,
        classification: [.floor, .table],
        minimumBounds: [2, 2]
      )
    )
    let planeModel = ModelEntity(
      mesh: .generatePlane(
        width: 8,
        height: 8
      )
    )
    let planeMaterial = SimpleMaterial(
      color: .red,
      isMetallic: false
    )
    planeModel.model?.materials = [planeMaterial, OcclusionMaterial()]
    planeModel.transform.rotation = simd_quatf(
      angle: -.pi / 2,
      axis: [1, 0, 0]
    )
    planeModel.physicsBody = PhysicsBodyComponent(
      massProperties: .default,
      material: .default,
      mode: .static
    )
    planeModel.position = [0,-1,-2]
    planeModel.generateCollisionShapes(recursive: true)
    content.add(planeModel)
    anchor = newAnchor
    return planeModel
  }
  
  //MARK: - To Be Done
  //  func applyForceFromCamera(to entity: ModelEntity, cameraTransform: Transform, magnitude: Float) {
  //    guard let _ = entity.physicsBody else {
  //      print("Physics body not found.")
  //      return
  //    }
  //    let direction = cameraTransform.matrix.forwardVector * magnitude
  //    entity.addForce(direction, relativeTo: nil)
  //  }
  
}
