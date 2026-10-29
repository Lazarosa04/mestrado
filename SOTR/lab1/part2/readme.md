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

## Shared-memory and POSIX semaphore implementation

`inverted_pendulum_TT_ET_SEM_SHM.c` replaces both message queues with a POSIX
shared-memory region (`shm_open`/`mmap`) and process-shared POSIX semaphores.
The Sensor publishes the four state values and signals the Controller; the
Controller stores the LQR force and signals the Actuator; the Actuator updates
`g_state.force` and releases the slot for the next sample. The slot semaphore
prevents a producer from overwriting shared data before the next task consumes
it, preserving Sensor → Controller → Actuator order with only one sample in
flight. If the chain takes longer than the Sensor period, the next Sensor
activation waits for the previous Actuator update before sampling again.

Build and run this variant with the same real-time permissions and optional
load arguments:

```bash
gcc -O2 -Wall "inverted_pendulum_TT_ET_SEM_SHM.c" \
  -o /tmp/inverted_pendulum_sem_shm -pthread -lm -lrt
sudo /tmp/inverted_pendulum_sem_shm
```

For a baseline without the periodic load, add `-n`; the other load options
(`-p`, `-e`, and `-r`) work as described above. The shared-memory object and
semaphores are cleaned up when the program exits.

### Task timing, Gantt chart, and schedulability

The SEM/SHM executable records one row per job for Plant, Sensor, Controller,
Actuator, periodic Load (when enabled), and Display. Each row has the scheduled
release time, actual start/finish times, and thread CPU execution time in
nanoseconds. Release/start/finish are relative to the run; the additional
`run_origin_monotonic_ns` column contains the `CLOCK_MONOTONIC` start value
needed to align these timestamps with a kernel trace. The default output is
`task_trace.csv`; use `-t path.csv` to choose another file. The trace adds
clock-read and in-memory logging overhead to each measured job.

Generate an SVG Gantt chart using Python's standard library (no plotting
package required). A short window makes the 1 ms Plant activations readable:

```bash
sudo /tmp/inverted_pendulum_sem_shm -n -t task_trace.csv
python3 plot_task_gantt.py task_trace.csv --start-ms 0 --duration-ms 50 \
  --output task_gantt.svg
```

The bars show each job's wall-clock start-to-finish interval. Hover over a bar
in an SVG-capable viewer to see its release, start, finish, wall duration, and
CPU time. The difference between wall duration and CPU time includes time
preempted or blocked; use kernel scheduling traces to distinguish those cases.
Use `--start-ms` to inspect later sections of the 60 second run.

For Linux systems with `trace-cmd` and the scheduler tracepoints enabled, capture
the kernel's actual context switches and wakeups in a separate run. The task
threads are named Plant, Sensor, Controller, Actuator, Load, and Display for
identification in the trace:

```bash
sudo trace-cmd record -C mono -o pendulum-sched.dat \
  -e sched:sched_switch -e sched:sched_wakeup -e sched:sched_waking \
  /tmp/inverted_pendulum_sem_shm -n
sudo kernelshark pendulum-sched.dat
```

In KernelShark, filter or select those task names and compare their wakeups
and running intervals with the CSV. Add `run_origin_monotonic_ns` to a CSV
relative timestamp to obtain the corresponding monotonic timestamp.
`sched_switch` reveals preemptions that a single start/finish bar cannot show.
Kernel trace collection itself adds overhead, so compare it as a separate
diagnostic run.

Schedulability should be judged from every measured run, not inferred just
from a stable animation. For each periodic job, compare its finish time with
its next release/deadline: 1 ms for Plant and 5 ms for Sensor. For the
semaphore-triggered Controller and Actuator, check that each job follows its
preceding release and that the full Sensor-to-Actuator response fits within
the 5 ms sampling interval. The CSV supplies measured execution times and
response intervals; the summary reports Plant/Sensor deadline misses.
A measured utilization estimate for real-time work is
`Cplant/1 ms + (Csensor + Ccontroller + Cactuator)/5 ms + Cload/Tload`;
use per-task CPU times from the CSV for each `C`, and exclude Display, which
runs as `SCHED_OTHER`. This estimate helps identify overload but cannot prove
schedulability: check response times and misses across repeated runs, and use
worst-case execution-time/response-time analysis for a guarantee.
Normal Linux/WSL measurements are empirical and are not a hard real-time
guarantee.

### RT priority assignment

The RT task priorities are assigned in descending order (Linux
`SCHED_FIFO`, where a larger number is higher priority):

| Task | Period/activation | Priority |
|---|---|---:|
| Plant physics | 1 ms periodic | 99 |
| Sensor | 5 ms periodic | 98 |
| Controller | Released by Sensor semaphore | 97 |
| Actuator | Released by Controller semaphore | 96 |
| Periodic load (default) | Configurable periodic | 95 |
| Display | ~33 ms periodic | Normal `SCHED_OTHER` |

This is a rate-monotonic assignment for the periodic deadlines: the 1 ms
Plant receives the highest priority, and the 5 ms Sensor/Controller/Actuator
pipeline follows in its required execution order. The semaphores enforce the
data dependency as well as waking each sporadic task. The load stays below
the control pipeline by default. Raising it with `-r` is intended for
interference experiments, not the normal priority assignment; at equal
`SCHED_FIFO` priority, a running load job can delay the task until it blocks.
The plant-state mutex uses priority inheritance to bound inversion while
the higher-priority Plant accesses shared state.
