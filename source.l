%{
#include <iostream>
#include <vector>
#include <fstream>
#include <cstdlib>
#include <algorithm>
#include <stack>

using namespace std;

int *** nfa_table;					//Transition table for NFA
vector<vector<int> > state_ref;
vector<vector<int> > dfa_table;

int num_state,num_final,num_input;

int *input_element;					//List of all valid inputs
int *state;						//List of all states
int *final;						//List of all final states
int* kleen_closure;					//To store the e_closure of a given state


int dfa_current_state;					//Current state of DFA

void read_specification();
void print_specification();
int index(vector<int> temp);
void insert_state_ref(vector<int> temp);
void e_closure(int _state);
vector<int> get_next_state(vector<int> _current_state);
void nfa_dfa_conversion();
int countElement(const char*);				//To count the element in COMA separated input (1,3,2,4)

void done();
void update_current_state(char c);
void reinitialize_current_state();
void printNewTable();

%}



%%

[$^]	;
[ ]	{}
\n	{done(); reinitialize_current_state();}
.	{update_current_state(yytext[0]);}

%%


int main(int argc, char* argv[]){
	if(argc!=4){
		printf("Invalid format of the executable file.\n");
		return 0;
	}

	num_state=atoi(argv[1]);
	num_final=atoi(argv[2]);
	num_input=atoi(argv[3]);
			//Intializing current state
	kleen_closure = (int*)malloc(num_state*sizeof(int));
	read_specification();
			//Printing specification.txt file
	print_specification();
	nfa_dfa_conversion();
	printNewTable();
			//calling pattern matching function
	reinitialize_current_state();
	yylex();

	return 0;
}

void reinitialize_current_state(){
	dfa_current_state=state[0];
}


void print_specification(){
	printf("States : ");
	for(int i = 0;i<num_state;i++)
		cout<<state[i]<<" ";
	cout<<"\nFinal States : ";
	for(int i = 0;i<num_final;i++)
		cout<<final[i]<<" ";
	cout<<"\nInput Symbols : ";
	for(int i = 0;i<num_input;i++)
		cout<<input_element[i]<<" ";

	printf("\nNFA Transition Table : \n");
	for(int i = 0;i<num_state;i++){
		for(int j = 0;j<=num_input;j++){
			if(nfa_table[i][j][0] == -1){
				printf("%c\t\t",'^');
				continue;
			}
			for(int k = 0;nfa_table[i][j][k]!=-1;k++){
				printf("%d ",nfa_table[i][j][k]);
			}
			printf("\t\t");
		}
		printf("\n");
	}

}

void printNewTable(){
	cout<<"\n\nNew DFA Transition Table : \n\n";
	
	cout<<"New States : \n";
		
	for(int i = 0;i<state_ref.size();i++){
		cout<<i<<"\t:  ";
		for(int j = 0;j<state_ref[i].size();j++)
			cout<<state_ref[i][j]<<" ";
		cout<<endl;
	}

	cout<<"New Final States : ";
	
	for(int i = 0;i!=num_final;i++){
		cout<<final[i]<<" ";
	}
	
	cout<<endl<<endl;
	
	cout<<"\t|";
	for(int i = 0;i<num_input;i++)
		cout<<(char)input_element[i]<<"\t";
	cout<<endl;
	
	for(int i = 0;i<8;i++)
		cout<<"-";
	cout<<"+";
	for(int i = 0;i<(num_input-1)*9;i++)
		cout<<"-";
	cout<<endl;
	for(int i = 0;i<dfa_table.size();i++){
		cout<<i<<"\t|";
		for(int j = 0;j<dfa_table[i].size();j++)
			cout<<dfa_table[i][j]<<"\t";
		cout<<endl;
	}
}

void read_specification(){
	char error[100];						//to read the unnecessary letter from the file
	FILE* f = fopen("specification.txt","r");

			//Allocating memory
	state = (int*)malloc(sizeof(int)*num_state);
	final = (int*)malloc(sizeof(int)*num_final);
	input_element = (int*)malloc(sizeof(int)*(num_input));

			//reading state from file
	for(int i = 0;i<num_state;i++){
		fscanf(f,"%d", &state[i]);
	}

			//Reading Final State from file
	for(int i = 0;i<num_final;i++){
		fscanf(f,"%d", &final[i]);
	}
	
			//Reading Input symbol from file
	for(int i = 0;i<num_input;){
		input_element[i] = fgetc(f);
		if(input_element[i] == ' '||input_element[i]=='\n'||input_element[i] == '\t')continue;
		i++;
		
	}

	fgets(error,100,f); //read previous /n
//	fgets(error,100,f);					//this line of specification.txt file is not requred
//	puts(error);

			//IF THE DFA THEN ALLOCATING MEMORY TO DFA TABLE ONLY AND ALSO INITIALIZE THIS TABLE
			//ELSE DO THIS FOR NFA TABLE
	
	nfa_table = (int***)malloc((num_state)*sizeof(int**));
	for(int i = 0;i<num_state;i++)
		nfa_table[i] = (int**)malloc(sizeof(int*)*(num_input+1));

		
	for(int i = 0;i<num_state;i++){
//		int temp2;
//		fscanf(f,"%d",&temp2);
		for(int j = 0;j<=num_input;j++){
			int temp_state = 0,index = 0;
			char temp_input[100];
			fscanf(f,"%s",temp_input);
			int temp_element = countElement(temp_input);
			nfa_table[i][j] = (int*)malloc(sizeof(int)*(temp_element+1));			//last element is -1 to check end of the table
			for(int k=0;;k++){
				if(temp_input[k]=='\0'){
					nfa_table[i][j][index++] = temp_state;
					nfa_table[i][j][index++] = -1;
					temp_state = 0;break;
				}else if(temp_input[k] == '^'){
					nfa_table[i][j][index++] = -1;
					nfa_table[i][j][index] = -1;
					break;
				}
				if(temp_input[k]==','){
					nfa_table[i][j][index++] = temp_state;
					temp_state = 0;
				}else if(temp_input[k]<='9' && temp_input[k]>='0'){
					temp_state = temp_state*10 + temp_input[k]-'0';				
				}
			}
		}
	}
	fclose(f);
}

int index(vector<int> temp){
	sort(temp.begin(),temp.end());
	for(int j = 0;j < state_ref.size();j++)
		if(temp == state_ref[j])
			return j;
	return -3;
}

void insert_state_ref(vector<int> temp){
	sort(temp.begin(),temp.end());
	if(index(temp) == -3)
		state_ref.push_back(temp);
}

void e_closure(int _state){
	for(int i = 0;i<num_state;i++)
		if(i == _state)
			kleen_closure[i] = 1;
		else
			kleen_closure[i] = 0;

	stack<int> s1;

	for(int i = 0;nfa_table[_state][num_input][i] != -1;i++){
		if(kleen_closure[nfa_table[_state][num_input][i]]!=1){
			s1.push(nfa_table[_state][num_input][i]);
			kleen_closure[nfa_table[_state][num_input][i]] = 1;
		}
	}
	while(!s1.empty()){
		_state = s1.top();
		s1.pop();
		for(int i = 0;nfa_table[_state][num_input][i] != -1;i++){
			if(kleen_closure[nfa_table[_state][num_input][i]]!=1){
				s1.push(nfa_table[_state][num_input][i]);
				kleen_closure[nfa_table[_state][num_input][i]] = 1;
			}
		}
	}
	
}

vector<int> get_next_state(vector<int> _current_state){

	vector<int> temp;

	if(_current_state[0] == -1){
		int null_index = index(_current_state);
		for(int i = 0;i<num_input;i++)
			temp.push_back(null_index);
		return temp;
	}

	int current_state[num_state] = {0};
	for(int i = 0;i<_current_state.size();i++){
		e_closure(_current_state[i]);
		for(int j = 0;j<num_state;j++)
			if(kleen_closure[j] == 1)
				current_state[j] = 1;
	}
	
	
	for(int i=0;i<num_input;i++){
		int next_state[num_state] = {0};
		for(int j = 0;j<num_state;j++){
			if(current_state[j] == 1){
				for(int k = 0;nfa_table[j][i][k]!=-1;k++){
					e_closure(nfa_table[j][i][k]);
					for(int l=0;l<num_state;l++)
						if(kleen_closure[l] == 1){
							next_state[l] = 1;
						}
				}
			}
		}
		vector<int> _next_state;
		for(int j = 0;j<num_state;j++)
			if(next_state[j] == 1)
				_next_state.push_back(j);
		if(_next_state.size() == 0)
			_next_state.push_back(-1);

		insert_state_ref(_next_state);
		temp.push_back(index(_next_state));
	}
	return temp;
}

void nfa_dfa_conversion(){
	vector<int> temp1;
	e_closure(0);
	for(int i = 0;i<num_state;i++)
		if(kleen_closure[i] == 1)
			temp1.push_back(i);
	state_ref.push_back(temp1);
	
	for(int i =0;i<state_ref.size();i++){
		dfa_table.push_back(get_next_state(state_ref[i]));
	}
	
	
	bool temp2[num_state] = {0};
	for(int i = 0;i<num_final;i++)
		temp2[final[i]] = true;	

	num_state=dfa_table.size();
	state = (int*)realloc(state,sizeof(int)*num_state);
	
	vector<int> new_final;
	for(int i = 0;i<state_ref.size();i++){
		for(int j = 0;j<state_ref[i].size();j++){
			if(temp2[state_ref[i][j]]){
				new_final.push_back(i);
				break;
			}
		}
	}
	
	int *_new_final = (int*)malloc(sizeof(int)*new_final.size());
	for(int i = 0;i<new_final.size();i++)
		_new_final[i] = new_final[i];
	free(final);
	final = _new_final;
	num_final = new_final.size();
}

int countElement(const char* s){
	int size = 0;
	for(int i = 0;s[i]!='\0';i++){
		if(s[i] == ',')
			size++;
	}
	return size+1;
}


			//THIS FUNCTION CHECK, IF THE PATTERN MATCHES OR NOT, BY COMPARING CURRENT STATE TO THE LIST OF FINAL STATE
void done(){
	for(int i = 0;i<num_final;i++){
		if(final[i] == dfa_current_state){
			printf("MATCHED\n");
			return ;
		}
	}
	printf("ERROR\n");
}

			//THIS FUNCTION UPDATE THE CURRENT STATE USING THE TRANSITION TABLE
void update_current_state(char c){
	for(int i =0;i<num_input;i++){
		if(c==input_element[i]){
			dfa_current_state = dfa_table[dfa_current_state][i];
			return ;
		}
	}
			//User input char which are not listed in the input_element
	printf("\nYour are not supposed to enter input other than given.\n");
	exit(0);
}

