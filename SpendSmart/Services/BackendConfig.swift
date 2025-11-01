//
//  BackendConfig.swift
//  SpendSmart
//
//  Created by SpendSmart Team on 2025-07-29.
//

import Foundation

/// Manages backend configuration and URL detection
class BackendConfig {
    static let shared = BackendConfig()
    
    // Backend URLs
    private let localhostURL = "http://localhost:3000"
    private let productionURL = "https://spend-smart-backend-iota.vercel.app"
    
    private init() {}
    
    /// Determines if we're in development mode
    var isDevelopment: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    /// Checks if localhost is reachable
    private func isLocalhostReachable() async -> Bool {
        guard let url = URL(string: "\(localhostURL)/health") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 2.0 // Short timeout for quick check
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200 || httpResponse.statusCode == 404 // 404 means server is reachable
            }
        } catch {
            return false
        }
        
        return false
    }
    
    /// Returns the active backend URL (checks localhost first in debug mode)
    var activeBackendURL: String {
        get async {
            if isDevelopment {
                // In development, try localhost first
                let isReachable = await isLocalhostReachable()
                return isReachable ? localhostURL : productionURL
            } else {
                // In production, always use production URL
                return productionURL
            }
        }
    }
    
    /// Returns whether currently using localhost
    var isUsingLocalhost: Bool {
        get async {
            if isDevelopment {
                let isReachable = await isLocalhostReachable()
                return isReachable
            }
            return false
        }
    }
}

