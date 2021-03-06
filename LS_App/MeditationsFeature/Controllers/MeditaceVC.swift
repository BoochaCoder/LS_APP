//
//  MeditaceVC.swift
//  LS_App
//
//  Created by Boocha on 17.08.18.
//  Copyright © 2018 Boocha. All rights reserved.
//

import UIKit
import Foundation
import NVActivityIndicatorView
import SwiftKeychainWrapper
import Alamofire
import SwiftyJSON
import Kingfisher

public var signedIn = false

class MeditaceVC: UIViewController, UITabBarDelegate, UITableViewDataSource, UITableViewDelegate {
    //  Hlavní VC meditací se seznam v TableView.
    
    @IBOutlet weak var overallLoadingView: UIView!
    
    @IBOutlet weak var spinnerView: NVActivityIndicatorView!
    
    @IBAction func refreshBtnPressed(_ sender: Any) {
        overallLoadingView.isHidden = false
        spinnerView.startAnimating()
        self.viewDidLoad()
    }
    
    @IBOutlet weak var meditaceTableView: UITableView!
    
    var meditaceArray:[MeditaceClass]? = []
    var savedJson: String?
    var userName: String?
    var userPassWord: String?
    var token = ""
    let internetManager = NetworkReachabilityManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationItem.setHidesBackButton(true, animated: true)
        //  Schová "Zpět" button. Objevuje se, pokud je tento VC pushnut ze SignInVC, což nechci.
        
        if internetManager!.isReachable{
        //  Pokud je internet dostupný, tak načítám z API. Pokud není, spustím listener a ten načte data v momentě, kdy je net zase available.
            spinnerView.startAnimating()
            setDefaultLogin()
            performDoubleRequest()
            
        }else{
            displayMessage(userMessage: "Nejste připojen(a) k internetu. Lze přehrávat pouze stažené meditace.")
            
            savedJson = KeychainWrapper.standard.string(forKey: "json")
            if savedJson == nil {
                savedJson = prvotniJson
            }
            loadMeditationData(jsonData: JSON.init(parseJSON: savedJson!))
            
            //  Listener připojení k internetu.
            internetManager?.listener = { status in
                
                switch status{
                    case .notReachable:
                        print("Není net")
                        return
                    case .reachable(.ethernetOrWiFi), .reachable(.wwan):
                        print("net funguje.")
                        
                        self.spinnerView.startAnimating()
                        self.setDefaultLogin()
                        self.performDoubleRequest()
                    case .unknown:
                        print("Nevím, jestli net funguje.")
                        return
                }
            }
            internetManager?.startListening()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
    }
    
    func loadMeditationData(jsonData: JSON){
    //  Načte stáhnutá data do objektů meditace a vytvoří array, kterým naplní cells tableview.
            meditaceArray = []
    
            for item in jsonData["body"]{
                let meditaceObjekt = MeditaceClass()
                
                meditaceObjekt.id = item.1["id"].int
                if let id = meditaceObjekt.id{
                    meditaceObjekt.downloaded = checkSoundFiles(id: id)
                }
                meditaceObjekt.nadpis = item.1["title"].string
                meditaceObjekt.obsah = item.1["description"].string
                meditaceObjekt.obrazekUrl = item.1["imageUrl"].string
                meditaceObjekt.cena = item.1["price."].int
                meditaceObjekt.velikost = item.1["size"].int64
                meditaceObjekt.dostupnost = item.1["isAvailable"].bool
                
                meditaceArray?.append(meditaceObjekt)
            }
            meditaceTableView.reloadData()
            overallLoadingView.isHidden = true
            spinnerView.stopAnimating()
    }
    
    func setDefaultLogin(){
        //  Nastavuje hodnotu var signedIn a zadava pri prvnim spusteni defaultni prihlasovaci udaje.
        userName = KeychainWrapper.standard.string(forKey: "userName")
        userPassWord = KeychainWrapper.standard.string(forKey: "passWord")
        
        if userName != nil || userPassWord != nil{
            if userName == "iphoneappka@seznam.cz"{
                print("Neprihlasen. Mam defaultni login.")
                signedIn = false
            }else{
                print("Prihlasen.")
                signedIn = true
            }
        }else{
            print("Nastavuji defaultni login údaje.")
            KeychainWrapper.standard.set("iphoneappka@seznam.cz", forKey: "userName")
            KeychainWrapper.standard.set("LaskyplnySvet1@", forKey: "passWord")
            signedIn = false
        }
    }
    
    func performDoubleRequest(){
        //   Nejdříve zjistí token na základě přihlašovacích údajů a následně stáhne seznam meditací
        
        //  Token request
        userName = KeychainWrapper.standard.string(forKey: "userName")
        userPassWord = KeychainWrapper.standard.string(forKey: "passWord")
        
        let url = URL(string: "http://68.183.64.160/api/media/login")
        let parameters: Parameters = ["username" : userName!, "password" : userPassWord!]
        
        Alamofire.request(url!, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil).validate(statusCode: 200..<300)
            
            .responseData{ response in

                switch response.result{
                case .success:
                    let downloadedJSON = JSON(response.data!)
                    
                    if let newToken = downloadedJSON["body"]["token"].string{
                        self.token = newToken
                        let saveAccessToken: Bool = KeychainWrapper.standard.set(self.token, forKey: "accessToken")
                        print("Token uložen do klíčenky: ", saveAccessToken)
                        self.meditationListRequest()
                    }else{
                        print("Nezískal jsem Token z JSONa.")
                    }
                case .failure:
                    print("Error při requestu o token.")
                    print(response.result)
                    print(response)
                    print(response.response)
                    self.spinnerView.stopAnimating()
                    self.displayMessage(userMessage: "Chyba při pokusu o přihlášení. Zkuste prosím později. ")
                }
        }
    }
    
    func meditationListRequest(){
        //  Stáhne data meditací.
        let urlMeditace = URL(string: "http://68.183.64.160/api/media/meditations")
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(String(describing: token))",
            "Accept": "application/json"
        ]
        
        Alamofire.request(urlMeditace!, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300)
            .responseData() { response in
                switch response.result{
            
                    case .success:
                        do{
                            let json = try JSON(data: response.data!, options: .mutableContainers)
                            KeychainWrapper.standard.set(json.rawString()!, forKey: "json")
                            self.loadMeditationData(jsonData: json)
                        }catch{
                            print("Nepodařilo se převést data na json.")
                            print("Data: ", response.data!)
                            print("Status code: ", response.response?.statusCode as Any)
                        }
                    
                    case .failure:
                        print("Failed request. Načítám přihlašovací screen.")
                        print("Status code: ", response.response?.statusCode as Any)
                        print("Response: ", response.response as Any)
                        //  Načti přihlašovací obrazovku
                        self.loadSignInVC()
                }
        }
    }
    
    func loadSignInVC(){
        // Načte přihlašovací VC.
        
        let signInVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "signInVc") as! SignInViewController
        self.navigationController?.pushViewController(signInVC, animated: true)
    }
    
    func displayMessage(userMessage:String) -> Void {
        //  Zobrazí alert.
        DispatchQueue.main.async
            {
                let alertController = UIAlertController(title: "Upozornění", message: userMessage, preferredStyle: .alert)
                
                let OKAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) in
                    DispatchQueue.main.async
                        {
                            self.dismiss(animated: true, completion: nil)
                    }
                }
                alertController.addAction(OKAction)
                self.present(alertController, animated: true, completion:nil)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //  Naplní tableview daty.
        
        let cell = meditaceTableView.dequeueReusableCell(withIdentifier: "meditaceCell", for: indexPath) as! MeditaceCell
        
        cell.nadpisCellMeditace.text = self.meditaceArray?[indexPath.item].nadpis
        cell.popisekCellMeditace.text = self.meditaceArray?[indexPath.item].obsah
        
        cell.obrazekMalyMeditace.layer.cornerRadius = 5
        cell.obrazekMalyMeditace.clipsToBounds = true
        
        if let obrazekURL = URL(string: (self.meditaceArray?[indexPath.item].obrazekUrl)!){
            let resource = ImageResource(downloadURL: obrazekURL)
            let placeHolderImage = UIImage(named: "\(self.meditaceArray![indexPath.item].id!).jpg")
            
            cell.obrazekMalyMeditace.kf.setImage(with: resource, placeholder: placeHolderImage)
            
            //  Obrázek zámku přes nekoupené meditace.
            if !(self.meditaceArray?[indexPath.item].dostupnost)!{
                cell.vrchniObrazek.image = #imageLiteral(resourceName: "locked.png")
                cell.obrazekMalyMeditace.alpha = 0.4
            }else{
                cell.vrchniObrazek.image = nil
                
                if (self.meditaceArray?[indexPath.item].downloaded)!{
                    cell.vrchniObrazek.image = #imageLiteral(resourceName: "downloaded")
                }
                
                cell.obrazekMalyMeditace.alpha = 1
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        
        let detailMeditaceVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "meditaceDetail") as! DetailMeditaceVC
        
        detailMeditaceVC.nadpis = self.meditaceArray?[indexPath.item].nadpis
        detailMeditaceVC.obsah =  self.meditaceArray?[indexPath.item].obsah
        detailMeditaceVC.obrazekUrl = self.meditaceArray?[indexPath.item].obrazekUrl
        detailMeditaceVC.id = self.meditaceArray?[indexPath.item].id
        detailMeditaceVC.dostupnost = self.meditaceArray?[indexPath.item].dostupnost
        detailMeditaceVC.downloaded = self.meditaceArray?[indexPath.item].downloaded
        
        self.navigationController?.pushViewController(detailMeditaceVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return meditaceArray?.count ?? 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // Pokud se uživatel ještě nikdy nepřihlásil a není k dipozici internet, načte se tableview defaulně z tohoto jsonu. Při každém stáhnutí se json aktualizuje na novou verzi. 
    let prvotniJson = "{\n  \"error\" : null,\n  \"body\" : [\n    {\n      \"title\" : \"Pozorování vlastní müsli\",\n      \"price\" : 0,\n      \"size\" : 0,\n      \"id\" : 10,\n      \"isAvailable\" : true,\n      \"description\" : \"Nemusíme přijmout za své všechny myšlenky, které nám vstoupí do hlavy. Odosobníme se od myšlenek a naučíme se být jejich nezávislý pozorovatel. Žádná myšlenka nás nesmí ovládnout. V praxi pak dokážete odsunout nechtěné myšlenky, ať už ty negativní, nebo i pozitivní, na něž v danou chvíli nemáte v životě místo (když se chceme soustředit pouze na jednu konkrétní činnost).\",\n      \"imageUrl\" : \"https:\\/\\/www.ay.energy\\/laskyplnysvet\\/media\\/images\\/meditations\\/pozorovani_myslenek.jpg\"\n    },\n    {\n      \"title\" : \"Komunikace s miminkem\",\n      \"price\" : 380,\n      \"size\" : 0,\n      \"id\" : 1,\n      \"isAvailable\" : false,\n      \"description\" : \"Jeden z nejsilnějších zážitků pro maminky během těhotenství. Naučte se komunikovat se svým miminkem ještě předtím, než je budete držet v náručí.\",\n      \"imageUrl\" : \"https:\\/\\/www.ay.energy\\/laskyplnysvet\\/media\\/images\\/meditations\\/miminko.jpg\"\n    },\n    {\n      \"title\" : \"Nejlepší den\",\n      \"price\" : 130,\n      \"size\" : 0,\n      \"id\" : 2,\n      \"isAvailable\" : false,\n      \"description\" : \"Meditace určená k rannímu probuzení a namotivování pro nejlepší možné výsledky. Doporučujeme si tuto nahrávku nastavit jako budík, proto vám ji jako jedinou nahrávku zašleme po zakoupení také do e-mailové schránky. Skutečně neznáme lepší start dne, než se vědomě probudit, utřídit si myšlenky, podpořit naše nejlepší vlastnosti a nadšeně tvořit svůj nejlepší den.\",\n      \"imageUrl\" : \"https:\\/\\/www.ay.energy\\/laskyplnysvet\\/media\\/images\\/meditations\\/nejlepsi_den.jpg\"\n    },\n    {\n      \"title\" : \"Léčivá meditace\",\n      \"price\" : 300,\n      \"size\" : 0,\n      \"id\" : 3,\n      \"isAvailable\" : false,\n      \"description\" : \"Ať už se jedná o rýmu, nebo vážně dlouhodobé obtíže, většina našich nemocí má původ v neovládnutých myšlenkách. Podpořit léčbu skrze uklidnění mysli a naučit se sebeléčení je tedy logický krok, proto pro vás máme nádherný příběh. Nechte se jím vtáhnout a urychlete své uzdravení.\",\n      \"imageUrl\" : \"https:\\/\\/www.ay.energy\\/laskyplnysvet\\/media\\/images\\/meditations\\/leciva_meditace.jpg\"\n    },\n    {\n      \"title\" : \"Meditace klidu\",\n      \"price\" : 90,\n      \"size\" : 0,\n      \"id\" : 4,\n      \"isAvailable\" : false,\n      \"description\" : \"Po náročném dni je důležité se uvolnit a pročistit mysl, jen tak můžeme skutečně v noci regenerovat po všech stránkách. V této meditaci se vše potřebné naučíme a již nikdy nebudeme usínat s hlavou plnou starostí.\",\n      \"imageUrl\" : \"https:\\/\\/www.ay.energy\\/laskyplnysvet\\/media\\/images\\/meditations\\/meditace_klidu.jpg\"\n    },\n    {\n      \"title\" : \"Nacítění astrálního těla\",\n      \"price\" : 480,\n      \"size\" : 0,\n      \"id\" : 5,\n      \"isAvailable\" : false,\n      \"description\" : \"Seznámíme se s prvotním reálným procítěním astrálního těla. Již to nebude pouze teorie, ale jdeme do praxe. Nebudeme astrálně cestovat, “pouze” se naučíme cítit naše astrální tělo – tedy první krok k úspěšnému astrálnímu cestování.\",\n      \"imageUrl\" : \"https:\\/\\/www.ay.energy\\/laskyplnysvet\\/media\\/images\\/meditations\\/naciteni_astralniho_tela.jpg\"\n    },\n    {\n      \"title\" : \"Napojení na univerzální sílu\",\n      \"price\" : 360,\n      \"size\" : 0,\n      \"id\" : 6,\n      \"isAvailable\" : false,\n      \"description\" : \"Naučíme se čerpat čistou univerzální energii, kterou si poté transformujeme do námi zvolené vlastnosti. Bude to klid mysli, láska, odhodlání či pevnost? To je již na vás. P.S.: zároveň podpoříme intuici. ;)\",\n      \"imageUrl\" : \"https:\\/\\/www.ay.energy\\/laskyplnysvet\\/media\\/images\\/meditations\\/univerzalni_sila.jpg\"\n    },\n    {\n      \"title\" : \"Niterná síla\",\n      \"price\" : 220,\n      \"size\" : 0,\n      \"id\" : 7,\n      \"isAvailable\" : false,\n      \"description\" : \"Poznat sami sebe více do hloubky a z různých úhlů pohledu. Výlet do nitra nás samotných pro získání sebevědomí a jistoty.\",\n      \"imageUrl\" : \"https:\\/\\/www.ay.energy\\/laskyplnysvet\\/media\\/images\\/meditations\\/niterna_sila.jpg\"\n    },\n    {\n      \"title\" : \"Ochranná bytost\",\n      \"price\" : 180,\n      \"size\" : 0,\n      \"id\" : 8,\n      \"isAvailable\" : false,\n      \"description\" : \"Setkání s ochrannou bytostí bývá vždy příjemný zážitek. Někomu se ihned zjeví její tvar, na někoho ze začátku pouze promlouvá, avšak všichni cítíme ten nekonečný láskyplný klid, který nás zalévá, a tím otevírá naše nejniternější vedení. Vždy nás nasměruje na správnou cestu životem.\",\n      \"imageUrl\" : \"https:\\/\\/www.ay.energy\\/laskyplnysvet\\/media\\/images\\/meditations\\/ochranna_bytost.jpg\"\n    },\n    {\n      \"title\" : \"Ovládnutí jedné myšlenky\",\n      \"price\" : 90,\n      \"size\" : 0,\n      \"id\" : 9,\n      \"isAvailable\" : false,\n      \"description\" : \"Díky dovednosti jasné koncentrace dokážeme žít všichni kvalitnější život a intenzivněji jej prožívat. Zaměříme se pouze na jednu námi zvolenou myšlenku a vše ostatní pro nás přestává být důležité. Jdeme si za svým cílem, šetříme čas, jsme efektivnější.\",\n      \"imageUrl\" : \"https:\\/\\/www.ay.energy\\/laskyplnysvet\\/media\\/images\\/meditations\\/jedna_myslenka.jpg\"\n    },\n    {\n      \"title\" : \"Rozlučme se s depresí\",\n      \"price\" : 240,\n      \"size\" : 0,\n      \"id\" : 11,\n      \"isAvailable\" : false,\n      \"description\" : \"Tato velmi silná emoce dokáže obrovské věci - zcela ovládne naši mysl, nutí nás ležet v posteli, brečet, litovat se. Nevidíme východisko ze své situace. Nyní je čas převzít svou veškerou sílu zpět a opět žít šťastný život.\",\n      \"imageUrl\" : \"https:\\/\\/www.ay.energy\\/laskyplnysvet\\/media\\/images\\/meditations\\/deprese.jpg\"\n    },\n    {\n      \"title\" : \"Do vyšších sfér a zpět\",\n      \"price\" : 720,\n      \"size\" : 0,\n      \"id\" : 12,\n      \"isAvailable\" : false,\n      \"description\" : \"Jedinečná meditace pro poznání vyšších sfér, postupně se zbavíte veškerých myšlenek, problémů, ega, sami sebe… . Cestou zpět vše opět naberete a budete si o to více užívat hmotný svět. Tato meditace je určena pro ty zkušenější z vás, kteří již ovládají svou mysl.\",\n      \"imageUrl\" : \"https:\\/\\/www.ay.energy\\/laskyplnysvet\\/media\\/images\\/meditations\\/vyssi_sfery.jpg\"\n    }\n  ]\n}"
}
