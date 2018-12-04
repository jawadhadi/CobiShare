//
//  FrameColorPicker.swift
//  CobiShare
//
//  Created by Hadi on 22/11/2018.
//  Copyright © 2018 Hadi. All rights reserved.
//

import UIKit

private let reuseIdentifier = "colorCell"

class FrameColorPicker: UICollectionViewController {

    let hexColorCodes = ["000000", "FF0000", "0C88C2", "00C8E6", "3D3D3D", "76CD68", "CACACA", "EAB151", "FA4B69", "FFC300", "581845", "048DC8", "FFFFFF", "625693", "D3249B", "E0AAE2"]

    var delegate: AddBikeViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
       
        return hexColorCodes.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
    
        let hexCode = hexColorCodes[indexPath.item]
        cell.backgroundColor = UIColor.from(hexCode: hexCode) //implemented as an extension to UIColor
        
        return cell
    }
        
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let selectedCell = collectionView.cellForItem(at: indexPath)
        let colorHex = hexColorCodes[indexPath.item]
        let color = selectedCell?.backgroundColor
        delegate!.setFrameColor(color: color!, for: colorHex)
        
    }

}
