//
// Passbolt - Open source password manager for teams
// Copyright (c) 2021 Passbolt SA
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General
// Public License (AGPL) as published by the Free Software Foundation version 3.
//
// The name "Passbolt" is a registered trademark of Passbolt SA, and Passbolt SA hereby declines to grant a trademark
// license to "Passbolt" pursuant to the GNU Affero General Public License version 3 Section 7(e), without a separate
// agreement with Passbolt SA.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License along with this program. If not,
// see GNU Affero General Public License v3 (http://www.gnu.org/licenses/agpl-3.0.html).
//
// @copyright     Copyright (c) Passbolt SA (https://www.passbolt.com)
// @license       https://opensource.org/licenses/AGPL-3.0 AGPL License
// @link          https://www.passbolt.com Passbolt (tm)
// @since         v1.0
//

import Combine
import CommonDataModels
import Features
import TestExtensions
import UIComponents
import XCTest

@testable import Accounts
@testable import PassboltApp
@testable import Resources

// swift-format-ignore: AlwaysUseLowerCamelCase, NeverUseImplicitlyUnwrappedOptionals
final class ResourceMenuControllerTests: TestCase {

  var resources: Resources!
  var pasteboard: Pasteboard!
  var linkOpener: LinkOpener!

  override func setUp() {
    super.setUp()

    linkOpener = .placeholder
    pasteboard = .placeholder
    resources = .placeholder
  }

  override func tearDown() {
    super.tearDown()

    resources = nil
  }

  func test_resourceDetailsPublisher_publishes_initially() {
    resources.resourceDetailsPublisher = always(
      Just(detailsViewResource)
        .setFailureType(to: TheError.self)
        .eraseToAnyPublisher()
    )
    features.use(linkOpener)
    features.use(pasteboard)
    features.use(resources)

    let controller: ResourceMenuController = testInstance(
      context: (
        resourceID: detailsViewResource.id,
        showEdit: { _ in /* NOP */ },
        showDeleteAlert: { _ in /* NOP */ }
      )
    )
    var result: ResourceDetailsController.ResourceDetails?

    controller
      .resourceDetailsPublisher()
      .sink(
        receiveCompletion: { _ in
          XCTFail("Unexpected completion")
        },
        receiveValue: { value in
          result = value
        }
      )
      .store(in: cancellables)

    XCTAssertEqual(result?.id.rawValue, detailsViewResource.id.rawValue)
  }

  func test_availableActionsPublisher_publishesActionAvailable_initially() {
    resources.resourceDetailsPublisher = always(
      Just(detailsViewResource)
        .setFailureType(to: TheError.self)
        .eraseToAnyPublisher()
    )
    features.use(linkOpener)
    features.use(pasteboard)
    features.use(resources)

    let controller: ResourceMenuController = testInstance(
      context: (
        resourceID: detailsViewResource.id,
        showEdit: { _ in /* NOP */ },
        showDeleteAlert: { _ in /* NOP */ }
      )
    )
    var result: Array<ResourceMenuController.Action>!

    controller.availableActionsPublisher()
      .sink { actions in
        result = actions
      }
      .store(in: cancellables)

    XCTAssertEqual(result, ResourceMenuController.Action.allCases)
  }

  func test_performAction_copiesSecretToPasteboard_forCopyPasswordAction() {
    resources.resourceDetailsPublisher = always(
      Just(detailsViewResource)
        .setFailureType(to: TheError.self)
        .eraseToAnyPublisher()
    )
    resources.loadResourceSecret = always(
      Just(resourceSecret)
        .setFailureType(to: TheError.self)
        .eraseToAnyPublisher()
    )
    features.use(resources)

    var result: String?
    pasteboard.put = { string in
      result = string
    }
    features.use(pasteboard)
    features.use(linkOpener)

    let controller: ResourceMenuController = testInstance(
      context: (
        resourceID: detailsViewResource.id,
        showEdit: { _ in /* NOP */ },
        showDeleteAlert: { _ in /* NOP */ }
      )
    )

    controller
      .performAction(.copyPassword)
      .sinkDrop()
      .store(in: cancellables)

    XCTAssertEqual(result, resourceSecret.password)
  }

  func test_performAction_copiesURLToPasteboard_forCopyURLAction() {
    resources.resourceDetailsPublisher = always(
      Just(detailsViewResource)
        .setFailureType(to: TheError.self)
        .eraseToAnyPublisher()
    )
    features.use(resources)

    var result: String? = nil
    pasteboard.put = { string in
      result = string
    }
    features.use(pasteboard)
    features.use(linkOpener)

    let controller: ResourceMenuController = testInstance(
      context: (
        resourceID: detailsViewResource.id,
        showEdit: { _ in /* NOP */ },
        showDeleteAlert: { _ in /* NOP */ }
      )
    )

    controller
      .performAction(.copyURL)
      .sinkDrop()
      .store(in: cancellables)

    XCTAssertEqual(result, detailsViewResource.url)
  }

  func test_performAction_opensURL_forOpenURLAction() {
    resources.resourceDetailsPublisher = always(
      Just(detailsViewResource)
        .setFailureType(to: TheError.self)
        .eraseToAnyPublisher()
    )
    features.use(resources)
    features.use(pasteboard)

    var result: URL? = nil
    linkOpener.openLink = { url in
      result = url
      return Just(true).eraseToAnyPublisher()
    }
    features.use(linkOpener)

    let controller: ResourceMenuController = testInstance(
      context: (
        resourceID: detailsViewResource.id,
        showEdit: { _ in /* NOP */ },
        showDeleteAlert: { _ in /* NOP */ }
      )
    )

    controller
      .performAction(.openURL)
      .sinkDrop()
      .store(in: cancellables)

    XCTAssertEqual(result?.absoluteString, detailsViewResource.url)
  }

  func test_performAction_fails_forOpenURLAction_whenOpeningFails() {
    resources.resourceDetailsPublisher = always(
      Just(detailsViewResource)
        .setFailureType(to: TheError.self)
        .eraseToAnyPublisher()
    )
    features.use(resources)
    features.use(pasteboard)

    linkOpener.openLink = { _ in
      Just(false)
        .eraseToAnyPublisher()
    }
    features.use(linkOpener)

    let controller: ResourceMenuController = testInstance(
      context: (
        resourceID: detailsViewResource.id,
        showEdit: { _ in /* NOP */ },
        showDeleteAlert: { _ in /* NOP */ }
      )
    )

    var result: TheError?
    controller
      .performAction(.openURL)
      .sink(
        receiveCompletion: { completion in
          guard case let .failure(error) = completion
          else { return }
          result = error
        },
        receiveValue: {}
      )
      .store(in: cancellables)

    XCTAssertEqual(result?.identifier, .failedToOpenURL)
  }

  func test_performAction_copiesUsernameToPasteboard_forCopyUsernameAction() {
    resources.resourceDetailsPublisher = always(
      Just(detailsViewResource)
        .setFailureType(to: TheError.self)
        .eraseToAnyPublisher()
    )
    features.use(resources)

    var result: String? = nil
    pasteboard.put = { string in
      result = string
    }
    features.use(pasteboard)
    features.use(linkOpener)

    let controller: ResourceMenuController = testInstance(
      context: (
        resourceID: detailsViewResource.id,
        showEdit: { _ in /* NOP */ },
        showDeleteAlert: { _ in /* NOP */ }
      )
    )

    controller
      .performAction(.copyUsername)
      .sinkDrop()
      .store(in: cancellables)

    XCTAssertEqual(result, detailsViewResource.username)
  }

  func test_performAction_copiesDescriptionToPasteboard_forCopyDescriptionAction_withUnencryptedDescription() {
    resources.resourceDetailsPublisher = always(
      Just(detailsViewResource)
        .setFailureType(to: TheError.self)
        .eraseToAnyPublisher()
    )
    features.use(resources)

    var result: String? = nil
    pasteboard.put = { string in
      result = string
    }
    features.use(pasteboard)
    features.use(linkOpener)

    let controller: ResourceMenuController = testInstance(
      context: (
        resourceID: detailsViewResource.id,
        showEdit: { _ in /* NOP */ },
        showDeleteAlert: { _ in /* NOP */ }
      )
    )

    controller
      .performAction(.copyDescription)
      .sinkDrop()
      .store(in: cancellables)

    XCTAssertEqual(result, detailsViewResource.description)
  }

  func test_performAction_copiesDescriptionToPasteboard_forCopyDescriptionAction_withEncryptedDescription() {
    resources.resourceDetailsPublisher = always(
      Just(detailsViewResourceWithoutDescription)
        .setFailureType(to: TheError.self)
        .eraseToAnyPublisher()
    )
    resources.loadResourceSecret = always(
      Just(resourceSecret)
        .setFailureType(to: TheError.self)
        .eraseToAnyPublisher()
    )
    features.use(resources)

    var result: String?
    pasteboard.put = { string in
      result = string
    }
    features.use(pasteboard)
    features.use(linkOpener)

    let controller: ResourceMenuController = testInstance(
      context: (
        resourceID: detailsViewResource.id,
        showEdit: { _ in /* NOP */ },
        showDeleteAlert: { _ in /* NOP */ }
      )
    )

    controller
      .performAction(.copyDescription)
      .sinkDrop()
      .store(in: cancellables)

    XCTAssertEqual(result, "encrypted description")
  }

  func test_performAction_triggersShowDeleteAlert_forDeleteAction() {
    resources.resourceDetailsPublisher = always(
      Just(detailsViewResourceWithoutDescription)
        .setFailureType(to: TheError.self)
        .eraseToAnyPublisher()
    )
    resources.loadResourceSecret = always(
      Just(resourceSecret)
        .setFailureType(to: TheError.self)
        .eraseToAnyPublisher()
    )
    features.use(resources)
    features.use(pasteboard)
    features.use(linkOpener)

    var result: Resource.ID?

    let controller: ResourceMenuController = testInstance(
      context: (
        resourceID: detailsViewResource.id,
        showEdit: { _ in /* NOP */ },
        showDeleteAlert: { resourceID in result = resourceID }
      )
    )

    controller
      .performAction(.delete)
      .sinkDrop()
      .store(in: cancellables)

    XCTAssertEqual(result, detailsViewResource.id)
  }
}

private let detailsViewResource: DetailsViewResource = .init(
  id: .init(rawValue: "1"),
  permission: .owner,
  name: "Passphrase",
  url: "https://passbolt.com",
  username: "passbolt@passbolt.com",
  description: "Passbolt",
  properties: [
    .init(name: "username", typeString: "string", required: true, encrypted: false, maxLength: nil)!,
    .init(name: "password", typeString: "string", required: true, encrypted: true, maxLength: nil)!,
    .init(name: "uri", typeString: "string", required: true, encrypted: false, maxLength: nil)!,
    .init(name: "description", typeString: "string", required: true, encrypted: false, maxLength: nil)!,
  ]
)

private let detailsViewResourceWithoutDescription: DetailsViewResource = .init(
  id: .init(rawValue: "1"),
  permission: .owner,
  name: "Passphrase",
  url: "https://passbolt.com",
  username: "passbolt@passbolt.com",
  description: nil,
  properties: [
    .init(name: "username", typeString: "string", required: true, encrypted: false, maxLength: nil)!,
    .init(name: "password", typeString: "string", required: true, encrypted: true, maxLength: nil)!,
    .init(name: "uri", typeString: "string", required: true, encrypted: false, maxLength: nil)!,
    .init(name: "description", typeString: "string", required: true, encrypted: true, maxLength: nil)!,
  ]
)

private let resourceSecret: ResourceSecret = .from(
  decrypted: #"{"password" : "passbolt", "description": "encrypted description"}"#,
  using: .init()
)!
