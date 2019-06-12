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

class CreateAccountVC: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    // Outlets
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var locationField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var websiteField: UITextField!
    @IBOutlet weak var jobTitleField: UITextField!
    @IBOutlet weak var userProfileImg: CircleImage!
    
    // Variables
    var newUserData: [String: String?] = [:]
    var imageSelected = false
    var imagePicker: UIImagePickerController!
    var userImageUrl: String!
    static var imageCache: NSCache<NSString, UIImage> = NSCache() // Not used yet
    
    // Constants
    let ref = FIRDatabase.database().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true    // Allow user to move picture around and crop
        imagePicker.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        nameField.delegate = self
        locationField.delegate = self
        emailField.delegate = self
        phoneField.delegate = self
        websiteField.delegate = self
        jobTitleField.delegate = self
        
        // Keyboard observers
        NotificationCenter.default.addObserver(self, selector: #selector(CreateAccountVC.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CreateAccountVC.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    // Keyboard view-moving functions
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height * 0.7
            }
        }
    }
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += keyboardSize.height * 0.7
            }
        }
    }
    
    // Jump from usernameField to passwordField to passwordConfirm then hide the keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameField {
            locationField.becomeFirstResponder()
        } else if textField == locationField {
            jobTitleField.becomeFirstResponder()
        } else if textField == jobTitleField {
            emailField.becomeFirstResponder()
        } else if textField == emailField {
            phoneField.becomeFirstResponder()
        }
        else {
            nameField.resignFirstResponder()
            locationField.resignFirstResponder()
            emailField.resignFirstResponder()
            phoneField.resignFirstResponder()
            websiteField.resignFirstResponder()
            jobTitleField.resignFirstResponder()
        }
        return true
    }
    
    func segueIsValid() -> Bool {
        if nameField.text == "" || locationField.text == "" {
            return false
        }
        return true
    }
    
    @IBAction func goButtonPressed(_ sender: Any) {
        print("KYLE: Go button pressed")
        
        // Print an error if the image is nil or if an image was not selected
        guard let img = userProfileImg.image, imageSelected == true else {
            print("KYLE: An image must be selected")
            return
        }
        
        // Convert image to imageData and compress to 20% quality
        if let imgData = UIImageJPEGRepresentation(img, 0.2) {
            let imgUid = NSUUID().uuidString
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"
            
            DataService.ds.REF_PROFILE_IMAGES.child(imgUid).put(imgData, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print("KYLE: Unable to upload image to Firebase storage")
                } else {
                    print("KYLE: Successfully uploaded image to Firebase storage")
                    let downloadURL = metadata?.downloadURL()?.absoluteString
                    if let url = downloadURL {
                        self.userImageUrl = url
                        self.updateDatabase()
                    }
                }
            }
        }
    }
    
    // This function receives the user's input text to update the Firebase text. Also stores the profile image URL once it has been uploaded.
    func updateDatabase() {
        if segueIsValid() {
            if authenticatedWithFacebook {
                if let user = FIRAuth.auth()?.currentUser { // Confirm that user is signed in
                    newUserData = [
                        // Required data
                        "provider": "facebook.com",
                        "display-name": self.nameField.text,
                        "location": self.locationField.text,
                        "job-title": self.jobTitleField.text,
                        "img-url": self.userImageUrl,
                        
                        // Optional data
                        "contact-email": self.emailField.text,
                        "contact-phone": self.phoneField.text,
                        "contact-website": self.websiteField.text
                    ]
                    
                    ref.child("users").child((user.uid)).setValue(newUserData)   // Updates existing user with new data
                    ref.child("wingmen").child((user.uid)).setValue(newUserData)
                    
                    // Code used to ensure user data was updated. Non-vital code.
                    let userID = user.uid
                    ref.child("users").child(userID).observeSingleEvent(of: .value, with: { (snapshot) in
                        // Get user value
                        let value = snapshot.value as? NSDictionary
                        let username = value?["display-name"] as? String ?? ""
                    }) { (error) in
                        print("KYLE: Error - \(error.localizedDescription)")
                    }
                } else {
                    print("The user is nil")
                }
            }
                
            else if authenticatedWithEmail {
                if registerVCEmail != "" && registerVCPassword != "" {
                    FIRAuth.auth()?.signIn(withEmail: registerVCEmail, password: registerVCPassword, completion: { (user, error) in
                        if error != nil {
                            // Something went wrong. :(
                        } else {
                            let newUserData = [
                                // Required data
                                "provider": user?.providerID,
                                "display-name": self.nameField.text,
                                "location": self.locationField.text,
                                "job-title": self.jobTitleField.text,
                                "img-url": self.userImageUrl,
                                
                                // Optional data
                                "contact-email": self.emailField.text,
                                "contact-phone": self.phoneField.text,
                                "contact-website": self.websiteField.text
                            ]
                            self.ref.child("users").child((user?.uid)!).setValue(newUserData)
                            self.ref.child("wingmen").child((user?.uid)!).setValue(newUserData) // TEST: This should copy the user to wingmen on completion of account
                        }
                    })
                }
            }
            //            performSegue(withIdentifier: "registerSignInSegue", sender: nil)
        } else {
            print("KYLE: User must enter all required information")
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
    
    @IBAction func profilePicturePressed(_ sender: Any) {
        changeProfilePicture()
    }
    
    @IBAction func profileLabelPressed(_ sender: Any) {
        changeProfilePicture()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            userProfileImg.image = image  // Replaces the image on the "addImage" button with the user's image
            imageSelected = true
        } else {
            print("KYLE: A valid image was not selected.")
        }
        imagePicker.dismiss(animated: true, completion: nil)    // Hide the image picker once the user selects an image
    }
    
    func changeProfilePicture() {
        present(imagePicker, animated: true, completion: nil)
    }
    
}
