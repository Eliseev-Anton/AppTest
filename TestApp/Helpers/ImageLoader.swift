import UIKit

/// Lightweight image loader with in-memory caching.
/// Designed to avoid repeated network requests for avatar images.
final class ImageLoader {
    static let shared = ImageLoader()
    private let cache = NSCache<NSURL, UIImage>()

    /// Asynchronously loads image from URL with caching.
    /// - Parameters:
    ///   - url: Remote image URL.
    ///   - completion: Returns cached or downloaded image.
    func load(url: URL, completion: @escaping (UIImage?) -> Void) {
        
        // Return image instantly if cached
        if let img = cache.object(forKey: url as NSURL) {
            DispatchQueue.main.async { completion(img) }
            return
        }

        // Load image from network
        URLSession.shared.dataTask(with: url) { data, _, _ in
            var image: UIImage? = nil
            
            if let data = data { image = UIImage(data: data) }
            
            // Cache successful result
            if let image = image {
                self.cache.setObject(image, forKey: url as NSURL)
            }
            
            DispatchQueue.main.async { completion(image) }
        }.resume()
    }
}
