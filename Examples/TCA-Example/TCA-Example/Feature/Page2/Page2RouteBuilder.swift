import LinkNavigator
import SwiftUI

struct Page2RouteBuilder: RouteBuilder {
  var matchPath: String { "page2" }

  var build: (LinkNavigatorType, [String: String], DependencyType) -> MatchingViewController? {
    { navigator, items, dep in
      WrappingController(matchingKey: matchPath) {
        Page2View(
          store: .init(
            initialState: Page2.State(),
            reducer: Page2()))
      }
    }
  }
}
