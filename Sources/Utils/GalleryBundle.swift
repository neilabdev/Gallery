import UIKit
import Foundation

class GalleryBundle {
  static func image(_ named: String) -> UIImage? {
    let bundleForClass = Bundle(for: GalleryBundle.self)
    let bundleURL = bundleForClass.resourceURL?.appendingPathComponent("Gallery.bundle")

    if let url = bundleURL, let resourceBundle = Bundle(url: url) { // NOTE: Should always succeed
      return UIImage(named: named, in: resourceBundle, compatibleWith: nil)
    } else {
      let bundle = Bundle(for: Bundle.self)
      return UIImage(named: "Gallery.bundle/\(named)", in: bundle, compatibleWith: nil)
    }
  }
}
