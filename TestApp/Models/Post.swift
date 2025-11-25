import Foundation

struct Post: Codable, Sendable {
    let userId: Int
    let id: Int
    let title: String
    let body: String

    var avatarURL: URL? {
      URL(string: "https://i.pravatar.cc/150?u=\(self.id)")
    }
}               
