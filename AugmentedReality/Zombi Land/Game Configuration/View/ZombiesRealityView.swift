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
  
  var body: some View {
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
        
        print("Zombi is in \(zombi.position) ")
        print("Gun is in \(zombiesViewModel.gunModel?.position) ")
        
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
        Spacer()
        if isStarted {
          levelLabel
        } else {
          startButton
        }
      }
    }
    .onTapGesture {
      guard let content = content else { return }
      let magnitude: Float = 1000.0
      let pos = getCameraForwardVector(camera: cameraAnchor!)
      let bullet = zombiesViewModel.shoot(from: pos )
      bullet.name = "Bullet"
      bullet.model?.materials.append(OcclusionMaterial())
      self.bullet = bullet
      content.add(bullet)
      zombiesViewModel.applyForce(to: bullet, direction: pos, magnitude: magnitude)
      if let animation = zombiesViewModel.gunModel?.availableAnimations.first {
        zombiesViewModel.gunModel?.playAnimation(animation, transitionDuration: 0.02)
      }
      
    }
    //TODO: - Handle Losing point
//    .onChange(of: currentZombi?.entity?.position) { oldValue, newValue in
//      
//      guard let zombi = currentZombi?.entity?.position else { return }
//      guard let gun = zombiesViewModel.gunModel?.position else { return }
//      print(zombi.x - gun.x)
//      print(zombi.y - gun.y)
//      print(zombi.z - gun.z)
//    }
  
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

extension ZombiesRealityView {
  
  private var startButton: some View {
    Button(action: {
      isStarted = true
      do {
        let baseModel = try ModelEntity.loadModel(named: "Woman.usdz")
        baseModel.scale = [0.01, 0.01, 0.01]
        baseModel.transform.rotation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        
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
        currentZombi = ZombieModel(name: "Woman", entity: baseModel, primaryLife: 20, lifeRemaining: .constant(10))
        baseModel.position = zombiesViewModel.getPosition()
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
