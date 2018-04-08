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
        coachViews.bodyView.nextLabel.text = "Ok"
        return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, didEndShowingBySkipping skipped: Bool) {
        UserDefaults.standard.set(true, forKey: "ShowGuideView")
    }
    
}



extension ViewController: UITextFieldDelegate{
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        print(string)
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
                        let result = JSON(data: response.data!)
                        print(result)
                    case .failure(let error):
                        print(error)
                    }
            }
        }
    }
}

