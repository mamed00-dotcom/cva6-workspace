# PerfMon RISC‑V Performance Monitoring Report

This document summarizes the **perfmon.c** harness, its observed outputs when measuring various events, and a step‑by‑step explanation on how we got the results. please check `cva6_perfmon_exec` on /cva6 to run the simulation.

Run the following command to get the .s file : 

```bash 
riscv-none-elf-gcc -O0 -S perfmon.c -o perfmon.s
```

---

## 1. Source Code (perfmon.c)

```c
/* perfmon.c (with new instruction)*/
#include <stdint.h>
#include <stdio.h>

/* ── CSR definitions (CV32A60AX) ─────────────────────────────────────────── */
#define CSR_MCOUNTINHIBIT   0x320
#define CSR_MINSTRET        0xB02
#define CSR_MHPMEVENT3      0x323
#define CSR_MHPMCOUNTER3    0xB03

/* ── CSR helpers ---------------------------------------------------- */
#define stringify(x) #x
#define csr_write(csr, val) \
    asm volatile("csrw " stringify(csr) ", %0" :: "rK"(val))
#define csr_read(csr) ({       \
    uint32_t _v;                \
    asm volatile("csrr %0, " stringify(csr) : "=r"(_v)); \
    _v;                         \
})

/* ── Safe load buffer for wl_loads and pure load ──────────────────────── */
static const uint32_t load_data[3] = {7, 3, 5};

static void enable_hpm3(void) {
    uint32_t mci = csr_read(CSR_MCOUNTINHIBIT);
    mci &= ~(1u << 3);  /* enable MHPMCOUNTER3 */
    csr_write(CSR_MCOUNTINHIBIT, mci);
}

/* ── micro-ops ────────────────────────────────────────────────────── */
static void wl_stall(void) {
    asm volatile(
        "la   t3, load_data\n\t"
        "lw   t0, 0(t3)\n\t"
        "addi t1, t0, 1\n\t"
        "lw   t2, 4(t3)\n\t"
        "addi t3, t2, 1"
        ::: "t0","t1","t2","t3"
    );
}
static void wl_loads(void) {
    asm volatile(
        "la   t3, load_data\n\t"
        "lw   t0, 0(t3)\n\t"
        "lw   t1, 4(t3)\n\t"
        "lw   t2, 8(t3)\n\t"
        ::: "t0","t1","t2","t3"
    );
}
static void wl_stores(void) {
    asm volatile(
        "sw x0, 0(sp)\n\t"
        "sw x0, 4(sp)"
        :::
    );
}
static void wl_br(void) {
    asm volatile(
        "beq x0, x0, 1f\n\t"
        "nop\n"
        "1:"
    );
}
static void wl_call(void) {
    asm volatile("jal ra,1f\n1:" ::: "ra");
}
static void wl_ret(void) {
    asm volatile(
        "la   t0, 1f\n\t"
        "mv   ra, t0\n\t"
        "jalr x0, ra, 0\n"
        "1:"
        ::: "t0","ra"
    );
}
static void wl_addi(void) {
    asm volatile("addi t0, t0, 42" ::: "t0");
}
static void wl_mul(void) {
    asm volatile("mul t1, t0, t0" ::: "t1");
}


/* ── run one HPM test with dynamic reg capture ───────────────────────── */
static void run(uint32_t event, const char* label,
                void (*work)(void), uint8_t num_regs) {
    printf("\n[%s] (event %u)\n", label, event);
    csr_write(CSR_MHPMEVENT3, event);
    csr_write(CSR_MHPMCOUNTER3, 0);

    /* init registers t0..t2 */
    asm volatile(
        "li t0, 7\n\t"
        "li t1, 3\n\t"
        "li t2, 5"
        ::: "t0","t1","t2"
    );

    work();

    uint32_t cnt = csr_read(CSR_MHPMCOUNTER3);
    csr_write(CSR_MHPMEVENT3, 0);

    /* capture up to 4 regs */
    uint32_t r[4] = {0};
    asm volatile("mv %0, t0" : "=r"(r[0]));
    asm volatile("mv %0, t1" : "=r"(r[1]));
    if (num_regs > 2) asm volatile("mv %0, t2" : "=r"(r[2]));
    if (num_regs > 3) asm volatile("mv %0, t3" : "=r"(r[3]));

    printf("  HPM3 = %u\n  regs =", cnt);
    for (uint8_t i = 0; i < num_regs; i++) {
        printf(" t%u=0x%08x(%u)", i, r[i], r[i]);
    }
    printf("\n");
}

int main(void) {
    enable_hpm3();

    run(22, "Pipeline stall", wl_stall, 4);

/* Measure exactly three loads back‐to‐back */
csr_write(CSR_MHPMEVENT3, 5);       // Select “Memory LOADs” event
csr_write(CSR_MHPMCOUNTER3, 0);     // Zero the counter
asm volatile(
    "la   t3, load_data\n\t"        // point to your constant buffer
    "lw   t0, 0(t3)\n\t"            // load #1
    "lw   t1, 4(t3)\n\t"            // load #2
    "lw   t2, 8(t3)"               // load #3
    ::: "t0","t1","t2","t3"
);
uint32_t three_loads = csr_read(CSR_MHPMCOUNTER3);
csr_write(CSR_MHPMEVENT3, 0);      // Disable counting
printf("[Triple Memory LOAD] = %u\n", three_loads);


    run(5,  "Memory LOADs", wl_loads, 4);
    run(6,  "Memory STOREs", wl_stores, 2);
    run(9,  "Branch instructions", wl_br, 2);
    run(12, "CALL instructions", wl_call, 2);
    run(13, "RETURN instructions", wl_ret, 2);

    run(20, "Integer ADDI", wl_addi, 2);
    run(20, "Integer MUL", wl_mul, 2);

    uint32_t before = csr_read(CSR_MINSTRET);
    asm volatile("addi x0, x0, 0");
    printf("\n[minstret delta] = %u\n", csr_read(CSR_MINSTRET) - before);

    return 0;
}
	
```

---

## 2. Observed Output

```
[Pipeline stall] (event 22)
  HPM3 = 18
  regs = t0=0x00000007(7) t1=0x00000008(8) t2=0x00000003(3) t3=0x00000004(4)
[Triple Memory LOAD] = 3

[Memory LOADs] (event 5)
  HPM3 = 5
  regs = t0=0x00000007(7) t1=0x00000003(3) t2=0x00000005(5) t3=0x800051a0(2147504544)

[Memory STOREs] (event 6)
  HPM3 = 3
  regs = t0=0x00000007(7) t1=0x00000003(3)

[Branch instructions] (event 9)
  HPM3 = 3
  regs = t0=0x00000007(7) t1=0x00000003(3)

[CALL instructions] (event 12)
  HPM3 = 2
  regs = t0=0x00000007(7) t1=0x00000003(3)

[RETURN instructions] (event 13)
  HPM3 = 2
  regs = t0=0x80004386(2147500934) t1=0x00000003(3)

[Integer ADDI] (event 20)
  HPM3 = 8
  regs = t0=0x00000031(49) t1=0x00000003(3)

[Integer MUL] (event 20)
  HPM3 = 8
  regs = t0=0x00000007(7) t1=0x00000031(49)

[minstret delta] = 5
verif/sim/perfmon.elf *** SUCCESS *** (tohost = 0) after 1829336 cycles
CPU time used: 127404.98 ms
Wall clock time passed: 127522.62 ms

```

---

## 3. Explanation of Results

### A) Pipeline stalls (Event 22 = 18)

When you zero MHPMCOUNTER3:

```asm
la   t3, load_data   # AUIPC+ADDI (no stall)
lw   t0, 0(t3)       # load 1
addi t1, t0, 1       # needs t0 -> stalls S0 cycles
lw   t2, 4(t3)       # load 2
addi t3, t2, 1       # needs t2 -> stalls S1 cycles

```

Event 22 (“Pipeline stall”) counts every cycle the decode/issue stage waits for a source register.

Each addi comes immediately after its lw, so the core must pause until the load returns from memory.

Prologue/epilogue, CSR writes, and call/return flushes do not increment event 22; only these operand‑wait bubbles do.

\### B) Triple Memory LOAD (pure 3× `lw`, printed = 3) By bracketing exactly three `lw` instructions with CSR writes, no function prologue/epilogue runs inside the counting window:

```asm
csrw mhpmcounter3, x0   <- zero
lw t0, 0(t3)
lw t1, 4(t3)
lw t2, 8(t3)
csrr a5, mhpmcounter3  <- read => 3
```

Yields exactly **3** retired loads.

\### C) 1- Memory LOADs (Event 5 = 3) In `run(5, wl_loads)`, the window includes:

- **1** explicit `lw t0,0(t3)` in `wl_loads`
- **1** implicit `lw s0,12(sp)` restoring `s0`
- **1** implicit `lw a5,-24(s0)` reloading the counter value -> **3** total.

2- In order to compare the number of cycles in the output we add some extra instructions inside the load function Memory LOADs (Event 5 = 5):
```bash
static void wl_loads(void) {
    asm volatile(
        "la   t3, load_data\n\t"
        "lw   t0, 0(t3)\n\t"
        "lw   t1, 4(t3)\n\t"
        "lw   t2, 8(t3)\n\t"
        ::: "t0","t1","t2","t3"
    );
}
```

When invoked via `run(5, "Memory LOADs", wl_loads, 3)`, the counted window covers:
	- Three explicit loads in wl_loads:
	
```bash
	lw   t0,0(t3)
	lw   t1,4(t3)
	lw   t2,8(t3)
```
	-Implicit epilogue load restoring s0:
```bash
	lw   s0,12(sp)  # implicit load from function epilogue line 48
```
	-Implicit loader in run() fetching the counter value:
```bash
# ... after returning from wl_loads
# 101 "perfmon.c" 1
    csrr a5, 0xB03       # read MHPMCOUNTER3 (end of counted region)
# 0 "" 2
# NO_APP
    sw   a5,-24(s0)      # store counter result
    lw   a5,-24(s0)      # <- THIS lw is the implicit load counted (implicit load #3) line 241
    sw   a5,-28(s0)
# 104 "perfmon.c" 1
    csrw 0x323, 0       # disable counter
```
\### D) Memory STOREs (Event 6 = 3) The stores counted are:

- **1** implicit `sw s0,12(sp)` saving `s0` (prologue)
- **2** explicit `sw x0,0(sp)` and `sw x0,4(sp)` in `wl_stores` -> **3** total.

*Branch*, *Call*, *Return*, *Integer* events similarly combine the explicit inline‑ASM with implicit prologue/epilogue overhead, matching the counts shown above.

### F) Integer ADDI (Event 20 = 8)

When invoking `run(20, "Integer ADDI", wl_addi, 2)`, Event 20 counts each retire of an `addi` instruction between zeroing and readback:

1. **Three `li` initializations** in `run()` expand to `addi`:
```asm
   addi t0, x0, 7  # li t0,7
   addi t1, x0, 3  # li t1,3
   addi t2, x0, 5  # li t2,5
```

2. wl_addi prologue, adjust stack pointer:
```asm
addi sp, sp, -16  
```
3. Explicit arithmetic in wl_addi
```asm
addi t0, t0, 42
```
4.  wl_addi epilogue, restore stack pointer
```asm
addi sp, sp, 16
```
5. run() prologue, create frame:
```asm
addi sp, sp, -64
```
6. minstret marker before reading CSR_MINSTRET:
```asm
addi x0, x0, 0
```


# CV32A60X – Pipeline‑Stall Counter (HPM3, event 22)

This part compares **three ways** of instrumenting the same `wl_stall()` kernel and shows how the placement of the CSR instructions that start/stop the event selector changes what gets counted.

---

## Scenario 1 — Global Counting (18 cycles)

``** as built by the compiler (no extra CSRs)**

```c
static void wl_stall(void) {
    asm volatile(
        "la   t3, load_data\n\t"
        "lw   t0, 0(t3)\n\t"
        "addi t1, t0, 1\n\t"
        "lw   t2, 4(t3)\n\t"
        "addi t3, t2, 1"
        ::: "t0","t1","t2","t3"
    );
}
```

*Counting window*: everything from the call into `wl_stall()` until the return, including frontend flushes and prologue/epilogue.\
*Measured result*: **HPM3 = 18** cycles.

---

## Scenario 2 — Local Start/Stop Inside the Kernel (9 cycles)

``** with explicit stop / reset / start / stop**

```c
static void __attribute__((naked)) wl_stall(void)
{
    asm volatile(
        "csrw 0x323, x0\n\t"        /* stop event 22          */
        "csrw 0xB03,  x0\n\t"        /* reset counter          */

        "la   t3, load_data\n\t"      /* pointer setup          */

        "li   t0, 22\n\t"
        "csrw 0x323, t0\n\t"         /* start event 22         */

        /* --- kernel under test --- */
        "lw   t0, 0(t3)\n\t"
        "addi t1, t0, 1\n\t"          /* load->use #1            */
        "lw   t2, 4(t3)\n\t"
        "addi t3, t2, 1\n\t"          /* load->use #2            */
        /* ------------------------ */

        "csrw 0x323, x0\n\t"         /* stop before return     */
        "ret\n\t"
        ::: "t0","t1","t2","t3"
    );
}
```

Counting window : Begins after the csrw 0x323,t0 retires (counter active) and ends before the final csrw 0x323,x0. Therefore, it captures only the two load->use stalls; the CSR pipeline flush itself and the subsequent ret flush are outside the window.



---

## Scenario 3 — Event Disabled for Sanity Check (0 cycles)

``** with the start lines commented out**

```c
static void __attribute__((naked)) wl_stall(void)
{
    asm volatile(
        "csrw 0x323, x0\n\t"        /* selector cleared */
        "csrw 0xB03,  x0\n\t"        /* counter reset   */

        "la   t3, load_data\n\t"

        /* selector never re‑enabled */
        "lw   t0, 0(t3)\n\t"
        "addi t1, t0, 1\n\t"
        "lw   t2, 4(t3)\n\t"
        "addi t3, t2, 1\n\t"

        "ret\n\t"
        ::: "t0","t1","t2","t3"
    );
}
```

Because the selector remains at 0, the counter never increments, so **HPM3 = 0** cycles.



*Revision 22 Jul 2025*

