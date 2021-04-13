//
//  AppDelegate.swift
//  AppInvokeSampleApp
//
//  Created by Payal Gupta on 14/11/19.
//  Copyright © 2019 Payal Gupta. All rights reserved.
//

import UIKit
import AppInvokeSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
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
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let dict = self.separateDeeplinkParamsIn(url: url.absoluteString, byRemovingParams: nil)
        print("🔶 Paytm Callback Response: ", dict)
        // Below code is for adding mpass-events when user receives callback from to paytm app to sdk
        /* AIHandler().callGetURLRequest(mID: dict["mid"] ?? "",orderID: dict["orderId"] ?? "", eventAction: "Paytm_App_Response", eventLabel:"true" )
        var statusStr = "fail"
        if dict["status"] == "PYTM_103"{
            statusStr = "success"
            
        }
        AIHandler().callGetURLRequest(mID: dict["mid"] ?? "", orderID: dict["orderId"] ?? "", eventAction: "Response_Back",eventLabel: statusStr) */

        let alert = UIAlertController(title: "Response", message: dict.description, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        window?.rootViewController?.present(alert, animated: true, completion: nil)
        return true
    }

    func separateDeeplinkParamsIn(url: String?, byRemovingParams rparams: [String]?)  -> [String: String] {
        guard let url = url else {
            return [String : String]()
        }
        
        /// This url gets mutated until the end. The approach is working fine in current scenario. May need a revisit.
        var urlString = stringByRemovingDeeplinkSymbolsIn(url: url)
        
        var paramList = [String : String]()
        let pList = urlString.components(separatedBy: CharacterSet.init(charactersIn: "&?"))
        for keyvaluePair in pList {
            let info = keyvaluePair.components(separatedBy: CharacterSet.init(charactersIn: "="))
            if let fst = info.first , let lst = info.last, info.count == 2 {
                paramList[fst] = lst.removingPercentEncoding
                if let rparams = rparams, rparams.contains(info.first!) {
                    urlString = urlString.replacingOccurrences(of: keyvaluePair + "&", with: "")
                    //Please dont interchage the order
                    urlString = urlString.replacingOccurrences(of: keyvaluePair, with: "")
                }
            }
            if info.first == "response" {
                paramList["response"] = keyvaluePair.replacingOccurrences(of: "response=", with: "").removingPercentEncoding
            }
        }
        if let trimmedURL = pList.first {
            paramList["trimmedurl"] = trimmedURL
        }
        if let status = paramList["status"] {
            paramList["statusReason"] = addStatusString(status)
        }
        return paramList
    }
    
    private func addStatusString(_ status: String) -> String {
        switch status {
        case "PYTM_100":
            return "none"
        case "PYTM_101":
            return "initiated"
        case "PYTM_102":
            return "paymentMode"
        case "PYTM_103":
            return "paymentDeduction"
        case "PYTM_104":
            return "errorInParameter"
        case "PYTM_105":
            return "error"
        case "PYTM_106":
            return "cancel"
        default:
            return ""
        }
    }
    
    func  stringByRemovingDeeplinkSymbolsIn(url: String) -> String {
        var urlString = url.replacingOccurrences(of: "$", with: "&")
        
        /// This may need a revisit. This is doing more than just removing the deeplink symbol.
        if let range = urlString.range(of: "&"), urlString.contains("?") == false{
            urlString = urlString.replacingCharacters(in: range, with: "?")
        }
        return urlString
    }
}

