#if canImport(UIKit)

import UIKit

public struct Alert: Equatable {

  // MARK: Lifecycle

  public init(title: String? = .none, message: String?, buttons: [ActionButton], flagType: FlagType) {
    self.title = title ?? ""
    self.message = message ?? ""
    self.buttons = buttons
    self.flagType = flagType
  }

  // MARK: Public

  public enum FlagType: Equatable {
    case error
    case `default`
  }

  // MARK: Internal

  let title: String?
  let message: String
  let buttons: [ActionButton]
  let flagType: FlagType

  func build() -> UIAlertController {
    let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
    for button in buttons {
      controller.addAction(button.buildAlertButton())
    }
    return controller
  }
}

#endif
