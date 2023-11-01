//
//  ViewController.swift
//  HTTPSwiftExample
//
//  Created by Eric Larson on 3/30/15.
//  Copyright (c) 2015 Eric Larson. All rights reserved.
//

// This exampe is meant to be run with the python example:
//              tornado_example.py 
//              from the course GitHub repository: tornado_bare, branch turi_create_examples



import UIKit

class ViewController: UIViewController, URLSessionDelegate {
    
    //MARK: Properties
    var floatValue = 5.5
    let operationQueue = OperationQueue()
    
    //MARK: View Outlets
    @IBOutlet weak var mainTextView: UITextView!
    @IBOutlet weak var ipAddressTextView: UITextField!
    
    //MARK: Lazy Computed Properties
    lazy var animation = {
        let tmp = CATransition()
        // create reusable animation, for updating the server
        tmp.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        tmp.type = CATransitionType.reveal
        tmp.duration = 0.5
        return tmp
    }()
    
    lazy var SERVER_URL = {
        //setup default server IP (if not entered by user)
        let default_ip = "10.9.191.61"
        let tmp = "http://\(default_ip):8000"
        
        DispatchQueue.main.async {
            self.ipAddressTextView.text = default_ip
        }
        
        return tmp
    }()
    
    lazy var session = {
        let sessionConfig = URLSessionConfiguration.ephemeral
        
        sessionConfig.timeoutIntervalForRequest = 5.0
        sessionConfig.timeoutIntervalForResource = 8.0
        sessionConfig.httpMaximumConnectionsPerHost = 1
        
        let tmp = URLSession(configuration: sessionConfig,
            delegate: self,
            delegateQueue:self.operationQueue)
        
        return tmp
        
    }()
    
    
    //MARK: View Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // be the delegate for this text field
        self.ipAddressTextView.delegate = self
        
        
    }
    

    //MARK: Get Request
    @IBAction func sendGetRequest(_ sender: AnyObject) {
        // create a GET request and get the reponse back as NSData
        let baseURL = "\(SERVER_URL)/GetExample"
        let query = "?arg=\(self.floatValue)"
        
        let getUrl = URL(string: "\(baseURL)\(query)")
        let request: URLRequest = URLRequest(url: getUrl!)
        let dataTask : URLSessionDataTask = self.session.dataTask(with: request,
            completionHandler:{(data, response, error) in
            
                // TODO: handle error!
                print("Response:\n\(response!)")
                let strData = String(data:data!, encoding:String.Encoding(rawValue: String.Encoding.utf8.rawValue))
                
                self.displayMainTextView(response: response!,
                                         strData: strData!)
        })
        
        dataTask.resume() // start the task
        
    }
    
    //MARK: Post Request, args as string in data
    @IBAction func sendPostRequest(_ sender: AnyObject) {
        
        let baseURL = "\(SERVER_URL)/DoPost"
        let postUrl = URL(string: "\(baseURL)")
        
        // create a custom HTTP POST request
        var request = URLRequest(url: postUrl!)
        
        // data to send in body of post request (style of get arguments)
        let requestBody:Data? = "arg1=\(self.floatValue)".data(using: String.Encoding.utf8, allowLossyConversion: false)
        
        request.httpMethod = "POST"
        request.httpBody = requestBody
        
        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
            completionHandler:{(data, response, error) in
                // TODO: handle error!
                print("Response:\n\(response!)")
                let jsonDictionary = self.convertDataToDictionary(with: data)
                print("\n\nJSON Data:\n%@",jsonDictionary)
                
                self.displayMainTextView(response: response!,
                                         strData: jsonDictionary)

        })
        
        postTask.resume() // start the task
    }
    
    //MARK: Post Request, args in request body (preferred)
    @IBAction func sendPostWithJsonInBody(_ sender: AnyObject) {
        
        let baseURL = "\(SERVER_URL)/PostWithJson"
        let postUrl = URL(string: "\(baseURL)")
        
        // create a custom HTTP POST request
        var request = URLRequest(url: postUrl!)
        
        // data to send in body of post request (send arguments as json)
        let jsonUpload:NSDictionary = [
            "arg": [3.2,self.floatValue*2,self.floatValue],
            "arg2":["CoronaVirus","NO",2021] as [Any],
            "arg3":["EricLarson","YES",2022] as [Any]
        ]
        
        // utility method to use from below
        let requestBody:Data? = self.convertDictionaryToData(with:jsonUpload)
    
        request.httpMethod = "POST"
        request.httpBody = requestBody
        
        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
                        completionHandler:{(data, response, error) in
            print("Response:\n%@",response!)
            let jsonDictionary = self.convertDataToDictionary(with: data)
            print("\n\nJSON Data:\n%@",jsonDictionary)
                            
            self.displayMainTextView(response: response!,
                                     strData: jsonDictionary)

        })
        
        postTask.resume() // start the task
        
    }

}


//MARK: TextFieldDelegate methods
// if you do not know your local sharing server name try:
//    ifconfig |grep inet
// to see what your public facing IP address is, the ip address can be used here
extension ViewController: UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let ip = textField.text{
            // make sure ip is formatted correctly
            if matchIp(for:"((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\\.|$)){4}", in: ip){
                SERVER_URL = "http://\(ip):8000"
                print(SERVER_URL)
            }else{
                print("invalid ip entered")
            }
            
        }
        textField.resignFirstResponder()
        return true
    }
    
    func matchIp(for regex:String, in text:String)->(Bool){
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            if results.count > 0{return true}
            
        } catch _{
            return false
        }
        return false
    }
}


//MARK: Utility Extending Functions
extension ViewController {
    
    func displayMainTextView(response:Any, strData:Any){
        // convenience function meant for displaying the response and the
        // extra argument data from an HTTP request completion
        DispatchQueue.main.async{
            self.mainTextView.layer.add(self.animation, forKey: nil)
            self.mainTextView.text = "\(response) \n==================\n\(strData)"
        }
    }
    
    func convertDictionaryToData(with jsonUpload:NSDictionary) -> Data?{
        // convenience function for serialiing an NSDictionary
        do { // try to make JSON and deal with errors using do/catch block
            let requestBody = try JSONSerialization.data(withJSONObject: jsonUpload, options:JSONSerialization.WritingOptions.prettyPrinted)
            return requestBody
        } catch {
            print("json error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func convertDataToDictionary(with data:Data?)->NSDictionary{
        // convenience function for getting Dictionary from server data
        do { // try to parse JSON and deal with errors using do/catch block
            let jsonDictionary: NSDictionary =
                try JSONSerialization.jsonObject(with: data!,
                                              options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            
            return jsonDictionary
            
        } catch {
            print("json error: \(error.localizedDescription)")
            if let strData = String(data:data!, encoding:String.Encoding(rawValue: String.Encoding.utf8.rawValue)){
                print("printing JSON received as string: "+strData)
            }
            return NSDictionary() // just return empty
        }
    }
}



