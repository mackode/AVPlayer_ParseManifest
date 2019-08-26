//
//  PlayerViewController.swift
//  AVPlayer_ParseManifest
//
//  Created by Mackode - Bartlomiej Makowski on 15/08/2019.
//  Copyright © 2019 com.castlabs.player.parsemanifest. All rights reserved.
//

import UIKit
import AVKit

class PlayerViewController: AVPlayerViewController, AVPlayerViewControllerDelegate, AVAssetResourceLoaderDelegate {

    var playerItem: AVPlayerItem!
    var metadataCollector: AVPlayerItemMetadataCollector!
    var identifier: Int = 0
    let formatter = DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        self.formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"

        // setup AVPlayer
        let videoURLString = "proxy://https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8"
        let videoURL = URL(string: videoURLString)
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
        let asset = AVURLAsset(url: videoURL!)
        asset.resourceLoader.setDelegate(self, queue: DispatchQueue(label: "asset.resource.loader"))

        asset.loadValuesAsynchronously(forKeys: ["playable"]) {
            DispatchQueue.main.async {
                self.playerItem = AVPlayerItem(asset: asset)
                self.player = AVPlayer(playerItem: self.playerItem)
                //self.player?.automaticallyWaitsToMinimizeStalling = false
                self.player?.play()
            }
        }
    }

    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        let scheme = loadingRequest.request.url?.scheme

        if scheme == "proxy" {
            let url = URL(string: String((loadingRequest.request.url?.absoluteString.dropFirst(8))!))!
            if url.absoluteString.contains("master.m3u8") {
                DispatchQueue.main.async {
                    let url = URL(string: String((loadingRequest.request.url?.absoluteString.dropFirst(8))!))!
                    // TODO: error handling
                    let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                        guard let data = data else { return }
                        self.parseManifest(String(data: data, encoding: .utf8)!)
                        loadingRequest.dataRequest?.respond(with: data)
                        loadingRequest.finishLoading()
                    }
                    task.resume()
                }
            } else {
                let redirect = URLRequest.init(url: url)
                loadingRequest.redirect = redirect
                let response = HTTPURLResponse.init(url: url, statusCode: 302, httpVersion: nil, headerFields: nil)

                loadingRequest.response = response
                loadingRequest.finishLoading()
            }

            return true
        }

        return false
    }

    func parseManifest(_ manifest: String) {
        print(manifest)
    }

}

