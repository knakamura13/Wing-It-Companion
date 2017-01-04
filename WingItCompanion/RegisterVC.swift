//
//  RegisterVC.swift
//  WingItCompanion
//
//  Created by Kyle Nakamura on 12/31/16.
//  Copyright © 2016 Kyle Nakamura. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit
import SwiftKeychainWrapper

// Global Variables
var registerVCEmail: String!
var registerVCPassword: String!

class RegisterVC: UIViewController, UITextFieldDelegate {
    // Outlets
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var passwordConfirmField: UITextField!
    
    // Variables
    var ref: FIRDatabaseReference!
    
    override func viewWillAppear(_ animated: Bool) {
        emailField.text = loginVCEmail
    }
    
    override func viewDidAppear(_ animated: Bool) {
        emailField.delegate = self
        passwordField.delegate = self
        passwordConfirmField.delegate = self
        
        // Keyboard observers
        NotificationCenter.default.addObserver(self, selector: #selector(RegisterVC.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(RegisterVC.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    // Keyboard view-moving functions
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += keyboardSize.height
            }
        }
    }
    
    // Jump from usernameField to passwordField to passwordConfirm then hide the keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            passwordConfirmField.becomeFirstResponder()
        } else {
            passwordField.resignFirstResponder()
        }
        return true
    }
    
    // KEEP THIS
    func isValidEmail(testStr:String) -> Bool {
        // False case 1
        if !testStr.contains(".") || !testStr.contains("@") {
            return false
        }
        
        // Final test:
        let emailTest = NSPredicate(format:"SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}")
        for domain in validDomains {
            if testStr.contains(domain) && emailTest.evaluate(with: testStr) {
                return true
            }
        }
        
        print("KYLE: User entered an invalid email address.")
        return emailTest.evaluate(with: testStr)
    }
    
    // Final sign-in step
    func completeSignIn(id: String, userData: Dictionary<String, String>) {
        DataService.ds.createFirebaseDBUser(uid: id, userData: userData)
        let keychainResult = KeychainWrapper.standard.set(id, forKey: KEY_UID)
        print("Kyle: Data saved to keychain: \(keychainResult)")
        
        registerVCEmail = emailField.text
        registerVCPassword = passwordField.text
        
        // Send user a confirmation email
        FIRAuth.auth()?.currentUser?.sendEmailVerification(completion: { (error) in
            // ...
        })
        
        performSegue(withIdentifier: "register2Segue", sender: nil)
    }
    
    // This function is required for Facebook Auth (Use for any Facebook sign-in button)
    @IBAction func FBButtonTapped(_ sender: Any) {
        let facebookLogin = FBSDKLoginManager()
        facebookLogin.logIn(withReadPermissions: ["email"], from: self) { (result, error) in
            if error != nil {
                print("Kyle: unable to authenticate with Facebook.")
            } else if result?.isCancelled == true {
                print("Kyle: User cancelled Facebook Authentication.")
            } else {
                print("Kyle: Successfully authenticated with Facebook.")
                let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                self.firebaseAuth(credential)
            }
        }
    }
    
    // This function is required for Firebase Auth
    func firebaseAuth(_ credential: FIRAuthCredential) {
        FIRAuth.auth()?.signIn(with: credential, completion: { (user, error) in
            if error != nil {
                print("Kyle: Unable to authenticate with Firebase. - \(error!)")
            } else {
                print("Kyle: Successfully authenticated with Firebase.")
                if let user = user {
                    let userData = ["provider" : credential.provider]
                    self.completeSignIn(id: (user.uid), userData: userData)
                }
            }
        })
    }
    
    // Function for Email Authentication
    @IBAction func registerTapped(_ sender: Any) {
        if let email = emailField.text, let pwd = passwordField.text {
            FIRAuth.auth()?.signIn(withEmail: email, password: pwd, completion: { (user, error) in
                if error == nil {
                    // TELL THE USER THAT THE EMAIL IS TAKEN
                    print("KYLE: The user already exists.")
                } else {
                    //  CREATE NEW USER IF THE USER DID NOT EXIST
                    if self.passwordField.text == self.passwordConfirmField.text && !(self.passwordField.text == "" || self.passwordField.text == nil) {
                        FIRAuth.auth()?.createUser(withEmail: email, password: pwd, completion: { (user, error) in
                            if error != nil {
                                print("Kyle: Unable to authenticate with Firebase using email.")
                            } else {
                                print("Kyle: Successfully   authenticated with Firebase.")
                                if let user = user {
                                    let userData = ["provider" : user.providerID ]
                                    self.completeSignIn(id: (user.uid), userData: userData)
                                }
                            }
                        })
                    } else {
                        // THE PASSWORDS DO NOT MATCH
                        print("KYLE: The passwords do not match.")
                    }
                }
            })
        }
    }
    
    @IBAction func backgroundTapped(_ sender: Any) {
        view.endEditing(true)
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        passwordConfirmField.resignFirstResponder()
    }
}
