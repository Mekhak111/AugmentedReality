//
//  Level.swift
//  AugmentedReality
//
//  Created by Mekhak Ghapantsyan on 1/31/25.
//

import Foundation

enum Level: TimeInterval {
  
  case easy = 10.0, medium = 5.0, hard = 2.0
  
  var description: String {
    switch self {
    case .easy:
      return "Easy"
    case .medium:
      return "Medium"
    case .hard:
      return "Hard"
    }
  }
  
}
