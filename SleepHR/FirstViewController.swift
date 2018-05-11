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

class FirstViewController: UIViewController {

    let healthStore = HKHealthStore()
    var timeToSleep = Date()
    var timeToWake = Date()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func goToHealth(_ sender: Any) {
        UIApplication.shared.open(URL(string:"x-apple-health://app/sleep/")!, options: [:], completionHandler: nil)
        //to health app
        //UIApplication.shared.open(URL(string:"x-apple-health://app/")!, options: [:], completionHandler: nil)
    }
    
    @IBAction func saveSleepTime(_ sender: Any) {
        saveSleepAnalysis()
        
    }
    
    @IBAction func getSleepAnalysis(_ sender: Any) {
        
        if HKHealthStore.isHealthDataAvailable() {
            // Add code to use HealthKit here.
            
        }
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
    
    @IBAction func trackSleep(_ sender: Any) {
        UserDefaults.standard.set(Date.init(), forKey: "sleepTime")
    }
    
    @IBAction func trackAwake(_ sender: Any) {
         UserDefaults.standard.set(Date.init(), forKey: "wakeTime")
    }
    
    func retrieveSleepAnalysis() {
        // first, we define the object type we want
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
                    if(result.first != nil){
                        self.timeToSleep = max((result.last?.startDate)!, self.timeToSleep)
                    }
                    if(result.last != nil){
                        self.timeToWake = min((result.first?.endDate)!, self.timeToWake)
                    }
                    
                    for item in result {
                        if let sample = item as? HKCategorySample {
                            let value = (sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue) ? "InBed" : "Asleep"
//                            print("Healthkit sleep: \(sample.startDate.millisecondsSince1970) \(sample.endDate.millisecondsSince1970) - value: \(value)")
                            print("Healthkit sleep: \(sample.startDate) \(sample.endDate) - value: \(value)")
                        }
                    }
                }
            }
            
            // finally, we execute our query
            healthStore.execute(query)
        }
    }
    
    func saveSleepAnalysis() {
        let userdefaults = UserDefaults.standard
        if(userdefaults.contains(key: "sleepTime")){
            timeToSleep = UserDefaults.standard.object(forKey: "sleepTime") as! Date
        }
        if(userdefaults.contains(key: "wakeTime")){
            timeToWake = UserDefaults.standard.object(forKey: "wakeTime") as! Date
        }
        
        // make combine estimation
        retrieveSleepAnalysis()
        
        // alarmTime and endTime are NSDate objects
        if let sleepType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis) {
            
//            // we create our new object we want to push in Health app
//            let object = HKCategorySample(type:sleepType, value: HKCategoryValueSleepAnalysis.inBed.rawValue, start: self.timeToSleep, end: self.timeToWake)
//
//            // at the end, we save it
//            healthStore.save(object, withCompletion: { (success, error) -> Void in
//
//                if error != nil {
//                    // something happened
//                    return
//                }
//
//                if success {
//                    print("My new data was saved in HealthKit")
//
//                } else {
//                    // something happened again
//                }
//
//            })
            
            
            let object2 = HKCategorySample(type:sleepType, value: HKCategoryValueSleepAnalysis.asleep.rawValue, start: timeToSleep, end: timeToWake)
            
            healthStore.save(object2, withCompletion: { (success, error) -> Void in
                if error != nil {
                    // something happened
                    return
                }
                
                if success {
                    print("saved in HealthKit")
                } else {
                    // something happened again
                }
                
            })
            
        }
        let url = URL(string: "https://sleephr.herokuapp.com")
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
       
        NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue.main) {(response, data, error) in
            print(NSString(data: data!, encoding: String.Encoding.utf8.rawValue))
        }
        
        
    }
}

