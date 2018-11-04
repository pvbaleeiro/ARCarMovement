//
//  ViewController.swift
//  ARCarMovement
//
//  Created by Victor Baleeiro on 03/11/18.
//  Copyright © 2018 Antony Raphel. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps

class ViewController: UIViewController, GMSMapViewDelegate {
    
    var driverMarker: GMSMarker?
    var CoordinateArr: Array<Any>?
    var mapView: GMSMapView?
    var count: Int?
    var moveMent: ARCarMovement = ARCarMovement()
    var manager: CLLocationManager = CLLocationManager()
    var oldCoordinate: CLLocationCoordinate2D?
    // Test
    var timer: Timer?
    var coordinates: Array<Any> = Array()
    var counter: Int = 0
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupData()
    }
    
    // MARK: Setups
    private func setupData() {
        self.moveMent.delegate = self
        self.loadFakeData()
        //self.manager.delegate = self
        //self.manager.desiredAccuracy = kCLLocationAccuracyBest
        //self.manager.requestAlwaysAuthorization()
    }
    
    // MARK: Load real data
    private func loadRealData() {
        
        // Update location
        
    }
    
    
    // MARK: Test
    private func loadFakeData() {
        
        if let path = Bundle.main.path(forResource: "coordinates", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let jsonResult = jsonResult as? Array<Any> {
                    coordinates = jsonResult
                    self.timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(timerTriggered), userInfo: nil, repeats: true)
                }
            } catch {
                // handle error
            }
        }
    }
    
    @objc private func timerTriggered() {
        
        if self.counter < self.coordinates.count {
            
            let coord: NSDictionary = self.coordinates[counter] as! NSDictionary
            let lat: Double = Double.init(truncating: coord.value(forKey: "lat") as! NSNumber)
            let long: Double = Double.init(truncating: coord.value(forKey: "long") as! NSNumber)
            
            let newCoordinate = CLLocationCoordinate2DMake(lat, long)
            if self.mapView == nil {
                let camera = GMSCameraPosition.camera(withLatitude: lat, longitude: long, zoom: 17.0)
                self.mapView = GMSMapView.map(withFrame: .zero, camera: camera)
                self.mapView?.isMyLocationEnabled = true
                self.mapView?.delegate = self
                self.view = self.mapView
            }

            if driverMarker == nil {
                driverMarker = GMSMarker()
                driverMarker?.icon = UIImage.init(named: "car")
                driverMarker?.map = self.mapView
            }

            driverMarker?.position = newCoordinate
            self.moveMent.ARCarMovement(marker: driverMarker!, oldCoordinate: oldCoordinate ?? newCoordinate, newCoordinate: newCoordinate, mapView: self.mapView!, bearing: 0)
            self.oldCoordinate = newCoordinate
            self.counter += 1
            
        } else {
            self.timer?.invalidate()
            self.timer = nil
        }
    }
}

// MARK: ARCarMovementDelegate
extension ViewController: ARCarMovementDelegate {
    
    func ARCarMovementMoved(_ Marker: GMSMarker) {
        print("ARCarMovementMoved")
        driverMarker = Marker
        driverMarker?.map = self.mapView
        
        // animation to make car icon in center of the mapview
        let updatedCamera: GMSCameraUpdate = GMSCameraUpdate.setTarget((driverMarker?.position)!, zoom: 17.0)
        self.mapView?.animate(with: updatedCamera)
    }
}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted, .denied, .notDetermined:
            // report error, do something
            print("error")
        default:
            // location si allowed, start monitoring
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let locationObj = locations.last {
            
            print("Latitude: \(locationObj.coordinate.latitude)\n" +
                "Longitude: \(locationObj.coordinate.longitude)")
            
            let newCoordinate = CLLocationCoordinate2DMake(locationObj.coordinate.latitude, locationObj.coordinate.longitude)
            if self.mapView == nil {
                let camera = GMSCameraPosition.camera(withLatitude: locationObj.coordinate.latitude, longitude: locationObj.coordinate.longitude, zoom: 17.0)
                self.mapView = GMSMapView.map(withFrame: .zero, camera: camera)
                self.mapView?.isMyLocationEnabled = true
                self.mapView?.delegate = self
                self.view = self.mapView
            }
            
            if driverMarker == nil {
                driverMarker = GMSMarker()
                driverMarker?.icon = UIImage.init(named: "car")
                driverMarker?.map = self.mapView
            }
            
            driverMarker?.position = newCoordinate
            self.moveMent.ARCarMovement(marker: driverMarker!, oldCoordinate: oldCoordinate ?? newCoordinate, newCoordinate: newCoordinate, mapView: self.mapView!, bearing: 0)
            self.oldCoordinate = newCoordinate
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error location: \(error)")
    }
}
