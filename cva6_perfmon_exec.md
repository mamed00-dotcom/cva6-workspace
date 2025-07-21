# CVA6 Performance‑Counter Example
---
## Code perfmon.c

```c
 /* perfmon.c */
#include <stdint.h>
#include <stdio.h>

/* ── CSR definitions (CV32A60AX) ─────────────────────────────────────────── */
#define CSR_MCOUNTINHIBIT   0x320
#define CSR_MINSTRET        0xB02
#define CSR_MHPMEVENT3      0x323
#define CSR_MHPMCOUNTER3    0xB03

/* ── CSR helpers ---------------------------------------------------- */
#define csr_write(csr, val) \
    asm volatile ("csrw  " stringify(csr) ", %0" :: "rK"(val))
#define csr_read(csr) ({       \
    uint32_t _v;                \
    asm volatile ("csrr %0, " stringify(csr) : "=r"(_v)); \
    _v;                         \
})

/* macro to stringify a macro name */
#define stringify(x) #x

static void enable_hpm3(void) {
    uint32_t mci = csr_read(CSR_MCOUNTINHIBIT);
    mci &= ~(1u << 3);  /* clear bit 3 => enable MHPMCOUNTER3 */
    csr_write(CSR_MCOUNTINHIBIT, mci);
}

/* ── micro-ops ────────────────────────────────────────────────────── */
static void wl_stall(void)  { asm volatile("lw t0, 0(sp)\n\taddi t1, t0, 1" ::: "t0","t1"); }
static void wl_loads(void)  { asm volatile("lw t0, 0(sp)\n\tlw t1, 4(sp)\n\tlw t2, 8(sp)" ::: "t0","t1","t2"); }
static void wl_stores(void) { asm volatile("sw x0, 0(sp)\n\tsw x0, 4(sp)"); }
static void wl_br(void)     { asm volatile("beq x0,x0,1f\n\tnop\n1:" :::); }
static void wl_call(void)   { asm volatile("jal ra,1f\n1:" ::: "ra"); }
/* exactly one return */
static void wl_ret(void) {
    asm volatile (
        "la t0, 1f\n\t"       // Load address of label1 into t0 (target for return)
        "mv ra, t0\n\t"       // Set RA (x1) to that target address
        "jalr x0, ra, 0\n\t"  // Jump to address in RA (execute a 'ret' instruction)
        "1:\n"               // Label1: execution continues here after the jump
        : : : "ra", "t0"
    );
}

/* ── run one HPM test ───────────────────────────────────────────────────── */
static void run(uint32_t event, const char* label, void (*work)(void)) {
    printf("\n[%s] (event %u)\n", label, event);

    /* select event, zero counter */
    csr_write(CSR_MHPMEVENT3, event);
    csr_write(CSR_MHPMCOUNTER3, 0);

    work();

    /* read back and disable */
    uint32_t cnt = csr_read(CSR_MHPMCOUNTER3);
    csr_write(CSR_MHPMEVENT3, 0);

    printf("  HPM3 = %u\n", cnt);
}

int main(void) {
    enable_hpm3();

    run(22, "Pipeline stall",      wl_stall);
    run(5,  "Memory LOADs",        wl_loads);
    run(6,  "Memory STOREs",       wl_stores);
    run(9,  "Branch instructions", wl_br);
    run(12, "CALL instructions",   wl_call);
    run(13, "RETURN instructions", wl_ret);

    /* quick minstret sanity-check */
    uint32_t before = csr_read(CSR_MINSTRET);
    asm volatile("addi x0, x0, 0");
    printf("\n[minstret delta] = %u\n",
           csr_read(CSR_MINSTRET) - before);

    return 0;
}

```

---

## 1 Test Source

- `` – counts three machine‐mode events
  - `minstret`  (retired instructions)
  - `mcycle`   (cycles)
  - `mhpmcounter3` (generic counter – event ID 20, retired integer instrs)
- Compile‑time switch `` skips section 3 for environments (Spike) that do not implement generic HPM counters.

---

## 2 Environment

```bash
# once per terminal
export CVA6_REPO_DIR=$HOME/cva6
cd verif/sim
export DV_SIMULATORS=veri-testharness
source setup-env.sh
```

---

## 3 Build & Run (Verilator test‑harness)

### 3.1 Single command

```bash
python3 cva6.py   --target cv64a6_imafdc_sv39   --iss "$DV_SIMULATORS"   --iss_yaml cva6.yaml   --c_tests ../tests/custom/perfmon/perfmon.c   --linker ../../config/gen_from_riscv_config/linker/link.ld   --gcc_opts='-static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -g ../tests/custom/common/syscalls.c ../tests/custom/common/crt.S -lgcc -I../tests/custom/env -I../tests/custom/common'   --issrun_opts='+echo_uart'
```

### 3.2 Results

```
out_YYYY-MM-DD/veri-testharness_sim/
             ├─ perfmon.cv64a6_imafdc_sv39.log.iss   # console / UVM log
             ├─ perfmon.cv64a6_imafdc_sv39.log      # RVFI disassembly
```



## 4 building manually 

```bash 
cd ~/cva6/verif/sim
riscv-none-elf-gcc \
  -march=rv64gc -mabi=lp64d \
  -T ../../config/gen_from_riscv_config/linker/link.ld \
  -static -mcmodel=medany -fvisibility=hidden \
  -nostdlib -nostartfiles -g \
  ../tests/custom/common/crt.S \
  ../tests/custom/common/syscalls.c \
  ../tests/custom/perfmon/perfmon.c \
  -I../tests/custom/env -I../tests/custom/common \
  -lgcc \
  -o perfmon.elf
```


```bash 
cd ~/cva6
make verilate VERILATOR_FLAGS="--no-timing" target=cv64a6_imafdc_sv39
```


```bash 
./work-ver/Variane_testharness   verif/sim/perfmon.elf   +echo_uart

```

- output: 
```bash
This emulator compiled with JTAG Remote Bitbang client. To enable, use +jtag_rbb_enable=1.
Listening on port 34271
*** [rvf_tracer] INFO: Loading binary : 
*** [rvf_tracer] INFO: tohost_addr: 0000000000000000
*** [rvf_tracer] WARNING: No valid address of 'tohost' (tohost == 0x0000000000000000), termination possible only by timeout or Ctrl-C!


[Pipeline stall] (event 22)
  HPM3 = 5

[Memory LOADs] (event 5)
  HPM3 = 5

[Memory STOREs] (event 6)
  HPM3 = 3

[Branch instructions] (event 9)
  HPM3 = 3

[CALL instructions] (event 12)
  HPM3 = 2

[RETURN instructions] (event 13)
  HPM3 = 2

[minstret delta] = 5
verif/sim/perfmon.elf *** SUCCESS *** (tohost = 0) after 1001264 cycles
CPU time used: 71941.82 ms
Wall clock time passed: 72008.46 ms
```

## Making a script file to run it automatically 

- create a .sh file 
```bash
nano run_sim.sh
```

```bash 
#!/bin/bash

# Check if a filename was passed
if [ -z "$1" ]; then
  echo "Usage: $0 <filename>"
  exit 1
fi

DIR_NAME="$1" // Folder path
FILENAME="$2" // File name

# Step 1: Compile the ELF
cd ~/cva6/verif/sim || { echo "Failed to enter sim directory"; exit 1; }

riscv-none-elf-gcc \
  -march=rv64gc -mabi=lp64d \
  -T ../../config/gen_from_riscv_config/linker/link.ld \
  -static -mcmodel=medany -fvisibility=hidden \
  -nostdlib -nostartfiles -g \
  ../tests/custom/common/crt.S \
  ../tests/custom/common/syscalls.c \
  ../tests/custom/"$DIR_NAME"/"$FILENAME".c \
  -I../tests/custom/env -I../tests/custom/common \
  -lgcc \
  -o "$FILENAME".elf

if [ $? -ne 0 ]; then
  echo "Compilation failed."
  exit 1
fi

# Step 2: Build the Verilated model
cd ~/cva6 || { echo "Failed to enter cva6 directory"; exit 1; }

make verilate VERILATOR_FLAGS="--no-timing" target=cv64a6_imafdc_sv39

if [ $? -ne 0 ]; then
  echo "Verilation failed."
  exit 1
fi

# Step 3: Run the simulation
cd ~/cva6 || { echo "Failed to return to sim directory"; exit 1; }

./work-ver/Variane_testharness verif/sim/"$FILENAME".elf +echo_uart
```

- In terminal, we run for once : 
```bash 
chmod +x ~/run_sim.sh
```
Then: 
```bash
~/run_sim.sh perfmon perfmon
```
