//
//  ViewController.swift
//  AppInvokeSampleApp
//
//  Created by Payal Gupta on 14/11/19.
//  Copyright © 2019 Payal Gupta. All rights reserved.
//

import UIKit
import AppInvokeSDK

class ViewController: UIViewController {
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    //MARK: Outlets
    @IBOutlet weak var merchantIdTextField: UITextField!
    @IBOutlet weak var orderIdTextField: UITextField!
    @IBOutlet weak var txnTokenTextField: UITextField!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var callbackTextField: UITextField!
    @IBOutlet weak var switchRestrictAppinvoke: UISwitch!


    //MARK: Private Properties
    private let appInvoke = AIHandler()
    private var orderId: String = ""
    private var merchantId: String = ""
    private var txnToken: String = ""
    private var amount : String = ""
    private var callBackURL : String = ""
    private var makeSubscriptionPayment : Bool = false
    
    //MARK: Lifecycle Methods
    @IBAction func restrictAppInvoke(_ sender: Any) {
        appInvoke.restrictAppInvokeFlow(restrict: switchRestrictAppinvoke.isOn)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addKeyboardNotifications()
        //self.appInvoke.version()
    }
}

//MARK: - Button Action Methods
extension ViewController {
    @IBAction func openPaytm(_ sender: UIButton) {
        self.orderId = (self.orderIdTextField.text == "") ? "OrderTest" + "\(arc4random())" : self.orderIdTextField.text!
        let alert = UIAlertController(title: "Environment", message: "Select the server environment in which you want to open paytm.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Staging", style: .default, handler: {[weak self] (action) in
            self?.hitInitiateTransaction(.staging)
        }))
        alert.addAction(UIAlertAction(title: "Production", style: .default, handler: {[weak self] (action) in
            self?.hitInitiateTransaction(.production)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func showSubsDetails(_ sender: UISwitch) {
        self.makeSubscriptionPayment = sender.isOn
    }
}

// MARK: - AIDelegate
extension ViewController: AIDelegate {
    func didFinish(with status: AIPaymentStatus, response: [String : Any]) {
        print("🔶 Paytm Callback Response: ", response)
        let alert = UIAlertController(title: "\(status)", message: String(describing: response), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func openPaymentWebVC(_ controller: UIViewController?) {
        if let vc = controller {
            DispatchQueue.main.async {[weak self] in
                self?.present(vc, animated: true, completion: nil)
            }
        }
        self.dismiss(animated: true)
    }
}

// MARK: - API Integration
private extension ViewController {
    
    func hitInitiateTransaction(_ env: AIEnvironment) {
        let isValid = validateTextFields()
        if isValid.0{
            self.showAlert(message: isValid.1)
        }else{
            let mid = self.merchantIdTextField.text
            let orderId = self.orderIdTextField.text
            let txnToken = self.txnTokenTextField.text
            let callBack = self.callbackTextField.text
            let amount = self.amountTextField.text
            
            if let mId = mid{
                self.merchantId = mId
            }
            if let ordId = orderId{
                self.orderId = ordId
            }
            if let txn = txnToken{
                self.txnToken = txn
            }
            if let callback = callBack{
                self.callBackURL = callback
            }
            if let amt = amount{
                self.amount = amt
            }
            
            if self.makeSubscriptionPayment{
                self.appInvoke.openPaytmSubscription(merchantId: self.merchantId, orderId: self.orderId, txnToken: self.txnToken, amount: self.amount, callbackUrl: self.callBackURL, delegate: self, environment: env)
            }else{
                self.appInvoke.openPaytm(merchantId: self.merchantId, orderId: self.orderId, txnToken: self.txnToken, amount: self.amount, callbackUrl:self.callBackURL, delegate: self, environment: env)
            }
        }
    }
    
    func validateTextFields() -> (Bool, String){
        var count = 0
        var msg = ""
        if let mid = merchantIdTextField.text, mid.isEmpty{
            count = count + 1
            msg = "Enter valid MID"
        }
        if let orderId = orderIdTextField.text, orderId.isEmpty{
            count = count + 1
            msg += "\n Enter valid Order Id"
        }
        if let txnToken = txnTokenTextField.text, txnToken.isEmpty{
            count = count + 1
            msg += "\n Enter valid Txn Token here"
        }
        if let callback = callbackTextField.text, callback.isEmpty{
            count = count + 1
            msg += "\n Enter valid Callback URL here"
        }
        if count > 0{
            return (true,msg)
        }else{
            return (false,"")
        }
        
    }
}

//MARK:- Private Methods
private extension ViewController {
    func showAlert(message: String?) {
        let alert = UIAlertController(title: "Alert..!!!", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func printRequest(_ request: URLRequest, for api: String) {
        print("🔷 \(api) Request")
        if let data = request.httpBody, let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("\nBody Params:", dict)
        }
        print("--------------------")
    }
    
    func printResponse(_ dict: [String:Any]?, for api: String) {
        print("🔶 \(api) Response")
        print("--------------------")
    }
    
    func currentDate() -> String? {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

//MARK:- Keyboard Handling
private extension ViewController {
    func addKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillhide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    @objc func keyboardWillAppear(notification: Notification) {
        if var keyBoardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as AnyObject?)?.cgRectValue?.size.height {
            if UIScreen.main.bounds.height >= 812.0 {
                keyBoardHeight -= 34.0
            }
            UIView.animate(withDuration: 1.0) {
                self.scrollViewBottomConstraint.constant = keyBoardHeight
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @objc func keyboardWillhide(notification: Notification) {
        self.scrollViewBottomConstraint.constant = 0
        UIView.animate(withDuration: 1.0) {
            self.view.layoutIfNeeded()
        }
    }
}

//MARK:- UITextFieldDelegate methods
extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}

extension UITextField {
    func getText() -> String? {
        if let text = self.text, !text.isEmpty {
            return text
        }
        return nil
    }
}
