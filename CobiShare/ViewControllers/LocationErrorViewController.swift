//
//  LocationErrorViewController.swift
//  CobiShare
//
//  Created by Hadi on 01/12/2018.
//  Copyright © 2018 Hadi. All rights reserved.
//

import UIKit

class LocationErrorViewController: UIViewController {

    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var contentView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        settingsButton.clipsToBounds = true
        settingsButton.layer.cornerRadius = 15
        
        contentView.layer.cornerRadius = 20
        contentView.clipsToBounds = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(dismissViewController), name: NSNotification.Name(rawValue: "hideLocationErrorController"), object: nil)
        
    }
    
    @IBAction func didTapSettingsButton() {
        
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        
    }
    
    @objc func dismissViewController(){
        
        self.dismiss(animated: true, completion: nil)
        
    }

}
