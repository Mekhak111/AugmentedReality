//
//  ContentView.swift
//  AugmentedReality
//
//  Created by Mekhak Ghapantsyan on 1/21/25.
//

import SwiftUI
import RealityKit

struct ContentView: View {
  
  @State private var modelEntity: Entity?
  @State private var anchor: AnchorEntity?
  
  var body: some View {
    VStack {
      RealityView { content in
        content.camera = .spatialTracking
        if anchor == nil {
          loadModel(into: content)
        }
      }
      .edgesIgnoringSafeArea(.all)
      HStack {
        Button("Start") {
          modelEntity?.stopAllAnimations()
          playAnimation(named: "global scene animation")
        }
        .padding()
        
        Button("Stop") {
          modelEntity?.availableAnimations.forEach({ anm in
            print(anm.name)
          })
          modelEntity?.stopAllAnimations()
        }
        .padding()
      }
    }
  }
  
  func collectAnimations(from entity: Entity) -> [AnimationResource] {
    var animations = entity.availableAnimations
    for child in entity.children {
      animations.append(contentsOf: collectAnimations(from: child))
    }
    return animations
  }
  
  
  func loadModel(into content: RealityViewCameraContent)  {
    do {
      let loadedEntity = try Entity.load(named: "Woman.usdz")
      modelEntity = loadedEntity
      
      let newAnchor = AnchorEntity(world: .zero)
      loadedEntity.scale = [0.01,0.01,0.01]
      loadedEntity.position = [0,-1,-12]
      newAnchor.addChild(loadedEntity)
      anchor = newAnchor
      
      content.add(newAnchor)
    } catch {
      print("Error loading USDZ model: \(error)")
    }
  }
  
  func playAnimation(named animationName: String) {
    guard let modelEntity else {
      print("Model entity is not loaded.")
      return
    }
    if let animation = modelEntity.availableAnimations.first(where: { $0.name == animationName }) {
      modelEntity.playAnimation(animation.repeat(), transitionDuration: 0.3)
      
      let targetPosition = SIMD3<Float>(0, -1, -2)
      modelEntity.move(to: Transform(scale: modelEntity.transform.scale,
                                     rotation: modelEntity.transform.rotation,
                                     translation: targetPosition),
                       relativeTo: modelEntity.parent,
                       duration: 15.0)
    } else {
      print("Animation '\(animationName)' not found.")
    }
  }
  
}

#Preview {
  ContentView()
}
