//
//  SecondViewController.swift
//  SleepHR
//
//  Created by Yanxin Yin on 4/21/18.
//  Copyright © 2018 Yanxin Yin. All rights reserved.
//

import UIKit
import WebKit

class SecondViewController: UIViewController, WKNavigationDelegate {
    
    var webView: WKWebView!
    
    @IBOutlet var UIView: UIView!
    
    func constrainView(view:UIView, toView contentView:UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        view.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView = WKWebView(frame: UIView.frame)
        webView.navigationDelegate = self
        let myURL = URL(string:"https://sleephr.herokuapp.com")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
        webView.allowsBackForwardNavigationGestures = true
        UIView.addSubview(webView)
        constrainView(view: webView, toView: UIView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if(FBSDKAccessToken.current() != nil){
            fetchProfile()
        }else{
            let alert = UIAlertController(title: "Error", message: "Please Log in with Facebook account first!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    func fetchProfile(){
        FBSDKGraphRequest(graphPath: "me", parameters: ["fields" : "id, name"]).start {(connection, result, error) -> Void in
            if error != nil{
                print(error!)
                return
            }
            if let userInfo = result as? [String: Any] {
                UserDefaults.standard.set(userInfo["id"] as? String, forKey: "myFBID")
                UserDefaults.standard.set(userInfo["name"] as? String, forKey: "myName")
            }
        }
        FBSDKGraphRequest(graphPath: "me/friends", parameters: ["fields": "id"]).start {(connection, result, error) -> Void in
            if error != nil{
                print(error!)
                return
            }
            if let userInfo = result as? [String: Any] {
                print(userInfo)
                let friend_list = userInfo["data"] as! [NSDictionary]
                var id_list: [String] = []
                for friend in friend_list {
                    id_list.append(friend["id"] as! String)
                }
                UserDefaults.standard.set(id_list, forKey: "id_list")
                self.updateUserInfo()
            }
        }
    }

    func updateUserInfo(){
        // prepare json data
        let json: [String: Any] = ["_id": UserDefaults.standard.object(forKey: "myFBID") as! String,
                                   "userName": UserDefaults.standard.object(forKey: "myName") as! String,
                                   "friends": UserDefaults.standard.stringArray(forKey: "id_list") as! [String]]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // create post request
        let myURL = URL(string: "https://sleephr.herokuapp.com/api/updateuser")
//        let myURL = URL(string: "https://localhost:5000/api/updateuser")
        //        print(UserDefaults.standard.object(forKey: "myFBID") as! String)
        var myRequest = URLRequest(url: myURL!)
        myRequest.httpMethod = "POST"
        
        // insert json data to the request
        myRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        myRequest.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: myRequest) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
            }
        }
        task.resume()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func scoreboard(_ sender: Any) {
        let myURL = URL(string: "https://sleephr.herokuapp.com/scoreboard?_id=\(UserDefaults.standard.object(forKey: "myFBID") as! String)")
        var myRequest = URLRequest(url: myURL!)
        myRequest.httpMethod = "GET"
        webView.load(myRequest)
    }
    
    @IBAction func report(_ sender: Any) {
        let myURL = URL(string: "https://sleephr.herokuapp.com/report?_id=\(UserDefaults.standard.object(forKey: "myFBID") as! String)&analysisRange=\(10)")
        var myRequest = URLRequest(url: myURL!)
        myRequest.httpMethod = "GET"
        webView.load(myRequest)
    }
}

