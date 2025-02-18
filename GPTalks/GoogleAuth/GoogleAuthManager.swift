//
//  GoogleAuthManager.swift
//  GPTalks
//
//  Created by Zabir Raihan on 17/09/2024.
//

import Foundation
import AuthenticationServices

@Observable class GoogleAuthManager: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = GoogleAuthManager()
    
    private(set) var accessToken: String = ""
    private var refreshToken: String = ""
    private var expirationDate: Date = Date()
    
    let clientId = "401645137849-5tlu6a5kai0oav5m498ntbhevm2lvgu1.apps.googleusercontent.com"
    let redirectUri = "com.zabir.GPTalksNew:/oauth2redirect"
    
    private let queue = DispatchQueue(label: "com.zabir.GPTalksNew.tokenmanager")
    private var authenticationSession: ASWebAuthenticationSession?
    
    private override init() {
        super.init()
        loadTokens()
    }
    
    // TODO: must not save tokens in UserDefaults
    private func loadTokens() {
        accessToken = UserDefaults.standard.string(forKey: "accessToken") ?? ""
        refreshToken = UserDefaults.standard.string(forKey: "refreshToken") ?? ""
        expirationDate = UserDefaults.standard.object(forKey: "tokenExpirationDate") as? Date ?? Date()
    }
    
    private func saveTokens() {
        UserDefaults.standard.set(accessToken, forKey: "accessToken")
        UserDefaults.standard.set(refreshToken, forKey: "refreshToken")
        UserDefaults.standard.set(expirationDate, forKey: "tokenExpirationDate")
    }
    
    func clearTokens() {
        queue.async {
            self.accessToken = ""
            self.refreshToken = ""
            self.expirationDate = Date()
            self.saveTokens()
        }
    }
    
    func signIn() async throws {
        let authUrl = URL(string: "https://accounts.google.com/o/oauth2/v2/auth?client_id=\(clientId)&redirect_uri=\(redirectUri)&response_type=code&scope=profile email https://www.googleapis.com/auth/cloud-platform openid")!
        let callbackUrlScheme = "com.zabir.GPTalksNew"
        
        return try await withCheckedThrowingContinuation { continuation in
            authenticationSession = ASWebAuthenticationSession(url: authUrl, callbackURLScheme: callbackUrlScheme) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let callbackURL = callbackURL,
                      let queryItems = URLComponents(string: callbackURL.absoluteString)?.queryItems,
                      let code = queryItems.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: NSError(domain: "TokenManager", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to get authorization code"]))
                    return
                }
                
                Task {
                    do {
                        try await self.exchangeCodeForTokens(authCode: code)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            authenticationSession?.presentationContextProvider = self
            authenticationSession?.start()
        }
    }
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        #if os(macOS)
        return NSApplication.shared.keyWindow ?? ASPresentationAnchor()
        #else
        return UIApplication.shared.windows.first ?? ASPresentationAnchor()
        #endif
    }
    
    var isSignedIn: Bool {
        return !accessToken.isEmpty
    }
    
    private func refreshAccessToken() async throws -> String {
        guard !refreshToken.isEmpty else {
            throw NSError(domain: "TokenManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No refresh token available"])
        }
        
        let url = URL(string: "https://oauth2.googleapis.com/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: String] = [
            "client_id": clientId,
            "client_secret": "",
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ]
        
        let bodyString = parameters.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let jsonResult = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let newAccessToken = jsonResult["access_token"] as? String,
              let expiresIn = jsonResult["expires_in"] as? TimeInterval else {
            throw NSError(domain: "TokenManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }
        
        DispatchQueue.main.async {
            self.accessToken = newAccessToken
            self.expirationDate = Date().addingTimeInterval(expiresIn)
            self.saveTokens()
        }
        
        return newAccessToken
    }
    
    func exchangeCodeForTokens(authCode: String) async throws {
        let url = URL(string: "https://oauth2.googleapis.com/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: String] = [
            "client_id": clientId,
            "client_secret": "",
            "code": authCode,
            "grant_type": "authorization_code",
            "redirect_uri": redirectUri,
            "scope": "https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/cloud-platform openid"
        ]
        
        let bodyString = parameters.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let jsonResult = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let accessToken = jsonResult["access_token"] as? String,
              let refreshToken = jsonResult["refresh_token"] as? String,
              let expiresIn = jsonResult["expires_in"] as? TimeInterval else {
            throw NSError(domain: "TokenManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }
        
        DispatchQueue.main.async {
            self.accessToken = accessToken
            self.refreshToken = refreshToken
            self.expirationDate = Date().addingTimeInterval(expiresIn)
            self.saveTokens()
        }
    }
    
    func getValidAccessToken() async throws -> String {
        if Date().addingTimeInterval(5 * 60) < expirationDate && !accessToken.isEmpty {
            return accessToken
        }
        return try await refreshAccessToken()
    }
}

#if os(iOS)
extension UIViewController: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.view.window ?? ASPresentationAnchor()
    }
}
#elseif os(macOS)
extension NSWindow: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self
    }
}
#endif
