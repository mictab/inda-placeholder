//
//  StoryTableViewController.swift
//  Hacker News
//
//  Created by Michel Tabari on 5/4/16.
//  Copyright © 2016 Michel Tabari. All rights reserved.
//

import UIKit
import SafariServices
import Firebase

class StoryTableViewController: UITableViewController, SFSafariViewControllerDelegate, UISearchBarDelegate {
    
    // MARK: Properties
    var stories = [Story]()
    var filteredStories = [Story]()
    var firebase: Firebase!
    let baseUrl = "https://hacker-news.firebaseio.com/v0/"
    let storyNumLimit: UInt = 60
    var storyType: String = "topstories"
    let dateFormatter = NSDateFormatter()
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var segmentedController: UISegmentedControl!
    @IBOutlet weak var nestedStackView: UIStackView! {
        didSet {
            nestedStackView.layoutMargins = UIEdgeInsets(top: 0.0, left: 7.0, bottom: 0.0, right: 7.0)
            nestedStackView.layoutMarginsRelativeArrangement = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        firebase = Firebase(url: baseUrl)
        self.dateFormatter.dateFormat = "HH:mm"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barTintColor = Colors.greyishTint
        searchBar.delegate = self
        getStories()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return stories.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let identifier = "StoryTableViewCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as! StoryTableViewCell
        let story = stories[indexPath.row]
        
        cell.titleLabel.text = story.title
        if story.score > 1 {
            cell.detailLabel.text = "\(story.score) points by \(story.author), published at \(story.time)"
        } else {
            cell.detailLabel.text = "\(story.score) point by \(story.author), published at \(story.time)"
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let story = stories[indexPath.row]
        if let url = story.url {
            let webViewController = SFSafariViewController(URL: NSURL(string: url)!, entersReaderIfAvailable: true)
            webViewController.delegate = self
            presentViewController(webViewController, animated: true, completion: nil)
        }
    }
    
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func getStories() {
        let item = "item"
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        self.stories = []
        // Map each Id to a story
        var storiesMap = [Int:Story]()
        let dataQuery = firebase.childByAppendingPath(storyType).queryLimitedToFirst(storyNumLimit)
        dataQuery.observeSingleEventOfType(.Value, withBlock:  {
            snapshot in let ids = snapshot.value as! [Int]
            for id in ids {
                let dataQuery = self.firebase.childByAppendingPath(item).childByAppendingPath(String(id))
                dataQuery.observeSingleEventOfType(.Value, withBlock: {
                    snapshot in storiesMap[id] = self.getStoryDetail(snapshot)
                    if storiesMap.count == Int(self.storyNumLimit) {
                        // We have our stories
                        for id in ids {
                            // Newest first
                            self.stories.append(storiesMap[id]!)
                        }
                        self.tableView.reloadData()
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                        print("Stories are in!")
                    }
                })
            }
        })
    }
    
    func getStoryDetail(snapshot: FDataSnapshot) -> Story {
        let title = snapshot.value["title"] as! String
        let url = snapshot.value["url"] as? String
        let author = snapshot.value["by"] as! String
        let score = snapshot.value["score"] as! Int
        let time = NSDate(timeIntervalSince1970: snapshot.value["time"] as! Double)
        let dateString = dateFormatter.stringFromDate(time)
        
        return Story(title: title, url: url, author: author, score: score, time: dateString)
    }
    
    @IBAction func changeStoryType(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            self.storyType = "topstories"
            getStories()
        } else if sender.selectedSegmentIndex == 1 {
            self.storyType = "newstories"
            getStories()
        } else {
            print("Not yet implemented")
        }
    }
    
    @IBAction func scrollToTop(sender: UIBarButtonItem) {
        self.tableView.setContentOffset(CGPointMake(0, 0 - self.tableView.contentInset.top), animated: true)
    }
}
