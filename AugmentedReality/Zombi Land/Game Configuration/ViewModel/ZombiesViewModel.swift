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
  
  @Published var level: Level = .easy
  @Published var gunModel: ModelEntity?
  @Published var lostTheGame: Bool = false
  
  private var bulletModel: ModelEntity?
  private var index: Int = 0
  private let positions: [SIMD3<Float>] = [
    [1, 2, 0],
    [-1, 2, 0],
    [1, 2, 0],
    [0, 3, 0],
    [2, 3, 0],
    [-2, 3, 0],
    [0, 6, 0],
    [4, 6, 0],
    [-4, 6, 0],
  ]
  
  func getPosition() -> SIMD3<Float> {
    if index >= positions.count {
      index = 0
    }
    detectLevel(count: index)
    let pos = positions[index]
    index +=  1
    return pos
  }
  
  func resetIndex() {
    index = 0
  }
  
  func playAnimation(for entity: Entity) {
    if let animation = entity.availableAnimations.first {
      entity.playAnimation(animation.repeat(), transitionDuration: 0.3)
      let targetPosition = SIMD3<Float>(0, -1, 0)
      entity.move(
        to: Transform(
          scale: entity.transform.scale,
          rotation: entity.transform.rotation,
          translation: targetPosition
        ),
        relativeTo: entity.parent,
        duration: level.rawValue
      )
      entity.generateCollisionShapes(recursive: true)
    } else {
      print("Animation not found.")
    }
  }
  
  func loadGun() {
    do {
      let gunModel = try ModelEntity.loadModel(named: "fireGun")
      gunModel.name = "Gun"
      let rotationY = simd_quatf(angle: .pi, axis: [0, 1, 0])
      gunModel.transform.rotation = rotationY
      self.gunModel = gunModel
    } catch {
      print("Failed to Load Gun with error \(error)")
    }
            
  }
  
  func createSpatialAudio() -> Entity {
      let audioSource = Entity()
      audioSource.spatialAudio = SpatialAudioComponent(gain: -5)
      
      audioSource.spatialAudio?.directivity = .beam(focus: 1)
      
      do {
          let resource = try AudioFileResource.load(named: "zombi_walking", configuration: .init(shouldLoop: true))
          audioSource.playAudio(resource)
      } catch {
          print("Error loading audio file: \\(error.localizedDescription)")
      }
      
      return audioSource
  }
  
  func shoot(from position: SIMD3<Float>) -> ModelEntity {
    guard let bulletModel else {
      let bullet = ModelEntity(mesh: .generateSphere(radius: 0.1))
      bullet.position = position
      bullet.physicsBody = PhysicsBodyComponent(
        massProperties: .default,
        material: .default,
        mode: .dynamic
      )
      if let textureResource = try? TextureResource.load(named: "bullet_texture")  {
        bullet.model?.materials = [
          UnlitMaterial(texture: textureResource)
        ]
      }
      bullet.generateCollisionShapes(recursive: true)
      bulletModel = bullet.clone(recursive: true)
      
      return bullet
    }
    let clone = bulletModel.clone(recursive: true)
    clone.position = position
    return clone
    
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
    let planeModel = ModelEntity(
      mesh: .generatePlane(
        width: 20,
        height: 20
      )
    )
    let planeMaterial = SimpleMaterial(
      color: .clear,
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
    return planeModel
  }
  
  private func detectLevel(count: Int) {
    let divisioner = positions.count/3
    switch count {
    case 0..<divisioner:
      level = .easy
    case divisioner..<2*divisioner:
      level = .medium
    case divisioner..<3*divisioner:
      level = .hard
    default:
      level = .easy
    }
  }
  
}
