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
    private func fetchServiceToken(completion: @escaping (Result<(token: String, refreshToken: String), Error>) -> Void) {
        guard let config = self.config else {
            completion(.failure(NSError(domain: "PulseMetrics", code: -1, userInfo: [NSLocalizedDescriptionKey: "Configuration not set"])))
            return
        }
        
        var request = URLRequest(url: config.oauthTokenURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(config.authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                completion(.failure(NSError(domain: "PulseMetrics", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error: \(statusCode)"])))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "PulseMetrics", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let tokenResponse = try decoder.decode(OAuthTokenResponse.self, from: data)
                self.serviceToken = tokenResponse.token
                self.refreshToken = tokenResponse.refreshToken
                completion(.success((tokenResponse.token, tokenResponse.refreshToken)))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
} 