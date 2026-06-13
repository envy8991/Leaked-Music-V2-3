//
//  TrackMetadata.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 2/27/25.
//


import Foundation
import UIKit

struct TrackMetadata: Equatable {
    let fileURL: URL
    let title: String
    let artist: String
    let albumTitle: String
    let artwork: UIImage?
}