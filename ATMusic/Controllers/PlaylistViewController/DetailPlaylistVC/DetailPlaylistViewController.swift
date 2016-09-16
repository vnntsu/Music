//
//  DetailPlaylistViewController.swift
//  ATMusic
//
//  Created by Nguyen Thanh Su on 8/17/16.
//  Copyright © 2016 at. All rights reserved.
//

import UIKit
import SDWebImage

class DetailPlaylistViewController: BaseVC {

    // MARK: - private outlet
    @IBOutlet private weak var avatar: UIImageView!
    @IBOutlet private weak var playlistNameTextField: UITextField!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var numberOfSong: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var editButton: UIButton!

    // MARK: - private property
    private var playlist: Playlist?
    private var index = 0
    private var isEnableToEditNamePlaylist = false
    private var isCurrentPlaylistAtParentVC = false

    // MARK: - override func
    convenience init(playlist: Playlist?, index: Int, isCurrentPlaylistAtParentVC: Bool) {
        self.init()
        self.playlist = playlist
        self.index = index
        self.isCurrentPlaylistAtParentVC = isCurrentPlaylistAtParentVC
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func configUI() {
        navigationController?.navigationBar.tintColor = Color.Red225
        navigationItem.backBarButtonItem?.title = ""
        setupImage()
        if let imageURLString = playlist?.songs.first?.urlImage, imageURL = NSURL(string: imageURLString) {
            avatar.sd_setImageWithURL(imageURL)
        }
        playlistNameTextField.text = playlist?.name
        playlistNameTextField.enabled = false
        setTextForNumberSongLabel()
        tableView.registerNib(TrackTableViewCell)
        tableView.delegate = self
        tableView.dataSource = self
        playlistNameTextField.delegate = self
    }

    override func createDetailPlaylist(song: Song?, playlistName: String?, indexPath: NSIndexPath, isChangePlaylist: Bool) {
        super.createDetailPlaylist(song, playlistName: playlistName, indexPath: indexPath, isChangePlaylist: isChangePlaylist)
        kAppDelegate?.detailPlayerVC?.dataSource = self
        tabBarController?.presentPopupBarWithContentViewController(kAppDelegate?.detailPlayerVC ?? DetailPlayerViewController(),
            animated: true, completion: nil)
    }

    // MARK: - private func
    @IBAction private func didTapEditButton(sender: UIButton) {
        isEnableForEdit()
    }

    @IBAction private func didTapDeleteButton(sender: UIButton) {
        Alert.sharedInstance.showConfirmAlert(self, title: Strings.Warning, message: Strings.Delete) {
            if self.playlist?.name == kAppDelegate?.detailPlayerVC?.getPlaylistName() {
                Alert.sharedInstance.showAlert(self, title: Strings.Error, message: Strings.DeletePlaylistFailure)
                return
            }
            if Helper.checkingPlayList(self.playlist?.name) {
                if let item = PlaylistName.getItemWithName(self.playlist?.name) {
                    item.setUsing(false)
                }
            }
            self.navigationController?.popViewControllerAnimated(true)
            kNotification.postNotificationName(
                Strings.NotificationDeletePlaylist,
                object: nil,
                userInfo: [Strings.NotiCellIndex: self.index])
        }
    }

    private func isEnableForEdit() {
        if isEnableToEditNamePlaylist {
            let text = playlistNameTextField.text?.trimmedCJK()
            if text == "" {
                Alert.sharedInstance.showAlert(self, title: Strings.Warning, message: Strings.EmptyPlaylistName)
            } else {
                if text != playlist?.name {
                    playlist?.setNameWithText(text)
                    NSNotificationCenter.defaultCenter().postNotificationName(
                        Strings.NotiChangePlaylistName,
                        object: nil,
                        userInfo: [Strings.NotiCurrentPlaylistAtParentVC: isCurrentPlaylistAtParentVC])
                }
            }
            playlistNameTextField.borderStyle = .None
        } else {
            playlistNameTextField.borderStyle = .RoundedRect
        }
        playlistNameTextField.text = playlist?.name
        isEnableToEditNamePlaylist = !isEnableToEditNamePlaylist
        editButton.setTitle(getTextForButtonEdit(), forState: .Normal)
        playlistNameTextField.enabled = isEnableToEditNamePlaylist
        playlistNameTextField.becomeFirstResponder()
        titleLabel.hidden = !isEnableToEditNamePlaylist
    }

    private func getTextForButtonEdit() -> String {
        return isEnableToEditNamePlaylist ? Strings.Save : Strings.Edit
    }

    private func setTextForNumberSongLabel() {
        if let number = playlist?.songs.count {
            numberOfSong.text = number > 1 ? "\(number) songs" : "\(number) song"
        }
    }

    private func setupImage() {
        if let imageURLString = playlist?.songs.first?.urlImage, imageURL = NSURL(string: imageURLString) {
            avatar.sd_setImageWithURL(imageURL)
        } else {
            avatar.image = UIImage()
        }
    }
}

// MARK: - TableView delegate and datasource
extension DetailPlaylistViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return TrackTableViewCell.cellHeight()
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlist?.songs.count ?? 0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(TrackTableViewCell)
        cell.configCellWithTrack(playlist?.songs[indexPath.row], index: indexPath.row, showButtonMore: false)
        return cell
    }

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .Normal, title: Strings.DeleteString) { (action, indexPath) in
            if indexPath.row == kAppDelegate?.detailPlayerVC?.getSongIndex() {
                Alert.sharedInstance.showAlert(self, title: Strings.DeleteError, message: Strings.SongIsPlaying)
            } else {
                tableView.beginUpdates()
                self.playlist?.deleteSongAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                tableView.endUpdates()
                self.setTextForNumberSongLabel()
                self.setupImage()
                kNotification.postNotificationName(Strings.NotiDeleteSong,
                    object: nil, userInfo: [Strings.NotiCellIndex: indexPath,
                        Strings.NotiCurrentPlaylistAtParentVC: self.isCurrentPlaylistAtParentVC])
            }

        }
        deleteAction.backgroundColor = UIColor.redColor()
        return [deleteAction]
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if kAppDelegate?.detailPlayerVC?.getPlaylistName() != playlist?.name {
            createDetailPlaylist(playlist?.songs[indexPath.row],
                playlistName: playlist?.name,
                indexPath: indexPath, isChangePlaylist: true)
        } else {
            guard kAppDelegate?.detailPlayerVC?.currentSongID() != playlist?.songs[indexPath.row].id else {
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
                return
            }
            createDetailPlaylist(playlist?.songs[indexPath.row],
                playlistName: playlist?.name,
                indexPath: indexPath, isChangePlaylist: false)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}

// MARK: - TextField Delegate
extension DetailPlaylistViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        isEnableForEdit()
        return true
    }
}

// MARK: - DetailPlayerDelegate
extension DetailPlaylistViewController: DetailPlayerDataSource {

    func numberOfSongInPlaylist(viewController: UIViewController) -> Int? {
        return playlist?.songs.count
    }

    func songInPlaylist(viewController: UIViewController, atIndex index: Int) -> Song? {
        return playlist?.songs[index]
    }

    func songNameList(viewController: UIViewController) -> [String]? {
        return nil
    }
}
