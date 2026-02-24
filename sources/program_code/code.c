#include <stdio.h>
#include "xil_io.h"
#include "xil_types.h"
#include "sleep.h"
#include "xparameters.h"
#include "xil_printf.h"

#define TOP_BASE      XPAR_AXI_GPIO_TOP_0_BASEADDR 
#define TOP_REG_OFF   0x00u                        
#define TOP_TRI_OFF   0x04u                        
#define TOP_MASK_8BIT 0x01u                        
#define DELAY_US      1000000u                     // 1Sec

// -----------------------------
static inline void write_to_reg(u8 v)
{
    Xil_Out32(TOP_BASE + TOP_REG_OFF, (u32)(v & TOP_MASK_8BIT));
}

static inline u8 read_from_reg(void)
{
    return (u8)(Xil_In32(TOP_BASE + TOP_REG_OFF) & TOP_MASK_8BIT);
}

// -----------------------------
static inline void set_gpio_conf_input(void)
{
    Xil_Out32(TOP_BASE + TOP_TRI_OFF, 0x00u & TOP_MASK_8BIT); // 0 - input (tri-state)
}

static inline void set_gpio_conf_output(void)
{
    Xil_Out32(TOP_BASE + TOP_TRI_OFF, 0x01u & TOP_MASK_8BIT); // 1 - output
}

static inline u8 read_gpio_conf(void)
{
    return (u8)(Xil_In32(TOP_BASE + TOP_TRI_OFF) & TOP_MASK_8BIT);
}

// -----------------------------
int main(void)
{
    u8 led_val = 0;
    u8 tri_val = 0;

    set_gpio_conf_output();
    tri_val = read_gpio_conf();

    while (1) {
        led_val = !led_val;

        write_to_reg(led_val);


        u8 read_val = read_from_reg();
        xil_printf("GPIO state: %d\n", read_val);


        usleep(DELAY_US); 


        set_gpio_conf_input();
         tri_val = read_gpio_conf();

        xil_printf("GPIO direction (tri): %d\n", read_gpio_conf());

        usleep(DELAY_US);

  
        set_gpio_conf_output();
         tri_val = read_gpio_conf();

        xil_printf("GPIO direction (tri): %d\n", read_gpio_conf());
    }

    return 0;
}

