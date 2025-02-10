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
  @Published var bulletTarget: ModelEntity?
  @Published var lostTheGame: Bool = false
  @Published var yodaModel: ModelEntity?
  
  private var textureResource: TextureResource?
  private var audioFileResource: AudioFileResource?
  private var bulletModel: ModelEntity?
  private var index: Int = 0
  
  init() {
    textureResource = try? TextureResource.load(named: "bullet_texture")
    audioFileResource = try? AudioFileResource.load(named: "zombi_walking", configuration: .init(shouldLoop: true))
    
  }
  
  func getPosition() -> SIMD3<Float> {
    let rangesForX  = [(-9...(-3)), (3...9)]
    let rangesForY =  [(-9...(-4)), (4...9)]
    let selectedRangeforX = rangesForX.randomElement()!
    let selectedRangeforY = rangesForY.randomElement()!
    let x = Float(Int.random(in: selectedRangeforX))
    let y = Float(Int.random(in: selectedRangeforY))
    let z: Float = 0.0
    detectLevel(count: index)
    index += 1
    
    return SIMD3<Float>(x, y, z)
  }
  
  func resetIndex() {
    index = 0
  }
  
  func playAnimation(for entity: Entity) {
    if let animation = entity.availableAnimations.first {
      entity.playAnimation(animation.repeat(), transitionDuration: 0.3)
      let targetPosition = SIMD3<Float>(0, -1.3, 0)
      entity.move(
        to: Transform(
          scale: entity.transform.scale,
          rotation: entity.transform.rotation,
          translation: yodaModel?.position ?? targetPosition
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
      
      let sphereMesh = MeshResource.generateSphere(radius: 0.00001)
      let sphereMaterial = SimpleMaterial(color: .red, isMetallic: false)
      let sphereEntity = ModelEntity(mesh: sphereMesh, materials: [sphereMaterial])
      sphereEntity.position = [0, 0.1, 0.25]
      bulletTarget = sphereEntity
      
      gunModel.addChild(bulletTarget!)
    } catch {
      print("Failed to Load Gun with error \(error)")
    }
    
  }
  
  func createSpatialAudio() -> Entity {
    let audioSource = Entity()
    audioSource.spatialAudio = SpatialAudioComponent(gain: -5)
    audioSource.spatialAudio?.directivity = .beam(focus: 1)
    if let audioFileResource {
      audioSource.playAudio(audioFileResource)
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
      if let  textureResource {
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
      isMetallic: true
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
  
  func loadZombie() -> ModelEntity {
    do {
      
      let baseModel = try ModelEntity.loadModel(named: "Woman.usdz")
      baseModel.scale = [0.01, 0.01, 0.01]
      baseModel.addChild(createSpatialAudio())
      let bounds = baseModel.visualBounds(relativeTo: nil)
      let originalSize = bounds.extents
      let scaledSize = SIMD3(
        originalSize.x * 0.8,
        originalSize.y * 7,
        originalSize.z * 0.21
      )
      
      let shape = ShapeResource.generateBox(size: scaledSize)
      
      baseModel.components.set(CollisionComponent(shapes: [shape]))
      baseModel.components.set(PhysicsBodyComponent(
        massProperties: .default,
        material: .default,
        mode: .static
      ))
      
      
      let colider = ModelEntity(
        mesh: .generateCone(height: 5, radius: 3),
        materials: [SimpleMaterial(
          color: .clear,
          isMetallic: true)]
      )
      colider.name = "zombi"
      colider.position = [0, 5, 0]
      baseModel.addChild(colider)
      let material = OcclusionMaterial()
      baseModel.model?.materials.append(material)
      return baseModel
    } catch {
      print(error)
      return ModelEntity()
    }
  }
  
  func rotate(_ modelInstance: ModelEntity, by position: SIMD3<Float>) {
    if position.y > 0 {
      let rotation = simd_quatf(angle: .pi/2 , axis: [1, 0, 0])
      modelInstance.transform.rotation = rotation
    } else {
      let rotationY = simd_quatf(angle: .pi/2 , axis: [1, 0, 0])
      let rotataionX = simd_quatf(angle: .pi , axis: [0, 1, 0])
      modelInstance.transform.rotation = rotationY * rotataionX
    }
  }
  
  func loadYoda() {
    do {
      let yodaModel = try ModelEntity.loadModel(named: "Baby_Yoda")
      yodaModel.components.set(
        PhysicsBodyComponent(
          massProperties: .default,
          material: .default,
          mode: .static
        )
      )
      yodaModel.name = "Yoda"
      yodaModel.generateCollisionShapes(recursive: true,static: true)
      self.yodaModel = yodaModel
      self.yodaModel?.position = [0,3,0]
    } catch {
      print("Failed to load Yoda, Error: \(error)")
    }
  }
  
  private func detectLevel(count: Int) {
    switch count {
    case 0..<3:
      level = .easy
    case 3..<6:
      level = .medium
    default:
      level = .hard
    }
  }
  
}
