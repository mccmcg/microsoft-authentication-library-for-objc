//
// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

@objcMembers
public final class MSALNativeAuthPublicClientApplication: MSALPublicClientApplication {

    private let controllerFactory: MSALNativeAuthControllerBuildable
    private let inputValidator: MSALNativeAuthInputValidating
    private let internalChallengeTypes: [MSALNativeAuthInternalChallengeType]

    public init(
        configuration config: MSALPublicClientApplicationConfig,
        challengeTypes: MSALNativeAuthChallengeTypes) throws {
        guard let ciamAuthority = config.authority as? MSALCIAMAuthority else {
            throw MSALNativeAuthInternalError.invalidAuthority
        }

        self.internalChallengeTypes =
            MSALNativeAuthPublicClientApplication.getInternalChallengeTypes(challengeTypes)

        let nativeConfiguration = try MSALNativeAuthConfiguration(
            clientId: config.clientId,
            authority: ciamAuthority,
            challengeTypes: internalChallengeTypes
        )

        self.controllerFactory = MSALNativeAuthControllerFactory(config: nativeConfiguration)
        self.inputValidator = MSALNativeAuthInputValidator()

        try super.init(configuration: config)
    }

    public init(
        clientId: String,
        challengeTypes: MSALNativeAuthChallengeTypes,
        rawTenant: String,
        redirectUri: String? = nil) throws {
        let ciamAuthority = try MSALNativeAuthAuthorityProvider()
                .authority(rawTenant: rawTenant)

        self.internalChallengeTypes =
                MSALNativeAuthPublicClientApplication.getInternalChallengeTypes(challengeTypes)
        let nativeConfiguration = try MSALNativeAuthConfiguration(
            clientId: clientId,
            authority: ciamAuthority,
            rawTenant: rawTenant,
            challengeTypes: internalChallengeTypes
        )

        self.controllerFactory = MSALNativeAuthControllerFactory(config: nativeConfiguration)
        self.inputValidator = MSALNativeAuthInputValidator()

        let configuration = MSALPublicClientApplicationConfig(
            clientId: clientId,
            redirectUri: redirectUri,
            authority: ciamAuthority
        )

        try super.init(configuration: configuration)
    }

    init(
        controllerFactory: MSALNativeAuthControllerBuildable,
        inputValidator: MSALNativeAuthInputValidating,
        internalChallengeTypes: [MSALNativeAuthInternalChallengeType]
    ) {
        self.controllerFactory = controllerFactory
        self.inputValidator = inputValidator
        self.internalChallengeTypes = internalChallengeTypes

        super.init()
    }

    // MARK: delegate methods

    /// Sign up a user with a given username and password
    /// - Parameters:
    ///   - username: Username for the new account
    ///   - password: Password to be used for the new account
    ///   - scopes: Permissions you want included in the access token received after sign in flow has completed
    ///   - correlationId: UUID to correlate this request with the server for debugging
    ///   - delegate: Delegate that receives callbacks for the Sign Up flow
    public func signUpUsingPassword(
        username: String,
        password: String,
        attributes: [String: Any]? = nil,
        correlationId: UUID? = nil,
        delegate: SignUpPasswordStartDelegate
    ) {
        guard inputValidator.isInputValid(username) else {
            DispatchQueue.main.async {
                delegate.onSignUpPasswordError(error: SignUpPasswordStartError(type: .invalidUsername))
            }
            return
        }
        guard inputValidator.isInputValid(password) else {
            DispatchQueue.main.async {
                delegate.onSignUpPasswordError(error: SignUpPasswordStartError(type: .invalidPassword))
            }
            return
        }

        let controller = controllerFactory.makeSignUpController()
        let context = MSALNativeAuthRequestContext(correlationId: correlationId)

        Task {
            await controller.signUpStartPassword(
                parameters: .init(
                    username: username,
                    password: password,
                    attributes: attributes ?? [:],
                    context: context
                ),
                delegate: delegate
            )
        }
    }

    /// Sign up a user with a given username
    /// - Parameters:
    ///   - username: Username for the new account
    ///   - attributes: User attributes to be used during account creation
    ///   - correlationId: UUID to correlate this request with the server for debugging
    ///   - delegate: Delegate that receives callbacks for the Sign Up flow
    public func signUp(
        username: String,
        attributes: [String: Any]? = nil,
        correlationId: UUID? = nil,
        delegate: SignUpStartDelegate
    ) {
        guard inputValidator.isInputValid(username) else {
            DispatchQueue.main.async {
                delegate.onSignUpError(error: SignUpStartError(type: .invalidUsername))
            }
            return
        }

        let controller = controllerFactory.makeSignUpController()
        let context = MSALNativeAuthRequestContext(correlationId: correlationId)

        Task {
            await controller.signUpStartCode(
                parameters: .init(
                    username: username,
                    password: nil,
                    attributes: attributes ?? [:],
                    context: context
                ),
                delegate: delegate
            )
        }
    }

    /// Sign in a user with a given username and password
    /// - Parameters:
    ///   - username: Username for the account
    ///   - password: Password for the account
    ///   - scopes: Permissions you want included in the access token received after sign in flow has completed
    ///   - correlationId: UUID to correlate this request with the server for debugging
    ///   - delegate: Delegate that receives callbacks for the Sign In flow
    public func signInUsingPassword(
        username: String,
        password: String,
        scopes: [String]? = nil,
        correlationId: UUID? = nil,
        delegate: SignInPasswordStartDelegate
    ) {
        guard inputValidator.isInputValid(username) else {
            DispatchQueue.main.async {
                delegate.onSignInPasswordError(error: SignInPasswordStartError(type: .invalidUsername))
            }
            return
        }
        guard inputValidator.isInputValid(password) else {
            DispatchQueue.main.async {
                delegate.onSignInPasswordError(error: SignInPasswordStartError(type: .invalidPassword))
            }
            return
        }
        let controller = controllerFactory.makeSignInController()
        let params = MSALNativeAuthSignInWithPasswordParameters(
            username: username,
            password: password,
            context: MSALNativeAuthRequestContext(correlationId: correlationId),
            scopes: scopes)
        Task {
            await controller.signIn(params: params, delegate: delegate)
        }
    }

    /// Sign in a user with a given username
    /// - Parameters:
    ///   - username: Username for the account
    ///   - scopes: Permissions you want included in the access token received after sign in flow has completed
    ///   - correlationId: UUID to correlate this request with the server for debugging
    ///   - delegate: Delegate that receives callbacks for the Sign In flow
    public func signIn(
        username: String,
        scopes: [String]? = nil,
        correlationId: UUID? = nil,
        delegate: SignInStartDelegate
    ) {
        guard inputValidator.isInputValid(username) else {
            DispatchQueue.main.async {
                delegate.onSignInError(error: SignInStartError(type: .invalidUsername))
            }
            return
        }
        let controller = controllerFactory.makeSignInController()
        let params = MSALNativeAuthSignInWithCodeParameters(
            username: username,
            context: MSALNativeAuthRequestContext(correlationId: correlationId),
            scopes: scopes)
        Task {
            await controller.signIn(params: params, delegate: delegate)
        }
    }

    public func resetPassword(
        username: String,
        correlationId: UUID? = nil,
        delegate: ResetPasswordStartDelegate
    ) {
        guard inputValidator.isInputValid(username) else {
            Task {
                await delegate.onResetPasswordError(error: ResetPasswordStartError(type: .invalidUsername))
            }
            return
        }

        let controller = controllerFactory.makeResetPasswordController()
        let context = MSALNativeAuthRequestContext(correlationId: correlationId)

        Task {
            await controller.resetPassword(
                parameters: .init(
                    username: username,
                    context: context
                ),
                delegate: delegate
            )
        }
    }

    public func getNativeAuthUserAccount(correlationId: UUID? = nil) -> MSALNativeAuthUserAccountResult? {
        let controller = controllerFactory.makeCredentialsController()
        let context = MSALNativeAuthRequestContext(correlationId: correlationId)

        return controller.retrieveUserAccountResult(context: context)
    }

    private static func getInternalChallengeTypes(
        _ challengeTypes: MSALNativeAuthChallengeTypes) -> [MSALNativeAuthInternalChallengeType] {
            var internalChallengeTypes = [MSALNativeAuthInternalChallengeType]()

            if challengeTypes.contains(.OOB) {
                internalChallengeTypes.append(.oob)
            }

            if challengeTypes.contains(.password) {
                internalChallengeTypes.append(.password)
            }

            internalChallengeTypes.append(.redirect)
            return internalChallengeTypes
    }
}
