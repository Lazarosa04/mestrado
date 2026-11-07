/*
 * Paulo Pedreiras, 2025/07
 * 		Simple Digital Input/Output example.
 *
 * 		Set the state of LED1 according to the state of BUT1. 		
 * 		Note the difference between the devicetree naming (0...3) and the silk labeling (1...4) for leds and buttons
 *
 * Base documentation:
 *
 *      HW info:
 *          https://docs.nordicsemi.com/category/nrf52840-category
 *          Resources -> Peripherals -> GPIO / GPIOTE
 *
 *          Board specific HW info can be found in "nRF52840 DK Hardware", https://docs.nordicsemi.com/bundle/ug_nrf52840_dk/page/UG/dk/intro.html
 * 			
 *		Notes:
 * 			- Note that the GPIO must be enabled
 * 				In this version it is set in nrf52880_dk default config, so there is no need to set it in prj.conf
 * 			- nrf52880_dk default config also sets "CONFIG_SERIAL=y", "CONFIG_CONSOLE=y" and "CONFIG_UART_CONSOLE=y",
 * 				so we can use printf() and get output on the vcom 
 */

/* Includes. Add according to the resources used  */
#include <zephyr/kernel.h>          /* for k_msleep() */
#include <zephyr/device.h>          /* for device_is_ready() and device structure */
#include <zephyr/devicetree.h>		/* for DT_NODELABEL() */
#include <zephyr/drivers/gpio.h>    /* for GPIO api*/

/* Define return codes */
#define ERR_DEV_NOT_READY	-1

/* Define the polling time, in ms */
#define SLEEP_TIME_MS 100

/* Get led0 and button0 node IDs. Refer to the DTS file */
#define LED0_NODE_ID DT_ALIAS(led0)
#define BUT0_NODE_ID DT_ALIAS(sw0)


/* Get the device pointer, pin number, and configuration flags for led0 and button 0. A build error on this line means your board is unsupported. */
static const struct gpio_dt_spec led1 = GPIO_DT_SPEC_GET(LED0_NODE_ID, gpios);
static const struct gpio_dt_spec but1 = GPIO_DT_SPEC_GET(BUT0_NODE_ID, gpios);

/*
 * The main function
 */
int main(void)
{
	int ret =0;
	int butStat=0; // Variable to code the button status
	
	/* Check if device are ready */
	if (!device_is_ready(led1.port) || !device_is_ready(but1.port)) {
		return ERR_DEV_NOT_READY;
	}	

	/* Configure the GPIO pins for input/output and set active logic */
	/* Note that the devicetree activates the internal pullup and sets the active low flag */
	/*   so an external resistor is not needed and pressing the button causes a logic level of 1*/
	ret = gpio_pin_configure_dt(&led1, GPIO_OUTPUT_INACTIVE);
	if (ret < 0) {
		return ret;
	}

	ret = gpio_pin_configure_dt(&but1, GPIO_INPUT);
	if (ret < 0) {
		return ret;
	}

	/*
	 * The main loop
	 */
	while(1) { 
		/* Read button status and set led accordingly */
		/* Could (and should) be improved by adding e.g. debouncing */		
		butStat = gpio_pin_get_dt(&but1);
		if (butStat < 0) {
			return butStat;
		}
		ret = gpio_pin_set_dt(&led1,butStat);
		if (ret < 0) {
			return ret;
		}

		/* Sleep for a while to allow energy saving */
		k_msleep(SLEEP_TIME_MS);
	}

	return 0;
}