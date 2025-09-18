`define _IFDEF_BLOCK(define, block) \
    `ifdef define                         \
        block                             \
    `endif

`define _IFNDEF_BLOCK(define, block) \
    `ifndef define                         \
        block                             \
    `endif

`define _IFDEF_CONDITIONAL_SET(define, dst, src)  \
    `_IFDEF_BLOCK(define, dst = src;)

`define _IFDEF_CONDITIONAL_ASSIGN(define, dst, src)      \
    `_IFDEF_BLOCK(define, assign dst = src;)

`define _IFDEF_CONDITIONAL_FF(define, dst, src, clk, reset_n)      \
    `_IFDEF_BLOCK(define, always_ff @(posedge (clk)) if(!reset_n) dst <= '0; else dst <= src;)

`define _IFDEF_CONDITIONAL_FF_EN(define, dst, src, clk, reset_n, en)      \
    `_IFDEF_BLOCK(define, always_ff @(posedge (clk)) if(!reset_n) dst <= '0; else if (en) dst <= src;)

`define _IFNDEF_CONDITIONAL_SET(define, dst, src)  \
    `_IFNDEF_BLOCK(define, dst = src;)

`define _IFNDEF_CONDITIONAL_ASSIGN(define, dst, src)      \
    `_IFNDEF_BLOCK(define, assign dst = src;)

`define _IFNDEF_CONDITIONAL_FF(define, dst, src, clk, reset_n)      \
    `_IFNDEF_BLOCK(define, always_ff @(posedge (clk)) if(!reset_n) dst <= '0; else dst <= src;)

`define _IFNDEF_CONDITIONAL_FF_EN(define, dst, src, clk, reset_n, en)      \
    `_IFNDEF_BLOCK(define, always_ff @(posedge (clk)) if(!reset_n) dst <= '0; else if (en) dst <= src;)

`define _IFNDEF_CONDITIONAL_FORCE(define, dst, src)      \
    `_IFNDEF_BLOCK(define, force dst = src;)

`define _IFNDEF_CONDITIONAL_RELEASE(define, dst)      \
    `_IFNDEF_BLOCK(define, release dst;)

`define GEN_SIM_MACROS(name, def)                                                                                 \
    `define name``_SET(dst, src)                     `_IFDEF_CONDITIONAL_SET(def, dst, src)                       \
    `define name``_ASSIGN(dst, src)                  `_IFDEF_CONDITIONAL_ASSIGN(def, dst, src)                    \
    `define name``_BLOCK(block)                      `_IFDEF_BLOCK(def, block)                                    \
    `define name``_FF(dst, src, clk, reset_n)        `_IFDEF_CONDITIONAL_FF(def, dst, src, clk, reset_n)          \
    `define name``_FF_EN(dst, src, clk, reset_n, en) `_IFDEF_CONDITIONAL_FF_EN(def, dst, src, clk, reset_n, en)   \
    `define name``_IO(block)                         `_IFDEF_BLOCK(def, block)

`define GEN_INVERTED_SIM_MACROS(name, def)                                                                        \
    `define name``_SET(dst, src)                     `_IFNDEF_CONDITIONAL_SET(def, dst, src)                      \
    `define name``_ASSIGN(dst, src)                  `_IFNDEF_CONDITIONAL_ASSIGN(def, dst, src)                   \
    `define name``_BLOCK(block)                      `_IFNDEF_BLOCK(def, block)                                   \
    `define name``_FF(dst, src, clk, reset_n)        `_IFNDEF_CONDITIONAL_FF(def, dst, src, clk, reset_n)         \
    `define name``_FF_EN(dst, src, clk, reset_n, en) `_IFNDEF_CONDITIONAL_FF_EN(def, dst, src, clk, reset_n, en)  \
    `define name``_IO(block)                         `_IFNDEF_BLOCK(def, block)                                   \
    `define name``_FORCE(dst, src)                   `_IFNDEF_CONDITIONAL_FORCE(def, dst, src)                    \
    `define name``_RELEASE(dst)                      `_IFNDEF_CONDITIONAL_RELEASE(def, dst)

`GEN_SIM_MACROS(SHADOW_MODEL,SHADOW_MODEL)
`GEN_SIM_MACROS(ASSERTION_ENABLE,ASSERTION_ENABLE)
`GEN_INVERTED_SIM_MACROS(XMR_DUT,BBOX_DUT)
