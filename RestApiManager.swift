//
//  RestApiManager.swift
//  devdactic-rest
//
//  Created by Simon Reimler on 05/02/16.
//  Copyright © 2016 devdactic. All rights reserved.
//

import SwiftyJSON

typealias ServiceResponse = (JSON, NSError?) -> Void

class RestApiManager: NSObject {
    static let sharedInstance = RestApiManager()
    
    let baseURL = "https://itunes.apple.com/us/rss/topgrossingipadapplications/limit=25/json"//"https://api.trello.com/1/lists/4eea4ffc91e31d174600004a?fields=name&cards=open&card_fields=name&key=c2c5eeac5316244f7e1ee51d099e25f0"
    
    func getRandomUser(onCompletion: (JSON) -> Void) {
        let route = baseURL
        makeHTTPGetRequest(route, onCompletion: { json, err in
            onCompletion(json as JSON)
            print("error is \(err)")
        })
    }
    
    //dev key: c2c5eeac5316244f7e1ee51d099e25f0
    //token: ebeb1e6a29edf83fc5ed5b5c423bfe02d0109eec1ed55e9048565a51ec77c281
    //public board id: rq2mYJNn
    //secret: 692a1675ff63e568d2b45b73ca60b53ae39e9000661c915267402098d6b3038b
    
    // MARK: Perform a GET Request
    func makeHTTPGetRequest(path: String, onCompletion: ServiceResponse) {
        let request = NSMutableURLRequest(URL: NSURL(string: path)!)
        
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            print("another error is \(error)")
            if let jsonData = data {
                let json:JSON = JSON(data: jsonData)
                if let userName = json[0]["id"].string {
                    //Now you got your value
                    print("username is \(userName)")
                }
                onCompletion(json, error)
                
            } else {
                onCompletion(nil, error)
                print("fail")
            }
        })
        task.resume()
    }
    
    // MARK: Perform a POST Request
    func makeHTTPPostRequest(path: String, body: [String: AnyObject], onCompletion: ServiceResponse) {
        let request = NSMutableURLRequest(URL: NSURL(string: path)!)
        
        // Set the method to POST
        request.HTTPMethod = "POST"
        
        do {
            // Set the POST body for the request
            let jsonBody = try NSJSONSerialization.dataWithJSONObject(body, options: .PrettyPrinted)
            request.HTTPBody = jsonBody
            let session = NSURLSession.sharedSession()
            
            let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
                if let jsonData = data {
                    let json:JSON = JSON(data: jsonData)
                    onCompletion(json, nil)
                } else {
                    onCompletion(nil, error)
                }
            })
            task.resume()
        } catch {
            // Create your personal error
            onCompletion(nil, nil)
        }
    }
}