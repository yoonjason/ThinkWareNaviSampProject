//
//  ViewController.swift
//  iNaviSystemsProject
//
//  Created by yoon on 2020/01/29.
//  Copyright © 2020 yoon. All rights reserved.
//

import UIKit
import GooglePlaces
import GoogleMaps
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate, GMSAutocompleteResultsViewControllerDelegate {
    
    @IBOutlet weak var mainMapView: GMSMapView!
    @IBAction func searchingRoute(_ sender: Any) {
        showAlertOkNo(title: "길을 찾으시겠습니까?", message: "한국어로는 자동차 안내는 불가합니다.")
    }
    @IBOutlet weak var searchingButton: UIButton!
    
    
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    var resultView: UITextView?
    var marker = GMSMarker()
    
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var placesClient: GMSPlacesClient!
    var zoomLevel: Float = 16.3
    var likelyPlaces: [GMSPlace] = []
    var selectedPlace: GMSPlace?
    var location_name : String = ""
    var current_latitude:CLLocationDegrees = 0.0
    var current_longitude:CLLocationDegrees = 0.0
    var result_latitude:CLLocationDegrees = 0.0
    var result_longitude:CLLocationDegrees = 0.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSearchBar()
        initView()
    }
    
    func initView() {
        print("#@#@#@ initview")
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        placesClient = GMSPlacesClient.shared()
        searchingButton.isHidden = true
    }
    func initSearchBar() {
        resultsViewController = GMSAutocompleteResultsViewController()
        resultsViewController?.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController?.searchResultsUpdater = resultsViewController
        
        let subView = UIView(frame: CGRect(x: 0, y: 65.0, width: 350.0, height: 45.0))
        
        subView.addSubview((searchController?.searchBar)!)
        view.addSubview(subView)
        
        searchController?.searchBar.sizeToFit()
        navigationItem.titleView = searchController?.searchBar
        
        definesPresentationContext = true
        searchController?.hidesNavigationBarDuringPresentation = false
        searchController?.modalPresentationStyle = .popover
    }
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didAutocompleteWith place: GMSPlace) {
        searchController?.isActive = false
        let camera = GMSCameraPosition.camera(withLatitude: place.coordinate.latitude, longitude: place.coordinate.longitude, zoom: 16.3)
        mainMapView.camera = camera
        mainMapView.animate(to: camera)
        
        searchingButton.isHidden = false

        result_latitude = place.coordinate.latitude
        result_longitude = place.coordinate.longitude
        
        marker.position = CLLocationCoordinate2D(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        if !(place.name ?? "").isEmpty {
            marker.title = place.name
        }else {
            marker.title =  "현재 위치"
        }
        if !(place.name ?? "").isEmpty {
            marker.snippet = place.formattedAddress
        }
        marker.map = mainMapView
        print(place.name)
        
    }

    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didFailAutocompleteWithError error: Error){
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("map update")
        let location: CLLocation = locations.last!
        print("Location: \(location)")
        #if arch(i386) || arch(x86_64)
        print("simulator")
        original_latitude = 37.402259
        original_longitude = 127.1091899
        //simulator
        #else
        current_latitude = location.coordinate.latitude
        current_longitude = location.coordinate.longitude
        //device
        #endif
        
        
        let camera = GMSCameraPosition.camera(withLatitude: current_latitude,
                                              longitude: current_longitude,
                                              zoom: zoomLevel)
        
        if mainMapView.isHidden {
            mainMapView.isHidden = false
            mainMapView.camera = camera
        } else {
            mainMapView.animate(to: camera)
        }
        mainMapView.padding = UIEdgeInsets(top: 0, left: 0, bottom: 50, right:20)
        mainMapView.settings.compassButton = true
        mainMapView.settings.myLocationButton = true
        
        marker.position = CLLocationCoordinate2D(latitude: current_latitude, longitude: current_longitude)
        marker.map = mainMapView
        
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            // Display the map using the default location.
            mainMapView.isHidden = false
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        @unknown default:
           print("")
        }
    }
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
    
    func showAlertOkNo(title : String, message : String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler : {
            (action) in
            self.searchRouteAndPoly()
        })
        let cancel = UIAlertAction(title: "cancel", style: .cancel, handler : nil)
        alert.addAction(okAction)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    func searchRouteAndPoly(){
        
        let path = GMSMutablePath()
        path.add(CLLocationCoordinate2D(latitude: current_latitude, longitude: current_longitude))
        path.add(CLLocationCoordinate2D(latitude: result_latitude, longitude: result_longitude))
        let polyLine = GMSPolyline(path: path)
        polyLine.strokeWidth = 10.0
        polyLine.geodesic = true
        polyLine.strokeColor = .red

        let rectangle = GMSPolyline(path: path)
        rectangle.map = mainMapView
        let circleCenter = CLLocationCoordinate2D(latitude: result_latitude, longitude: result_longitude)
        let circ = GMSCircle(position: circleCenter, radius: 1000)
        circ.map = mainMapView
        
        let camera = GMSCameraPosition.camera(withLatitude: result_latitude, longitude: result_longitude, zoom: 12)
        mainMapView.camera = camera
        mainMapView.animate(to: camera)
    }
    
}

