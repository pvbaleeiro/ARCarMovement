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
import SwiftSocket

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
    let client = TCPClient(address: "35.247.226.179", port: 80)
    //let client = TCPClient(address: "192.168.1.147", port: 2222)
    var isConnected = false
    let hexaOriginalMessage = "40405900043231335458323031353030303832310000000000400100DA196C5C811D6C5C8E6802000000000000000000000000100400000000111A00000001<><><>&&&&&&D8FA0C050E472E0A02000000CC010000B7D50D0A40405900043231335458323031353030303832310000000000400100DA196C5CF61D6C5C8E6802000000000000000000000000100400000000111B0000000113021312110596FA0C055C472E0A00000000BC010000470A0D0A40405900043231335458323031353030303832310000000000400100DA196C5CF81D6C5C8E6802000000000000000000000000100400000000111B0000000113021312110790FA0C055C472E0A00000000BC0100001C8C0D0A00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupData()
    }
    
    // MARK: Setups
    private func setupData() {
        self.moveMent.delegate = self
        //self.loadFakeData()
        self.manager.delegate = self
        self.manager.desiredAccuracy = kCLLocationAccuracyBest
        self.manager.requestAlwaysAuthorization()
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
            
            // Send location
            self.sendLocation(latitude: locationObj.coordinate.latitude, longitude: locationObj.coordinate.longitude)
            
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
    
    func sendLocation(latitude: Double, longitude: Double) {
        print("Irá tentar enviar a localização...")
        
        // Localização
        var hexaFinalMessage = hexaOriginalMessage
        let hexaLatitude = to2Rev(String(Int(latitude*3600000) * -1, radix: 16)).uppercased()
        let hexaLongitude = to2Rev(String(Int(longitude*3600000) * -1, radix: 16)).uppercased()

        let rangeLatitude = hexaOriginalMessage.range(of: "D8FA0C05")
        hexaFinalMessage.replaceSubrange(rangeLatitude!, with: hexaLatitude)
        let rangeLongitude = hexaOriginalMessage.range(of: "0E472E0A")
        hexaFinalMessage.replaceSubrange(rangeLongitude!, with: hexaLongitude)
        
        //Data
        let now = Date()
        let timeZone = TimeZone(identifier: "UTC")
        var calendar = NSCalendar.current
        calendar.timeZone = timeZone!
        
        let year = Int(String(Calendar.current.component(.year, from: now))[2..<4])
        let month = Int(String(String(format: "%02d", calendar.component(.month, from: now))))
        let day = Int(String(String(format: "%02d", calendar.component(.day, from: now))))
        let yearHexa = String(String(year!, radix: 16)).uppercased()
        let monthHexa = String(String(month!, radix: 16)).uppercased()
        let dayHexa = String(String(day!, radix: 16)).uppercased()
        
        let rangeDate = hexaOriginalMessage.range(of: "<><><>")
        hexaFinalMessage.replaceSubrange(rangeDate!, with: ((dayHexa.count == 1) ? "0" + dayHexa : dayHexa) + ((monthHexa.count == 1) ? "0" + monthHexa : monthHexa) + ((yearHexa.count == 1) ? "0" + yearHexa : yearHexa))
        
        let hour = Int(String(String(format: "%02d", calendar.component(.hour, from: now))))
        let min = Int(String(String(format: "%02d", calendar.component(.minute, from: now))))
        let sec = Int(String(String(format: "%02d", calendar.component(.second, from: now))))
        let hourHexa = String(String(hour!, radix: 16)).uppercased()
        let minHexa = String(String(min!, radix: 16)).uppercased()
        let secHexa = String(String(sec!, radix: 16)).uppercased()
        
        let rangeTime = hexaOriginalMessage.range(of: "&&&&&&")
        hexaFinalMessage.replaceSubrange(rangeTime!, with: ((hourHexa.count == 1) ? "0" + hourHexa : hourHexa) + ((minHexa.count == 1) ? "0" + minHexa : minHexa) + ((secHexa.count == 1) ? "0" + secHexa : secHexa))
        
        // Aqui nós vamos trocar apenas a latitude e longitude
        self.prepareMessage(hexaFinalMessage)
    }
    
    func prepareMessage(_ message: String) {
        print("Enviando a localização...")
        
        let data: Data = message.hexadecimal()!
        switch self.client.connect(timeout: 1) {
        case .success:
            self.isConnected = true;
            self.sendMessage(data)
            
        case .failure(let error):
            print("Connection error: \(error)")
        }
    }
    
    func sendMessage(_ messageData: Data) {
        switch self.client.send(data: messageData) {
        case .success:
            print("success")
        case .failure(let error):
            print("Sending error: \(error)")
        }
    }
    
    func to2Rev(_ value: String) -> String {
        var newValue = value
        if (newValue.count % 2 != 0) {
            newValue = "0" + newValue
        }
        
        return newValue[6..<8] + newValue[4..<6] + newValue[2..<4] + newValue[0..<2]
    }
}

extension String {
    
    /// Create `Data` from hexadecimal string representation
    ///
    /// This takes a hexadecimal representation and creates a `Data` object. Note, if the string has any spaces or non-hex characters (e.g. starts with '<' and with a '>'), those are ignored and only hex characters are processed.
    ///
    /// - returns: Data represented by this hexadecimal string.
    
    func hexadecimal() -> Data? {
        var data = Data(capacity: characters.count / 2)
        
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, options: [], range: NSMakeRange(0, characters.count)) { match, flags, stop in
            let byteString = (self as NSString).substring(with: match!.range)
            var num = UInt8(byteString, radix: 16)!
            data.append(&num, count: 1)
        }
        
        guard data.count > 0 else {
            return nil
        }
        
        return data
    }
}

extension String {
    
    /// Create `String` representation of `Data` created from hexadecimal string representation
    ///
    /// This takes a hexadecimal representation and creates a String object from that. Note, if the string has any spaces, those are removed. Also if the string started with a `<` or ended with a `>`, those are removed, too.
    
    init?(hexadecimal string: String) {
        guard let data = string.hexadecimal() else {
            return nil
        }
        
        self.init(data: data, encoding: .utf8)
    }
    
    /// - parameter encoding: The `NSStringCoding` that indicates how the string should be converted to `NSData` before performing the hexadecimal conversion.
    
    /// - returns: `String` representation of this String object.
    
    func hexadecimalString() -> String? {
        return data(using: .utf8)?
            .hexadecimal()
    }
    
}

extension Data {
    
    /// Create hexadecimal string representation of `Data` object.
    
    /// - returns: `String` representation of this `Data` object.
    
    func hexadecimal() -> String {
        return map { String(format: "%02x", $0) }
            .joined(separator: "")
    }
}

extension String {
    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }
    
    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
}
