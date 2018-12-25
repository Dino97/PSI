%option noyywrap yylineno
%{
  #include "text.tab.h"
%}

%%

[ \t]+    { /* skip */ }

"."         { return _DOT; }
"?"	    { return _QMARK; }
"!"	    { return _EXMARK; }
","	    { return _COMMA; }
"\n"+	    { return _NEWLINE; }
"("	    { return _LPAREN; }
")"	    { return _RPAREN; }
[A-Z][a-z]* { return _CAPITAL_WORD; }
[a-z]+      { return _WORD; }
                     
.           { printf("\nline %d: LEXICAL ERROR on char %c", 
                      yylineno, *yytext); }    

