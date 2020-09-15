//
//  WithoutWalletViewController.swift
//  SmartWallet
//
//  Created by Frederic DE MATOS on 06/03/2020.
//  Copyright © 2020 Frederic DE MATOS. All rights reserved.
//

import UIKit
import JGProgressHUD
import MaterialComponents.MaterialSnackbar

class WithoutWalletViewController: UIViewController {
    
    
    let walletStorage: WalletStorage = WalletStorage()
   
    @IBAction func createWalletAction(_ sender: Any) {
        
        let hud = JGProgressHUD(style: .extraLight)
        hud.textLabel.text = "Your wallet is being created.\nPlease wait (around 1 min)"
        hud.show(in: self.view)
        
        let hdAccount = HDEthereumAccount()
        Application.backendService.deployGnosisSafe(account: hdAccount.first.ethereumAddress.value){ (result) in
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                   
                    _ = Application.backendService.waitTxToBeMined(trackingID: response.tracking_id) { (result) in
                        switch result {
                        case .success(let receipt):
                            DispatchQueue.main.async {
                                hud.dismiss()
                                
                                let walletID = WalletID(address: receipt.logs[0].dataAsAddress(), mnemonic: hdAccount.mnemonic)
                                
                                Application.restore(walletId: walletID)
                                
                                try? self.walletStorage.store(walletID: walletID)
                                self.navigationController?.displayWalletView(animated: true, newWallet: true)
                            }
                            break
                            
                        case .failure(_):
                            DispatchQueue.main.async {
                                hud.dismiss()
                                self.displayErrorOccured()
                            }
                            break
                        }
                    }
                    
                    
                }
                
                break
            case .failure(let error):
                DispatchQueue.main.async {
                    print("######")
                    print(error)
                    hud.dismiss()
                    self.displayErrorOccured()
                }
                break
            }
        }
    }
    
    public func displayErrorOccured() {
        let snackBarMessage = MDCSnackbarMessage()
        snackBarMessage.text = "An error occured. Please try again."
       MDCSnackbarManager.default.show(snackBarMessage)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "show-wallet-segue" {
            if let destinationVC = segue.destination as? WalletViewController {
                destinationVC.isNewWallet = true
            }
        }
    
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
       
}
