//
//  ViewController.swift
//  Solar Cal
//
//  Created by Laxman Pandey on 09/07/18.
//  Copyright © 2018 Laxman Pandey. All rights reserved.
//

import UIKit
import MapKit
import CoreData

protocol HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark)
}

protocol BookmarkSelection {
    func tappedBookmark(_ location: LocationData)
}

class ViewController: UIViewController {

    // MARK:- IBOutlets
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var lblSunSetTime: UILabel!
    @IBOutlet weak var lblSunRiseTime: UILabel!
    @IBOutlet weak var lblMoonRiseTime: UILabel!
    @IBOutlet weak var lblMoonSetTime: UILabel!
    @IBOutlet weak var lblDisplayDate: UILabel!
    
    @IBOutlet weak var btnPreviousDate: UIButton!
    @IBOutlet weak var btnTodayDate: UIButton!
    @IBOutlet weak var btnNextDate: UIButton!
    
    @IBOutlet weak var barButtonPin: UIBarButtonItem!
    @IBOutlet weak var barButtonBookMark: UIBarButtonItem!
    
     // MARK:- Properties
    let locationManager = CLLocationManager()
    var resultSearchController:UISearchController? = nil
    var selectedPin:MKPlacemark? = nil
    var annotation = MKPointAnnotation()
    var currentTimezone = TimeZone.current
    var nextPreviousCount = 0
    var sunRiseSetTime: EDSunriseSet? = nil
    
    // MARK:- View Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTableVC
        locationSearchTable.handleMapSearchDelegate = self
        locationSearchTable.mapView = mapView
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for places"
        navigationItem.titleView = resultSearchController?.searchBar
        navigationItem.prompt = "Solar Calculator"
        
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK:- User Action Methods
    @IBAction func saveLocation(_ sender: UIBarButtonItem) {
        let entity =
            NSEntityDescription.entity(forEntityName: "LocationData",
                                       in: CoreDataStack.sharedInstance.managedContext)!
        
        let locationData = LocationData(entity: entity, insertInto: CoreDataStack.sharedInstance.managedContext)
        locationData.lat = annotation.coordinate.latitude
        locationData.long = annotation.coordinate.longitude
        locationData.timezone = currentTimezone.identifier
        locationData.title = annotation.title
        locationData.subtitle = annotation.subtitle
    
        if (CoreDataStack.sharedInstance.saveContext() ) {
        
        let alertController = UIAlertController(title: "Location saved!", message: "Location data saved successfully to deliver, Golden hour alert.", preferredStyle: .alert)
        let action = UIAlertAction(title: "Dismiss", style: .destructive, handler: nil)
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
            
        }
        else {
            let alertController = UIAlertController(title: "Something went wrong!", message: "Please try again after some time", preferredStyle: .alert)
            let action = UIAlertAction(title: "Dismiss", style: .destructive, handler: nil)
            alertController.addAction(action)
            self.present(alertController, animated: true, completion: nil)
        }
        
        LocationNotification.shared.registerNotification(at: (self.sunRiseSetTime?.sunrise)!, data: locationData, timezone: currentTimezone) { (isSuccess) in
            if(isSuccess) {
                print("Notification Registered")
            }
        }
    
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "BookmarkVC"){
            let controller = segue.destination as! UINavigationController
            let bookmarkVC = controller.viewControllers[0] as! BookmarkViewController
            bookmarkVC.bookmarkSelectionDelegate = self
        }
    }
    @IBAction func nextDate(_ sender: UIButton) {
        nextPreviousCount += 1
        let date = Date().increaseDecrease(date: Date(), toValue: nextPreviousCount)
        getSunSetAndRise(for: date)
    }
    
    @IBAction func todayDate(_ sender: UIButton) {
        nextPreviousCount = 0
        getSunSetAndRise(for: Date())
    }
    @IBAction func previousDate(_ sender: UIButton) {
        nextPreviousCount -= 1
        let date = Date().increaseDecrease(date: Date(), toValue: nextPreviousCount)
        getSunSetAndRise(for: date)
    }
    
    func getSunSetAndRise(for date: Date){
       let sunriseAndsetTime = EDSunriseSet.sunriseset(with: date, timezone: currentTimezone, latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        if let sunTime = sunriseAndsetTime {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateFormatter.timeZone = currentTimezone
            print(annotation.title! + annotation.subtitle!)
            print("Sunrise = \(dateFormatter.string(from: sunTime.sunrise))")
            print("Sunset = \(dateFormatter.string(from: sunTime.sunset))")
            
            dateFormatter.dateFormat = "hh:mm a"
            lblSunRiseTime.text = dateFormatter.string(from: sunTime.sunrise)
            lblSunSetTime.text = dateFormatter.string(from: sunTime.sunset)
            
            dateFormatter.dateStyle = .long
            lblDisplayDate.text = dateFormatter.string(from: sunTime.sunrise)
            self.sunRiseSetTime = sunTime
            
            
        }
        

    }
    
}

extension ViewController: MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKPointAnnotation {
            let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "myPin")
            
            pinAnnotationView.isDraggable = true
            pinAnnotationView.canShowCallout = true
            pinAnnotationView.animatesDrop = true
            configureAnnotation()
            
            return pinAnnotationView
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        if newState == MKAnnotationViewDragState.ending {
            configureAnnotation()
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // Remove all annotations
        self.mapView.removeAnnotations(mapView.annotations)
        
        // Add new annotation
        annotation = MKPointAnnotation()
        annotation.coordinate = mapView.centerCoordinate
        self.mapView.addAnnotation(annotation)
    }
   
    func configureAnnotation() {
        let location = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { [weak self](placeMarks, error) in
            if let placemark = placeMarks?.first{
                self?.annotation.title = placemark.subLocality
                if let city = placemark.locality,
                    let state = placemark.administrativeArea, let country = placemark.country {
                    self?.annotation.subtitle = "\(city) \(state) \(country)"
                    if let timezone = placemark.timeZone {
                        self?.currentTimezone = timezone
                        self?.getSunSetAndRise(for: Date().increaseDecrease(date: Date(), toValue: (self?.nextPreviousCount)!))
                    }
                }
            }
        }
    }
}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }

    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let location = locations.first {
            let span = MKCoordinateSpanMake(0.05, 0.05)
            let region = MKCoordinateRegion(center: location.coordinate, span: span)
            mapView.setRegion(region, animated: true)
        }
        
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
}
extension ViewController: HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark){
        
        if let timezone = placemark.timeZone {
            currentTimezone = timezone
        }
        
        selectedPin = placemark
        mapView.removeAnnotations(mapView.annotations)
        annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
            annotation.subtitle = "\(city) \(state)"
        }
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mapView.setRegion(region, animated: true)
    }
}
extension ViewController: BookmarkSelection {
    func tappedBookmark(_ location: LocationData) {
        mapView.removeAnnotations(mapView.annotations)
        annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: location.lat, longitude: location.long)
        annotation.title = location.title
        annotation.subtitle = location.subtitle
    
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(annotation.coordinate, span)
        mapView.setRegion(region, animated: true)
    }
}
extension Date {
    var morning: Date {
        return Calendar.current.date(bySettingHour: 0, minute: 1, second: 0, of: self)!
    }
    func increaseDecrease(date: Date, toValue: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: toValue, to: morning)!
    }
}





