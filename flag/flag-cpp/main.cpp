//
//  main.cpp
//  flag
//
//  Created by hejunqiu on 2017/7/14.
//  Copyright © 2017年 hejunqiu. All rights reserved.
//

#include <stdio.h>
#include <cassert>
#include <sstream>
#include "Flag.hpp"

using namespace std;

int main(int argc, const char * argv[]) {
    Flag::InitialCommandLine(argc, argv);
    auto n = Flag::Bool("n", false, "omit trailing newline");
    auto sep = Flag::String("s", " ", "separator");
    auto f = Flag::Float("f", 0, "Float test");
    auto i = Flag::Integer("i", 0, "Integer test");
    Flag::Parse();
    printf("-n %s\n", *n ? "true" : "false");
    printf("-s %s\n", sep->c_str());
    printf("-f %f\n", *f);
    printf("-i %lld\n", *i);

    return 0;
}
