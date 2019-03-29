//
//  ViewController.swift
//  InAppPurchaseDemo
//

import UIKit
import SwiftyStoreKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    func purchaseProduct(){
       //Loader Show
        SwiftyStoreKit.purchaseProduct(PRODUCT_ID_YEARLY, atomically: true) { result in
           //Loader Hide
            if case .success(let purchase) = result {
                // Deliver content from server, then:
                if purchase.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }
                SwiftyStoreKit.verifyReceipt(using: APPLE_VALIDATOR) { result in
                    
                    if case .success(let receipt) = result {
                        let purchaseResult = SwiftyStoreKit.verifySubscription(
                            ofType: .autoRenewable,
                            productId: PRODUCT_ID_YEARLY,
                            inReceipt: receipt)
                        switch purchaseResult {
                        case .purchased(let expiryDate, let receiptItems):
                            UserDefaults.standard.set(true, forKey: PRODUCT_ID_YEARLY)
                            UserDefaults.standard.synchronize()
                            print("Product-\(receiptItems) is valid until \(expiryDate)")
                            
                        case .expired(let expiryDate, let receiptItems):
                            UserDefaults.standard.set(false, forKey: PRODUCT_ID_YEARLY)
                            UserDefaults.standard.synchronize()
                            print("Product-\(receiptItems) is expired since \(expiryDate)")
                        case .notPurchased:
                            print("This product has never been purchased")
                        }
                    } else {
                        // receipt verification error
                    }
                }
            } else {
                // purchase error
                //Loader Hide
            }
        }
    }
    func restorePurchaseClicked() {
        
        //Loader Show
        SwiftyStoreKit.restorePurchases(atomically: false) { results in
            if results.restoreFailedPurchases.count > 0 {
               //Loader Hide
                print("Restore Failed: \(results.restoreFailedPurchases)")
            }
            else if results.restoredPurchases.count > 0 {
                for purchase in results.restoredPurchases {
                    // fetch content from your server, then:
                    if purchase.needsFinishTransaction {
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                    print("Restore Success: \(results.restoredPurchases)")
                    // Unlock content
                     if purchase.productId == PRODUCT_ID_YEARLY{
                            UserDefaults.standard.set(true, forKey: PRODUCT_ID_YEARLY)
                            UserDefaults.standard.synchronize()
                       //Loader Show
                        self.verifyReceipt(productIds: [PRODUCT_ID_YEARLY])
                        return
                    }
                }
            }
            else {
                //Loader Hide
                print("Nothing to Restore")
            }
        }
    }
    // Verify Receipt
    func verifyReceipt(productIds : Set<String>){
        SwiftyStoreKit.verifyReceipt(using: APPLE_VALIDATOR) { result in
            switch result {
            case .success(let receipt):
                let purchaseResult = SwiftyStoreKit.verifySubscriptions(productIds: productIds, inReceipt: receipt)
                //Hide Loader
                switch purchaseResult {
                case .purchased(let expiryDate, let items):
                    for item in items{
                        if item.productId == PRODUCT_ID_YEARLY{
                            UserDefaults.standard.set(true, forKey: PRODUCT_ID_YEARLY)
                            UserDefaults.standard.synchronize()
                        }
                    }
                    print("\(productIds) are valid until \(expiryDate)\n\(items)\n")
                case .expired(let expiryDate, let items):
                    for item in items{
                        if item.productId == PRODUCT_ID_YEARLY{
                            UserDefaults.standard.set(false, forKey: PRODUCT_ID_YEARLY)
                            UserDefaults.standard.synchronize()
                        }
                    }
                    print("\(productIds) are expired since \(expiryDate)\n\(items)\n")
                case .notPurchased:
                    print("The user has never purchased \(productIds)")
                }
            case .error(let error):
                print("Receipt verification failed: \(error)")
            }
        }
    }
}

