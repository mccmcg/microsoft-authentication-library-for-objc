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

@objc
public protocol SignInPasswordStartDelegate {
    func onSignInPasswordError(error: SignInPasswordStartError)
    func onSignInCompleted(result: MSALNativeAuthUserAccount)
}

@objc
public protocol SignInStartDelegate {
    func onSignInError(error: SignInStartError)
    func onSignInCodeRequired(newState: SignInCodeRequiredState,
                              sentTo: String,
                              channelTargetType: MSALNativeAuthChannelType,
                              codeLength: Int)
    @objc optional func onSignInPasswordRequired(newState: SignInPasswordRequiredState)
}

@objc
public protocol SignInPasswordRequiredDelegate {
    func onSignInPasswordRequiredError(error: PasswordRequiredError, newState: SignInPasswordRequiredState?)
    func onSignInCompleted(result: MSALNativeAuthUserAccount)
}

@objc
public protocol SignInResendCodeDelegate {
    func onSignInResendCodeError(error: ResendCodeError, newState: SignInCodeRequiredState?)
    func onSignInResendCodeCodeRequired(newState: SignInCodeRequiredState,
                                        sentTo: String,
                                        channelTargetType: MSALNativeAuthChannelType,
                                        codeLength: Int)
}

@objc
public protocol SignInVerifyCodeDelegate {
    func onSignInVerifyCodeError(error: VerifyCodeError, newState: SignInCodeRequiredState?)
    func onSignInCompleted(result: MSALNativeAuthUserAccount)
}
