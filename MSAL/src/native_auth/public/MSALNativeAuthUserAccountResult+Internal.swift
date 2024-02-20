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

extension MSALNativeAuthUserAccountResult {

    func getAccessTokenInternal(
        forceRefresh: Bool,
        correlationId: UUID?,
        cacheAccessor: MSALNativeAuthCacheInterface
    ) async -> MSALNativeAuthCredentialsControlling.RefreshTokenCredentialControllerResponse {
        let context = MSALNativeAuthRequestContext(correlationId: correlationId)
        let correlationId = context.correlationId()

        if let accessToken = self.authTokens.accessToken {
            if forceRefresh || accessToken.isExpired() {
                let controllerFactory = MSALNativeAuthControllerFactory(config: configuration)
                let credentialsController = controllerFactory.makeCredentialsController(cacheAccessor: cacheAccessor)
                return await credentialsController.refreshToken(context: context, authTokens: authTokens)
            } else {
                return .init(.success(accessToken.accessToken), correlationId: correlationId)
            }
        } else {
            MSALLogger.log(level: .error, context: context, format: "Retrieve Access Token: Existing token not found")
            return .init(.failure(RetrieveAccessTokenError(type: .tokenNotFound, correlationId: correlationId)), correlationId: correlationId)
        }
    }
}