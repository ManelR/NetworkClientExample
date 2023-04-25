//
//  ViewController.swift
//  Network Client Example
//
//  Created by Manel Roca on 21/4/23.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        Task {
            let client = HTTPClient(session: .shared)
            let request = URLRequest(url: URL(string: "https://dummyjson.com/products")!)
            let result = try await client.send(request: request)
            print("Result - \(result)")
        }
        
    }


}

