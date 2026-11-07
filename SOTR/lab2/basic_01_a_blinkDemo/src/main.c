/*
 * Paulo Pedreiras, 2025/07
 * 		Simple Digital Output example, based on Nordic blinky
 *
 * 		Toggles periodically LED1, which is internally connected to P0.13 and labeled led0 on the devicetree
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

/* Define some return codes */
#define ERR_DEV_NOT_READY	-1

/* Define the sleep time, in ms (roughly half the period) */
#define SLEEP_TIME_MS 2000

/* Get led 0 node ID. Refer to the DTS file to find "led0" node label
 *   (could also be obtained via alias, see below).
 */
#define LED0_NODE_ID DT_NODELABEL(led0)
//#define LED0_NODE_ID DT_ALIAS(led0) /* Same action, via alias */

/* Get the device pointer, pin number, and configuration flags. A build error on this line means your board is unsupported.
 * See the sample documentation for information on how to fix this.
 */
static const struct gpio_dt_spec led1 = GPIO_DT_SPEC_GET(LED0_NODE_ID, gpios);

/*
 * The main function
 */
int main(void)
{
	int ret, ledstate=0;
	
	/* Check if device is ready */
	if (!device_is_ready(led1.port))  {
		return ERR_DEV_NOT_READY;
	}

	/* Print some hardware info, part of the gpio specification struct*/
	printf("led 1 info:\n");
	printf("\t Device name:%s \n",led1.port->name);
	printf("\t HW Pin %u \n",led1.pin);
	printf("\t Flags (Hex) %x\n",led1.dt_flags);

	/* Configure the GPIO pin for output ans set it to logic 0 */
	ret = gpio_pin_configure_dt(&led1, GPIO_OUTPUT_INACTIVE);
	if (ret < 0) {
		return ret;
	}

	/*
	 * The main loop
	 */
	while(1) { 
		/* Toggle the led */
		/* Could be used instead "ret = gpio_pin_toggle_dt(&led1);" (simpler-one line only) */
		ret = gpio_pin_set_dt(&led1,ledstate);
		if (ret < 0) {
			return ret;
		}

		if(ledstate == 1)
			ledstate = 0;
		else
			ledstate = 1; 

		/* Sleep */
		k_msleep(SLEEP_TIME_MS);
	}

	return 0;
}