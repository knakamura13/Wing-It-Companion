//
//  DataService.swift
//  WingItCompanion
//
//  Created by Kyle Nakamura on 12/31/16.
//  Copyright © 2016 Kyle Nakamura. All rights reserved.
//

import Foundation
import Firebase
import SwiftKeychainWrapper

let DB_BASE = FIRDatabase.database().reference()
let ST_BASE = FIRStorage.storage().reference()

class DataService {
    
    // Global object
    static let ds = DataService()
    
    // DB References
    private var _REF_BASE = DB_BASE
    private var _REF_POSTS = DB_BASE.child("posts")
    private var _REF_USERS = DB_BASE.child("users")
    
    // ST References
    private var _REF_PROFILE_IMAGES = ST_BASE.child("profile-pics")
    
    var REF_BASE: FIRDatabaseReference {
        return _REF_BASE
    }
    
    var REF_POSTS: FIRDatabaseReference {
        return _REF_POSTS
    }
    
    var REF_USERS: FIRDatabaseReference {
        return _REF_USERS
    }
    
    var REF_USER_CURRENT: FIRDatabaseReference {
        let uid = KeychainWrapper.standard.string(forKey: KEY_UID)
        let user = REF_USERS.child(uid!)
        return user
    }
    
    var REF_PROFILE_IMAGES: FIRStorageReference {
        return _REF_PROFILE_IMAGES
    }
    
    func createFirebaseDBUser(uid: String, userData: Dictionary <String, String>) {
        REF_USERS.child(uid).updateChildValues(userData) // Adds data to existing user or creates a new user
    }
}
