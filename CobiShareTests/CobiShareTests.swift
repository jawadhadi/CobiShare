//
//  CobiShareTests.swift
//  CobiShareTests
//
//  Created by Hadi on 03/12/2018.
//  Copyright © 2018 Hadi. All rights reserved.
//

import XCTest
import CoreLocation
@testable import CobiShare

class CobiShareTests: XCTestCase, CobiBikeAPIDelegate {

    private let mockCobiBikeAPI = MockCobiBikeAPI()
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        
        mockCobiBikeAPI.delegate = self
        
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testUIColorFromHexCode(){
    
        let redHexCode = "FF0000" //hex code for red color
        let redColor = UIColor.from(hexCode: redHexCode)
        XCTAssertEqual(redColor, .red)
        
        let greenHexCode = "00FF00" //hex code for green color
        let greenColor = UIColor.from(hexCode: greenHexCode)
        XCTAssertEqual(greenColor, .green)
        
        let blueHexCode = "0000FF" //hex code for green color
        let blueColor = UIColor.from(hexCode: blueHexCode)
        XCTAssertEqual(blueColor, .blue)
        
        let badColorHex = "X32146"
        let badColor = UIColor.from(hexCode: badColorHex)
        XCTAssertNil(badColor)
        
        let incompleteColorHex = "FF00"
        let incompleteColor = UIColor.from(hexCode: incompleteColorHex)
        XCTAssertNil(incompleteColor)
        
        let redColorLowerCaseHex = "ff0000"
        let redColor2 = UIColor.from(hexCode: redColorLowerCaseHex)
        XCTAssertEqual(redColor2, .red)
        
    }
    
    //////////////////////////GET NEARBY BIKES
    
    private var getBikesExpectation: XCTestExpectation!
    private var bikeCount = 0
    
    func testGetNearbyBikes(){
        
        getBikesExpectation = expectation(description: "getBikes")
        
        let fakeLocation = CLLocation(latitude: CLLocationDegrees(50.119926), longitude: CLLocationDegrees(8.637754))
        mockCobiBikeAPI.getNearbyBikes(forLocation: fakeLocation, withRadius: 500)
        
        wait(for: [getBikesExpectation], timeout: 5)
        XCTAssertEqual(self.bikeCount, 3)
        
    }
    
    func didGetNearbyBikes(_ data: Data?, response: HTTPURLResponse?, error: NSError?) {
        
        if error == nil{
            
            if let statusCode = response?.statusCode{
                
                if statusCode == 200{
                    
                    //self.rentBikeStatusCode = 200
                    //rentBikeExpectation.fulfill()
                    
                    guard let data = data else{
                        
                        print("data was nil")
                        return
                    }
                    
                    BikeParser.parseBike(data, onSuccess: { (bikes) in
                        
                        self.bikeCount = (bikes?.count)!
                        self.getBikesExpectation.fulfill()
                        
                    }) { (error) in
                        
                        print("Parsing bikes failed")
                        
                    }
                    
                    
                }
                
            }
            
        }
        
    }
    
    ////////////////////////// ADD BIKE
    
    private var addBikeExpectation: XCTestExpectation!
    private var addBikeStatusCode: Int!
    
    func testAddBike(){
        
        addBikeExpectation = expectation(description: "addBike")
        
        let bikeLocation = Location(latitude: 50.149926, longitude: 8.677754)
        let newBike = Bike(name: "TestBike", color: "625693", pin: "4444", location: bikeLocation)
        
        mockCobiBikeAPI.addBike(newBike)
        
        wait(for: [addBikeExpectation], timeout: 5)
        XCTAssertEqual(self.addBikeStatusCode, 200)
    }
    
    func didAddBike(response: HTTPURLResponse?, error: NSError?) {
        
        if error == nil{
            
            if let statusCode = response?.statusCode{
                
                if statusCode == 200{
                
                    self.addBikeStatusCode = 200
                    addBikeExpectation.fulfill()
                    
                }
                
            }
            
        }
        
    }
    
    
    ////////////////////////// RENT BIKE
    
    private var rentBikeExpectation: XCTestExpectation!
    private var rentBikeStatusCode: Int!
    
    func testRentBike(){
        
        rentBikeExpectation = expectation(description: "rentBike")
        
        mockCobiBikeAPI.rentBike(withId: 1)
        

        wait(for: [rentBikeExpectation], timeout: 5)
        XCTAssertEqual(self.rentBikeStatusCode, 200)
    }
    
    func didRentBike(response: HTTPURLResponse?, error: NSError?) {
        
        if error == nil{
            
            if let statusCode = response?.statusCode{
                
                if statusCode == 200{
                    
                    self.rentBikeStatusCode = 200
                    rentBikeExpectation.fulfill()
                    
                }
                
            }
            
        }
        
    }
    
    ////////////////////////// RETURN BIKE
    
    private var returnBikeExpectation: XCTestExpectation!
    private var returnBikeStatusCode: Int!
    
    func testReturnBike(){
        
        returnBikeExpectation = expectation(description: "returnBike")
        
        let fakeLocation = Location(latitude: 50.149726, longitude: 8.677954)
        var fakeRentedBike = Bike(name: "Bike2", color: "581845", pin: "5678", location: fakeLocation)
        fakeRentedBike.id = 2
        
        mockCobiBikeAPI.returnBike(fakeRentedBike)
        
        wait(for: [returnBikeExpectation], timeout: 5)
        XCTAssertEqual(self.returnBikeStatusCode, 200)
    }
    
    func didReturnBike(response: HTTPURLResponse?, error: NSError?) {
        
        if error == nil{
            
            if let statusCode = response?.statusCode{
                
                if statusCode == 200{
                    
                    self.returnBikeStatusCode = 200
                    returnBikeExpectation.fulfill()
                    
                }
                
            }
            
        }
    }
    
    /////////////MOCK API
    
    class MockCobiBikeAPI: CobiBikeAPI{
        
        //static to keep count
        static var currentId = 1
        var bikesDictionary: [Int: Bike]
        
        let mockURL: URL
        var fakeResponse: HTTPURLResponse?
        
        override init() {
            
            //populating 3 fake bikes
            
            bikesDictionary = [Int: Bike]()
            
            var bikes = [Bike]()
            
            let fakeLocation1 = Location(latitude: 50.149826, longitude: 8.677854)
            let fakeBike1 = Bike(name: "Bike1", color: "FFC300", pin: "1234", location: fakeLocation1)
            
            bikes.append(fakeBike1)
            
            let fakeLocation2 = Location(latitude: 50.149726, longitude: 8.677954)
            let fakeBike2 = Bike(name: "Bike2", color: "581845", pin: "5678", location: fakeLocation2)
            
            bikes.append(fakeBike2)
            
            let fakeLocation3 = Location(latitude: 50.149626, longitude: 8.677995)
            let fakeBike3 = Bike(name: "eBike3", color: "625693", pin: "0000", location: fakeLocation3)
            
            bikes.append(fakeBike3)
            
            for var bike in bikes{
                
                bike.id = CobiShareTests.MockCobiBikeAPI.currentId
                bike.rented = false
                bikesDictionary[bike.id!] = bike
                CobiShareTests.MockCobiBikeAPI.currentId += 1
                
            }
            
            mockURL = URL(string: "http://localhost:3000/")!
            fakeResponse = HTTPURLResponse(url: mockURL, statusCode: 200, httpVersion: "1.1", headerFields: nil)
            
        }
        
        override func getNearbyBikes(forLocation location: CLLocation, withRadius radius: Int) {
            
            let encoder = JSONEncoder()
            var bikes = [Bike]()
            for (_, bike) in bikesDictionary{
                
                bikes.append(bike)
                
            }
            
            guard let jsonData = try? encoder.encode(bikes) else{
                
                print("Suprisingly JSON encoding failed")
                
                return
            }
            
            delegate?.didGetNearbyBikes!(jsonData, response: fakeResponse, error: nil)
            
        }
        
        override func addBike(_ bike: Bike) {
            
            var newBike = bike
            
            CobiShareTests.MockCobiBikeAPI.currentId += 1
            newBike.id = CobiShareTests.MockCobiBikeAPI.currentId
            newBike.rented = false
            bikesDictionary[newBike.id!] = newBike
            
            delegate?.didAddBike!(response: fakeResponse, error: nil)
        }
        
        override func rentBike(withId id: Int) {
            
            guard id <= bikesDictionary.count + 1 else{
                
                return
                
            }
            
            bikesDictionary[id]?.rented = true
            
            delegate?.didRentBike!(response: fakeResponse, error: nil)
            
        }
        
        override func returnBike(_ bike: Bike) {
            
            var updatedBike = bike
            updatedBike.rented = false
            updatedBike.location = Location(latitude: 50.159926, longitude: 8.667754) //new fake location
            bikesDictionary[updatedBike.id!] = updatedBike
            
            delegate?.didReturnBike!(response: fakeResponse, error: nil)
            
        }
        
    }


}
