//
//  UIColor+fromHexCodeExtension.swift
//  CobiShare
//
//  Created by Hadi on 25/11/2018.
//  Copyright © 2018 Hadi. All rights reserved.
//

import Foundation
import UIKit

extension UIColor{
    
    public static func from(hexCode: String)-> UIColor?{
        
        var r = 0
        var g = 0
        var b = 0
        
        let hexToDec = ["0": 0, "1": 1, "2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7, "8": 8, "9": 9, "A": 10, "B": 11, "C": 12, "D": 13, "E": 14, "F": 15]
        
        guard hexCode.count == 6 else{
            return nil
        }
        
        let hexCodeUpper = hexCode.uppercased()
        
        var numberArray = [Int]()
        
        for char in hexCodeUpper{
            
            
            let characterString = String(char)
            guard let number = hexToDec[characterString] else{

                return nil

            }
            
            numberArray.append(number)
            
        }
        
        var index = 0
        for number in numberArray{

            index += 1

            if index <= 2{

                if index % 2 != 0{

                    r = number * 16

                }else{

                    r = r + number

                }

            }else if index <= 4{

                if index % 2 != 0{

                    g = number * 16

                }else{

                    g = g + number

                }

            }else if index <= 6{

                if index % 2 != 0{

                    b = number * 16

                }else{

                    b = b + number

                    let rFloat = CGFloat(integerLiteral: r)
                    let gFloat = CGFloat(integerLiteral: g)
                    let bFloat = CGFloat(integerLiteral: b)

                    return UIColor(red: rFloat/255, green: gFloat/255, blue: bFloat/255, alpha: 1.0)

                }

            }

        }
        
        return nil
        
    }
    
}
