//
//  DownloadVC.swift
//  LS_App
//
//  Created by Boocha on 15.02.19.
//  Copyright © 2019 Boocha. All rights reserved.
//

import UIKit
import Alamofire

class DownloadVC: UIViewController {
    
    
    @IBOutlet weak var hudbaLabel: UILabel!
    
    @IBOutlet weak var hudbaProgressView: UIProgressView!
    
    @IBOutlet weak var slovoLabel: UILabel!
    
    @IBOutlet weak var slovoProgressView: UIProgressView!
    
    @IBAction func prerusitBtnPressed(_ sender: Any) {
        
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            sessionDataTask.forEach { $0.cancel() }
            uploadData.forEach { $0.cancel() }
            downloadData.forEach { $0.cancel() }
        }
    }
    var voiceUrl: String?
    var musicUrl: String?
    var id: Int?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        if !checkInternet(){
            displayMessage(userMessage: "Pro stahování meditací je zapotřebí připojení k internetu.")
        }
        
        
        let hudbaDestination: DownloadRequest.DownloadFileDestination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("\(self.id!)_hudba.mp3")
            
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        let slovoDestination: DownloadRequest.DownloadFileDestination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("\(self.id!)_slovo.mp3")
            
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        if let musicURLunwrapped = musicUrl{
        
            Alamofire.download(musicURLunwrapped, to: hudbaDestination)
                //stahování hudby, po dokončení se stahuje slovo
                .downloadProgress{progress in
                    print("Progress celkový: ", progress.totalUnitCount)
                    print("Progress so far: ", progress.completedUnitCount)
                    
                    let progressInt = Int((progress.fractionCompleted * 1000).rounded() / 10)
                    self.hudbaLabel.text = "Hudba: \(progressInt) %"
                    self.hudbaProgressView.progress = Float(progress.fractionCompleted)
                }
                
                .response{ response in
                    Alamofire.download(self.voiceUrl!, to: slovoDestination)
                        //stahování slova
                        .downloadProgress{progress in
                            let progressInt = Int((progress.fractionCompleted * 1000).rounded() / 10)
                            self.slovoLabel.text = "Mluvené slovo: \(progressInt) %"
                            self.slovoProgressView.progress = Float(progress.fractionCompleted)
                    }
                        .response{response in
                            //po dokončení stahování slova se načte seznam meditací
                            let meditaceVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "meditaceVC") as! MeditaceVC
                            self.navigationController?.pushViewController(meditaceVC, animated: true)
                            
                        }
                    
                }
        }
    }
    
    
    
    
    func displayMessage(userMessage:String) -> Void {
        DispatchQueue.main.async
            {
                let alertController = UIAlertController(title: nil, message: userMessage, preferredStyle: .alert)
                
                let OKAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) in
                    // Code in this block will trigger when OK button tapped.
                    print("Ok button tapped")
                    DispatchQueue.main.async
                        {
                            self.dismiss(animated: true, completion: nil)
                    }
                }
                alertController.addAction(OKAction)
                self.present(alertController, animated: true, completion:nil)
        }
    }

}
