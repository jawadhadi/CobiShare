//
//  AddBikeViewController.swift
//  CobiShare
//
//  Created by Hadi on 20/11/2018.
//  Copyright © 2018 Hadi. All rights reserved.
//

import UIKit
import GoogleMaps
import MBProgressHUD

class AddBikeViewController: UIViewController {
    
    @IBOutlet weak var miniMapView: GMSMapView!
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var pinTextField: UITextField!
    
    @IBOutlet weak var frameColorButton: UIButton!
    
    @IBOutlet weak var addBikeButton: UIButton!
    
    var selectedColorHex: String?
    
    var currentLocation: CLLocation?
    
    weak var delegate: MapViewController! //to update nearby bikes once a new is added
    
    private let cobiBikeAPI = CobiBikeAPI()
    
    var progressHUD: MBProgressHUD?

    var activeTextField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cobiBikeAPI.delegate = self
        
        pinTextField.delegate = self
        nameTextField.delegate = self
        
        frameColorButton.clipsToBounds = true
        frameColorButton.layer.cornerRadius = 10
        frameColorButton.layer.borderColor = UIColor.lightGray.cgColor
        frameColorButton.layer.borderWidth = 1
        
        nameTextField.clipsToBounds = true
        nameTextField.layer.cornerRadius = 10
        nameTextField.layer.borderColor = UIColor.lightGray.cgColor
        nameTextField.layer.borderWidth = 1
        
        pinTextField.clipsToBounds = true
        pinTextField.layer.cornerRadius = 10
        pinTextField.layer.borderColor = UIColor.lightGray.cgColor
        pinTextField.layer.borderWidth = 1
        
        addBikeButton.clipsToBounds = true
        addBikeButton.layer.cornerRadius = 10
        
        NotificationCenter.default.addObserver(self, selector: #selector(userDidTurnOffLocationServices), name: NSNotification.Name(rawValue: "locationServicesDisabled"), object: nil)
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(returnTextField(gesture:))))
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let location = currentLocation{
            
            let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: 18.0)
            miniMapView.camera = camera
            
            let marker = GMSMarker(position: location.coordinate)
            marker.map = miniMapView
            
        }
    }
    
    @IBAction func didTapFrameColorButton(_ sender: UIButton) {
        
        let frameColorPickerViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "frameColorPickerVC") as! FrameColorPicker
        
        frameColorPickerViewController.modalPresentationStyle = UIModalPresentationStyle.popover
        frameColorPickerViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.up
        frameColorPickerViewController.popoverPresentationController?.delegate = self
        frameColorPickerViewController.delegate = self //to get back selected color and it's hex
        frameColorPickerViewController.popoverPresentationController?.sourceView = frameColorButton
        frameColorPickerViewController.popoverPresentationController?.sourceRect = frameColorButton.bounds
        
        // present the popover
        self.present(frameColorPickerViewController, animated: true, completion: nil)
        
    }
    
    @IBAction func userDidTapAddBikeButton() {
        
        guard let name = nameTextField.text, !name.isEmpty else{
        
            self.showErrorAlert(withMessage: "Kindly enter your bike's name.")
            
            return
        }
        
        guard let frameColor = selectedColorHex else{
            
            self.showErrorAlert(withMessage: "Kindly select a frame color.")
            
            return
            
        }
        
        guard let pin = pinTextField.text, !pin.isEmpty else{
            
            self.showErrorAlert(withMessage: "Kindly enter 4-digit PIN.")
            
            return
            
        }
        
        guard pin.count == 4 else{
            
            self.showErrorAlert(withMessage: "PIN couldn't be less than 4 digits.")
            
            return
            
        }
        
        guard let location = currentLocation else{
            
            self.showErrorAlert(withMessage: "Unable to retrieve your location. Make sure you have given access to Location Services.")
            
            return
            
        }
        
        progressHUD = MBProgressHUD.showAdded(to: self.view, animated: true)
        
        let bikeLocation = Location(latitude: Double(location.coordinate.latitude), longitude: Double(location.coordinate.longitude))
        
        let newBike = Bike(name: name, color: frameColor, pin: pin, location: bikeLocation)
        
        cobiBikeAPI.addBike(newBike)

    }
    
    @IBAction func didTapCancelButton() {
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
    
    func setFrameColor(color: UIColor, for hexCode: String){
        
        frameColorButton.setTitle("", for: .normal)
        frameColorButton.backgroundColor = color
        selectedColorHex = hexCode
        
    }

}

extension AddBikeViewController: UITextFieldDelegate{
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == pinTextField{
        
            let currentText = textField.text ?? ""
            guard let stringRange = Range(range, in: currentText) else { return false }
            
            let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
            
            if updatedText.count < 4 {
                
                return true
                
            }else if updatedText.count == 4{
                
                textField.text = currentText+string
                textField.resignFirstResponder()
                return true
                
            }
            
            textField.resignFirstResponder()
            return false
        }
        
        return true
    }
    
    @objc func returnTextField(gesture: UIGestureRecognizer) {
        guard activeTextField != nil else {
            return
        }
        
        activeTextField?.resignFirstResponder()
        activeTextField = nil
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        
        activeTextField = textField
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        activeTextField = nil
        return true
    }
    
    @objc func userDidTurnOffLocationServices(){
        
        self.dismiss(animated: true, completion: nil)
        self.delegate.showLocationErrorViewController()
        
    }
    
}

extension AddBikeViewController: CobiBikeAPIDelegate{
    
    func didAddBike(response: HTTPURLResponse?, error: NSError?) {
        
        if let hud = self.progressHUD{
            
            DispatchQueue.main.async {
            
                hud.hide(animated: true)
            
            }
        }
        
        if let error = error{
            
            DispatchQueue.main.async {
                //because it will show alerts
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
                let alert = UIAlertController(title: "Success", message: "Your bike has been added successfully.", preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (action) in
                    
                    //to show the newly added bike to map
                    self.delegate.getNearByBikes()
                    self.dismiss(animated: true, completion: nil)
                }))
                self.present(alert, animated: true, completion: nil)
            }
            
        }else if response.statusCode == 400{
            
            DispatchQueue.main.async {
                self.showErrorAlert(withMessage: "Invalid bike data. Contact support")
            }
            
        }
        
    }
    
}

extension AddBikeViewController: UIPopoverPresentationControllerDelegate{
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
}

extension AddBikeViewController{
    
    
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
