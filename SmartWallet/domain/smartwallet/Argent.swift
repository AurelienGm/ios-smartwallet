//
//  Argent.swift
//  SmartWallet
//
//  Created by Fred on 11/09/2020.
//  Copyright © 2020 Frederic DE MATOS. All rights reserved.
//

import Foundation
import web3
import BigInt
import secp256k1

enum KeyUtilError: Error {
    case invalidContext
    case privateKeyInvalid
    case unknownError
    case signatureFailure
}

public struct Argent: SmartWallet {
    
    public static let transferModuleAddress =  EthereumAddress("0x103675510a219bd84CE91d1bcb82Ca194D665a09")
      
    public let address: EthereumAddress
    
    public let client: EthereumClient
    
    public init(address: String,  rpc: EthereumClient){
        self.address = web3.EthereumAddress(address)
        self.client = rpc
    }
    
    public var ethereumAddress: String {
        return self.address.value
    }
    
    
    public func encodeExecute(to: EthereumAddress, value: BigUInt, data: Data, safeTxGas: BigUInt, baseGas: BigUInt, gasPrice: BigUInt, refundReceiver: EthereumAddress, signature: Data) -> String {
        return ""
    }
    
    public func encodeAddOwnerWithThreshold(owner: EthereumAddress, threshold: BigUInt) -> String {
        return ""
    }
    
    public func isOwner(owner: EthereumAddress, completion: @escaping (Result<(Bool), Error>) -> Void) {
        completion(.success(true))
    }
    
    public func getNonce(completion: @escaping (Result<(BigUInt), Error>) -> Void) {
     completion(.success(BigUInt(0)))
    }
    
    public func getNonceArg(completion: @escaping (Result<(String), Error>) -> Void) {
        let function = GetNonceFunc(contract: Argent.transferModuleAddress, walletAddress: self.address)
        let transaction = try! function.transaction()
        
        self.client.eth_call(transaction) { (error, result) in
        
            guard error == nil else {
                completion(.failure(error!))
                return
            }
            
            guard let res = result else {
                completion(.failure(NSError(domain: "Nil result", code: 0, userInfo: nil)))
                return
            }
            completion(.success(res))
        }
    }
    
    public func getTransactionHashWithNonce(to: EthereumAddress, value: BigUInt, data: Data, safeTxGas: BigUInt, baseGas: BigUInt, gasPrice: BigUInt, refundReceiver: EthereumAddress, completion: @escaping (Result<(String), Error>) -> Void) {
        

        
        return completion(.success(""))
    }
    
    public func getOwners(completion: @escaping (Result<([String]), Error>) -> Void) {
        return completion(.success([""]))
    }
    
    public func encodeCallContract(to: EthereumAddress, value: BigUInt, data: Data) -> Data {
        NSLog("TO "+to.value+" "+value.description+" "+data.hexValue)
        let function =  CallContractFunc(contract: self.address, walletAddress: self.address, to: to, value: value, data: data)
        let transaction = try? function.transaction()
        return transaction!.data!
    }
    
    
    public func encodeExec(data: Data, signature: Data, nonce: String) -> Data {
        let function =  ExecuteFunc(contract: Argent.transferModuleAddress, from: self.address, walletAddress: self.address, data: data, nonce: BigUInt(hex:nonce)!, signature: signature)
        let transaction = try? function.transaction()
        return transaction!.data!
    }
    
    public func hashMessage(data: Data, nonce: String) -> Data {
        let zeroValue = String(format: "0x%064X", 0)
        let nonceValue = String(nonce.dropFirst(2)).leftPadding(toLength: 64, withPad: "0")
        
        let params: [String] = ["0x19",
                                "0x00",
                                Argent.transferModuleAddress.value,
                                self.address.value,
                                zeroValue, data.hexValue, "0x"+nonceValue, zeroValue, zeroValue]
        
        let concatenatedParams = "0x"+params.map { $0.dropFirst(2) }.joined(separator: "")
        
        return Data(hex: concatenatedParams).sha3(.keccak256)
    }
}


public struct GetNonceFunc: ABIFunction {
public static let name = "getNonce"
    public let gasPrice: BigUInt? = nil
       public let gasLimit: BigUInt? = nil
       public var contract: EthereumAddress
       public let from: EthereumAddress?
       
       public let walletAddress: EthereumAddress
    
    public init(contract: EthereumAddress,
                    from: EthereumAddress? = nil,
                    walletAddress: EthereumAddress) {
            self.contract = contract
            self.walletAddress = walletAddress
            self.from = from
        }
        
    public func encode(to encoder: ABIFunctionEncoder) throws {
        try encoder.encode(self.walletAddress)
    }
}





public struct CallContractFunc: ABIFunction {
    public static let name = "callContract"
    
    public let gasPrice: BigUInt? = nil
    public let gasLimit: BigUInt? = nil
    public var contract: EthereumAddress
    public let from: EthereumAddress?
    
    public let walletAddress: EthereumAddress
    public let to: EthereumAddress
    public let value: BigUInt
    public let data: Data
    
    public init(contract: EthereumAddress,
                from: EthereumAddress? = nil,
                walletAddress: EthereumAddress,
                to: EthereumAddress,
                value: BigUInt,
                data: Data) {
        self.contract = contract
        self.walletAddress = walletAddress
        self.from = from
        self.to = to
        self.value = value
        self.data = data
    }
    
    public func encode(to encoder: ABIFunctionEncoder) throws {
        try encoder.encode(self.walletAddress)
        try encoder.encode(self.to)
        try encoder.encode(self.value)
        try encoder.encode(self.data)
    }
}

public struct ExecuteFunc: ABIFunction {
    public static let name = "execute"
    
    public let gasPrice: BigUInt? = BigUInt(0)
    public let gasLimit: BigUInt? =  BigUInt(0)
    public var contract: EthereumAddress
    public let from: EthereumAddress?
    
    public let walletAddress: EthereumAddress
    public let data: Data
    public let nonce: BigUInt
    public let signature: Data
    
    public init(contract: EthereumAddress,
                from: EthereumAddress? = nil,
                walletAddress: EthereumAddress,
                data: Data,
                nonce: BigUInt,
                signature: Data) {
        self.contract = contract
        self.walletAddress = walletAddress
        self.from = from
        self.data = data
        self.nonce = nonce
        self.signature = signature
    }
    
    public func encode(to encoder: ABIFunctionEncoder) throws {
        try encoder.encode(self.walletAddress)
        try encoder.encode(self.data)
        try encoder.encode(self.nonce)
        try encoder.encode(self.signature)
        try encoder.encode(self.gasPrice!)
        try encoder.encode(self.gasLimit!)
        
    }
}


extension String {
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let stringLength = self.count
        if stringLength < toLength {
            return String(repeatElement(character, count: toLength - stringLength)) + self
        } else {
            return String(self.suffix(toLength))
        }
    }
}

func generateRandomBytes() -> String {

    var keyData = Data(count: 10)
    let result = keyData.withUnsafeMutableBytes {
        SecRandomCopyBytes(kSecRandomDefault, 10, $0.baseAddress!)
    }
    if result == errSecSuccess {
        return keyData.hexValue
    } else {
        print("Problem generating random bytes")
        return "0x0"
    }
}

public func signMessage(message: Data, hdwallet: HDEthereumAccount) throws -> String {
    let prefix = "\u{19}Ethereum Signed Message:\n\(String(message.count))"
    guard var data = prefix.data(using: .ascii) else {
        throw EthereumAccountError.signError
    }
    data.append(message)
    let hash = data.web3.keccak256
    
    guard var signed = try? hdwallet.first.sign(hash: hash) else {
        throw EthereumAccountError.signError
        
    }
    
    // Check last char (v)
    guard var last = signed.popLast() else {
        throw EthereumAccountError.signError
        
    }
    
    if last < 27 {
        last += 27
    }
    
    signed.append(last)
    return signed.web3.hexString
}



