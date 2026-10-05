%% ex 7

% a)
% consider the n additional VoIP packet flows.
% Consider that packets of all flows (data and VoIP) are queued on a
% single queue served with a FIFO scheduling discipline. 
% The input parameters of Simulator3 should be all the input parameters of 
% Simulator1 plus parameter n.

function [PL , PL_v, APD, ADP_v , MPD, MPD_v , TT] = Simulator4(lambda,C,f,P,n)
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
TOTALPACKETS_v = 0;
LOSTPACKETS= 0;      % No. of packets dropped due to buffer overflow
LOSTPACKETS_v = 0;
TRANSPACKETS= 0;     % No. of transmitted packets
TRANSPACKETS_v = 0;
TRANSBYTES= 0;       % Sum of the Bytes of transmitted packets
DELAYS= 0;           % Sum of the delays of transmitted packets
DELAYS_v = 0;
MAXDELAY= 0;         % Maximum delay among all transmitted packets
MAXDELAY_v = 0;

% Initializing the simulation clock:
Clock= 0;

% Initializing the List of Events with the first ARRIVAL:
tmp= Clock + exprnd(1/lambda);
Event_List = [ARRIVAL, tmp, GenerateDataPacketSize(), tmp, 0];

% First VoIP arrivals -> 0 to 20 ms
for i = 1:n
    tmp = 0.02*rand;
    Event_List = [Event_List; ARRIVAL, tmp, randi([110,130]), tmp, 1];
end

%Similation loop:
while TRANSPACKETS + TRANSPACKETS_v <P                     % Stopping criterium
    Event_List= sortrows(Event_List,2);  % Order EventList by time
    Event= Event_List(1,1);                 % Get first event 
    Clock= Event_List(1,2);                 %    and all
    PacketSize= Event_List(1,3);            %    associated
    ArrInstant= Event_List(1,4);            %    parameters
    Type = Event_List(1,5);                 %    type packet
    Event_List(1,:)= [];                 % Eliminate first event
    switch Event
            case ARRIVAL         % If first event is an ARRIVAL
                if Type == 0
                    TOTALPACKETS= TOTALPACKETS+1;
                    tmp= Clock + exprnd(1/lambda);
                    Event_List = [Event_List; ARRIVAL, tmp, GenerateDataPacketSize(), tmp, 0];
                else
                    TOTALPACKETS_v = TOTALPACKETS_v + 1;
                    tmp = Clock + 0.016 + 0.008 * rand;
                    Event_List = [Event_List; ARRIVAL, tmp, randi([110,130]), tmp, 1];
                end
                
                if STATE==0
                    STATE= 1;
                    Event_List = [Event_List; DEPARTURE, Clock + 8*PacketSize/(C*1e6), PacketSize, Clock, Type];
                else
                    if QUEUEOCCUPATION + PacketSize <= f
                        QUEUE= [QUEUE;PacketSize , Clock, Type];
                        QUEUEOCCUPATION= QUEUEOCCUPATION + PacketSize;
                    else
                        if Type == 0
                            LOSTPACKETS= LOSTPACKETS + 1;
                        else
                            LOSTPACKETS_v = LOSTPACKETS_v + 1;
                        end
                    end
                end
            case DEPARTURE          % If first event is a DEPARTURE
                TRANSBYTES= TRANSBYTES + PacketSize;
                if Type == 0
                    DELAYS= DELAYS + (Clock - ArrInstant);
                    if Clock - ArrInstant > MAXDELAY
                       MAXDELAY= Clock - ArrInstant;
                    end
                    TRANSPACKETS= TRANSPACKETS + 1;
                else
                    DELAYS_v = DELAYS_v + (Clock - ArrInstant);
                    if Clock - ArrInstant > MAXDELAY_v
                       MAXDELAY_v= Clock - ArrInstant;
                    end
                    TRANSPACKETS_v= TRANSPACKETS_v + 1;
                end

                if QUEUEOCCUPATION > 0
                    % procurar por void packets, procurar por quem tem Type = 1
                    idx_voip = find((QUEUE(:,3)==1), 1);
                    if ~isempty(idx_voip)
                        QSize= QUEUE(idx_voip,1);
                        QInstant= QUEUE(idx_voip,2);
                        QType = QUEUE(idx_voip,3);
                        QUEUE(idx_voip, :) = [];  % remove o pacote escolhido
                    else
                        QSize= QUEUE(1,1);
                        QInstant= QUEUE(1,2);
                        QType = QUEUE(1,3);
                        QUEUE(1,:)= [];
                    end
                    Event_List = [Event_List; DEPARTURE, Clock + 8*QSize/(C*1e6), QSize, QInstant, QType];
                    QUEUEOCCUPATION= QUEUEOCCUPATION - QSize;
                else
                    STATE= 0;
                end
    end
end

%Performance parameters determination:
PL   = 100*LOSTPACKETS   / TOTALPACKETS;  % in percentage
PL_v = 100*LOSTPACKETS_v / TOTALPACKETS_v;
APD  = 1000*DELAYS       / TRANSPACKETS;  % in milliseconds
ADP_v = 1000*DELAYS_v    / TRANSPACKETS_v;
MPD   = 1000*MAXDELAY;                    % in milliseconds
MPD_v = 1000*MAXDELAY_v;
TT   = 1e-6*TRANSBYTES*8/Clock;       % in Mbps

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