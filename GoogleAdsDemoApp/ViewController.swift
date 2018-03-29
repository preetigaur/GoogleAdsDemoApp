//
//  ViewController.swift
//  GoogleAdsDemoApp
//
//  Created by Preeti Gaur on 22/03/18.
//  Copyright © 2018 Preeti Gaur. All rights reserved.
//

import UIKit
import GoogleMobileAds



class ViewController: UIViewController, GADInterstitialDelegate, GADBannerViewDelegate, UITableViewDelegate, UITableViewDataSource {
    
    
    /// The interstitial ad.
    var interstitial: GADInterstitial!
    @IBOutlet weak var bannerView: GADBannerView!
    @IBOutlet var tableView: UITableView!
    
    
    var tableViewItems = [AnyObject]()
    var adsToLoad = [GADBannerView]()
    var loadStateForAds = [GADBannerView: Bool]()
    let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    // A banner ad is placed in the UITableView once per `adInterval`. iPads will have a
    // larger ad interval to avoid mutliple ads being on screen at the same time.
    let adInterval = UIDevice.current.userInterfaceIdiom == .pad ? 12 : 6
    // The banner ad height.
    let adViewHeight = CGFloat(100)
    

    override func viewDidLoad() {
        super.viewDidLoad()
        //Interstitial ad set up
        interstitial = GADInterstitial(adUnitID: "ca-app-pub-3940256099942544/4411468910")
        interstitial.delegate = self
        let request = GADRequest()
        request.testDevices = [ kGADSimulatorID ]
        interstitial.load(request)
        
        //Banner Ad Set Up. Banner Add View is added at the bottom of the View.
        bannerView.adUnitID = bannerAdUnitID
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        
        
        self.tableView.register(UINib(nibName: "MenuItem", bundle: nil),
                           forCellReuseIdentifier: "MenuItemViewCell")
        self.tableView.register(UINib(nibName: "BannerAd", bundle: nil),
                           forCellReuseIdentifier: "BannerViewCell")
        
        // Allow row height to be determined dynamically while optimizing with an estimated row height.
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 135
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        addMenuItems()
        addBannerAds()
        preloadNextAd()
        self.tableView.reloadData()
        
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    // MARK: - UITableView delegate methods
    
     func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
     func tableView(_ tableView: UITableView,
                            heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let tableItem = tableViewItems[indexPath.row] as? GADBannerView {
            let isAdLoaded = loadStateForAds[tableItem]
            return isAdLoaded == true ? adViewHeight : 0
        }
        return UITableViewAutomaticDimension
    }
    
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewItems.count
    }
    
     func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let BannerView = tableViewItems[indexPath.row] as? GADBannerView {
            let reusableAdCell = tableView.dequeueReusableCell(withIdentifier: "BannerViewCell",
                                                               for: indexPath)
            
            // Remove previous GADBannerView from the content view before adding a new one.
            for subview in reusableAdCell.contentView.subviews {
                subview.removeFromSuperview()
            }
            
            reusableAdCell.contentView.addSubview(BannerView)
            // Center GADBannerView in the table cell's content view.
            BannerView.center = reusableAdCell.contentView.center
            
            return reusableAdCell
            
        } else {
            
            let menuItem = tableViewItems[indexPath.row] as? MenuItem
            
            let reusableMenuItemCell = tableView.dequeueReusableCell(withIdentifier: "MenuItemViewCell",
                                                                     for: indexPath) as! MenuItemViewCell
            
            reusableMenuItemCell.nameLabel.text = menuItem?.name
            reusableMenuItemCell.descriptionLabel.text = menuItem?.description
            reusableMenuItemCell.priceLabel.text = menuItem?.price
            reusableMenuItemCell.categoryLabel.text = menuItem?.category
            reusableMenuItemCell.photoView.image = menuItem?.photo
            
            return reusableMenuItemCell
        }
    }
    
    // MARK: - GADBannerView delegate methods
    
    func adViewDidReceiveAd(_ adView: GADBannerView) {
        // Mark banner ad as succesfully loaded.
        loadStateForAds[adView] = true
        // Load the next ad in the adsToLoad list.
        preloadNextAd()
    }
    
    func adView(_ adView: GADBannerView,
                didFailToReceiveAdWithError error: GADRequestError) {
        print("Failed to receive ad: \(error.localizedDescription)")
        // Load the next ad in the adsToLoad list.
        preloadNextAd()
    }
    
    // MARK: - UITableView source data generation
    
    /// Adds banner ads to the tableViewItems list.
    func addBannerAds() {
        var index = adInterval
        // Ensure subview layout has been performed before accessing subview sizes.
        tableView.layoutIfNeeded()
        while index < tableViewItems.count {
            let adSize = GADAdSizeFromCGSize(
                CGSize(width: tableView.contentSize.width, height: adViewHeight))
            let adView = GADBannerView(adSize: adSize)
            adView.adUnitID = bannerAdUnitID
            adView.rootViewController = self
            adView.delegate = self
            
            tableViewItems.insert(adView, at: index)
            adsToLoad.append(adView)
            loadStateForAds[adView] = false
            
            index += adInterval
        }
    }
    
    /// Preload banner ads sequentially. Dequeue and load next ad from `adsToLoad` list.
    func preloadNextAd() {
        if !adsToLoad.isEmpty {
            let ad = adsToLoad.removeFirst()
            let adRequest = GADRequest()
            adRequest.testDevices = [ kGADSimulatorID ]
            ad.load(adRequest)
        }
    }
    
    /// Adds MenuItems to the tableViewItems list.
    func addMenuItems() {
        var JSONObject: Any
        
        guard let path = Bundle.main.url(forResource: "menuItemsJSON",
                                         withExtension: "json") else {
                                            print("Invalid filename for JSON menu item data.")
                                            return
        }
        
        do {
            let data = try Data(contentsOf: path)
            JSONObject = try JSONSerialization.jsonObject(with: data,
                                                          options: JSONSerialization.ReadingOptions())
        } catch {
            print("Failed to load menu item JSON data: %s", error)
            return
        }
        
        guard let JSONObjectArray = JSONObject as? [Any] else {
            print("Failed to cast JSONObject to [AnyObject]")
            return
        }
        
        for object in JSONObjectArray {
            guard let dict = object as? [String: Any],
                let menuIem = MenuItem(dictionary: dict) else {
                    print("Failed to load menu item JSON data.")
                    return
            }
            tableViewItems.append(menuIem)
        }
    }
    
    // MARK: -Interstitial Ad Delegate Methods
    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        interstitial.present(fromRootViewController: self)
    }
    
    func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        print(error)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

