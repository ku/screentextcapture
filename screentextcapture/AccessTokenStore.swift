//
//  AccessTokenStore.swift
//  screentextcapture
//
//  Created by ku on 2020/06/07.
//  Copyright © 2020 ku. All rights reserved.
//

import Foundation

import AppAuth

private let kIssuer = "https://accounts.google.com/"
private let kSuccessURLString = "http://openid.github.io/AppAuth-iOS/redirect/"
private let kRedirectURI = "https://localhost/"

class AccessTokenStore: NSObject {
    typealias AccessToken = String

    enum AccountType: String {
        case oAuth
        case rawToken
    }

    private var redirectHandler: RedirectHTTPHandler?
    private var state: OIDAuthState?

    enum TokenError: Swift.Error {
        case deallocated
        case stateIsNil
        case invalidToken
        case invalidResponse
        case networkError(Error)
        case decodingError(String)
    }

    override init() {
        super.init()
        state = KeyStore().getAuthState()
    }

    var accountType: AccountType {
        get {
            guard let typeString = UserDefaults.standard.string(forKey: "AccountType"),
                let type = AccountType(rawValue: typeString) else {
                    return .oAuth
            }
            return type
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "AccountType")
            UserDefaults.standard.synchronize()
        }
    }

    var hasValidToken: Bool {
        return false
    }

    func perform(action: @escaping (Result<AccessToken, Error>) -> Void) {
        guard let state = state else {
            authorize(completion: action)
            return
        }

        state.performAction { (accessToken, idToken, error) in
            if let error = error {
                action(.failure(error: error))
                return
            }
            guard let accessToken = accessToken else {
                action(.failure(error: TokenError.invalidToken))
                return
            }
            action(.success(value: accessToken))
        }
    }

    private func authorize(completion: @escaping (Result<AccessToken, Error>) -> Void) {
        let handler = RedirectHTTPHandler(successURL: URL(string: kSuccessURLString))
        let redirectUri = handler.startHTTPListener(nil)
        self.redirectHandler = handler

        OIDAuthorizationService.discoverConfiguration(
            forIssuer: URL(string: kIssuer)!,
            completion: { [weak self] configuration, error in
                guard let strongSelf = self else {
                    completion(.failure(error: TokenError.deallocated))
                    return
                }

                guard let configuration = configuration else {
                    print("configuration not found", error?.localizedDescription ?? "")
                    return
                }

                strongSelf.found(configuration: configuration, redirectURI: redirectUri, completion: completion)
        })
    }

    private func found(configuration: OIDServiceConfiguration, redirectURI: URL, completion: @escaping (Result<AccessToken, Error>) -> Void) {
        let request = OIDAuthorizationRequest(
            configuration: configuration,
            clientId: Environment.kGcpClientId, clientSecret: Environment.kGcpClientSecret,
            scopes: [
                "https://www.googleapis.com/auth/userinfo.email",
                "https://www.googleapis.com/auth/cloud-vision"
            ],
            redirectURL: redirectURI,
            responseType: "code", additionalParameters: nil)

        redirectHandler?.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, callback: { [weak self] state, error in
            guard let strongSelf = self else {
                completion(.failure(error: TokenError.deallocated))
                return
            }
            if let error = error {
                completion(.failure(error: error))
            }
            guard let state = state else {
                completion(.failure(error: TokenError.stateIsNil))
                return
            }
            guard let accessToken = state.lastTokenResponse?.accessToken else {
                completion(.failure(error: TokenError.invalidResponse))
                return
            }

            strongSelf.save(state: state)
            completion(.success(value: accessToken))
        })
    }

    private func save(state: OIDAuthState) {
        KeyStore().saveAuthState(state)
        self.state = state
    }

    struct GoogleProfile: Decodable {
        let sub: String
        let picture: String
        let email: String
        let email_verified: Bool
        let hd: String
    }

    func userInfo(completion: @escaping (Result<GoogleProfile, TokenError>) -> Void) {
        guard let url = state?.lastAuthorizationResponse.request.configuration.discoveryDocument?.userinfoEndpoint else {
            completion(.failure(error: .stateIsNil))
            return
        }

        state?.performAction(freshTokens: { accessToken, idToken, error in
            guard let accessToken = accessToken else { return }

            var request = URLRequest(url: url)
            request.addValue("Bearer \( accessToken )", forHTTPHeaderField: "Authorization")

            let session = URLSession(configuration: URLSessionConfiguration.default)
            let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(.failure(error: .networkError(error)))
                        return
                    }

                    if let response = response as? HTTPURLResponse,
                        response.statusCode == 200,
                        let data = data {
                        do {
                            let profile = try JSONDecoder().decode(GoogleProfile.self, from: data)
                            completion(.success(value: profile))
                        } catch {
                            let responseText = String(data: data, encoding: .utf8) ?? ""
                            completion(.failure(error: .decodingError(responseText)))
                        }
                    } else {
                        completion(.failure(error: TokenError.invalidResponse))
                    }
                }
            }
            task.resume()
        })
    }
}



extension AccessTokenStore: OIDAuthStateChangeDelegate {
    func didChange(_ state: OIDAuthState) {
        print("new state", state)
    }


}
//extension AccessTokenStore: OIDAuthStateErrorDelegate {
//    func authState(_ state: OIDAuthState, didEncounterAuthorizationError error: Error) {
//
//    }
//
//    func authState(_ state: OIDAuthState, didEncounterAuthorizationError error: Error) {
//        print(error)
//    }
//}
//
