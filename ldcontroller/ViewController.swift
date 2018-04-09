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

class ViewController: UIViewController {
    
    @IBOutlet weak var btEdit: UIButton!
    @IBOutlet weak var btPower: UIButton!
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
    @IBOutlet weak var btKeyboard: UIButton!
    @IBOutlet weak var tfHolder: UITextField!
    
    let coachMarksController = CoachMarksController()
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        gestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(gestureRecognizer)
        tfHolder.delegate = self
        coachMarksController.dataSource = self
        coachMarksController.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(capsChange), name: NSNotification.Name.UITextInputCurrentInputModeDidChange, object: nil)
    }
    
    @objc func capsChange(){
        print("caps")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let showGuideView: Bool = UserDefaults.standard.bool(forKey: "ShowGuideView")
        if(!showGuideView){
            self.coachMarksController.start(on: self)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.coachMarksController.stop(immediately: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func setIP(){
        let localIp = getLocalIPAddressForCurrentWiFi()
        let alertView = UIAlertController.init(title: "Setting", message: "", preferredStyle: .alert)
        let confirmAction = UIAlertAction.init(title: "Confirm", style: .default, handler: {action in
            for textField in alertView.textFields!{
                if let ip = textField.text{
                    print(ip)
                    UserDefaults.standard.set(ip, forKey: "IPAddress")
                }
            }
        })
        let cancelAction = UIAlertAction.init(title: "Cancel", style: .cancel, handler: {action in
            
        })
        alertView.addTextField(configurationHandler: {textField in
            textField.keyboardType = .numbersAndPunctuation
            textField.keyboardAppearance = .alert
            textField.placeholder = "type in ip"
            if let ip = UserDefaults.standard.string(forKey: "IPAddress"){
                textField.text = ip
            }else{
                if localIp != nil {
                    textField.text = localIp
                }
            }
        })
        alertView.addAction(confirmAction)
        alertView.addAction(cancelAction)
        self.present(alertView, animated: true, completion: nil)
    }
    
    @IBAction func clickButton(button: UIButton){
        AudioServicesPlaySystemSound(1105)
        switch button {
        case btPower:
            sendCommand(26)
        case btUp:
            sendCommand(19)
        case btDown:
            sendCommand(20)
        case btLeft:
            sendCommand(21)
        case btRight:
            sendCommand(22)
        case btOK:
            sendCommand(23)
        case btVolUp:
            sendCommand(24)
        case btVolDown:
            sendCommand(25)
        case btHome:
            sendCommand(3)
        case btBack:
            sendCommand(4)
        case btApps:
            sendCommand(262)
        default:
            print("default")
        }
    }
    
    @IBAction func clickKeyboard(){
        tfHolder.becomeFirstResponder()
    }
    
    @objc func hideKeyboard(){
        tfHolder.resignFirstResponder()
    }

    
    func getLocalIPAddressForCurrentWiFi() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        guard getifaddrs(&ifaddr) == 0 else {
            return nil
        }
        guard let firstAddr = ifaddr else {
            return nil
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



extension ViewController: CoachMarksControllerDataSource, CoachMarksControllerDelegate{
    
    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        return 1
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkAt index: Int) -> CoachMark {
        return coachMarksController.helper.makeCoachMark(for: btEdit, pointOfInterest: nil, cutoutPathMaker: nil)
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkViewsAt index: Int, madeFrom coachMark: CoachMark) -> (bodyView: CoachMarkBodyView, arrowView: CoachMarkArrowView?) {
        let coachViews = coachMarksController.helper.makeDefaultCoachViews(withArrow: true, arrowOrientation: coachMark.arrowOrientation)
        coachViews.bodyView.hintLabel.text = "Click to set IP address"
        coachViews.bodyView.nextLabel.text = "Got it"
        return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, didEndShowingBySkipping skipped: Bool) {
        UserDefaults.standard.set(true, forKey: "ShowGuideView")
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

