%{
  #include <stdio.h>
  int yylex(void);
  int yyparse(void);
  extern int yylineno;
	int izjavnih = 0;
	int upitnih = 0;
	int uzvicnih = 0;
	int pasusa = 0;
	int uZagradama = 0;
%}

%token  _DOT
%token	_QMARK
%token 	_EXMARK
%token  _CAPITAL_WORD
%token  _WORD
%token 	_COMMA
%token 	_NEWLINE
%token 	_LPAREN
%token	_RPAREN

%%

text 
  : /* empty text */
  | text paragraph _NEWLINE { pasusa++; }
  ;

sentence 
  : _CAPITAL_WORD allWords parens end;
  ;

end
	: _DOT { izjavnih++; }
	| _QMARK { upitnih++; }
	| _EXMARK { uzvicnih++; }
	;

allWords
	: /* empty */
	| allWords words
	| allWords wordsInParens
	;

words 
  : /* empty */
  | words comma _WORD
  | words comma _CAPITAL_WORD
  ;

wordsInParens
	: /* empty */
  | wordsInParens comma _WORD { uZagradama++; }
  | wordsInParens comma _CAPITAL_WORD { uZagradama++; }
	;

comma
	: /* empty */
	| _COMMA
	;

parens
	: /* empty */
	| _LPAREN wordsInParens _RPAREN
	| _LPAREN parens _RPAREN
	;

paragraph
	: sentence
	| paragraph sentence
	;

%%

main() {
  yyparse();

	printf("izjavnih: %d,upitnih: %d,uzvicnih %d,pasusa: %d, reci u zagradama: %d\n", izjavnih, upitnih, uzvicnih, pasusa, uZagradama);
}

yyerror(char *s) {
  fprintf(stderr, "line %d: SYNTAX ERROR %s\n", yylineno, s);
} 

