// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
`ifndef NTR_SINK_MMR_PKG_SVH
`define NTR_SINK_MMR_PKG_SVH

package ntr_sink_mmr_pkg;

localparam NTR_SINK_REG_MAP_BASE_ADDR                                  = 12'h000;

localparam NTR_SINK_TRRAMCONTROL_REG_OFFSET                            = 12'h000;
localparam NTR_SINK_TRRAMCONTROL_REG_ADDR                              = 12'h000;
localparam NTR_SINK_TRRAMIMPL_REG_OFFSET                               = 12'h004;
localparam NTR_SINK_TRRAMIMPL_REG_ADDR                                 = 12'h004;
localparam NTR_SINK_TRRAMSTARTLOW_REG_OFFSET                           = 12'h010;
localparam NTR_SINK_TRRAMSTARTLOW_REG_ADDR                             = 12'h010;
localparam NTR_SINK_TRRAMSTARTHIGH_REG_OFFSET                          = 12'h014;
localparam NTR_SINK_TRRAMSTARTHIGH_REG_ADDR                            = 12'h014;
localparam NTR_SINK_TRRAMLIMITLOW_REG_OFFSET                           = 12'h018;
localparam NTR_SINK_TRRAMLIMITLOW_REG_ADDR                             = 12'h018;
localparam NTR_SINK_TRRAMLIMITHIGH_REG_OFFSET                          = 12'h01C;
localparam NTR_SINK_TRRAMLIMITHIGH_REG_ADDR                            = 12'h01C;
localparam NTR_SINK_TRRAMWPLOW_REG_OFFSET                              = 12'h020;
localparam NTR_SINK_TRRAMWPLOW_REG_ADDR                                = 12'h020;
localparam NTR_SINK_TRRAMWPHIGH_REG_OFFSET                             = 12'h024;
localparam NTR_SINK_TRRAMWPHIGH_REG_ADDR                               = 12'h024;
localparam NTR_SINK_TRRAMRPLOW_REG_OFFSET                              = 12'h028;
localparam NTR_SINK_TRRAMRPLOW_REG_ADDR                                = 12'h028;
localparam NTR_SINK_TRRAMRPHIGH_REG_OFFSET                             = 12'h02C;
localparam NTR_SINK_TRRAMRPHIGH_REG_ADDR                               = 12'h02C;
localparam NTR_SINK_TRRAMDATA_REG_OFFSET                               = 12'h040;
localparam NTR_SINK_TRRAMDATA_REG_ADDR                                 = 12'h040;
localparam NTR_SINK_TRCUSTOMRAMSMEMLIMITLOW_REG_OFFSET                 = 12'hE00;
localparam NTR_SINK_TRCUSTOMRAMSMEMLIMITLOW_REG_ADDR                   = 12'hE00;
localparam NTR_SINK_SCRATCHLO_REG_OFFSET                               = 12'hFF8;
localparam NTR_SINK_SCRATCHLO_REG_ADDR                                 = 12'hFF8;
localparam NTR_SINK_SCRATCHHI_REG_OFFSET                               = 12'hFFC;
localparam NTR_SINK_SCRATCHHI_REG_ADDR                                 = 12'hFFC;

localparam NTR_SINK_TRRAMCONTROL_TRRAMACTIVE_MASK                       = 32'h1;
localparam NTR_SINK_TRRAMCONTROL_TRRAMACTIVE_SHIFT                      = 0;
localparam NTR_SINK_TRRAMCONTROL_TRRAMACTIVE_LOW                        = 0;
localparam NTR_SINK_TRRAMCONTROL_TRRAMACTIVE_HIGH                       = 0;
localparam NTR_SINK_TRRAMCONTROL_TRRAMACTIVE_WIDTH                      = 1;

localparam NTR_SINK_TRRAMCONTROL_TRRAMENABLE_MASK                       = 32'h2;
localparam NTR_SINK_TRRAMCONTROL_TRRAMENABLE_SHIFT                      = 1;
localparam NTR_SINK_TRRAMCONTROL_TRRAMENABLE_LOW                        = 1;
localparam NTR_SINK_TRRAMCONTROL_TRRAMENABLE_HIGH                       = 1;
localparam NTR_SINK_TRRAMCONTROL_TRRAMENABLE_WIDTH                      = 1;

localparam NTR_SINK_TRRAMCONTROL_RSVD22_MASK                            = 32'h4;
localparam NTR_SINK_TRRAMCONTROL_RSVD22_SHIFT                           = 2;
localparam NTR_SINK_TRRAMCONTROL_RSVD22_LOW                             = 2;
localparam NTR_SINK_TRRAMCONTROL_RSVD22_HIGH                            = 2;
localparam NTR_SINK_TRRAMCONTROL_RSVD22_WIDTH                           = 1;

localparam NTR_SINK_TRRAMCONTROL_TRRAMEMPTY_MASK                        = 32'h8;
localparam NTR_SINK_TRRAMCONTROL_TRRAMEMPTY_SHIFT                       = 3;
localparam NTR_SINK_TRRAMCONTROL_TRRAMEMPTY_LOW                         = 3;
localparam NTR_SINK_TRRAMCONTROL_TRRAMEMPTY_HIGH                        = 3;
localparam NTR_SINK_TRRAMCONTROL_TRRAMEMPTY_WIDTH                       = 1;

localparam NTR_SINK_TRRAMCONTROL_TRRAMMODE_MASK                         = 32'h10;
localparam NTR_SINK_TRRAMCONTROL_TRRAMMODE_SHIFT                        = 4;
localparam NTR_SINK_TRRAMCONTROL_TRRAMMODE_LOW                          = 4;
localparam NTR_SINK_TRRAMCONTROL_TRRAMMODE_HIGH                         = 4;
localparam NTR_SINK_TRRAMCONTROL_TRRAMMODE_WIDTH                        = 1;

localparam NTR_SINK_TRRAMCONTROL_RSVD75_MASK                            = 32'hE0;
localparam NTR_SINK_TRRAMCONTROL_RSVD75_SHIFT                           = 5;
localparam NTR_SINK_TRRAMCONTROL_RSVD75_LOW                             = 5;
localparam NTR_SINK_TRRAMCONTROL_RSVD75_HIGH                            = 7;
localparam NTR_SINK_TRRAMCONTROL_RSVD75_WIDTH                           = 3;

localparam NTR_SINK_TRRAMCONTROL_TRRAMSTOPONWRAP_MASK                   = 32'h100;
localparam NTR_SINK_TRRAMCONTROL_TRRAMSTOPONWRAP_SHIFT                  = 8;
localparam NTR_SINK_TRRAMCONTROL_TRRAMSTOPONWRAP_LOW                    = 8;
localparam NTR_SINK_TRRAMCONTROL_TRRAMSTOPONWRAP_HIGH                   = 8;
localparam NTR_SINK_TRRAMCONTROL_TRRAMSTOPONWRAP_WIDTH                  = 1;

localparam NTR_SINK_TRRAMCONTROL_RSVD319_MASK                           = 32'hFFFFFE00;
localparam NTR_SINK_TRRAMCONTROL_RSVD319_SHIFT                          = 9;
localparam NTR_SINK_TRRAMCONTROL_RSVD319_LOW                            = 9;
localparam NTR_SINK_TRRAMCONTROL_RSVD319_HIGH                           = 31;
localparam NTR_SINK_TRRAMCONTROL_RSVD319_WIDTH                          = 23;

localparam NTR_SINK_TRRAMIMPL_TRRAMVERMAJOR_MASK                        = 32'hF;
localparam NTR_SINK_TRRAMIMPL_TRRAMVERMAJOR_SHIFT                       = 0;
localparam NTR_SINK_TRRAMIMPL_TRRAMVERMAJOR_LOW                         = 0;
localparam NTR_SINK_TRRAMIMPL_TRRAMVERMAJOR_HIGH                        = 3;
localparam NTR_SINK_TRRAMIMPL_TRRAMVERMAJOR_WIDTH                       = 4;

localparam NTR_SINK_TRRAMIMPL_TRRAMVERMINOR_MASK                        = 32'hF0;
localparam NTR_SINK_TRRAMIMPL_TRRAMVERMINOR_SHIFT                       = 4;
localparam NTR_SINK_TRRAMIMPL_TRRAMVERMINOR_LOW                         = 4;
localparam NTR_SINK_TRRAMIMPL_TRRAMVERMINOR_HIGH                        = 7;
localparam NTR_SINK_TRRAMIMPL_TRRAMVERMINOR_WIDTH                       = 4;

localparam NTR_SINK_TRRAMIMPL_TRRAMCOMPTYPE_MASK                        = 32'hF00;
localparam NTR_SINK_TRRAMIMPL_TRRAMCOMPTYPE_SHIFT                       = 8;
localparam NTR_SINK_TRRAMIMPL_TRRAMCOMPTYPE_LOW                         = 8;
localparam NTR_SINK_TRRAMIMPL_TRRAMCOMPTYPE_HIGH                        = 11;
localparam NTR_SINK_TRRAMIMPL_TRRAMCOMPTYPE_WIDTH                       = 4;

localparam NTR_SINK_TRRAMIMPL_TRRAMHASSRAM_MASK                         = 32'h1000;
localparam NTR_SINK_TRRAMIMPL_TRRAMHASSRAM_SHIFT                        = 12;
localparam NTR_SINK_TRRAMIMPL_TRRAMHASSRAM_LOW                          = 12;
localparam NTR_SINK_TRRAMIMPL_TRRAMHASSRAM_HIGH                         = 12;
localparam NTR_SINK_TRRAMIMPL_TRRAMHASSRAM_WIDTH                        = 1;

localparam NTR_SINK_TRRAMIMPL_TRRAMHASSMEM_MASK                         = 32'h2000;
localparam NTR_SINK_TRRAMIMPL_TRRAMHASSMEM_SHIFT                        = 13;
localparam NTR_SINK_TRRAMIMPL_TRRAMHASSMEM_LOW                          = 13;
localparam NTR_SINK_TRRAMIMPL_TRRAMHASSMEM_HIGH                         = 13;
localparam NTR_SINK_TRRAMIMPL_TRRAMHASSMEM_WIDTH                        = 1;

localparam NTR_SINK_TRRAMIMPL_RSVD2314_MASK                             = 32'hFFC000;
localparam NTR_SINK_TRRAMIMPL_RSVD2314_SHIFT                            = 14;
localparam NTR_SINK_TRRAMIMPL_RSVD2314_LOW                              = 14;
localparam NTR_SINK_TRRAMIMPL_RSVD2314_HIGH                             = 23;
localparam NTR_SINK_TRRAMIMPL_RSVD2314_WIDTH                            = 10;

localparam NTR_SINK_TRRAMIMPL_TRRAMVENDORFRAMELENGTH_MASK               = 32'hF000000;
localparam NTR_SINK_TRRAMIMPL_TRRAMVENDORFRAMELENGTH_SHIFT              = 24;
localparam NTR_SINK_TRRAMIMPL_TRRAMVENDORFRAMELENGTH_LOW                = 24;
localparam NTR_SINK_TRRAMIMPL_TRRAMVENDORFRAMELENGTH_HIGH               = 27;
localparam NTR_SINK_TRRAMIMPL_TRRAMVENDORFRAMELENGTH_WIDTH              = 4;

localparam NTR_SINK_TRRAMIMPL_RSVD3128_MASK                             = 32'hF0000000;
localparam NTR_SINK_TRRAMIMPL_RSVD3128_SHIFT                            = 28;
localparam NTR_SINK_TRRAMIMPL_RSVD3128_LOW                              = 28;
localparam NTR_SINK_TRRAMIMPL_RSVD3128_HIGH                             = 31;
localparam NTR_SINK_TRRAMIMPL_RSVD3128_WIDTH                            = 4;

localparam NTR_SINK_TRRAMSTARTLOW_RSVD10_MASK                           = 32'h3;
localparam NTR_SINK_TRRAMSTARTLOW_RSVD10_SHIFT                          = 0;
localparam NTR_SINK_TRRAMSTARTLOW_RSVD10_LOW                            = 0;
localparam NTR_SINK_TRRAMSTARTLOW_RSVD10_HIGH                           = 1;
localparam NTR_SINK_TRRAMSTARTLOW_RSVD10_WIDTH                          = 2;

localparam NTR_SINK_TRRAMSTARTLOW_TRRAMSTARTLOW_MASK                    = 32'hFFFFFFFC;
localparam NTR_SINK_TRRAMSTARTLOW_TRRAMSTARTLOW_SHIFT                   = 2;
localparam NTR_SINK_TRRAMSTARTLOW_TRRAMSTARTLOW_LOW                     = 2;
localparam NTR_SINK_TRRAMSTARTLOW_TRRAMSTARTLOW_HIGH                    = 31;
localparam NTR_SINK_TRRAMSTARTLOW_TRRAMSTARTLOW_WIDTH                   = 30;

localparam NTR_SINK_TRRAMSTARTHIGH_TRRAMSTARTHIGH_MASK                  = 32'hFFFFFFFF;
localparam NTR_SINK_TRRAMSTARTHIGH_TRRAMSTARTHIGH_SHIFT                 = 0;
localparam NTR_SINK_TRRAMSTARTHIGH_TRRAMSTARTHIGH_LOW                   = 0;
localparam NTR_SINK_TRRAMSTARTHIGH_TRRAMSTARTHIGH_HIGH                  = 31;
localparam NTR_SINK_TRRAMSTARTHIGH_TRRAMSTARTHIGH_WIDTH                 = 32;

localparam NTR_SINK_TRRAMLIMITLOW_RSVD10_MASK                           = 32'h3;
localparam NTR_SINK_TRRAMLIMITLOW_RSVD10_SHIFT                          = 0;
localparam NTR_SINK_TRRAMLIMITLOW_RSVD10_LOW                            = 0;
localparam NTR_SINK_TRRAMLIMITLOW_RSVD10_HIGH                           = 1;
localparam NTR_SINK_TRRAMLIMITLOW_RSVD10_WIDTH                          = 2;

localparam NTR_SINK_TRRAMLIMITLOW_TRRAMLIMITLOW_MASK                    = 32'hFFFFFFFC;
localparam NTR_SINK_TRRAMLIMITLOW_TRRAMLIMITLOW_SHIFT                   = 2;
localparam NTR_SINK_TRRAMLIMITLOW_TRRAMLIMITLOW_LOW                     = 2;
localparam NTR_SINK_TRRAMLIMITLOW_TRRAMLIMITLOW_HIGH                    = 31;
localparam NTR_SINK_TRRAMLIMITLOW_TRRAMLIMITLOW_WIDTH                   = 30;

localparam NTR_SINK_TRRAMLIMITHIGH_TRRAMLIMITHIGH_MASK                  = 32'hFFFFFFFF;
localparam NTR_SINK_TRRAMLIMITHIGH_TRRAMLIMITHIGH_SHIFT                 = 0;
localparam NTR_SINK_TRRAMLIMITHIGH_TRRAMLIMITHIGH_LOW                   = 0;
localparam NTR_SINK_TRRAMLIMITHIGH_TRRAMLIMITHIGH_HIGH                  = 31;
localparam NTR_SINK_TRRAMLIMITHIGH_TRRAMLIMITHIGH_WIDTH                 = 32;

localparam NTR_SINK_TRRAMWPLOW_TRRAMWRAP_MASK                           = 32'h1;
localparam NTR_SINK_TRRAMWPLOW_TRRAMWRAP_SHIFT                          = 0;
localparam NTR_SINK_TRRAMWPLOW_TRRAMWRAP_LOW                            = 0;
localparam NTR_SINK_TRRAMWPLOW_TRRAMWRAP_HIGH                           = 0;
localparam NTR_SINK_TRRAMWPLOW_TRRAMWRAP_WIDTH                          = 1;

localparam NTR_SINK_TRRAMWPLOW_RSVD11_MASK                              = 32'h2;
localparam NTR_SINK_TRRAMWPLOW_RSVD11_SHIFT                             = 1;
localparam NTR_SINK_TRRAMWPLOW_RSVD11_LOW                               = 1;
localparam NTR_SINK_TRRAMWPLOW_RSVD11_HIGH                              = 1;
localparam NTR_SINK_TRRAMWPLOW_RSVD11_WIDTH                             = 1;

localparam NTR_SINK_TRRAMWPLOW_TRRAMWPLOW_MASK                          = 32'hFFFFFFFC;
localparam NTR_SINK_TRRAMWPLOW_TRRAMWPLOW_SHIFT                         = 2;
localparam NTR_SINK_TRRAMWPLOW_TRRAMWPLOW_LOW                           = 2;
localparam NTR_SINK_TRRAMWPLOW_TRRAMWPLOW_HIGH                          = 31;
localparam NTR_SINK_TRRAMWPLOW_TRRAMWPLOW_WIDTH                         = 30;

localparam NTR_SINK_TRRAMWPHIGH_TRRAMWPHIGH_MASK                        = 32'hFFFFFFFF;
localparam NTR_SINK_TRRAMWPHIGH_TRRAMWPHIGH_SHIFT                       = 0;
localparam NTR_SINK_TRRAMWPHIGH_TRRAMWPHIGH_LOW                         = 0;
localparam NTR_SINK_TRRAMWPHIGH_TRRAMWPHIGH_HIGH                        = 31;
localparam NTR_SINK_TRRAMWPHIGH_TRRAMWPHIGH_WIDTH                       = 32;

localparam NTR_SINK_TRRAMRPLOW_RSVD10_MASK                              = 32'h3;
localparam NTR_SINK_TRRAMRPLOW_RSVD10_SHIFT                             = 0;
localparam NTR_SINK_TRRAMRPLOW_RSVD10_LOW                               = 0;
localparam NTR_SINK_TRRAMRPLOW_RSVD10_HIGH                              = 1;
localparam NTR_SINK_TRRAMRPLOW_RSVD10_WIDTH                             = 2;

localparam NTR_SINK_TRRAMRPLOW_TRRAMRPLOW_MASK                          = 32'hFFFFFFFC;
localparam NTR_SINK_TRRAMRPLOW_TRRAMRPLOW_SHIFT                         = 2;
localparam NTR_SINK_TRRAMRPLOW_TRRAMRPLOW_LOW                           = 2;
localparam NTR_SINK_TRRAMRPLOW_TRRAMRPLOW_HIGH                          = 31;
localparam NTR_SINK_TRRAMRPLOW_TRRAMRPLOW_WIDTH                         = 30;

localparam NTR_SINK_TRRAMRPHIGH_TRRAMRPHIGH_MASK                        = 32'hFFFFFFFF;
localparam NTR_SINK_TRRAMRPHIGH_TRRAMRPHIGH_SHIFT                       = 0;
localparam NTR_SINK_TRRAMRPHIGH_TRRAMRPHIGH_LOW                         = 0;
localparam NTR_SINK_TRRAMRPHIGH_TRRAMRPHIGH_HIGH                        = 31;
localparam NTR_SINK_TRRAMRPHIGH_TRRAMRPHIGH_WIDTH                       = 32;

localparam NTR_SINK_TRRAMDATA_TRRAMDATA_MASK                            = 32'hFFFFFFFF;
localparam NTR_SINK_TRRAMDATA_TRRAMDATA_SHIFT                           = 0;
localparam NTR_SINK_TRRAMDATA_TRRAMDATA_LOW                             = 0;
localparam NTR_SINK_TRRAMDATA_TRRAMDATA_HIGH                            = 31;
localparam NTR_SINK_TRRAMDATA_TRRAMDATA_WIDTH                           = 32;

localparam NTR_SINK_TRCUSTOMRAMSMEMLIMITLOW_RSVD10_MASK                 = 32'h3;
localparam NTR_SINK_TRCUSTOMRAMSMEMLIMITLOW_RSVD10_SHIFT                = 0;
localparam NTR_SINK_TRCUSTOMRAMSMEMLIMITLOW_RSVD10_LOW                  = 0;
localparam NTR_SINK_TRCUSTOMRAMSMEMLIMITLOW_RSVD10_HIGH                 = 1;
localparam NTR_SINK_TRCUSTOMRAMSMEMLIMITLOW_RSVD10_WIDTH                = 2;

localparam NTR_SINK_TRCUSTOMRAMSMEMLIMITLOW_TRCUSTOMRAMSMEMLIMITLOW_MASK   = 32'hFFFFFFFC;
localparam NTR_SINK_TRCUSTOMRAMSMEMLIMITLOW_TRCUSTOMRAMSMEMLIMITLOW_SHIFT   = 2;
localparam NTR_SINK_TRCUSTOMRAMSMEMLIMITLOW_TRCUSTOMRAMSMEMLIMITLOW_LOW   = 2;
localparam NTR_SINK_TRCUSTOMRAMSMEMLIMITLOW_TRCUSTOMRAMSMEMLIMITLOW_HIGH   = 31;
localparam NTR_SINK_TRCUSTOMRAMSMEMLIMITLOW_TRCUSTOMRAMSMEMLIMITLOW_WIDTH   = 30;

localparam NTR_SINK_SCRATCHLO_DATA_MASK                                 = 32'hFFFFFFFF;
localparam NTR_SINK_SCRATCHLO_DATA_SHIFT                                = 0;
localparam NTR_SINK_SCRATCHLO_DATA_LOW                                  = 0;
localparam NTR_SINK_SCRATCHLO_DATA_HIGH                                 = 31;
localparam NTR_SINK_SCRATCHLO_DATA_WIDTH                                = 32;

localparam NTR_SINK_SCRATCHHI_DATA_MASK                                 = 32'hFFFFFFFF;
localparam NTR_SINK_SCRATCHHI_DATA_SHIFT                                = 0;
localparam NTR_SINK_SCRATCHHI_DATA_LOW                                  = 0;
localparam NTR_SINK_SCRATCHHI_DATA_HIGH                                 = 31;
localparam NTR_SINK_SCRATCHHI_DATA_WIDTH                                = 32;

localparam NTR_SINK_NUM_REGISTERS                                       = 14;

typedef struct packed {
  logic               NtrSinkMmrTrramcontrolHit;
  logic               NtrSinkMmrTrramimplHit;
  logic               NtrSinkMmrTrramstartlowHit;
  logic               NtrSinkMmrTrramstarthighHit;
  logic               NtrSinkMmrTrramlimitlowHit;
  logic               NtrSinkMmrTrramlimithighHit;
  logic               NtrSinkMmrTrramwplowHit;
  logic               NtrSinkMmrTrramwphighHit;
  logic               NtrSinkMmrTrramrplowHit;
  logic               NtrSinkMmrTrramrphighHit;
  logic               NtrSinkMmrTrramdataHit;
  logic               NtrSinkMmrTrcustomramsmemlimitlowHit;
  logic               NtrSinkMmrScratchloHit;
  logic               NtrSinkMmrScratchhiHit;
} NtrSinkMmrHit_s;

typedef struct packed {
    logic   [22:0]        Rsvd319 ;
    logic    [0:0]        Trramstoponwrap ;
    logic    [2:0]        Rsvd75 ;
    logic    [0:0]        Trrammode ;
    logic    [0:0]        Trramempty ;
    logic    [0:0]        Rsvd22 ;
    logic    [0:0]        Trramenable ;
    logic    [0:0]        Trramactive ;
} NtrSinkTrramcontrolMmr_s;

typedef struct packed {
    logic    [3:0]        Rsvd3128 ;
    logic    [3:0]        Trramvendorframelength ;
    logic    [9:0]        Rsvd2314 ;
    logic    [0:0]        Trramhassmem ;
    logic    [0:0]        Trramhassram ;
    logic    [3:0]        Trramcomptype ;
    logic    [3:0]        Trramverminor ;
    logic    [3:0]        Trramvermajor ;
} NtrSinkTrramimplMmr_s;

typedef struct packed {
    logic   [29:0]        Trramstartlow ;
    logic    [1:0]        Rsvd10 ;
} NtrSinkTrramstartlowMmr_s;

typedef struct packed {
    logic   [31:0]        Trramstarthigh ;
} NtrSinkTrramstarthighMmr_s;

typedef struct packed {
    logic   [29:0]        Trramlimitlow ;
    logic    [1:0]        Rsvd10 ;
} NtrSinkTrramlimitlowMmr_s;

typedef struct packed {
    logic   [31:0]        Trramlimithigh ;
} NtrSinkTrramlimithighMmr_s;

typedef struct packed {
    logic   [29:0]        Trramwplow ;
    logic    [0:0]        Rsvd11 ;
    logic    [0:0]        Trramwrap ;
} NtrSinkTrramwplowMmr_s;

typedef struct packed {
    logic   [31:0]        Trramwphigh ;
} NtrSinkTrramwphighMmr_s;

typedef struct packed {
    logic   [29:0]        Trramrplow ;
    logic    [1:0]        Rsvd10 ;
} NtrSinkTrramrplowMmr_s;

typedef struct packed {
    logic   [31:0]        Trramrphigh ;
} NtrSinkTrramrphighMmr_s;

typedef struct packed {
    logic   [31:0]        Trramdata ;
} NtrSinkTrramdataMmr_s;

typedef struct packed {
    logic   [29:0]        Trcustomramsmemlimitlow ;
    logic    [1:0]        Rsvd10 ;
} NtrSinkTrcustomramsmemlimitlowMmr_s;

typedef struct packed {
    logic   [31:0]        Data ;
} NtrSinkScratchloMmr_s;

typedef struct packed {
    logic   [31:0]        Data ;
} NtrSinkScratchhiMmr_s;

typedef struct packed {
    logic   [22:0]        Rsvd319 ;
    logic    [0:0]        Trramstoponwrap ;
    logic    [2:0]        Rsvd75 ;
    logic    [0:0]        Trrammode ;
    logic    [0:0]        Trramempty ;
    logic    [0:0]        Rsvd22 ;
    logic    [0:0]        Trramenable ;
    logic    [0:0]        Trramactive ;
} NtrSinkTrramcontrolMmrUnpack_s;

typedef struct packed {
    logic    [3:0]        Rsvd3128 ;
    logic    [3:0]        Trramvendorframelength ;
    logic    [9:0]        Rsvd2314 ;
    logic    [0:0]        Trramhassmem ;
    logic    [0:0]        Trramhassram ;
    logic    [3:0]        Trramcomptype ;
    logic    [3:0]        Trramverminor ;
    logic    [3:0]        Trramvermajor ;
} NtrSinkTrramimplMmrUnpack_s;

typedef struct packed {
    logic   [29:0]        Trramstartlow ;
    logic    [1:0]        Rsvd10 ;
} NtrSinkTrramstartlowMmrUnpack_s;

typedef struct packed {
    logic   [31:0]        Trramstarthigh ;
} NtrSinkTrramstarthighMmrUnpack_s;

typedef struct packed {
    logic   [29:0]        Trramlimitlow ;
    logic    [1:0]        Rsvd10 ;
} NtrSinkTrramlimitlowMmrUnpack_s;

typedef struct packed {
    logic   [31:0]        Trramlimithigh ;
} NtrSinkTrramlimithighMmrUnpack_s;

typedef struct packed {
    logic   [29:0]        Trramwplow ;
    logic    [0:0]        Rsvd11 ;
    logic    [0:0]        Trramwrap ;
} NtrSinkTrramwplowMmrUnpack_s;

typedef struct packed {
    logic   [31:0]        Trramwphigh ;
} NtrSinkTrramwphighMmrUnpack_s;

typedef struct packed {
    logic   [29:0]        Trramrplow ;
    logic    [1:0]        Rsvd10 ;
} NtrSinkTrramrplowMmrUnpack_s;

typedef struct packed {
    logic   [31:0]        Trramrphigh ;
} NtrSinkTrramrphighMmrUnpack_s;

typedef struct packed {
    logic   [31:0]        Trramdata ;
} NtrSinkTrramdataMmrUnpack_s;

typedef struct packed {
    logic   [29:0]        Trcustomramsmemlimitlow ;
    logic    [1:0]        Rsvd10 ;
} NtrSinkTrcustomramsmemlimitlowMmrUnpack_s;

typedef struct packed {
    logic   [31:0]        Data ;
} NtrSinkScratchloMmrUnpack_s;

typedef struct packed {
    logic   [31:0]        Data ;
} NtrSinkScratchhiMmrUnpack_s;

typedef struct packed {
    NtrSinkTrramcontrolMmr_s Data;
    logic                 Rsvd319WrEn ;
    logic                 TrramstoponwrapWrEn ;
    logic                 Rsvd75WrEn ;
    logic                 TrrammodeWrEn ;
    logic                 TrramemptyWrEn ;
    logic                 Rsvd22WrEn ;
    logic                 TrramenableWrEn ;
    logic                 TrramactiveWrEn ;
} NtrSinkTrramcontrolMmrWr_s;

typedef struct packed {
    NtrSinkTrramstartlowMmr_s Data;
    logic                 TrramstartlowWrEn ;
} NtrSinkTrramstartlowMmrWr_s;

typedef struct packed {
    NtrSinkTrramstarthighMmr_s Data;
    logic                 TrramstarthighWrEn ;
} NtrSinkTrramstarthighMmrWr_s;

typedef struct packed {
    NtrSinkTrramlimitlowMmr_s Data;
    logic                 TrramlimitlowWrEn ;
} NtrSinkTrramlimitlowMmrWr_s;

typedef struct packed {
    NtrSinkTrramlimithighMmr_s Data;
    logic                 TrramlimithighWrEn ;
} NtrSinkTrramlimithighMmrWr_s;

typedef struct packed {
    NtrSinkTrramwplowMmr_s Data;
    logic                 TrramwplowWrEn ;
    logic                 Rsvd11WrEn ;
    logic                 TrramwrapWrEn ;
} NtrSinkTrramwplowMmrWr_s;

typedef struct packed {
    NtrSinkTrramwphighMmr_s Data;
    logic                 TrramwphighWrEn ;
} NtrSinkTrramwphighMmrWr_s;

typedef struct packed {
    NtrSinkTrramrplowMmr_s Data;
    logic                 TrramrplowWrEn ;
} NtrSinkTrramrplowMmrWr_s;

typedef struct packed {
    NtrSinkTrramrphighMmr_s Data;
    logic                 TrramrphighWrEn ;
} NtrSinkTrramrphighMmrWr_s;

typedef struct packed {
    NtrSinkTrramdataMmr_s Data;
    logic                 TrramdataWrEn ;
} NtrSinkTrramdataMmrWr_s;

typedef struct packed {
    NtrSinkTrramcontrolMmr_s Trramcontrol;
    NtrSinkTrramimplMmr_s Trramimpl;
    NtrSinkTrramstartlowMmr_s Trramstartlow;
    NtrSinkTrramstarthighMmr_s Trramstarthigh;
    NtrSinkTrramlimitlowMmr_s Trramlimitlow;
    NtrSinkTrramlimithighMmr_s Trramlimithigh;
    NtrSinkTrramwplowMmr_s Trramwplow;
    NtrSinkTrramwphighMmr_s Trramwphigh;
    NtrSinkTrramrplowMmr_s Trramrplow;
    NtrSinkTrramrphighMmr_s Trramrphigh;
    NtrSinkTrramdataMmr_s Trramdata;
    NtrSinkTrcustomramsmemlimitlowMmr_s Trcustomramsmemlimitlow;
    NtrSinkScratchloMmr_s Scratchlo;
    NtrSinkScratchhiMmr_s Scratchhi;
} NtrSinkMmrs_s;

typedef struct packed {
    NtrSinkTrramcontrolMmrWr_s TrramcontrolWr;
    NtrSinkTrramstartlowMmrWr_s TrramstartlowWr;
    NtrSinkTrramstarthighMmrWr_s TrramstarthighWr;
    NtrSinkTrramlimitlowMmrWr_s TrramlimitlowWr;
    NtrSinkTrramlimithighMmrWr_s TrramlimithighWr;
    NtrSinkTrramwplowMmrWr_s TrramwplowWr;
    NtrSinkTrramwphighMmrWr_s TrramwphighWr;
    NtrSinkTrramrplowMmrWr_s TrramrplowWr;
    NtrSinkTrramrphighMmrWr_s TrramrphighWr;
    NtrSinkTrramdataMmrWr_s TrramdataWr;
} NtrSinkMmrsWr_s;

function automatic NtrSinkTrramcontrolMmrUnpack_s unpack_NtrSinkTrramcontrolMmr;
input NtrSinkTrramcontrolMmr_s packed_mmr;
begin
    unpack_NtrSinkTrramcontrolMmr = '0;
    unpack_NtrSinkTrramcontrolMmr.Trramactive = packed_mmr.Trramactive;
    unpack_NtrSinkTrramcontrolMmr.Trramenable = packed_mmr.Trramenable;
    unpack_NtrSinkTrramcontrolMmr.Rsvd22 = packed_mmr.Rsvd22;
    unpack_NtrSinkTrramcontrolMmr.Trramempty = packed_mmr.Trramempty;
    unpack_NtrSinkTrramcontrolMmr.Trrammode = packed_mmr.Trrammode;
    unpack_NtrSinkTrramcontrolMmr.Rsvd75 = packed_mmr.Rsvd75;
    unpack_NtrSinkTrramcontrolMmr.Trramstoponwrap = packed_mmr.Trramstoponwrap;
    unpack_NtrSinkTrramcontrolMmr.Rsvd319 = packed_mmr.Rsvd319;
end
endfunction

function automatic NtrSinkTrramimplMmrUnpack_s unpack_NtrSinkTrramimplMmr;
input NtrSinkTrramimplMmr_s packed_mmr;
begin
    unpack_NtrSinkTrramimplMmr = '0;
    unpack_NtrSinkTrramimplMmr.Trramvermajor = packed_mmr.Trramvermajor;
    unpack_NtrSinkTrramimplMmr.Trramverminor = packed_mmr.Trramverminor;
    unpack_NtrSinkTrramimplMmr.Trramcomptype = packed_mmr.Trramcomptype;
    unpack_NtrSinkTrramimplMmr.Trramhassram = packed_mmr.Trramhassram;
    unpack_NtrSinkTrramimplMmr.Trramhassmem = packed_mmr.Trramhassmem;
    unpack_NtrSinkTrramimplMmr.Rsvd2314 = packed_mmr.Rsvd2314;
    unpack_NtrSinkTrramimplMmr.Trramvendorframelength = packed_mmr.Trramvendorframelength;
    unpack_NtrSinkTrramimplMmr.Rsvd3128 = packed_mmr.Rsvd3128;
end
endfunction

function automatic NtrSinkTrramstartlowMmrUnpack_s unpack_NtrSinkTrramstartlowMmr;
input NtrSinkTrramstartlowMmr_s packed_mmr;
begin
    unpack_NtrSinkTrramstartlowMmr = '0;
    unpack_NtrSinkTrramstartlowMmr.Rsvd10 = packed_mmr.Rsvd10;
    unpack_NtrSinkTrramstartlowMmr.Trramstartlow = packed_mmr.Trramstartlow;
end
endfunction

function automatic NtrSinkTrramstarthighMmrUnpack_s unpack_NtrSinkTrramstarthighMmr;
input NtrSinkTrramstarthighMmr_s packed_mmr;
begin
    unpack_NtrSinkTrramstarthighMmr = '0;
    unpack_NtrSinkTrramstarthighMmr.Trramstarthigh = packed_mmr.Trramstarthigh;
end
endfunction

function automatic NtrSinkTrramlimitlowMmrUnpack_s unpack_NtrSinkTrramlimitlowMmr;
input NtrSinkTrramlimitlowMmr_s packed_mmr;
begin
    unpack_NtrSinkTrramlimitlowMmr = '0;
    unpack_NtrSinkTrramlimitlowMmr.Rsvd10 = packed_mmr.Rsvd10;
    unpack_NtrSinkTrramlimitlowMmr.Trramlimitlow = packed_mmr.Trramlimitlow;
end
endfunction

function automatic NtrSinkTrramlimithighMmrUnpack_s unpack_NtrSinkTrramlimithighMmr;
input NtrSinkTrramlimithighMmr_s packed_mmr;
begin
    unpack_NtrSinkTrramlimithighMmr = '0;
    unpack_NtrSinkTrramlimithighMmr.Trramlimithigh = packed_mmr.Trramlimithigh;
end
endfunction

function automatic NtrSinkTrramwplowMmrUnpack_s unpack_NtrSinkTrramwplowMmr;
input NtrSinkTrramwplowMmr_s packed_mmr;
begin
    unpack_NtrSinkTrramwplowMmr = '0;
    unpack_NtrSinkTrramwplowMmr.Trramwrap = packed_mmr.Trramwrap;
    unpack_NtrSinkTrramwplowMmr.Rsvd11 = packed_mmr.Rsvd11;
    unpack_NtrSinkTrramwplowMmr.Trramwplow = packed_mmr.Trramwplow;
end
endfunction

function automatic NtrSinkTrramwphighMmrUnpack_s unpack_NtrSinkTrramwphighMmr;
input NtrSinkTrramwphighMmr_s packed_mmr;
begin
    unpack_NtrSinkTrramwphighMmr = '0;
    unpack_NtrSinkTrramwphighMmr.Trramwphigh = packed_mmr.Trramwphigh;
end
endfunction

function automatic NtrSinkTrramrplowMmrUnpack_s unpack_NtrSinkTrramrplowMmr;
input NtrSinkTrramrplowMmr_s packed_mmr;
begin
    unpack_NtrSinkTrramrplowMmr = '0;
    unpack_NtrSinkTrramrplowMmr.Rsvd10 = packed_mmr.Rsvd10;
    unpack_NtrSinkTrramrplowMmr.Trramrplow = packed_mmr.Trramrplow;
end
endfunction

function automatic NtrSinkTrramrphighMmrUnpack_s unpack_NtrSinkTrramrphighMmr;
input NtrSinkTrramrphighMmr_s packed_mmr;
begin
    unpack_NtrSinkTrramrphighMmr = '0;
    unpack_NtrSinkTrramrphighMmr.Trramrphigh = packed_mmr.Trramrphigh;
end
endfunction

function automatic NtrSinkTrramdataMmrUnpack_s unpack_NtrSinkTrramdataMmr;
input NtrSinkTrramdataMmr_s packed_mmr;
begin
    unpack_NtrSinkTrramdataMmr = '0;
    unpack_NtrSinkTrramdataMmr.Trramdata = packed_mmr.Trramdata;
end
endfunction

function automatic NtrSinkTrcustomramsmemlimitlowMmrUnpack_s unpack_NtrSinkTrcustomramsmemlimitlowMmr;
input NtrSinkTrcustomramsmemlimitlowMmr_s packed_mmr;
begin
    unpack_NtrSinkTrcustomramsmemlimitlowMmr = '0;
    unpack_NtrSinkTrcustomramsmemlimitlowMmr.Rsvd10 = packed_mmr.Rsvd10;
    unpack_NtrSinkTrcustomramsmemlimitlowMmr.Trcustomramsmemlimitlow = packed_mmr.Trcustomramsmemlimitlow;
end
endfunction

function automatic NtrSinkScratchloMmrUnpack_s unpack_NtrSinkScratchloMmr;
input NtrSinkScratchloMmr_s packed_mmr;
begin
    unpack_NtrSinkScratchloMmr = '0;
    unpack_NtrSinkScratchloMmr.Data = packed_mmr.Data;
end
endfunction

function automatic NtrSinkScratchhiMmrUnpack_s unpack_NtrSinkScratchhiMmr;
input NtrSinkScratchhiMmr_s packed_mmr;
begin
    unpack_NtrSinkScratchhiMmr = '0;
    unpack_NtrSinkScratchhiMmr.Data = packed_mmr.Data;
end
endfunction

function automatic NtrSinkTrramcontrolMmr_s pack_NtrSinkTrramcontrolMmr;
input NtrSinkTrramcontrolMmrUnpack_s unpacked_mmr;
begin
    pack_NtrSinkTrramcontrolMmr.Trramactive = unpacked_mmr.Trramactive;
    pack_NtrSinkTrramcontrolMmr.Trramenable = unpacked_mmr.Trramenable;
    pack_NtrSinkTrramcontrolMmr.Rsvd22 = unpacked_mmr.Rsvd22;
    pack_NtrSinkTrramcontrolMmr.Trramempty = unpacked_mmr.Trramempty;
    pack_NtrSinkTrramcontrolMmr.Trrammode = unpacked_mmr.Trrammode;
    pack_NtrSinkTrramcontrolMmr.Rsvd75 = unpacked_mmr.Rsvd75;
    pack_NtrSinkTrramcontrolMmr.Trramstoponwrap = unpacked_mmr.Trramstoponwrap;
    pack_NtrSinkTrramcontrolMmr.Rsvd319 = unpacked_mmr.Rsvd319;
end
endfunction

function automatic NtrSinkTrramimplMmr_s pack_NtrSinkTrramimplMmr;
input NtrSinkTrramimplMmrUnpack_s unpacked_mmr;
begin
    pack_NtrSinkTrramimplMmr.Trramvermajor = unpacked_mmr.Trramvermajor;
    pack_NtrSinkTrramimplMmr.Trramverminor = unpacked_mmr.Trramverminor;
    pack_NtrSinkTrramimplMmr.Trramcomptype = unpacked_mmr.Trramcomptype;
    pack_NtrSinkTrramimplMmr.Trramhassram = unpacked_mmr.Trramhassram;
    pack_NtrSinkTrramimplMmr.Trramhassmem = unpacked_mmr.Trramhassmem;
    pack_NtrSinkTrramimplMmr.Rsvd2314 = unpacked_mmr.Rsvd2314;
    pack_NtrSinkTrramimplMmr.Trramvendorframelength = unpacked_mmr.Trramvendorframelength;
    pack_NtrSinkTrramimplMmr.Rsvd3128 = unpacked_mmr.Rsvd3128;
end
endfunction

function automatic NtrSinkTrramstartlowMmr_s pack_NtrSinkTrramstartlowMmr;
input NtrSinkTrramstartlowMmrUnpack_s unpacked_mmr;
begin
    pack_NtrSinkTrramstartlowMmr.Rsvd10 = unpacked_mmr.Rsvd10;
    pack_NtrSinkTrramstartlowMmr.Trramstartlow = unpacked_mmr.Trramstartlow;
end
endfunction

function automatic NtrSinkTrramstarthighMmr_s pack_NtrSinkTrramstarthighMmr;
input NtrSinkTrramstarthighMmrUnpack_s unpacked_mmr;
begin
    pack_NtrSinkTrramstarthighMmr.Trramstarthigh = unpacked_mmr.Trramstarthigh;
end
endfunction

function automatic NtrSinkTrramlimitlowMmr_s pack_NtrSinkTrramlimitlowMmr;
input NtrSinkTrramlimitlowMmrUnpack_s unpacked_mmr;
begin
    pack_NtrSinkTrramlimitlowMmr.Rsvd10 = unpacked_mmr.Rsvd10;
    pack_NtrSinkTrramlimitlowMmr.Trramlimitlow = unpacked_mmr.Trramlimitlow;
end
endfunction

function automatic NtrSinkTrramlimithighMmr_s pack_NtrSinkTrramlimithighMmr;
input NtrSinkTrramlimithighMmrUnpack_s unpacked_mmr;
begin
    pack_NtrSinkTrramlimithighMmr.Trramlimithigh = unpacked_mmr.Trramlimithigh;
end
endfunction

function automatic NtrSinkTrramwplowMmr_s pack_NtrSinkTrramwplowMmr;
input NtrSinkTrramwplowMmrUnpack_s unpacked_mmr;
begin
    pack_NtrSinkTrramwplowMmr.Trramwrap = unpacked_mmr.Trramwrap;
    pack_NtrSinkTrramwplowMmr.Rsvd11 = unpacked_mmr.Rsvd11;
    pack_NtrSinkTrramwplowMmr.Trramwplow = unpacked_mmr.Trramwplow;
end
endfunction

function automatic NtrSinkTrramwphighMmr_s pack_NtrSinkTrramwphighMmr;
input NtrSinkTrramwphighMmrUnpack_s unpacked_mmr;
begin
    pack_NtrSinkTrramwphighMmr.Trramwphigh = unpacked_mmr.Trramwphigh;
end
endfunction

function automatic NtrSinkTrramrplowMmr_s pack_NtrSinkTrramrplowMmr;
input NtrSinkTrramrplowMmrUnpack_s unpacked_mmr;
begin
    pack_NtrSinkTrramrplowMmr.Rsvd10 = unpacked_mmr.Rsvd10;
    pack_NtrSinkTrramrplowMmr.Trramrplow = unpacked_mmr.Trramrplow;
end
endfunction

function automatic NtrSinkTrramrphighMmr_s pack_NtrSinkTrramrphighMmr;
input NtrSinkTrramrphighMmrUnpack_s unpacked_mmr;
begin
    pack_NtrSinkTrramrphighMmr.Trramrphigh = unpacked_mmr.Trramrphigh;
end
endfunction

function automatic NtrSinkTrramdataMmr_s pack_NtrSinkTrramdataMmr;
input NtrSinkTrramdataMmrUnpack_s unpacked_mmr;
begin
    pack_NtrSinkTrramdataMmr.Trramdata = unpacked_mmr.Trramdata;
end
endfunction

function automatic NtrSinkTrcustomramsmemlimitlowMmr_s pack_NtrSinkTrcustomramsmemlimitlowMmr;
input NtrSinkTrcustomramsmemlimitlowMmrUnpack_s unpacked_mmr;
begin
    pack_NtrSinkTrcustomramsmemlimitlowMmr.Rsvd10 = unpacked_mmr.Rsvd10;
    pack_NtrSinkTrcustomramsmemlimitlowMmr.Trcustomramsmemlimitlow = unpacked_mmr.Trcustomramsmemlimitlow;
end
endfunction

function automatic NtrSinkScratchloMmr_s pack_NtrSinkScratchloMmr;
input NtrSinkScratchloMmrUnpack_s unpacked_mmr;
begin
    pack_NtrSinkScratchloMmr.Data = unpacked_mmr.Data;
end
endfunction

function automatic NtrSinkScratchhiMmr_s pack_NtrSinkScratchhiMmr;
input NtrSinkScratchhiMmrUnpack_s unpacked_mmr;
begin
    pack_NtrSinkScratchhiMmr.Data = unpacked_mmr.Data;
end
endfunction

endpackage

`endif
