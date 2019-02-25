import UIKit
import Photos

public protocol CartDelegate: class {
  func cart(_ cart: Cart, didAdd image: Image, newlyTaken: Bool)
  func cart(_ cart: Cart, didRemove image: Image)
  func cartDidReload(_ cart: Cart)
}

/// Cart holds selected images and videos information
public class Cart {

  public var images: [Image] = []
  public var videos: [Video] = []
  var delegates: NSHashTable<AnyObject> = NSHashTable.weakObjects()

  // MARK: - Initialization

  init() {

  }

  // MARK: - Delegate

  public func add(delegate: CartDelegate) {
    delegates.add(delegate)
  }

  // MARK: - Logic

  public func add(_ image: Image, newlyTaken: Bool = false) {
    guard image is(Video) == false else {
      add(image as! Video,newlyTaken: newlyTaken)
      return
    }
    guard !images.contains(image) else { return }

    images.append(image)

    for case let delegate as CartDelegate in delegates.allObjects {
      delegate.cart(self, didAdd: image, newlyTaken: newlyTaken)
    }
  }

  public func remove(_ image: Image) {
    guard image  is(Video) == false else {
      remove(image as! Video)
      return
    }
    guard let index = images.index(of: image) else { return }

    images.remove(at: index)

    for case let delegate as CartDelegate in delegates.allObjects {
      delegate.cart(self, didRemove: image)
    }
  }

  public func add(_ video: Video, newlyTaken: Bool = false) {
    guard !videos.contains(video) else { return }

    videos.append(video)

    for case let delegate as CartDelegate in delegates.allObjects {
      delegate.cart(self, didAdd: video, newlyTaken: newlyTaken)
    }
  }
  public func remove(_ video: Video) {
    guard let index = videos.index(of: video) else { return }

    videos.remove(at: index)

    for case let delegate as CartDelegate in delegates.allObjects {
      delegate.cart(self, didRemove: video)
    }
  }

  func contains(_ imageOrVideo:Image) -> Bool {
    if let video = imageOrVideo as? Video  {
      return self.videos.contains(video)
    } else if let image = imageOrVideo as? Image {
      return self.images.contains(image)
    }

    return false
  }

  func index(of item: Image) -> Int? {
    if let video = item as? Video {
      return self.videos.index(of:video)
    }

    return self.images.index(of:item)
  }

  public func reload(_ images: [Image]) {
    self.images = images

    for case let delegate as CartDelegate in delegates.allObjects {
      delegate.cartDidReload(self)
    }
  }

  // MARK: - Reset

  public func reset() {
   // video = nil
    images.removeAll()
    delegates.removeAllObjects()
  }
}
