function [PL , PL_64, PL_110, PL_1518, APD, APD_64, APD_110, APD_1518 , MPD , TT] = Simulator1A(lambda,C,f,P)  % extra -> 64, 110, 1518
% INPUT PARAMETERS:
%  lambda - packet rate (packets/sec)
%  C      - link bandwidth (Mbps)
%  f      - queue size (Bytes)
%  P      - number of packets (stopping criterium)
% OUTPUT PARAMETERS:
%  PL   - packet loss (%)
%  APD  - average packet delay (milliseconds)
%  MPD  - maximum packet delay (milliseconds)
%  TT   - transmitted throughput (Mbps)

%Events:
ARRIVAL= 0;       % Arrival of a packet            
DEPARTURE= 1;     % Departure of a packet

%State variables:
STATE = 0;          % 0 - connection is free; 1 - connection is occupied
QUEUEOCCUPATION= 0; % Occupation of the queue (in Bytes)
QUEUE= [];          % Size and arriving time instant of each packet in the queue

%Statistical Counters:
TOTALPACKETS= 0;     % No. of packets arrived to the system
TOTALPACKETS_64= 0;
TOTALPACKETS_110= 0;
TOTALPACKETS_1518= 0;
LOSTPACKETS= 0;      % No. of packets dropped due to buffer overflow
LOSTPACKETS_64= 0;
LOSTPACKETS_110= 0;
LOSTPACKETS_1518= 0;
TRANSPACKETS= 0;     % No. of transmitted packets
TRANSPACKETS_64= 0;
TRANSPACKETS_110= 0;
TRANSPACKETS_1518= 0;
TRANSBYTES= 0;       % Sum of the Bytes of transmitted packets
DELAYS= 0;           % Sum of the delays of transmitted packets
DELAYS_64= 0;
DELAYS_110= 0;
DELAYS_1518= 0;
MAXDELAY= 0;         % Maximum delay among all transmitted packets

% Initializing the simulation clock:
Clock= 0;

% Initializing the List of Events with the first ARRIVAL:
tmp= Clock + exprnd(1/lambda);
Event_List = [ARRIVAL, tmp, GenerateDataPacketSize(), tmp];

%Similation loop:
while TRANSPACKETS<P                     % Stopping criterium
    Event_List= sortrows(Event_List,2);  % Order EventList by time
    Event= Event_List(1,1);                 % Get first event 
    Clock= Event_List(1,2);                 %    and all
    PacketSize= Event_List(1,3);            %    associated
    ArrInstant= Event_List(1,4);            %    parameters.
    Event_List(1,:)= [];                 % Eliminate first event
    switch Event
        case ARRIVAL         % If first event is an ARRIVAL
            TOTALPACKETS= TOTALPACKETS+1;
            if PacketSize == 64
                TOTALPACKETS_64 = TOTALPACKETS_64 + 1;
            elseif PacketSize == 110
                TOTALPACKETS_110 = TOTALPACKETS_110 + 1;
            elseif PacketSize == 1518
                TOTALPACKETS_1518 = TOTALPACKETS_1518 + 1;
            end
            tmp= Clock + exprnd(1/lambda);
            Event_List = [Event_List; ARRIVAL, tmp, GenerateDataPacketSize(), tmp];
            if STATE==0
                STATE= 1;
                Event_List = [Event_List; DEPARTURE, Clock + 8*PacketSize/(C*1e6), PacketSize, Clock];
            else
                if QUEUEOCCUPATION + PacketSize <= f
                    QUEUE= [QUEUE;PacketSize , Clock];
                    QUEUEOCCUPATION= QUEUEOCCUPATION + PacketSize;
                else
                    LOSTPACKETS= LOSTPACKETS + 1;
                    if PacketSize == 64
                        LOSTPACKETS_64 = LOSTPACKETS_64 + 1;
                    elseif PacketSize == 110
                        LOSTPACKETS_110 = LOSTPACKETS_110 + 1;
                    elseif PacketSize == 1518
                        LOSTPACKETS_1518 = LOSTPACKETS_1518 + 1;
                    end
                end
            end
        case DEPARTURE          % If first event is a DEPARTURE
            TRANSBYTES= TRANSBYTES + PacketSize;
            DELAYS= DELAYS + (Clock - ArrInstant);
            if PacketSize == 64
                DELAYS_64 = DELAYS_64 + (Clock - ArrInstant);
            elseif PacketSize == 110
                DELAYS_110 = DELAYS_110 + (Clock - ArrInstant);
            elseif PacketSize == 1518
                DELAYS_1518 = DELAYS_1518 + (Clock - ArrInstant);
            end
            if Clock - ArrInstant > MAXDELAY
                MAXDELAY= Clock - ArrInstant;
            end
            TRANSPACKETS= TRANSPACKETS + 1;
            if PacketSize == 64
                TRANSPACKETS_64 = TRANSPACKETS_64 + 1;
            elseif PacketSize == 110
                TRANSPACKETS_110 = TRANSPACKETS_110 + 1;
            elseif PacketSize == 1518
                TRANSPACKETS_1518 = TRANSPACKETS_1518 + 1;
            end
            if QUEUEOCCUPATION > 0
                QSize= QUEUE(1,1);
                QInstant= QUEUE(1,2);
                Event_List = [Event_List; DEPARTURE, Clock + 8*QSize/(C*1e6), QSize, QInstant];
                QUEUEOCCUPATION= QUEUEOCCUPATION - QSize;
                QUEUE(1,:)= [];
            else
                STATE= 0;
            end
    end
end

%Performance parameters determination:
PL= 100*LOSTPACKETS/TOTALPACKETS;  % in percentage
APD= 1000*DELAYS/TRANSPACKETS;     % in milliseconds
MPD= 1000*MAXDELAY;                % in milliseconds
TT= 1e-6*TRANSBYTES*8/Clock;       % in Mbps

PL_64 = 100*LOSTPACKETS_64/TOTALPACKETS_64;
PL_110 = 100*LOSTPACKETS_110/TOTALPACKETS_110;
PL_1518 = 100*LOSTPACKETS_1518/TOTALPACKETS_1518;

APD_64= 1000*DELAYS_64/TRANSPACKETS_64;
APD_110= 1000*DELAYS_110/TRANSPACKETS_110;
APD_1518= 1000*DELAYS_1518/TRANSPACKETS_1518;
end

function out= GenerateDataPacketSize()
    aux= rand();
    aux2= [65:109 111:1517];
    if aux <= 0.19
        out= 64;
    elseif aux <= 0.19 + 0.23
        out= 110;
    elseif aux <= 0.19 + 0.23 + 0.17
        out= 1518;
    else
        out = aux2(randi(length(aux2)));
    end
end