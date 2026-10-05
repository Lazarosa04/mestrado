%% ex 6

% a)
% The input parameters of Simulator2 must be all the input parameters of 
% Simulator1 plus parameter b and The stopping criterion of Simulator2 must
% be the time instant when the link finishes the transmission of the packet
% without errors

function [PL , APD , MPD , TT] = Simulator2(lambda, C, f, P, b)
% INPUT PARAMETERS:
%  lambda - packet rate (packets/sec)
%  C      - link bandwidth (Mbps)
%  f      - queue size (Bytes)
%  P      - number of correctly transmitted packets (stopping criterion)
%  b      - bit error rate (BER)
%
% OUTPUT PARAMETERS:
%  PL   - packet loss (%)
%  APD  - average packet delay (milliseconds)
%  MPD  - maximum packet delay (milliseconds)
%  TT   - transmitted throughput (Mbps)

%Events:
ARRIVAL   = 0;    % Arrival of a packet            
DEPARTURE = 1;    % Departure of a packet

%State variables:
STATE = 0;                % 0 - connection free; 1 - connection occupied
QUEUEOCCUPATION = 0;      % Queue occupation (Bytes)
QUEUE = [];               % [PacketSize, ArrivalTime]

%Statistical counters:
TOTALPACKETS = 0;         % Total number of packets arrived to the system
LOSTPACKETS  = 0;         % Packets lost (queue overflow + transmission errors)
TRANSPACKETS = 0;         % Total transmitted packets (with or without errors)
GOODPACKETS  = 0;         % Successfully transmitted packets (no errors)
TRANSBYTES   = 0;         % Sum of Bytes of correctly transmitted packets
DELAYS       = 0;         % Sum of delays of correctly transmitted packets
MAXDELAY     = 0;         % Maximum delay among correctly transmitted packets

% Simulation clock:
Clock = 0;

% Initialize Event List with first ARRIVAL:
tmp = Clock + exprnd(1/lambda);
Event_List = [ARRIVAL, tmp, GenerateDataPacketSize(), tmp];

% ---------------- SIMULATION LOOP ----------------
while GOODPACKETS < P
    Event_List = sortrows(Event_List, 2);   % Order by time
    Event      = Event_List(1, 1);
    Clock      = Event_List(1, 2);
    PacketSize = Event_List(1, 3);
    ArrInstant = Event_List(1, 4);
    Event_List(1, :) = [];                  % Remove processed event

    switch Event
        case ARRIVAL
            TOTALPACKETS = TOTALPACKETS + 1;

            % Schedule next arrival:
            tmp = Clock + exprnd(1/lambda);
            Event_List = [Event_List; ARRIVAL, tmp, GenerateDataPacketSize(), tmp];

            if STATE == 0
                % Link free -> start transmission immediately
                STATE = 1;
                Event_List = [Event_List; DEPARTURE, Clock + 8*PacketSize/(C*1e6), PacketSize, Clock];
            else
                % Link busy -> check if packet fits in queue
                if QUEUEOCCUPATION + PacketSize <= f
                    QUEUE = [QUEUE; PacketSize, Clock];
                    QUEUEOCCUPATION = QUEUEOCCUPATION + PacketSize;
                else
                    % Packet lost (queue overflow)
                    LOSTPACKETS = LOSTPACKETS + 1;
                end
            end

        case DEPARTURE
            TRANSPACKETS = TRANSPACKETS + 1;

            % ----- Channel error check -----
            % Probability that the packet has at least one bit error:
            % P_erro = 1 - P_NO_erro = 1 - (1-b)^(n_bits do pacote)
            if rand() < (1 - (1 - b)^(8 * PacketSize))
                % Packet lost due to transmission error
                LOSTPACKETS = LOSTPACKETS + 1;
            else
                % Packet successfully transmitted
                TRANSBYTES = TRANSBYTES + PacketSize;
                DELAYS = DELAYS + (Clock - ArrInstant);
                if (Clock - ArrInstant) > MAXDELAY
                    MAXDELAY = Clock - ArrInstant;
                end
                GOODPACKETS = GOODPACKETS + 1;
            end

            % ----- Next packet transmission -----
            if QUEUEOCCUPATION > 0
                QSize = QUEUE(1, 1);
                QInstant = QUEUE(1, 2);
                Event_List = [Event_List; DEPARTURE, Clock + 8*QSize/(C*1e6), QSize, QInstant];
                QUEUEOCCUPATION = QUEUEOCCUPATION - QSize;
                QUEUE(1, :) = [];
            else
                STATE = 0;
            end
    end
end

% ---------------- PERFORMANCE METRICS ----------------
PL  = 100 * LOSTPACKETS / TOTALPACKETS;   % Packet loss (%)
APD = 1000 * DELAYS / GOODPACKETS;        % Average packet delay (ms)
MPD = 1000 * MAXDELAY;                    % Maximum packet delay (ms)
TT  = 1e-6 * TRANSBYTES * 8 / Clock;      % Throughput (Mbps)

end

% -----------------------------------------------------
function out = GenerateDataPacketSize()
    aux = rand();
    aux2 = [65:109 111:1517];
    if aux <= 0.19
        out = 64;
    elseif aux <= 0.19 + 0.23
        out = 110;
    elseif aux <= 0.19 + 0.23 + 0.17
        out = 1518;
    else
        out = aux2(randi(length(aux2)));
    end
end
