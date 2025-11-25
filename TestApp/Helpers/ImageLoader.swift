import UIKit

final class ImageLoader {
    static let shared = ImageLoader()
    private init() {}

    private let cache = NSCache<NSURL, UIImage>()

    func load(url: URL, completion: @escaping (UIImage?) -> Void) {
        if let img = cache.object(forKey: url as NSURL) {
            completion(img)
            return
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, resp, err in
            guard let self = self else { return }
            if let data = data, let image = UIImage(data: data) {
                self.cache.setObject(image, forKey: url as NSURL)
                completion(image)
            } else {
                completion(nil)
            }
        }
        task.resume()
    }
}
