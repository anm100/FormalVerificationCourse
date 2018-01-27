#define N 4

mtype = { start, wait, connected, waiting_for_task, sending_to_am, receiving_from_am,  ready, processing, finish};

chan client_s[5] = [1] of {byte};
chan client_r[5] = [1] of {byte};

chan d_am = [0] of {byte};
chan c_am = [0] of {byte};

proctype client(byte index)
{
	mtype state = start;
	byte msg_s = index, msg_r = 0;

	do
	:: (state == start) -> atomic {client_s[index]! msg_s; state = wait;}
	:: (state == wait) -> 	atomic {client_r[index]? 1; state = connected;}
	:: (state == connected) -> state = start;
	od
}

proctype server()
{	
	mtype state = waiting_for_task;
	byte done[N]=0, task[N]=0, temp;
	do
	:: (state == waiting_for_task) ->
		if
		:: atomic {client_s[0]? task[0]; state = sending_to_am;}
		:: atomic {client_s[1]? task[1]; state = sending_to_am;}
		:: atomic {client_s[2]? task[2]; state = sending_to_am;}
		:: atomic {client_s[3]? task[3]; state = sending_to_am;}
		:: atomic {client_s[4]? task[4]; state = sending_to_am;}
		fi
	:: (state == waiting_for_task) -> atomic{d_am? temp; done[temp] = 1; state = receiving_from_am;}
	:: (state == sending_to_am) -> 
		if
		:: atomic {c_am! task[0]; state = waiting_for_task;}
		:: atomic {c_am! task[1]; state = waiting_for_task;}
		:: atomic {c_am! task[2]; state = waiting_for_task;}
		:: atomic {c_am! task[3]; state = waiting_for_task;}
		:: atomic {c_am! task[4]; state = waiting_for_task;}
		fi
	:: (state == receiving_from_am) -> 
		if
		:: atomic {c_am! task[0]; state = waiting_for_task;}
		:: atomic {c_am! task[1]; state = waiting_for_task;}
		:: atomic {c_am! task[2]; state = waiting_for_task;}
		:: atomic {c_am! task[3]; state = waiting_for_task;}
		:: atomic {c_am! task[4]; state = waiting_for_task;}
		fi
	od
}

proctype am()
{	
	mtype state = ready;
	byte m[3] = 0, counter = 0, temp;
	do
	:: (state == ready)-> atomic { c_am? temp; m[counter] = temp; counter++; state = processing;} 
	:: (state == processing) && (counter<4) -> state = ready;
	:: (state == processing) -> 
		if
		:: atomic { (m[0]!=0) -> d_am! m[0]; counter--; state = finish;}
		:: atomic { (m[1]!=0) -> d_am! m[1]; counter--; state = finish;}
		:: atomic { (m[2]!=0) -> d_am! m[2]; counter--; state = finish;}
		:: atomic { (m[3]!=0) -> d_am! m[3]; counter--; state = finish;}
		fi
	od
}

init
{
	byte counter = N;
	
	run server();
                run am();
	do
	::	(counter >= 0) -> atomic {run client(counter); counter--;}
	od
	
}

