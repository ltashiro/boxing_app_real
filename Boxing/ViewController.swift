//
//  ViewController.swift
//  Boxing
//
//  Created by Lilian Tashiro on 1/14/18.
//  Copyright © 2018 Apple, Inc. All rights reserved.
//


//vibration
//
//gif functions


import UIKit
import CoreMotion
import AVFoundation
import AudioToolbox

//AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);


class ViewController: UIViewController {
    
    @IBOutlet weak var gifView: UIImageView!
    var motionManager : CMMotionManager?
    var backGroundPlayer = AVAudioPlayer()
    var backGroundPlayer1 = AVAudioPlayer()
    let opQueue = OperationQueue()
    var health = 100
    var isFighting=false
    var a_xs:[Double]=[]
    var isPunching=false
    var attitudeStart:[Double]=[]
    var attitudeEnd:[Double]=[]
    var attitudeRest:[Double]=[]
    
    @IBOutlet weak var ReadyToFightLabel: UILabel!
    
    @IBOutlet weak var buttonPressed: UIButton!
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        health = 100
        if(!isFighting){
            isFighting=true
            buttonPressed.setTitle("Stop",for:.normal)
            backGroundPlayer.play()
            ReadyToFightLabel.text = "FIGHT!"
            fight()
        }else{
            isFighting=false
            buttonPressed.setTitle("Push to Start",for:.normal)
            if let manager = motionManager {
                print ("stopping motion manager")
                if manager.isDeviceMotionAvailable && manager.isAccelerometerAvailable {
                    print("stopping motion and accel")
                    manager.stopDeviceMotionUpdates()
                    manager.stopAccelerometerUpdates()
                }
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let fileManager = FileManager.default
        if let tDocumentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath =  tDocumentDirectory.appendingPathComponent("\("test")")
            if !fileManager.fileExists(atPath: filePath.path) {
                do {
                    try fileManager.createDirectory(atPath: filePath.path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                   print("Couldn't create document directory")
                }
            }
            print("Document directory is \(filePath)")
        }
        
        
        
        gifView.loadGif(name: "giphy-tumblr")
        do{
            backGroundPlayer = try AVAudioPlayer(contentsOf: URL.init(fileURLWithPath: Bundle.main.path(forResource: "MommaSayKnockYouOut", ofType: "mp3")!))
            backGroundPlayer.prepareToPlay()
            backGroundPlayer.numberOfLoops = -1
            
            let audioSession = AVAudioSession.sharedInstance()
            do{
                try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            }
            catch{
            }
        }
        catch {
            print(error)
        }
        motionManager = CMMotionManager()
    }
    func fight(){
        if let manager = motionManager {
            print ("we are in motion manager")
            if manager.isDeviceMotionAvailable && manager.isAccelerometerAvailable {
                print("we have motion and accel")
                
                let myQ = OperationQueue()
                
                manager.deviceMotionUpdateInterval =  0.01
                motionManager?.accelerometerUpdateInterval = 0.01
                
                manager.startDeviceMotionUpdates(to: myQ, withHandler: { (data: CMDeviceMotion?, error: Error?) in
                    if let mydata = data {
                        let attitude = mydata.attitude
//                        print (attitude)
                        if self.attitudeRest.count<3{
                            self.attitudeRest=[attitude.pitch,attitude.roll,attitude.yaw]
                        }
                        if let myAccelData = data
                        {
                            let xMotion = myAccelData.userAcceleration.x
                            if xMotion < -0.6 && self.isPunching == true {
                                self.isPunching=false
                                var damage:Double=0
                                for a_x in self.a_xs {
                                    if a_x > 0 {
                                        damage += a_x
                                        
                                    }
                                }
//                                damage = damage/5
                                self.attitudeEnd=[attitude.pitch,attitude.roll,attitude.yaw]
                                let damageType = self.analyzePunch()
                                DispatchQueue.main.async { // Correct
//                                    self.ReadyToFightLabel.text = "Keep fighting- above 75%"
                                    self.buttonPressed.setTitle(damageType+"!!! -\(Int(damage))",for:.normal)
                                }
                                self.dealDamage(damage: damage)
                                print("Punch finished, damage \(damage), length \(self.a_xs.count)",damageType)
                                self.a_xs=[]
                                print("finished attitude:\(attitude)")
//                                self.ReadyToFightLabel.text=damageType
 AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                            } else if xMotion > 0.1 && self.isPunching==false{
                                
                                self.attitudeStart=[attitude.pitch,attitude.roll,attitude.yaw]
                                print("Punch started")
                                print("start attitude:\(attitude.pitch)")

                                self.isPunching=true
                            }
                            
                            if self.a_xs.count>50 {
                                self.a_xs=[]
                                self.isPunching=false
                                print("punch reset")
                                self.attitudeRest=[attitude.pitch,attitude.roll,attitude.yaw]

                            } else if self.isPunching == true {
                                self.a_xs.append(xMotion)
                            }
                        }
                    }
                    
                    if let myerror = error {
                        print("myerror", myerror)
                        manager.stopDeviceMotionUpdates()
                        manager.stopAccelerometerUpdates()
                    }
                })
            }
            else {
                print("Cannot detect device motion")
            }
        }
        else {
            print("We do not have a motion manager.")
        }
    }
    func analyzePunch()->String{
        var punchType="Jab"
        print(abs(attitudeRest[0]-attitudeEnd[0]),abs(attitudeRest[1]-attitudeEnd[1]),abs(attitudeRest[2]-attitudeEnd[2]))
        if degrees(abs(attitudeRest[2]-attitudeEnd[2]))>50 && degrees(abs(attitudeRest[2]-attitudeEnd[2])) < 130 {
            punchType="Hook"
        }else if degrees(abs(attitudeRest[1]-attitudeEnd[1]))>50 && degrees(abs(attitudeRest[1]-attitudeEnd[1])) < 130 {
            punchType="Upper Cut"
        }
        return punchType
    }
    func dealDamage(damage:Double){
        self.health -= Int(damage)
        print("\(self.health)")
        self.checkHealth()
    }
    func checkHealth(){
        if self.health > 75 && self.health < 100 {
            DispatchQueue.main.async { // Correct
                self.ReadyToFightLabel.text = "Keep fighting- above 75%"
                self.gifView.loadGif(name: "giphy-1")

            }
            print ("Keep fighting- above 75%")
            
        }
            
        else if self.health > 50 && self.health < 74  {
            print ("Halfway there- at 50%")
            DispatchQueue.main.async { // Correct
                self.ReadyToFightLabel.text = "Halfway there- at 50%"
                self.gifView.loadGif(name: "giphy-2")
            }
//            self.gifView.loadGif(name: "giphy-2")
        }
            
        else if self.health > 25 && self.health < 49 {
            print ("Almost there- at 25%")
            DispatchQueue.main.async { // Correct
                self.ReadyToFightLabel.text = "Almost there- at 25%"
                self.gifView.loadGif(name: "giphy-3")

            }
        }
            
        else if self.health > 1 && self.health < 24 {
            print ("Down goes Frasier-")
            DispatchQueue.main.async { // Correct
                self.ReadyToFightLabel.text = "Down goes Frasier-"
                self.gifView.loadGif(name: "giphy-4")

            }
        }
        
        if self.health <= 0 {
            print("You win!!!!")
            DispatchQueue.main.async { // Correct
                self.ReadyToFightLabel.text = "KNOCKOUT!"
                self.buttonPressed.isHidden = false
                self.buttonPressed.setTitle("Ready To Fight Again?", for: .normal)
                self.gifView.loadGif(name: "giphy-5")
                self.backGroundPlayer.stop()
                                    self.isFighting=false
                                    self.buttonPressed.setTitle("Push to Start",for:.normal)
                                    if let manager = self.motionManager {
                                        print ("stopping motion manager")
                                        if manager.isDeviceMotionAvailable && manager.isAccelerometerAvailable {
                                            print("stopping motion and accel")
                                            manager.stopDeviceMotionUpdates()
                                            manager.stopAccelerometerUpdates()
                                        }
                                    }
                do{
                    self.backGroundPlayer1 = try AVAudioPlayer(contentsOf: URL.init(fileURLWithPath: Bundle.main.path(forResource: "boxing_bell", ofType: "mp3")!))
                    self.backGroundPlayer1.prepareToPlay()
                    self.backGroundPlayer1.play()
//                    self.backGroundPlayer1.stop()
                    //                            self.backGroundPlayer1.numberOfLoops = 0
                    //                            let audioSession = AVAudioSession.sharedInstance()
                    //                            do{
                    //                                try audioSession.setCategory(AVAudioSessionCategoryPlayback)
                    //                            }
                    //                            catch{
                    //                                print("cant see you plpayer1")
                    //                            }

                }
                catch {
                    print(error)
                }
            }
            //                        manager.stopDeviceMotionUpdates()
            //                        manager.stopAccelerometerUpdates()
            
            
        }
    }
    func updateUI(){
        print("it went to the updateUI")
    }
    func degrees(_ radians: Double) -> Double {
        return 180/Double.pi * radians
    }
}

