//
//  ViewController.swift
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
var isSignedInAsWingman: Bool = false
var loginVCEmail: String!
var loginVCPassword: String!
var authenticatedWithFacebook = false
var authenticatedWithEmail = false

class LoginVC: UIViewController, UITextFieldDelegate {
    // Outlets
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    // Variables
    var ref: FIRDatabaseReference!
    var userRequiresUsername = false
    
    override func viewDidAppear(_ animated: Bool) {
        emailField.delegate = self
        passwordField.delegate = self
        
        // Keyboard observers DO NOT EDIT
        NotificationCenter.default.addObserver(self, selector: #selector(RegisterVC.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(RegisterVC.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func completeSignIn(id: String, userData: Dictionary<String, String>) {
        DataService.ds.createFirebaseDBUser(uid: id, userData: userData)
        let keychainResult = KeychainWrapper.standard.set(id, forKey: KEY_UID)
        print("KYLE: Data saved to keychain: \(keychainResult)")
        
        // All of this is required to check if user has set a username on the CreateAccountVC.
        FIRDatabase.database().reference().child("users").child(FIRAuth.auth()!.currentUser!.uid).observeSingleEvent(of: .value, with: { (snapshot) in
            for rest in snapshot.children.allObjects as! [FIRDataSnapshot] {
                if rest.key.contains("display-name") {
                    print("KYLE: User has previously set a display-name.")
                    self.performSegue(withIdentifier: "bypassSegue1", sender: nil)
                }
            }
            self.userRequiresUsername = true
        }) {(error) in
            print(error.localizedDescription)
        }
        
        if userRequiresUsername {
            self.performSegue(withIdentifier: "regularSignInSegue", sender: nil)
        }
    }
    
    // This code is required for Facebook Auth (Use for any "sign in with facebook" button
    @IBAction func FBButtonTapped(_ sender: Any) {
        let facebookLogin = FBSDKLoginManager()
        facebookLogin.logIn(withReadPermissions: ["email"], from: self) { (result, error) in
            if error != nil {
                print("KYLE: unable to authenticate with Facebook.")
            } else if result?.isCancelled == true {
                print("KYLE: User cancelled Facebook Authentication.")
            } else {
                print("KYLE: Successfully authenticated with Facebook.")
                authenticatedWithFacebook = true
                authenticatedWithEmail = false
                let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                self.firebaseAuth(credential)
            }
        }
    }
    
    // This function is also required for Firebase Auth
    func firebaseAuth(_ credential: FIRAuthCredential) {
        FIRAuth.auth()?.signIn(with: credential, completion: { (user, error) in
            if error != nil {
                print("KYLE: Unable to authenticate with Firebase. - \(error!)")
            } else {
                print("KYLE: Successfully authenticated with Firebase.")
                if let user = user {
                    let userData = ["provider" : credential.provider]
                    self.completeSignIn(id: (user.uid), userData: userData)
                }
            }
        })
    }
    
    // Function used for Email Authentication
    @IBAction func signInTapped(_ sender: Any) {
        if let email = emailField.text, let pwd = passwordField.text {
            FIRAuth.auth()?.signIn(withEmail: email, password: pwd, completion: { (user, error) in
                if error == nil {
                    print("KYLE: User signed in with Firebase.")
                    authenticatedWithEmail = true
                    authenticatedWithFacebook = false
                    loginVCEmail = email
                    loginVCPassword = pwd
                    if let user = user {
                        let userData = ["provider" : user.providerID]
                        self.completeSignIn(id: (user.uid), userData: userData)
                    }
                } else {
                    // TELL THE USER THEY ENTERED THE WRONG INFO
                    print("KYLE: The user does not exist")
                }
            })
        }
    }
    
    @IBAction func createNewAccount(_ sender: Any) {
        // Save email globally for RegisterVC
        loginVCEmail = emailField.text
        
        performSegue(withIdentifier: "Register Segue", sender: nil) // Go to register screen
    }
    
    @IBAction func backgroundTapped(_ sender: Any) {
        view.endEditing(true)
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
    }
    
    
    
    
    
    
    /*
        Boring functions for keyboard, background press, view animations, etc.
    */
    
    // Keyboard functions to move the entire screen when the keyboard is active
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
    
    // Jump from textfield 1 to 2 to 3 then hide the keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else {
            passwordField.resignFirstResponder()
        }
        return true
    }
    
    // Check if the email follows expected email syntax
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
}
