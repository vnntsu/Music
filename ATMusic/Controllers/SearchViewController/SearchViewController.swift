//
//  SearchViewController.swift
//  ATMusic
//
//  Created by Nguyen Thanh Su on 8/1/16.
//  Copyright © 2016 at. All rights reserved.
//

import UIKit
import SVPullToRefresh

private let kTableviewTopMargin: CGFloat = 64
private let kTableviewBottomMargin: CGFloat = 49

class SearchViewController: BaseVC {
    // MARK: - private outlet
    @IBOutlet private weak var tableView: UITableView!
//    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var paddingTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var dataLabel: UILabel!

    // MARK: - private property
    private let limit = 20
    private var offset = 0
    private var songs: [Song]?
    private var searchText = ""
    private var blurView: UIView?
//    private var searchBar = UISearchBar()
    lazy var searchBar = UISearchBar()
    // MARK: - override func
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func configUI() {
        dataLabel.font = HelveticaFont().Regular(20)
        searchBar.returnKeyType = .Done
        searchBar.autocorrectionType = .No
        searchBar.delegate = self
        searchBar.placeholder = Strings.Search
        searchBar.tintColor = Color.Red225
        navigationItem.titleView = searchBar
        navigationController?.navigationBar.backgroundColor = Color.White178
        tableView.separatorStyle = .None
        super.configUI()
        tableView.contentInset = UIEdgeInsets(top: kTableviewTopMargin, left: 0, bottom: kTableviewBottomMargin, right: 0)
        tableView.registerNib(TrackTableViewCell)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.addInfiniteScrollingWithActionHandler {
            self.loadSong()
        }
//        hideBottomBorder()
    }

    override func loadData() {
        songs = [Song]()
    }

    override func createDetailPlaylist(song: Song?, playlistName: String?, indexPath: NSIndexPath, isChangePlaylist: Bool) {
        super.createDetailPlaylist(song, playlistName: playlistName, indexPath: indexPath, isChangePlaylist: isChangePlaylist)
        kAppDelegate?.detailPlayerVC?.dataSource = self
        tabBarController?.presentPopupBarWithContentViewController(kAppDelegate?.detailPlayerVC ?? DetailPlayerViewController(),
            animated: true, completion: nil)
    }

    // MARK: - private func
    private func loadSong() {
        if let isEmpty = songs?.isEmpty where isEmpty {
            self.tableView.infiniteScrollingView.stopAnimating()
            return
        }
        offset += limit
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        APIManager.sharedInstance.searchSong(withKey: searchText, limit: limit, atOffet: offset) { (result, error, message) in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            if error {
                print("ERROR: \(message)")
            } else {
                guard let result = result else { return }
                self.songs?.appendContentsOf(result)
                self.tableView.reloadData()
                kAppDelegate?.detailPlayerVC?.reloadWhenChangeSongList(playlistName: Strings.Search, index: -1)
            }
            self.tableView.infiniteScrollingView.stopAnimating()
        }
    }

    private func hideKeyBoardAndCancelButton() {
        UIView.animateWithDuration(0.7) {
            self.searchBar.resignFirstResponder()
            self.searchBar.showsCancelButton = false
        }
    }

//    private func hideBottomBorder() {
//        for view in (navigationController?.navigationBar.subviews.filter({
//            NSStringFromClass($0.dynamicType) == "_UINavigationBarBackground" }))! as [UIView] {
//                if let imageView = view.subviews.filter({ $0 is UIImageView }).first as? UIImageView {
//                    imageView.removeFromSuperview()
//                }
//        }
//    }
}

// MARK: - UITableViewDelegate and DataSource
extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return TrackTableViewCell.cellHeight()
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs?.count ?? 0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(TrackTableViewCell)
        cell.configCellWithTrack(songs?[indexPath.row], index: indexPath.row, showButtonMore: true)
        cell.delegate = self
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if kAppDelegate?.detailPlayerVC?.getPlaylistName() != Strings.Search {
            createDetailPlaylist(songs?[indexPath.row],
                playlistName: Strings.Search,
                indexPath: indexPath, isChangePlaylist: true)
        } else {
            guard kAppDelegate?.detailPlayerVC?.currentSongID() != songs?[indexPath.row].id else {
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
                return
            }
            createDetailPlaylist(songs?[indexPath.row],
                playlistName: Strings.Search,
                indexPath: indexPath, isChangePlaylist: false)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    func scrollViewDidScroll(scrollView: UIScrollView) {
        hideKeyBoardAndCancelButton()
    }

    func scrollViewWillEndDragging(scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>) {
            UIView.animateWithDuration(0.4, delay: 0, options: .CurveEaseOut,
                animations: {
                    if velocity.y == 0 { return }
                    let constant = velocity.y > 0 ? (64 - self.searchBar.bounds.height) : 64
                    self.paddingTopConstraint.constant = constant
                    self.searchBar.layoutIfNeeded()
                },
                completion: { finished in })

    }
}

// MARK: - UISearchBarDelegate
extension SearchViewController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(true, animated: true)
        return true
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        hideKeyBoardAndCancelButton()
    }

    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        hideKeyBoardAndCancelButton()
    }

    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            songs?.removeAll()
            tableView.reloadData()
            kAppDelegate?.detailPlayerVC?.reloadWhenChangeSongList(playlistName: Strings.Search, index: -1)
            dataLabel.hidden = false
            APIManager.sharedInstance.cancelRequest()
            return
        }
        if searchText.characters.last == " " {
            return
        }
        self.searchText = searchText
        APIManager.sharedInstance.searchSong(withKey: searchText, limit: limit, atOffet: offset) { (result, error, message) in
            if error {
                print("ERROR: \(message)")
            } else {
                self.songs = result
                self.tableView.reloadData()
                kAppDelegate?.detailPlayerVC?.reloadWhenChangeSongList(playlistName: Strings.Search, index: -1)
                self.dataLabel.hidden = true
            }
        }
    }
}

// MARK: - TrackTableViewCellDelegate
extension SearchViewController: TrackTableViewCellDelegate {
    func didTapMoreButton(tableViewCell: TrackTableViewCell, cellIndex: Int) {
        addSongIntoPlaylist(songs?[cellIndex])
    }
}

// MARK: - DetailPlayerDelegate
extension SearchViewController: DetailPlayerDataSource {
    func numberOfSongInPlaylist(viewController: UIViewController) -> Int? {
        return songs?.count
    }

    func songInPlaylist(viewController: UIViewController, atIndex index: Int) -> Song? {
        return songs?[index]
    }

    func songNameList(viewController: UIViewController) -> [String]? {
        var songNameList: [String] = [String]()
        guard let songs = songs else { return nil }
        for item in songs {
            if let name = item.songName {
                songNameList.append(name)
            }
        }
        return songNameList
    }
}
