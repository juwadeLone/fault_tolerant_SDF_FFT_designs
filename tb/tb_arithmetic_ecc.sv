`timescale 1ns/1ps
`include "common/tb_utils.svh"

module tb_arithmetic_ecc;
    `TB_INIT("arithmetic_ecc");
    `TB_TIMEOUT(100000)

    reg signed [34:0] c0r, c0i, c1r, c1i, c2r, c2i, c3r, c3i;
    reg signed [34:0] c4r, c4i, c5r, c5i;
    reg signed [34:0] r0r, r0i, r1r, r1i, r2r, r2i, r3r, r3i;
    reg signed [34:0] r4r, r4i, r5r, r5i;
    wire signed [34:0] o0r, o0i, o1r, o1i, o2r, o2i, o3r, o3i;
    integer i, j, variant, magnitude_index;
    reg signed [34:0] error_real, error_imag, magnitude;

    arithmetic_boundary_from_clean_v5 dut(
        c0r, c0i, c1r, c1i, c2r, c2i, c3r, c3i,
        c4r, c4i, c5r, c5i, r0r, r0i, r1r, r1i,
        r2r, r2i, r3r, r3i, r4r, r4i, r5r, r5i,
        o0r, o0i, o1r, o1i, o2r, o2i, o3r, o3i
    );

    task build;
        begin
            c0r = $random % 100000;
            c0i = $random % 100000;
            c1r = $random % 100000;
            c1i = $random % 100000;
            c2r = $random % 100000;
            c2i = $random % 100000;
            c3r = $random % 100000;
            c3i = $random % 100000;
            c4r = c0r + c1r + c2r + c3r;
            c4i = c0i + c1i + c2i + c3i;
            c5r = c0r - c1i - c2r + c3i;
            c5i = c0i + c1r - c2i - c3r;
            r0r = c0r; r0i = c0i;
            r1r = c1r; r1i = c1i;
            r2r = c2r; r2i = c2i;
            r3r = c3r; r3i = c3i;
            r4r = c4r; r4i = c4i;
            r5r = c5r; r5i = c5i;
        end
    endtask

    task check_outputs;
        begin
            `TB_CHECK_EQ(o0r, c0r, "arithmetic corrected o0r")
            `TB_CHECK_EQ(o0i, c0i, "arithmetic corrected o0i")
            `TB_CHECK_EQ(o1r, c1r, "arithmetic corrected o1r")
            `TB_CHECK_EQ(o1i, c1i, "arithmetic corrected o1i")
            `TB_CHECK_EQ(o2r, c2r, "arithmetic corrected o2r")
            `TB_CHECK_EQ(o2i, c2i, "arithmetic corrected o2i")
            `TB_CHECK_EQ(o3r, c3r, "arithmetic corrected o3r")
            `TB_CHECK_EQ(o3i, c3i, "arithmetic corrected o3i")
        end
    endtask

    initial begin
        tb_pass = 0;
        tb_fail = 0;
        tb_xfail = 0;
        tb_xpass = 0;
        for (i = 0; i < 20; i = i + 1) begin
            build;
            #1;
            check_outputs;
            for (magnitude_index = 0; magnitude_index < 4; magnitude_index =
                 magnitude_index + 1) begin
                case (magnitude_index)
                    0: magnitude = 35'sd1;
                    1: magnitude = -35'sd1;
                    2: magnitude = 35'sd1048576;
                    default: magnitude = -35'sd1048576;
                endcase
                for (variant = 0; variant < 3; variant = variant + 1) begin
                    for (j = 0; j < 6; j = j + 1) begin
                        r0r = c0r; r0i = c0i;
                        r1r = c1r; r1i = c1i;
                        r2r = c2r; r2i = c2i;
                        r3r = c3r; r3i = c3i;
                        r4r = c4r; r4i = c4i;
                        r5r = c5r; r5i = c5i;
                        error_real = (variant == 1) ? 0 : magnitude;
                        error_imag = (variant == 0) ? 0 : magnitude;
                        case (j)
                            0: begin r0r = r0r + error_real; r0i = r0i + error_imag; end
                            1: begin r1r = r1r + error_real; r1i = r1i + error_imag; end
                            2: begin r2r = r2r + error_real; r2i = r2i + error_imag; end
                            3: begin r3r = r3r + error_real; r3i = r3i + error_imag; end
                            4: begin r4r = r4r + error_real; r4i = r4i + error_imag; end
                            default: begin
                                r5r = r5r + error_real;
                                r5i = r5i + error_imag;
                            end
                        endcase
                        #1;
                        check_outputs;
                    end
                end
            end
            build;
            r0r = r0r + 35'sd1048576;
            r1r = r1r - 35'sd1;
            r2i = r2i + 35'sd1;
            #1;
            $display("arithmetic double-symbol result: %0d %0d %0d %0d",
                     o0r, o1r, o2r, o3r);
            `TB_CHECK((^o0r !== 1'bx) && (^o0i !== 1'bx) &&
                      (^o1r !== 1'bx) && (^o1i !== 1'bx) &&
                      (^o2r !== 1'bx) && (^o2i !== 1'bx) &&
                      (^o3r !== 1'bx) && (^o3i !== 1'bx),
                      "arithmetic double-symbol result is deterministic")
        end
        `TB_FINISH;
    end
endmodule
