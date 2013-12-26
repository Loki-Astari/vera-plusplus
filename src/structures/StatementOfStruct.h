//
// Copyright (C) 2006-2007 Maciej Sobczak
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef STATEMENTOFSTRUCT_H_INCLUDED
#define STATEMENTOFSTRUCT_H_INCLUDED

#include "Tokens.h"
#include <string>
#include <vector>
#include "Statements.h"

namespace Vera
{
namespace Structures
{

/**
 * @brief Classes that implements a decorator dedicated to the construction
 * of Statements of type "Struct".
 */
class StatementOfStruct
: public StatementsBuilder
{
  public:

    StatementOfStruct(Statement& statement,
      Tokens::TokenSequence::const_iterator& it,
      Tokens::TokenSequence::const_iterator& end);

    /**
     * @brief Gets the scope of the current sentence.
     *
     * @return The const reference to the Statement structure
     * which contains the associated tokens.
     */
    const Statement& getStatementScope();

    static bool isValid(Tokens::TokenSequence::const_iterator it,
      Tokens::TokenSequence::const_iterator end);

    static bool isValidWithoutName(Tokens::TokenSequence::const_iterator it,
        Tokens::TokenSequence::const_iterator end);

    void initialize(Tokens::TokenSequence::const_iterator& it,
        Tokens::TokenSequence::const_iterator& end);

    bool parseName(Tokens::TokenSequence::const_iterator& it,
        Tokens::TokenSequence::const_iterator& end);

    bool parseHeritage(Tokens::TokenSequence::const_iterator& it,
        Tokens::TokenSequence::const_iterator& end);

    bool parseScope(Tokens::TokenSequence::const_iterator& it,
        Tokens::TokenSequence::const_iterator& end);


  private:

    const std::string* name_;
    Statement* scope_;
    Statement* hieritance_;
};

} // namespace Structures

} // namespace Vera

#endif // STATEMENTOFSTRUCT_H_INCLUDED