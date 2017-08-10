//
//  main.cpp
//  flag
//
//  Created by hejunqiu on 2017/7/14.
//  Copyright © 2017年 hejunqiu. All rights reserved.
//

#include "Flag.hpp"
#include <iostream>

using namespace std;

int main(int argc, const char * argv[]) {
    Flag::InitialCommandLine(argc, argv);
    auto host = Flag::String("h", "localhost", "Server host string");
    auto port = Flag::Integer("p", 1234, "Network port(TCP)");
    auto race = Flag::Float("race", 0, "Test the float value");
    auto logg = Flag::Bool("log", false, "show the log");
    Flag::Parse();
    cout << "connect to " << *host << ":" << *port << " with race " << *race << ". Show log?:" << *logg << endl;
    return 0;
}
