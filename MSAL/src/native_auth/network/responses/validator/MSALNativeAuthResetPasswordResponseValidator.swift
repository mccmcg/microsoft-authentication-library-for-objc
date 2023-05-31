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

@_implementationOnly import MSAL_Private

protocol MSALNativeAuthResetPasswordResponseValidating {
    func validate(_ result: Result<MSALNativeAuthResetPasswordStartResponse, Error>,
                  with context: MSIDRequestContext) -> MSALNativeAuthResetPasswordStartValidatedResponse
    func validate(_ result: Result<MSALNativeAuthResetPasswordChallengeResponse, Error>,
                  with context: MSIDRequestContext) -> MSALNativeAuthResetPasswordChallengeValidatedResponse
    func validate(_ result: Result<MSALNativeAuthResetPasswordContinueResponse, Error>,
                  with context: MSIDRequestContext) -> MSALNativeAuthResetPasswordContinueValidatedResponse
    func validate(_ result: Result<MSALNativeAuthResetPasswordSubmitResponse, Error>,
                  with context: MSIDRequestContext) -> MSALNativeAuthResetPasswordSubmitValidatedResponse
    func validate(_ result: Result<MSALNativeAuthResetPasswordPollCompletionResponse, Error>,
                  with context: MSIDRequestContext) -> MSALNativeAuthResetPasswordPollCompletionValidatedResponse
}

final class MSALNativeAuthResetPasswordResponseValidator: MSALNativeAuthResetPasswordResponseValidating {

    // MARK: - Start Request

    func validate(_ result: Result<MSALNativeAuthResetPasswordStartResponse, Error>,
                  with context: MSIDRequestContext) -> MSALNativeAuthResetPasswordStartValidatedResponse {
        switch result {
        case .success(let response):
            return handleStartSuccess(response, with: context)
        case .failure(let error):
            return handleStartFailed(error, with: context)
        }
    }

    private func handleStartSuccess(_ response: MSALNativeAuthResetPasswordStartResponse,
                                    with context: MSIDRequestContext) -> MSALNativeAuthResetPasswordStartValidatedResponse {
        if response.challengeType == .redirect {
            return .redirect
        } else if let passwordResetToken = response.passwordResetToken {
            return .success(passwordResetToken: passwordResetToken)
        } else {
            MSALLogger.log(level: .error,
                           context: context,
                           filename: #fileID,
                           lineNumber: #line,
                           function: #function,
                           format: "Error type not expected")

            return .unexpectedError
        }
    }

    private func handleStartFailed(_ error: Error,
                                   with context: MSIDRequestContext) -> MSALNativeAuthResetPasswordStartValidatedResponse {
        guard let apiError = error as? MSALNativeAuthResetPasswordStartResponseError else {
            MSALLogger.log(level: .error,
                           context: context,
                           filename: #fileID,
                           lineNumber: #line,
                           function: #function,
                           format: "Error type not expected")

            return .unexpectedError
        }

        return .error(apiError.error)
    }

    // MARK: - Challenge Request

    func validate(
        _ result: Result<MSALNativeAuthResetPasswordChallengeResponse, Error>,
        with context: MSIDRequestContext
    ) -> MSALNativeAuthResetPasswordChallengeValidatedResponse {
        switch result {
        case .success(let response):
            return handleChallengeSuccess(response, with: context)
        case .failure(let error):
            return handleChallengeError(error, with: context)
        }
    }

    private func handleChallengeSuccess(
        _ response: MSALNativeAuthResetPasswordChallengeResponse,
        with context: MSIDRequestContext
    ) -> MSALNativeAuthResetPasswordChallengeValidatedResponse {
        switch response.challengeType {
        case .redirect:
            return .redirect
        case .password,
             .oob:
            if let displayName = response.challengeTargetLabel,
               let displayType = response.challengeChannel,
               let codeLength = response.codeLength,
               let passwordResetToken = response.passwordResetToken {
                return .success(displayName, displayType, codeLength, passwordResetToken)
            } else {
                MSALLogger.log(level: .info, context: context, format: "Missing expected fields from backend")
                return .unexpectedError
            }
        case .otp:
            MSALLogger.log(level: .info, context: context, format: "ChallengeType not expected")
            return .unexpectedError
        }
    }

    private func handleChallengeError(_ error: Error, with context: MSIDRequestContext) -> MSALNativeAuthResetPasswordChallengeValidatedResponse {
        guard let apiError = error as? MSALNativeAuthResetPasswordChallengeResponseError else {
            MSALLogger.log(level: .info, context: context, format: "Error type not expected")
            return .unexpectedError
        }

        return .error(apiError.error)
    }

    // MARK: - Continue Request

    func validate(
        _ result: Result<MSALNativeAuthResetPasswordContinueResponse, Error>,
        with context: MSIDRequestContext
    ) -> MSALNativeAuthResetPasswordContinueValidatedResponse {
        switch result {
        case .success(let response):
            return handleContinueSuccess(response, with: context)
        case .failure(let error):
            return handleContinueError(error, with: context)
        }
    }

    private func handleContinueSuccess(
        _ response: MSALNativeAuthResetPasswordContinueResponse,
        with context: MSIDRequestContext
    ) -> MSALNativeAuthResetPasswordContinueValidatedResponse {
        return .success(passwordSubmitToken: response.passwordSubmitToken)
    }

    private func handleContinueError(_ error: Error, with context: MSIDRequestContext) -> MSALNativeAuthResetPasswordContinueValidatedResponse {
        guard let apiError = error as? MSALNativeAuthResetPasswordContinueResponseError else {
            MSALLogger.log(level: .error, context: context, format: "continue returned unexpected error type")
            return .unexpectedError
        }

        switch apiError.error {
        case .invalidOOBValue:
            guard let passwordResetToken = apiError.passwordResetToken else {
                MSALLogger.log(level: .error, context: context, format: "password reset token is missing")
                return .unexpectedError
            }

            return .invalidOOB(passwordResetToken: passwordResetToken)
        case .invalidClient,
             .invalidGrant,
             .expiredToken,
             .invalidRequest:
            return .error(apiError.error)
        case .verificationRequired:
            MSALLogger.log(level: .error, context: context, format: "verificationRequired is not supported yet")
            return .unexpectedError
        }
    }

    // MARK: - Submit Request

    func validate(
        _ result: Result<MSALNativeAuthResetPasswordSubmitResponse, Error>,
        with context: MSIDRequestContext
    ) -> MSALNativeAuthResetPasswordSubmitValidatedResponse {
        switch result {
        case .success(let response):
            return handleSubmitSuccess(response, with: context)
        case .failure(let error):
            return handleSubmitError(error, with: context)
        }
    }

    private func handleSubmitSuccess(
        _ response: MSALNativeAuthResetPasswordSubmitResponse,
        with context: MSIDRequestContext
    ) -> MSALNativeAuthResetPasswordSubmitValidatedResponse {
        return .success(
            passwordResetToken: response.passwordResetToken,
            pollInterval: response.pollInterval
        )
    }

    private func handleSubmitError(_ error: Error, with context: MSIDRequestContext) -> MSALNativeAuthResetPasswordSubmitValidatedResponse {
        guard let apiError = error as? MSALNativeAuthResetPasswordSubmitResponseError else {
            MSALLogger.log(level: .error, context: context, format: "submit returned unexpected error type")
            return .unexpectedError
        }

        switch apiError.error {
        case .passwordTooWeak,
             .passwordTooShort,
             .passwordTooLong,
             .passwordRecentlyUsed,
             .passwordBanned:
            return .passwordError(error: apiError.error, passwordSubmitToken: nil) // TODO: pass passwordSubmitToken when it is available
        case .invalidRequest,
             .invalidClient,
             .expiredToken:
            return .error(apiError.error)
        }
    }

    // MARK: - Poll Completion Request

    func validate(
        _ result: Result<MSALNativeAuthResetPasswordPollCompletionResponse, Error>,
        with context: MSIDRequestContext
    ) -> MSALNativeAuthResetPasswordPollCompletionValidatedResponse {
        switch result {
        case .success(let response):
            return handlePollCompletionSuccess(response, with: context)
        case .failure(let error):
            return handlePollCompletionError(error, with: context)
        }
    }

    private func handlePollCompletionSuccess(
        _ response: MSALNativeAuthResetPasswordPollCompletionResponse,
        with context: MSIDRequestContext
    ) -> MSALNativeAuthResetPasswordPollCompletionValidatedResponse {
        return .success(status: response.status)
    }

    private func handlePollCompletionError(_ error: Error, with context: MSIDRequestContext) -> MSALNativeAuthResetPasswordPollCompletionValidatedResponse {
        guard let apiError = error as? MSALNativeAuthResetPasswordPollCompletionResponseError else {
            MSALLogger.log(level: .error, context: context, format: "Poll Completion returned unexpected error type")
            return .unexpectedError
        }

        switch apiError.error {
        case .passwordTooWeak,
             .passwordTooShort,
             .passwordTooLong,
             .passwordRecentlyUsed,
             .passwordBanned:
            return .passwordError(error: apiError.error, passwordSubmitToken: nil) // TODO: pass passwordSubmitToken when it is available
        case .userNotFound,
             .invalidRequest,
             .invalidClient,
             .expiredToken:
            return .error(apiError.error)
        }
    }
}
