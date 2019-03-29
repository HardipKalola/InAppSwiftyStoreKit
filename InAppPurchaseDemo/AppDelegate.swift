//
//  AppDelegate.swift
//  InAppPurchaseDemo
//
//  

import UIKit
import SwiftyStoreKit

var arrProductIds = Set<String>()
let PRODUCT_ID_YEARLY = "your product id" //Testing
var APPLE_VALIDATOR = AppleReceiptValidator(service: .sandbox, sharedSecret: "your secret key") // Testing Secret
var freeTrailDetail = "your trail duration"
var priceYearlyPack = "your in app price default"


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        self.getProductInfo()
        self.autoBuyForAppleID()
    
        arrProductIds = [PRODUCT_ID_YEARLY]
        self.verifyReceipt(productIds: arrProductIds)
        return true
    }
    func autoBuyForAppleID(){
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        // Deliver content from server, then:
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                    // Unlock content
                    if purchase.productId == PRODUCT_ID_YEARLY{
                        UserDefaults.standard.set(true, forKey: PRODUCT_ID_YEARLY)
                        UserDefaults.standard.synchronize()
                    }
                // Unlock content
                case .failed, .purchasing, .deferred:
                    break // do nothing
                }
            }
        }
    }
    func verifyReceipt(productIds : Set<String>){
        SwiftyStoreKit.verifyReceipt(using: APPLE_VALIDATOR) { result in
            switch result {
            case .success(let receipt):
                let purchaseResult = SwiftyStoreKit.verifySubscriptions(productIds: productIds, inReceipt: receipt)
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
    func getProductInfo(){
        SwiftyStoreKit.retrieveProductsInfo([PRODUCT_ID_YEARLY]) { result in
            
            if result.retrievedProducts.count > 0{
                for product in result.retrievedProducts{
                    print("Product: \(product.localizedDescription), price: \(product.localizedPrice!)")
                     if product.productIdentifier == PRODUCT_ID_YEARLY{
                        priceYearlyPack = product.localizedPrice!
                        if #available(iOS 11.2, *) {
                            let period = String(format: "%lu", product.introductoryPrice?.subscriptionPeriod.numberOfUnits ?? 0)
                            var periodUnit = ""
                            switch product.introductoryPrice!.subscriptionPeriod.unit {
                            case .day:
                                periodUnit = "days"
                            case .week:
                                periodUnit = "week"
                            case .month:
                                periodUnit = "month"
                            case .year:
                                periodUnit = "year"
                            }
                            let trialPeriod = "Free for "+"\(period) \(periodUnit)"
                            print("trialPeriod: \(trialPeriod)")
                            freeTrailDetail = trialPeriod
                            print("freeTrailDetail: \(freeTrailDetail)")
                        } else {
                            freeTrailDetail = "3 Day free"
                        }
                    }
                }
            }
            else if let invalidProductId = result.invalidProductIDs.first {
                print("Invalid product identifier: \(invalidProductId)")
            }
            else {
                print("Error: \(result.error)")
            }
        }
    }
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

