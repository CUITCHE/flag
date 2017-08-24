//
//  Flag.cpp
//  flag
//
//  Created by hejunqiu on 2017/7/14.
//  Copyright © 2017年 hejunqiu. All rights reserved.
//

#include "Flag.hpp"
#include <string>
#include <memory>
#include <tuple>
#include <cassert>
#include <sstream>
#include <unordered_map>
#include <vector>
#include <functional>

using namespace std;

#define let const auto
#define var auto

#define FLAG_NAMESPACE_BEGIN namespace Flag {
#define FLAG_NAMESPACE_END }

#define FLAG_PRIVATE_NAMESPACE_BEGIN namespace Flag_Private {
#define FLAG_PRIVATE_NAMESPACE_END }

FLAG_NAMESPACE_BEGIN

static stringstream ss;

FLAG_PRIVATE_NAMESPACE_BEGIN
struct proto_value {
    enum clazz_type {
        Base,
        Bool,
        Integer,
        Float,
        String
    };
    virtual shared_ptr<string> set(const string &str) { return nullptr; }
    virtual string string() const { return ""; }
    virtual clazz_type type() const { return Base; }
};

struct Flag {
    static int identifier;
    const int id;
    unique_ptr<proto_value> value;
    const string name;
    const string usage;
    const string defValue;

    Flag(const Flag &other)
    :id(other.id), value(make_unique<proto_value>(*other.value)), name(other.name), usage(other.usage),defValue(other.defValue)
    {}

    Flag(Flag &&other)
    :id(other.id), value(std::move((other.value))), name(std::move(other.name)), usage(std::move(other.usage)),defValue(std::move(other.defValue))
    {}

    Flag(const string &name, const string &usage, const string &defValue, proto_value *value)
    :id(++identifier), name(name), usage(usage),defValue(defValue)
    {
        this->value.reset(value);
    }

    bool isBoolFlag() const {
        return value->type() == proto_value::Bool;
    }

    static tuple<string, string> unquoteUsage(const Flag& flag) {
        const string &usage = flag.usage;
        auto first = usage.find('`');
        if (first != string::npos) {
            auto second = usage.find('`', first + 1);
            if (second != string::npos) {
                string name = usage.substr(first + 1, second - first - 1);
                string usageNew = usage.substr(0, first) + name + usage.substr(second + 1);
                return tie(name, usageNew);
            }
        }
        string name = "value";
        switch (flag.value->type()) {
            case proto_value::Base:
                break;
            case proto_value::Bool:
                name = "";
                break;
            case proto_value::Integer:
                name = "int";
                break;
            case proto_value::Float:
                name = "float";
                break;
            case proto_value::String:
                name = "string";
                break;
            default:
                assert(false && "Unknown value type");
                break;
        }
        return tie(name, usage);
    }
};

int Flag::identifier = 0;

struct Bool: public proto_value {
    bool actual;

    Bool(bool val): actual(val) { }

    virtual shared_ptr<std::string> set(const std::string &str) override {
        if (str == "true") {
            actual = true;
        } else if (str == "false") {
            actual = false;
        } else {
            return make_shared<std::string>("invalid syntax. Bool value only accept: `true` or `false`.");
        }
        return nullptr;
    }
    virtual std::string string() const override  { return actual ? "true" : "false"; }
    virtual clazz_type type() const override { return proto_value::Bool; }
};

struct Integer: public proto_value {
    long long actual;

    Integer(long long val): actual(val) { }

    virtual shared_ptr<std::string> set(const std::string &str) override {
        ss.clear();
        ss.str(str);
        ss >> actual;
        return nullptr;
    }
    virtual std::string string() const override  {
        ss.clear();
        ss.str("");
        ss << actual;
        return ss.str();
    }
    virtual clazz_type type() const override { return proto_value::Integer; }
};

struct Float: public proto_value {
    double actual;

    Float(double val): actual(val) { }

    virtual shared_ptr<std::string> set(const std::string &str) override {
        ss.clear();
        ss.str(str);
        ss >> actual;
        return nullptr;
    }
    virtual std::string string() const override  {
        if (actual == 0) {
            return "0.0";
        }
        ss.clear();
        ss.str("");
        ss << actual;
        return ss.str();
    }
    virtual clazz_type type() const override { return proto_value::Float; }
};

struct String: public proto_value {
    std::string actual;

    String(const std::string &val): actual(val) { }

    virtual shared_ptr<std::string> set(const std::string &str) override {
        actual = str;
        return nullptr;
    }
    virtual std::string string() const override  { return actual; }
    virtual clazz_type type() const override { return proto_value::String; }
};

struct FlagSet {
    const string name;
    bool parsed = false;
    unique_ptr<unordered_map<string, unique_ptr<Flag>>> formal = make_unique<decltype(formal)::element_type>();
    unique_ptr<vector<string>> args = make_unique<decltype(args)::element_type>();

    FlagSet(const string &name): name(name) { }

    template<class T>
    auto bindVariable(const T &val, const string &name, const string &usage) -> const decltype(T::actual)* {
        auto value = new T(val);
        auto iter = this->bind(value, name, usage);
        auto ptr = (T *)(iter->second->value.get());
        return &ptr->actual;
    }

    void parse() {
        parsed = true;
        for (;;) {
            auto ret = this->parseOne();
            if (get<0>(ret)) {
                continue;
            }
            if (get<1>(ret).length() == 0) {
                break;
            }
            println(get<1>(ret));
            exit(2);
        }
    }

    tuple<bool, string> parseOne() {
        if (args->empty()) {
            return make_tuple(false, "");
        }
        auto const &s = args->at(0);
        if (s.length() == 0 || s[0] != '-' || s.length() == 1) {
            return make_tuple(false, string("Unknown identifier: ").append(s));
        }

        size_t numMinuses = 1;
        if (s[1] == '-') {
            if (s.length() == 2) {
                args->erase(args->begin());
                return make_tuple(false, "");
            }
            ++numMinuses;
        }
        auto name = s.substr(numMinuses);
        if (name.length() == 0 || name[0] == '-' || name[0] == '=') {
            return make_tuple(false, string("bad flag syntax: ").append(s));
        }

        args->erase(args->begin());
        bool hasValue = false;
        string value = "";
        for (size_t i=1; i<name.length(); ++i) {
            if (name.at(i) == '=') {
                hasValue = true;
                value = name.substr(i + 1);
                name = name.substr(0, i);
                break;
            }
        }

        auto iter = formal->find(name);
        if (iter != formal->end()) {
            if (iter->second->isBoolFlag()) {
                if (hasValue) {
                    auto err = iter->second->value->set(value);
                    if (err) {
                        return make_tuple(false, string("invalid boolean value ").append(value).append(" for -").append(name).append(": ").append(*err));
                    }
                } else {
                    auto err = iter->second->value->set("true");
                    if (err) {
                        return make_tuple(false, string("invalid boolean value ").append("for -").append(name).append(": ").append(*err));
                    }
                }
            } else {
                if (!hasValue && args->size() > 0) {
                    hasValue = true;
                    value = args->front();
                    args->erase(args->begin());
                }
                if (!hasValue) {
                    return make_tuple(false, string("flag needs an argument: -").append(name));
                }
                auto err = iter->second->value->set(value);
                if (err) {
                    return make_tuple(false, string("invalid value ").append(value).append(" for flag -").append(name).append(": ").append(*err));
                }
            }
        } else {
            if (name == "help" || name == "h") {
                usage();
                exit(0);
            }
            return make_tuple(false, string("flag provided but not defined: -").append(name));
        }

        return make_tuple(true, "");
    }

    void defaultUsage() {
        if (name.length() == 0) {
            println("Usage:");
        } else {
            println(string("Usage of ").append(name).append(":"));
        }
        printDefault();
    }

    void printDefault() {
        visitAll([this] (const Flag &flag) {
            let name = string("  -").append(flag.name);
            var s = string("");
            let info = Flag::unquoteUsage(flag);
            if (get<0>(info).length() > 0) {
                s += " " + get<0>(info);
            }
            if (s.length() + name.length() <= 4) {
                s += "\t";
            } else {
                s += "\n    \t";
            }
            s += get<1>(info);
            if (this->isZeroValue(flag, flag.defValue) == false) {
                if (flag.value->type() == proto_value::String) {
                    s += string(" (default \"").append(flag.defValue).append("\")");
                } else {
                    s += string(" (default ").append(flag.defValue).append(")");
                }
            }
            print(name, s);
        });
    }

    void visitAll(std::function<void(const Flag &flag)> callback) {
        vector<Flag *> flags(formal->size());
        transform(formal->begin(), formal->end(), flags.begin(), [](auto &pair) { return pair.second.get(); });
        sort(flags.begin(), flags.end(), [](const Flag *_1, const Flag *_2) { return _1->id < _2->id; });
        for (auto flag: flags) {
            callback(*flag);
        }
    }

private:
    decltype(formal)::element_type::iterator bind(proto_value *value, const string &name, const string &usage) const {
        if (formal->find(name) != formal->end()) {
            string msg;
            if (name.length() == 0) {
                msg.append("flag redefined: ").append(name);
            } else {
                msg.append(this->name).append(" flag redefined: ").append(name);
            }
            println(msg);
        }
        auto flag = make_unique<Flag>(name, usage, value->string(), value);
        return formal->emplace(name, std::move(flag)).first;
    }

    bool isZeroValue(const Flag &flag, const string &value) {
        if (value == "false") {
            return true;
        } else if (value == "") {
            return true;
        } else if (value == "0") {
            return true;
        } else {
            return false;
        }
    }

    void usage() {
        defaultUsage();
    }

private:
    int println(const string &text) const {
        return print("", text);
    }

    int print(const string &colorWords, const string &otherWords) const {
        return fprintf(stderr, "\033[0;1m%s\033[0m%s\n", colorWords.c_str(), otherWords.c_str());
    }
};

FLAG_PRIVATE_NAMESPACE_END

Flag_Private::FlagSet *CommandLine = nullptr;

void InitialCommandLine(int argc, const char **argv) {
    if (argc == 0 || CommandLine) {
        return;
    }
    string name(argv[0]);
    size_t pos = name.find_last_of('/');
    name = name.substr(pos + 1);
    CommandLine = new Flag_Private::FlagSet(name);
    for (int i=1; i<argc; ++i) {
        CommandLine->args->push_back(argv[i]);
    }
}

void Parse() {
    if (!CommandLine) {
        fprintf(stderr, "Please invoke `InitialCommandLine` before starting.");
        exit(-1);
    }
    CommandLine->parse();
}

const bool* Bool(const string &name, bool defValue, const string &usage) {
    if (!CommandLine) {
        fprintf(stderr, "Please invoke `InitialCommandLine` before starting.");
        exit(-1);
    }
    return CommandLine->bindVariable<Flag_Private::Bool>(defValue, name, usage);
}

const long long* Integer(const string &name, long long defValue, const string &usage) {
    if (!CommandLine) {
        fprintf(stderr, "Please invoke `InitialCommandLine` before starting.");
        exit(-1);
    }
    return CommandLine->bindVariable<Flag_Private::Integer>(defValue, name, usage);
}

const double* Float(const string &name, double defValue, const string &usage) {
    if (!CommandLine) {
        fprintf(stderr, "Please invoke `InitialCommandLine` before starting.");
        exit(-1);
    }
    return CommandLine->bindVariable<Flag_Private::Float>(defValue, name, usage);
}

const string* String(const string &name, const string &defValue, const string &usage) {
    if (!CommandLine) {
        fprintf(stderr, "Please invoke `InitialCommandLine` before starting.");
        exit(-1);
    }
    return CommandLine->bindVariable<Flag_Private::String>(defValue, name, usage);
}

FLAG_NAMESPACE_END
