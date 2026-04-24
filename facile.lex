%{
#include <assert.h>
#include <string.h>
#include <glib.h>
#include "facile.y.h"
%}

%option yylineno

%%

"if"       { return TOK_IF; }
"then"     { return TOK_THEN; }
"while"    { return TOK_WHILE; }
"do"       { return TOK_DO; }
"endif"    { return TOK_END_IF; }
"endwhile" { return TOK_END_WHILE; }
"end"      { return TOK_END; }
"elseif"   { return TOK_ELSE_IF; }
"else"     { return TOK_ELSE; }
"print"    { return TOK_PRINT; }
"read"     { return TOK_READ; }
"continue" { return TOK_CONTINUE; }
"break"    { return TOK_BREAK; }
"true"     { return TOK_TRUE; }
"false"    { return TOK_FALSE; }
"not"      { return TOK_NOT; }
"and"      { return TOK_AND; }
"or"       { return TOK_OR; }

"("  { return TOK_OPEN_PARENTHESIS; }
")"  { return TOK_CLOSE_PARENTHESIS; }
";"  { return TOK_SEMI_COLON; }
":=" { return TOK_AFFECTATION; }
"+"  { return TOK_ADD; }
"-"  { return TOK_SUB; }
"*"  { return TOK_MUL; }
"/"  { return TOK_DIV; }
"<=" { return TOK_INF_OR_EQ; }
">=" { return TOK_SUP_OR_EQ; }
"<"  { return TOK_INF; }
">"  { return TOK_SUP; }
"="  { return TOK_EQ; }
"#"  { return TOK_HASHTAG; }


[0-9]+ {  
    sscanf(yytext, "%lu", &yylval.number); 
    return TOK_NUMBER;
}


[a-zA-Z][a-zA-Z0-9_]* {
    yylval.string = strdup(yytext);
    return TOK_IDENTIFIER;
}


[ \t\n]  ;

. {
    return yytext[0];
}

%%

int yywrap(void) {
    return 1;
}
