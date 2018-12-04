//
//  Bike.swift
//  CobiShare
//
//  Created by Hadi on 23/11/2018.
//  Copyright © 2018 Hadi. All rights reserved.
//

import Foundation

struct Bike: Codable{

    var id: Int? = nil
    var name: String
    var color: String
    var pin: String
    var location: Location
    var rented: Bool? = nil
    
    init(name: String, color: String, pin: String, location: Location) {
        self.name = name
        self.color = color
        self.pin = pin
        self.location = location
    }
    
}


struct Location: Codable{
    
    var latitude: Double
    var longitude: Double
    
}
