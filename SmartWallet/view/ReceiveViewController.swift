//
//  ReceiveViewController.swift
//  SmartWallet
//
//  Created by Frederic DE MATOS on 09/03/2020.
//  Copyright © 2020 Frederic DE MATOS. All rights reserved.
//

import UIKit

class ReceiveViewController: UIViewController {

    
    @IBOutlet weak var qrcodeImageView: UIImageView!
    
    @IBOutlet weak var addressLabel: UILabel!
    
    override func viewDidLoad() {
        self.qrcodeImageView.image = self.generateQRCode(from:self.rockside.identity!.ethereumAddress)
        
        self.addressLabel.text = self.rockside.identity?.ethereumAddress
    }
    
    @IBAction func copyAddressAction(_ sender: Any) {
         UIPasteboard.general.string = self.rockside.identity?.ethereumAddress
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)

            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }

        return nil
    }
    
}
