/* *********************************************************************
 * SOTR 26/27
 * 
 * Linux RT Services - base code
 * 
 * Paulo Pedreiras, /Sept 2026
 * 
 * This code implements a simulation of an Inverted Pendulum
 * It contains 6 tasks:
 * 	- THREAD 1: Plant Physics Simulator (Runs at 1 kHz / 1 ms period)
 * 	- THREAD 2: Periodic Sensor (Samples every 5 ms)
 * 	- THREAD 3: Sporadic Feedback Controller (Triggered by a semaphore)
 * 	- THREAD 4: Sporadic Actuator (Triggered by a semaphore)
 * 	- THREAD 5: ASCII Graphics Display (Low-Priority, ~30 Hz / 33 ms period)
 * 	- THREAD 6: Periodic CPU load (Configurable execution time, period and priority)
 * 	
 * The code is supposed to work "out-of-the-box".
 * The task periods could be different. Note however that changing  
 * them may require adjusting the controller, which is out of the 
 * scope of this course unit. So, keep the task periods consistent with
 * with the rates provided in this code.
 * 
 * Report any bugs to:
 * 	Paulo Pedreiras, pbrp@ua.pt
 * *********************************************************************/

#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <time.h>
#include <pthread.h>
#include <sched.h>
#include <stdatomic.h>
#include <sys/mman.h>
#include <semaphore.h>
#include <sys/stat.h>
#include <math.h>
#include <unistd.h>
#include <string.h>
#include <inttypes.h>

#define NSEC_PER_SEC 1000000000L
#define DEFAULT_LOAD_PERIOD_US 5000L
#define DEFAULT_LOAD_EXECUTION_US 500L
#define MIN_LOAD_PERIOD_US 1000L
#define MAX_LOAD_PERIOD_US 100000L
#define MIN_LOAD_EXECUTION_US 100L
#define TRACE_CAPACITY 500000U

typedef enum {
    TASK_PLANT,
    TASK_SENSOR,
    TASK_CONTROLLER,
    TASK_ACTUATOR,
    TASK_LOAD,
    TASK_DISPLAY,
    TASK_COUNT
} TaskId;

typedef struct {
    uint64_t release_ns;
    uint64_t start_ns;
    uint64_t finish_ns;
    uint64_t cpu_ns;
    uint64_t job;
    TaskId task;
} TraceRecord;

typedef struct {
    uint64_t release_ns;
    uint64_t job;
    TaskId task;
    struct timespec wall_start;
    struct timespec cpu_start;
    bool valid;
} TraceToken;

/* System Physical Parameters */
#define M_CART  1.0f   /* Cart mass (kg) */
#define M_POLE  0.1f   /* Pole mass (kg) */
#define LENGTH  0.5f   /* Half-pole length (m) */
#define GRAVITY 9.81f  /* Gravity (m/s^2) */

/* Visualization settings */
#define DISPLAY_WIDTH 60
#define POLE_CHAR_LEN 6

/* Shared State Buffer Structure */
typedef struct {
    float theta;       /* Pendulum angle (rad), 0 = upright */    
    float theta_dot;   /* Angular velocity (rad/s) */
    float x;           /* Cart position (m) */
    float x_dot;       /* Cart velocity (m/s) */
    float force;       /* Control force (N) */
} PlantState;

typedef struct {
    float theta;
    float theta_dot;
    float x;
    float x_dot;
} SensorData;

typedef struct {
    SensorData sensor_data;
    float control_force;
    uint64_t sensor_release_ns;
    uint64_t actuator_release_ns;
    sem_t sensor_slot_available;
    sem_t sensor_ready;
    sem_t actuator_ready;
} SharedControlData;

typedef struct {
    long period_us;
    long execution_us;
    int priority;
    bool enabled;
} LoadConfig;

static PlantState g_state = { .theta = 0.15f, .theta_dot = 0.0f, .x = 0.0f, .x_dot = 0.0f, .force = 0.0f };
static pthread_mutex_t g_state_mutex;
static atomic_bool g_running = ATOMIC_VAR_INIT(true);
static SharedControlData *g_shared_control;
static int64_t g_sensor_max_lateness_ns;
static int64_t g_sensor_max_deadline_lateness_ns;
static uint64_t g_sensor_missed_deadlines;
static uint64_t g_load_jobs;
static int64_t g_plant_max_lateness_ns;
static int64_t g_plant_max_deadline_lateness_ns;
static uint64_t g_plant_missed_deadlines;
static TraceRecord *g_trace_records;
static atomic_size_t g_trace_count;
static atomic_uint_fast64_t g_trace_overflow;
static uint64_t g_trace_origin_ns;

/* Helper: Add nanoseconds to timespec */
static void timespec_add_ns(struct timespec *t, long ns) {
    t->tv_nsec += ns;
    while (t->tv_nsec >= NSEC_PER_SEC) {
        t->tv_nsec -= NSEC_PER_SEC;
        t->tv_sec++;
    }
}

static int64_t timespec_diff_ns(const struct timespec *later,
                                const struct timespec *earlier) {
    return (int64_t)(later->tv_sec - earlier->tv_sec) * NSEC_PER_SEC +
           later->tv_nsec - earlier->tv_nsec;
}

static uint64_t timespec_to_ns(const struct timespec *value) {
    return (uint64_t)value->tv_sec * NSEC_PER_SEC + (uint64_t)value->tv_nsec;
}

static uint64_t trace_relative_ns(const struct timespec *value) {
    return timespec_to_ns(value) - g_trace_origin_ns;
}

static const char *task_name(TaskId task) {
    static const char *const names[TASK_COUNT] = {
        "Plant", "Sensor", "Controller", "Actuator", "Load", "Display"
    };
    return task < TASK_COUNT ? names[task] : "Unknown";
}

static void name_current_thread(TaskId task) {
    int error = pthread_setname_np(pthread_self(), task_name(task));
    if (error != 0) {
        fprintf(stderr, "Failed to name %s thread: %s\n",
                task_name(task), strerror(error));
    }
}

static TraceToken trace_begin(TaskId task, uint64_t job,
                              uint64_t release_ns) {
    TraceToken token = {
        .release_ns = release_ns,
        .job = job,
        .task = task,
        .valid = false
    };
    if (clock_gettime(CLOCK_MONOTONIC, &token.wall_start) == -1 ||
        clock_gettime(CLOCK_THREAD_CPUTIME_ID, &token.cpu_start) == -1) {
        perror("Failed to start task trace measurement");
        atomic_store(&g_running, false);
        return token;
    }
    token.valid = true;
    return token;
}

static void trace_finish(const TraceToken *token) {
    struct timespec wall_finish;
    struct timespec cpu_finish;
    if (!token->valid) {
        return;
    }
    if (clock_gettime(CLOCK_THREAD_CPUTIME_ID, &cpu_finish) == -1 ||
        clock_gettime(CLOCK_MONOTONIC, &wall_finish) == -1) {
        perror("Failed to finish task trace measurement");
        atomic_store(&g_running, false);
        return;
    }

    size_t index = atomic_fetch_add(&g_trace_count, 1);
    if (index >= TRACE_CAPACITY) {
        atomic_fetch_add(&g_trace_overflow, 1);
        return;
    }
    g_trace_records[index] = (TraceRecord) {
        .release_ns = token->release_ns,
        .start_ns = trace_relative_ns(&token->wall_start),
        .finish_ns = trace_relative_ns(&wall_finish),
        .cpu_ns = (uint64_t)timespec_diff_ns(&cpu_finish, &token->cpu_start),
        .job = token->job,
        .task = token->task
    };
}

static int compare_trace_records(const void *left, const void *right) {
    const TraceRecord *a = left;
    const TraceRecord *b = right;
    if (a->start_ns < b->start_ns) return -1;
    if (a->start_ns > b->start_ns) return 1;
    if (a->task < b->task) return -1;
    if (a->task > b->task) return 1;
    return 0;
}

static bool write_trace_csv(const char *path) {
    size_t count = atomic_load(&g_trace_count);
    if (count > TRACE_CAPACITY) {
        count = TRACE_CAPACITY;
    }
    qsort(g_trace_records, count, sizeof(*g_trace_records), compare_trace_records);

    FILE *trace_file = fopen(path, "w");
    if (trace_file == NULL) {
        perror("Failed to open task trace CSV");
        return false;
    }
    bool success = fprintf(trace_file,
                           "task,job,release_ns,start_ns,finish_ns,cpu_ns,"
                           "run_origin_monotonic_ns\n") >= 0;
    for (size_t i = 0; success && i < count; i++) {
        const TraceRecord *record = &g_trace_records[i];
        success = fprintf(trace_file, "%s,%" PRIu64 ",%" PRIu64 ",%" PRIu64
                          ",%" PRIu64 ",%" PRIu64 ",%" PRIu64 "\n",
                          task_name(record->task), record->job,
                          record->release_ns, record->start_ns,
                          record->finish_ns, record->cpu_ns,
                          g_trace_origin_ns) >= 0;
    }
    if (fclose(trace_file) == EOF) {
        perror("Failed to close task trace CSV");
        success = false;
    }
    if (!success) {
        fprintf(stderr, "Failed while writing task trace CSV: %s\n", path);
        return false;
    }
    uint64_t overflow = atomic_load(&g_trace_overflow);
    printf("Task trace: %s (%zu jobs recorded", path, count);
    if (overflow > 0) {
        printf(", %" PRIu64 " omitted: trace capacity exceeded", overflow);
    }
    printf(").\n");
    return overflow == 0;
}

static int wait_for_semaphore(sem_t *semaphore) {
    int result;
    do {
        result = sem_wait(semaphore);
    } while (result == -1 && errno == EINTR && atomic_load(&g_running));
    return result;
}

static bool parse_long_option(const char *value, long min_value, long max_value,
                              long *parsed_value) {
    char *end;
    errno = 0;
    long parsed = strtol(value, &end, 10);
    if (errno != 0 || end == value || *end != '\0' ||
        parsed < min_value || parsed > max_value) {
        return false;
    }
    *parsed_value = parsed;
    return true;
}

static void print_usage(const char *program, int min_priority, int max_priority) {
    fprintf(stderr,
            "Usage: %s [-n] [-p period_us] [-e execution_us] [-r priority] "
            "[-t trace.csv]\n"
            "  -n             Disable the periodic load task\n"
            "  period_us:     %ld..%ld (default %ld)\n"
            "  execution_us:  %ld..90%% of period_us (default %ld)\n"
            "  priority:      %d..%d (default: below Actuator)\n"
            "  -t trace.csv:  task execution trace output "
            "(default task_trace.csv)\n",
            program, MIN_LOAD_PERIOD_US, MAX_LOAD_PERIOD_US,
            DEFAULT_LOAD_PERIOD_US, MIN_LOAD_EXECUTION_US,
            DEFAULT_LOAD_EXECUTION_US, min_priority, max_priority);
}

static int create_realtime_thread(pthread_t *thread,
                                  void *(*start_routine)(void *),
                                  void *arg,
                                  int priority) {
    pthread_attr_t attr;
    struct sched_param scheduling = { .sched_priority = priority };
    int error = pthread_attr_init(&attr);
    if (error != 0) {
        return error;
    }

    error = pthread_attr_setinheritsched(&attr, PTHREAD_EXPLICIT_SCHED);
    if (error == 0) {
        error = pthread_attr_setschedpolicy(&attr, SCHED_FIFO);
    }
    if (error == 0) {
        error = pthread_attr_setschedparam(&attr, &scheduling);
    }
    if (error == 0) {
        error = pthread_create(thread, &attr, start_routine, arg);
    }

    int destroy_error = pthread_attr_destroy(&attr);
    return error != 0 ? error : destroy_error;
}

/* -------------------------------------------------------------------------- */
/* THREAD 1: Plant Physics Simulator (Runs at 1 kHz / 1 ms period)           */
/* -------------------------------------------------------------------------- */
void* physics_plant_thread(void *arg) {
    name_current_thread(TASK_PLANT);
    struct timespec next_period;
    const long period_ns = 1000000L; /* 1 ms */
    const float dt = 0.001f;
    float u=0, th=0, alpha = 0, acceleration = 0; // Auxiliary variables         		        
    int64_t max_lateness_ns = 0;
    int64_t max_deadline_lateness_ns = 0;
    uint64_t missed_deadlines = 0;
    uint64_t job = 0;

    clock_gettime(CLOCK_MONOTONIC, &next_period);

	// Loop, triggered every 1 ms
    while (atomic_load(&g_running)) {
		// Wait for next activation
        timespec_add_ns(&next_period, period_ns);
        int sleep_error;
        do {
            sleep_error = clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME,
                                          &next_period, NULL);
        } while (sleep_error == EINTR && atomic_load(&g_running));
        if (sleep_error != 0 && sleep_error != EINTR) {
            fprintf(stderr, "Plant clock_nanosleep failed: %s\n",
                    strerror(sleep_error));
            atomic_store(&g_running, false);
            break;
        }
        if (!atomic_load(&g_running)) {
            break;
        }

        struct timespec activation_time;
        if (clock_gettime(CLOCK_MONOTONIC, &activation_time) == -1) {
            perror("Plant activation clock_gettime failed");
            atomic_store(&g_running, false);
            break;
        }
        int64_t lateness_ns = timespec_diff_ns(&activation_time, &next_period);
        if (lateness_ns > max_lateness_ns) {
            max_lateness_ns = lateness_ns;
        }
        TraceToken trace = trace_begin(TASK_PLANT, job++,
                                       timespec_to_ns(&next_period) -
                                       g_trace_origin_ns);

		// Plant state is a structure shared by diverse tasks. Ensure mutual exclusion
        pthread_mutex_lock(&g_state_mutex);

        u = g_state.force;
        th = g_state.theta;         		

        /* Linearized Pendulum Equations of Motion near upright equilibrium */
        alpha = ((M_CART + M_POLE) * GRAVITY * th - u) / (M_CART * LENGTH);
        acceleration = (u - M_POLE * LENGTH * alpha) / (M_CART + M_POLE);

        /* Euler Integration */
        g_state.theta_dot += alpha * dt;
        g_state.theta     += g_state.theta_dot * dt;
        g_state.x_dot     += acceleration * dt;
        g_state.x         += g_state.x_dot * dt;

        pthread_mutex_unlock(&g_state_mutex);
        trace_finish(&trace);

        struct timespec completion_time;
        if (clock_gettime(CLOCK_MONOTONIC, &completion_time) == -1) {
            perror("Plant completion clock_gettime failed");
            atomic_store(&g_running, false);
            break;
        }
        struct timespec deadline = next_period;
        timespec_add_ns(&deadline, period_ns);
        int64_t deadline_lateness_ns = timespec_diff_ns(&completion_time, &deadline);
        if (deadline_lateness_ns > max_deadline_lateness_ns) {
            max_deadline_lateness_ns = deadline_lateness_ns;
        }
        if (deadline_lateness_ns > 0) {
            missed_deadlines++;
        }
    }
    g_plant_max_lateness_ns = max_lateness_ns;
    g_plant_max_deadline_lateness_ns = max_deadline_lateness_ns;
    g_plant_missed_deadlines = missed_deadlines;
    return NULL;
}

/* -------------------------------------------------------------------------- */
/* THREAD 2: Periodic Sensor (Publishes state in shared memory)               */
/* -------------------------------------------------------------------------- */
void* sensor_thread(void *arg) {
    name_current_thread(TASK_SENSOR);
    struct timespec next_period;
    const long period_ns = 5000000L; /* 5 ms */
    int64_t max_lateness_ns = 0;
    int64_t max_deadline_lateness_ns = 0;
    uint64_t missed_deadlines = 0;
    uint64_t job = 0;

    clock_gettime(CLOCK_MONOTONIC, &next_period);

    while (atomic_load(&g_running)) {
        timespec_add_ns(&next_period, period_ns);
        int sleep_error;
        do {
            sleep_error = clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME,
                                          &next_period, NULL);
        } while (sleep_error == EINTR && atomic_load(&g_running));
        if (sleep_error != 0 && sleep_error != EINTR) {
            fprintf(stderr, "Sensor clock_nanosleep failed: %s\n",
                    strerror(sleep_error));
            atomic_store(&g_running, false);
            break;
        }
        if (!atomic_load(&g_running)) {
            break;
        }
        uint64_t release_ns = timespec_to_ns(&next_period) -
                              g_trace_origin_ns;

        struct timespec activation_time;
        if (clock_gettime(CLOCK_MONOTONIC, &activation_time) == -1) {
            perror("Sensor clock_gettime failed");
            atomic_store(&g_running, false);
            break;
        }
        int64_t lateness_ns = timespec_diff_ns(&activation_time, &next_period);
        if (lateness_ns > max_lateness_ns) {
            max_lateness_ns = lateness_ns;
        }
        if (wait_for_semaphore(&g_shared_control->sensor_slot_available) == -1) {
            if (!atomic_load(&g_running)) {
                break;
            }
            perror("Sensor semaphore wait failed");
            atomic_store(&g_running, false);
            break;
        }
        if (!atomic_load(&g_running)) {
            break;
        }
        TraceToken trace = trace_begin(TASK_SENSOR, job++, release_ns);

        pthread_mutex_lock(&g_state_mutex);
        g_shared_control->sensor_data.theta = g_state.theta;
        g_shared_control->sensor_data.theta_dot = g_state.theta_dot;
        g_shared_control->sensor_data.x = g_state.x;
        g_shared_control->sensor_data.x_dot = g_state.x_dot;
        pthread_mutex_unlock(&g_state_mutex);

        struct timespec controller_release;
        if (clock_gettime(CLOCK_MONOTONIC, &controller_release) == -1) {
            perror("Sensor release clock_gettime failed");
            atomic_store(&g_running, false);
            break;
        }
        g_shared_control->sensor_release_ns = timespec_to_ns(&controller_release);
        if (sem_post(&g_shared_control->sensor_ready) == -1) {
            perror("Sensor semaphore post failed");
            atomic_store(&g_running, false);
            break;
        }
        trace_finish(&trace);
        struct timespec completion_time;
        if (clock_gettime(CLOCK_MONOTONIC, &completion_time) == -1) {
            perror("Sensor completion clock_gettime failed");
            atomic_store(&g_running, false);
            break;
        }
        struct timespec deadline = next_period;
        timespec_add_ns(&deadline, period_ns);
        int64_t deadline_lateness_ns = timespec_diff_ns(&completion_time, &deadline);
        if (deadline_lateness_ns > max_deadline_lateness_ns) {
            max_deadline_lateness_ns = deadline_lateness_ns;
        }
        if (deadline_lateness_ns > 0) {
            missed_deadlines++;
        }
    }
    g_sensor_max_lateness_ns = max_lateness_ns;
    g_sensor_max_deadline_lateness_ns = max_deadline_lateness_ns;
    g_sensor_missed_deadlines = missed_deadlines;
    return NULL;
}

//* -------------------------------------------------------------------------- */
/* THREAD 3: Sporadic Feedback Controller (Triggered by Sensor semaphore)     */
/* -------------------------------------------------------------------------- */
void* control_loop_thread(void *arg) {
    name_current_thread(TASK_CONTROLLER);
    SensorData sample;
    uint64_t job = 0;
    
    /* Full-State Feedback Gains (LQR / Pole Placement Derived) */
    const float K_theta     =  45.0f;  /* Angle Error (Stabilizes Pole) */
    const float K_theta_dot =  10.0f;  /* Angular Velocity (Damps Pole) */
    const float K_x         =  2.0f;  /* Cart Position (Drives x -> 0) */
    const float K_x_dot     =  4.0f;  /* Cart Velocity (Damps Cart) */

	// Sporadic activation: the Sensor releases this task after publishing a sample.
	for (;;) {
	    if (wait_for_semaphore(&g_shared_control->sensor_ready) == -1) {
	        if (!atomic_load(&g_running)) {
	            break;
	        }
	        perror("Controller semaphore wait failed");
	        atomic_store(&g_running, false);
	        break;
	    }
	    if (!atomic_load(&g_running)) {
	        break;
	    }
        TraceToken trace = trace_begin(
            TASK_CONTROLLER, job++,
            g_shared_control->sensor_release_ns - g_trace_origin_ns);
	    sample = g_shared_control->sensor_data;

		// Add noise to the sample - real sensors suffer from noise and interference 
		// Generate a random integer in a specific range [min, max]
		int min = -50;
		int max = +50;
		int random_num = min + rand() % (max - min + 1);
		float noise = (float)random_num/1500;

        // State Feedback Law: u = K_theta*theta + K_theta_dot*theta_dot + K_x*x + K_x_dot*x_dot
        float control_force = (K_theta * (sample.theta + noise)) +
                              (K_theta_dot * sample.theta_dot) +
                              (K_x * sample.x) +
                              (K_x_dot * sample.x_dot);

        g_shared_control->control_force = control_force;
        struct timespec actuator_release;
        if (clock_gettime(CLOCK_MONOTONIC, &actuator_release) == -1) {
            perror("Controller release clock_gettime failed");
            atomic_store(&g_running, false);
            break;
        }
        g_shared_control->actuator_release_ns = timespec_to_ns(&actuator_release);
        if (sem_post(&g_shared_control->actuator_ready) == -1) {
            perror("Controller semaphore post failed");
            atomic_store(&g_running, false);
            break;
        }
        trace_finish(&trace);
    }
    return NULL;
}

/* -------------------------------------------------------------------------- */
/* THREAD 4: Sporadic Actuator (Triggered by Controller semaphore)            */
/* -------------------------------------------------------------------------- */
void* actuator_thread(void *arg) {
    name_current_thread(TASK_ACTUATOR);
    uint64_t job = 0;
    for (;;) {
        if (wait_for_semaphore(&g_shared_control->actuator_ready) == -1) {
            if (!atomic_load(&g_running)) {
                break;
            }
            perror("Actuator semaphore wait failed");
            atomic_store(&g_running, false);
            break;
        }
        if (!atomic_load(&g_running)) {
            break;
        }
        TraceToken trace = trace_begin(
            TASK_ACTUATOR, job++,
            g_shared_control->actuator_release_ns - g_trace_origin_ns);

        pthread_mutex_lock(&g_state_mutex);
        g_state.force = g_shared_control->control_force;
        pthread_mutex_unlock(&g_state_mutex);

        if (sem_post(&g_shared_control->sensor_slot_available) == -1) {
            perror("Actuator semaphore post failed");
            atomic_store(&g_running, false);
            break;
        }
        trace_finish(&trace);
    }
    return NULL;
}

/* -------------------------------------------------------------------------- */
/* THREAD 6: Periodic CPU load (Configured execution time and period)          */
/* -------------------------------------------------------------------------- */
void* periodic_load_thread(void *arg) {
    name_current_thread(TASK_LOAD);
    const LoadConfig *config = arg;
    const long period_ns = config->period_us * 1000L;
    const int64_t execution_ns = (int64_t)config->execution_us * 1000L;
    struct timespec next_release;
    uint64_t jobs = 0;
    volatile uint64_t work = 0;

    if (clock_gettime(CLOCK_MONOTONIC, &next_release) == -1) {
        perror("Load clock_gettime failed");
        atomic_store(&g_running, false);
        return NULL;
    }

    while (atomic_load(&g_running)) {
        timespec_add_ns(&next_release, period_ns);
        int sleep_error;
        do {
            sleep_error = clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME,
                                          &next_release, NULL);
        } while (sleep_error == EINTR && atomic_load(&g_running));
        if (sleep_error != 0 && sleep_error != EINTR) {
            fprintf(stderr, "Load clock_nanosleep failed: %s\n",
                    strerror(sleep_error));
            atomic_store(&g_running, false);
            break;
        }
        if (!atomic_load(&g_running)) {
            break;
        }

        TraceToken trace = trace_begin(
            TASK_LOAD, jobs,
            timespec_to_ns(&next_release) - g_trace_origin_ns);
        struct timespec cpu_start;
        struct timespec cpu_now;
        if (clock_gettime(CLOCK_THREAD_CPUTIME_ID, &cpu_start) == -1) {
            perror("Load CPU clock_gettime failed");
            atomic_store(&g_running, false);
            break;
        }
        do {
            work++;
            if (clock_gettime(CLOCK_THREAD_CPUTIME_ID, &cpu_now) == -1) {
                perror("Load CPU clock_gettime failed");
                atomic_store(&g_running, false);
                return NULL;
            }
        } while (timespec_diff_ns(&cpu_now, &cpu_start) < execution_ns &&
                 atomic_load(&g_running));
        trace_finish(&trace);
        jobs++;
    }

    g_load_jobs = jobs;
    return NULL;
}

/* -------------------------------------------------------------------------- */
/* THREAD 5: ASCII Graphics Display (Low-Priority, ~30 Hz / 33 ms period)      */
/* -------------------------------------------------------------------------- */
void* display_thread(void *arg) {
    name_current_thread(TASK_DISPLAY);
    struct timespec next_period;
    const long period_ns = 33000000L; /* ~33 ms */
    uint64_t job = 0;

    clock_gettime(CLOCK_MONOTONIC, &next_period);

    while (atomic_load(&g_running)) {
		// Wait for next activation
        timespec_add_ns(&next_period, period_ns);
        clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &next_period, NULL);
        TraceToken trace = trace_begin(
            TASK_DISPLAY, job++,
            timespec_to_ns(&next_period) - g_trace_origin_ns);

        // Get a copy of state data
        pthread_mutex_lock(&g_state_mutex);
        float th = g_state.theta;
        float x  = g_state.x;
        float f  = g_state.force;
        pthread_mutex_unlock(&g_state_mutex);

        /* Map cart x position [-2.0m, +2.0m] to terminal column index */
        int cart_col = (int)((x + 2.0f) / 4.0f * DISPLAY_WIDTH);
        if (cart_col < 2) cart_col = 2;
        if (cart_col > DISPLAY_WIDTH - 3) cart_col = DISPLAY_WIDTH - 3;

        /* Calculate tip offset based on angle theta */
        int tip_offset = (int)(sinf(th) * POLE_CHAR_LEN * 2.5f);
        int tip_col = cart_col + tip_offset;
        if (tip_col < 0) tip_col = 0;
        if (tip_col >= DISPLAY_WIDTH) tip_col = DISPLAY_WIDTH - 1;

        /* Render Frame to Terminal */ 
        printf("\033[H\033[J"); /* Clear screen and reset cursor */
		printf("================ INVERTED PENDULUM (Non-RT) ================\n");

        printf(" Theta: %+.4f rad | Cart Pos: %+.3f m | Force: %+.2f N\n", th, x, f);
        printf("--------------------------------------------------------------\n\n");

        /* Draw Pendulum Tip */
        for (int i = 0; i < DISPLAY_WIDTH; i++) {
            if (i == tip_col) printf("O");
            else printf(" ");
        }
        printf("\n");

        /* Draw Pole Body */
        for (int line = 0; line < 3; line++) {
            int body_col = cart_col + (tip_offset * (3 - line) / 4);
            for (int i = 0; i < DISPLAY_WIDTH; i++) {
                if (i == body_col) printf("|");
                else printf(" ");
            }
            printf("\n");
        }

        /* Draw Cart Base */
        for (int i = 0; i < DISPLAY_WIDTH; i++) {
            if (i == cart_col - 2) printf("[");
            else if (i == cart_col + 2) printf("]");
            else if (i > cart_col - 2 && i < cart_col + 2) printf("=");
            else printf(" ");
        }
        printf("\n");

        /* Draw Track Floor */
        for (int i = 0; i < DISPLAY_WIDTH; i++) {
            if (i == cart_col - 1 || i == cart_col + 1) printf("o");
            else printf("-");
        }
        printf("\n\nPress Ctrl+C to terminate.\n");
        fflush(stdout);
        trace_finish(&trace);
    }
    return NULL;
}

/* -------------------------------------------------------------------------- */
/* MAIN: Initialization & Thread Creation                                    */
/* -------------------------------------------------------------------------- */
int main(int argc, char *argv[]) {
    pthread_t plant_thread, sensor_thread_id, controller_thread, actuator_thread_id, gui_thread;
    pthread_t load_thread_id;
    bool plant_started = false;
    bool sensor_started = false;
    bool controller_started = false;
    bool actuator_started = false;
    bool load_started = false;
    bool gui_started = false;
    pthread_mutexattr_t mutex_attr;
    int error;
    int shm_fd = -1;
    bool shm_created = false;
    bool shared_memory_mapped = false;
    bool sensor_slot_sem_initialized = false;
    bool sensor_ready_sem_initialized = false;
    bool actuator_ready_sem_initialized = false;
    bool trace_written = false;
    char shared_memory_name[64];
    const char *trace_path = "task_trace.csv";
    int rt_min_priority;
    int rt_max_priority;
    int plant_priority;
    int sensor_priority;
    int controller_priority;
    int actuator_priority;
    int load_priority;
    LoadConfig load_config = {
        .period_us = DEFAULT_LOAD_PERIOD_US,
        .execution_us = DEFAULT_LOAD_EXECUTION_US,
        .priority = 0,
        .enabled = true
    };
    long option_value;
    int option;
        
    // 1. Seed the random number generator using current time
	srand((unsigned int)time(NULL));


    // 2. Initialize a priority-inheritance mutex for shared plant state.
    error = pthread_mutexattr_init(&mutex_attr);
    if (error != 0) {
        fprintf(stderr, "Failed to initialize priority-inheritance mutex: %s\n",
                strerror(error));
        return EXIT_FAILURE;
    }
    error = pthread_mutexattr_setprotocol(&mutex_attr, PTHREAD_PRIO_INHERIT);
    if (error != 0) {
        pthread_mutexattr_destroy(&mutex_attr);
        fprintf(stderr, "Failed to configure priority-inheritance mutex: %s\n",
                strerror(error));
        return EXIT_FAILURE;
    }
    error = pthread_mutex_init(&g_state_mutex, &mutex_attr);
    pthread_mutexattr_destroy(&mutex_attr);
    if (error != 0) {
        fprintf(stderr, "Failed to initialize priority-inheritance mutex: %s\n",
                strerror(error));
        return EXIT_FAILURE;
    }

    snprintf(shared_memory_name, sizeof(shared_memory_name),
             "/pendulum_control_%ld", (long)getpid());
    shm_fd = shm_open(shared_memory_name, O_CREAT | O_EXCL | O_RDWR, 0600);
    if (shm_fd == -1) {
        perror("Failed to create POSIX shared memory");
        pthread_mutex_destroy(&g_state_mutex);
        return EXIT_FAILURE;
    }
    shm_created = true;

    if (ftruncate(shm_fd, sizeof(SharedControlData)) == -1) {
        perror("Failed to size POSIX shared memory");
        shm_unlink(shared_memory_name);
        close(shm_fd);
        pthread_mutex_destroy(&g_state_mutex);
        return EXIT_FAILURE;
    }

    g_shared_control = mmap(NULL, sizeof(SharedControlData),
                            PROT_READ | PROT_WRITE, MAP_SHARED, shm_fd, 0);
    if (g_shared_control == MAP_FAILED) {
        g_shared_control = NULL;
        perror("Failed to map POSIX shared memory");
        shm_unlink(shared_memory_name);
        close(shm_fd);
        pthread_mutex_destroy(&g_state_mutex);
        return EXIT_FAILURE;
    }
    shared_memory_mapped = true;
    memset(g_shared_control, 0, sizeof(*g_shared_control));

    if (sem_init(&g_shared_control->sensor_slot_available, 1, 1) == -1) {
        perror("Failed to initialize Sensor slot semaphore");
        goto shared_memory_init_failed;
    }
    sensor_slot_sem_initialized = true;
    if (sem_init(&g_shared_control->sensor_ready, 1, 0) == -1) {
        perror("Failed to initialize Sensor-to-Controller semaphore");
        goto shared_memory_init_failed;
    }
    sensor_ready_sem_initialized = true;
    if (sem_init(&g_shared_control->actuator_ready, 1, 0) == -1) {
        perror("Failed to initialize Controller-to-Actuator semaphore");
        goto shared_memory_init_failed;
    }
    actuator_ready_sem_initialized = true;

    rt_min_priority = sched_get_priority_min(SCHED_FIFO);
    rt_max_priority = sched_get_priority_max(SCHED_FIFO);
    if (rt_min_priority == -1 || rt_max_priority == -1 ||
        rt_max_priority - rt_min_priority < 4) {
        perror("Failed to query SCHED_FIFO priority range");
        goto startup_failed;
    }

    plant_priority = rt_max_priority;
    sensor_priority = rt_max_priority - 1;
    controller_priority = rt_max_priority - 2;
    actuator_priority = rt_max_priority - 3;
    load_priority = rt_max_priority - 4;
    load_config.priority = load_priority;
    while ((option = getopt(argc, argv, "nt:p:e:r:h")) != -1) {
        switch (option) {
            case 'n':
                load_config.enabled = false;
                break;
            case 't':
                trace_path = optarg;
                break;
            case 'p':
                if (!parse_long_option(optarg, MIN_LOAD_PERIOD_US,
                                       MAX_LOAD_PERIOD_US, &option_value)) {
                    fprintf(stderr, "Invalid load period: %s\n", optarg);
                    print_usage(argv[0], rt_min_priority, rt_max_priority);
                    goto startup_failed;
                }
                load_config.period_us = option_value;
                break;
            case 'e':
                if (!parse_long_option(optarg, MIN_LOAD_EXECUTION_US,
                                       MAX_LOAD_PERIOD_US, &option_value)) {
                    fprintf(stderr, "Invalid load execution time: %s\n", optarg);
                    print_usage(argv[0], rt_min_priority, rt_max_priority);
                    goto startup_failed;
                }
                load_config.execution_us = option_value;
                break;
            case 'r':
                if (!parse_long_option(optarg, rt_min_priority, rt_max_priority,
                                       &option_value)) {
                    fprintf(stderr, "Invalid SCHED_FIFO priority: %s\n", optarg);
                    print_usage(argv[0], rt_min_priority, rt_max_priority);
                    goto startup_failed;
                }
                load_config.priority = (int)option_value;
                break;
            case 'h':
                print_usage(argv[0], rt_min_priority, rt_max_priority);
                sem_destroy(&g_shared_control->actuator_ready);
                sem_destroy(&g_shared_control->sensor_ready);
                sem_destroy(&g_shared_control->sensor_slot_available);
                munmap(g_shared_control, sizeof(*g_shared_control));
                close(shm_fd);
                shm_unlink(shared_memory_name);
                pthread_mutex_destroy(&g_state_mutex);
                return EXIT_SUCCESS;
            default:
                print_usage(argv[0], rt_min_priority, rt_max_priority);
                goto startup_failed;
        }
    }
    if (optind != argc ||
        load_config.execution_us * 10 > load_config.period_us * 9) {
        fprintf(stderr, "Load execution time must not exceed 90%% of its period; "
                        "reserve CPU time for the control tasks and shutdown.\n");
        print_usage(argv[0], rt_min_priority, rt_max_priority);
        goto startup_failed;
    }

    if (load_config.enabled) {
        double load_utilization = (double)load_config.execution_us /
                                  (double)load_config.period_us;
        printf("Periodic load: C=%ld us, T=%ld us, priority=%d, utilization=%.1f%%\n",
               load_config.execution_us, load_config.period_us,
               load_config.priority, load_utilization * 100.0);
    } else {
        printf("Periodic load disabled.\n");
    }
    printf("SCHED_FIFO priorities: Plant=%d, Sensor=%d, Controller=%d, "
           "Actuator=%d, default load=%d\n",
           plant_priority, sensor_priority, controller_priority,
           actuator_priority, load_priority);

    g_trace_records = calloc(TRACE_CAPACITY, sizeof(*g_trace_records));
    if (g_trace_records == NULL) {
        perror("Failed to allocate task trace buffer");
        goto startup_failed;
    }
    struct timespec trace_origin;
    if (clock_gettime(CLOCK_MONOTONIC, &trace_origin) == -1) {
        perror("Failed to initialize task trace clock");
        goto startup_failed;
    }
    g_trace_origin_ns = timespec_to_ns(&trace_origin);

    // Rate-monotonic order: 1 ms Plant first, then the 5 ms Sensor-to-Actuator chain.
    error = create_realtime_thread(&actuator_thread_id, actuator_thread,
                                   NULL,
                                   actuator_priority);
    if (error != 0) {
        fprintf(stderr, "Failed to create SCHED_FIFO Actuator thread "
                        "(root or CAP_SYS_NICE may be required): %s\n",
                strerror(error));
        goto startup_failed;
    }
    actuator_started = true;

    error = create_realtime_thread(&controller_thread, control_loop_thread,
                                   NULL,
                                   controller_priority);
    if (error != 0) {
        fprintf(stderr, "Failed to create SCHED_FIFO Controller thread "
                        "(root or CAP_SYS_NICE may be required): %s\n",
                strerror(error));
        goto startup_failed;
    }
    controller_started = true;

    error = create_realtime_thread(&sensor_thread_id, sensor_thread,
                                   NULL,
                                   sensor_priority);
    if (error != 0) {
        fprintf(stderr, "Failed to create SCHED_FIFO Sensor thread "
                        "(root or CAP_SYS_NICE may be required): %s\n",
                strerror(error));
        goto startup_failed;
    }
    sensor_started = true;

    error = create_realtime_thread(&plant_thread, physics_plant_thread,
                                   NULL,
                                   plant_priority);
    if (error != 0) {
        fprintf(stderr, "Failed to create SCHED_FIFO Plant thread "
                        "(root or CAP_SYS_NICE may be required): %s\n",
                strerror(error));
        goto startup_failed;
    }
    plant_started = true;

    // Keep the visualization at the default, non-real-time scheduling policy.
    error = pthread_create(&gui_thread, NULL, display_thread, NULL);
    if (error != 0) {
        fprintf(stderr, "Failed to create Display thread: %s\n", strerror(error));
        goto startup_failed;
    }
    gui_started = true;

    if (load_config.enabled) {
        error = create_realtime_thread(&load_thread_id, periodic_load_thread,
                                       &load_config, load_config.priority);
        if (error != 0) {
            fprintf(stderr, "Failed to create SCHED_FIFO load thread "
                            "(root or CAP_SYS_NICE may be required): %s\n",
                    strerror(error));
            goto startup_failed;
        }
        load_started = true;
    }

    /* Run simulation for 60 seconds */
    sleep(60);

    /* Cleanup */
    atomic_store(&g_running, false);
    if (sem_post(&g_shared_control->sensor_slot_available) == -1) {
        perror("Failed to wake Sensor during shutdown");
    }
    if (sem_post(&g_shared_control->sensor_ready) == -1) {
        perror("Failed to wake Controller during shutdown");
    }
    if (sem_post(&g_shared_control->actuator_ready) == -1) {
        perror("Failed to wake Actuator during shutdown");
    }
    pthread_join(plant_thread, NULL);
    pthread_join(sensor_thread_id, NULL);
    if (load_started) {
        pthread_join(load_thread_id, NULL);
    }

    pthread_join(controller_thread, NULL);
    pthread_join(actuator_thread_id, NULL);
    pthread_join(gui_thread, NULL);

    printf("\nSimulation complete.\n");
    printf("Periodic load: %s; completed %" PRIu64 " jobs.\n",
           load_started ? "enabled" : "disabled", g_load_jobs);
    printf("Plant max activation lateness: %.3f us; "
           "max deadline lateness: %.3f us; missed jobs: %" PRIu64 "\n",
           (double)g_plant_max_lateness_ns / 1000.0,
           (double)g_plant_max_deadline_lateness_ns / 1000.0,
           g_plant_missed_deadlines);
    printf("Sensor max activation lateness: %.3f us; "
           "max deadline lateness: %.3f us; missed jobs: %" PRIu64 "\n",
           (double)g_sensor_max_lateness_ns / 1000.0,
           (double)g_sensor_max_deadline_lateness_ns / 1000.0,
           g_sensor_missed_deadlines);
    trace_written = write_trace_csv(trace_path);
    fflush(stdout);

    goto cleanup;

startup_failed:
    atomic_store(&g_running, false);
    if (sem_post(&g_shared_control->sensor_slot_available) == -1) {
        perror("Failed to wake Sensor after startup error");
    }
    if (sem_post(&g_shared_control->sensor_ready) == -1) {
        perror("Failed to wake Controller after startup error");
    }
    if (sem_post(&g_shared_control->actuator_ready) == -1) {
        perror("Failed to wake Actuator after startup error");
    }
    if (sensor_started) {
        pthread_join(sensor_thread_id, NULL);
    }
    if (plant_started) {
        pthread_join(plant_thread, NULL);
    }
    if (load_started) {
        pthread_join(load_thread_id, NULL);
    }
    if (controller_started) {
        pthread_join(controller_thread, NULL);
    }
    if (actuator_started) {
        pthread_join(actuator_thread_id, NULL);
    }
    if (gui_started) {
        pthread_join(gui_thread, NULL);
    }

cleanup:
    free(g_trace_records);
    if (actuator_ready_sem_initialized) {
        sem_destroy(&g_shared_control->actuator_ready);
    }
    if (sensor_ready_sem_initialized) {
        sem_destroy(&g_shared_control->sensor_ready);
    }
    if (sensor_slot_sem_initialized) {
        sem_destroy(&g_shared_control->sensor_slot_available);
    }
    if (shared_memory_mapped && munmap(g_shared_control, sizeof(*g_shared_control)) == -1) {
        perror("Failed to unmap POSIX shared memory");
    }
    if (shm_fd != -1 && close(shm_fd) == -1) {
        perror("Failed to close POSIX shared memory");
    }
    if (shm_created && shm_unlink(shared_memory_name) == -1) {
        perror("Failed to unlink POSIX shared memory");
    }
    pthread_mutex_destroy(&g_state_mutex);

    if (gui_started && trace_written) {
        return EXIT_SUCCESS;
    }
    fprintf(stderr, "Simulation startup failed.\n");
    return EXIT_FAILURE;

shared_memory_init_failed:
    if (actuator_ready_sem_initialized) {
        sem_destroy(&g_shared_control->actuator_ready);
    }
    if (sensor_ready_sem_initialized) {
        sem_destroy(&g_shared_control->sensor_ready);
    }
    if (sensor_slot_sem_initialized) {
        sem_destroy(&g_shared_control->sensor_slot_available);
    }
    if (shared_memory_mapped) {
        munmap(g_shared_control, sizeof(*g_shared_control));
    }
    if (shm_fd != -1) {
        close(shm_fd);
    }
    if (shm_created) {
        shm_unlink(shared_memory_name);
    }
    pthread_mutex_destroy(&g_state_mutex);
    return EXIT_FAILURE;
}
