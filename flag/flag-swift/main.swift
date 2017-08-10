//
//  main.swift
//  flag-swift
//
//  Created by hejunqiu on 2017/8/10.
//  Copyright © 2017年 hejunqiu. All rights reserved.
//

import Foundation

let host = flag.String(name: "h", defValue: "localhost", usage: "Server host string")
let port = flag.Integer(name: "p", defValue: 1234, usage: "Network port(TCP)")
let race = flag.Float(name: "race", defValue: 0, usage: "Test the float value")
let logg = flag.Bool(name: "log", defValue: false, usage: "show the log")

flag.parse()

print("connect to \(host.pointee):\(port.pointee) with race \(race.pointee). Show log?:\(logg.pointee)")
