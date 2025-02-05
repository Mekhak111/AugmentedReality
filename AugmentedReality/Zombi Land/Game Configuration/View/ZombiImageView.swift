//
//  ZombiImageView.swift
//  AugmentedReality
//
//  Created by Mekhak Ghapantsyan on 2/3/25.
//

import SwiftUI
import AVFoundation

struct ZombiImageView: View {
  
  @State private var audioPlayer: AVAudioPlayer?
  var restartComplition:()->()
  
  var body: some View {
    ZStack {
      Image(.zombiBackground)
      
        .resizable()
        .ignoresSafeArea()
        .scaledToFill()
      VStack {
        Text("YOU LOST")
          .font(.largeTitle)
          .fontWeight(.bold)
          .foregroundColor(.red)
        Spacer()
        Button(action: {
          restartComplition()
        }) {
          Text("Restart")
            .font(.title2)
            .fontWeight(.semibold)
            .padding()
            .frame(maxWidth: 200)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(radius: 5)
        }
      }
      
    }
    .onAppear {
      playSound()
    }
    .onDisappear {
      audioPlayer = nil
    }
  }
  
  private func playSound() {
    guard let soundURL = Bundle.main.url(forResource: "zombi_screaming", withExtension: "wav") else {
      print("Audio file not found")
      return
    }
    
    do {
      audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
      audioPlayer?.play()
    } catch {
      print("Failed to play sound: \(error.localizedDescription)")
    }
  }
  
}

#Preview {
  ZombiImageView(restartComplition: {
    print("Restart")
  })
}
