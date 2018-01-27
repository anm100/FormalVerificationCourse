#define N 4

mtype = { start, wait, receive, waiting_for_task, sending_to_am, receiving_from_am,  ready, processing, finish};

chan client_s[5] = [0] of {byte};
chan client_r[5] =  [0] of {byte};

chan d_am = [0] of {byte};
chan c_am = [0] of {byte};

int counter = 0;


mtype a_state;
mtype s_state;
mtype cstate[N];
ltl r1 {[](counter < 4)}


ltl r2 {[]((cstate[index]==wait ) -> <>(cstate[index]==receive))}



proctype client(byte index)
{
	byte msgs = index;
	byte msgr=0;
	cstate[index] = start;

	do
	:: (cstate[index] == start) -> atomic {client_s[index] ! msgs; cstate[index] = wait;}
	:: (cstate[index] == wait) -> atomic {client_r[index] ? msgr; cstate[index] = receive;}
	:: (cstate[index] == receive) -> cstate[index] = start;
	od
}
proctype server()
{	
	s_state = waiting_for_task;
	byte done[N]=0,task[N]=0;
	byte temp;

	do
	:: (s_state == waiting_for_task) ->
		if
		::atomic {client_s[0] ? task[0]; s_state = sending_to_am;}
		::atomic {client_s[1] ? task[1]; s_state = sending_to_am;}
		::atomic {client_s[2] ? task[2]; s_state = sending_to_am;}
		::atomic {client_s[3] ? task[3]; s_state = sending_to_am;}
		fi
	:: (s_state == waiting_for_task ) -> atomic{d_am ? temp; done[temp] = 1; s_state = receiving_from_am;}
	:: (s_state == sending_to_am) -> 
		if
		::(done[0]==0) ->atomic {c_am ! task[0]; s_state = waiting_for_task;}
		:: (done[1]==0) ->atomic {c_am ! task[1]; s_state = waiting_for_task;}
		:: (done[2]==0)->atomic {c_am ! task[2]; s_state = waiting_for_task;}
		:: (done[3]==0)>atomic {c_am ! task[3]; s_state = waiting_for_task;}
		fi
	:: (s_state == receiving_from_am) -> 
		if
		:: (done[0]==1) -> atomic { client_r[0] ! done[0]; done[0] = 0;s_state = waiting_for_task; }
		:: (done[1]==1) -> atomic { client_r[1] ! done[1]; done[1] = 0; s_state = waiting_for_task; }
		:: (done[2]==1) -> atomic { client_r[2] ! done[2]; done[2] = 0; s_state = waiting_for_task; }
		:: (done[3]==1) -> atomic { client_r[3] ! done[3]; done[3] = 0;s_state = waiting_for_task; }

		fi
	od
}


proctype am()
{	
	
	a_state = ready;
	byte m[3];
	m[0]=255;
	m[1]=255; 
	m[2]=255;
	byte temp;
	do
	:: (a_state == ready && (counter<3) )-> atomic { c_am? temp; m[counter] = temp;  a_state = processing;} 
	:: (a_state == processing) -> 
		if
		:: (m[0]!=255) -> atomic {  d_am! m[0]; counter = counter-1; a_state = finish;}
		:: (m[1]!=255) -> atomic {  d_am! m[1]; counter = counter-1; a_state = finish;}
		:: (m[2]!=255) ->atomic {  d_am! m[2]; counter = counter-1; a_state = finish;}
		fi
	:: (a_state == finish) ->  a_state = ready;
	od
}

init
{	atomic{
		
		run client(0);
		run client(1);
		run client(2);
		run client(3);
		run server();	
		run am();

	}

	
	
}















