#include "Vuart_cmd_decoder.h"
#include "verilated.h"

#include <cstdint>
#include <cstdio>

static int pass_count;
static int fail_count;
static int xfail_count;
static int xpass_count;
static vluint64_t sim_time;

double sc_time_stamp() {
    return static_cast<double>(sim_time);
}

static Vuart_cmd_decoder *dut;

static void tick() {
    dut->clk = 0;
    dut->eval();
    ++sim_time;
    dut->clk = 1;
    dut->eval();
    ++sim_time;
    dut->clk = 0;
    dut->eval();
}

static void check(bool condition, const char *message) {
    if (condition) {
        ++pass_count;
        std::printf("PASS: %s\n", message);
    } else {
        ++fail_count;
        std::printf("FAIL: %s\n", message);
    }
}

static void xcheck(bool condition, const char *message, const char *reason) {
    if (condition) {
        ++xpass_count;
        ++fail_count;
        std::printf("XPASS: %s (RTL behaviour changed: %s)\n", message, reason);
    } else {
        ++xfail_count;
        std::printf("XFAIL: %s (%s)\n", message, reason);
    }
}

static void reset_dut() {
    dut->rst = 1;
    dut->byte_ready = 0;
    dut->rx_byte = 0;
    tick();
    tick();
    dut->rst = 0;
    tick();
}

static void drive_byte(uint8_t value, int idle_cycles = 0) {
    dut->rx_byte = value;
    dut->byte_ready = 1;
    tick();
    dut->byte_ready = 0;
    for (int i = 0; i < idle_cycles; ++i) {
        tick();
    }
}

struct Frame {
    uint8_t opcode;
    uint8_t site;
    uint8_t stage;
    uint8_t sel;
    uint8_t component;
    uint8_t bit;
    uint8_t trigger_mode;
    uint8_t trigger_lo;
    uint8_t trigger_hi;
};

static uint8_t checksum(const Frame &frame) {
    return frame.opcode ^ frame.site ^ frame.stage ^ frame.sel ^
           frame.component ^ frame.bit ^ frame.trigger_mode ^
           frame.trigger_lo ^ frame.trigger_hi;
}

static void send_frame(const Frame &frame, bool corrupt_checksum,
                       int idle_cycles = 0) {
    const uint8_t payload[] = {
        frame.opcode, frame.site, frame.stage, frame.sel, frame.component,
        frame.bit, frame.trigger_mode, frame.trigger_lo, frame.trigger_hi,
        static_cast<uint8_t>(checksum(frame) ^ (corrupt_checksum ? 1 : 0))
    };

    drive_byte(0xa5, idle_cycles);
    for (uint8_t value : payload) {
        drive_byte(value, idle_cycles);
    }
}

static void finish_and_report() {
    std::printf("TB uart_cmd_decoder: %d passed, %d failed, %d xfail, %d xpass\n",
                pass_count, fail_count, xfail_count, xpass_count);
    if (fail_count != 0 || xpass_count != 0) {
        std::fflush(stdout);
        std::exit(1);
    }
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    dut = new Vuart_cmd_decoder;
    dut->clk = 0;
    dut->rst = 0;
    dut->byte_ready = 0;
    dut->rx_byte = 0;

    const char *reason =
        "uart_cmd_decoder frame_buf off-by-one: payload byte k stored at "
        "frame_buf[k-1]; checksum compared against stale frame_buf[10]";
    const Frame first = {0x01, 0x00, 0x01, 0x02, 0x01, 0x03, 0x04, 0x05, 0x06};
    const Frame second = {0x01, 0x01, 0x0a, 0x07, 0x00, 0x3d, 0x00, 0x09, 0x08};

    reset_dut();
    drive_byte(0x11, 0);
    drive_byte(0x12, 3);
    drive_byte(0x13, 0);
    check(!dut->frame_valid && !dut->frame_bad, "leading junk is ignored");

    reset_dut();
    send_frame(first, false, 0);
    xcheck(dut->frame_valid == 1 && dut->frame_bad == 0,
           "well-formed frame is accepted", reason);
    xcheck(dut->frame_valid == 1 && dut->frame_bad == 0 &&
               dut->opcode == first.opcode && dut->site == first.site &&
               dut->stage_id == first.stage && dut->sel == first.sel &&
               dut->component == first.component && dut->bit_index == first.bit &&
               dut->trig_mode == first.trigger_mode &&
               dut->trig_count == 0x0605,
           "well-formed fields decode", reason);
    check(!dut->frame_valid && !dut->frame_bad,
          "eleven-byte frame produces no response in current RTL");
    drive_byte(0x00);
    check(dut->frame_bad == 1 && dut->frame_valid == 0,
          "twelfth byte exposes stale checksum comparison");

    reset_dut();
    send_frame(first, true, 2);
    xcheck(dut->frame_bad == 1 && dut->frame_valid == 0,
           "bad checksum is rejected", reason);
    check(!dut->frame_valid && !dut->frame_bad,
          "bad checksum has no response before the twelfth byte");
    drive_byte(0x00);
    check(dut->frame_valid == 1 && dut->frame_bad == 0,
          "bad checksum is accepted when stale frame_buf[10] matches");

    reset_dut();
    send_frame(first, false, 0);
    dut->rx_byte = 0xa5;
    dut->byte_ready = 1;
    tick();
    check(dut->frame_bad == 1 && dut->frame_valid == 0,
          "back-to-back preamble becomes the twelfth payload byte");
    dut->byte_ready = 0;
    send_frame(second, false, 0);
    xcheck(dut->frame_valid == 1, "second back-to-back frame is accepted", reason);
    check(!dut->frame_valid && !dut->frame_bad,
          "remaining bytes after the delayed error are ignored");

    reset_dut();
    drive_byte(0xa5);
    drive_byte(first.opcode);
    dut->rst = 1;
    tick();
    dut->rst = 0;
    send_frame(second, false, 1);
    xcheck(dut->frame_valid == 1, "frame after mid-frame reset is accepted", reason);
    check(!dut->frame_valid && !dut->frame_bad,
          "mid-frame reset discards the partial frame");

    finish_and_report();
    delete dut;
    return 0;
}
