//
//  FirstViewController.swift
//  SleepHR
//
//  Created by Yanxin Yin on 4/21/18.
//  Copyright © 2018 Yanxin Yin. All rights reserved.
//

import UIKit
import HealthKit

extension Date {
    var millisecondsSince1970:Int {
        return Int((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    init(milliseconds:Int) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds / 1000))
    }
}

extension UserDefaults {
    func contains(key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }
}

class FirstViewController: UIViewController, FBSDKLoginButtonDelegate {
    
    let loginButton: FBSDKLoginButton = {
        let button = FBSDKLoginButton()
        button.readPermissions = ["email"]
        return button
    }()
        
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        print("completed login")
    }
    
    func loginButtonWillLogin(_ loginButton: FBSDKLoginButton!) -> Bool {
        return true
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        
    }

    let healthStore = HKHealthStore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.addSubview(loginButton)
        loginButton.center = CGPoint(x: view.center.x, y: 570)
        loginButton.delegate = self
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
        print("fetch profile")
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
    @IBAction func goToHealth(_ sender: Any) {
        UIApplication.shared.open(URL(string:"x-apple-health://app/sleep/")!, options: [:], completionHandler: nil)
    }
    
    @IBAction func saveSleepTime(_ sender: Any) {
        
        saveSleepAnalysis()
        
        if(FBSDKAccessToken.current() != nil){
            let timeToSleep = UserDefaults.standard.object(forKey: "sleepTime") as! Date
            let timeToWake = UserDefaults.standard.object(forKey: "wakeTime") as! Date
            UserDefaults.standard.removeObject(forKey: "sleepTime")
            UserDefaults.standard.removeObject(forKey: "wakeTime")
            let urlString = "https://sleephr.herokuapp.com/survey?_id=\(UserDefaults.standard.object(forKey: "myFBID") as! String)&timeToSleep=\(timeToSleep.millisecondsSince1970)&timeToWake=\(timeToWake.millisecondsSince1970)"

            let alert = UIAlertController(title: "Almost there", message: "Ready to save! Please first finish a 10-sec self-report survey honestly!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {(action:UIAlertAction!) -> Void in
                UIApplication.shared.open(URL(string: urlString)!, options: [:], completionHandler: nil)
            }))
            self.present(alert, animated: true)
        }else{
            let alertLogin = UIAlertController(title: "Error", message: "Your data has been saved into iOS Health. Please Log in with Facebook account to enable more functions!", preferredStyle: .alert)
            alertLogin.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: nil))
            self.present(alertLogin, animated: true)
        }
    }
    
    @IBAction func getSleepAnalysis(_ sender: Any) {
        
        if HKHealthStore.isHealthDataAvailable() {
            let sleepType = Set([HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!])
            
            healthStore.requestAuthorization(toShare: sleepType, read: sleepType) { (success, error) in
                if !success {
                    let alert = UIAlertController(title: "Error!", message: "Fail to get authorization", preferredStyle: .alert)
                    
                    alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: nil))
                    alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                    
                    self.present(alert, animated: true)
                }else{
                    let alert = UIAlertController(title: "Success!", message: "Get authorization!", preferredStyle: .alert)
                    
                    alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: nil))
                    alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                    
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    @IBAction func trackSleep(_ sender: Any) {
        UserDefaults.standard.set(Date.init(), forKey: "sleepTime")
    }
    
    @IBAction func trackAwake(_ sender: Any) {
         UserDefaults.standard.set(Date.init(), forKey: "wakeTime")
    }
    
    func retrieveSleepAnalysis() {
        if let sleepType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis) {
        
            // Use a sortDescriptor to get the recent data first
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            
            let calendar = Calendar.current
            let now = Date()
            let components = calendar.dateComponents([.year, .month, .day], from: now)
            var startDate = calendar.date(from: components)
            startDate = calendar.date(byAdding: .day, value: -1, to: startDate!)
            startDate = calendar.date(byAdding: .hour, value: -6, to: startDate!)
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
            
            // we create our query with a block completion to execute
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [sortDescriptor]) { (query, tmpResult, error) -> Void in
                if error != nil {
                    print("HKSampleQuery Error")
                    return
                }
                
                if let result = tmpResult {
                    // do something with my data
                    let userdefaults = UserDefaults.standard
                    if(result.last != nil){
                        if(userdefaults.contains(key: "sleepTime")){
                            let timeToSleep = max((result.last!.startDate) , UserDefaults.standard.object(forKey: "sleepTime") as! Date)
                            UserDefaults.standard.set(timeToSleep, forKey: "sleepTime")
                        }else{
                            UserDefaults.standard.set((result.last!.startDate) , forKey: "sleepTime")
                        }
                    }
                    
                    if(result.first != nil){
                        if(userdefaults.contains(key: "wakeTime")){
                            let timeToWake = min((result.first!.endDate) , UserDefaults.standard.object(forKey: "wakeTime") as! Date)
                            UserDefaults.standard.set(timeToWake, forKey: "wakeTime")
                        }else{
                            UserDefaults.standard.set((result.first!.endDate) , forKey: "wakeTime")
                        }
                    }
                }
            }
            healthStore.execute(query)
        }
    }
    
    func saveSleepAnalysis() {
        
        // make combine estimation
        retrieveSleepAnalysis()

        let userdefaults = UserDefaults.standard
        if(!userdefaults.contains(key: "sleepTime")){
            /// no record
            let alert = UIAlertController(title: "Error", message: "No self-reported or automatically recorded data for time to sleep!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            return
        }
        if(!userdefaults.contains(key: "wakeTime")){
            let alert = UIAlertController(title: "Error", message: "No self-reported or automatically recorded data for time to wake up!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            return
        }
        
        /// push in Health app
        if let sleepType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis) {
            /// use asleep value to distinguish from HKCategoryValueSleepAnalysis.inBed.rawValue
            
            let object = HKCategorySample(type:sleepType, value: HKCategoryValueSleepAnalysis.asleep.rawValue, start: UserDefaults.standard.object(forKey: "sleepTime") as! Date, end: UserDefaults.standard.object(forKey: "wakeTime") as! Date)

            healthStore.save(object, withCompletion: { (success, error) -> Void in
                if error != nil {
                    let alert = UIAlertController(title: "Error", message: "Cannot push data into Apple HealthKit!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: nil))
                    self.present(alert, animated: true)
                    return
                }
                
                if success {
                    print("saved in HealthKit")
                } else {
                    let alert = UIAlertController(title: "Error", message: "Cannot push data into Apple HealthKit!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: nil))
                    self.present(alert, animated: true)
                    return
                }
            })
        }
    }
}

