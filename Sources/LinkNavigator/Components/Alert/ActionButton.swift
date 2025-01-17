#if canImport(UIKit)

import UIKit

// MARK: - SystemActionButton

public struct ActionButton: Equatable {

  // MARK: Lifecycle

  public init(title: String? = .none, style: ActionStyle, action: @escaping () -> Void = { }) {
    self.title = title ?? "title"
    self.style = style
    self.action = action
  }

  // MARK: Public

  public enum ActionStyle {
    case `default`
    case cancel
    case destructive

    var uiRawValue: UIAlertAction.Style {
      switch self {
      case .default: return .default
      case .cancel: return .cancel
      case .destructive: return .destructive
      }
    }
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.title == rhs.title
  }

  // MARK: Internal

  let title: String
  let style: ActionStyle
  let action: () -> Void

  func buildAlertButton() -> UIAlertAction {
    .init(title: title, style: style.uiRawValue) { _ in action() }
  }
}

#endif
