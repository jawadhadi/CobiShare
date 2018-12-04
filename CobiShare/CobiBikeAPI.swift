//
//  BikeData.swift
//  CobiShare
//
//  Created by Hadi on 03/12/2018.
//  Copyright © 2018 Hadi. All rights reserved.
//

import Foundation
import CoreLocation

@objc protocol CobiBikeAPIDelegate{
    
    @objc optional func didGetNearbyBikes(_ data: Data?, response: HTTPURLResponse?, error: NSError?)
    @objc optional func didAddBike(response: HTTPURLResponse?, error: NSError?)
    @objc optional func didRentBike(response: HTTPURLResponse?, error: NSError?)
    @objc optional func didReturnBike(response: HTTPURLResponse?, error: NSError?)
    
}

class CobiBikeAPI{
    
    let baseURL = "http://localhost:3000/"
    weak var delegate: CobiBikeAPIDelegate?
    
    func getNearbyBikes(forLocation location: CLLocation, withRadius radius: Int){
        
        let latitude = location.coordinate.latitude.description
        let longitude = location.coordinate.longitude.description
        
        let urlString = baseURL + "bikes?latitude=\(latitude)&longitude=\(longitude)&radius=\(radius)"
        
        guard let url = URL(string: urlString) else{
            
            print("urlString conversion to type URL failed")
            return
            
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            guard self.delegate != nil else{
                
                print("woah! delegate was nil")
                
                return
            }
            
            if let error = error as NSError?{
                
                self.delegate?.didGetNearbyBikes!(nil, response: nil, error: error)
                
                return
                
            }
            
            if let response = response as? HTTPURLResponse{
                
                if response.statusCode == 200{
                    
                    guard let data = data else{
                        
                        print("Bikes data was nil")
                        
                        return
                        
                    }
                    
                    self.delegate?.didGetNearbyBikes!(data, response: response, error: nil)
                    
                    
                }else if response.statusCode == 404{
                    
                    
                    self.delegate?.didGetNearbyBikes!(nil, response: response, error: nil)
                    
                    
                }
                
            }
            
        }
        
        task.resume()
        
    }
    
    func addBike(_ bike: Bike){
        
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(bike) else{
            
            print("Suprisingly JSON encoding failed")
            
            return
        }
        
        let urlString = baseURL + "bikes"
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            guard self.delegate != nil else{
                
                print("woah! delegate was nil")
                
                return
            }
            
            if let error = error as NSError?{
                
                self.delegate?.didAddBike!(response: nil, error: error)
                return
                
            }
            
            if let response = response as? HTTPURLResponse{

                self.delegate?.didAddBike!(response: response, error: nil)
                
            }
        }
        
        task.resume()
        
    }
    
    func rentBike(withId id: Int){
        
        let url = URL(string: "http://localhost:3000/bikes/\(id)/rented")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            guard self.delegate != nil else{
                
                print("woah! delegate was nil")
                
                return
            }
            
            if let error = error as NSError?{
                
                self.delegate?.didRentBike!(response: nil, error: error)
                
                return
                
            }
            
            
            if let response = response as? HTTPURLResponse{
                
               self.delegate?.didRentBike!(response: response, error: nil)
                
            }
            
        }
        
        task.resume()
        
    }
    
    func returnBike(_ bike: Bike){
        
        guard let bikeId = bike.id else{
            
            print("bike.id was nil")
            return
        }
        
        let urlString = baseURL + "bikes/\(bikeId)"
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(bike) else{
            
            print("Unable to process bike data. Contact Support")
            return
        }
        
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            guard self.delegate != nil else{
                
                print("woah! delegate was nil")
                
                return
            }
            
            if let error = error as NSError?{
                
                self.delegate?.didReturnBike!(response: nil, error: error)
                
                return
                
            }
            
            if let response = response as? HTTPURLResponse{
                
                if response.statusCode == 200{
                    
                    
                    let stringRentURL = self.baseURL + "bikes/\(bikeId)/rented"
                    let rentUrl = URL(string: stringRentURL)!
                    var request = URLRequest(url: rentUrl)
                    request.httpMethod = "DELETE"
                    
                    let task = URLSession.shared.dataTask(with: request) { data, response, error in
                        
                        if let error = error as NSError?{
                            
                            self.delegate?.didReturnBike!(response: nil, error: error)
                            
                            return
                            
                        }
                        
                        if let response = response as? HTTPURLResponse{
                            
                            self.delegate?.didReturnBike!(response: response, error: nil)
                            
                            
                        }
                        
                    }
                    
                    task.resume()
                    
                }else if response.statusCode == 400{
                    
                    print("Server: Invalid bike")
                    
                }else if response.statusCode == 404{
                    
                    print("Server: Bike not found")
                    
                }
                
            }
        }
        
        task.resume()
        
    }
    
}
