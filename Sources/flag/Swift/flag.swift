//
//  flag.swift
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/7/10.
//  Copyright © 2017年 CHE. All rights reserved.
//

import Foundation

fileprivate protocol Value {

    /// 返回值的string形式，要求返回的string能转换成值
    var string: String { get }

    /// 用string设置值
    ///
    /// - Parameter str: 值的string形式
    /// - Returns: optional类型，如果改string不能匹配到值，则返回一个字符串表示出错。
    func set(str: String) -> String?

    func set(str: Substring) -> String?
}

extension Value {
    func set(str: Substring) -> String? {
        return set(str: String(str))
    }
}


public struct Flag {
    fileprivate static var identifier = 0
    fileprivate let id: Int = {
        defer {
            Flag.identifier += 1
        }
        return Flag.identifier
    }()
    let name: String
    let usage: String
    fileprivate var value: Value
    fileprivate let defValue: String

    var isBoolFlag: Bool {
        return value is _Bool
    }

    static func unquoteUsage(flag: Flag) -> (name: String, usage: String) {
        let usage = flag.usage
        let first = usage.range(of: "`")
        let second = usage.range(of: "`", options: .backwards, range: usage.startIndex..<usage.endIndex, locale: nil)
        if let first = first, let second = second, first.lowerBound != second.lowerBound {
            let name = usage[usage.index(after: first.lowerBound)..<usage.index(usage.index(after: first.lowerBound), offsetBy: second.lowerBound.encodedOffset - first.lowerBound.encodedOffset)]
            let usageNew = usage[..<first.lowerBound] + name + usage[usage.index(after: second.lowerBound)...]
            return (name: String(name), usage: String(usageNew))
        }
        var name = "value"
        if flag.value is _Bool {
            name = ""
        } else if flag.value is _Integer {
            name = "int"
        } else if flag.value is _Float {
            name = "float"
        } else if flag.value is _String {
            name = "string"
        }

        return (name: name, usage: usage as String)
    }
}

public typealias __bool = Bool

fileprivate class _Bool: Value {
    var val: UnsafeMutablePointer<__bool>

    init(booleanLiteral value: Bool) {
        self.val = UnsafeMutablePointer<__bool>.allocate(capacity: MemoryLayout<__bool>.size)
        self.val.initialize(to: value)
    }

    deinit {
        val.deinitialize()
        val.deallocate(capacity: MemoryLayout<__bool>.size)
    }

    fileprivate func set(str: String) -> String? {
        if let b = Bool(str) {
            val.pointee = b
        } else {
            return "invalid syntax"
        }
        return nil
    }

    var string: String {
        return val.pointee ? "true" : "false"
    }
}

fileprivate class _Integer: Value {
    var val: UnsafeMutablePointer<Int64>
    init(value: Int64) {
        self.val = UnsafeMutablePointer<Int64>.allocate(capacity: MemoryLayout<Int64>.size)
        self.val.initialize(to: value)
    }

    deinit {
        val.deinitialize()
        val.deallocate(capacity: MemoryLayout<Int64>.size)
    }

    func set(str: String) -> String? {
        if let val = Int64(str) {
            self.val.pointee = val
        } else {
            return "invalid syntax"
        }
        return nil
    }

    var string: String {
        return String(self.val.pointee)
    }
}

fileprivate class _Float: Value {
    var val: UnsafeMutablePointer<Double>

    init(value: Double) {
        self.val = UnsafeMutablePointer<Double>.allocate(capacity: MemoryLayout<Double>.size)
        self.val.initialize(to: value)
    }

    deinit {
        val.deinitialize()
        val.deallocate(capacity: MemoryLayout<Double>.size)
    }

    func set(str: String) -> String? {
        if let val = Double(str) {
            self.val.pointee = val
        } else {
            return "invalid syntax"
        }
        return nil
    }

    var string: String {
        return String(self.val.pointee)
    }
}

fileprivate class _String: Value {
    var val: UnsafeMutablePointer<String>

    init(value: String) {
        self.val = UnsafeMutablePointer<String>.allocate(capacity: MemoryLayout<String>.size)
        self.val.initialize(to: value)
    }

    deinit {
        val.deinitialize()
        val.deallocate(capacity: MemoryLayout<String>.size)
    }

    func set(str: String) -> String? {
        self.val.pointee = str
        return nil
    }

    var string: String {
        return self.val.pointee
    }
}

public struct FlagSet {
    let name: String
    fileprivate var parsed = false
    fileprivate var formal = [String: Flag]()
    fileprivate var actual = [String: Flag]()
    var args: [String]
    var output: UnsafeMutablePointer<FILE>? = nil
    init() {
        var argv = CommandLine.arguments
        let name = argv.removeFirst()
        self.name = name.components(separatedBy: "/").last ?? ""
        self.args = argv
    }
}

fileprivate extension FlagSet {
    func out() -> UnsafeMutablePointer<FILE> {
        if self.output == nil {
            return stderr
        }
        return self.output!
    }

    mutating func bindVariable(value: Value, name: String, usage: String) {
        if formal.index(forKey: name) != nil {
            var msg: String
            if self.name.isEmpty {
                msg = "flag redefined: \(name)"
            } else {
                msg = "\(self.name) flag redefined: \(name)"
            }
            putln(text: msg)
        }
        let flag = Flag.init(name: name, usage: usage, value: value, defValue: value.string)
        formal[name] = flag
    }

    mutating func Bool(value: Bool, name: String, usage: String) -> UnsafePointer<__bool> {
        let bool = _Bool.init(booleanLiteral: value)
        self.bindVariable(value: bool, name: name, usage: usage)
        return UnsafePointer<__bool>(bool.val)
    }

    mutating func Integer(value: Int64, name: String, usage: String) -> UnsafePointer<Int64> {
        let integer = _Integer.init(value: value)
        self.bindVariable(value: integer, name: name, usage: usage)
        return UnsafePointer<Int64>(integer.val)
    }

    mutating func Float(value: Double, name: String, usage: String) -> UnsafePointer<Double> {
        let float = _Float.init(value: value)
        self.bindVariable(value: float, name: name, usage: usage)
        return UnsafePointer<Double>(float.val)
    }

    mutating func string(value: String, name: String, usage: String) -> UnsafePointer<String> {
        let string = _String.init(value: value)
        self.bindVariable(value: string, name: name, usage: usage)
        return UnsafePointer<String>(string.val)
    }


    mutating func parse() {
        self.parsed = true
        while true {
            let (seen, error) = self.parseOne()
            if seen {
                continue
            }
            if error == nil {
                break
            }
            putln(text: error!)
            exit(2)
        }
    }

    mutating func parseOne() -> (Bool, String?) {
        if args.isEmpty {
            return (false, nil)
        }

        let s = args[0]
        if s.count == 0 || s[s.startIndex] != "-" || s.count == 1 {
            return (false, "Unknown identifier: \(s)")
        }

        var numMinuses = 1
        if s[s.index(after: s.startIndex)] == "-" {
            if s.count == 2 {
                args.removeFirst()
                return (false, nil)
            }
            numMinuses += 1
        }

        var name = s[s.index(s.startIndex, offsetBy: numMinuses)...]
        if name.isEmpty || name[name.startIndex] == "-" || name[name.startIndex] == "=" {
            return (false, "bad flag syntax: \(s)")
        }

        args.removeFirst()
        var hasValue = false
        var value: Substring = ""
        for (i, ch) in name.dropFirst().enumerated() {
            if ch == "=" {
                hasValue = true
                value = name[name.index(name.startIndex, offsetBy: i + 1 + 1)...]
                name = name[...name.index(name.startIndex, offsetBy: i)]
                break
            }
        }
        let flag = formal[String(name)]
        if let flag = flag {
            if flag.isBoolFlag { // special case: doesn't need an arg
                if hasValue {
                    if let err = flag.value.set(str: value) {
                        return (false, "invalid boolean value \(value) for -\(name): \(err)")
                    }
                } else {
                    if let err = flag.value.set(str: "true") {
                        return (false, "invalid boolean value for -\(name): \(err)")
                    }
                }
            } else {
                // It must have a value, which might be the next argument.
                if hasValue == false && args.count > 0 {
                    hasValue = true
                    value = args.first![...]
                    args.removeFirst()
                }
                if hasValue == false {
                    return (false, "flag needs an argument: -\(name)")
                }
                if let err = flag.value.set(str: value) {
                    return (false, "invalid value \(value) for flag -\(name): \(err)");
                }
            }
        } else {
            if name == "help" || name == "h" { // special case for nice help message.
                self.usage()
                exit(0)
            }
            return (false, "flag provided but not defined: -\(name)")
        }
        actual[String(name)] = flag
        return (true, nil)
    }
}

public extension FlagSet {
    fileprivate func usage() {
        defaultUsage()
    }

    public func defaultUsage() {
        if name.isEmpty {
            putln(text: "Usage:")
        } else {
            putln(text: "Usage of \(name):")
        }
        printDefault()
    }

    public func printDefault() {
        self.visitAll { (flag) in
            let name = "  -\(flag.name)" // Two spaces before -; see next two comments.
            var s = ""
            let info = Flag.unquoteUsage(flag: flag)
            if info.name.isEmpty == false {
                s += " " + info.name
            }
            // Boolean flags of one ASCII letter are so common we
            // treat them specially, putting their usage on the same line.
            if s.count + name.count <= 4 {
                s += "\t"
            } else {
                // Four spaces before the tab triggers good alignment
                // for both 4- and 8-space tab stops.
                s += "\n    \t"
            }
            s += info.usage
            if isZeroValue(flag: flag, value: flag.defValue) == false {
                if flag.value is _String {
                    s += " (default \"\(flag.defValue)\")"
                } else {
                    s += " (default \(flag.defValue))"
                }
            }
            s += "\n"
            print(colorText: name, otherText: s)
        }
    }

    public func visitAll(fn: (_ flag: Flag) -> Void) {
        let values = formal.values.sorted { $0.id < $1.id }
        for flag in values {
            fn(flag)
        }
    }

    fileprivate func putln(text: String) {
        fputs("\(text)\n", stderr)
    }

    fileprivate func print(colorText: String, otherText: String) {
        fputs("\u{001b}[0;1m\(colorText)\u{001b}[0m\(otherText)\n", stderr)
    }

    fileprivate func isZeroValue(flag: Flag, value: String) -> Bool {
        // Build a zero value of the flag's Value type, and see if the
        // result of calling its String method equals the value passed in.
        // This works unless the Value type is itself an interface type.
        switch value {
        case "false":
            return true
        case "":
            return true
        case "0":
            return true
        default:
            return false
        }
    }
}


fileprivate var FlagCommandLine = FlagSet.init()

public class flag {

    public static func Bool(name: String, defValue: Bool, usage: String) -> UnsafePointer<__bool> {
        return FlagCommandLine.Bool(value: defValue, name: name, usage: usage)
    }

    public static func Integer(name: String, defValue: Int64, usage: String) -> UnsafePointer<Int64> {
        return FlagCommandLine.Integer(value: defValue, name: name, usage: usage)
    }

    public static func Float(name: String, defValue: Double, usage: String) -> UnsafePointer<Double> {
        return FlagCommandLine.Float(value: defValue, name: name, usage: usage)
    }

    public static func String(name: String, defValue: String, usage: String) -> UnsafePointer<String> {
        let str = FlagCommandLine.string(value: defValue, name: name, usage: usage)
        return str
    }

    public static func parse() {
        FlagCommandLine.parse()
    }

    public static func parsed() -> Bool {
        return FlagCommandLine.parsed
    }

    public static var executedPath: String {
        get {
            return CommandLine.arguments.first ?? ""
        }
    }
}
