//
//  ZombiesRealityView.swift
//  AugmentedReality
//
//  Created by Mekhak Ghapantsyan on 1/23/25.
//

import SwiftUI
import RealityKit

struct ZombiesRealityView: View {
  
  @State private var modelEntities: [Entity] = []
  @State private var anchor: AnchorEntity?
  
  var body: some View {
    VStack {
      RealityView { content in
        content.camera = .spatialTracking
        if anchor == nil {
          loadModels(into: content)
        }
      }
      .edgesIgnoringSafeArea(.all)
      HStack {
        Button("Start") {
          modelEntities.forEach { entity in
            playAnimation(named: "global scene animation", for: entity)
          }
        }
        .padding()
        
        Button("Stop") {
          modelEntities.forEach { entity in
            entity.stopAllAnimations()
          }
        }
        .padding()
      }
    }
  }
  
  func loadModels(into content: RealityViewCameraContent) {
    let newAnchor = AnchorEntity(world: .zero)
    anchor = newAnchor
    
    let positions: [SIMD3<Float>] = [
      [0, -1, -12],
      [-2, -1, -12],
      [2, -1, -12],
      [0, -1, -14],
      [-1, -1, -14],
      [1, -1, -14],
      [-3, -1, -12],
      [3, -1, -12],
      [-4, -1, -14],
      [4, -1, -14]
    ]
    
    do {
  
      let baseModel = try Entity.load(named: "Woman.usdz")
      baseModel.scale = [0.01, 0.01, 0.01]
      baseModel.generateCollisionShapes(recursive: true, static: true)
      
      for position in positions {
        let modelInstance = baseModel.clone(recursive: true)
        modelInstance.position = position
        newAnchor.addChild(modelInstance)
        modelEntities.append(modelInstance)
      }
      
      content.add(newAnchor)
    } catch {
      print("Error loading USDZ model: \(error)")
    }
  }
  
  func playAnimation(named animationName: String, for entity: Entity) {
    if let animation = entity.availableAnimations.first(where: { $0.name == animationName }) {
      
      entity.playAnimation(animation.repeat(), transitionDuration: 0.3)
      
      let targetPosition = SIMD3<Float>(0, -1, -1)
      entity.move(to: Transform(scale: entity.transform.scale,
                                rotation: entity.transform.rotation,
                                translation: targetPosition),
                  relativeTo: entity.parent,
                  duration: 15.0)
    } else {
      print("Animation '\(animationName)' not found.")
    }
  }
}

#Preview {
  ZombiesRealityView()
}
