/*
 * Paulo Pedreiras, 2025/07
 * 
 * Shows the use of printk and the Log module
 *  The main advantages are:
 *      printk: lightweigh version of printf(). Basic functionality but comnsumes much less CPU and memory.
 *      log module: selective levels, that allow to filter messages at compile time. Context imnformation
 *          (timestamp, module) and buffered output.  
 * 
 * See:
 *      https://docs.nordicsemi.com/bundle/ncs-latest/page/zephyr/services/logging/index.html
 * 
 *
 * Configurations at prj.conf:
 *      Activate the UART_console (not strictly necessary as it is enabled by default)
 *          CONFIG_UART_CONSOLE=y
 *
 *      To enable the logger module
 *          CONFIG_LOG=y 
 */


#include <zephyr/kernel.h>          
#include <zephyr/sys/printk.h>      /* for printk() */
#include <zephyr/logging/log.h>     /* Required for log */

/* Must register the module in the log system */
/* Firts arg (module name) is an ***unquoted*** string */
/* Log level is optional. If not provided then default log level is used in the file. */
/*      levels are: LOG_LEVEL_{DBG,INF,WRN,ERR} */

LOG_MODULE_REGISTER(Log_Demo_Module,LOG_LEVEL_DBG); /* DBG -> all log messages sent to console*/

char sample_data[]="0123456789";

void issue_logs(void) 
{
    int i=2;

    /* Let's try different log levels  */
    LOG_INF("Simple INF message");
    LOG_INF("INF message with a variable value: %d",i);    
    LOG_DBG("Simple DBG debug level");
    LOG_WRN("Simple WARNING message");
    LOG_ERR("Simple ERROR message");
    
    /* Now lets dump the contents of a variable */
    LOG_HEXDUMP_INF(sample_data, sizeof(sample_data),"The ASCII in hex of numbers 0 to 9"); 

    return;
}

int main(void)
{
    printk("Using log level DBG ...\n\r;");
    issue_logs();
    return 0;   
 
}
