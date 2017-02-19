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

#import "MSALTokenResponse.h"

@implementation MSALTokenResponse

- (id)initWithData:(NSData *)data error:(NSError *__autoreleasing *)error
{
    if (!(self = [super initWithData:data error:error]))
    {
        return nil;
    }
    
    NSString *atExpiresIn =  self.accessTokenExpiresIn;
    if (atExpiresIn)
    {
        _accessTokenExpiresOn = [NSDate dateWithTimeIntervalSinceNow:-[atExpiresIn doubleValue]];
    }
    
    NSString *idTokenExpiresIn = self.idTokenExpiresIn;
    if (idTokenExpiresIn)
    {
        _idTokenExpiresOn = [NSDate dateWithTimeIntervalSinceNow:-[idTokenExpiresIn doubleValue]];
    }
    
    return self;
}

MSAL_JSON_ACCESSOR(OAUTH2_TOKEN_TYPE, tokenType)
MSAL_JSON_ACCESSOR(OAUTH2_ACCESS_TOKEN, accessToken)
MSAL_JSON_ACCESSOR(OAUTH2_REFRESH_TOKEN, refreshToken)
MSAL_JSON_RW(OAUTH2_SCOPE, scope, setScope)
MSAL_JSON_ACCESSOR(OAUTH2_FAMILY_ID, familyId)
MSAL_JSON_ACCESSOR(OAUTH2_EXPIRES_IN, expiresIn)
MSAL_JSON_ACCESSOR(OAUTH2_EXPIRES_IN, accessTokenExpiresIn)
MSAL_JSON_ACCESSOR(OAUTH2_ID_TOKEN_EXPIRES_IN, idTokenExpiresIn)

@end
