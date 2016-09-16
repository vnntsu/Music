//
//  AppDelegate.swift
//  ATMusic
//
//  Created by Nguyen Thanh Su on 8/1/16.
//  Copyright © 2016 at. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

let kAppDelegate = UIApplication.sharedApplication().delegate as? AppDelegate

enum RepeatType {
    case None
    case One
    case All
}

let kNotification = NSNotificationCenter.defaultCenter()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var detailPlayerVC: DetailPlayerViewController?
    var timerVC: TimerViewController?
    var repeating: RepeatType = .None
    var isCounting = false
    var isPause = false
    var timer: NSTimer?
    var restCounter = 0
    var isShuffle = false
    var shuffleArray: [Int] = [Int]()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = BaseTabBarController()
        setupRemoteControl()
        window?.makeKeyAndVisible()
        return true
    }

    func setupTimer() {
        timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(updateTimer(_:)), userInfo: nil, repeats: true)
    }

    @objc private func updateTimer(timer: NSTimer) {
        restCounter = restCounter - 1
        timerVC?.reloadTitleForRestTimeLabel()
        if restCounter == 0 {
            detailPlayerVC?.pause()
            timerVC?.setupWhenTimerDidStop()
            kAppDelegate?.isCounting = false
        }
    }

    func deleteDetailPlayer() {
        detailPlayerVC?.player?.cancelPendingPrerolls()
        detailPlayerVC?.player = nil
        detailPlayerVC?.dataSource = nil
        detailPlayerVC = nil
    }

    private func setupRemoteControl() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, withOptions: [])
            try AVAudioSession.sharedInstance().setActive(true)
            UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
            detailPlayerVC?.becomeFirstResponder()
        } catch {
            print(error)
        }
    }

    override func canBecomeFirstResponder() -> Bool {
        return true
    }

    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        if let remoteControl = event?.subtype {
            switch remoteControl {
            case .RemoteControlPlay:
                detailPlayerVC?.play()
            case .RemoteControlPause:
                detailPlayerVC?.pause()
            case .RemoteControlPreviousTrack:
                detailPlayerVC?.previousSong()
            case .RemoteControlNextTrack:
                detailPlayerVC?.nextSong()
            default: break
            }
        }
    }

    func applicationWillResignActive(application: UIApplication) {
        detailPlayerVC?.stopAnimationForImageVC()
    }

    func applicationDidEnterBackground(application: UIApplication) {
    }

    func applicationWillEnterForeground(application: UIApplication) {
    }

    func applicationDidBecomeActive(application: UIApplication) {
        detailPlayerVC?.startAnimationForImageVC()
    }

    func applicationWillTerminate(application: UIApplication) {
    }
}
