//
//  DetailMeditaceVC.swift
//  LS_App
//
//  Created by Boocha on 18.08.18.
//  Copyright © 2018 Boocha. All rights reserved.
//

import UIKit
import AVFoundation

class DetailMeditaceVC: UIViewController {

    @IBOutlet weak var velkyImageMeditace: UIImageView!
    
    @IBOutlet weak var nadpisMeditaceLabel: UILabel!
    
    
    @IBAction func prehrajMeditaciPressed(_ sender: Any) {
        let playerVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "player") as! MeditacePlayerVC
        playerVC.mluveneSlovo = mluveneSlovo
        playerVC.podkladovaHudba = podkladovaHudba
        print(playerVC.mluveneSlovo)
        self.navigationController?.pushViewController(playerVC, animated: true)
    }
    

    
    var nadpis: String?
    var popisek: String?
    var image: String?
    var mluveneSlovo: String?
    var podkladovaHudba: String?
    

    //přehrává audio
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if nadpisMeditaceLabel != nil{
            nadpisMeditaceLabel.text = nadpis
        }
        
        if velkyImageMeditace != nil{
            velkyImageMeditace.image = UIImage(imageLiteralResourceName: image!)
        }
        // Do any additional setup after loading the view.
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
/*
    func playHudba() -> Void {
    //přehrává hudbu
        
        let url = Bundle.main.url(forResource: podkladovaHudba, withExtension: "mp3")!
        do {
            playerHudba = try AVAudioPlayer(contentsOf: url)
            guard let playerHudba = playerHudba else { return }
            playerHudba.numberOfLoops = -1
            //nekonečně přehrávání
            playerHudba.prepareToPlay()
            playerHudba.play()
    } catch let error {
    print(error.localizedDescription)
    }
    }
    
    
    
    func playSlovo(time: TimeInterval) -> Void {
        //přehrává zvuky
        if playerSlovo != nil{
            playerSlovo?.pause()
        }
        
        let url = Bundle.main.url(forResource: mluveneSlovo, withExtension: "mp3")!
        do {
            playerSlovo = try AVAudioPlayer(contentsOf: url)
            guard let player = playerSlovo else { return }
           
            player.prepareToPlay()
            player.currentTime = time
            player.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func skipSlovo(oKolik: Double){
        if playerSlovo != nil{
            var pozice = (playerSlovo?.currentTime)! + oKolik
            if pozice < 0{
                pozice = 0
            }
            
            if pozice < (playerSlovo?.duration)!{
                print(pozice)
                playerSlovo?.currentTime = pozice
            }else{
                playerSlovo?.stop()
            }
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
*/