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
 * 	- THREAD 3: Sporadic Feedback Controller (Triggered by sensor messages)
 * 	- THREAD 4: Sporadic Actuator (Triggered by force messages)
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
#include <mqueue.h>
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
    bool shutdown;
    SensorData data;
} SensorMessage;

typedef struct {
    bool shutdown;
    float force;
} ActuatorMessage;

typedef struct {
    long period_us;
    long execution_us;
    int priority;
    bool enabled;
} LoadConfig;

static PlantState g_state = { .theta = 0.15f, .theta_dot = 0.0f, .x = 0.0f, .x_dot = 0.0f, .force = 0.0f };
static pthread_mutex_t g_state_mutex;
static atomic_bool g_running = ATOMIC_VAR_INIT(true);
static mqd_t g_sensor_queue = (mqd_t)-1;
static mqd_t g_sensor_queue_rx = (mqd_t)-1;
static mqd_t g_actuator_queue = (mqd_t)-1;
static mqd_t g_actuator_queue_rx = (mqd_t)-1;
static int64_t g_sensor_max_lateness_ns;
static int64_t g_sensor_max_deadline_lateness_ns;
static uint64_t g_sensor_missed_deadlines;
static uint64_t g_load_jobs;
static int64_t g_plant_max_lateness_ns;
static int64_t g_plant_max_deadline_lateness_ns;
static uint64_t g_plant_missed_deadlines;

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
            "Usage: %s [-n] [-p period_us] [-e execution_us] [-r priority]\n"
            "  -n             Disable the periodic load task\n"
            "  period_us:     %ld..%ld (default %ld)\n"
            "  execution_us:  %ld..90%% of period_us (default %ld)\n"
            "  priority:      %d..%d (default: below Actuator)\n",
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
    struct timespec next_period;
    const long period_ns = 1000000L; /* 1 ms */
    const float dt = 0.001f;
    float u=0, th=0, alpha = 0, acceleration = 0; // Auxiliary variables         		        
    int64_t max_lateness_ns = 0;
    int64_t max_deadline_lateness_ns = 0;
    uint64_t missed_deadlines = 0;

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
/* THREAD 2: Sensor (Samples the plant and sends state to the Controller)     */
/* -------------------------------------------------------------------------- */
void* sensor_thread(void *arg) {
    struct timespec next_period;
    const long period_ns = 5000000L; /* 5 ms */
    int64_t max_lateness_ns = 0;
    int64_t max_deadline_lateness_ns = 0;
    uint64_t missed_deadlines = 0;

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
        SensorMessage message = { .shutdown = false };
        pthread_mutex_lock(&g_state_mutex);
        message.data.theta = g_state.theta;
        message.data.theta_dot = g_state.theta_dot;
        message.data.x = g_state.x;
        message.data.x_dot = g_state.x_dot;
        pthread_mutex_unlock(&g_state_mutex);

        if (mq_send(g_sensor_queue, (const char *)&message, sizeof(message), 0) == -1) {
            if (errno == EINTR && atomic_load(&g_running)) {
                continue;
            }
            perror("Sensor message queue send failed");
            atomic_store(&g_running, false);
            break;
        }
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
/* THREAD 3: Sporadic Feedback Controller (Triggered by sensor messages)     */
/* -------------------------------------------------------------------------- */
void* control_loop_thread(void *arg) {
    SensorMessage message;
    SensorData sample;
    
    /* Full-State Feedback Gains (LQR / Pole Placement Derived) */
    const float K_theta     =  45.0f;  /* Angle Error (Stabilizes Pole) */
    const float K_theta_dot =  10.0f;  /* Angular Velocity (Damps Pole) */
    const float K_x         =  2.0f;  /* Cart Position (Drives x -> 0) */
    const float K_x_dot     =  4.0f;  /* Cart Velocity (Damps Cart) */

	// Sporadic activation: each sensor message triggers one control calculation.
    for (;;) {
        ssize_t received = mq_receive(g_sensor_queue_rx, (char *)&message,
                                      sizeof(message), NULL);
        if (received == -1) {
            if (errno == EINTR && atomic_load(&g_running)) {
                continue;
            }
            perror("Controller message queue receive failed");
            atomic_store(&g_running, false);
            break;
        }
        if ((size_t)received != sizeof(message)) {
            fprintf(stderr, "Controller received an invalid sensor message size\n");
            atomic_store(&g_running, false);
            break;
        }
        if (message.shutdown) {
            break;
        }
        sample = message.data;

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

        ActuatorMessage force_message = {
            .shutdown = false,
            .force = control_force
        };
        if (mq_send(g_actuator_queue, (const char *)&force_message,
                    sizeof(force_message), 0) == -1) {
            if (errno == EINTR && atomic_load(&g_running)) {
                continue;
            }
            perror("Controller message queue send failed");
            atomic_store(&g_running, false);
            break;
        }
    }
    return NULL;
}

/* -------------------------------------------------------------------------- */
/* THREAD 4: Sporadic Actuator (Triggered by force messages)                  */
/* -------------------------------------------------------------------------- */
void* actuator_thread(void *arg) {
    ActuatorMessage message;

    for (;;) {
        ssize_t received = mq_receive(g_actuator_queue_rx,
                                      (char *)&message,
                                      sizeof(message), NULL);
        if (received == -1) {
            if (errno == EINTR && atomic_load(&g_running)) {
                continue;
            }
            perror("Actuator message queue receive failed");
            atomic_store(&g_running, false);
            break;
        }
        if ((size_t)received != sizeof(message)) {
            fprintf(stderr, "Actuator received an invalid force message size\n");
            atomic_store(&g_running, false);
            break;
        }
        if (message.shutdown) {
            break;
        }

        pthread_mutex_lock(&g_state_mutex);
        g_state.force = message.force;
        pthread_mutex_unlock(&g_state_mutex);
    }
    return NULL;
}

/* -------------------------------------------------------------------------- */
/* THREAD 6: Periodic CPU load (Configured execution time and period)          */
/* -------------------------------------------------------------------------- */
void* periodic_load_thread(void *arg) {
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
        jobs++;
    }

    g_load_jobs = jobs;
    return NULL;
}

/* -------------------------------------------------------------------------- */
/* THREAD 5: ASCII Graphics Display (Low-Priority, ~30 Hz / 33 ms period)      */
/* -------------------------------------------------------------------------- */
void* display_thread(void *arg) {
    struct timespec next_period;
    const long period_ns = 33000000L; /* ~33 ms */

    clock_gettime(CLOCK_MONOTONIC, &next_period);

    while (atomic_load(&g_running)) {
		// Wait for next activation
        timespec_add_ns(&next_period, period_ns);
        clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &next_period, NULL);

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
    struct mq_attr queue_attr = {
        .mq_flags = 0,
        .mq_maxmsg = 10,
        .mq_msgsize = sizeof(SensorMessage),
        .mq_curmsgs = 0
    };
    struct mq_attr actuator_queue_attr = queue_attr;
    char sensor_queue_name[64];
    char actuator_queue_name[64];
    int rt_min_priority;
    int rt_max_priority;
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

    snprintf(sensor_queue_name, sizeof(sensor_queue_name), "/pendulum_sensor_%ld",
             (long)getpid());
    g_sensor_queue = mq_open(sensor_queue_name, O_WRONLY | O_CREAT | O_EXCL,
                             0600, &queue_attr);
    if (g_sensor_queue == (mqd_t)-1) {
        perror("Failed to create sensor message queue");
        pthread_mutex_destroy(&g_state_mutex);
        return EXIT_FAILURE;
    }

    g_sensor_queue_rx = mq_open(sensor_queue_name, O_RDONLY);
    if (g_sensor_queue_rx == (mqd_t)-1) {
        perror("Failed to open sensor message queue for Controller");
        mq_close(g_sensor_queue);
        mq_unlink(sensor_queue_name);
        pthread_mutex_destroy(&g_state_mutex);
        return EXIT_FAILURE;
    }

    snprintf(actuator_queue_name, sizeof(actuator_queue_name), "/pendulum_actuator_%ld",
             (long)getpid());
    actuator_queue_attr.mq_msgsize = sizeof(ActuatorMessage);
    g_actuator_queue = mq_open(actuator_queue_name,
                               O_WRONLY | O_CREAT | O_EXCL,
                               0600, &actuator_queue_attr);
    if (g_actuator_queue == (mqd_t)-1) {
        perror("Failed to create actuator message queue");
        mq_close(g_sensor_queue_rx);
        mq_close(g_sensor_queue);
        mq_unlink(sensor_queue_name);
        pthread_mutex_destroy(&g_state_mutex);
        return EXIT_FAILURE;
    }

    g_actuator_queue_rx = mq_open(actuator_queue_name, O_RDONLY);
    if (g_actuator_queue_rx == (mqd_t)-1) {
        perror("Failed to open actuator message queue for Actuator");
        mq_close(g_actuator_queue);
        mq_close(g_sensor_queue_rx);
        mq_close(g_sensor_queue);
        mq_unlink(actuator_queue_name);
        mq_unlink(sensor_queue_name);
        pthread_mutex_destroy(&g_state_mutex);
        return EXIT_FAILURE;
    }

    rt_min_priority = sched_get_priority_min(SCHED_FIFO);
    rt_max_priority = sched_get_priority_max(SCHED_FIFO);
    if (rt_min_priority == -1 || rt_max_priority == -1 ||
        rt_max_priority - rt_min_priority < 4) {
        perror("Failed to query SCHED_FIFO priority range");
        goto startup_failed;
    }

    load_config.priority = rt_max_priority - 4;
    while ((option = getopt(argc, argv, "np:e:r:h")) != -1) {
        switch (option) {
            case 'n':
                load_config.enabled = false;
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
                mq_close(g_sensor_queue);
                mq_close(g_sensor_queue_rx);
                mq_close(g_actuator_queue);
                mq_close(g_actuator_queue_rx);
                mq_unlink(sensor_queue_name);
                mq_unlink(actuator_queue_name);
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
    printf("SCHED_FIFO priorities: Plant=%d, Sensor=%d, Controller=%d, Actuator=%d\n",
           rt_max_priority, rt_max_priority - 1,
           rt_max_priority - 2, rt_max_priority - 3);

    // Create sporadic consumers before their producers.
    error = create_realtime_thread(&actuator_thread_id, actuator_thread,
                                   NULL,
                                   rt_max_priority - 3);
    if (error != 0) {
        fprintf(stderr, "Failed to create SCHED_FIFO Actuator thread "
                        "(root or CAP_SYS_NICE may be required): %s\n",
                strerror(error));
        goto startup_failed;
    }
    actuator_started = true;

    error = create_realtime_thread(&controller_thread, control_loop_thread,
                                   NULL,
                                   rt_max_priority - 2);
    if (error != 0) {
        fprintf(stderr, "Failed to create SCHED_FIFO Controller thread "
                        "(root or CAP_SYS_NICE may be required): %s\n",
                strerror(error));
        goto startup_failed;
    }
    controller_started = true;

    error = create_realtime_thread(&sensor_thread_id, sensor_thread,
                                   NULL,
                                   rt_max_priority - 1);
    if (error != 0) {
        fprintf(stderr, "Failed to create SCHED_FIFO Sensor thread "
                        "(root or CAP_SYS_NICE may be required): %s\n",
                strerror(error));
        goto startup_failed;
    }
    sensor_started = true;

    error = create_realtime_thread(&plant_thread, physics_plant_thread,
                                   NULL,
                                   rt_max_priority);
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
    pthread_join(plant_thread, NULL);
    pthread_join(sensor_thread_id, NULL);
    if (load_started) {
        pthread_join(load_thread_id, NULL);
    }

    SensorMessage sensor_shutdown = { .shutdown = true };
    if (mq_send(g_sensor_queue, (const char *)&sensor_shutdown,
                sizeof(sensor_shutdown), 0) == -1) {
        perror("Failed to stop Controller thread");
    }
    pthread_join(controller_thread, NULL);

    ActuatorMessage actuator_shutdown = { .shutdown = true };
    if (mq_send(g_actuator_queue, (const char *)&actuator_shutdown,
                sizeof(actuator_shutdown), 0) == -1) {
        perror("Failed to stop Actuator thread");
    }
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
    fflush(stdout);

    goto cleanup;

startup_failed:
    atomic_store(&g_running, false);
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
        SensorMessage sensor_shutdown = { .shutdown = true };
        if (mq_send(g_sensor_queue, (const char *)&sensor_shutdown,
                    sizeof(sensor_shutdown), 0) == -1) {
            perror("Failed to stop Controller thread after startup error");
        }
        pthread_join(controller_thread, NULL);
    }
    if (actuator_started) {
        ActuatorMessage actuator_shutdown = { .shutdown = true };
        if (mq_send(g_actuator_queue, (const char *)&actuator_shutdown,
                    sizeof(actuator_shutdown), 0) == -1) {
            perror("Failed to stop Actuator thread after startup error");
        }
        pthread_join(actuator_thread_id, NULL);
    }
    if (gui_started) {
        pthread_join(gui_thread, NULL);
    }

cleanup:
    mq_close(g_sensor_queue);
    mq_close(g_sensor_queue_rx);
    mq_close(g_actuator_queue);
    mq_close(g_actuator_queue_rx);
    mq_unlink(sensor_queue_name);
    mq_unlink(actuator_queue_name);
    pthread_mutex_destroy(&g_state_mutex);

    if (gui_started) {
        return EXIT_SUCCESS;
    }
    fprintf(stderr, "Simulation startup failed.\n");
    return EXIT_FAILURE;
}
