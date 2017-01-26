//
//  GoogleMapsViewController.swift
//  Lia arbete 5
//
//  Created by Daniel Trondsen Wallin on 2016-10-20.
//  Copyright © 2016 Daniel Trondsen Wallin. All rights reserved.
//

import UIKit
import GoogleMaps
import CoreLocation
import Parse
import Foundation
import Alamofire
import SwiftyJSON


class GoogleMapsViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {
    
    @IBOutlet weak var addressLabel: UILabel!
    
    let locationManager = CLLocationManager()
    var currentLocation = CLLocation()
    let baseURL = "https://maps.googleapis.com/maps/api/"
    let API_KEY = Config.googleAPI
    var test: Int = 0
    
    var returnedLongitude: [NSNumber] = []
    var returnedLatitude: [NSNumber] = []
    var sharedLocation: [Bool] = []
    var willYouShareYourLocation: Bool = false
    var directionsActive = false
    var email: String = ""
    var objectId: String = ""
    var i = 0
    var marker = GMSMarker()
    
    var modesOfTransport: String = "driving"
    var otherLong: NSNumber = 0
    var otherLat: NSNumber = 0
    
    var otherLong2: NSNumber = 0
    var otherLat2: NSNumber = 0
    
    var timer = Timer()
    
    var newLocation = CLLocation()
    
    var mapView = GMSMapView()
    
    let segmentedControl = UISegmentedControl(items: ["Driving", "Walking", "Bicycling", "Transit"])
    
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {
        
        let image: UIImage = #imageLiteral(resourceName: "facebook-button.png")
        let height = image.size.height
        let width = image.size.width
        
        let navBarHeight: CGFloat = self.navigationController!.navigationBar.frame.height

        segmentedControl.frame = CGRect(x: 0, y: navBarHeight + 20, width: mapView.frame.size.width, height: 30)
        segmentedControl.backgroundColor = UIColor.white
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.isHidden = true
        segmentedControl.addTarget(self, action: #selector(GoogleMapsViewController.segmentedControlValueChanged), for: UIControlEvents.valueChanged)
        
        
        let button = UIButton()
        button.frame = (frame: CGRect(x: (mapView.frame.size.width / 2 - (width / 2)), y: mapView.frame.size.height - 120, width: width, height: height))
        button.setImage(#imageLiteral(resourceName: "facebook-button.png"), for: .normal)
        button.setTitle("My button", for: .normal)
        mapView.addSubview(button)
        mapView.addSubview(segmentedControl)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func unwindSecondView(segue: UIStoryboardSegue) {
        checkIfUserHasASavedLocation()
        getOtherUsersLocation()
        runTimer()
    }
    
    
    override func loadView() {
        mapView.delegate = self

        if returnedLongitude.isEmpty == false {
            self.returnedLatitude.removeAll()
            self.returnedLongitude.removeAll()
            self.sharedLocation.removeAll()
        }

        i = 0
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        //locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        currentLocation = locationManager.location!
        
        let camera = GMSCameraPosition.camera(withTarget: currentLocation.coordinate, zoom: 18.0)
        mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        mapView.settings.myLocationButton = true
        mapView.settings.compassButton = true
        mapView.settings.zoomGestures = true
        mapView.isMyLocationEnabled = true
        mapView.settings.rotateGestures = false
        mapView.settings.indoorPicker = false
        mapView.settings.compassButton = true
        self.view = mapView
        
        checkIfUserHasASavedLocation()
        getOtherUsersLocation()
        runTimer()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        timer.invalidate()
    }
    
    
    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(GoogleMapsViewController.getOtherUsersLocation), userInfo: nil, repeats: true)
    }
    
    
    func segmentedControlValueChanged() {
        
        if segmentedControl.selectedSegmentIndex == 0 {
            self.modesOfTransport = "driving"
            getOtherUsersLocation()
        }
        else if segmentedControl.selectedSegmentIndex == 1 {
            self.modesOfTransport = "walking"
            getOtherUsersLocation()
        }
        else if segmentedControl.selectedSegmentIndex == 2 {
            self.modesOfTransport = "bicycling"
            getOtherUsersLocation()
        }
        else if segmentedControl.selectedSegmentIndex == 3 {
            self.modesOfTransport = "transit"
            getOtherUsersLocation()
        }
        
    }
    
    
    
    func getAddressFromLongLat(address: String) {
        let stringUrl = "https://maps.googleapis.com/maps/api/geocode/json?address=\(address)&key=\(Config.googleDirectionsGeolocationAPI)"
        let url = NSURL(string: stringUrl)
        let request = NSMutableURLRequest(url: url! as URL)
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            guard error == nil && data != nil else {
                print("Error: ", error!.localizedDescription as Any)
                return
            }
            
            let httpStatus = response as? HTTPURLResponse
            
            if httpStatus!.statusCode == 200 {
                
                if data?.count != 0 {
                    
                    let responseString = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! NSDictionary
                    let test = responseString["status"]! as! String
                    if test == "ZERO_RESULTS" {
                        let alert = UIAlertController(title: "Error", message: "That address is invalid", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                    else {
                        let results = responseString["results"] as! NSArray
                        let result = results[0] as! NSDictionary
                        let geometry = result["geometry"] as! NSDictionary
                        let location = geometry["location"] as! NSDictionary
                        let lat = location["lat"] as! NSNumber
                        let long = location["lng"] as! NSNumber
                        let position = CLLocationCoordinate2DMake(CLLocationDegrees(lat), CLLocationDegrees(long))
                        
                        let query = PFQuery(className: "SharedLocations")
                        query.whereKey("SharedBy", equalTo: self.email)
                        query.getFirstObjectInBackground(block: { (object, error) in
                            
                            if object == nil {
                                let shareLocation = PFObject(className: "SharedLocations")
                                shareLocation["SharedBy"] = self.email
                                shareLocation["longitude"] = long
                                shareLocation["latitude"] = lat
                                shareLocation.saveInBackground(block: { (success, error) in
                                    if error != nil {
                                        print(error!.localizedDescription as Any!)
                                    }
                                    else {
                                        self.marker = GMSMarker(position: position)
                                        self.marker.icon = GMSMarker.markerImage(with: UIColor.blue)
                                        self.marker.map = self.mapView
                                        self.otherLat = lat
                                        self.otherLong = long
                                        self.getOtherUsersLocation()
                                    }
                                })
                            }
                            else {
                                object?["SharedBy"] = self.email
                                object?["longitude"] = long
                                object?["latitude"] = lat
                                object?.saveInBackground(block: { (success, error) in
                                    if error != nil {
                                        print("hej")
                                        print(error!.localizedDescription as Any!)
                                    }
                                    else {
                                        self.marker = GMSMarker(position: position)
                                        self.marker.icon = GMSMarker.markerImage(with: UIColor.blue)
                                        self.marker.map = self.mapView
                                        self.otherLat = lat
                                        self.otherLong = long
                                        self.getOtherUsersLocation()
                                    }
                                })
                            }
                        })
                    }
                    
                }
                else {
                    print(error!.localizedDescription as Any)
                    let alert = UIAlertController(title: "Error", message: "That address is invalid", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
            else {
                print("Error HttpStatusCode is: ", httpStatus!.statusCode)
            }
        }
        task.resume()
    }
    
    
    
    
    
    func drawDirections() {
        if otherLong != 0 && otherLat != 0 && otherLong != otherLong2 && otherLat != otherLat2{
            self.segmentedControl.isHidden = false
            self.mapView.clear()
            otherLong2 = otherLong
            otherLat2 = otherLat
            let position = CLLocationCoordinate2DMake(CLLocationDegrees(self.otherLat), CLLocationDegrees(self.otherLong))
            self.marker = GMSMarker(position: position)
            self.marker.icon = GMSMarker.markerImage(with: UIColor.blue)
            self.marker.map = self.mapView
            
            directionsActive = true
            let stringUrl = "\(baseURL)directions/json?origin=\(currentLocation.coordinate.latitude),\(currentLocation.coordinate.longitude)&destination=\(otherLat),\(otherLong)&mode=\(modesOfTransport)&key=\(Config.googleDirectionsGeolocationAPI)"
            let url = NSURL(string: stringUrl)
            let request = NSMutableURLRequest(url: url! as URL)
            let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
                guard error == nil && data != nil else {
                    print("Error: ", error!.localizedDescription as Any)
                    return
                }
                
                let httpStatus = response as? HTTPURLResponse
                
                if httpStatus!.statusCode == 200 {
                    
                    if data?.count != 0 {
                        
                        let responseString = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! NSDictionary
                        let routes = responseString["routes"] as! NSArray
                        let routesDict = routes[0] as! NSDictionary
                        let legs = routesDict["legs"] as! NSArray
                        let legsDict = legs[0] as! NSDictionary
                        let distance = legsDict["distance"] as! NSDictionary
                        let duration = legsDict["duration"] as! NSDictionary
                        let distanceText = distance["text"]! as! String
                        let durationText = duration["text"]! as! String
                        print("Du ska ta dig \(distanceText) och det kommer ta ca \(durationText)")
                        
                        for route in routes as! [[AnyHashable:Any]] {
                            let routeOverviewPolyline = route["overview_polyline"] as! NSDictionary
                            let points = routeOverviewPolyline["points"] as? String
                            
                            DispatchQueue.main.sync {
                                let path = GMSPath.init(fromEncodedPath: points!)
                                let polyline = GMSPolyline.init(path: path)
                                polyline.strokeWidth = 3.0
                                polyline.map = self.mapView
                            }
                         }
                    }
                    else {
                        print("Something went wrong")
                    }
                    
                }
                else {
                    print("Error HttpStatusCode is: ", httpStatus!.statusCode)
                }
            }
            task.resume()
        }
        else if otherLong != 0 && otherLat != 0 && otherLong == otherLong2 && otherLat == otherLat2{
            self.segmentedControl.isHidden = false
            let position = CLLocationCoordinate2DMake(CLLocationDegrees(self.otherLat), CLLocationDegrees(self.otherLong))
            self.marker = GMSMarker(position: position)
            self.marker.icon = GMSMarker.markerImage(with: UIColor.blue)
            self.marker.map = self.mapView
            
            directionsActive = true
            let stringUrl = "\(baseURL)directions/json?origin=\(currentLocation.coordinate.latitude),\(currentLocation.coordinate.longitude)&destination=\(otherLat),\(otherLong)&mode=\(modesOfTransport)&key=\(Config.googleDirectionsGeolocationAPI)"
            let url = NSURL(string: stringUrl)
            let request = NSMutableURLRequest(url: url! as URL)
            let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
                guard error == nil && data != nil else {
                    print("Error: ", error!.localizedDescription as Any)
                    return
                }
                
                let httpStatus = response as? HTTPURLResponse
                
                if httpStatus!.statusCode == 200 {
                    
                    if data?.count != 0 {
                        
                        let responseString = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! NSDictionary
                        let routes = responseString["routes"] as! NSArray
                        let routesDict = routes[0] as! NSDictionary
                        let legs = routesDict["legs"] as! NSArray
                        let legsDict = legs[0] as! NSDictionary
                        let distance = legsDict["distance"] as! NSDictionary
                        let duration = legsDict["duration"] as! NSDictionary
                        let distanceText = distance["text"]! as! String
                        let durationText = duration["text"]! as! String
                        print("Du ska ta dig \(distanceText) och det kommer ta ca \(durationText)")
                        
                        for route in routes as! [[AnyHashable:Any]] {
                            
                            let routeOverviewPolyline = route["overview_polyline"] as! NSDictionary
                            let points = routeOverviewPolyline["points"] as? String
                            
                            DispatchQueue.main.sync {
                                let path = GMSPath.init(fromEncodedPath: points!)
                                let polyline = GMSPolyline.init(path: path)
                                polyline.strokeWidth = 3.0
                                polyline.map = self.mapView
                            }
                        }
                    }
                    else {
                        print("Something went wrong")
                    }
                    
                }
                else {
                    print("Error HttpStatusCode is: ", httpStatus!.statusCode)
                }
            }
            task.resume()
        }
    }
    
    @IBAction func shareLocationWasClicked(_ sender: AnyObject) {
        
        
        // create the alert
        let alert = UIAlertController(title: "Notice", message: "Share Location", preferredStyle: UIAlertControllerStyle.alert)
        
        // add the actions (buttons)
        alert.addTextField { (adressTextfield) in
            adressTextfield.placeholder = "Sverigevägen 123"
        }
        
        alert.addAction(UIAlertAction(title: "Share Location", style: UIAlertActionStyle.default, handler: { (handler) in
            let textField = alert.textFields![0]
            if textField.text == "" {
                alert.dismiss(animated: false, completion: { 
                    print("test")
                })
            }
            else {
                let fixedStringUrl = textField.text!.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
                self.getAddressFromLongLat(address: fixedStringUrl!)
            }
        }))
            
        //alert.addAction(UIAlertAction(title: "Share Location", style: UIAlertActionStyle.default, handler: nil))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        
        // show the alert
        self.present(alert, animated: true, completion: nil)
        
    }
    
    
    
    func checkIfUserHasASavedLocation() {
        
        if let userEmail = PFUser.current()?["email"] as? String {
            self.email = userEmail
        }
        
        let yourLocation = PFObject(className: "UserLocations")
        yourLocation["longitude"] = currentLocation.coordinate.longitude
        yourLocation["latitude"] = currentLocation.coordinate.latitude
        yourLocation["userEmail"] = self.email
        yourLocation["shareLocation"] = self.willYouShareYourLocation
        
        let query = PFQuery(className: "UserLocations")
        query.whereKey("userEmail", equalTo: self.email)
        
        // Get all the information with the logged in users email
        query.findObjectsInBackground { (objects, error) in
            
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            // See if user already has saved position
            else if (objects?.count)! > 0 {

                if let returnedObjects = objects {
                    
                    for object in returnedObjects {
                        // Get the users ObjectID
                        self.objectId = object.objectId!
                    }
                }
                
                //print("\n \(self.objectId) \n")
                // Use the ObjectID to update the users location to the new one
                
                let newQuery = PFQuery(className: "UserLocations")
                newQuery.getObjectInBackground(withId: self.objectId, block: { (object, error) in
                    // Updates the users longitude and latitude
                    object!["longitude"] = self.currentLocation.coordinate.longitude
                    object!["latitude"] = self.currentLocation.coordinate.latitude
                    object!["shareLocation"] = self.willYouShareYourLocation
                    object!.saveInBackground()
                })
            }
            // User has no saved position and no errors
            else {
                yourLocation.saveInBackground { (object, error) in
                    
                    if error != nil {
                        print(error!.localizedDescription)
                        return
                    }
                        
                    // Added the users position without any errors
                    else {
                        print("your location has been saved")
                    }
                }
                
            }
        }
        
    }
    
    
    
    func getOtherUsersLocation() {
        mapView.clear()
        self.drawDirections()
        self.returnedLatitude.removeAll()
        self.returnedLongitude.removeAll()
        self.sharedLocation.removeAll()
        
        if let userEmail = PFUser.current()?["email"] as? String {
            
            self.email = userEmail
            
        }
        
        
        let query = PFQuery(className: "UserLocations")
        // Get all the users with another email (can't be two users with same email anyway)
        query.whereKey("userEmail", notEqualTo: email)
        // Get's all the other users location information
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print(error?.localizedDescription as Any)
            }
            else if (objects?.count)! > 0 {
                //print(objects?.count)
                if let returnedObjects = objects {
                    
                    for object in returnedObjects {
                        // Put's all the other users information into an array
                        self.returnedLatitude.append(object["latitude"] as! NSNumber)
                        self.returnedLongitude.append(object["longitude"] as! NSNumber)
                        self.sharedLocation.append(object["shareLocation"] as! Bool)
                    }
                    //print(self.returnedLongitude[0])
                    for _ in self.i...self.returnedLongitude.count - 1 {
                        //print(self.returnedLongitude[self.i])
                     
                        //let path = GMSMutablePath()
                        let position = CLLocationCoordinate2DMake(CLLocationDegrees(self.returnedLatitude[self.i]), CLLocationDegrees(self.returnedLongitude[self.i]))
                        self.marker = GMSMarker(position: position)
                        self.marker.map = self.mapView
                        
                        
                    }
                }
            }
            else {
                //print("no other user online")
            }
            //print(self.otherLong as Any)
        }
        
    }

    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        self.newLocation = locations.last! as CLLocation
        _ = CLLocationCoordinate2D(latitude: self.newLocation.coordinate.latitude, longitude: self.newLocation.coordinate.longitude)
        
        if let userEmail = PFUser.current()?["email"] as? String {
            self.email = userEmail
        }
        
        let query = PFQuery(className: "UserLocations")
        query.whereKey("userEmail", equalTo: self.email)
        
        query.findObjectsInBackground { (objects, error) in
            if error != nil {
                print(error?.localizedDescription as Any)
                return
            }
            else if (objects?.count)! > 0 {
                
                if let returnedObjects = objects {
                    
                    for object in returnedObjects {
                    
                        self.objectId = object.objectId!
                    }
                }
                
                let newQuery = PFQuery(className: "UserLocations")
                newQuery.getObjectInBackground(withId: self.objectId, block: { (object, error) in
                    // Updates the users longitude and latitude
                    object!["longitude"] = self.newLocation.coordinate.longitude
                    object!["latitude"] = self.newLocation.coordinate.latitude
                    object!["shareLocation"] = self.willYouShareYourLocation
                    object!.saveInBackground()
                    //print("updated the position")
                })
            }
        }
        
    }
    
}

