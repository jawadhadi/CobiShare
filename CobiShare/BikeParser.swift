//
//  BikeParser.swift
//  CobiShare
//
//  Created by Hadi on 04/12/2018.
//  Copyright © 2018 Hadi. All rights reserved.
//

import Foundation

class BikeParser{
    
    static func parseBike(_ data: Data, onSuccess: (_ bikes : [Bike]?) -> (),
                          onFailure: (_ error : NSError?) -> ()){
        
        let decoder = JSONDecoder()
        
        guard let latestBikes = try? decoder.decode([Bike].self, from: data) else {
            
            let error = NSError(domain: "Parse error", code: 200, userInfo: nil)
            onFailure(error)
            
            return
            
        }
        
        onSuccess(latestBikes)
        
    }
    
}
