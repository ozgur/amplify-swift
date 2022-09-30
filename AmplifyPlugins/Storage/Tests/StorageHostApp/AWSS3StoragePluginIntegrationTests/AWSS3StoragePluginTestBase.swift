//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSS3StoragePlugin
import AmplifyAsyncTesting
import AWSCognitoAuthPlugin

class AWSS3StoragePluginTestBase: XCTestCase {

    static let amplifyConfiguration = "testconfiguration/AWSS3StoragePluginTests-amplifyconfiguration"

    static let largeDataObject = Data(repeating: 0xff, count: 1_024 * 1_024 * 6) // 6MB

    static var user1: String = "integTest\(UUID().uuidString)"
    static var user2: String = "integTest\(UUID().uuidString)"
    static var password: String = "P123@\(UUID().uuidString)"
    static var email1 = UUID().uuidString + "@" + UUID().uuidString + ".com"
    static var email2 = UUID().uuidString + "@" + UUID().uuidString + ".com"

    static var isFirstUserSignedUp = false
    static var isSecondUserSignedUp = false

    override func setUp() async throws {
        do {
            await Amplify.reset()
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSS3StoragePlugin())
            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: Self.amplifyConfiguration)
            try Amplify.configure(amplifyConfig)
            if (try? await Amplify.Auth.getCurrentUser()) != nil {
                await signOut()
            }
            await signUp()
        } catch {
            XCTFail("Failed to initialize and configure Amplify \(error)")
        }
    }

    override func tearDown() async throws {
        invalidateCurrentSession()
        await Amplify.reset()
        // `sleep` has been added here to get more consistent test runs.
        // The plugin will always create a URLSession with the same key, so we need to invalidate it first.
        // However, it needs some time to properly clean up before creating and using a new session.
        // The `sleep` helps avoid the error: "Task created in a session that has been invalidated"
        sleep(1)
    }

    // MARK: Common Helper functions

    func uploadData(key: String, dataString: String,
                    file: StaticString = #file,
                    line: UInt = #line) async {
        await uploadData(key: key, data: dataString.data(using: .utf8)!, file: file, line: line)
    }

    func uploadTask(key: String, data: Data,
                    file: StaticString = #file,
                    line: UInt = #line) async -> StorageUploadDataTask? {
        await wait(name: "Upload Task created", file: file, line: line) {
            try await Amplify.Storage.uploadData(key: key, data: data)
        }
    }

    func downloadTask(key: String,
                      file: StaticString = #file,
                      line: UInt = #line) async -> StorageDownloadDataTask? {
        await wait(name: "Upload Task created", file: file, line: line) {
            try await Amplify.Storage.downloadData(key: key)
        }
    }

    func uploadData(key: String, data: Data,
                    file: StaticString = #file,
                    line: UInt = #line) async {
        let completeInvoked = asyncExpectation(description: "Completed is invoked")
        let result = await wait(with: completeInvoked, timeout: 60, file: file, line: line) {
            try await Amplify.Storage.uploadData(key: key, data: data, options: nil).value
        }
        XCTAssertNotNil(result, file: file, line: line)
    }
    
    func remove(key: String, accessLevel: StorageAccessLevel? = nil,
                file: StaticString = #file,
                line: UInt = #line) async {
        var removeOptions: StorageRemoveRequest.Options? = nil
        if let accessLevel = accessLevel {
            removeOptions = .init(accessLevel: accessLevel)
        }

        let result = await wait(name: "Remove operation should be successful", file: file, line: line) {
            return try await Amplify.Storage.remove(key: key, options: removeOptions)
        }
        XCTAssertNotNil(result, file: file, line: line)
    }

    static func getBucketFromConfig(forResource: String) throws -> String {
        let data = try TestConfigHelper.retrieve(forResource: forResource)
        let json = try JSONDecoder().decode(JSONValue.self, from: data)
        guard let bucket = json["storage"]?["plugins"]?["awsS3StoragePlugin"]?["bucket"] else {
            throw "Could not retrieve bucket from config"
        }

        guard case let .string(bucketValue) = bucket else {
            throw "bucket is not a string value"
        }

        return bucketValue
    }

    func signUp(file: StaticString = #file, line: UInt = #line) async {
        guard !Self.isFirstUserSignedUp, !Self.isSecondUserSignedUp else {
            return
        }

        let registerFirstUserComplete = asyncExpectation(description: "register firt user completed")
        Task {
            do {
                try await AuthSignInHelper.signUpUser(username: AWSS3StoragePluginTestBase.user1,
                                                      password: AWSS3StoragePluginTestBase.password,
                                                      email: AWSS3StoragePluginTestBase.email1)
                Self.isFirstUserSignedUp = true
                await registerFirstUserComplete.fulfill()
            } catch {
                XCTFail("Failed to Sign up user: \(error)", file: file, line: line)
                await registerFirstUserComplete.fulfill()
            }
        }

        let registerSecondUserComplete = asyncExpectation(description: "register second user completed")
        Task {
            do {
                try await AuthSignInHelper.signUpUser(username: AWSS3StoragePluginTestBase.user2,
                                                      password: AWSS3StoragePluginTestBase.password,
                                                      email: AWSS3StoragePluginTestBase.email2)
                Self.isSecondUserSignedUp = true
                await registerSecondUserComplete.fulfill()
            } catch {
                XCTFail("Failed to Sign up user: \(error)", file: file, line: line)
                await registerSecondUserComplete.fulfill()
            }
        }

        await waitForExpectations([registerFirstUserComplete, registerSecondUserComplete],
                                  timeout: TestCommonConstants.networkTimeout, file: file, line: line)
    }

    func getURL(key: String, options: StorageGetURLRequest.Options? = nil,
                file: StaticString = #file,
                line: UInt = #line) async -> URL? {
        await wait(name: "Get URL completed",
                   timeout: TestCommonConstants.networkTimeout,
                   file: file, line: line) {
            try await Amplify.Storage.getURL(key: key, options: options)
        }
    }

    func signOut(file: StaticString = #file, line: UInt = #line) async {
        await wait(name: "Sign out completed", file: file, line: line) {
            await Amplify.Auth.signOut()
        }
    }

    private func invalidateCurrentSession() {
        guard let plugin = try? Amplify.Storage.getPlugin(for: "awsS3StoragePlugin") as? AWSS3StoragePlugin,
              let service = plugin.storageService as? AWSS3StorageService else {
            print("Unable to to cast to AWSS3StorageService")
            return
        }

        if let delegate = service.urlSession.delegate as? StorageServiceSessionDelegate {
            delegate.storageService = nil
        }
        service.urlSession.invalidateAndCancel()
    }
}