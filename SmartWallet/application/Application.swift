//
//  ApplicationContext.swift
//  SmartWallet
//
//  Created by Fred on 20/08/2020.
//  Copyright © 2020 Frederic DE MATOS. All rights reserved.
//

import Foundation
import web3
import BigInt


public class Application {
    
    static public var smartwallet: SmartWallet?
    static public var account: HDEthereumAccount?
    static public var network: Chain = .mainnet
    static public var baseGas: BigUInt = BigUInt(45000)
    static public var ethPrice: Double?
    static public var tokenPrices: [String: [String: Double]]?
    static public var gasPrices: Speeds?
    
    static public var backendService: BackendService = BackendService()
    static public var coinGeckoService: CoinGeckoService = CoinGeckoService()
    static public var etherscanService: EtherscanService = EtherscanService()
    
    static let ethereumClient: EthereumClient = EthereumClient(url: URL(string:infoForKey("RpcURL")! )!)
    
    static let erc20: ERC20 = ERC20(client: ethereumClient)
    
    static func restore(walletId: WalletID){
        
        //TODO REMOVE HARD CODDED AGRGENT ADDRESS
        self.smartwallet = Argent(address: "0xe37BBBdd7364D82d46f6C346AA8977e27e9E374B", rpc: ethereumClient)
        self.account = HDEthereumAccount(mnemonic: walletId.mnemonic)
        NSLog(self.account!.first.ethereumAddress.value)
        NSLog(self.account!.first.description)
              
    }
    
    static func clear(){
        self.smartwallet = nil
        self.account = nil
    }
    
    static func relay(to: web3.EthereumAddress, value:BigUInt, data: Data, safeTxGas: BigUInt, completion: @escaping (Result<(RelayResponse), Error>) -> Void)  -> Void {
        
        Application.backendService.getGasPrice(address: self.smartwallet!.address) { (result) in
            switch result {
            case .success(let gasPriceResponse):
                
                /*self.encodeExecuteGnosis(to: to, value: value, data: data, safeTxGas: safeTxGas, speed:gasPriceResponse.speeds.fastest) { (result) in
                    switch result {
                    case .success(let executeData):
                        
                        let gas = (safeTxGas + baseGas).description
                        print(gas)
                        Application.backendService.relayTransaction(smartWallet: Application.smartwallet!, messageData: executeData, completion: completion)
                        return
                    case .failure(let error):
                        completion(.failure(error))
                        return
                    }
                
            
                }*/
                
                
                self.encodeExecuteArgent(to: to, value: value, data: data) { (result) in
                        switch result {
                        case .success(let executeData):
                            Application.backendService.relayTransaction(destination: Argent.transferModuleAddress, data: executeData.hexValue,//
                                                                       completion: completion)
                            return
                        case .failure(let error):
                            completion(.failure(error))
                            return
                        }
                    
                
                    }
        
                                      
                return
            case .failure(let error):
                completion(.failure(error))
                return
            }
        }
    }
    
    static func updateTokensPrices(tokens: [TokenBalance], completion: @escaping (Result<(Bool), Error>) -> Void)  -> Void {
        self.coinGeckoService.getTokenPrices(tokens: tokens) { (result) in
            switch result {
            case .success(let tokenPrices):
                self.tokenPrices = tokenPrices
                completion(.success(true))
                break
            case .failure(let error):
                completion(.failure(error))
                break
            }
            
        }
    }
    
    static func updateEthPrice(completion: @escaping (Result<(Double), Error>) -> Void)  -> Void {
        self.etherscanService.ethPrice(){ (result) in
            switch result {
            case .success(let ethPrice):
                self.ethPrice = Double(ethPrice.ethusd)
                completion(.success(self.ethPrice!))
                return
            case .failure(let error):
                self.ethPrice = nil
                completion(.failure(error))
                return
            }
        }
    }
    
    static func updateGasPrice(completion: @escaping (Result<(Speeds), Error>) -> Void)  -> Void {
        self.backendService.getGasPrice(address: self.smartwallet!.address) { (result) in
            switch result {
            case .success(let gasPriceResponse):
                self.gasPrices = gasPriceResponse.speeds
                completion(.success(gasPriceResponse.speeds))
                break
                
            case .failure(let error):
                NSLog(error.localizedDescription)
                completion(.failure(error))
                break
            }
        }
    }
    
    static func calculateEtherForGas(safeGas: BigUInt) -> BigUInt {
        guard let gasPrices = self.gasPrices else {
            return BigUInt(0)
        }
        
        
        let gasPrice = BigUInt(gasPrices.fastest.gas_price)!
        let totalGas = safeGas + Application.baseGas
        let totalEth = totalGas * gasPrice
        
        return totalEth
    }
    
    static func calculateGasFees(safeGas: BigUInt)  -> String {
        
        guard let price = self.ethPrice else {
            return ""
        }
        
        let totalEth = calculateEtherForGas(safeGas: safeGas)
        
        let formatter = EtherNumberFormatter()
        let ethNumber = formatter.string(from:BigInt(totalEth))
        let ethDouble = Double(ethNumber.replacingOccurrences(of: ",", with: "."))!
        
        let fees = ethDouble * price
        
        return "$"+String(format: "%.2f", fees)
    }
    
    static func isAccountOwner(completion: @escaping (Result<(Bool), Error>) -> Void)  -> Void {
        self.smartwallet?.isOwner(owner: web3.EthereumAddress(account!.first.ethereumAddress.value), completion: completion)
    }
    
    
    
    static func infoForKey(_ key: String) -> String? {
        return (Bundle.main.infoDictionary?[key] as? String)?
            .replacingOccurrences(of: "\\", with: "")
    }
    
    //MARK: Private method
    
    private static func encodeExecuteArgent(to: web3.EthereumAddress, value:BigUInt, data: Data, completion: @escaping (Result<(Data), Error>) -> Void)  -> Void {
    
        if let argentWallet = self.smartwallet as? Argent {
            
            
            argentWallet.getNonceArg() { (result) in
                switch result {
                case .success(let nonce):
                    var nonceBig = BigUInt(hex:nonce)!
                    nonceBig = nonceBig + BigUInt(1)
                    
                    let encoded = try! ABIEncoder.encode(nonceBig, staticSize: 256)
                    let nonce = encoded.hexString
                     NSLog("NONCE : "+nonce)
                    let callContractData =  argentWallet.encodeCallContract(to: to, value: value, data: data)
                    NSLog("DATA : "+callContractData.hexValue)
                    let hash = argentWallet.hashMessage(data: callContractData, nonce: nonce)
                    let signature = try! signMessage(message: hash, hdwallet: self.account!)
                 
                    let execData = argentWallet.encodeExec(data: callContractData, signature: Data(hex: signature), nonce: nonce)
                    completion(.success(execData))
                    return
                 case .failure(let error):
                    completion(.failure(error))
                    return
                }
                
            }
        } else {
            completion(.failure(NSError(domain: "NOT ARGENT WALLET", code: 0, userInfo: nil)))
        }
    
    }
    
    
    
    //MARK: Gnosis safe encode execute helper
    private static func encodeExecuteGnosis(to: web3.EthereumAddress, value:BigUInt, data: Data, safeTxGas: BigUInt, speed: Speed, completion: @escaping (Result<(String), Error>) -> Void)  -> Void {
           
           let gasPrice = BigUInt(speed.gas_price)!
           let refundAddress = EthereumAddress(speed.relayer)
           
           self.smartwallet!.getTransactionHashWithNonce(to: to, value: value, data: data, safeTxGas: safeTxGas, baseGas: baseGas, gasPrice:gasPrice , refundReceiver: refundAddress) { (result) in
               switch result {
               case .success(let hash):
                   let signature = self.account!.first.signV27(hash: Data(hex: hash)!)
                   let executeData = self.smartwallet!.encodeExecute(to: to, value: value, data: data, safeTxGas: safeTxGas, baseGas: baseGas, gasPrice: gasPrice, refundReceiver: refundAddress, signature: signature)
                   completion(.success(executeData))
                   return
               case .failure(let error):
                   completion(.failure(error))
                   return
               }
           }
       }
    
    
}
