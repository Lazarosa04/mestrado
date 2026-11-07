/*
 * Paulo Pedreiras, 2025/07
 * 
 * Demo of the use of the UART driver.  
 *      There are several APIs. The demo is based on the asynchronous API, which is very flexible and covers most of the use cases.
 *      The demo configures the UART and echoes the user input. 
 *      Received characters are accumulated during a period set by MAIN_SLEEP_TIME_MS
 *      All UART events are echoed 
 *      *This version uses a double buffer to support continuous receiving*
 * 
 * Info source:
 *      https://docs.nordicsemi.com/bundle/zephyr-apis-latest/page/group_uart_interface.html 
 *
 *  prj.conf should be set as follows:
 *
 *      To enable UART:
 *          CONFIG_SERIAL=y
 *          CONFIG_UART_ASYNC_API=y
 * 
 *
 */
/* Includes. Add according to the resources used  */
#include <zephyr/kernel.h>          /* for k_msleep() */
#include <zephyr/device.h>          /* for device_is_ready() and device structure */
#include <zephyr/devicetree.h>	    /* for DT_NODELABEL() */
#include <zephyr/drivers/uart.h>    /* for UART API*/
#include <zephyr/logging/log.h>     /* Required for LOG module */
#include <stdio.h>                  /* for sprintf() */
#include <stdlib.h>
#include <string.h>

#define UART_NODE_ID DT_NODELABEL(uart0)   /* UART0 node ID*/
#define MAIN_SLEEP_TIME_MS 1000         /* Time between main() activations */ 

#define RXBUF_SIZE 10                    /* RX buffer size (in general should be bigger. Left small for testing purposes) */
#define TXBUF_SIZE 60                   /* TX buffer size */
#define MSG_BUF_SIZE 100                /* Buffer for messages sent vai UART */
#define RX_TIMEOUT 1000                 /* Inactivity period after the instant when last char was received that triggers an rx event (in us) */

#define ERR_DEV_NOT_RDY -1              /* Device not ready error code */

/* Register services */
LOG_MODULE_REGISTER(UART_ASYNC_DB,LOG_LEVEL_DBG); /* DBG -> all log messages sent to console*/

/* Struct for UART configuration. If using default values (check devicetree info) is not needed) */
/* Dynamic configuration option, available if CONFIG_UART_USE_RUNTIME_CONFIGURE is set (it is by defualt)*/
/* For static UART configuration it is recommended to use the devicetree editor (Actions tab) */
const struct uart_config uart_cfg = {
		.baudrate = 115200,
		.parity = UART_CFG_PARITY_NONE,        
		.stop_bits = UART_CFG_STOP_BITS_1,
		.data_bits = UART_CFG_DATA_BITS_8,
		.flow_ctrl = UART_CFG_FLOW_CTRL_NONE        
};

/* UART related variables */
const struct device *uart_dev = DEVICE_DT_GET(UART_NODE_ID);
static uint8_t rx_buf[2][RXBUF_SIZE];   /* RX buffer, to store received data. Double buffering scheme  */
static uint8_t act_buf = 0;             /* Index of active device-driver buffer */   

static uint8_t rx_chars[RXBUF_SIZE];    /* chars actually received  */
volatile int uart_rxbuf_nchar=0;        /* Number of chars currrntly on the rx buffer - note the volatile modifier */

/* UART callback function prototype */
static void uart_cb(const struct device *dev, struct uart_event *evt, void *user_data);


/* Main function */
int main(void)
{
    
    /* Local vars */    
    int err=0; /* Generic error variable */
    uint8_t welcome_mesg[] = "UART demo: Type a few chars in a row and then pause for a little while ...\n\r"; 
    uint8_t rep_mesg[MSG_BUF_SIZE];

    /* Check if uart device is open */
    if (!device_is_ready(uart_dev)) {
        LOG_ERR("device_is_ready(uart) returned error! Aborting! \n\r");
        return ERR_DEV_NOT_RDY;
    }

    /* Configure UART */
    err = uart_configure(uart_dev, &uart_cfg);
    if (err == -ENOSYS) { /* If invalid configuration */
        LOG_ERR("uart_configure() error. Invalid configuration\n\r");
        return err; 
    }
        
    /* Register callback */
    err = uart_callback_set(uart_dev, uart_cb, NULL);
    if (err) {
        LOG_ERR("uart_callback_set() error. Error code:%d\n\r",err);
        return err;
    }
		
    /* Enable data reception */    
    err =  uart_rx_enable(uart_dev ,rx_buf[act_buf],sizeof(rx_buf[0]),RX_TIMEOUT);
    if (err) {
        LOG_ERR("uart_rx_enable() error. Error code:%d\n\r",err);
        return err;
    }

    /* Send a welcome message */ 
    /* Last arg is timeout. Only relevant if flow controll is used */
    err = uart_tx(uart_dev, welcome_mesg, sizeof(welcome_mesg), SYS_FOREVER_MS);
    if (err) {
        LOG_ERR("uart_tx() error. Error code:%d\n\r",err);
        return err;
    }
    
    /* Main loop */
    while(1) {
        k_msleep(MAIN_SLEEP_TIME_MS);
        
        /* Print string received so far. */
        /* Very basic implementation, just for showing the use of the API */
        /* E.g. it does not prevent race conditions with the callback!!!!*/
        /* Good solutions include e.g. using a FIFO or circular buffer to move data from */
        /*   the device-driver to teh application buffer */
        if(uart_rxbuf_nchar > 0) {
            rx_chars[uart_rxbuf_nchar] = 0; /* Terminate the string */
            uart_rxbuf_nchar = 0;           /* Reset counter */

            sprintf(rep_mesg,"You typed [%s]\n\r",rx_chars);            
            
            err = uart_tx(uart_dev, rep_mesg, strlen(rep_mesg), SYS_FOREVER_MS);
            if (err) {
                LOG_ERR("uart_tx() error. Error code:%d\n\r",err);
                return err;
            }
        }        
     
        /* Check for errors */
        err=uart_err_check(uart_dev);
        if(err) {
            LOG_WRN("UART error detected, code %d", err);            
            LOG_INF("Code explanation in uart.h/uart_rx_stop_reason");
        }
    }
}
        


/* UART callback implementation */
/* Note that callback functions are executed in the scope of interrupt handlers. */
/* They run asynchronously after hardware/software interrupts and have a higher priority than tasks/threads */
/* Should be kept as short and simple as possible. Heavy processing should be deferred to a task with suitable priority*/
static void uart_cb(const struct device *dev, struct uart_event *evt, void *user_data)
{    
    switch (evt->type) {
	
        case UART_TX_DONE:
		    LOG_DBG("UART_TX_DONE event \n\r");
            break;

    	case UART_TX_ABORTED:
	    	LOG_DBG("UART_TX_ABORTED event \n\r");
		    break;
		
	    case UART_RX_RDY:
		    LOG_DBG("UART_RX_RDY event \n\r");
            /* Data vailable at RX buffer. Data received and timeout, rx buffer full, ... */
            /* Move data to the application-level buffer */
            /* Simple approach, just for illustration. In most cases it is necessary to use */
            /*    e.g. a FIFO or a circular buffer to communicate with a task that shall process the messages*/            
            memcpy(&rx_chars[uart_rxbuf_nchar],&(evt->data.rx.buf[evt->data.rx.offset]),evt->data.rx.len);             
            uart_rxbuf_nchar += evt->data.rx.len;           
		    break;

	    case UART_RX_BUF_REQUEST:
		    LOG_DBG("UART_RX_BUF_REQUEST event \n\r");  
            
            /* Double buffer implementation */
            /* Compute index of next buffer to be used when current one is filled up*/
            act_buf++;
            if(act_buf == 2) { // Double buffer, so index is 0 or 1
                act_buf = 0;
            }          
            /* And provide it to the device-driver */
            uart_rx_buf_rsp(dev,rx_buf[act_buf], sizeof(rx_buf[act_buf]));
		    break;

	    case UART_RX_BUF_RELEASED:
		    LOG_DBG("UART_RX_BUF_RELEASED event \n\r");
            /* Signals that the previous buffer is no longer in use by the device driver. */
            /* If are used multiple buffers, it can be used to manage the pool of available ones. */
            /* Note that a buffer can only be reused after being released. */            
            break;
		
	    case UART_RX_DISABLED: 
            /* Since it is used a double buffer, via uart_rx_buf_rsp() this event should not be generated */            
            /* Checked it here jut for debug purposes */
            LOG_ERR("UART_RX_DISABLED event *** SHOULD NOT HAPPEN *** \n\r");
            break;

	    case UART_RX_STOPPED:
		    LOG_DBG("UART_RX_STOPPED event \n\r");
		    break;
		
	    default:
            LOG_DBG("UART: unknown event \n\r");
		    break;
    }

}
