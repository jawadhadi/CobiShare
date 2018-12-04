//
//  ViewController.swift
//  CobiShare
//
//  Created by Hadi on 20/11/2018.
//  Copyright © 2018 Hadi. All rights reserved.
//

import UIKit
import GoogleMaps
import MBProgressHUD

private let bikeDetailSegue = "bikeDetailSegue"
//private let addBikeSegue = "addBikeSegue"
//private let distanceRadius = 500

class MapViewController: UIViewController, GMSMapViewDelegate {

    @IBOutlet weak var addBikeBarButtonItem: UIBarButtonItem!
    
    //to store bikes against their ids
    lazy var bikesDictionary = [Int: Bike]()
    
    lazy var mapView = GMSMapView()
    
    //the bike that was selected by user so that it could be sent to detail VC
    var selectedBike: Bike?
    
    var locationManager = CLLocationManager()
    
    //to keep track of current location
    var currentLocation: CLLocation?
    
    //a button to end ride that will appear after user rents a bike
    lazy var returnBikeButton = UIButton(frame: CGRect(x: 0, y: 0, width: 145, height: 45))
    
    //to keep a reference of rented bike
    var rentedBike: Bike?
    
    //time to poll bikes data from server
    var locationUpdateTimer : Timer?
    
    private let cobiBikeAPI = CobiBikeAPI()
    
    //for showing activity indicator
    var progressHUD: MBProgressHUD?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        cobiBikeAPI.delegate = self
        
        self.title = "Tap on a bike to rent"
        
        enableLocationServices()
        
        mapView.delegate = self
        view = mapView
        
    }
    
    var didAlreadyDisplayError = false
    
    func getNearByBikes(){
        
        guard let currentLocation = self.currentLocation else{
            
            print("currentLocation is nil")
            return
        }
    
        let distanceRadius = 500
        cobiBikeAPI.getNearbyBikes(forLocation: currentLocation, withRadius: distanceRadius)
        
    }
    
    func mapBikes(){
        
        mapView.clear()
        
        var bikeAvailabilityCount = 0
        
        for bike in bikesDictionary.values{
            
            if bike.rented == false{
                
                self.title = "Tap on a bike to rent"
                
                bikeAvailabilityCount += 1
                let location = CLLocation(latitude: bike.location.latitude, longitude: bike.location.longitude)
                let marker = GMSMarker(position: (location.coordinate))
                marker.title = bike.id!.description
                marker.icon = UIImage(named: "bike_icon")
                marker.map = mapView

            }

        }
        
        if bikeAvailabilityCount == 0{
            
            self.title = "No bike available"
            
            let alert = UIAlertController(title: "Alert", message: "Sorry all bikes near you have been rented.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        }
        
    }

    func updateUserLocation(location: CLLocation){
        
        let camera = GMSCameraPosition.camera(withLatitude: (location.coordinate.latitude), longitude: (location.coordinate.longitude), zoom: 17.0)
        self.mapView.camera = camera
        self.mapView.isMyLocationEnabled = true
        self.mapView.settings.myLocationButton = true
        
    }
    
    func userDidRentBike(with bikeId: Int) {
        
        if let bike = bikesDictionary[bikeId]{
            
            rentedBike = bike
            if locationUpdateTimer?.isValid == true{
                
                locationUpdateTimer?.invalidate()
                
            }
            
            DispatchQueue.main.async {
                
                self.title = "Enjoy your ride"
                
                self.addBikeBarButtonItem.isEnabled = false
                
                self.mapView.clear()
                
                let location = CLLocation(latitude: bike.location.latitude, longitude: bike.location.longitude)
                let marker = GMSMarker(position: (location.coordinate))
                marker.title = bike.id!.description
                marker.icon = UIImage(named: "rentedBike_icon")
                marker.map = self.mapView
                
                self.returnBikeButton.backgroundColor = UIColor.red
                self.returnBikeButton.setTitle("Return Bike", for: .normal)
                self.returnBikeButton.layer.cornerRadius = 20
                self.returnBikeButton.addTarget(self, action: #selector(self.didTapReturnBikeButton), for: .touchUpInside)
                self.view.addSubview(self.returnBikeButton)
                
                self.returnBikeButton.translatesAutoresizingMaskIntoConstraints = false
                self.returnBikeButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
                self.returnBikeButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -40).isActive = true
                self.returnBikeButton.widthAnchor.constraint(equalToConstant: 140).isActive = true
                self.returnBikeButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
                
            }
        }
    }
    
    
    @objc func didTapReturnBikeButton(){
        
        guard let rentedBike = self.rentedBike else {
            print("Rented bike was nil")
            showErrorAlert(withMessage: "Unable to process bike data. Contact Support")
            return
        }
        
        guard let bikeId = rentedBike.id else {
            print("Rented bike.id was nil")
            return
        }
        
        progressHUD = MBProgressHUD.showAdded(to: self.view, animated: true)
        
        let bikeLocation = Location(latitude: Double(currentLocation!.coordinate.latitude), longitude: Double(currentLocation!.coordinate.longitude))
        
        var newBike = Bike(name: rentedBike.name, color: rentedBike.color, pin: rentedBike.pin, location: bikeLocation)
        
        newBike.id = bikeId
        
        cobiBikeAPI.returnBike(newBike)
        
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        
        if let bikeId = Int(marker.title!){
            
            let bike = bikesDictionary[bikeId]
            
            selectedBike = bike
            performSegue(withIdentifier: bikeDetailSegue, sender: nil)
            
        }
        
        return true
        
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == bikeDetailSegue{
            
            if let bikeDetailViewController = segue.destination as? BikeDetailViewController{
                
                bikeDetailViewController.bike = selectedBike
                bikeDetailViewController.delegate = self
                bikeDetailViewController.view.backgroundColor = UIColor.init(white: 0.6, alpha: 0.5)
                bikeDetailViewController.modalPresentationStyle = .overCurrentContext
                
            }
            
        }else if segue.identifier == "addBikeSegue"{
            
            if let addBikeViewController = segue.destination as? AddBikeViewController{
                
                addBikeViewController.delegate = self
                addBikeViewController.currentLocation = currentLocation
                
            }
            
        }
    }
    
}

extension MapViewController: CLLocationManagerDelegate{
    
    func enableLocationServices() {
        
        locationManager.delegate = self
        
        switch CLLocationManager.authorizationStatus() {
            
        case .notDetermined:
            // Request when-in-use authorization
            locationManager.requestWhenInUseAuthorization()
            
            break
            
        case .restricted, .denied:
            // display location error
            showLocationErrorViewController()
            
            break
            
        case .authorizedWhenInUse, .authorizedAlways:
            
            break
        }
    }
    
    //selector for timer to start location updates after a certain time
    @objc func startUpdatingLocation(){
        
        locationManager.startUpdatingLocation()
        
    }
    
    func setLocationUpdateTimer(){
        //sort of polling mechanism to get the latest nearby bikes.
        locationUpdateTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(startUpdatingLocation), userInfo: nil, repeats: true)
        
    }
    
    //MARK: Location Manager Delegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        locationManager.stopUpdatingLocation()
        if let location = locations.last{
            
            currentLocation = location
            updateUserLocation(location: location)
            getNearByBikes()
            
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
            
        case .restricted, .denied:
            
            if locationUpdateTimer?.isValid == true{
                
                locationManager.stopUpdatingLocation()
                locationUpdateTimer?.invalidate()
                
            }
            
            if self.viewIfLoaded?.window != nil && self.presentedViewController == nil{
                
                // viewController is visible & modal is not present
                showLocationErrorViewController()
                
            }else{
            
                //will notify to show error if there's any other view/viewcontroller at top
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "locationServicesDisabled"), object: nil, userInfo: nil)
                
            }
            
            break
            
        case .authorizedWhenInUse:
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "hideLocationErrorController"), object: nil, userInfo: nil)
            
            setLocationUpdateTimer()
            
            locationManager.startUpdatingLocation()
            
            break
            
        case .notDetermined, .authorizedAlways:
            
            break
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        locationManager.stopUpdatingLocation()
        print("Location manager failed with error: " + error.localizedDescription)
        
    }
    
    func showLocationErrorViewController(){
        
        let locationErrorController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LocationErrorVC")
        locationErrorController.view.backgroundColor = UIColor.init(white: 0.6, alpha: 0.5)
        locationErrorController.modalPresentationStyle = .overCurrentContext
        self.present(locationErrorController, animated: true, completion: nil)
        
    }
    
}

extension MapViewController: CobiBikeAPIDelegate{
    
    func didReturnBike(response: HTTPURLResponse?, error: NSError?) {
        
        if let hud = progressHUD{
            
            DispatchQueue.main.async {
                hud.hide(animated: true)
            }
            
        }
        
        if let error = error{
            
            self.handleURLErrors(withCode: error.code)
            
            return
            
        }
        
        guard let response = response else{
            
            print("Alert: Response was nil")
            return
            
        }
        
        if response.statusCode == 200{
            
            self.rentedBike = nil
            
            if self.locationUpdateTimer?.isValid == false{
                
                self.setLocationUpdateTimer()
                
            }
            
            DispatchQueue.main.async {
                self.title = "Tap on a bike to rent"
                self.addBikeBarButtonItem.isEnabled = true
                self.returnBikeButton.removeFromSuperview()
                self.mapView.clear()
                self.locationManager.startUpdatingLocation()
            }
            
        }else if response.statusCode == 400{
            
            print("Server Response: This bike is not rented right now")
            
        }else if response.statusCode == 404{
            
            print("Server Response: Bike not found")
            
        }
        
    }
    
    func didGetNearbyBikes(_ data: Data?, response: HTTPURLResponse?, error: NSError?) {
        
        if let error = error{
            
            //check if shown once don't display again
            if self.didAlreadyDisplayError == false{
                
                self.didAlreadyDisplayError = true
                
                DispatchQueue.main.async {
                    
                    self.mapView.clear()
                    //handleURLErrors will display alerts
                    self.handleURLErrors(withCode: error.code)
                }
            }
            
            return
            
        }
        
        guard let response = response else{
            
            print("Response was also nil.")
            return
            
        }
        
        if response.statusCode == 200{
            
            guard let data = data else{
                
                print("Bikes data was nil")
                
                return
                
            }
            
            BikeParser.parseBike(data, onSuccess: { (bikes) in
                
                guard let bikes = bikes else{
                    
                    print("Bikes from parser was nil")
                    return
                }
                
                for bike in bikes{
                    
                    self.bikesDictionary[bike.id!] = bike
                    
                }
                
                DispatchQueue.main.async {
                    self.mapBikes()
                }
                
            }) { (error) in
                print(error!.domain)
            }
            
            self.didAlreadyDisplayError = false
            
        }else if response.statusCode == 404{
            
            //check if shown once don't display again
            
            if self.locationUpdateTimer?.isValid == true{
                
                self.locationUpdateTimer?.invalidate()
                
            }
            
            self.title = "No bike found"
            
            let alert = UIAlertController(title: "Alert", message: "Sorry there are no bikes available near you.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
}


extension MapViewController{
    
    private func showErrorAlert(withMessage message: String){
        
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    private func handleURLErrors(withCode code: Int){
        
        switch code{
            
        case NSURLErrorTimedOut:
            
            self.showErrorAlert(withMessage: "Request timed out. Make sure you are connected to Internet.")
            
        case NSURLErrorCannotConnectToHost:
            
            self.showErrorAlert(withMessage: "Could not connect to COBI.Network. Make sure you're connected to Internet. Otherwise contact support.")
            
        default:
            
            self.showErrorAlert(withMessage: "An error occurred. Contact support.")
            
        }
        
    }
    
}
