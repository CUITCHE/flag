//
//  main.swift
//  Flag
//
//  Created by hejunqiu on 2017/11/28.
//  Copyright © 2017年 hejunqiu. All rights reserved.
//

import Foundation
var bbb = 35
print(bbb, withUnsafeBytes(of: &bbb, { return $0 }))
try? bbb.set(str: "764")
print(bbb, withUnsafeBytes(of: &bbb, { return $0 }))
