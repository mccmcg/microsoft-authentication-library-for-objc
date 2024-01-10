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
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

/// An object of this type is created when a user has reset their password successfully.
@objcMembers public class SignInAfterResetPasswordState: SignInAfterPreviousFlowBaseState {
    /// Sign in the user that just reset the password.
    /// - Parameters:
    ///   - scopes: Optional. Permissions you want included in the access token received after sign in flow has completed.
    ///   - delegate: Delegate that receives callbacks for the Sign In flow.
    public func signIn(scopes: [String]? = nil, delegate: SignInAfterResetPasswordDelegate) {
        Task {
            let controllerResponse = await signInInternal(scopes: scopes)
            let delegateDispatcher = SignInAfterResetPasswordDelegateDispatcher(
                delegate: delegate,
                telemetryUpdate: controllerResponse.telemetryUpdate
            )

            switch controllerResponse.result {
            case .success(let accountResult):
                await delegateDispatcher.dispatchSignInCompleted(result: accountResult)
            case .failure(let error):
                await delegate.onSignInAfterResetPasswordError(error: SignInAfterResetPasswordError(message: error.errorDescription))
            }
        }
    }
}