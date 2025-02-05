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
  @State var zombiesModel: ModelEntity?
  @State var currentZombi: ZombieModel?
  @State var zombiesLife: CGFloat = 1.0
  @State var bullet: ModelEntity?
  @State var cameraAnchor: AnchorEntity?
  @State var isStarted: Bool = false
  @State var loaction: (Float, Float) = (0,0)
  
  @State private var subs: [EventSubscription] = []
  private let group = ModelSortGroup(depthPass: .prePass)
  
  var body: some View {
    ZStack {
      playingContent
        .onTapGesture {
          handleTap()
        }
      if zombiesViewModel.lostTheGame {
        ZombiImageView(
          restartComplition: {
            restart()
          })
      }
    }
    .onLoad {
      loadZombi()
    }
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
      getNewZombie()
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
  
  private func loadZombi() {
    let baseModel = zombiesViewModel.loadZombie()
    zombiesModel = baseModel
    currentZombi = ZombieModel(name: "Woman", entity: baseModel)
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
    let modelInstance = zombiesModel?.clone(recursive: true)
    currentZombi = ZombieModel(name: "Woman", entity: modelInstance)
    guard let modelInstance else { return }
    let position = zombiesViewModel.getPosition()
    self.loaction = (position.x, position.y)
    modelInstance.position = position
    zombiesViewModel.rotate(modelInstance, by: position)
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
    loaction = (0,0)
  }
  
  func handleTap() {
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
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      bullet.removeFromParent()
    }
  }
  
}

#Preview {
  ZombiesRealityView()
}
