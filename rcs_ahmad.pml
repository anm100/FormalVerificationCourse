 #define N 4

mtype = { start,prewait, wait, receive, server_ready,sleeping, sending_to_am, receiving_from_am,  ready, processing, finish};

chan client_s[4] = [0] of {byte};
chan client_r[4] =  [0] of {byte};


int counter = 0;

mtype cstate[N];
mtype a_state;
mtype s_state;
byte done[N];
ltl r1 {[]<>(s_state==processing)}
ltl r2 {([]<>(cstate[0]==wait)-><>(cstate[0]==receive)) }
ltl r21 {[]((cstate[0]==wait)-><>(cstate[0]==receive))}

ltl r3 {[](counter <4)}
ltl r4 {[]((cstate[0]==wait ||cstate[1]==wait ||cstate[2]==wait ||cstate[3]==wait)->(s_state!=sleeping)) }
ltl test {<> (s_state==sleeping)}

proctype client(byte index)
{
	byte msgs = index;
	byte msgr;
	cstate[index] = start;

	do
	:: (cstate[index] == start) -> atomic {client_s[index] ! msgs;cstate[index] = prewait;}
	:: (cstate[index] == prewait) -> atomic {cstate[index] = wait;}
	:: (cstate[index] == wait) -> atomic {client_r[index] ? msgr; cstate[index] = receive;}
	:: (cstate[index] == receive) -> cstate[index] = start;
	od
}
proctype server()
{	
	byte task[N]=255;
	byte temp;
	s_state = processing;

	do
	:: (s_state == server_ready) ->
		if

		::(task[0]!=255 || task[1]!=255 || task[2]!=255 || task[3]!=255)->atomic {s_state = processing}
		fi
	:: (s_state == processing) -> 
		if
		::atomic {client_s[0] ? task[0];done[0]=0;s_state = processing;}
		::atomic {client_s[1] ? task[1];done[0]=0; s_state = processing;}
		::atomic {client_s[2] ? task[2];done[0]=0; s_state = processing;}
		::atomic {client_s[3] ? task[3];done[0]=0; s_state = processing;}
		::(done[0]==0 && task[0]!=255 && counter<3) ->atomic{done[0]=1;counter = counter+1; s_state = processing;}
		:: (done[1]==0 && task[1]!=255 && counter<3) ->atomic{done[1]=1;counter = counter+1; s_state = processing;}
		:: (done[2]==0 && task[2]!=255 && counter<3)->atomic{done[2]=1;counter = counter+1; s_state = processing;}
		:: (done[3]==0 && task[3]!=255 && counter<3)->atomic{done[3]=1;counter = counter+1; s_state = processing;}
		::(done[0]==1 && task[0]!=255 && counter>0) ->atomic{done[0]=1;client_r[0] ! 10;task[0]=255;counter = counter-1; s_state = processing;}
		:: (done[1]==1 && task[1]!=255 && counter>0) ->atomic{done[1]=1;client_r[1] ! 10;task[1]=255;counter = counter-1; s_state = processing;}
		:: (done[2]==1&& task[2]!=255 && counter>0)->atomic{done[2]=1;client_r[2] ! 10;task[2]=255;counter = counter-1; s_state = processing;}
		:: (done[3]==1 && task[3]!=255 && counter>0)->atomic{done[3]=1;client_r[3] ! 10;task[3]=255;counter = counter-1; s_state = processing;}
		::(task[0]==255 && task[1]==255 && task[2]==255 && task[3]==255)-> atomic {s_state = sleeping;}
		fi
	:: (s_state == sleeping) ->
		if
		::atomic {client_s[0] ? task[0];counter = counter+1; s_state = processing;}
		::atomic {client_s[1] ? task[1];counter = counter+1; s_state = processing;}
		::atomic {client_s[2] ? task[2];counter = counter+1; s_state = processing;}
		::atomic {client_s[3] ? task[3];counter = counter+1; s_state = processing;}
		fi
	od
}



init
{	atomic{
		
		run client(0);
		run client(1);
		run client(2);
		run client(3);
		run server();	

	}

	
	
}















