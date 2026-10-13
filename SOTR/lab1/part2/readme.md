# Base code - inverted pendulum
C programs that simulates the dynamics of an inverted pendulum and provides a suitable controller. 

As is, the application don't use Linux RT services

#Compile with:
gcc -O2 -Wall inverted_pendulum.c -o inverted_pendulum -lpthread -lm

#Run:
./inverted_pendulum

And in another terminal stress the PC, e.g.

sudo nice -n -20 stress-ng     --cpu $(nproc)   --cache 2  --switch 2     --schedmix 2   --vm 6  --timeout 30s

Actual impact depends on HW. Some tunning can be required

## Real-time message-queue implementation and periodic load

`inverted pendulum_TT_ET_MQ.c` separates the plant, periodic Sensor,
message-triggered Controller and Actuator, and ASCII display into threads.
The periodic load task is configurable so its effect can be measured rather
than inferred from the animation alone.

Build and run it in Linux/WSL from this directory:

```bash
gcc -O2 -Wall "inverted pendulum_TT_ET_MQ.c" \
  -o /tmp/inverted_pendulum_rt -pthread -lm -lrt
sudo /tmp/inverted_pendulum_rt
```

The RT threads use `SCHED_FIFO`; the process therefore needs suitable
real-time scheduling permission (for example, root or `CAP_SYS_NICE`). The
program reports an error and exits if that permission is unavailable.

The optional arguments configure the periodic load:

```text
-n                 Disable the periodic load task (baseline run)
-p period_us       1000..100000 us; default 5000 us
-e execution_us    100 us..90% of period_us; default 500 us
-r priority        SCHED_FIFO priority; default is below the Actuator
-h                 Show options
```

For example, this produces a 50% load every 5 ms, at priority 99:

```bash
sudo /tmp/inverted_pendulum_rt -p 5000 -e 2500 -r 99
```

The load task measures its job execution using its own CPU time, so being
preempted does not count toward its configured execution time. Its nominal CPU
utilization is `execution_us / period_us`; for a 5 ms period, 250, 1000, 2500,
and 4000 us correspond to 5%, 20%, 50%, and 80%. Execution is capped at 90%
of the period to leave CPU time for the simulation and shutdown.

The plant period is 1 ms and Sensor period is 5 ms. The default load priority
is lower than the Actuator, so it should have little effect on control jobs.
Raising the load priority to 96, 97, 98, or 99 makes it equal in priority to
Actuator, Controller, Sensor, or Plant, respectively (assuming Linux
`SCHED_FIFO` priorities 1..99). Equal-priority FIFO jobs do not preempt one
another, so a CPU-bound load job can delay a same-priority task until the load
blocks at the end of its execution. Higher-priority periodic tasks can still
preempt it. Near-100% utilization or priorities 98/99 can therefore introduce
substantial lateness and distort the simulation; test those settings only
briefly.

For a controlled comparison, use the same executable and run duration:

```bash
sudo /tmp/inverted_pendulum_rt -n
sudo /tmp/inverted_pendulum_rt -p 5000 -e 4000 -r 99
```

The first run disables the load task. The second consumes a nominal 80% CPU at
priority 99, equal to the Plant priority. Compare the Plant maximum activation
lateness, deadline lateness, and missed jobs first; a same-priority load can
delay the Plant even when the animation looks steady. Also compare the Sensor
metrics. A Plant job's deadline is 1 ms after its scheduled activation; a
Sensor job's deadline is 5 ms after its scheduled activation. The program
prints the load configuration and utilization at startup, reports metrics
after 60 seconds, and indicates whether the load task was enabled.

For a wider study, keep the period at 5000 us and compare execution times of
250, 1000, 2500, and 4000 us at priorities 95, 97, and 99. Change only one
parameter between runs. Expect priority 95 to have little effect on the
control tasks, while 99 should affect the Plant more clearly. The observed
result depends on CPU affinity and host scheduling; repeat runs and compare
the measurements rather than relying on the display alone.
