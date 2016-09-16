//
//  BaseVC.swift
//  ATMusic
//
//  Created by Nguyen Thanh Su on 8/4/16.
//  Copyright © 2016 at. All rights reserved.
//

import UIKit
import SwiftUtils

typealias AddFinished = () -> Void

class BaseVC: ViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        loadData()
        configUI()
    }

    func loadData() { }

    func configUI() { }

    // Show actionsheet to add song into playlist
    func addSongIntoPlaylist(song: Song?) {
        guard let playlists = RealmManager.getAllPlayList() where !playlists.isEmpty else {
            Alert.sharedInstance.showActionSheet(self, title: Strings.AddPlaylist, message: Strings.AddPlaylistMessage,
                options: nil) { (index, isCreate) in
                    if isCreate {
                        self.createNewPlaylist({
                            self.addSongIntoPlaylist(song)
                        })
                    }
            }
            return
        }

        var options: [String] = [String]()
        for item in playlists {
            options.append(item.name)
        }
        Alert.sharedInstance.showActionSheet(self, title: Strings.AddPlaylist, message: Strings.AddPlaylistMessage,
            options: options) { (index, isCreate) in
                if isCreate {
                    self.createNewPlaylist({
                        self.addSongIntoPlaylist(song)
                    })
                } else {
                    if let song = song, index = index {
                        if playlists[index].addSong(song) {
                            Alert.sharedInstance.showAlert(self, title: Strings.Success, message: Strings.AddSongSuccess.concat(song.songName))
                            kNotification.postNotificationName(Strings.NotiReloadWhenAddNew, object: nil, userInfo: [Strings.Playlist: playlists[index].name])
                        } else {
                            Alert.sharedInstance.showAlert(self, title: Strings.Failure, message: Strings.ExistSong.concat(song.songName))
                        }
                    }
                }
        }
    }

    func createDetailPlaylist(song: Song?, playlistName: String?, indexPath: NSIndexPath, isChangePlaylist: Bool) {
        kAppDelegate?.deleteDetailPlayer()
        kAppDelegate?.detailPlayerVC = DetailPlayerViewController(song: song,
            songIndex: indexPath.row, playlistName: playlistName, changePlaylist: isChangePlaylist)
    }

    private func createNewPlaylist(finished: AddFinished) {
        let playlistNameObject = PlaylistName.firstItemFree()
        Alert.sharedInstance.inputTextAlert(self, title: Strings.Create,
            message: Strings.CreateQuestion,
            placeholder: playlistNameObject.name) { (text, isUse) in
                let text = text.trimmedCJK()
                if text == "" {
                    Alert.sharedInstance.showAlert(self, title: Strings.Warning, message: Strings.EmptyPlaylistName)
                } else {
                    if Playlist.checkExist(playlistName: text) {
                        Alert.sharedInstance.showAlert(self, title: Strings.CanNotAddPlaylist, message: Strings.PlaylistExist)
                    } else {
                        playlistNameObject.setUsing(isUse)
                        if !isUse && Helper.checkingPlayList(text) {
                            if let item = PlaylistName.getItemWithName(text) {
                                item.setUsing(true)
                            } else {
                                RealmManager.add(PlaylistName(isUse: true))
                            }
                        }
                        RealmManager.add(Playlist(name: text))
                        NSNotificationCenter.defaultCenter().postNotificationName(Strings.NotiReloadWhenAddNew, object: nil, userInfo: nil)
                        finished()
                    }
                }
        }
    }

}
