//
//  ArticleListVC.swift
//  LS_App
//
//  Created by Boocha on 24.07.18.
//  Copyright © 2018 Boocha. All rights reserved.
//

import UIKit
import Foundation
import Alamofire
import SwiftyJSON
import Kingfisher
import NVActivityIndicatorView

class ArticleListVC: UIViewController, UITabBarDelegate, UITableViewDataSource, UITableViewDelegate {
    //VC, který zobrazuje seznam článků
    
    @IBOutlet weak var articlesTableView: UITableView!
    
    let APIadresa = "https://laskyplnysvet.cz/stesti/wp-json/wp/v2/posts"
    
    var articlesArray: [ArticleClass]? = []


    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingLabel: UILabel!
    var activityIndicatorView: NVActivityIndicatorView? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //vytvoření loading indikátoru
        
        loadArticles(APIurl: APIadresa)
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadArticles(APIurl: String){
        //pripoji se k API, vyzobe si z JSONa, co potrebuje a vytvori objekty pro Articl esarray
        
            displayInfo(infoText: "Načítám články...")
            //Loading bar
        
            Alamofire.request(APIadresa).responseJSON{response in
            
            if let value = response.result.value as? [Dictionary<String, Any>]{
            
            for item in value{
                let article = ArticleClass()
                
                let json = JSON(item)
                
                
                if let nadpis = json["title"]["rendered"].string{
                    article.nadpis = nadpis.htmlAttributed()?.string
                }
                
                if let obsah = json["content"]["rendered"].string{
                    article.obsah = obsah.htmlAttributed()
                }
                
                if let popisek = json["excerpt"]["rendered"].string{
                    article.popisek = popisek.htmlAttributed()?.string
                }
                
               if let linkClanku = json["link"].string{
                    article.linkClanku = linkClanku
                }
                
                if let mediaId = json["featured_media"].int{
                    article.mediaId = String(mediaId)
                }
                

                self.getObrazekURL(mediaId: String(article.mediaId!)){malyObrazekUrl, velkyObrazekUrl in
                    //nacita URL adresu thumbnail obrazku a velkeho obrazku
                    //jede asynchronne a data v table view se reloadnou teprve, az je nacteno vse
                    article.downloadedImageResource = ImageResource(downloadURL: URL(string: malyObrazekUrl)!, cacheKey: malyObrazekUrl)
                    
                    article.velkyObrazekURL = velkyObrazekUrl
                    
                    if article == self.articlesArray?.last{
                        print("ted")
                        self.articlesTableView.reloadData()
                        self.hideInfo()
                    }
                }
                
                
                
                self.articlesArray?.append(article)
                }
                
                
            }
            //self.articlesTableView.reloadData()
        }
    }
    
    
    
    
    //MARK: - funkce protokolů pro TableView
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //povinná funkce protokolu UITAbleViewDataSource. Využívá identifieru, který jsem nastavil ve vlastnostech buňky
        
        let cell = articlesTableView.dequeueReusableCell(withIdentifier: "articleCell", for: indexPath) as! ArticleCell
        
        cell.nadpisLabel.text = self.articlesArray?[indexPath.item].nadpis
        cell.popisekLabel.text = self.articlesArray?[indexPath.item].popisek
        
        cell.obrazekView.layer.cornerRadius = 5
        cell.obrazekView.clipsToBounds = true
        //oblé rohy
        
        let resource = self.articlesArray?[indexPath.item].downloadedImageResource
        cell.obrazekView.kf.setImage(with: resource, placeholder: #imageLiteral(resourceName: "LS_logo_male")){ (image, error, cacheType, imageUrl) in
            cell.setNeedsLayout()
        }
        
        return cell
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        //sekce rozdělují celly do skupin. Potřebuju jen jednu.
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.articlesArray?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        
        print("funguje klik")
        let clanekVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "web") as! ArticleVC
        clanekVC.obsahClanku = self.articlesArray?[indexPath.item].obsah
        clanekVC.velkyObrazekUrl = self.articlesArray?[indexPath.item].velkyObrazekURL
        clanekVC.nadpisClanku = self.articlesArray?[indexPath.item].nadpis
        
       // self.present(clanekVC, animated: true, completion: nil)
        self.navigationController?.pushViewController(clanekVC, animated: true)
    }
    
    
    

    func getObrazekURL(mediaId: String, completion: @escaping ((String, String) -> ())){
        //propoji se k dalši APIně, stáhne si JSONa a vyzobe z něj URL na obrázky. Nakonec toto URL předá closure completion jako její parametr. Protože stahování URL probíhá asynchronně, nelze normálně returnovat, ale na konci prostě řeknu: proveď tento kód s tímto parametrem. Při voláni funkce pak vytvořím samotnou closure. 
        
        let mediaUrl = "https://laskyplnysvet.cz/stesti/wp-json/wp/v2/media/" + mediaId
        var malyObrazekUrl: String?
        var velkyObrazekUrl: String?
        
        Alamofire.request(mediaUrl).responseJSON{response in
            if let odpoved = response.result.value as? NSDictionary{
                
                let json = JSON(odpoved)
                malyObrazekUrl = json["media_details"]["sizes"]["thumbnail"]["source_url"].string
                velkyObrazekUrl = json["media_details"]["sizes"]["full"]["source_url"].string
                
                
                if malyObrazekUrl != nil, velkyObrazekUrl != nil{
                    completion(malyObrazekUrl!, velkyObrazekUrl!)
                }
            }
        }
    }
    
    func displayInfo(infoText: String){
        //Zobrazí loading animaci a label
        loadingView.backgroundColor = UIColor(white: 0.8, alpha: 0.5)

        let bodX = UIScreen.main.bounds.width
        let bodY = UIScreen.main.bounds.height
        let frame = CGRect(x: bodX/2 - 40  , y: bodY/2 - 40 , width: 80  , height: 80)
        activityIndicatorView = NVActivityIndicatorView(frame: frame, type: .ballTrianglePath, color: .black)
        self.view.addSubview(activityIndicatorView!)
        
        activityIndicatorView?.startAnimating()
        loadingLabel.isHidden = false
        loadingLabel.center.x = bodX/2
        loadingLabel.center.y = bodY/2 + 80
        loadingLabel.text = infoText
    }
    
    func hideInfo(){
        activityIndicatorView?.stopAnimating()
        loadingView.isHidden = true
        loadingLabel.isHidden = true
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



extension String {
    //Dokáže přetvořit text s html tagy na normální text
    func htmlAttributed() -> NSAttributedString? {
        do {
            let htmlCSSString = "<style>" +
                "html * {font-size: 15.0pt !important;color: #383838 !important;font-family: Avenir !important;}</style> \(self)"
            
            guard let data = htmlCSSString.data(using: String.Encoding.utf8) else {
                return nil
            }
            let myAttribute = [NSAttributedStringKey.font: UIFont(name: "Avenir", size: 20.0)!]

            return try NSAttributedString(data: data,
                                          options: [.documentType: NSAttributedString.DocumentType.html,
                                                    .characterEncoding: String.Encoding.utf8.rawValue],
                                          documentAttributes: nil)
        } catch {
            print("error: ", error)
            return nil
        }
    }
    
}


