//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Victor Matthijs on 07/08/2018.
//  Copyright © 2018 Victor Matthijs. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationMapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate{

    @IBOutlet weak var deleteLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    var dataController:DataController!
    var userPins: [Pin] = []
    var editState:Bool = false
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        deleteLabel.isHidden = true
        mapView.delegate = self
        let action = #selector(TravelLocationMapViewController.addAnnotation(sender:))
        let uilgr = UILongPressGestureRecognizer(target: self, action: action)
        mapView.addGestureRecognizer(uilgr)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //get the previous center of the map
        if defaults.dictionary(forKey: "coor") != nil {
            let previous = defaults.dictionary(forKey: "coor")!
            let coordinate = CLLocationCoordinate2D(latitude: previous["lat"] as! CLLocationDegrees, longitude: previous["long"] as! CLLocationDegrees)
            let mapSpan = MKCoordinateSpan(latitudeDelta: previous["latDelta"] as! CLLocationDegrees, longitudeDelta: previous["longDelta"] as! CLLocationDegrees)
            var mapRegion = MKCoordinateRegion(center: coordinate, span: mapSpan)
            mapView.setRegion(mapRegion, animated: true)
        }
        
        
        //load the pins from the data
        loadPins()
        //draw the pins on the map
        drawPins()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        let latitudeDelta = mapView.region.span.latitudeDelta
        let longitudeDelta = mapView.region.span.longitudeDelta
        //make dictionary for coor
        let coorDic = ["lat" : latitude, "long" : longitude, "latDelta" : latitudeDelta, "longDelta" : longitudeDelta]
        defaults.set(coorDic, forKey: "coor")
    }
    
    func loadPins(){
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        do {
            userPins = try dataController.viewContext.fetch(fetchRequest)
        } catch {
            print("Fetching Failed")
        }
    }
    
    func drawPins(){
        for pin in userPins {
            let newCoor = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
            let newAnno = OwnAnnotion(coor: newCoor, pin: pin)
            newAnno.setBeenVisited(value: pin.beenVisited)
            mapView.addAnnotation(newAnno)
        }
    }
    @IBAction func editButtonTapped(_ sender: Any) {
        if editState {
            deleteLabel.isHidden = true
            editState = false
        }else{
            deleteLabel.isHidden = false
            editState = true
        }
    }
    
    @objc func addAnnotation(sender: UILongPressGestureRecognizer){
        if sender.state == UIGestureRecognizerState.ended {
            let touchPoint = sender.location(in: mapView)
            let newCoordinates = mapView.convert(touchPoint,toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            //save the annotation to the data as a Pin
            let newPin = Pin(context: dataController.viewContext)
            newPin.latitude = newCoordinates.latitude
            newPin.longitude = newCoordinates.longitude
            newPin.beenVisited = false
            try? dataController.viewContext.save()
            userPins.append(newPin)
            let anno = OwnAnnotion(coor: newCoordinates, pin: newPin)
            anno.setBeenVisited(value: false)
            mapView.addAnnotation(anno)
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if editState {
            let pinToDelete = (view.annotation as! OwnAnnotion).pin
            dataController.viewContext.delete(pinToDelete)
            mapView.removeAnnotation(view.annotation as! OwnAnnotion)
            try? dataController.viewContext.save()
        } else {
            let photoAlbumVC:PhotoAlbumViewController = self.storyboard?.instantiateViewController(withIdentifier: "photoAlbum") as! PhotoAlbumViewController
            photoAlbumVC.detailPinAnnotation = view.annotation as! OwnAnnotion
            photoAlbumVC.detailPin = (view.annotation as! OwnAnnotion).pin
            photoAlbumVC.dataController = dataController
            self.present(photoAlbumVC, animated: true, completion: nil)
        }
    }
    
}
