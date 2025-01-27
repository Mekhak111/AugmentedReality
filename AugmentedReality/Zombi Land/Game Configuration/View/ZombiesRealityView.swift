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
  
  var body: some View {
    VStack {
      RealityView { content in
        content.camera = .spatialTracking
        if zombiesViewModel.anchor == nil {
          loadModels(into: content)
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
        
        Button("Stop") {
          zombiesViewModel.modelEntities.forEach { entity in
            entity.stopAllAnimations()
          }
        }
        .padding()
      }
    }
  }
  
  func loadModels(into content: RealityViewCameraContent) {
    let newAnchor = AnchorEntity(
      .plane(
        .horizontal,
        classification: [.floor, .table],
        minimumBounds: [2, 2]
      )
    )
    let planeModel = ModelEntity(
      mesh: .generatePlane(
        width: 6,
        height: 30
      )
    )
    let planeMaterial = SimpleMaterial(
      color: .blue,
      isMetallic: false
    )
    planeModel.model?.materials = [planeMaterial]
    planeModel.transform.rotation = simd_quatf(
      angle: -.pi / 2,
      axis: [1, 0, 0]
    )
    planeModel.physicsBody = PhysicsBodyComponent(
      massProperties: .default,
      material: .default,
      mode: .static
    )
    newAnchor.addChild(planeModel)
    zombiesViewModel.anchor = newAnchor
    
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
        mode: .dynamic
      )
      
      for position in zombiesViewModel.positions {
        let modelInstance = baseModel.clone(recursive: true)
        modelInstance.position = position
        newAnchor.addChild(modelInstance)
        zombiesViewModel.modelEntities.append(modelInstance)
      }
      content.add(newAnchor)
    } catch {
      print("Error loading USDZ model: \(error)")
    }
  }
  
}

#Preview {
  ZombiesRealityView()
}
