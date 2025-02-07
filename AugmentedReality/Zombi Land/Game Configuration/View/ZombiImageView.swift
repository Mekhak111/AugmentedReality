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
      Image(.yodaBackgroud)
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
  }
  
}

#Preview {
  ZombiImageView(restartComplition: {
    print("Restart")
  })
}
