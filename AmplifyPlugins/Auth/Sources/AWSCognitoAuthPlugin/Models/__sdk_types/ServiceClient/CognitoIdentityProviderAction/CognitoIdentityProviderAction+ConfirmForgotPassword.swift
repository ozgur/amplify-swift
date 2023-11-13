//
//  File.swift
//
//
//  Created by Saultz, Ian on 10/27/23.
//

import Foundation
import AWSPluginsCore

extension CognitoIdentityProviderAction where
Input == ConfirmForgotPasswordInput,
Output == ConfirmForgotPasswordOutputResponse {

    /*
     "ConfirmForgotPassword":{
       "name":"ConfirmForgotPassword",
       "http":{
         "method":"POST",
         "requestUri":"/"
       },
       "input":{"shape":"ConfirmForgotPasswordRequest"},
       "output":{"shape":"ConfirmForgotPasswordResponse"},
       "errors":[
         {"shape":"ResourceNotFoundException"},
         {"shape":"UnexpectedLambdaException"},
         {"shape":"UserLambdaValidationException"},
         {"shape":"InvalidParameterException"},
         {"shape":"InvalidPasswordException"},
         {"shape":"NotAuthorizedException"},
         {"shape":"CodeMismatchException"},
         {"shape":"ExpiredCodeException"},
         {"shape":"TooManyFailedAttemptsException"},
         {"shape":"InvalidLambdaResponseException"},
         {"shape":"TooManyRequestsException"},
         {"shape":"LimitExceededException"},
         {"shape":"UserNotFoundException"},
         {"shape":"UserNotConfirmedException"},
         {"shape":"InternalErrorException"},
         {"shape":"ForbiddenException"}
       ],
       "authtype":"none"
     },
     */
    static func confirmForgotPassword(region: String) -> Self {
        .init(
            name: "ConfirmForgotPassword",
            method: .post,
            xAmzTarget: "AWSCognitoIdentityProviderService.ConfirmForgotPassword",
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            mapError: mapError(data:response:)
        )
    }
}