all: mylex

mylex:lex.yy.c
	g++ lex.yy.c -ll -o mylex

lex.yy.c:source.l specification.txt
	lex source.l

clean:
	rm -r mylex lex.yy.c
