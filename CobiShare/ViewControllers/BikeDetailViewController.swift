//
//  BikeDetailViewController.swift
//  CobiShare
//
//  Created by Hadi on 24/11/2018.
//  Copyright © 2018 Hadi. All rights reserved.
//

import UIKit
import MBProgressHUD

class BikeDetailViewController: UIViewController, UIGestureRecognizerDelegate {
    
    var bike: Bike?
    weak var delegate: MapViewController! //to send back the id of bike if it gets rented
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var frameColorView: UIView!
    @IBOutlet weak var pinLabel: UILabel!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var rentBikeButton: UIButton!
    
    private let cobiBikeAPI = CobiBikeAPI()
    
    var progressHUD: MBProgressHUD?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cobiBikeAPI.delegate = self
        
        frameColorView.clipsToBounds = true
        frameColorView.layer.cornerRadius = 5
        
        rentBikeButton.clipsToBounds = true
        rentBikeButton.layer.cornerRadius = 15
        
        contentView.layer.cornerRadius = 20
        contentView.clipsToBounds = true
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissViewController))
        tapGestureRecognizer.delegate = self
        view.addGestureRecognizer(tapGestureRecognizer)

        nameLabel.text = bike!.name
        
        pinLabel.text = bike!.pin
        
        frameColorView.backgroundColor = UIColor.from(hexCode: bike!.color)
        
        NotificationCenter.default.addObserver(self, selector: #selector(userDidTurnOffLocationServices), name: NSNotification.Name(rawValue: "locationServicesDisabled"), object: nil)
        
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        return gestureRecognizer.view == touch.view
        
    }

    var rentBikeId: Int!
    @IBAction func didTapRentButton() {
        
        guard let bikeId = bike?.id else{
            
            print("Bike.id was nil. How was that even possible?")
            
            return
            
        }
        
        //to send back to delegate upon success call
        rentBikeId = bikeId
        
        progressHUD = MBProgressHUD.showAdded(to: self.view, animated: true)
        
        cobiBikeAPI.rentBike(withId: bikeId)
        
    }
    
    @objc func dismissViewController(){
        
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
    @objc func userDidTurnOffLocationServices(){
    
        self.dismiss(animated: true, completion: nil)
        delegate.showLocationErrorViewController()
    
    }

}

extension BikeDetailViewController: CobiBikeAPIDelegate{
    
    func didRentBike(response: HTTPURLResponse?, error: NSError?) {
        
        if let hud = progressHUD{
            
            DispatchQueue.main.async {
                hud.hide(animated: true)
            }
            
        }
        
        if let error = error{
            
            DispatchQueue.main.async {
                self.handleURLErrors(withCode: error.code)
            }
            
            return
            
        }
        
        guard let response = response else{
            
            print("Response was nil, who's the culprit?")
            return
        }
            
        if response.statusCode == 200{
            
            DispatchQueue.main.async {
            
                self.delegate.userDidRentBike(with: self.rentBikeId)
                self.dismissViewController()
                
            }
            
            
        }else if response.statusCode == 400{
            
            DispatchQueue.main.async {
            
                let alert = UIAlertController(title: "Error", message: "Sorry this bike is no longer available to rent.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (action) in
                    
                    //update map to remove this bike from it
                    self.delegate.getNearByBikes()
                    
                    self.dismiss(animated: true, completion: nil)
                }))
                self.present(alert, animated: true, completion: nil)
                
            }
            
        }else if response.statusCode == 404{
            
            DispatchQueue.main.async {
                
                let alert = UIAlertController(title: "Error", message: "Bike not found. Contact support", preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (action) in
                    self.dismiss(animated: true, completion: nil)
                }))
                self.present(alert, animated: true, completion: nil)
                
            }
            
        }
        
    }
    
}

extension BikeDetailViewController{
    
    private func showErrorAlert(withMessage message: String){
        
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    private func handleURLErrors(withCode code: Int){
        
        switch code{
            
        case NSURLErrorTimedOut:
            
            self.showErrorAlert(withMessage: "Request timed out. Make sure you are connected to Internet.")
            
        case NSURLErrorCannotConnectToHost:
            
            self.showErrorAlert(withMessage: "Could not connect to COBI.Network. Make sure you're connected to Internet. Otherwise contact support.")
            
        default:
            
            self.showErrorAlert(withMessage: "An error occurred. Contact support.")
            
        }
        
    }

    
}
