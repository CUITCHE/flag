# flag
flag is a tool: parse command-line parameters.

Provide two program language: Swift and C++.

# Usage

**In Swift**

```swift
let host = flag.String(name: "h", defValue: "localhost", usage: "Server host string")
let port = flag.Integer(name: "p", defValue: 1234, usage: "Network port(TCP)")
let race = flag.Float(name: "race", defValue: 0, usage: "Test the float value")
let logg = flag.Bool(name: "log", defValue: false, usage: "show the log")

flag.parse()

print("connect to \(host.pointee):\(port.pointee) with race \(race.pointee). Show log?:\(logg.pointee)")
```

Assume we input:

`./flag-swift -h=www.github.com -p 9009 -race=32.9744445567 -log`

And then we get the output:

`connect to www.github.com:9009 with race 32.9744445567. Show log?:true`

**In C++**

```c++
Flag::InitialCommandLine(argc, argv);
    auto host = Flag::String("h", "localhost", "Server host string");
    auto port = Flag::Integer("p", 1234, "Network port(TCP)");
    auto race = Flag::Float("race", 0, "Test the float value");
    auto logg = Flag::Bool("log", false, "show the log");
    Flag::Parse();
    cout << "connect to " << *host << ":" << *port << " with race " << *race << ". Show log?:" << *logg << endl;
```

Assume we input:

`./flag-swift -h=www.github.com -p 9009 -race=32.9744445567 -log`

And then we get the output:

`connect to www.github.com:9009 with race 32.9744. Show log?:1`

*The key-value may be `-key=value` or `-key value`. Especially for bool value, `-key` represents true.*

**Default Key**

-help print flag your set help information. For demo's help info is:

```
Usage of flag-cpp:
  -h string
    	Server host string (default "localhost")
  -p int
    	Network port(TCP) (default 1234)
  -race float
    	Test the float value (default 0.0)
  -log
    	show the log
```



# LICENSE

The MIT LICENSE.