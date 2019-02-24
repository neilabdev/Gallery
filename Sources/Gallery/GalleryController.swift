import UIKit
import AVFoundation

@objc public   protocol GalleryControllerDelegate: AnyObject {

  func galleryController(_ controller: GalleryController, didSelectImages images: [Image])
  @objc optional func galleryController(_ controller: GalleryController, didSelectVideos videos: [Video])
  func galleryController(_ controller: GalleryController, didSelectVideo video: Video)
  func galleryController(_ controller: GalleryController, requestLightbox images: [Image])
  func galleryControllerDidCancel(_ controller: GalleryController)
}

extension  GalleryControllerDelegate {
  func galleryController(_ controller: GalleryController, didSelectVideos videos: [Video]) {} //optional
}

open class GalleryController: UIViewController, PermissionControllerDelegate {

  public weak var delegate: GalleryControllerDelegate?

  public let cart = Cart()

  // MARK: - Init

  public required init() {
    super.init(nibName: nil, bundle: nil)
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Life cycle

  open override func viewDidLoad() {
    super.viewDidLoad()

    setup()

    if let pagesController = makePagesController() {
      g_addChildController(pagesController)
    } else {
      let permissionController = makePermissionController()
      g_addChildController(permissionController)
    }
  }

  open override var prefersStatusBarHidden : Bool {
    return true
  }

  // MARK: - Child view controller

  func makeImagesController() -> ImagesController {
    let controller = ImagesController(cart: cart)
    controller.title = "Gallery.Images.Title".g_localize(fallback: "PHOTOS")

    return controller
  }

  func makeCameraController() -> CameraController {
    let controller = CameraController(cart: cart)
    controller.title = "Gallery.Camera.Title".g_localize(fallback: "CAMERA")

    return controller
  }

  func makeVideosController() -> VideosController {
    let controller = VideosController(cart: cart)
    controller.title = "Gallery.Videos.Title".g_localize(fallback: "VIDEOS")

    return controller
  }

  func makePagesController() -> PagesController? {
    guard Permission.Photos.status == .authorized else {
      return nil
    }

    let useCamera = Permission.Camera.needsPermission && Permission.Camera.status == .authorized

    let tabsToShow = Config.tabsToShow.compactMap { $0 != .cameraTab ? $0 : (useCamera ? $0 : nil) }

    let controllers: [UIViewController] = tabsToShow.compactMap { tab in
      if tab == .imageTab {
        return makeImagesController()
      } else if tab == .cameraTab {
        return makeCameraController()
      } else if tab == .videoTab {
        return makeVideosController()
      } else {
        return nil
      }
    }

    guard !controllers.isEmpty else {
      return nil
    }

    let controller = PagesController(controllers: controllers)
    controller.selectedIndex = tabsToShow.index(of: Config.initialTab ?? .cameraTab) ?? 0

    return controller
  }

  func makePermissionController() -> PermissionController {
    let controller = PermissionController()
    controller.delegate = self

    return controller
  }

  // MARK: - Setup

  func setup() {
    EventHub.shared.close = { [weak self] in
      if let strongSelf = self {
        strongSelf.delegate?.galleryControllerDidCancel(strongSelf)
      }
    }

    EventHub.shared.doneWithImages = { [weak self] in
      if let strongSelf = self {
        strongSelf.delegate?.galleryController(strongSelf, didSelectImages: strongSelf.cart.images)
      }
    }

    EventHub.shared.doneWithVideos = { [weak self] in
      if let strongSelf = self{
        let videos = strongSelf.cart.videos
        if Config.Camera.videoLimit == 0 || Config.Camera.videoLimit > 1 || videos.count > 1 {
          strongSelf.delegate?.galleryController(strongSelf, didSelectVideos: videos)
        } else  {
          strongSelf.delegate?.galleryController(strongSelf, didSelectVideo: videos.first!)
        }

      }
    }

    EventHub.shared.stackViewTouched = { [weak self] in
      if let strongSelf = self {
        strongSelf.delegate?.galleryController(strongSelf, requestLightbox: strongSelf.cart.images)
      }
    }
  }

  // MARK: - PermissionControllerDelegate

  func permissionControllerDidFinish(_ controller: PermissionController) {
    if let pagesController = makePagesController() {
      g_addChildController(pagesController)
      controller.g_removeFromParentController()
    }
  }
}
