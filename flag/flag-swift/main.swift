//
//  main.swift
//  flag-swift
//
//  Created by hejunqiu on 2017/8/10.
//  Copyright © 2017年 hejunqiu. All rights reserved.
//

import Foundation

let host = flag.String(name: "h", defValue: "localhost", usage: "Server host string")
let port = flag.Integer(name: "p", defValue: 1234, usage: "Network port(TCP)");

flag.parse()
print("connect to \(host.pointee):\(port.pointee)")
