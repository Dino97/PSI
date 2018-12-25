%{
  #include <stdio.h>
  #include <stdlib.h>
  #include "defs.h"
  #include "symtab.h"
  #include "codegen.h"

  int yyparse(void);
  int yylex(void);
  int yyerror(char *s);
  void warning(char *s);

  extern int yylineno;
  int out_lin = 0;
  char char_buffer[CHAR_BUFFER_LENGTH];
  int error_count = 0;
  int warning_count = 0;
  int var_num = 0;
  int fun_idx = -1;
  int fcall_idx = -1;
  int lab_num = -1;
  FILE *output;
  int case_nums[100];
  int case_nums_pos = 0;
%}

%union {
  int i;
  char *s;
}

%token <i> _TYPE
%token _IF
%token _ELSE
%token _RETURN
%token <s> _ID
%token <s> _INT_NUMBER
%token <s> _UINT_NUMBER
%token _LPAREN
%token _RPAREN
%token _LBRACKET
%token _RBRACKET
%token _ASSIGN
%token _SEMICOLON
%token <i> _AROP
%token <i> _RELOP
%token _FOR
%token _INCR
%token _SWITCH
%token _CASE
%token _DEFAULT
%token _BREAK
%token _COLON

%type <i> type num_exp exp literal
%type <i> function_call argument rel_exp if_part
%type <i> default

%nonassoc ONLY_IF
%nonassoc _ELSE

%%

program
  : function_list
      {  
        int idx = lookup_symbol("main", FUN);
        if(idx == -1)
          err("undefined reference to 'main'");
        else 
          if(get_type(idx) != INT)
            warn("return type of 'main' is not int");
      }
  ;

function_list
  : function
  | function_list function
  ;

function
  : type _ID
      {
        fun_idx = lookup_symbol($2, FUN);
        if(fun_idx == -1)
          fun_idx = insert_symbol($2, FUN, $1, NO_ATR, NO_ATR);
        else 
          err("redefinition of function '%s'", $2);

        code("\n%s:", $2);
        code("\n\t\t\tPUSH\t%%14");
        code("\n\t\t\tMOV \t%%15,%%14");
      }
    _LPAREN parameter _RPAREN body
      {
        clear_symbols(fun_idx + 1);
        var_num = 0;
        
        gen_sslab($2,"_exit");
        code("\n\t\t\tMOV \t%%14,%%15");
        code("\n\t\t\tPOP \t%%14");
        code("\n\t\t\tRET");
      }
  ;

type
  : _TYPE
      {  $$ = $1; }
  ;

parameter
  : /* empty */
      { set_atr1(fun_idx, 0); }

  | type _ID
      {
        insert_symbol($2, PAR, $1, 1, NO_ATR);
        set_atr1(fun_idx, 1);
        set_atr2(fun_idx, $1);
      }
  ;

body
  : _LBRACKET variable_list
      {
        if(var_num)
          code("\n\t\t\tSUBS\t%%15,$%d,%%15", 4*var_num);
        gen_sslab(get_name(fun_idx), "_body");
      }
    statement_list _RBRACKET
  ;

variable_list
  : /* empty */
  | variable_list variable
  ;

variable
  : type _ID _SEMICOLON
      {
        if(lookup_symbol($2, VAR|PAR) == -1)
           insert_symbol($2, VAR, $1, ++var_num, NO_ATR);
        else 
           err("redefinition of '%s'", $2);
      }
  ;

statement_list
  : /* empty */
  | statement_list statement
  ;

statement
  : compound_statement
  | assignment_statement
  | if_statement
  | return_statement
  | for_statement
  | switch_statement
  ;

compound_statement
  : _LBRACKET statement_list _RBRACKET
  ;

assignment_statement
  : _ID _ASSIGN num_exp _SEMICOLON
      {
        int idx = lookup_symbol($1, (VAR|PAR));
        if(idx == -1)
          err("invalid lvalue '%s' in assignment", $1);
        else
          if(get_type(idx) != get_type($3))
            err("incompatible types in assignment");
        gen_mov($3, idx);
      }
  ;
  
for_statement
	: _FOR _LPAREN _ID _ASSIGN literal _SEMICOLON 
		{
			$<i>$ = ++lab_num;
			int idx = lookup_symbol($3, (VAR|PAR));
			
			if(idx == -1)
				err("%s undefined", $3);
				
			if(get_type(idx) != get_type($5))
				err("%s and %d are not of the same type", $3, $5);
				
			gen_snlab("for_init", lab_num);
			gen_mov($5, idx);
			
			gen_snlab("for_condition", lab_num);
		}
		
		rel_exp _SEMICOLON 
		{
			code("\n\t\t\t%s\t@for_statement%d", get_jump_stmt($8, FALSE), $<i>7);
			code("\n\t\t\tJMP\t\t@for_exit%d", $<i>7);
			gen_snlab("for_statement", $<i>7);
		}
		
		_ID _INCR _RPAREN statement
		{
			int idx = lookup_symbol($11, (VAR|PAR));
			
			if(idx == -1)
				err("%s undefined", $11);
				
			if(get_type(idx) != get_type($5))
				err("%s and %d are not of the same type", $11, $5);
			
			code("\n\t\t\t%s\t", get_arop_stmt(ADD, get_type(idx)));
			print_symbol(idx);
			code(",$1,");
			print_symbol(idx);
			code("\n\t\t\tJMP\t\t@for_condition%d", $<i>7);
			gen_snlab("for_exit", $<i>7);
		}
	;

switch_statement
	:	_SWITCH _LPAREN _ID _RPAREN
		{
			int idx = lookup_symbol($3, (VAR|PAR));
			
			if(idx == -1)
				err("%s undefined", $3);
				
			$<i>$ = idx;
			
			code("\n\t\t\tJMP\t\t@jumps_switch%d\t\t# jump to comparing first", ++lab_num);
		}
		
		_LBRACKET case_list
		{
			code("\n\t\t\tJMP\t\t@exit_switch%d\t\t# last case statement, jump to exit", lab_num);
		}
		
		default _RBRACKET
		{
			gen_snlab("jumps_switch", lab_num);
			
			for(int i = 0; i < case_nums_pos; i++)
			{
				gen_cmp($<i>5, case_nums[i]);
				code("\n\t\t\tJEQ\t\t@switch%d_case%s", lab_num, get_name(case_nums[i]));
			}
			
			if($9 == 1)
				code("\n\t\t\tJMP\t\t@default_switch%d", lab_num);
				
			gen_snlab("exit_switch", lab_num);
			case_nums_pos = 0;
		}
	;
	
case_list
	: case
	| case_list case
	;
	
case
	: _CASE literal _COLON
		{
			for(int i = 0; i < case_nums_pos; i++)
			{
				if(case_nums[i] == $2)
					err("case %s already exists", get_name($2));
			}
		
			case_nums[case_nums_pos++] = $2;
		
			char str[50];
			sprintf(str, "%d_case%s", lab_num, get_name($2));
			gen_sslab("switch", str);
		}
		
		statement break
	;
	
default
	: /* empty */
		{
			$$ = 0;
		}
	| _DEFAULT _COLON
		{
			gen_snlab("default_switch", lab_num);
		}
		statement
		{
			code("\n\t\t\tJMP\t\t@exit_switch%d", lab_num);
			$$ = 1;
		}
	;
	
break
	: /* empty */
	| _BREAK _SEMICOLON
		{
			code("\n\t\t\tJMP\t\t@exit_switch%d\t\t#break", lab_num);
		}
	;

num_exp
  : exp

  | num_exp _AROP exp
      {
        if(get_type($1) != get_type($3))
          err("invalid operands: arithmetic operation");
        int t1 = get_type($1);
        code("\n\t\t\t%s\t", get_arop_stmt($2, t1));
        print_symbol($1);
        code(",");
        print_symbol($3);
        code(",");
        if($3 >= 0 && $3 <= LAST_WORKING_REG)
          free_reg();
        if($1 >= 0 && $1 <= LAST_WORKING_REG)
          free_reg();
        $$ = take_reg();
        print_symbol($$);
        set_type($$, t1);
      }
  ;

exp
  : literal

  | _ID
      {
        $$ = lookup_symbol($1, (VAR|PAR));
        if($$ == -1)
          err("'%s' undeclared", $1);
      }

  | function_call
      {
        $$ = take_reg();
        gen_mov(FUN_REG, $$);
      }
  
  | _LPAREN num_exp _RPAREN
      { $$ = $2; }
  ;

literal
  : _INT_NUMBER
      { $$ = insert_literal($1, INT); }

  | _UINT_NUMBER
      { $$ = insert_literal($1, UINT); }
  ;

function_call
  : _ID 
      {
        fcall_idx = lookup_symbol($1, FUN);
        if(fcall_idx == -1)
          err("'%s' is not a function", $1);
      }
    _LPAREN argument _RPAREN
      {
        if(get_atr1(fcall_idx) != $4)
          err("wrong number of arguments");
        code("\n\t\t\tCALL\t%s", get_name(fcall_idx));
        if($4 > 0)
          code("\n\t\t\tADDS\t%%15,$%d,%%15", $4 * 4);
        set_type(FUN_REG, get_type(fcall_idx));
        $$ = FUN_REG;
      }
  ;

argument
  : /* empty */
    { $$ = 0; }

  | num_exp
    { 
      if(get_atr2(fcall_idx) != get_type($1))
        err("incompatible type for argument");
      free_if_reg($1);
      code("\n\t\t\tPUSH\t");
      print_symbol($1);
      $$ = 1;
    }
  ;

if_statement
  : if_part %prec ONLY_IF
      { gen_snlab("exit", $1); }

  | if_part _ELSE statement
      { gen_snlab("exit", $1);}
  ;

if_part
  : _IF _LPAREN
      {
        $<i>$ = ++lab_num;
        gen_snlab("if", lab_num);
      }
    rel_exp
      {
        code("\n\t\t\t%s\t@false%d", 
          get_jump_stmt($4, TRUE),$<i>3);
        gen_snlab("true", $<i>3);
      }
    _RPAREN statement
      {
        code("\n\t\t\tJMP \t@exit%d", $<i>3);
        gen_snlab("false", $<i>3);
        $$ = $<i>3;
      }
  ;

rel_exp
  : num_exp _RELOP num_exp
      {
        if(get_type($1) != get_type($3))
          err("invalid operands: relational operator");
        $$ = $2 + ((get_type($1) - 1) * RELOP_NUMBER);
        gen_cmp($1, $3);
      }
  ;

return_statement
  : _RETURN num_exp _SEMICOLON
      {
        if(get_type(fun_idx) != get_type($2))
          err("incompatible types in return");
        gen_mov($2, FUN_REG);
        code("\n\t\t\tJMP \t@%s_exit", get_name(fun_idx));        
      }
  ;

%%

int yyerror(char *s) {
  fprintf(stderr, "\nline %d: ERROR: %s", yylineno, s);
  error_count++;
  return 0;
}

void warning(char *s) {
  fprintf(stderr, "\nline %d: WARNING: %s", yylineno, s);
  warning_count++;
}

int main() {
  int synerr;
  init_symtab();
  output = fopen("output.asm", "w+");

  synerr = yyparse();

  clear_symtab();
  fclose(output);
  
  if(warning_count)
    printf("\n%d warning(s).\n", warning_count);

  if(error_count) {
    remove("output.asm");
    printf("\n%d error(s).\n", error_count);
  }

  if(synerr)
    return -1;
  else
    return error_count;
}

