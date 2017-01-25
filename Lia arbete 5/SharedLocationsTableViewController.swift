//
//  SharedLocationsTableViewController.swift
//  Lia arbete 5
//
//  Created by Daniel Trondsen Wallin on 2017-01-18.
//  Copyright © 2017 Daniel Trondsen Wallin. All rights reserved.
//

import UIKit
import Parse
import GoogleMaps
import Alamofire
import SwiftyJSON

class SharedLocationsTableViewController: UITableViewController {
    
    var long: [NSNumber] = []
    var lat: [NSNumber] = []
    var email: [String] = []
    var longitude: NSNumber = 0
    var latitude: NSNumber = 0
    var selected: Int? = nil
    var modesOfTransport: String = ""
    
    @IBOutlet weak var segmentControl: UISegmentedControl!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        getSharedLocation()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isToolbarHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.isToolbarHidden = true
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return email.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        // Configure the cell...
        //cell.textLabel?.text = "\(long[indexPath.row]), \(lat[indexPath.row]) \n\(email[indexPath.row])"
        let coordinate = CLLocationCoordinate2DMake(CLLocationDegrees(lat[indexPath.row]), CLLocationDegrees(long[indexPath.row]))
        let geocoder = GMSGeocoder()
        
        geocoder.reverseGeocodeCoordinate(coordinate) { (response, error) in
            if let address = response?.firstResult() {
                let lines = address.lines! as [String]
                cell.textLabel?.text = lines.joined(separator: ", ")
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selected = indexPath.row
        longitude = long[indexPath.row]
        latitude = lat[indexPath.row]
    }

    func getSharedLocation() {
        
        let query = PFQuery(className: "SharedLocations")
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print(error!.localizedDescription as Any)
            }
            else {
                
                if let returnedObjects = objects {
                    
                    for object in returnedObjects {
                        self.long.append(object["longitude"] as! NSNumber)
                        self.lat.append(object["latitude"] as! NSNumber)
                        self.email.append(object["SharedBy"] as! String)
                    }
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "BackToMaps" {
            let destination = segue.destination as! GoogleMapsViewController
            
            if selected != nil {
                if segmentControl.selectedSegmentIndex == 0 {
                    destination.modesOfTransport = "driving"
                    destination.otherLong = longitude
                    destination.otherLat = latitude
                }
                else if segmentControl.selectedSegmentIndex == 1 {
                    destination.modesOfTransport = "walking"
                    destination.otherLong = longitude
                    destination.otherLat = latitude
                }
                else if segmentControl.selectedSegmentIndex == 2 {
                    destination.modesOfTransport = "bicycling"
                    destination.otherLong = longitude
                    destination.otherLat = latitude
                }
                else if segmentControl.selectedSegmentIndex == 3 {
                    destination.modesOfTransport = "transit"
                    destination.otherLong = longitude
                    destination.otherLat = latitude
                }
            }
            else {
                print("ajanaka")
            }
        }
        
    }
    
    
    @IBAction func dismissViewButton(_ sender: Any) {
        if selected == nil {
            print("funkade inte")
        }
        else {
            performSegue(withIdentifier: "BackToMaps", sender: self)
        }
        
    }
    
}
