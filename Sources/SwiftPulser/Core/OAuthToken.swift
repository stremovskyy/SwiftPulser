import Foundation

private struct OAuthTokenResponse: Codable {
    let refreshToken: String
    let token: String
    
    private enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
        case token = "token"
    }
}
extension PulseMetricsManager {
    func fetchServiceToken(completion: @escaping (Result<(token: String, refreshToken: String), Error>) -> Void) {
        guard let config = self.config else {
            let error = NSError(domain: "PulseMetrics", code: -1, userInfo: [NSLocalizedDescriptionKey: "Configuration not set"])
            print("[PulseMetrics][Error] Configuration not set")
            completion(.failure(error))
            return
        }
        
        var request = URLRequest(url: config.oauthTokenURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(config.authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        print("[PulseMetrics][Request] URL: \(config.oauthTokenURL)")
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else {
                print("[PulseMetrics][Error] Self deallocated before task completion")
                return
            }

            if let error = error {
                print("[PulseMetrics][Error] Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[PulseMetrics][Error] Invalid response type: \(String(describing: response))")
                let error = NSError(domain: "PulseMetrics", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                completion(.failure(error))
                return
            }
            
            print("[PulseMetrics][Response] Status Code: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("[PulseMetrics][Error] Server returned status code \(httpResponse.statusCode)")
                let error = NSError(domain: "PulseMetrics", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"])
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("[PulseMetrics][Error] No data received")
                let error = NSError(domain: "PulseMetrics", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                completion(.failure(error))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let tokenResponse = try decoder.decode(OAuthTokenResponse.self, from: data)
                self.serviceToken = tokenResponse.token
                self.refreshToken = tokenResponse.refreshToken
                print("[PulseMetrics][Success] Token fetched successfully")
                self.persistTokens()
                completion(.success((tokenResponse.token, tokenResponse.refreshToken)))
            } catch {
                print("[PulseMetrics][Error] JSON decoding failed: \(error)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}
