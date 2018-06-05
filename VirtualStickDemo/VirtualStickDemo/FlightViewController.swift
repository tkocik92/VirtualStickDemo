//
//  ViewController.swift
//  VirtualStickDemo
//
//  Created by Tom Kocik on 5/15/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import DJISDK
import UIKit

class FlightViewController: UIViewController, DJIFlightControllerDelegate, FlightControlCallback {
    @IBOutlet weak var logTextView: UITextView!
    
    private var loadingAlert: UIAlertController!
    
    private var flightPlanner: FlightPlanner!
    private var flightController: DJIFlightController?
    
    func onCommandSuccess() {
        // Do another command 
    }
    
    func onError(error: Error?) {
        if error != nil {
            self.logTextView.text = self.logTextView.text + "\nFlight Control: " + (error?.localizedDescription)!
        } else {
            self.logTextView.text = self.logTextView.text + "\nUnknown Error has occured"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.flightController = (DJISDKManager.product() as? DJIAircraft)?.flightController
        
        // Change default measurement systems to make the drone easier to control
        self.flightController?.isVirtualStickAdvancedModeEnabled = true
        self.flightController?.rollPitchControlMode = .velocity
        self.flightController?.yawControlMode = .angle
        self.flightController?.rollPitchCoordinateSystem = .body
        self.flightController?.delegate = self
        
        self.flightPlanner = FlightPlanner(flightController: self.flightController!, callback: self)
        
        // Make sure the camera is pointing straight ahead
        DJISDKManager.product()?.gimbal?.rotate(with: DJIGimbalRotation(pitchValue: 0, rollValue: 0, yawValue: 0, time: 1, mode: DJIGimbalRotationMode.absoluteAngle), completion: { (error) in
            if error != nil {
                self.logTextView.text = self.logTextView.text + "\nGimbal: " + (error?.localizedDescription)!
            }
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        DJISDKManager.missionControl()?.removeListener(self)
        DJISDKManager.keyManager()?.stopAllListening(ofListeners: self)
    }
    
    private var firstLoad = false
    
    // DJIFlightControllerDelegate
    func flightController(_ fc: DJIFlightController, didUpdate state: DJIFlightControllerState) {
        if !self.firstLoad {
            self.firstLoad = true
            self.flightPlanner.setUpParameters(initialYaw: state.attitude.yaw)
            
            var message = ""
            if self.flightController?.yawControlMode == .angle {
                message += "Yaw = Angle, "
            } else {
                message += "Yaw = Angular Velocity, "
            }
            
            if self.flightController?.rollPitchControlMode == .velocity {
                message += "RollPitch = Velocity, "
            } else {
                message += "RollPitch = Angle, "
            }
            
            if self.flightController?.rollPitchCoordinateSystem == .body {
                message += "Coordinate System = Body"
            } else {
                message += "Coordinate System = Ground"
            }
            
            if state.isUltrasonicBeingUsed {
                self.logTextView.text = self.logTextView.text + "\nIsUltrasonicBeingUsed: \(state.isUltrasonicBeingUsed)"
            }
            
            self.logTextView.text = self.logTextView.text + "\nController State: " + message
            self.logTextView.text = self.logTextView.text + "\nController State Info: \(state.attitude.yaw)"
        }
    }
    
    @IBAction func stop(_ sender: Any?) {
        self.flightController?.setVirtualStickModeEnabled(false, withCompletion: nil)
    }
    
    @IBAction func turn(_ sender: Any?) {
        self.flightPlanner.turn()
    }
    
    @IBAction func increasePitch(_ sender: Any?) {
//        self.flightPlanner.changePitch()
    }
    
    @IBAction func startFlight(_ sender: Any?) {
        self.flightController?.setVirtualStickModeEnabled(true, withCompletion: { (error) in
            if error != nil {
                self.logTextView.text = self.logTextView.text + "\nVSME: " + (error?.localizedDescription)!
            } else {
                self.flightController?.startTakeoff(completion: { (error) in
                    if error != nil {
                        self.logTextView.text = self.logTextView.text + "\nST: " + (error?.localizedDescription)!
                    } else {
                        self.firstLoad = false
                    }
                })
            }
        })
    }
}

