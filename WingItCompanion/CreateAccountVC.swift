//
//  CreateAccountVC.swift
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

class CreateAccountVC: UIViewController {
    
    // Outlets
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var locationField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var websiteField: UITextField!
    
    // Variables
    var newUser: [String: String?] = [:]
    
    // Constants
    let ref = FIRDatabase.database().reference().child("users")
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func segueIsValid() -> Bool {
        if nameField.text == "" || locationField.text == "" {
            return false
        }
        return true
    }
    
    @IBAction func goButtonPressed(_ sender: Any) {
        if segueIsValid() {
            if authenticatedWithFacebook {
                if FIRAuth.auth()?.currentUser != nil { // Confirm that user is signed in
                    let user = FIRAuth.auth()?.currentUser
                    
                    // Create new data to be added to existing user
                    newUser = [
                        "provider": "facebook.com",
                        "display-name": self.nameField.text,
                        "location": self.locationField.text,
                        
                        // Optional data
                        "contact-email": self.emailField.text,
                        "contact-phone": self.phoneField.text,
                        "contact-website": self.websiteField.text
                    ]
                    
                    ref.child((user?.uid)!).setValue(newUser)   // Updates existing user with new data
                    
                    // Test code in order to ensure username was updated. Non-vital code.
                    let userID = user?.uid
                    ref.child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in
                        // Get user value
                        let value = snapshot.value as? NSDictionary
                        let username = value?["display-name"] as? String ?? ""
                        print("Username: \(username)")
                    }) { (error) in
                        print("KYLE: Error - \(error.localizedDescription)")
                    }
                    
                } else {
                    print("The user is nil")
                }
            }
                
            else if authenticatedWithEmail {
                if registerVCEmail != "" && registerVCPassword != nil {    // If user logged in through Login page
                    FIRAuth.auth()?.signIn(withEmail: registerVCEmail, password: registerVCPassword, completion: { (user, error) in
                        if error != nil {
                            // Something went wrong. :(
                        } else {
                            let newUser = [
                                // Required data
                                "provider": user?.providerID,
                                "display-name": self.nameField.text,
                                "location": self.locationField.text,
                                
                                // Optional data
                                "contact-email": self.emailField.text,
                                "contact-phone": self.phoneField.text,
                                "contact-website": self.websiteField.text
                            ]
                            self.ref.child((user?.uid)!).setValue(newUser)
                        }
                    })
                } else {  // If user logged in through register page
                    // NOTE: IN THEORY THIS CASE SHOULD NEVER OCCUR. USER SHOULD ALWAYS REGISTER THROUGH REGISTERVC WITH A USERNAME.
                    FIRAuth.auth()?.signIn(withEmail: loginVCEmail, password: loginVCPassword, completion: { (user, error) in
                        if error != nil {
                            // Something went wrong. :(
                        } else {
                            let newUser = [
                                // Required data
                                "provider": user?.providerID,
                                "display-name": self.nameField.text,
                                "location": self.locationField.text,
                                
                                // Optional data
                                "contact-email": self.emailField.text,
                                "contact-phone": self.phoneField.text,
                                "contact-website": self.websiteField.text
                            ]
                            self.ref.child((user?.uid)!).setValue(newUser)
                        }
                    })
                }
            }
            performSegue(withIdentifier: "registerSignInSegue", sender: nil)
        } else {
            print("KYLE: User must enter their name and location")
        }
    }
    
    @IBAction func backgroundTapped(_ sender: Any) {
        view.endEditing(true)
        nameField.resignFirstResponder()
        locationField.resignFirstResponder()
        emailField.resignFirstResponder()
        phoneField.resignFirstResponder()
        websiteField.resignFirstResponder()
    }
    
}
