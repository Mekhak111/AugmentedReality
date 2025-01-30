//
//  ZombiesRealityView.swift
//  AugmentedReality
//
//  Created by Mekhak Ghapantsyan on 1/23/25.
//

import SwiftUI
import RealityKit

struct ZombiesRealityView: View {
  
  @StateObject var zombiesViewModel: ZombiesViewModel = ZombiesViewModel()
  @State var content: RealityViewCameraContent?
  @State var planeModel: ModelEntity?
  @State var currentZombi: ZombieModel?
  @State var zombiesLife: CGFloat = 1.0
  @State var bullet: ModelEntity?
  @State private var subs: [EventSubscription] = []
  
  var body: some View {
    ZStack {
      ProgressBarView(progress: $zombiesLife)
        .padding()
      RealityView { content in
        self.content = content
        content.camera = .spatialTracking
        if zombiesViewModel.anchor == nil {
          self.planeModel = zombiesViewModel.loadModels(into: content)
        }
      } update: { content in
        guard let bullet else { return }
        let event =  content.subscribe(to: CollisionEvents.Began.self, on: bullet) { cllision in
          print("Collision Between \(cllision.entityA.name) and \(cllision.entityB.name)")
        }
        DispatchQueue.main.async {
          subs.append(event)
        }
      }
      .ignoresSafeArea(.all)
      HStack {
        Button("Start") {
          zombiesViewModel.modelEntities.forEach { entity in
            zombiesViewModel.playAnimation(for: entity)
          }
        }
        .padding()
        Button("Place zombies") {
          do {
            let baseModel = try ModelEntity.loadModel(
              named: "Woman.usdz"
            )
            baseModel.scale = [0.01, 0.01, 0.01]
            baseModel.generateCollisionShapes(
              recursive: true,
              static: true
            )
            baseModel.physicsBody = PhysicsBodyComponent(
              massProperties: .default,
              material: .default,
              mode: .static
            )
            baseModel.transform.rotation = simd_quatf(
              angle: .pi/2,
              axis: [1, 0, 0]
            )
            let material = OcclusionMaterial()
            baseModel.model?.materials.append(material)
            currentZombi = ZombieModel(name: "Woman",entity: baseModel, primaryLife: 20, lifeRemaining: .constant(10))
            for position in zombiesViewModel.positions {
              let modelInstance = baseModel.clone(recursive: true)
              currentZombi?.entity = modelInstance
              modelInstance.position = position
              planeModel?.addChild(modelInstance)
              zombiesViewModel.modelEntities.append(modelInstance)
            }
          } catch {
            print("Error loading USDZ model: \(error)")
          }
        }
        .padding()
        Button("Shoot") {
          guard let content = content else { return }
          let direction = SIMD3<Float>(0, 0, -1)
          let magnitude: Float = 1000.0
          let bullet = zombiesViewModel.shoot(from: [0, 0.5, 0])
          bullet.name = "Bullet"
          bullet.model?.materials.append(OcclusionMaterial())
          self.bullet = bullet
          content.add(bullet)
          zombiesViewModel.applyForce(to: bullet, direction: direction, magnitude: magnitude)
          if zombiesLife > 0.1 {
            currentZombi?.lifeRemaining -= 1
            zombiesLife -= 0.1
          } else {
            regenerateZombies()
          }
        }
        .padding()
      }
    }
  }
  
  func regenerateZombies() {
    self.currentZombi?.entity?.removeFromParent()
    //TODO: - Implement Logic of new zombies
  }
  
}

#Preview {
  ZombiesRealityView()
}
