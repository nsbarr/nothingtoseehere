//
//  UserObject.swift
//  devdactic-rest
//
//  Created by Simon Reimler on 05/02/16.
//  Copyright © 2016 devdactic. All rights reserved.
//

import SwiftyJSON

class UserObject {
    var pictureURL: String!
    var username: String!
    
    required init(json: JSON) {
        pictureURL = json["lists"]["id"].stringValue
        username = json["lists"]["name"].stringValue
    }
}