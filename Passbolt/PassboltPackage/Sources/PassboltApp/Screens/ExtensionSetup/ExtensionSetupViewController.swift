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

import UIComponents

internal final class ExtensionSetupViewController: PlainViewController, UIComponent {

  internal typealias View = ExtensionSetupView
  internal typealias Controller = ExtensionSetupController

  internal static func instance(
    using controller: Controller,
    with components: UIComponentFactory
  ) -> Self {
    Self(
      using: controller,
      with: components
    )
  }

  internal private(set) lazy var contentView: View = .init()
  internal let components: UIComponentFactory

  private let controller: Controller
  private var continueSetupPresentationSubscriptionCancellable: AnyCancellable?

  internal init(
    using controller: Controller,
    with components: UIComponentFactory
  ) {
    self.controller = controller
    self.components = components
    super.init()
  }

  func activate() {
    continueSetupPresentationSubscriptionCancellable =
      controller
      .continueSetupPresentationPublisher()
      .receive(on: RunLoop.main)
      .sink { [weak self] in
        self?.replaceWindowRoot(with: SplashScreenViewController.self)
      }
  }

  func deactivate() {
    continueSetupPresentationSubscriptionCancellable = nil
  }

  internal func setupView() {
    mut(navigationItem) {
      .hidesBackButton(true)
    }
    setupSubscriptions()
  }

  private func setupSubscriptions() {
    contentView
      .setupTapPublisher
      .sink { [weak self] in
        guard let self = self else { return }
        self.controller
          .setupExtension()
          .sink(
            receiveCompletion: { [weak self] completion in
              guard case .failure = completion else { return }
              self?.present(
                snackbar: Mutation<UICommons.View>
                  .snackBarErrorMessage(
                    localized: .genericError,
                    inBundle: .commons
                  )
                  .instantiate(),
                hideAfter: 3
              )
            }
          )
          .store(in: self.cancellables)
      }
      .store(in: cancellables)

    contentView
      .skipTapPublisher
      .sink { [weak self] in
        self?.controller.skipSetup()
      }
      .store(in: cancellables)
  }
}
