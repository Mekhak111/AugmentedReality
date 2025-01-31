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
  @State var index: Int = 0
  @State var cameraAnchor: AnchorEntity?
  
  var body: some View {
    ZStack {
      RealityView { content in
        self.content = content
        content.camera = .spatialTracking
        if zombiesViewModel.anchor == nil {
          self.planeModel = zombiesViewModel.loadModels(into: content)
        }
      } update: { content in
        let camera = AnchorEntity(.camera)
        camera.name = "Camera"
        DispatchQueue.main.async {
          cameraAnchor = camera
        }
        content.add(camera)
        guard let bullet else { return }
        let event =  content.subscribe(to: CollisionEvents.Began.self, on: bullet) { cllision in
          if cllision.entityA.name == "scene" || cllision.entityB.name == "scene" {
            if zombiesLife > 0.1 {
              currentZombi?.lifeRemaining -= 1
              zombiesLife -= 0.1
            } else {
              regenerateZombies()
            }
          }
        }
        DispatchQueue.main.async {
          subs.append(event)
        }
      }
      .ignoresSafeArea(.all)
      VStack {
        ProgressBarView(progress: $zombiesLife)
        Spacer()
        HStack {
          Button("Start") {
            do {
              let baseModel = try ModelEntity.loadModel(
                named: "Woman.usdz"
              )
              baseModel.scale = [0.01, 0.01, 0.01]
              baseModel.transform.rotation = simd_quatf(
                angle: .pi/2,
                axis: [1, 0, 0]
              )
              let bounds = baseModel.visualBounds(relativeTo: nil)
              let originalSize = bounds.extents
              let scaledSize = SIMD3(
                originalSize.x * 0.8,
                originalSize.y * 7,
                originalSize.z * 0.21
              )
              
              let shape = ShapeResource.generateBox(size: scaledSize)
              print(shape.bounds)
              baseModel.components.set(CollisionComponent(shapes: [shape]))
              baseModel.components.set(PhysicsBodyComponent(
                massProperties: .default,
                material: .default,
                mode: .static
              ))
              
              
              let material = OcclusionMaterial()
              baseModel.model?.materials.append(material)
              currentZombi = ZombieModel(name: "Woman",entity: baseModel, primaryLife: 20, lifeRemaining: .constant(10))
              baseModel.position = zombiesViewModel.getPosition()
              planeModel?.addChild(baseModel)
              zombiesViewModel.playAnimation(for: baseModel)
            } catch {
              print("Error loading USDZ model: \(error)")
            }
          }
          .padding()
          Button("Shoot") {
            guard let content = content else { return }
            let magnitude: Float = 1000.0
            let pos = getCameraForwardVector(camera: cameraAnchor!)
            let bullet = zombiesViewModel.shoot(from: pos )
            bullet.name = "Bullet"
            bullet.model?.materials.append(OcclusionMaterial())
            self.bullet = bullet
            content.add(bullet)
            zombiesViewModel.applyForce(to: bullet, direction: pos, magnitude: magnitude)
          }
          .padding()
          
          Text("Level \(zombiesViewModel.level.rawValue)")
        }
      }
    }
  }
  
  func getCameraForwardVector(camera: Entity) -> SIMD3<Float> {
    let cameraOrientation = camera.orientation(relativeTo: nil)
    let forward = cameraOrientation.act(SIMD3<Float>(0, 0, -1))
    return normalize(forward)
  }
  
  func regenerateZombies() {
    self.currentZombi?.entity?.removeFromParent()
    
    zombiesLife = 1.0
    getNewZombie()
  }
  
  func getNewZombie() {
    let modelInstance = currentZombi?.entity?.clone(recursive: true)
    guard let modelInstance else { return }
    currentZombi?.entity = modelInstance
    modelInstance.position = zombiesViewModel.getPosition()
    planeModel?.addChild(modelInstance)
    zombiesViewModel.playAnimation(for: modelInstance)
  }
  
}

#Preview {
  ZombiesRealityView()
}
