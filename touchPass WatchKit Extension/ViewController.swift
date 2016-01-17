//
//  Created by Pranav Rajpurkar on 11/29/15.
//  Copyright © 2015 psr. All rights reserved.
//

import WatchKit
import Foundation
import CoreMotion

let simulate = false
let host = "http://171.64.70.117:3000"

let COLLECTION_INTERVAL = 0.01
var hasSetPassword = false
let REFRESH_RATE = Int(1/(COLLECTION_INTERVAL*10))
let NUM_POSTED_LIMIT = Int(1/COLLECTION_INTERVAL) * 10

func startSensorUpdates(motionManager: CMMotionManager, handler: CMAccelerometerHandler) {
    motionManager.accelerometerUpdateInterval = COLLECTION_INTERVAL
    motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue()!, withHandler: handler)
}

func randomCGFloat() -> CGFloat {
    return CGFloat(Float(arc4random()) / Float(UINT32_MAX))
}

func generateRandomData() -> (Double, Double, Double){
    let x = Double(randomCGFloat())
    let y = Double(randomCGFloat())
    let z = Double(randomCGFloat())
    return (x, y, z)
}

class collectionController: WKInterfaceController {
    let motionManager: CMMotionManager = CMMotionManager()
    var dataArray: [(Double, Double, Double, Double)] = []
    var responseCount: Int = 0
    var collectionTimer: NSTimer!
    var route: String!
    
    func callback (x:Double, y:Double, z:Double, time:Double) {
        dataArray.append((x, y, z, time))
    }

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        startGettingData()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        stopGettingData()
    }
    
    func getSimulatedAccelerometerData () {
        let time = NSDate().timeIntervalSince1970 * 1000.00
        let (x, y, z) = generateRandomData()
        self.callback(x, y: y, z: z, time: time)
    }
    
    func startGettingData () {
        if (simulate) {
            self.collectionTimer = NSTimer(timeInterval: COLLECTION_INTERVAL, target: self, selector: "getSimulatedAccelerometerData", userInfo: nil, repeats: true)
            NSRunLoop.currentRunLoop().addTimer(self.collectionTimer, forMode: NSRunLoopCommonModes)
            
        } else {
            let handler:CMAccelerometerHandler = {(data: CMAccelerometerData?, error: NSError?) -> Void in
                let currentDate = NSDate().timeIntervalSince1970 * 1000.00
                self.callback(data!.acceleration.x, y: data!.acceleration.y, z: data!.acceleration.z, time: currentDate)
            }
            startSensorUpdates(motionManager, handler: handler)
        }
    }
    
    func onResponseReceived (data: String) {
        return
    }
    
    func sendData() -> Int  {
        let request:NSMutableURLRequest
        request = NSMutableURLRequest(URL: NSURL(string: host + self.route)!)
        let postString:String = "data=" + dataArray.description
        var numPosted  = dataArray.count
        if (numPosted > NUM_POSTED_LIMIT){
            numPosted = 0
        }
        dataArray = []
        if(numPosted > 0) {
            request.HTTPMethod = "POST"
            request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
            let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
                data, response, error in
                if error != nil {
                    print("error=\(error)")
                    self.onResponseReceived("Error")
                } else {
                    self.onResponseReceived(NSString(data: data!, encoding: NSUTF8StringEncoding)! as String)
                }
            }
            task.resume()
        }
        return numPosted
    }
    
    func stopGettingData () {
        if (simulate) {
            self.collectionTimer.invalidate()
        } else {
            self.motionManager.stopAccelerometerUpdates()
        }
    }
}

class testController: collectionController {
    @IBOutlet var labelX: WKInterfaceLabel!
    @IBOutlet var labelY: WKInterfaceLabel!
    @IBOutlet var labelZ: WKInterfaceLabel!
    
    @IBAction func buttonPressed() {
        stopGettingData()
        let numCount = sendData()
        self.labelX.setText("Sent")
        self.labelY.setText(String(Double(numCount) * COLLECTION_INTERVAL))
        self.labelZ.setText("sec")
    }
    
    override func onResponseReceived(data: String) {
        self.labelX.setText("Send")
        self.labelY.setText(data)
        self.labelZ.setText("")
    }
    
    override func callback(x: Double, y: Double, z: Double, time: Double) {
        super.callback(x, y: y, z: z, time: time)
        if (hasSetPassword == false){
            self.labelX.setText(String("Not set password"))
            self.labelY.setText("")
            self.labelZ.setText("")
        } else {
            if (self.responseCount++ % REFRESH_RATE  == 0){
                self.labelX.setText(String(format: "%.2f", x))
                self.labelY.setText(String(format: "%.2f", y))
                self.labelZ.setText(String(format: "%.2f", z))
                self.responseCount = 1
            }
        }
    }
    
    override init() {
        super.init()
        self.route = "/verifyPassword"
    }
}

class setController: collectionController {
    @IBOutlet var labelX: WKInterfaceLabel!
    @IBOutlet var labelY: WKInterfaceLabel!
    @IBOutlet var labelZ: WKInterfaceLabel!
    
    @IBAction func buttonPressed() {
        stopGettingData()
        let numCount = sendData()
        self.labelX.setText("Sent")
        self.labelY.setText(String(Double(numCount) * COLLECTION_INTERVAL))
        self.labelZ.setText("sec")
    }
    
    override func onResponseReceived(data: String) {
        self.labelX.setText("Send")
        self.labelY.setText(data)
        self.labelZ.setText("")
    }
    
    override func callback(x: Double, y: Double, z: Double, time: Double) {
        super.callback(x, y: y, z: z, time: time)
        if (self.responseCount++ % REFRESH_RATE  == 0){
            self.labelX.setText(String(format: "%.2f", x))
            self.labelY.setText(String(format: "%.2f", y))
            self.labelZ.setText(String(format: "%.2f", z))
            self.responseCount = 1
        }
    }
    
    override init() {
        super.init()
        hasSetPassword = true
        self.route = "/setPassword"
    }
}

class trainController: collectionController {
    @IBOutlet var labelX: WKInterfaceLabel!
    @IBOutlet var labelY: WKInterfaceLabel!
    @IBOutlet var labelZ: WKInterfaceLabel!
    @IBOutlet var numTrainedPasswordsLabel: WKInterfaceLabel!
    var numTrainedPasswords = 0
    
    func updateNumTrainedPasswords(numCount: Int) {
        if (numCount > 0) {
            self.numTrainedPasswords++
        }
        self.numTrainedPasswordsLabel.setText(numTrainedPasswords.description)
    }
    
    @IBAction func buttonPressed() {
        stopGettingData()
        let numCount = sendData()
        updateNumTrainedPasswords(numCount)
        self.labelX.setText("Sent")
        self.labelY.setText(String(Double(numCount) * COLLECTION_INTERVAL))
        self.labelZ.setText("sec")
        startGettingData()
    }
    
    override func callback(x: Double, y: Double, z: Double, time: Double) {
        super.callback(x, y: y, z: z, time: time)
        if (self.responseCount++ % REFRESH_RATE  == 0){
            self.labelX.setText(String(format: "%.2f", x))
            self.labelY.setText(String(format: "%.2f", y))
            self.labelZ.setText(String(format: "%.2f", z))
            self.responseCount = 1
        }
    }
    
    override init() {
        super.init()
        self.route = "/trainFromWatch"
    }
    
}


class mainController: WKInterfaceController {

}
