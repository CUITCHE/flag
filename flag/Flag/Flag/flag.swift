//
//  flag.swift
//  Flag
//
//  Created by hejunqiu on 2017/11/28.
//  Copyright © 2017年 hejunqiu. All rights reserved.
//

import Foundation

public enum ParseNumberError: Error {
    case error(String)
}

public protocol FlagValue {
    /// 返回值的string形式，要求返回的string能转换成值
    func string() -> String

    /// 用string设置值
    ///
    /// - Parameter str: 值的string形式
    /// - Returns: optional类型，如果改string不能匹配到值，则返回一个字符串表示出错。
    mutating func set(str: String) throws

    mutating func set(str: Substring) throws
}

extension FlagValue {
    mutating public func set(str: Substring) throws {
        try set(str: String(str))
    }

    public func string() -> String {
        return "\(self)"
    }
}

extension Bool: FlagValue {
    mutating public func set(str: String) throws {
        guard let val = Bool(str) else {
            throw ParseNumberError.error("Invalid syntax")
        }
        self = val
    }
}

extension Int: FlagValue {
    mutating public func set(str: String) throws {
        guard let val = Int(str) else {
            throw ParseNumberError.error("Invalid syntax")
        }
        self = val
    }
}

extension UInt: FlagValue {
    mutating public func set(str: String) throws {
        guard let val = UInt(str) else {
            throw ParseNumberError.error("Invalid syntax")
        }
        self = val
    }
}

extension Float: FlagValue {
    mutating public func set(str: String) throws {
        guard let val = Float(str) else {
            throw ParseNumberError.error("Invalid syntax")
        }
        self = val
    }
}

extension Double: FlagValue {
    mutating public func set(str: String) throws {
        guard let val = Double(str) else {
            throw ParseNumberError.error("Invalid syntax")
        }
        self = val
    }
}

extension String: FlagValue {
    mutating public func set(str: String) throws {
        self = str
    }
}

public class Flag {
    public let name: String
    public let shortName: String
    public var value: FlagValue { return _value }
    public let usage: String
    public let defaulValue: String
    public let expectedValues: [FlagValue]
    public let valueTypeAliasName: String

    var _value: FlagValue
    var _changed = false

    init(name: String, shortName: String?, usage: String, defaultValue: FlagValue, expectedValues: [FlagValue], valueTypeAliasName: String = "") {
        self.name = name
        self.shortName = shortName ?? ""
        self.usage = usage
        self._value = defaultValue
        self.defaulValue = defaultValue.string()
        self.expectedValues = expectedValues
        self.valueTypeAliasName = valueTypeAliasName
    }
}

public class Command {
    public typealias Action = (_ args: [Flag]) -> Void
    public let name: String
    public let usage: String

    var flags = [Flag]()
    let action: Action

    init(name: String, usage: String, action: @escaping Action) {
        self.name = name
        self.usage = usage
        self.action = action
    }

    public func bindFlag(with defValue: FlagValue, name: String, usage: String, shortName: String? = nil, expectedValues: [FlagValue], valueTypeAliasName: String = "") {
        guard let _ = flags.index(where: { return $0.name == name }) else {
            print("flag(\(name)) has existed! Please check your code.")
            exit(-1)
        }
        if let shortName = shortName {
            guard shortName.count == 1 else {
                print("The length of flag short name must be 1.")
                exit(-1)
            }
            guard let _ = flags.index(where: { return !$0.shortName.isEmpty && $0.shortName == shortName }) else {
                print("flag short(\(shortName)) has existed! Please check your code.")
                exit(-1)
            }
        }
        let flag = Flag(name: name, shortName: shortName, usage: usage, defaultValue: defValue, expectedValues: expectedValues, valueTypeAliasName: valueTypeAliasName)
        flags.append(flag)
    }
}

class RootCommand: Command {
    var args: [String]
    var commands = [Command]()
    var parsed = false

    init() {
        var argv = CommandLine.arguments
        self.args = argv
        let name = argv.removeFirst().components(separatedBy: "/").last ?? "Unknown"
        super.init(name: name, usage: "") { flags in
            //
        }
    }

    func bindCommand(with name: String, usage: String, action: @escaping Command.Action) -> Command {
        guard let _ = commands.index(where: { return $0.name == name }) else {
            print("Command(\(name)) has existed! Please check your code.")
            exit(-1)
        }
        let command = Command(name: name, usage: usage, action: action)
        commands.append(command)
        return command
    }

    func parse() {
        guard parsed == false else { return }
        parsed = true
    }
}

private let root = RootCommand()

public struct flag {
    public static var version = "1.0.0"

    public static func addCommand(with name: String, action: @escaping Command.Action) -> Command {
        return root.bindCommand(with: name, usage: "", action: action)
    }

    public static func addFlag(with defValue: FlagValue, name: String, usage: String, expectedValues: [FlagValue], shortName: String? = nil, valueTypeAliasName: String = "") {
        root.bindFlag(with: defValue, name: name, usage: usage, shortName: shortName, expectedValues: expectedValues, valueTypeAliasName: valueTypeAliasName)
    }

    public static func parse() {
        root.parse()
    }
}
