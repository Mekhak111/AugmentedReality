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
  @State var  isStarted: Bool = false
  @State var loaction: (Float, Float) = (0,0)
  let group = ModelSortGroup(depthPass: .prePass)
  
  var body: some View {
    if zombiesViewModel.lostTheGame {
      ZombiImageView(restartComplition: {
        restart()
      })
    } else {
      playingContent
        .onTapGesture {
          guard let content = content else { return }
          let magnitude: Float = 1000.0
          let pos = getCameraForwardVector(camera: cameraAnchor!)
          let bullet = zombiesViewModel.shoot(from: zombiesViewModel.bulletTarget!.position(relativeTo: nil))
          bullet.name = "Bullet"
          bullet.model?.materials.append(OcclusionMaterial())
          self.bullet = bullet
          content.add(bullet)
          zombiesViewModel.applyForce(to: bullet, direction: pos, magnitude: magnitude)
          if let animation = zombiesViewModel.gunModel?.availableAnimations.first {
            zombiesViewModel.gunModel?.playAnimation(animation, transitionDuration: 0.02)
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
    let position = zombiesViewModel.getPosition()
    self.loaction = (position.x, position.y)
    modelInstance.position = position
    if position.y > 0 {
      let rotation = simd_quatf(angle: .pi/2 , axis: [1, 0, 0])
      modelInstance.transform.rotation = rotation
    } else {
      let rotationY = simd_quatf(angle: .pi/2 , axis: [1, 0, 0])
      let rotataionX = simd_quatf(angle: .pi , axis: [0, 1, 0])
      modelInstance.transform.rotation = rotationY * rotataionX
      
    }

    planeModel?.addChild(modelInstance)
    zombiesViewModel.playAnimation(for: modelInstance)
  }
  
  func restart() {
    isStarted = false
    currentZombi = nil
    zombiesLife = 1.0
    zombiesViewModel.lostTheGame = false
    zombiesViewModel.level = .easy
    zombiesViewModel.resetIndex()
  }
  
}

extension ZombiesRealityView {
  
  private var playingContent: some View {
    ZStack {
      RealityView { content in
        self.content = content
        content.camera = .spatialTracking
        self.planeModel = zombiesViewModel.loadModels(into: content)
        zombiesViewModel.loadGun()
        let camera = AnchorEntity(.camera)
        camera.name = "Camera"
        DispatchQueue.main.async {
          cameraAnchor = camera
        }
        guard let gun = zombiesViewModel.gunModel else { return }
        gun.position = [-0.03,-0.2,-0.4]
        
        camera.addChild(gun)
        
        content.add(camera)
      } update: { content in
        guard let bullet else { return }
        guard let zombi = currentZombi?.entity else { return }
        if zombi.position == SIMD3<Float>(0, -1.3, 0) {
          DispatchQueue.main.async {
            zombiesViewModel.lostTheGame = true
            currentZombi?.entity?.removeFromParent()
            currentZombi?.entity = nil
          }
        }
        let event =  content.subscribe(to: CollisionEvents.Began.self, on: bullet) { cllision in
          if cllision.entityA.name == "scene" || cllision.entityB.name == "scene" {
            bullet.removeFromParent()
            zombiesLife -= 0.5
            if zombiesLife == 0 {
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
        HStack {
          Spacer()
          MapView(locationXY: $loaction)
            .padding()
        }
        Spacer()
        if isStarted {
          levelLabel
        } else {
          startButton
        }
      }
    }
  }
  
  private var startButton: some View {
    Button(action: {
      isStarted = true
      do {
        let baseModel = try ModelEntity.loadModel(named: "Woman.usdz")
        baseModel.scale = [0.01, 0.01, 0.01]
        baseModel.addChild(zombiesViewModel.createSpatialAudio())
        
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
        
        let material = OcclusionMaterial()
        baseModel.model?.materials.append(material)
        currentZombi = ZombieModel(name: "Woman", entity: baseModel, primaryLife: 20, lifeRemaining: .constant(10))
        let position  = zombiesViewModel.getPosition()
        self.loaction = (position.x, position.y)
        baseModel.position = position
        if position.y > 0 {
          let rotation = simd_quatf(angle: .pi/2 , axis: [1, 0, 0])
          baseModel.transform.rotation = rotation
        } else {
          let rotationY = simd_quatf(angle: .pi/2 , axis: [1, 0, 0])
          let rotataionX = simd_quatf(angle: .pi , axis: [0, 1, 0])
          baseModel.transform.rotation = rotationY * rotataionX
          
        }

        planeModel?.addChild(baseModel)
        zombiesViewModel.playAnimation(for: baseModel)
      } catch {
        print("Error loading USDZ model: \(error)")
      }
    }) {
      Text("Start")
        .font(.system(size: 24, weight: .bold, design: .rounded))
        .foregroundStyle(.white)
        .padding(.horizontal, 40)
        .padding(.vertical, 15)
        .background(
          LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: .black.opacity(0.3), radius: 5, x: 3, y: 3)
    }
    .padding()
  }
  
  private var levelLabel: some View {
    Text("Level \(zombiesViewModel.level.description)")
      .font(.system(size: 32, weight: .bold, design: .rounded))
      .foregroundStyle(.linearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
      .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(.ultraThinMaterial)
          .shadow(radius: 5)
      )
      .padding()
  }
  
}

#Preview {
  ZombiesRealityView()
}
