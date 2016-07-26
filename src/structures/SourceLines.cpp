//
// Copyright (C) 2006-2007 Maciej Sobczak
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#include "SourceLines.h"
#include "Tokens.h"
#include "../plugins/Reports.h"
#include <vector>
#include <map>
#include <fstream>
#include <sstream>
#include <cstring>
#include <cerrno>


namespace // unnamed
{

typedef std::map<Vera::Structures::SourceFiles::FileName,
    Vera::Structures::SourceLines::LineCollection> SourceFileCollection;

SourceFileCollection sources_;

} // unnamed namespace


namespace Vera
{
extern bool gTransformPass;

namespace Structures
{

const SourceLines::LineCollection & SourceLines::getAllLines(const SourceFiles::FileName & name)
{
    const SourceFileCollection::const_iterator it = sources_.find(name);
    if (it != sources_.end())
    {
        return it->second;
    }
    else
    {
        // lazy load of the source file
        loadFile(name);
        return sources_[name];
    }
}

void SourceLines::loadFile(const SourceFiles::FileName & name)
{
    if (name == "-")
    {
        SourceLines::loadFile(std::cin, name);
    }
    else
    {
        std::ifstream file(name.c_str());
        if (file.is_open() == false)
        {
            std::ostringstream ss;
            ss << "Cannot open source file " << name << ": "
               << strerror(errno);
            throw SourceFileError(ss.str());
        }
        SourceLines::loadFile(file, name);
        if (file.bad())
        {
            throw std::runtime_error(
                "Cannot read from " + name + ": " + strerror(errno));
        }
    }
}

void SourceLines::loadFile(std::istream & file, const SourceFiles::FileName & name)
{
    LineCollection & lines = sources_[name];
    std::vector<int>    filterState;
    filterState.push_back(true);

    std::string line;
    Tokens::FileContent fullSource;
    bool   lastLineHasNewLine = true;

    while (getline(file, line))
    {
        bool pragmaLine = false;
        if (line.compare(0, 19, "#pragma vera_pushon") == 0)
        {
            filterState.push_back(1);
            pragmaLine = true;
        }
        if (line.compare(0, 20, "#pragma vera_pushoff") == 0)
        {
            filterState.push_back(0);
            pragmaLine = true;
        }
        if (line.compare(0, 20, "#pragma vera_pop") == 0)
        {
            if (filterState.empty())
            {
                throw std::runtime_error(
                    "Unbalanced vera-pop pragma: ie too many pop pragmas");
            }
            filterState.pop_back();
            pragmaLine = true;
        }
        if (not filterState.back() && not pragmaLine && not gTransformPass)
        {
            // If pragmas have turned off vera
            // Then make the line empty. This will just generate the end of line token
            // Thus allowing us to count lines but nothing else.
            line = "// Redacted Line"; // This is to prevent the empty line rule firing
        }
        lines.push_back(line);
        fullSource += line;
        fullSource += '\n';
        lastLineHasNewLine  = not file.eof();
    }
    if (filterState.size() != 1)
    {
        throw std::runtime_error(
            "Unbalanced vera-push pragma: ie too many push pragmas");
    }

    Tokens::parse(name, fullSource, lastLineHasNewLine, lines.size());
}

int SourceLines::getLineCount(const SourceFiles::FileName & name)
{
    return static_cast<int>(getAllLines(name).size());
}

const std::string & SourceLines::getLine(const SourceFiles::FileName & name, int lineNumber)
{
    const LineCollection & lines = getAllLines(name);
    if (lineNumber < 1 || lineNumber > static_cast<int>(lines.size()))
    {
        std::cerr << "Requested wrong line number: " << lineNumber << '\n';
        std::cerr << "lines.size in " << name << " is " << static_cast<int>(lines.size()) << '\n';
        throw SourceFileError("requested line number is out of range");
    }

    return lines[lineNumber - 1];
}

}
}
