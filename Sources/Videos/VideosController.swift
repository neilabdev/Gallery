import UIKit
import Photos
import AVKit

class VideosController: UIViewController {

  lazy var gridView: GridView = self.makeGridView()
  lazy var videoBox: VideoBox = self.makeVideoBox()
  lazy var infoLabel: UILabel = self.makeInfoLabel()
  lazy var stackView: StackView = self.makeStackView()

  var items: [Video] = []
  let library = VideosLibrary()
  let once = Once()
  let cart: Cart

  // MARK: - Init

  public required init(cart: Cart) {
    self.cart = cart
    super.init(nibName: nil, bundle: nil)
    cart.delegates.add(self)
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Life cycle

  override func viewDidLoad() {
    super.viewDidLoad()

    setup()
  }

  // MARK: - Setup

  func setup() {
    view.backgroundColor = UIColor.white

    view.addSubview(gridView)

    [videoBox, infoLabel].forEach {
      gridView.bottomView.addSubview($0)
    }

    gridView.bottomView.addSubview(stackView)

    gridView.g_pinEdges()

    videoBox.g_pin(size: CGSize(width: 44, height: 44))
    videoBox.g_pin(on: .centerY)
    videoBox.g_pin(on: .left, constant: 38)

    infoLabel.g_pin(on: .centerY)
    infoLabel.g_pin(on: .left, view: videoBox, on: .right, constant: 11)
    infoLabel.g_pin(on: .right, constant: -50)


    stackView.g_pin(on: .centerY, constant: -4)
    stackView.g_pin(on: .left, constant: 38)
    stackView.g_pin(size: CGSize(width: 56, height: 56))

    gridView.closeButton.addTarget(self, action: #selector(closeButtonTouched(_:)), for: .touchUpInside)
    gridView.doneButton.addTarget(self, action: #selector(doneButtonTouched(_:)), for: .touchUpInside)
    stackView.addTarget(self, action: #selector(stackViewTouched(_:)), for: .touchUpInside)

    gridView.collectionView.dataSource = self
    gridView.collectionView.delegate = self
    gridView.collectionView.register(VideoCell.self, forCellWithReuseIdentifier: String(describing: VideoCell.self))

    gridView.arrowButton.updateText("Gallery.AllVideos".g_localize(fallback: "ALL VIDEOS"))
    gridView.arrowButton.arrow.isHidden = true
  }

  // MARK: - Action

  @objc func closeButtonTouched(_ button: UIButton) {
    EventHub.shared.close?()
  }

  @objc func doneButtonTouched(_ button: UIButton) {
    EventHub.shared.doneWithVideos?()
  }

  @objc func stackViewTouched(_ stackView: StackView) {
    EventHub.shared.stackViewTouched?()
  }

  // MARK: - View

  func refreshView() {
    let hasVideos = !cart.videos.isEmpty
    gridView.bottomView.g_fade(visible: hasVideos)
    gridView.collectionView.g_updateBottomInset(hasVideos ? gridView.bottomView.frame.size.height : 0)
    /*
    if let selectedItem = cart.video {
      videoBox.imageView.g_loadImage(selectedItem.asset)
    } else {
      videoBox.imageView.image = nil
    }

    let hasVideo = (cart.video != nil)
    gridView.bottomView.g_fade(visible: hasVideo)
    gridView.collectionView.g_updateBottomInset(hasVideo ? gridView.bottomView.frame.size.height : 0)

    cart.video?.fetchDuration { [weak self] duration in
      self?.infoLabel.isHidden = duration <= Config.VideoEditor.maximumDuration
    } */
  }

  // MARK: - Controls

  func makeGridView() -> GridView {
    let view = GridView()
    view.bottomView.alpha = 0
    
    return view
  }

  func makeVideoBox() -> VideoBox {
    let videoBox = VideoBox()
    videoBox.delegate = self

    return videoBox
  }

  func makeInfoLabel() -> UILabel {
    let label = UILabel()
    label.textColor = UIColor.white
    label.font = Config.Font.Text.regular.withSize(12)
    label.text = String(format: "Gallery.Videos.MaxiumDuration".g_localize(fallback: "FIRST %d SECONDS"),
                        (Int(Config.VideoEditor.maximumDuration)))

    return label
  }

  func makeStackView() -> StackView {
    let view = StackView()

    return view
  }
}

extension VideosController: PageAware {

  func pageDidShow() {
    once.run {
      library.reload {
        self.gridView.loadingIndicator.stopAnimating()
        self.items = self.library.items
        self.gridView.collectionView.reloadData()
        self.gridView.emptyView.isHidden = !self.items.isEmpty
      }
    }
  }
}

extension VideosController: VideoBoxDelegate {

  func videoBoxDidTap(_ videoBox: VideoBox) {
    cart.video?.fetchPlayerItem { item in
      guard let item = item else { return }

      DispatchQueue.main.async {
        let controller = AVPlayerViewController()
        let player = AVPlayer(playerItem: item)
        controller.player = player

        self.present(controller, animated: true) {
          player.play()
        }
      }
    }
  }
}

extension VideosController: CartDelegate {

  func cart(_ cart: Cart, didAdd image: Image, newlyTaken: Bool) {
    stackView.reload(cart.videos, added: true)
    refreshView()

    //if newlyTaken {
    //  refreshSelectedAlbum()
    //}
  }

  func cart(_ cart: Cart, didRemove image: Image) {
    stackView.reload(cart.videos)
    refreshView()
  }

  func cartDidReload(_ cart: Cart) {
    stackView.reload(cart.videos)
    refreshView()
    //refreshSelectedAlbum()
  }
}


extension VideosController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

  // MARK: - UICollectionViewDataSource

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return items.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: VideoCell.self), for: indexPath)
      as! VideoCell
    let item = items[(indexPath as NSIndexPath).item]

    cell.configure(item)

    if self.supportsMultipleVideos == false {
      cell.frameView.label.isHidden = true
    }

    configureFrameView(cell, indexPath: indexPath)

    return cell
  }

  var supportsMultipleVideos :Bool {
    get {
      let v = Config.Camera.videoLimit == 0 ||  Config.Camera.videoLimit > 1 //Config.Camera.videoLimit > cart.videos.count
      return v
    }
  }

  var supportsAdditionalVideo: Bool {
    get {
      return Config.Camera.videoLimit == 0 || Config.Camera.videoLimit > cart.videos.count
    }
  }

  // MARK: - UICollectionViewDelegateFlowLayout

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

    let size = (collectionView.bounds.size.width - (Config.Grid.Dimension.columnCount - 1) * Config.Grid.Dimension.cellSpacing)
      / Config.Grid.Dimension.columnCount
    return CGSize(width: size, height: size)
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let item = items[(indexPath as NSIndexPath).item]

    if cart.contains(item) {
      cart.remove(item)
    } else  if let video = item as? Video  {

      if self.supportsMultipleVideos == false {
        cart.videos.removeAll()
      }

      if supportsAdditionalVideo == true  {
        cart.add(item)
      }
    }

    /*

    if let selectedItem = cart.video , selectedItem == item {
      cart.video = nil
    } else {
      cart.video = item
    }

    refreshView()*/
    configureFrameViews()
  }

  func configureFrameViews() {
    for case let cell as VideoCell in gridView.collectionView.visibleCells {
      if let indexPath = gridView.collectionView.indexPath(for: cell) {
        configureFrameView(cell, indexPath: indexPath)
      }
    }
  }

  func configureFrameView(_ cell: VideoCell, indexPath: IndexPath) {
    let item = items[(indexPath as NSIndexPath).item]

    if let index = cart.index(of: item) {
      cell.frameView.g_quickFade()
      cell.frameView.label.text = "\(index + 1)"
    } else {
      cell.frameView.alpha = 0
    }
/*
    if let selectedItem = cart.video , selectedItem == item {
      cell.frameView.g_quickFade()
    } else {
      cell.frameView.alpha = 0
    } */
  }
}
