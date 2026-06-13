//
//  ImageCache.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 2/23/25.
//


import UIKit

/// A simple in-memory image cache using NSCache.
final class ImageCache {
    static let shared = ImageCache()
    private init() {}

    /// The underlying cache. Key = the image URL, Value = the image data
    private let cache = NSCache<NSURL, UIImage>()

    /// Retrieve an image from cache if present.
    func image(for url: NSURL) -> UIImage? {
        cache.object(forKey: url)
    }

    /// Store an image in the cache.
    func store(_ image: UIImage, for url: NSURL) {
        cache.setObject(image, forKey: url)
    }
}
