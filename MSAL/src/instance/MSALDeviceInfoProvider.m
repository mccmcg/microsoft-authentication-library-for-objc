//------------------------------------------------------------------------------
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
//
//------------------------------------------------------------------------------

#import "MSALDeviceInfoProvider.h"
#import "MSIDRequestParameters.h"
#import "MSALDefinitions.h"
#import "MSIDSSOExtensionGetDeviceInfoRequest.h"
#import "MSIDRequestParameters+Broker.h"
#import "MSALDeviceInformation+Internal.h"

@implementation MSALDeviceInfoProvider

- (void)deviceInfoWithRequestParameters:(MSIDRequestParameters *)requestParameters
                        completionBlock:(MSALDeviceInformationCompletionBlock)completionBlock API_AVAILABLE(ios(13.0), macos(10.15))
{
    if (![MSIDSSOExtensionGetDeviceInfoRequest canPerformRequest] || ![requestParameters shouldUseBroker])
    {
        NSError *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorBrokerNotAvailable, @"Broker is either not present on this device or not available for this operation", nil, nil, nil, nil, nil, YES);
        completionBlock(nil, error);
        return;
    }
    
    NSError *requestError;
    MSIDSSOExtensionGetDeviceInfoRequest *ssoExtensionRequest = [[MSIDSSOExtensionGetDeviceInfoRequest alloc] initWithRequestParameters:requestParameters
                                                                                                                                  error:&requestError];
    
    if (!ssoExtensionRequest)
    {
        completionBlock(nil, requestError);
        return;
    }
    
    if (![self setCurrentSSOExtensionRequest:ssoExtensionRequest])
    {
        NSError *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Trying to start a get accounts request while one is already executing", nil, nil, nil, nil, nil, YES);
        completionBlock(nil, error);
        return;
    }
    
    [ssoExtensionRequest executeRequestWithCompletion:^(MSIDDeviceInfo * _Nullable deviceInfo, NSError * _Nullable error)
    {
        [self copyAndClearCurrentSSOExtensionRequest];
        
        if (!deviceInfo)
        {
            completionBlock(nil, error);
            return;
        }
        
        MSALDeviceInformation *msalDeviceInfo = [[MSALDeviceInformation alloc] initWithMSIDDeviceInfo:deviceInfo];
        completionBlock(msalDeviceInfo, nil);
    }];
}

@end
