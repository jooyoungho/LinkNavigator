import UIKit

// MARK: - SingleLinkNavigator

public final class SingleLinkNavigator<ItemValue: EmptyValueType> {

  // MARK: Lifecycle

  public init(
    rootNavigator: Navigator<ItemValue>,
    routeBuilderItemList: [RouteBuilderOf<SingleLinkNavigator, ItemValue>],
    dependency: DependencyType,
    subNavigator: Navigator<ItemValue>? = nil)
  {
    self.rootNavigator = rootNavigator
    self.routeBuilderItemList = routeBuilderItemList
    self.dependency = dependency
    self.subNavigator = subNavigator
  }

  // MARK: Public

  public let rootNavigator: Navigator<ItemValue>
  public let routeBuilderItemList: [RouteBuilderOf<SingleLinkNavigator, ItemValue>]
  public let dependency: DependencyType

  public var subNavigator: Navigator<ItemValue>?

  // MARK: Private

  private var coordinate: Coordinate = .init(sheetDidDismiss: { })

}

extension SingleLinkNavigator {

  public func launch(item: LinkItem<ItemValue>? = .none, prefersLargeTitles: Bool = false) -> BaseNavigator {
    rootNavigator.replace(
      rootNavigator: self,
      item: item ?? rootNavigator.initialLinkItem,
      isAnimated: false,
      routeBuilderList: routeBuilderItemList,
      dependency: dependency)
    rootNavigator.controller.navigationBar.prefersLargeTitles = prefersLargeTitles

    return .init(viewController: rootNavigator.controller)
  }

  public var activeNavigator: Navigator<ItemValue>? {
    isSubNavigatorActive ? subNavigator : rootNavigator
  }
}

// MARK: LinkNavigatorProtocol

extension SingleLinkNavigator: LinkNavigatorFindLocationUsable {

  public func getCurrentPaths() -> [String] {
    isSubNavigatorActive ? subNavigatorCurrentPaths : getRootCurrentPaths()
  }

  public func getRootCurrentPaths() -> [String] {
    rootNavigator.viewControllers.map(\.matchPath)
  }

}

extension SingleLinkNavigator {

  private func _next(linkItem: LinkItem<ItemValue>, isAnimated: Bool) {
    activeNavigator?.push(
      rootNavigator: self,
      item: linkItem,
      isAnimated: isAnimated,
      routeBuilderList: routeBuilderItemList,
      dependency: dependency)
  }

  private func _rootNext(linkItem: LinkItem<ItemValue>, isAnimated: Bool) {
    rootNavigator.push(
      rootNavigator: self,
      item: linkItem,
      isAnimated: isAnimated,
      routeBuilderList: routeBuilderItemList,
      dependency: dependency)
  }

  private func _sheet(linkItem: LinkItem<ItemValue>, isAnimated: Bool) {
    sheetOpen(item: linkItem, isAnimated: isAnimated)
  }

  private func _fullSheet(linkItem: LinkItem<ItemValue>, isAnimated: Bool, prefersLargeTitles: Bool?) {
    sheetOpen(
      item: linkItem,
      isAnimated: isAnimated,
      prefersLargeTitles: prefersLargeTitles,
      presentWillAction: {
        $0.modalPresentationStyle = .fullScreen
      },
      presentDidAction: { [weak self] in
        $0.presentationController?.delegate = self?.coordinate
      })
  }

  private func _customSheet(
    linkItem: LinkItem<ItemValue>,
    isAnimated: Bool,
    iPhonePresentationStyle: UIModalPresentationStyle,
    iPadPresentationStyle: UIModalPresentationStyle,
    prefersLargeTitles: Bool?)
  {
    sheetOpen(
      item: linkItem,
      isAnimated: isAnimated,
      prefersLargeTitles: prefersLargeTitles,
      presentWillAction: {
        $0.modalPresentationStyle = UIDevice.current.userInterfaceIdiom == .phone
          ? iPhonePresentationStyle
          : iPadPresentationStyle
      },
      presentDidAction: { [weak self] in
        $0.presentationController?.delegate = self?.coordinate
      })
  }

  private func _replace(linkItem: LinkItem<ItemValue>, isAnimated: Bool) {
    rootNavigator.controller.dismiss(animated: isAnimated) { [weak self] in
      guard let self else { return }
      subNavigator?.reset(isAnimated: isAnimated)
      subNavigator?.controller.presentationController?.delegate = .none
    }
    rootNavigator.replace(
      rootNavigator: self,
      item: linkItem,
      isAnimated: isAnimated,
      routeBuilderList: routeBuilderItemList,
      dependency: dependency)
  }

  private func _backOrNext(linkItem: LinkItem<ItemValue>, isAnimated: Bool) {
    activeNavigator?.backOrNext(
      rootNavigator: self,
      item: linkItem,
      isAnimated: isAnimated,
      routeBuilderList: routeBuilderItemList,
      dependency: dependency)
  }

  private func _rootBackOrNext(linkItem: LinkItem<ItemValue>, isAnimated: Bool) {
    guard let path = linkItem.pathList.first else { return }
    guard let pick = rootNavigator.viewControllers.first(where: { $0.matchPath == path }) else {
      rootNavigator.push(
        rootNavigator: self,
        item: .init(path: path, items: linkItem.items),
        isAnimated: isAnimated,
        routeBuilderList: routeBuilderItemList,
        dependency: dependency)
      return
    }
    rootNavigator.controller.popToViewController(pick, animated: isAnimated)
  }

  private func _back(isAnimated: Bool) {
    isSubNavigatorActive
      ? sheetBack(isAnimated: isAnimated)
      : rootNavigator.back(isAnimated: isAnimated)
  }

  private func _remove(pathList: [String]) {
    activeNavigator?.remove(item: .init(pathList: pathList, items: .empty))
  }

  private func _rootRemove(pathList: [String]) {
    rootNavigator.remove(item: .init(pathList: pathList, items: .empty))
  }

  private func _backToLast(path: String, isAnimated: Bool) {
    activeNavigator?.backToLast(item: .init(path: path, items: .empty), isAnimated: isAnimated)
  }

  private func _rootBackToLast(path: String, isAnimated: Bool) {
    rootNavigator.backToLast(item: .init(path: path, items: .empty), isAnimated: isAnimated)
  }

  private func _close(isAnimated: Bool, completeAction: @escaping () -> Void) {
    guard activeNavigator == subNavigator else { return }
    rootNavigator.controller.dismiss(animated: isAnimated) { [weak self] in
      completeAction()
      self?.subNavigator?.reset()
      self?.subNavigator?.controller.presentationController?.delegate = .none
    }
  }

  private func _range(path: String) -> [String] {
    getRootCurrentPaths().reduce([String]()) { current, next in
      guard current.contains(path) else { return current + [next] }
      return current
    }
  }

  private func _rootReloadLast(items: ItemValue, isAnimated: Bool) {
    guard let lastPath = getRootCurrentPaths().last else { return }
    guard let new = routeBuilderItemList.first(where: { $0.matchPath == lastPath })?.routeBuild(self, items, dependency)
    else { return }

    let newList = Array(rootNavigator.controller.viewControllers.dropLast()) + [new]
    rootNavigator.controller.setViewControllers(newList, animated: isAnimated)
  }

  private func _alert(target: NavigationTarget, model: Alert) {
    switch target {
    case .default:
      _alert(target: isSubNavigatorActive ? .sub : .root, model: model)
    case .root:
      rootNavigator.controller.present(model.build(), animated: true)
    case .sub:
      subNavigator?.controller.present(model.build(), animated: true)
    }
  }
}

/// MARK: - Main
extension SingleLinkNavigator {
  public var isSubNavigatorActive: Bool {
    rootNavigator.controller.presentedViewController != .none
  }
}

/// MARK: - Sub
extension SingleLinkNavigator {

  // MARK: Public

  public func sheetOpen(
    item: LinkItem<ItemValue>,
    isAnimated: Bool,
    prefersLargeTitles: Bool? = .none,
    presentWillAction: @escaping (UINavigationController) -> Void = { _ in },
    presentDidAction: @escaping (UINavigationController) -> Void = { _ in })
  {
    rootNavigator.controller.dismiss(animated: true)

    let new = Navigator(initialLinkItem: item)
    if let prefersLargeTitles { new.controller.navigationBar.prefersLargeTitles = prefersLargeTitles }
    presentWillAction(new.controller)

    new.replace(
      rootNavigator: self,
      item: item,
      isAnimated: false,
      routeBuilderList: routeBuilderItemList,
      dependency: dependency)
    rootNavigator.controller.present(new.controller, animated: isAnimated)
    presentDidAction(new.controller)

    subNavigator = new
  }

  // MARK: Private

  private var subNavigatorCurrentPaths: [String] {
    subNavigator?.currentPath ?? []
  }

  private func sheetBack(isAnimated: Bool) {
    guard let subNavigator else { return }
    guard subNavigator.viewControllers.count > 1 else {
      rootNavigator.controller.dismiss(animated: true)
      self.subNavigator = .none
      return
    }
    subNavigator.back(isAnimated: isAnimated)
  }
}

extension SingleLinkNavigator: LinkNavigatorURLEncodedItemProtocol where ItemValue == String {
  public func next(linkItem: LinkItem<ItemValue>, isAnimated: Bool) {
    _next(linkItem: linkItem, isAnimated: isAnimated)
  }

  public func rootNext(linkItem: LinkItem<ItemValue>, isAnimated: Bool) {
    _rootNext(linkItem: linkItem, isAnimated: isAnimated)
  }

  public func sheet(linkItem: LinkItem<ItemValue>, isAnimated: Bool) {
    _sheet(linkItem: linkItem, isAnimated: isAnimated)
  }

  public func fullSheet(linkItem: LinkItem<ItemValue>, isAnimated: Bool, prefersLargeTitles: Bool?) {
    _fullSheet(linkItem: linkItem, isAnimated: isAnimated, prefersLargeTitles: prefersLargeTitles)
  }

  public func customSheet(linkItem: LinkItem<ItemValue>, isAnimated: Bool, iPhonePresentationStyle: UIModalPresentationStyle, iPadPresentationStyle: UIModalPresentationStyle, prefersLargeTitles: Bool?) {
    _customSheet(
      linkItem: linkItem,
      isAnimated: isAnimated,
      iPhonePresentationStyle: iPhonePresentationStyle,
      iPadPresentationStyle: iPadPresentationStyle,
      prefersLargeTitles: prefersLargeTitles)
  }

  public func replace(linkItem: LinkItem<ItemValue>, isAnimated: Bool) {
    _replace(linkItem: linkItem, isAnimated: isAnimated)
  }

  public func backOrNext(linkItem: LinkItem<ItemValue>, isAnimated: Bool) {
    _backOrNext(linkItem: linkItem, isAnimated: isAnimated)
  }

  public func rootBackOrNext(linkItem: LinkItem<ItemValue>, isAnimated: Bool) {
    _rootBackOrNext(linkItem: linkItem, isAnimated: isAnimated)
  }

  public func back(isAnimated: Bool) {
    _back(isAnimated: isAnimated)
  }

  public func remove(pathList: [String]) {
    _remove(pathList: pathList)
  }

  public func rootRemove(pathList: [String]) {
    _rootRemove(pathList: pathList)
  }

  public func backToLast(path: String, isAnimated: Bool) {
    _backToLast(path: path, isAnimated: isAnimated)
  }

  public func rootBackToLast(path: String, isAnimated: Bool) {
    _rootBackToLast(path: path, isAnimated: isAnimated)
  }

  public func close(isAnimated: Bool, completeAction: @escaping () -> Void) {
    _close(isAnimated: isAnimated, completeAction: completeAction)
  }

  public func range(path: String) -> [String] {
    _range(path: path)
  }

  public func rootReloadLast(items: ItemValue, isAnimated: Bool) {
    _rootReloadLast(items: items, isAnimated: isAnimated)
  }

  public func alert(target: NavigationTarget, model: Alert) {
    _alert(target: target, model: model)
  }

}

extension SingleLinkNavigator: LinkNavigatorDictionaryItemProtocol where ItemValue == [String: String] {
  public func next(linkItem: LinkItem<ItemValue>, isAnimated: Bool) {
    _next(linkItem: linkItem, isAnimated: isAnimated)
  }

  public func rootNext(linkItem: LinkItem<ItemValue>, isAnimated: Bool) {
    _rootNext(linkItem: linkItem, isAnimated: isAnimated)
  }

  public func sheet(linkItem: LinkItem<ItemValue>, isAnimated: Bool) {
    _sheet(linkItem: linkItem, isAnimated: isAnimated)
  }

  public func fullSheet(linkItem: LinkItem<ItemValue>, isAnimated: Bool, prefersLargeTitles: Bool?) {
    _fullSheet(linkItem: linkItem, isAnimated: isAnimated, prefersLargeTitles: prefersLargeTitles)
  }

  public func customSheet(linkItem: LinkItem<ItemValue>, isAnimated: Bool, iPhonePresentationStyle: UIModalPresentationStyle, iPadPresentationStyle: UIModalPresentationStyle, prefersLargeTitles: Bool?) {
    _customSheet(
      linkItem: linkItem,
      isAnimated: isAnimated,
      iPhonePresentationStyle: iPhonePresentationStyle,
      iPadPresentationStyle: iPadPresentationStyle,
      prefersLargeTitles: prefersLargeTitles)
  }

  public func replace(linkItem: LinkItem<ItemValue>, isAnimated: Bool) {
    _replace(linkItem: linkItem, isAnimated: isAnimated)
  }

  public func backOrNext(linkItem: LinkItem<ItemValue>, isAnimated: Bool) {
    _backOrNext(linkItem: linkItem, isAnimated: isAnimated)
  }

  public func rootBackOrNext(linkItem: LinkItem<ItemValue>, isAnimated: Bool) {
    _rootBackOrNext(linkItem: linkItem, isAnimated: isAnimated)
  }

  public func back(isAnimated: Bool) {
    _back(isAnimated: isAnimated)
  }

  public func remove(pathList: [String]) {
    _remove(pathList: pathList)
  }

  public func rootRemove(pathList: [String]) {
    _rootRemove(pathList: pathList)
  }

  public func backToLast(path: String, isAnimated: Bool) {
    _backToLast(path: path, isAnimated: isAnimated)
  }

  public func rootBackToLast(path: String, isAnimated: Bool) {
    _rootBackToLast(path: path, isAnimated: isAnimated)
  }

  public func close(isAnimated: Bool, completeAction: @escaping () -> Void) {
    _close(isAnimated: isAnimated, completeAction: completeAction)
  }

  public func range(path: String) -> [String] {
    _range(path: path)
  }

  public func rootReloadLast(items: ItemValue, isAnimated: Bool) {
    _rootReloadLast(items: items, isAnimated: isAnimated)
  }

  public func alert(target: NavigationTarget, model: Alert) {
    _alert(target: target, model: model)
  }


}

// MARK: SingleLinkNavigator.Coordinate

extension SingleLinkNavigator {
  fileprivate class Coordinate: NSObject, UIAdaptivePresentationControllerDelegate {

    // MARK: Lifecycle

    init(sheetDidDismiss: @escaping () -> Void) {
      self.sheetDidDismiss = sheetDidDismiss
    }

    // MARK: Internal

    var sheetDidDismiss: () -> Void

    func presentationControllerDidDismiss(_: UIPresentationController) {
      sheetDidDismiss()
    }
  }
}
