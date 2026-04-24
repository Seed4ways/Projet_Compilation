%{

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <glib.h>

extern int yylex(void);
extern int yyerror(const char *msg);
extern int yylineno;

FILE       *stream;
GHashTable *table;
char       *module_name;

int label_counter = 0;

#define MAX_WHILE_DEPTH 64
int while_start_stack[MAX_WHILE_DEPTH];
int while_end_stack[MAX_WHILE_DEPTH];
int while_stack_top = 0;

void begin_code(void);
void end_code(void);
void produce_code(GNode *node);
void produce_condition(GNode *cond, const char *false_label);

%}

%define parse.error verbose

%union {
    gulong  number;
    gchar  *string;
    GNode  *node;
}

%token TOK_AFFECTATION              ":="
%token TOK_SEMI_COLON               ";"
%token TOK_IF                       "if"
%token TOK_THEN                     "then"                     
%token TOK_WHILE                    "while"
%token TOK_DO                       "do"
%token TOK_END                      "end"
%token TOK_END_IF                   "endif"
%token TOK_END_WHILE                "endwhile"
%token TOK_ELSE                     "else"
%token TOK_ELSE_IF                  "elseif"
%token TOK_PRINT                    "print"
%token TOK_READ                     "read"
%token TOK_CONTINUE                 "continue"
%token TOK_BREAK                    "break"
%token TOK_OPEN_PARENTHESIS         "("
%token TOK_CLOSE_PARENTHESIS        ")"
%token TOK_TRUE                     "true"
%token TOK_FALSE                    "false"
%token TOK_HASHTAG                  "#"
%token<number> TOK_NUMBER           "number"
%token<string> TOK_IDENTIFIER       "identifier"

%left  TOK_OR                       "or"
%left  TOK_AND                      "and"
%right TOK_NOT                      "not"
%nonassoc TOK_EQ                       "="
%nonassoc TOK_INF TOK_SUP TOK_INF_OR_EQ TOK_SUP_OR_EQ  "<" ">" "<=" ">="     
%left  TOK_ADD  TOK_SUB             "+" "-"                    
%left  TOK_MUL  TOK_DIV             "*" "/"         



%type<node> code
%type<node> expression
%type<node> instruction
%type<node> identifier
%type<node> print
%type<node> read
%type<node> affectation
%type<node> number
%type<node> condition
%type<node> if_instruction
%type<node> else_part
%type<node> while_instruction

%%

program:
    code
    {
        begin_code();
        produce_code( $1);
        end_code();
        g_node_destroy( $1);
    }
;

code:
    /* vide */
    {
        $$ = g_node_new("");
    }
    | instruction code
    {
        $$ = g_node_new("code");
        g_node_append($$, $1);
        g_node_append($$, $2);
    }
;

instruction:
    affectation
    | print
    | read
    | if_instruction
    | while_instruction
    | TOK_BREAK TOK_SEMI_COLON
    {
        $$ = g_node_new("break");
    }
    | TOK_CONTINUE TOK_SEMI_COLON
    {
        $$ = g_node_new("continue");
    }
;

affectation:
    identifier TOK_AFFECTATION expression TOK_SEMI_COLON
    {
        $$ = g_node_new("affectation");
        g_node_append($$, $1);
        g_node_append($$, $3);
    }
;

print:
    TOK_PRINT expression TOK_SEMI_COLON
    {
        $$ = g_node_new("print");
        g_node_append($$, $2);
    }
;

read:
    TOK_READ identifier TOK_SEMI_COLON
    {
        $$ = g_node_new("read");
        g_node_append($$, $2);
    }
;

expression:
    identifier
    | number
    | expression TOK_ADD expression
      {
          $$ = g_node_new("add");
          g_node_append($$, $1);
          g_node_append($$, $3);
      }
    | expression TOK_SUB expression
      {
          $$ = g_node_new("sub");
          g_node_append($$, $1);
          g_node_append($$, $3);
      }
    | expression TOK_MUL expression
      {
          $$ = g_node_new("mul");
          g_node_append($$, $1);
          g_node_append($$, $3);
      }
    | expression TOK_DIV expression
      {
          $$ = g_node_new("div");
          g_node_append($$, $1);
          g_node_append($$, $3);
      }
    | TOK_OPEN_PARENTHESIS expression TOK_CLOSE_PARENTHESIS
      {
          $$ = $2;
      }
;

identifier:
    TOK_IDENTIFIER
    {
        $$ = g_node_new("identifier");
        gulong value = (gulong) g_hash_table_lookup(table,  $1);
        if (!value) {
            value = g_hash_table_size(table) + 1;
            g_hash_table_insert(table, strdup( $1), (gpointer) value);
        }
        g_node_append_data($$, (gpointer)value);
    }
;

number:
    TOK_NUMBER
    {
        $$ = g_node_new("number");
        g_node_append_data($$, (gpointer)$1);
    }
;

condition:
    expression TOK_EQ expression
    {
        $$ = g_node_new("eq");
        g_node_append($$, $1);
        g_node_append($$, $3);
    }
    | expression TOK_HASHTAG expression
    {
        $$ = g_node_new("neq");
        g_node_append($$, $1);
        g_node_append($$, $3);
    }
    | expression TOK_INF expression
    {
        $$ = g_node_new("inf");
        g_node_append($$, $1);
        g_node_append($$, $3);
    }
    | expression TOK_SUP expression
    {
        $$ = g_node_new("sup");
        g_node_append($$, $1);
        g_node_append($$, $3);
    }
    | expression TOK_INF_OR_EQ expression
    {
        $$ = g_node_new("inf_or_eq");
        g_node_append($$, $1);
        g_node_append($$, $3);
    }
    | expression TOK_SUP_OR_EQ expression
    {
        $$ = g_node_new("sup_or_eq");
        g_node_append($$, $1);
        g_node_append($$, $3);
    }
;

if_instruction:
    TOK_IF condition TOK_THEN code else_part TOK_END_IF
    {
        $$ = g_node_new("if");
        g_node_append($$, $2);
        g_node_append($$, $4);
        g_node_append($$, $5);
    }
;

else_part:
    /* vide */
    {
        $$ = g_node_new("noelse");
    }
    | TOK_ELSE code
    {
        $$ = g_node_new("else");
        g_node_append($$, $2);
    }
    | TOK_ELSE_IF condition TOK_THEN code else_part
    {
        $$ = g_node_new("elseif");
        g_node_append($$, $2);
        g_node_append($$, $4);
        g_node_append($$, $5);
    }
;

while_instruction:
    TOK_WHILE condition TOK_DO code TOK_END_WHILE
    {
        $$ = g_node_new("while");
        g_node_append($$, $2);
        g_node_append($$, $4);
    }
;

%%

int yyerror(const char *msg) {
    fprintf(stderr, "Erreur ligne %d : %s\n", yylineno, msg);
    return 0;
}

void produce_condition(GNode *cond, const char *false_label) {
    produce_code(g_node_nth_child(cond, 0));
    produce_code(g_node_nth_child(cond, 1));

    if      (strcmp(cond->data, "eq")        == 0) fprintf(stream, " bne.un %s\n", false_label);
    else if (strcmp(cond->data, "neq")       == 0) fprintf(stream, " beq %s\n",    false_label);
    else if (strcmp(cond->data, "inf")       == 0) fprintf(stream, " bge %s\n",    false_label);
        else if (strcmp(cond->data, "sup")       == 0) fprintf(stream, " ble %s\n",    false_label);
    else if (strcmp(cond->data, "inf_or_eq") == 0) fprintf(stream, " bgt %s\n",    false_label);
    else if (strcmp(cond->data, "sup_or_eq") == 0) fprintf(stream, " blt %s\n",    false_label);
}

void begin_code(void) {
    fprintf(stream, ".assembly extern mscorlib {}\n");
    fprintf(stream, ".assembly %s {}\n", module_name);
    fprintf(stream, ".method static void main() {\n");
    fprintf(stream, ".entrypoint\n");
    fprintf(stream, ".maxstack 10\n");
    fprintf(stream, ".locals init (");
    guint size = g_hash_table_size(table);
    for (guint i = 0; i < size; i++) {
        if (i > 0) fprintf(stream, ", ");
        fprintf(stream, "int32");
    }
    fprintf(stream, ")\n");
}

void produce_code(GNode *node) {
    if (node == NULL) return;
    if (strcmp(node->data, "") == 0) return;

    if (strcmp(node->data, "code") == 0) {
        produce_code(g_node_nth_child(node, 0));
        produce_code(g_node_nth_child(node, 1));

    } else if (strcmp(node->data, "affectation") == 0) {
        produce_code(g_node_nth_child(node, 1));
        fprintf(stream, " stloc\t%ld\n",
            (long)g_node_nth_child(g_node_nth_child(node, 0), 0)->data - 1);

    } else if (strcmp(node->data, "add") == 0) {
        produce_code(g_node_nth_child(node, 0));
        produce_code(g_node_nth_child(node, 1));
        fprintf(stream, " add\n");

    } else if (strcmp(node->data, "sub") == 0) {
        produce_code(g_node_nth_child(node, 0));
        produce_code(g_node_nth_child(node, 1));
        fprintf(stream, " sub\n");

    } else if (strcmp(node->data, "mul") == 0) {
        produce_code(g_node_nth_child(node, 0));
        produce_code(g_node_nth_child(node, 1));
        fprintf(stream, " mul\n");

    } else if (strcmp(node->data, "div") == 0) {
        produce_code(g_node_nth_child(node, 0));
        produce_code(g_node_nth_child(node, 1));
        fprintf(stream, " div\n");

    } else if (strcmp(node->data, "number") == 0) {
        fprintf(stream, " ldc.i4\t%ld\n",
            (long)g_node_nth_child(node, 0)->data);

    } else if (strcmp(node->data, "identifier") == 0) {
        fprintf(stream, " ldloc\t%ld\n",
            (long)g_node_nth_child(node, 0)->data - 1);

    } else if (strcmp(node->data, "print") == 0) {
        produce_code(g_node_nth_child(node, 0));
        fprintf(stream, " call void class [mscorlib]System.Console::WriteLine(int32)\n");

    } else if (strcmp(node->data, "read") == 0) {
        fprintf(stream, " call string class [mscorlib]System.Console::ReadLine()\n");
        fprintf(stream, " call int32 int32::Parse(string)\n");
        fprintf(stream, " stloc\t%ld\n",
            (long)g_node_nth_child(g_node_nth_child(node, 0), 0)->data - 1);

    } else if (strcmp(node->data, "if") == 0) {
        int label = label_counter++;
        char endif_label[32], else_label[32];
        sprintf(endif_label, "ENDIF_%d", label);
        sprintf(else_label,  "ELSE_%d",  label);

        GNode *cond    = g_node_nth_child(node, 0);
        GNode *code    = g_node_nth_child(node, 1);
        GNode *elspart = g_node_nth_child(node, 2);

        if (strcmp(elspart->data, "noelse") == 0) {
            produce_condition(cond, endif_label);
            produce_code(code);
            fprintf(stream, "ENDIF_%d:\n", label);
        } else {
            produce_condition(cond, else_label);
            produce_code(code);
            fprintf(stream, " br ENDIF_%d\n", label);
            fprintf(stream, "ELSE_%d:\n", label);
            produce_code(elspart);
            fprintf(stream, "ENDIF_%d:\n", label);
        }

    } else if (strcmp(node->data, "noelse") == 0) {
        /* rien */

    } else if (strcmp(node->data, "else") == 0) {
        produce_code(g_node_nth_child(node, 0));

    } else if (strcmp(node->data, "elseif") == 0) {
        int label = label_counter++;
        char endif_label[32], else_label[32];
        sprintf(endif_label, "ENDIF_%d", label);
        sprintf(else_label,  "ELSE_%d",  label);

        GNode *cond    = g_node_nth_child(node, 0);
        GNode *code    = g_node_nth_child(node, 1);
        GNode *elspart = g_node_nth_child(node, 2);

        if (strcmp(elspart->data, "noelse") == 0) {
            produce_condition(cond, endif_label);
            produce_code(code);
            fprintf(stream, "ENDIF_%d:\n", label);
        } else {
            produce_condition(cond, else_label);
            produce_code(code);
            fprintf(stream, " br ENDIF_%d\n", label);
            fprintf(stream, "ELSE_%d:\n", label);
            produce_code(elspart);
            fprintf(stream, "ENDIF_%d:\n", label);
        }

    } else if (strcmp(node->data, "while") == 0) {
        int label = label_counter++;
        char while_label[32], endwhile_label[32];
        sprintf(while_label,    "WHILE_%d",    label);
        sprintf(endwhile_label, "ENDWHILE_%d", label);

        while_start_stack[while_stack_top] = label;
        while_end_stack[while_stack_top]   = label;
        while_stack_top++;

        fprintf(stream, "WHILE_%d:\n", label);
        GNode *cond = g_node_nth_child(node, 0);
        GNode *code = g_node_nth_child(node, 1);

        produce_condition(cond, endwhile_label);
        produce_code(code);
        fprintf(stream, " br WHILE_%d\n", label);
        fprintf(stream, "ENDWHILE_%d:\n", label);

        while_stack_top--;

    } else if (strcmp(node->data, "break") == 0) {
        if (while_stack_top == 0) {
            fprintf(stderr, "Erreur : break en dehors d'un while\n");
        } else {
            int label = while_end_stack[while_stack_top - 1];
            fprintf(stream, " br ENDWHILE_%d\n", label);
        }

    } else if (strcmp(node->data, "continue") == 0) {
        if (while_stack_top == 0) {
            fprintf(stderr, "Erreur : continue en dehors d'un while\n");
        } else {
            int label = while_start_stack[while_stack_top - 1];
            fprintf(stream, " br WHILE_%d\n", label);
        }
    }
}

int main(int argc, char *argv[]) {
    extern FILE *yyin;

    if (argc != 2) {
        fprintf(stderr, "Usage : %s fichier.facile\n", argv[0]);
        return 1;
    }

    yyin = fopen(argv[1], "r");
    if (!yyin) {
        perror(argv[1]);
        return 1;
    }

    module_name = strdup(argv[1]);
    char *dot = strrchr(module_name, '.');
    if (dot) *dot = '\0';

    char output[256];
    snprintf(output, sizeof(output), "%s.il", module_name);
    stream = fopen(output, "w");
    if (!stream) {
        perror(output);
        return 1;
    }

    table = g_hash_table_new(g_str_hash, g_str_equal);

    yyparse();

    fclose(yyin);
    fclose(stream);
    g_hash_table_destroy(table);
    free(module_name);

    return 0;
}

