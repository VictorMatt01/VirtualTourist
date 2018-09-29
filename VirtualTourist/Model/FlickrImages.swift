//
//  FlickrImages.swift
//  VirtualTourist
//
//  Created by Victor Matthijs on 10/08/2018.
//  Copyright © 2018 Victor Matthijs. All rights reserved.
//

import Foundation
class FlickrImages {
    
    func getCountPagesByLatLon(latitude:Double, longitude:Double,_ completionHandlerForCountPages: @escaping (_ result: Int, _ error: String) -> Void){
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: latLongToString(latitude: latitude, longitude: longitude),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
            ] as [String : AnyObject]
        
        // create session and request
        let session = URLSession.shared
        let request = URLRequest(url: flickrURLFromParameters(methodParameters))
        
        // create network request
        let task = session.dataTask(with: request) { (data, response, error) in
            
            guard (error == nil) else {
                completionHandlerForCountPages(0, error as! String)
                print("There was an error with your request: \(String(describing: error))")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                completionHandlerForCountPages(0, error as! String)
                print("Your request returned a status code other than 2xx!")
                return
            }
            
            guard let data = data else {
                completionHandlerForCountPages(0, error as! String)
                print("No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch {
                completionHandlerForCountPages(0, error as! String)
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                completionHandlerForCountPages(0, error as! String)
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                completionHandlerForCountPages(0, error as! String)
                print("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
            guard let totalPages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else {
                completionHandlerForCountPages(0, error as! String)
                print("Cannot find key '\(Constants.FlickrResponseKeys.Pages)' in \(photosDictionary)")
                return
            }
            
            let pageLimit = min(totalPages, 50)
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            
            completionHandlerForCountPages(randomPage, "")
            
        }
        task.resume()
    }
    
    func getPhotosByLatLon(latitude:Double, longitude:Double, pageNumber:Int ,_ completionHandlerForPhotos: @escaping (_ result: [[String: AnyObject]], _ error: String) -> Void){
        var methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: latLongToString(latitude: latitude, longitude: longitude),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
            ] as [String : AnyObject]
        methodParameters[Constants.FlickrParameterKeys.Page] = pageNumber as AnyObject?
        
        // create session and request
        let session = URLSession.shared
        let request = URLRequest(url: flickrURLFromParameters(methodParameters))
        
        // create network request
        let task = session.dataTask(with: request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                completionHandlerForPhotos([], (error?.localizedDescription)!)
                print("There was an error with your request: \(String(describing: error))")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                completionHandlerForPhotos([], (error?.localizedDescription)!)
                print("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                completionHandlerForPhotos([], (error?.localizedDescription)!)
                print("No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch {
                completionHandlerForPhotos([], (error.localizedDescription))
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                completionHandlerForPhotos([], (error?.localizedDescription)!)
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                completionHandlerForPhotos([], (error?.localizedDescription)!)
                print("Cannot find key '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photo" key in photosDictionary? */
            guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                completionHandlerForPhotos([], (error?.localizedDescription)!)
                print("Cannot find key '\(Constants.FlickrResponseKeys.Photo)' in \(photosDictionary)")
                return
            }
            
            let countPages = photosArray.count
            //pick 15 random numbers out of the countPages
            var index = 0
            var arrayWithPhotoIndex:[Int] = []
            while index < 15 {
                var randomPage = Int(arc4random_uniform(UInt32(countPages))) + 1
                while arrayWithPhotoIndex.contains(randomPage) {
                    randomPage = Int(arc4random_uniform(UInt32(countPages))) + 1
                }
                arrayWithPhotoIndex.append(randomPage)
                index += 1
            }
            var resultPhotos:[[String: AnyObject]] = []
            for index in arrayWithPhotoIndex {
                resultPhotos.append(photosArray[index - 1])
            }
            completionHandlerForPhotos(resultPhotos, "")
        }
        
        task.resume()
    }
    
    func latLongToString(latitude:Double, longitude:Double) -> String{
        let minimumLon = longitude - Constants.Flickr.SearchBBoxHalfWidth
        let maximumLon = longitude + Constants.Flickr.SearchBBoxHalfWidth
        let minimumLat = latitude - Constants.Flickr.SearchBBoxHalfHeight
        let maximumLat = latitude + Constants.Flickr.SearchBBoxHalfHeight
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    private func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    
    
}

