import Foundation
import Alamofire

/// Network layer of the application.
/// Handles API requests to JSONPlaceholder.
/// Uses Alamofire for simplicity and reliability.
final class NetworkService {
    static let shared = NetworkService()
    private init() {}

    private let base = "https://jsonplaceholder.typicode.com"

    // MARK: - Posts
    
    /// Fetches list of posts from API.
    /// - Returns: Parsed array of `Post` or error.
    func fetchPosts(completion: @escaping (Result<[Post], Error>) -> Void) {
        let url = "\(base)/posts"
        
        AF.request(url)
            .validate()
            .responseData { response in
                
                switch response.result {
                case .success(let data):
                    do {
                        let posts = try JSONDecoder().decode([Post].self, from: data)
                        DispatchQueue.main.async { completion(.success(posts)) }
                    } catch {
                        DispatchQueue.main.async { completion(.failure(error)) }
                    }
                    
                case .failure(let error):
                    DispatchQueue.main.async { completion(.failure(error)) }
                }
            }
    }

    // MARK: - Users (optional)
    
    /// Loads user profiles (if needed for future extensions).
    func fetchUsers(completion: @escaping (Result<[User], Error>) -> Void) {
        let url = "\(base)/users"
        
        AF.request(url)
            .validate()
            .responseData { response in
                
                switch response.result {
                case .success(let data):
                    do {
                        let users = try JSONDecoder().decode([User].self, from: data)
                        DispatchQueue.main.async { completion(.success(users)) }
                    } catch {
                        DispatchQueue.main.async { completion(.failure(error)) }
                    }
                    
                case .failure(let error):
                    DispatchQueue.main.async { completion(.failure(error)) }
                }
            }
    }
}
