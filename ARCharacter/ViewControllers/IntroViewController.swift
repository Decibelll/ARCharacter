//
//  IntroViewController.swift
//  ARCharacter
//
//  Created by Sergii Nesteruk on 8/21/18.
//  Copyright © 2018 NLab. All rights reserved.
//

import UIKit
import AVFoundation

class IntroViewController: UIViewController {
    
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var startButton: UIButton!
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        checkCameraAccessStatus()
    }
    
    private func checkCameraAccessStatus() {
        
        // Check camera access
        let cameraMediaType = AVMediaType.video
        let cameraAccessStatus = AVCaptureDevice.authorizationStatus(for: cameraMediaType)
        
        switch cameraAccessStatus {
        case .denied, .restricted:
            statusLabel.text = "Please allow access to camera in Settings"
            statusLabel.textColor = UIColor.red
            statusLabel.isHidden = false
            startButton.isHidden = true
            infoLabel.isHidden = false
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            break
            
        case .authorized:
            statusLabel.text = "Starting AR"
            statusLabel.textColor = UIColor.lightGray
            statusLabel.isHidden = false
            startButton.isHidden = true
            infoLabel.isHidden = true
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            performSegue(withIdentifier: "Show AR", sender: nil)
            break
            
        case .notDetermined:
            statusLabel.isHidden = true
            infoLabel.isHidden = false
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            startButton.isHidden = false
        }
    }
    
    @IBAction func startButtonTapped() {
        
        let cameraMediaType = AVMediaType.video
        AVCaptureDevice.requestAccess(for: cameraMediaType) { granted in
            DispatchQueue.main.async {
                if granted {
                    self.performSegue(withIdentifier: "Show AR", sender: nil)
                } else {
                    self.checkCameraAccessStatus()
                }
            }
        }
    }
}
