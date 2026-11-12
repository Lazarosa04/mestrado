function [PL , APD , MPD , TT] = Sim3FlowsPrioT(lambda,C,f,P, prio)
% INPUT PARAMETERS:
%  lambda - row vector with the packet rate of each flow (packets/sec)
%  C      - link bandwidth (Mbps)
%  f      - vector of the queue sizes of the three flows (Bytes)
%  P      - number of packets (stopping criterium)
%  prio   - 1 if flow 3 has priority, 0 if flows 1/2 have priority
% OUTPUT PARAMETERS:
%  PL   - row vector with the packet loss (%) of each flow
%  APD  - row vector with the average packet delay (milliseconds) of each flow
%  MPD  - maximum packet delay (milliseconds) of each flow
%  TT   - transmitted throughput (Mbps) of each flow

%Events:
ARRIVAL= 0;       % Arrival of a packet            
DEPARTURE= 1;     % Departure of a packet

%State variables:
STATE = 0;                      % 0 - connection is free; 1 - connection is occupied
QUEUEOCCUPATION= zeros(1,3);    % Occupation of the queues (in Bytes) 
QUEUE= {[] [] []};              % Size, arriving time instant and flowID of each packet in the queue, for the three queues

% Initializing the required Statistical Counters:
TOTALPACKETS= zeros(1,3);     % No. of packets of each flow arrived to the system
LOSTPACKETS= zeros(1,3);      % No. of packets of each flow lost due to buffer fulness
TRANSPACKETS= zeros(1,3);     % No. of transmitted packets of each flow
TRANSBYTES= zeros(1,3);       % Sum of the Bytes of all transmitted packets of each flow
DELAYS= zeros(1,3);           % Sum of the delays of all transmitted packets of each flow
MAXDELAY= zeros(1,3);         % Maximum delay among all transmitted packets of each flow

% Initializing the Simulation Clock:
Clock= 0;

% Each row of Event List:
% Row 1: Event Type
% Row 2: Time instant of event occurrence
% Row 3: Packet size
% Row 4: Flow ID of the packet
% Row 5: Time instant of the packet arrival to the system
%
% Initializing the List of Events with the first ARRIVAL of each flow:
tmp= Clock + exprnd(1/lambda(1));
EventList = [ARRIVAL, tmp, GenerateSize1(), 1, tmp];
tmp= Clock + exprnd(1/lambda(2));
EventList = [EventList; ARRIVAL, tmp, GenerateSize2(), 2, tmp];
tmp= Clock + exprnd(1/lambda(3));
EventList = [EventList; ARRIVAL, tmp, GenerateSize3(), 3, tmp];

% Simulation loop:
while sum(TRANSPACKETS)<P       % Simulation stopping criterion
    EventList= sortrows(EventList,2); % Order EventList by 2nd column (the time instant)
    Event= EventList(1,1);            % Get event 
    Clock= EventList(1,2);            % Get the time instant of the event 
    PacketSize= EventList(1,3);       % Get the packet size of the event
    Flow= EventList(1,4);             % Get the flow ID of the packet
    ArrInstant= EventList(1,5);       % Get the arriving instant of the packet
    EventList(1,:)= [];               % Eliminate first event from the EventList
    switch Event
        case ARRIVAL         % If event is an ARRIVAL
            TOTALPACKETS(Flow)= TOTALPACKETS(Flow)+1;
            tmp= Clock + exprnd(1/lambda(Flow));
            switch Flow
                case 1
                    nextPacketSize= GenerateSize1();
                case 2
                    nextPacketSize= GenerateSize2();
                case 3
                    nextPacketSize= GenerateSize3();
            end
            EventList = [EventList; ARRIVAL, tmp, nextPacketSize, Flow, tmp];
            if STATE==0
                STATE= 1;
                EventList = [EventList; DEPARTURE, Clock + 8*PacketSize/(C*1e6), PacketSize, Flow, Clock];
            else
                if QUEUEOCCUPATION(Flow) + PacketSize <= f(Flow)
                    QUEUE{Flow}= [QUEUE{Flow}; PacketSize , Clock, Flow];
                    QUEUEOCCUPATION(Flow)= QUEUEOCCUPATION(Flow) + PacketSize;
                else
                    LOSTPACKETS(Flow)= LOSTPACKETS(Flow) + 1;
                end
            end
        case DEPARTURE          % If event is a DEPARTURE
            TRANSBYTES(Flow)= TRANSBYTES(Flow) + PacketSize;
            TRANSPACKETS(Flow)= TRANSPACKETS(Flow) + 1;
            DELAYS(Flow)= DELAYS(Flow) + (Clock - ArrInstant);
            if Clock - ArrInstant > MAXDELAY(Flow)
                MAXDELAY(Flow)= Clock - ArrInstant;
            end
            QFlow = 0;
            if prio == 1
                if QUEUEOCCUPATION(3) > 0
                    QFlow = 3;
                elseif QUEUEOCCUPATION(1) > 0 && QUEUEOCCUPATION(2) > 0
                    Q1Instant = QUEUE{1}(1, 2);
                    Q2Instant = QUEUE{2}(1, 2);
                    if Q1Instant <= Q2Instant
                        QFlow = 1;
                    else
                        QFlow = 2;
                    end
                elseif QUEUEOCCUPATION(1) > 0
                    QFlow = 1;
                elseif QUEUEOCCUPATION(2) > 0
                    QFlow = 2;
                else
                    STATE = 0;
                end
            elseif prio == 0
                if QUEUEOCCUPATION(1) > 0 && QUEUEOCCUPATION(2) > 0
                    Q1Instant = QUEUE{1}(1,2);
                    Q2Instant = QUEUE{2}(1,2);
                    if Q1Instant <= Q2Instant
                        QFlow = 1;
                    else
                        QFlow = 2;
                    end
                elseif QUEUEOCCUPATION(1) > 0
                    QFlow = 1;
                elseif QUEUEOCCUPATION(2) > 0
                    QFlow = 2;
                elseif QUEUEOCCUPATION(3) > 0
                    QFlow = 3;
                else
                    STATE = 0;
                end
            else
                STATE = 0;
            end
            if QFlow > 0
                QSize = QUEUE{QFlow}(1, 1);
                QInstant = QUEUE{QFlow}(1, 2);
                EventList = [EventList; DEPARTURE, ...
                    Clock + 8*QSize/(C*1e6), QSize, QFlow, QInstant];
                QUEUEOCCUPATION(QFlow) = QUEUEOCCUPATION(QFlow) - QSize;
                QUEUE{QFlow}(1, :) = [];
            end
    end
end

% Performance parameters determination:
PL= 100*LOSTPACKETS./TOTALPACKETS;  % in percentage
APD= 1000*DELAYS./TRANSPACKETS;     % in milliseconds
MPD= 1000*MAXDELAY;                % in milliseconds
TT= 1e-6*TRANSBYTES*8/Clock;       % in Mbps

end


% Flow  1  with  a  random  packet  size  between  100  and  1500  bytes  (all  values  with  equal probability)
function out= GenerateSize1()
    out= randi([100 1500]);
end

% Flow  2  with  a  random  packet  size  between  100  and  150  bytes  (all  values  with  equal probability) 
function out= GenerateSize2()
    out= randi([100 150]);
end

% Flow  3  with  a  random  packet  size  between  500  and  1000  bytes  (all  values  with  equal probability)
function out= GenerateSize3()
    out= randi([500 1000]);
end