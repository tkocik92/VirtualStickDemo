//
//  StartupViewController.swift
//  VirtualStickDemo
//
//  Created by Tom Kocik on 5/15/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import DJISDK
import UIKit

class StartupViewController: UIViewController {
    private var appDelegate: AppDelegate! = UIApplication.shared.delegate as? AppDelegate
    
    @IBOutlet weak var labelStatus: UILabel!
    @IBOutlet weak var labelModel: UILabel!
    @IBOutlet weak var buttonOpen: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.resetUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        guard let connectedKey = DJIProductKey(param: DJIParamConnection) else {
            print("Error creating the connectedKey")
            return;
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            DJISDKManager.keyManager()?.startListeningForChanges(on: connectedKey, withListener: self, andUpdate: { (oldValue: DJIKeyedValue?, newValue : DJIKeyedValue?) in
                if newValue != nil {
                    self.handleConnectionResult(isConnected: (newValue?.boolValue)!)
                }
            })
            
            DJISDKManager.keyManager()?.getValueFor(connectedKey, withCompletion: { (value:DJIKeyedValue?, error:Error?) in
                if let unwrappedValue = value {
                    self.handleConnectionResult(isConnected: unwrappedValue.boolValue)
                }
            })
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        DJISDKManager.keyManager()?.stopAllListening(ofListeners: self)
    }
    
    // Connection UI
    func showDroneConnected() {
        self.labelModel.text = "Status: Connected"
        
        self.labelModel.text = "Model: \((DJISDKManager.product()?.model)!)"
        self.buttonOpen.isEnabled = true;
        self.buttonOpen.alpha = 1.0;
    }
    
    private func resetUI() {
        self.title = "Drone Barcode"
        self.labelModel.text = "Status: Trying to connect..."
        self.labelModel.text = "Model: Unavailable"
        self.buttonOpen.isEnabled = false
    }
    
    private func handleConnectionResult(isConnected: Bool) {
        DispatchQueue.main.async {
            if isConnected {
                self.productConnected()
            } else {
                self.productDisconnected()
            }
        }
    }
    
    private func productConnected() {
        guard DJISDKManager.product() != nil else {
            let alert = UIAlertController(title: "Error", message: "Product is connected but cannot be retrieved", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return;
        }
        
        self.labelModel.text = "Status: Connecting..."
        
        let controller = (DJISDKManager.product() as? DJIAircraft)?.flightController
        
        controller?.setVisionAssistedPositioningEnabled(true, withCompletion: { (error) in
            if error != nil {
                // Handle error
            } else {
                self.showDroneConnected()
            }
        })
    }
    
    private func productDisconnected() {
        self.labelModel.text = "Status: No Product Connected"
        self.labelModel.text = "Model: Unavailable"
        
        self.buttonOpen.isEnabled = false;
        self.buttonOpen.alpha = 0.8;
    }
}
