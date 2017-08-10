//
//  Flag.hpp
//  flag
//
//  Created by hejunqiu on 2017/7/14.
//  Copyright © 2017年 hejunqiu. All rights reserved.
//

#ifndef FLAG_H
#define FLAG_H

#include <string>

using std::string;

namespace Flag {
    extern void InitialCommandLine(int argc, const char **argv);
    extern void Parse();

    extern const bool* Bool(const string &name, bool defValue, const string &usage);

    extern const long long* Integer(const string &name, long long defValue, const string &usage);

    extern const double* Float(const string &name, double defValue, const string &usage);

    extern const string* String(const string &name, const string &defValue, const string &usage);
}

#endif /* FLAG_H */
