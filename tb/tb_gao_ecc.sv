`timescale 1ns/1ps
`include "common/tb_utils.svh"

module tb_gao_ecc;
    `TB_INIT("gao_ecc");
    `TB_TIMEOUT(100000)

    reg signed [34:0] c0r, c0i, c1r, c1i, c2r, c2i, c3r, c3i;
    reg signed [34:0] c4r, c4i, c5r, c5i, c6r, c6i;
    reg signed [34:0] r0r, r0i, r1r, r1i, r2r, r2i, r3r, r3i;
    reg signed [34:0] r4r, r4i, r5r, r5i, r6r, r6i;
    wire signed [34:0] d0r, d0i, d1r, d1i, d2r, d2i, d3r, d3i;
    integer i, j, variant, magnitude_index;
    reg signed [34:0] error_real, error_imag, magnitude;

    gao_boundary_from_clean_v5 dut(
        c0r, c0i, c1r, c1i, c2r, c2i, c3r, c3i,
        c4r, c4i, c5r, c5i, c6r, c6i,
        r0r, r0i, r1r, r1i, r2r, r2i, r3r, r3i,
        r4r, r4i, r5r, r5i, r6r, r6i,
        d0r, d0i, d1r, d1i, d2r, d2i, d3r, d3i
    );

    task build;
        begin
            c0r = $random % 10000; c0i = $random % 10000;
            c1r = $random % 10000; c1i = $random % 10000;
            c2r = $random % 10000; c2i = $random % 10000;
            c3r = $random % 10000; c3i = $random % 10000;
            c4r = $random % 10000; c4i = $random % 10000;
            c5r = $random % 10000; c5i = $random % 10000;
            c6r = $random % 10000; c6i = $random % 10000;
            r0r = c0r; r0i = c0i;
            r1r = c1r; r1i = c1i;
            r2r = c2r; r2i = c2i;
            r3r = c3r; r3i = c3i;
            r4r = c4r; r4i = c4i;
            r5r = c5r; r5i = c5i;
            r6r = c6r; r6i = c6i;
        end
    endtask

    task check_outputs;
        begin
            `TB_CHECK_EQ(d0r, c2r, "GAO corrected d0r")
            `TB_CHECK_EQ(d0i, c2i, "GAO corrected d0i")
            `TB_CHECK_EQ(d1r, c4r, "GAO corrected d1r")
            `TB_CHECK_EQ(d1i, c4i, "GAO corrected d1i")
            `TB_CHECK_EQ(d2r, c5r, "GAO corrected d2r")
            `TB_CHECK_EQ(d2i, c5i, "GAO corrected d2i")
            `TB_CHECK_EQ(d3r, c6r, "GAO corrected d3r")
            `TB_CHECK_EQ(d3i, c6i, "GAO corrected d3i")
        end
    endtask

    initial begin
        tb_pass = 0;
        tb_fail = 0;
        tb_xfail = 0;
        tb_xpass = 0;
        for (i = 0; i < 30; i = i + 1) begin
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
                    for (j = 0; j < 7; j = j + 1) begin
                        r0r = c0r; r0i = c0i;
                        r1r = c1r; r1i = c1i;
                        r2r = c2r; r2i = c2i;
                        r3r = c3r; r3i = c3i;
                        r4r = c4r; r4i = c4i;
                        r5r = c5r; r5i = c5i;
                        r6r = c6r; r6i = c6i;
                        error_real = (variant == 1) ? 0 : magnitude;
                        error_imag = (variant == 0) ? 0 : magnitude;
                        case (j)
                            0: begin r0r = r0r + error_real; r0i = r0i + error_imag; end
                            1: begin r1r = r1r + error_real; r1i = r1i + error_imag; end
                            2: begin r2r = r2r + error_real; r2i = r2i + error_imag; end
                            3: begin r3r = r3r + error_real; r3i = r3i + error_imag; end
                            4: begin r4r = r4r + error_real; r4i = r4i + error_imag; end
                            5: begin r5r = r5r + error_real; r5i = r5i + error_imag; end
                            default: begin
                                r6r = r6r + error_real;
                                r6i = r6i + error_imag;
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
            #1;
            $display("GAO double-symbol result: %0d %0d %0d %0d",
                     d0r, d1r, d2r, d3r);
            `TB_CHECK((^d0r !== 1'bx) && (^d0i !== 1'bx) &&
                      (^d1r !== 1'bx) && (^d1i !== 1'bx) &&
                      (^d2r !== 1'bx) && (^d2i !== 1'bx) &&
                      (^d3r !== 1'bx) && (^d3i !== 1'bx),
                      "GAO double-symbol result is deterministic")
        end
        `TB_FINISH;
    end
endmodule
