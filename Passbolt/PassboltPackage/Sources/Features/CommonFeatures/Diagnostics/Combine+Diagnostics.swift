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

import Commons

extension Publisher where Failure == TheError {

  public func collectErrorLog(
    withPrefix prefix: StaticString = "",
    using diagnostics: Diagnostics
  ) -> AnyPublisher<Output, Failure> {
    #if DEBUG
    handleEvents(receiveCompletion: { completion in
      switch completion {
      case .finished, .failure(.canceled):
        break

      case let .failure(error):
        diagnostics.debugLog("\(prefix)\(error.debugDescription)")
      }
    })
    .eraseToAnyPublisher()
    #else
    #warning("TODO: we might need to store some information in regular diagnostic log")
    return eraseToAnyPublisher()
    #endif
  }
}

extension Publisher {

  public func collectValueLog(
    withPrefix prefix: StaticString = "Received:",
    using diagnostics: Diagnostics
  ) -> AnyPublisher<Output, Failure> {
    #if DEBUG
    handleEvents(receiveOutput: { output in
      diagnostics.debugLog("\(prefix)\(output)")
    })
    .eraseToAnyPublisher()
    #else
    eraseToAnyPublisher()
    #endif
  }
}

extension Publisher {

  public func collectCancelationLog(
    withPrefix prefix: StaticString = "Canceled",
    using diagnostics: Diagnostics
  ) -> AnyPublisher<Output, Failure> {
    #if DEBUG
    handleEvents(receiveCancel: {

      diagnostics.debugLog("\(prefix)")
    })
    .eraseToAnyPublisher()
    #else
    eraseToAnyPublisher()
    #endif
  }
}
