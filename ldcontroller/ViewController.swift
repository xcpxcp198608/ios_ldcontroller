//
//  ViewController.swift
//  ldcontroller
//
//  Created by patrick on 2018/4/7.
//  Copyright © 2018 许程鹏. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Instructions
import AudioToolbox
import Popover_OC
import MMPopupView
import CoreData
import CoreStore
import PKHUD
import Reachability


class ViewController: UIViewController {
    
    @IBOutlet weak var btEdit: UIButton!
    @IBOutlet weak var btPower: UIButton!
    @IBOutlet weak var laAlias: UILabel!
    @IBOutlet weak var btBtv: UIButton!
    @IBOutlet weak var btUp: UIButton!
    @IBOutlet weak var btDown: UIButton!
    @IBOutlet weak var btLeft: UIButton!
    @IBOutlet weak var btRight: UIButton!
    @IBOutlet weak var btOK: UIButton!
    @IBOutlet weak var btHome: UIButton!
    @IBOutlet weak var btBack: UIButton!
    @IBOutlet weak var btApps: UIButton!
    @IBOutlet weak var btVolUp: UIButton!
    @IBOutlet weak var btVolDown: UIButton!
    @IBOutlet weak var btVolMute: UIButton!
    @IBOutlet weak var btKeyboard: UIButton!
    @IBOutlet weak var tfHolder: UITextField!
    
    let coachMarksController = CoachMarksController()
    let reachability = Reachability()!
    
    var localIp = ""
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
//        checkNetwork()
        self.localIp = self.getLocalIPAddressForCurrentWiFi()
        do {
            try CoreStore.addStorageAndWait(SQLiteStore.init(fileName: "ldcontroller.sqlite"))
        }
        catch { // ...
        }
        let config = MMAlertViewConfig.global()
        config?.defaultTextOK = "Confirm"
        config?.defaultTextConfirm = "Confirm"
        config?.defaultTextCancel = "Cancel"
        
        let sConfig = MMSheetViewConfig.global()
        sConfig?.defaultTextCancel = "Cancel"
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        gestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(gestureRecognizer)
        tfHolder.delegate = self
        coachMarksController.dataSource = self
        coachMarksController.delegate = self
        
        if let currentIp = UserDefaults.standard.string(forKey: "IPAddress"){
            var oIp: IP?
            CoreStore.perform(
                asynchronous: { (transaction) -> Void in
                    oIp = transaction.fetchOne(
                        From<IP>()
                            .where(\.ip == currentIp)
                    )
                },
                completion: { (result) -> Void in
                    switch result {
                    case .success: self.laAlias.text = oIp?.name
                    case .failure(let error): print(error)
                    }
                })
        }
    }
    
    func checkNetwork(){
        reachability.whenReachable = { reachability in
            if reachability.connection == .wifi {
                self.localIp = self.getLocalIPAddressForCurrentWiFi()
            } else {
                print("Reachable via Cellular")
            }
        }
        reachability.whenUnreachable = { _ in
            print("Not reachable")
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
    
    
    @objc func hideKeyboard(){
        tfHolder.resignFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let showGuideView: Bool = UserDefaults.standard.bool(forKey: "ShowGuideView")
        if(!showGuideView){
            self.coachMarksController.start(on: self)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.coachMarksController.stop(immediately: true)
        reachability.stopNotifier()
    }
    
    
    @IBAction func showPopupMenu(){
        let popAdd = PopoverAction.init(image: #imageLiteral(resourceName: "add_30"), title: "Add new", handler: {action in
            self.setIP()
        })
        let popList = PopoverAction.init(image: #imageLiteral(resourceName: "menu_30"), title: "Show all", handler: {action in
            self.showLocalIps()
        })
        let popDelete = PopoverAction.init(image: #imageLiteral(resourceName: "ic_delete_forever_30"), title: "Delete all", handler: {action in
            self.deleteLocalIps()
        })
        let popView = PopoverView()
        popView.style = .dark
        popView.show(to: btEdit, with: [popAdd!, popList!, popDelete!])
    }
    
    func setIP(){
        let alertView = MMAlertView.init(inputTitle: "Add New", detail: "Enter IP address shown on your BTVi B-KeyMo Air app", placeholder: localIp) { (newIp) in
            if let ip = newIp{
                if ip.count <= 0{
                    return
                }
                let regexIP = "^(1\\d{2}|2[0-4]\\d|25[0-5]|[1-9]\\d|[1-9])\\.(1\\d{2}|2[0-4]\\d|25[0-5]|[1-9]\\d|\\d)\\.(1\\d{2}|2[0-4]\\d|25[0-5]|[1-9]\\d|\\d)\\.(1\\d{2}|2[0-4]\\d|25[0-5]|[1-9]\\d|\\d)$"
                let predicate = NSPredicate(format: "SELF MATCHES %@", regexIP)
                if !predicate.evaluate(with: ip) {
                    HUD.flash(.labeledError(title: "", subtitle: "IP address format error"), delay: 2.5)
                    return
                }
                self.setIPAlias(ip)
            }
        }
        alertView?.show()
    }
    
    func setIPAlias(_ ip: String){
        let alertView = MMAlertView.init(inputTitle: "Set alias", detail: "", placeholder: "type in alias") { (alias) in
            var name = ""
            if (alias?.count)! > 0{
                name = alias!
            }
            UserDefaults.standard.set(ip, forKey: "IPAddress")
            CoreStore.perform(
                asynchronous: { (transaction) -> Void in
                    let ipInfo = transaction.create(Into<IP>())
                    ipInfo.ip = ip
                    ipInfo.name = name
                },
                completion: { (result) -> Void in
                    switch result {
                    case .success: print("success!")
                    case .failure(let error): print(error)
                    }
            })
            self.laAlias.text = name
        }
        alertView?.show()
    }
    
    
    
    func showLocalIps(){
        let ips = CoreStore.fetchAll(From<IP>())
        if(ips == nil || (ips?.count)! <= 0){
            HUD.flash(.labeledError(title: "", subtitle: "Please enter targeted BTVi IP"), delay: 1.5)
            return
        }
        var alertItems = [MMPopupItem]()
        for ip in ips!{
            print(ip.ip)
            let alertItem = MMItemMake("\(ip.ip)(\(ip.name))", .normal) { (position) in
                self.showIPAction(ip.ip, ip.name)
            }
            alertItems.append(alertItem!)
        }
        
        let alertSheetView = MMSheetView .init(title: "Choose paired BTVi device", items: alertItems)
        alertSheetView?.backgroundColor = UIColor.darkGray
        alertSheetView?.show()
    }
    
    func showIPAction(_ ip: String, _ name: String){
        let alertItemControl = MMItemMake("Control", .highlight) { (position) in
            UserDefaults.standard.set(ip, forKey: "IPAddress")
            self.laAlias.text = name
        }
        
        let alertItemDelete = MMItemMake("Delete", .normal) { (position) in
            CoreStore.perform(
                asynchronous: { (transaction) -> Void in
                    let oIp = transaction.fetchOne(
                        From<IP>()
                            .where(\.ip == ip)
                    )
                    transaction.delete(oIp)
                },
                completion: { (result) -> Void in
                    switch result {
                    case .success:
                        if let currentIp = UserDefaults.standard.string(forKey: "IPAddress"){
                            if currentIp == ip{
                                UserDefaults.standard.removeObject(forKey: "IPAddress")
                                self.laAlias.text = ""
                            }
                        }
                        break
                    case .failure(let error): print(error)
                    }
            })
        }
        
        let alertItemCancel = MMItemMake("Cancel", .normal) { (position) in
        }
        let alertView = MMAlertView.init(title: "Choose Action", detail: "", items: [alertItemControl!, alertItemDelete!, alertItemCancel!])
        alertView?.show()
    }
    
    
    func deleteLocalIps(){
        let confirmItem = MMItemMake("Confirm", .highlight) { (position) in
            CoreStore.perform(
                asynchronous: { (transaction) -> Void in
                    transaction.deleteAll(From<IP>())
                },
                completion: { (result) -> Void in
                    switch result {
                    case .success:
                        UserDefaults.standard.removeObject(forKey: "IPAddress")
                        self.laAlias.text = ""
                        break
                    case .failure(let error): print(error)
                    }
                })
        }
        let cancelItem = MMItemMake("Cancel", .normal) { (position) in
            
        }
        let alertView = MMAlertView.init(title: "Delete", detail: "Please confirm to remove all BTVi pairings", items: [confirmItem!, cancelItem!])
        
        alertView?.show()
    }
    
    @IBAction func clickButton(button: UIButton){
        let currentIp = UserDefaults.standard.string(forKey: "IPAddress")
        if currentIp == nil || (currentIp?.count)! <= 0{
            HUD.flash(.labeledError(title: "", subtitle: "Please enter targeted BTVi IP"), delay: 1.5)
            return
        }
        switch button {
        case btPower:
            sendCommand(26)
            break
        case btBtv:
            sendCommand(260)
            break
        case btUp:
            sendCommand(19)
            break
        case btDown:
            sendCommand(20)
            break
        case btLeft:
            sendCommand(21)
            break
        case btRight:
            sendCommand(22)
            break
        case btOK:
            sendCommand(23)
            break
        case btVolUp:
            sendCommand(24)
            break
        case btVolDown:
            sendCommand(25)
            break
        case btVolMute:
            sendCommand(164)
            break
        case btHome:
            sendCommand(3)
            break
        case btBack:
            sendCommand(4)
            break
        case btApps:
            sendCommand(262)
            break
        case btKeyboard:
            tfHolder.becomeFirstResponder()
            break
        default:
            print("default")
            break
        }
        AudioServicesPlaySystemSound(1105)
    }

}



extension ViewController: CoachMarksControllerDataSource, CoachMarksControllerDelegate{
    
    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        return 1
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkAt index: Int) -> CoachMark {
        return coachMarksController.helper.makeCoachMark(for: btEdit, pointOfInterest: nil, cutoutPathMaker: nil)
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkViewsAt index: Int, madeFrom coachMark: CoachMark) -> (bodyView: CoachMarkBodyView, arrowView: CoachMarkArrowView?) {
        let coachViews = coachMarksController.helper.makeDefaultCoachViews(withArrow: true, arrowOrientation: coachMark.arrowOrientation)
        coachViews.bodyView.hintLabel.text = "Click edit button to pair with your BTVi"
        coachViews.bodyView.nextLabel.text = "Got it"
        return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, didEndShowingBySkipping skipped: Bool) {
        UserDefaults.standard.set(true, forKey: "ShowGuideView")
    }
    
}


extension ViewController {
    
    
    func getLocalIPAddressForCurrentWiFi() -> String {
        var address = ""
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        guard getifaddrs(&ifaddr) == 0 else {
            return address
        }
        guard let firstAddr = ifaddr else {
            return address
        }
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" {
                    var addr = interface.ifa_addr.pointee
                    var hostName = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(&addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostName, socklen_t(hostName.count), nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostName)
                }
            }
        }
        freeifaddrs(ifaddr)
        return address
    }
    
}


extension ViewController: UITextFieldDelegate{
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        switch string {
        case "0":
            sendCommand(7)
        case "1":
            sendCommand(8)
        case "2":
            sendCommand(9)
        case "3":
            sendCommand(10)
        case "4":
            sendCommand(11)
        case "5":
            sendCommand(12)
        case "6":
            sendCommand(13)
        case "7":
            sendCommand(14)
        case "8":
            sendCommand(15)
        case "9":
            sendCommand(16)
        case "a":
            sendCommand(29)
        case "b":
            sendCommand(30)
        case "c":
            sendCommand(31)
        case "d":
            sendCommand(32)
        case "e":
            sendCommand(33)
        case "f":
            sendCommand(34)
        case "g":
            sendCommand(35)
        case "h":
            sendCommand(36)
        case "i":
            sendCommand(37)
        case "j":
            sendCommand(38)
        case "k":
            sendCommand(39)
        case "l":
            sendCommand(40)
        case "m":
            sendCommand(41)
        case "n":
            sendCommand(42)
        case "o":
            sendCommand(43)
        case "p":
            sendCommand(44)
        case "q":
            sendCommand(45)
        case "r":
            sendCommand(46)
        case "s":
            sendCommand(47)
        case "t":
            sendCommand(48)
        case "u":
            sendCommand(49)
        case "v":
            sendCommand(50)
        case "w":
            sendCommand(51)
        case "x":
            sendCommand(52)
        case "y":
            sendCommand(53)
        case "z":
            sendCommand(54)
        case " ":
            sendCommand(62)
        case "-":
            sendCommand(69)
        case "_":
            sendCommand(0)
        case "+":
            sendCommand(81)
        case "=":
            sendCommand(70)
        case "{":
            sendCommand(0)
        case "}":
            sendCommand(0)
        case "[":
            sendCommand(71)
        case "]":
            sendCommand(72)
        case "|":
            sendCommand(0)
        case "\\":
            sendCommand(73)
        case ":":
            sendCommand(0)
        case ";":
            sendCommand(74)
        case "\"":
            sendCommand(0)
        case "'":
            sendCommand(75)
        case "<":
            sendCommand(0)
        case ">":
            sendCommand(0)
        case ",":
            sendCommand(55)
        case ".":
            sendCommand(56)
        case "?":
            sendCommand(0)
        case "/":
            sendCommand(76)
        case "~":
            sendCommand(0)
        case "!":
            sendCommand(0)
        case "@":
            sendCommand(77)
        case "#":
            sendCommand(0)
        case "$":
            sendCommand(0)
        case "%":
            sendCommand(0)
        case "^":
            sendCommand(0)
        case "&":
            sendCommand(0)
        case "*":
            sendCommand(0)
        case "(":
            sendCommand(0)
        case ")":
            sendCommand(0)
        case "":
            sendCommand(67)
        case "\n":
            sendCommand(66)
        case "caps":
            sendCommand(115)
        default:
            print(string)
        }
        return true
    }
    
    
}



extension ViewController{
    
    func sendCommand(_ command: Int){
        if let ip = UserDefaults.standard.string(forKey: "IPAddress"){
            let url = "http://\(ip):8088/rc/\(command)"
            Alamofire.request(url, method: .get)
                .validate()
                .responseData { (response) in
                    switch response.result {
                    case .success:
                        print(response.data!)
                    case .failure(let error):
                        print(error)
                    }
            }
        }
    }
}

