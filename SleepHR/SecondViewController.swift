//
//  SecondViewController.swift
//  SleepHR
//
//  Created by Yanxin Yin on 4/21/18.
//  Copyright © 2018 Yanxin Yin. All rights reserved.
//

import UIKit
import WebKit

class SecondViewController: UIViewController, FBSDKLoginButtonDelegate, WKNavigationDelegate {
    
    var webView: WKWebView!
    
    @IBOutlet var UIView: UIView!
    
    let loginButton: FBSDKLoginButton = {
        let button = FBSDKLoginButton()
        button.readPermissions = ["email"]
        return button
    }()
    
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
        ///  setting the web view's navigationDelegate property to self, which means "when any web page navigation happens, please tell me."
        webView.navigationDelegate = self
        let myURL = URL(string:"https://sleephr.herokuapp.com")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
        webView.allowsBackForwardNavigationGestures = true
        UIView.addSubview(webView)
        constrainView(view: webView, toView: UIView)
        // Do any additional setup after loading the view, typically from a nib.
        view.addSubview(loginButton)
//        loginButton.center = view.center
        loginButton.center = CGPoint(x: view.center.x, y: 400)
        loginButton.delegate = self
    
        if(FBSDKAccessToken.current() != nil){
            fetchProfile()
        }
    }
    
    func fetchProfile(){
        print("fetch profile")
        
//        let params = ["fields": "id, first_name, last_name, name, email, picture"]
//        let parameters = ["fields": "id, name, email, first_name, last_name, picture.type(large)"]
        
        FBSDKGraphRequest(graphPath: "me", parameters: ["fields" : "id, name"]).start {(connection, result, error) -> Void in
            if error != nil{
                print(error)
                return
            }
            if let userInfo = result as? [String: Any] {
                UserDefaults.standard.set(userInfo["id"] as? String, forKey: "myFBID")
                UserDefaults.standard.set(userInfo["name"] as? String, forKey: "myName")
            }
        }
        FBSDKGraphRequest(graphPath: "me/friends", parameters: ["fields": "id"]).start {(connection, result, error) -> Void in
            if error != nil{
                print(error)
                return
            }
            if let userInfo = result as? [String: Any] {
                print(userInfo)
                let total_count = userInfo["summary"] as! Int
                let friend_list = userInfo["data"] as! [NSDictionary]
                var id_list: [String] = []
                id_list.append(UserDefaults.standard.object(forKey: "myFBID") as! String)
                
                for friend in friend_list {
                    id_list.append(friend["id"] as! String)
                }
                
                UserDefaults.standard.set(id_list, forKey: "id_list")
            }
        }
    }

    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        print("completed login")
    }
    
    func loginButtonWillLogin(_ loginButton: FBSDKLoginButton!) -> Bool {
        return true
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func scoreboard(_ sender: Any) {
        let id_list = UserDefaults.standard.stringArray(forKey: "id_list") ?? [String]()
        let myURL = URL(string:"https://sleephr.herokuapp.com")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
    }
    
    @IBAction func report(_ sender: Any) {
        let myURL = URL(string: "https://sleephr.herokuapp.com/report?_id=\(UserDefaults.standard.object(forKey: "myFBID") as! String)&analysisRange=\(10)")
//        print(UserDefaults.standard.object(forKey: "myFBID") as! String)
        var myRequest = URLRequest(url: myURL!)
        myRequest.httpMethod = "GET"
        webView.load(myRequest)
    }
}

