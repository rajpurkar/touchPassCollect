//
//  ViewController.swift
//  touchPass
//
//  Created by Pranav Rajpurkar on 11/29/15.
//  Copyright © 2015 psr. All rights reserved.
//


import CoreMotion
import UIKit


let simulate = false
let host = "http://171.64.70.117:3000"
let route = "/trainFromPhone"

class ViewController: UIViewController {
    let motionManager: CMMotionManager = CMMotionManager()
    var timer1       = NSTimer()
    var dataArray:[(Int!, Double)] = []
   
    @IBAction func tap(sender: UIButton) {
        let tapInt: Int! = Int(sender.titleLabel!.text!)
        self.dataArray += [(tapInt, NSDate().timeIntervalSince1970 * 1000.00)]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        timer1 = NSTimer(timeInterval: 1.0, target: self, selector: "sendData", userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(timer1, forMode: NSRunLoopCommonModes)
    }
    
    func sendData() {
        if (dataArray.count > 0) {
            let request = NSMutableURLRequest(URL: NSURL(string: host + route)!)
            request.HTTPMethod = "POST"
            let postString:String = "data=" + dataArray.description
            dataArray = []
            request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
            let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
                data, response, error in
                if error != nil {
                    print("error=\(error)")
                    return
                }
            }
            task.resume()
        }
    }
}

