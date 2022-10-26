import ComposableArchitecture

public struct Home: ReducerProtocol {
  public struct State: Equatable {
    var paths: [String] = []
  }

  public enum Action: Equatable {
    case getPaths
    case onTapNext
    case onTapLast
    case onTapSheet
    case onTapFullSheet
  }

  @Dependency(\.sideEffect.home) var sideEffect

  public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
    switch action {
    case .getPaths:
      state.paths = sideEffect.getPaths()
      return .none

    case .onTapNext:
      sideEffect.routeToPage1()
      return .none

    case .onTapLast:
      sideEffect.routeToPage3()
      return .none

    case .onTapSheet:
      sideEffect.routeToSheet()
      return .none

    case .onTapFullSheet:
      sideEffect.routeToFullSheet()
      return .none
    }
  }
}