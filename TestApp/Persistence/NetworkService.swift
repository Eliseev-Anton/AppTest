import Foundation
import Alamofire

final class NetworkService {
    static let shared = NetworkService()
    private init() {}

    private let base = "https://jsonplaceholder.typicode.com"

    // MARK: - Fetch Posts
    func fetchPosts(completion: @escaping (Result<[Post], Error>) -> Void) {
        let url = "\(base)/posts"
        AF.request(url).validate().responseData { response in
            switch response.result {
            case .success(let data):
                do {
                    let posts = try JSONDecoder().decode([Post].self, from: data)
                    DispatchQueue.main.async {
                        completion(.success(posts))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Fetch Users
    func fetchUsers(completion: @escaping (Result<[User], Error>) -> Void) {
        let url = "\(base)/users"
        AF.request(url).validate().responseData { response in
            switch response.result {
            case .success(let data):
                do {
                    let users = try JSONDecoder().decode([User].self, from: data)
                    DispatchQueue.main.async {
                        completion(.success(users))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}
