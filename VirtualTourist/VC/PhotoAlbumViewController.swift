//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Victor Matthijs on 07/08/2018.
//  Copyright © 2018 Victor Matthijs. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var detailMapView: MKMapView!
    @IBOutlet weak var photoAlbumCollection: UICollectionView!
    @IBOutlet weak var deletePhotots: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var detailPinAnnotation:OwnAnnotion!
    var detailPin:Pin!
    let regionRadius: CLLocationDistance = 4000
    var dataController:DataController!
    var photoStream:[Data] = []
    var photoStreamToDelete:[Int] = []
    let flickrImages = FlickrImages.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        deletePhotots.isHidden = true
        detailMapView.delegate = self
        let detailLocation = CLLocation(latitude: detailPinAnnotation.coordinate.latitude, longitude: detailPinAnnotation.coordinate.longitude)
        newCollectionButton.isEnabled = false
        centerMapOnLocation(location: detailLocation)
        activityIndicator.hidesWhenStopped = true
        
        if detailPin.beenVisited {
            //if beenvisited is true then load photo's from core data
            loadPicturesFromCoreData()
        }else{
            //else load new pictures from flickr
            activityIndicator.startAnimating()
            loadPictures(latitude: detailPin.latitude, longitude: detailPin.longitude)
        }
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius, regionRadius)
        detailMapView.setRegion(coordinateRegion, animated: true)
        let anno = detailPinAnnotation
        detailMapView.addAnnotation(anno!)
    }
    
    func loadPicturesFromCoreData(){
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "fromPin == %@", detailPinAnnotation.pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "photoData", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        do {
            let photostream = try dataController.viewContext.fetch(fetchRequest)
            for photo in photostream {
                photoStream.append(photo.photoData!)
            }
            photoAlbumCollection.reloadData()
        } catch {
            print("Fetching Failed")
        }
    }
    
    func loadPictures(latitude:Double, longitude:Double){
        flickrImages.getCountPagesByLatLon(latitude: latitude, longitude: longitude) { (result, error) in
            if result != 0 {
                self.flickrImages.getPhotosByLatLon(latitude: latitude, longitude: longitude, pageNumber: result) { (result, error) in
                    if error == ""{
                        for photo in result {
                            let imageURL = URL(string: photo["url_m"] as! String)
                            if let imageData = try? Data(contentsOf: imageURL!) {
                                self.photoStream.append(imageData)
                            } else {
                                print("Image does not exist at \(String(describing: photo["url_m"]))")
                            }
                        }
                        DispatchQueue.main.async {
                            self.photoAlbumCollection.reloadData()
                            self.newCollectionButton.isEnabled = true
                            self.activityIndicator.stopAnimating()
                            
                        }
                    } else{
                        DispatchQueue.main.async {
                            self.showAlertMessage(messageType: "Error", messageText: error)
                        }
                    }
                }
            }else {
                DispatchQueue.main.async {
                    self.showAlertMessage(messageType: "Error", messageText: error)
                }
            }
        }
    }
    
    // MARK: - CollectionView
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoStream.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = photoAlbumCollection.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCollectionViewCell
        cell.photoView.image = UIImage(data: photoStream[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        newCollectionButton.isHidden = true
        deletePhotots.isHidden = false
        let selectedCell = collectionView.cellForItem(at: indexPath) as! PhotoCollectionViewCell
        
        if selectedCell.isCellSelected {
            selectedCell.isCellSelected = false
            selectedCell.photoView.image = UIImage(data: photoStream[indexPath.item])
            photoStreamToDelete = photoStreamToDelete.filter { $0 != indexPath.row }
        } else {
            selectedCell.isCellSelected = true
            selectedCell.photoView.image = selectedCell.photoView.image?.tint(with: UIColor.gray)
            photoStreamToDelete.append(indexPath.row)
        }
    }
    
    // MARK: - Functions
    
    @IBAction func confirmTapped(_ sender: Any) {
        //if not been visited then save all photos in core data
        if !detailPin.beenVisited {
            for photoData in photoStream {
                let image = UIImage(data: photoData)
                let finalImageData = UIImageJPEGRepresentation(image!, 1)
                let photo = Photo(context: dataController.viewContext)
                photo.photoData = finalImageData
                photo.fromPin = detailPinAnnotation.pin
            }
            try? dataController.viewContext.save()
            detailPin.beenVisited = true
        }
        //dismiss view
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func newCollectionTapped(_ sender: Any) {
        newCollectionButton.isEnabled = false
        photoStream = []
        loadPictures(latitude: detailPinAnnotation.coordinate.latitude, longitude: detailPinAnnotation.coordinate.longitude)
    }
    
    @IBAction func deletePhotosTapped(_ sender: UIButton) {
        photoStream.remove(at: photoStreamToDelete)
        photoAlbumCollection.reloadData()
        photoStreamToDelete = []
    }
    
    // MARK: - showAlert Function
    
    func showAlertMessage(messageType:String, messageText:String){
        let alert = UIAlertController(title: messageType, message: messageText, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            switch action.style{
            case .default:
                print("default")
                
            case .cancel:
                print("cancel")
                
            case .destructive:
                print("destructive")
            }}))
        self.present(alert, animated: true, completion: nil)
    }
}

extension UIImage {
    
    func tint(with color: UIColor) -> UIImage
    {
        UIGraphicsBeginImageContext(self.size)
        guard let context = UIGraphicsGetCurrentContext() else { return self }
        
        // flip the image
        context.scaleBy(x: 1.0, y: -1.0)
        context.translateBy(x: 0.0, y: -self.size.height)
        
        // multiply blend mode
        context.setBlendMode(.multiply)
        
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        context.clip(to: rect, mask: self.cgImage!)
        color.setFill()
        context.fill(rect)
        
        // create UIImage
        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else { return self }
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
}

extension Array {
    mutating func remove(at indexes: [Int]) {
        var lastIndex: Int? = nil
        for index in indexes.sorted(by: >) {
            guard lastIndex != index else {
                continue
            }
            remove(at: index)
            lastIndex = index
        }
    }
}

