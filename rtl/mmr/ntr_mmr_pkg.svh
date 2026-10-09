// SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
`ifndef NTR_MMR_PKG_SVH
`define NTR_MMR_PKG_SVH

package ntr_mmr_pkg;

localparam NTR_REG_MAP_BASE_ADDR                                       = 12'h000;

localparam NTR_TRTECONTROL_REG_OFFSET                                  = 12'h000;
localparam NTR_TRTECONTROL_REG_ADDR                                    = 12'h000;
localparam NTR_TRTEIMPL_REG_OFFSET                                     = 12'h004;
localparam NTR_TRTEIMPL_REG_ADDR                                       = 12'h004;
localparam NTR_TRTEINSTFEATURES_REG_OFFSET                             = 12'h008;
localparam NTR_TRTEINSTFEATURES_REG_ADDR                               = 12'h008;
localparam NTR_TRTEINSTFILTERS_REG_OFFSET                              = 12'h00C;
localparam NTR_TRTEINSTFILTERS_REG_ADDR                                = 12'h00C;
localparam NTR_TRTEFILTER0CONTROL_REG_OFFSET                           = 12'h010;
localparam NTR_TRTEFILTER0CONTROL_REG_ADDR                             = 12'h010;
localparam NTR_TRTEFILTER0MATCHINST_REG_OFFSET                         = 12'h014;
localparam NTR_TRTEFILTER0MATCHINST_REG_ADDR                           = 12'h014;
localparam NTR_TRTSCONTROL_REG_OFFSET                                  = 12'h040;
localparam NTR_TRTSCONTROL_REG_ADDR                                    = 12'h040;
localparam NTR_CDBGNTRACEFRAMECFG_REG_OFFSET                           = 12'h1A8;
localparam NTR_CDBGNTRACEFRAMECFG_REG_ADDR                             = 12'h1A8;
localparam NTR_SCRATCHLO_REG_OFFSET                                    = 12'hFF8;
localparam NTR_SCRATCHLO_REG_ADDR                                      = 12'hFF8;
localparam NTR_SCRATCHHI_REG_OFFSET                                    = 12'hFFC;
localparam NTR_SCRATCHHI_REG_ADDR                                      = 12'hFFC;

localparam NTR_TRTECONTROL_TRTEACTIVE_MASK                              = 32'h1;
localparam NTR_TRTECONTROL_TRTEACTIVE_SHIFT                             = 0;
localparam NTR_TRTECONTROL_TRTEACTIVE_LOW                               = 0;
localparam NTR_TRTECONTROL_TRTEACTIVE_HIGH                              = 0;
localparam NTR_TRTECONTROL_TRTEACTIVE_WIDTH                             = 1;

localparam NTR_TRTECONTROL_TRTEENABLE_MASK                              = 32'h2;
localparam NTR_TRTECONTROL_TRTEENABLE_SHIFT                             = 1;
localparam NTR_TRTECONTROL_TRTEENABLE_LOW                               = 1;
localparam NTR_TRTECONTROL_TRTEENABLE_HIGH                              = 1;
localparam NTR_TRTECONTROL_TRTEENABLE_WIDTH                             = 1;

localparam NTR_TRTECONTROL_TRTEINSTTRACING_MASK                         = 32'h4;
localparam NTR_TRTECONTROL_TRTEINSTTRACING_SHIFT                        = 2;
localparam NTR_TRTECONTROL_TRTEINSTTRACING_LOW                          = 2;
localparam NTR_TRTECONTROL_TRTEINSTTRACING_HIGH                         = 2;
localparam NTR_TRTECONTROL_TRTEINSTTRACING_WIDTH                        = 1;

localparam NTR_TRTECONTROL_TRTEEMPTY_MASK                               = 32'h8;
localparam NTR_TRTECONTROL_TRTEEMPTY_SHIFT                              = 3;
localparam NTR_TRTECONTROL_TRTEEMPTY_LOW                                = 3;
localparam NTR_TRTECONTROL_TRTEEMPTY_HIGH                               = 3;
localparam NTR_TRTECONTROL_TRTEEMPTY_WIDTH                              = 1;

localparam NTR_TRTECONTROL_TRTEINSTMODE_MASK                            = 32'h70;
localparam NTR_TRTECONTROL_TRTEINSTMODE_SHIFT                           = 4;
localparam NTR_TRTECONTROL_TRTEINSTMODE_LOW                             = 4;
localparam NTR_TRTECONTROL_TRTEINSTMODE_HIGH                            = 6;
localparam NTR_TRTECONTROL_TRTEINSTMODE_WIDTH                           = 3;

localparam NTR_TRTECONTROL_RSVD87_MASK                                  = 32'h180;
localparam NTR_TRTECONTROL_RSVD87_SHIFT                                 = 7;
localparam NTR_TRTECONTROL_RSVD87_LOW                                   = 7;
localparam NTR_TRTECONTROL_RSVD87_HIGH                                  = 8;
localparam NTR_TRTECONTROL_RSVD87_WIDTH                                 = 2;

localparam NTR_TRTECONTROL_TRTECONTEXT_MASK                             = 32'h200;
localparam NTR_TRTECONTROL_TRTECONTEXT_SHIFT                            = 9;
localparam NTR_TRTECONTROL_TRTECONTEXT_LOW                              = 9;
localparam NTR_TRTECONTROL_TRTECONTEXT_HIGH                             = 9;
localparam NTR_TRTECONTROL_TRTECONTEXT_WIDTH                            = 1;

localparam NTR_TRTECONTROL_RSVD1010_MASK                                = 32'h400;
localparam NTR_TRTECONTROL_RSVD1010_SHIFT                               = 10;
localparam NTR_TRTECONTROL_RSVD1010_LOW                                 = 10;
localparam NTR_TRTECONTROL_RSVD1010_HIGH                                = 10;
localparam NTR_TRTECONTROL_RSVD1010_WIDTH                               = 1;

localparam NTR_TRTECONTROL_TRTEINSTTRIGGERENABLE_MASK                   = 32'h800;
localparam NTR_TRTECONTROL_TRTEINSTTRIGGERENABLE_SHIFT                  = 11;
localparam NTR_TRTECONTROL_TRTEINSTTRIGGERENABLE_LOW                    = 11;
localparam NTR_TRTECONTROL_TRTEINSTTRIGGERENABLE_HIGH                   = 11;
localparam NTR_TRTECONTROL_TRTEINSTTRIGGERENABLE_WIDTH                  = 1;

localparam NTR_TRTECONTROL_TRTEINSTSTALLOROVERFLOW_MASK                 = 32'h1000;
localparam NTR_TRTECONTROL_TRTEINSTSTALLOROVERFLOW_SHIFT                = 12;
localparam NTR_TRTECONTROL_TRTEINSTSTALLOROVERFLOW_LOW                  = 12;
localparam NTR_TRTECONTROL_TRTEINSTSTALLOROVERFLOW_HIGH                 = 12;
localparam NTR_TRTECONTROL_TRTEINSTSTALLOROVERFLOW_WIDTH                = 1;

localparam NTR_TRTECONTROL_TRTEINSTSTALLENA_MASK                        = 32'h2000;
localparam NTR_TRTECONTROL_TRTEINSTSTALLENA_SHIFT                       = 13;
localparam NTR_TRTECONTROL_TRTEINSTSTALLENA_LOW                         = 13;
localparam NTR_TRTECONTROL_TRTEINSTSTALLENA_HIGH                        = 13;
localparam NTR_TRTECONTROL_TRTEINSTSTALLENA_WIDTH                       = 1;

localparam NTR_TRTECONTROL_RSVD1414_MASK                                = 32'h4000;
localparam NTR_TRTECONTROL_RSVD1414_SHIFT                               = 14;
localparam NTR_TRTECONTROL_RSVD1414_LOW                                 = 14;
localparam NTR_TRTECONTROL_RSVD1414_HIGH                                = 14;
localparam NTR_TRTECONTROL_RSVD1414_WIDTH                               = 1;

localparam NTR_TRTECONTROL_TRTEINHIBITSRC_MASK                          = 32'h8000;
localparam NTR_TRTECONTROL_TRTEINHIBITSRC_SHIFT                         = 15;
localparam NTR_TRTECONTROL_TRTEINHIBITSRC_LOW                           = 15;
localparam NTR_TRTECONTROL_TRTEINHIBITSRC_HIGH                          = 15;
localparam NTR_TRTECONTROL_TRTEINHIBITSRC_WIDTH                         = 1;

localparam NTR_TRTECONTROL_TRTESYNCMODE_MASK                            = 32'h30000;
localparam NTR_TRTECONTROL_TRTESYNCMODE_SHIFT                           = 16;
localparam NTR_TRTECONTROL_TRTESYNCMODE_LOW                             = 16;
localparam NTR_TRTECONTROL_TRTESYNCMODE_HIGH                            = 17;
localparam NTR_TRTECONTROL_TRTESYNCMODE_WIDTH                           = 2;

localparam NTR_TRTECONTROL_RSVD1918_MASK                                = 32'hC0000;
localparam NTR_TRTECONTROL_RSVD1918_SHIFT                               = 18;
localparam NTR_TRTECONTROL_RSVD1918_LOW                                 = 18;
localparam NTR_TRTECONTROL_RSVD1918_HIGH                                = 19;
localparam NTR_TRTECONTROL_RSVD1918_WIDTH                               = 2;

localparam NTR_TRTECONTROL_TRTESYNCMAX_MASK                             = 32'hF00000;
localparam NTR_TRTECONTROL_TRTESYNCMAX_SHIFT                            = 20;
localparam NTR_TRTECONTROL_TRTESYNCMAX_LOW                              = 20;
localparam NTR_TRTECONTROL_TRTESYNCMAX_HIGH                             = 23;
localparam NTR_TRTECONTROL_TRTESYNCMAX_WIDTH                            = 4;

localparam NTR_TRTECONTROL_TRTEFORMAT_MASK                              = 32'h7000000;
localparam NTR_TRTECONTROL_TRTEFORMAT_SHIFT                             = 24;
localparam NTR_TRTECONTROL_TRTEFORMAT_LOW                               = 24;
localparam NTR_TRTECONTROL_TRTEFORMAT_HIGH                              = 26;
localparam NTR_TRTECONTROL_TRTEFORMAT_WIDTH                             = 3;

localparam NTR_TRTECONTROL_RSVD3127_MASK                                = 32'hF8000000;
localparam NTR_TRTECONTROL_RSVD3127_SHIFT                               = 27;
localparam NTR_TRTECONTROL_RSVD3127_LOW                                 = 27;
localparam NTR_TRTECONTROL_RSVD3127_HIGH                                = 31;
localparam NTR_TRTECONTROL_RSVD3127_WIDTH                               = 5;

localparam NTR_TRTEIMPL_TRTEVERMAJOR_MASK                               = 32'hF;
localparam NTR_TRTEIMPL_TRTEVERMAJOR_SHIFT                              = 0;
localparam NTR_TRTEIMPL_TRTEVERMAJOR_LOW                                = 0;
localparam NTR_TRTEIMPL_TRTEVERMAJOR_HIGH                               = 3;
localparam NTR_TRTEIMPL_TRTEVERMAJOR_WIDTH                              = 4;

localparam NTR_TRTEIMPL_TRTEVERMINOR_MASK                               = 32'hF0;
localparam NTR_TRTEIMPL_TRTEVERMINOR_SHIFT                              = 4;
localparam NTR_TRTEIMPL_TRTEVERMINOR_LOW                                = 4;
localparam NTR_TRTEIMPL_TRTEVERMINOR_HIGH                               = 7;
localparam NTR_TRTEIMPL_TRTEVERMINOR_WIDTH                              = 4;

localparam NTR_TRTEIMPL_TRTECOMPTYPE_MASK                               = 32'hF00;
localparam NTR_TRTEIMPL_TRTECOMPTYPE_SHIFT                              = 8;
localparam NTR_TRTEIMPL_TRTECOMPTYPE_LOW                                = 8;
localparam NTR_TRTEIMPL_TRTECOMPTYPE_HIGH                               = 11;
localparam NTR_TRTEIMPL_TRTECOMPTYPE_WIDTH                              = 4;

localparam NTR_TRTEIMPL_RSVD1512_MASK                                   = 32'hF000;
localparam NTR_TRTEIMPL_RSVD1512_SHIFT                                  = 12;
localparam NTR_TRTEIMPL_RSVD1512_LOW                                    = 12;
localparam NTR_TRTEIMPL_RSVD1512_HIGH                                   = 15;
localparam NTR_TRTEIMPL_RSVD1512_WIDTH                                  = 4;

localparam NTR_TRTEIMPL_TRTEPROTOCOLMAJOR_MASK                          = 32'hF0000;
localparam NTR_TRTEIMPL_TRTEPROTOCOLMAJOR_SHIFT                         = 16;
localparam NTR_TRTEIMPL_TRTEPROTOCOLMAJOR_LOW                           = 16;
localparam NTR_TRTEIMPL_TRTEPROTOCOLMAJOR_HIGH                          = 19;
localparam NTR_TRTEIMPL_TRTEPROTOCOLMAJOR_WIDTH                         = 4;

localparam NTR_TRTEIMPL_TRTEPROTOCOLMINOR_MASK                          = 32'hF00000;
localparam NTR_TRTEIMPL_TRTEPROTOCOLMINOR_SHIFT                         = 20;
localparam NTR_TRTEIMPL_TRTEPROTOCOLMINOR_LOW                           = 20;
localparam NTR_TRTEIMPL_TRTEPROTOCOLMINOR_HIGH                          = 23;
localparam NTR_TRTEIMPL_TRTEPROTOCOLMINOR_WIDTH                         = 4;

localparam NTR_TRTEIMPL_TRTEVENDORFRAMELENGTH_MASK                      = 32'hF000000;
localparam NTR_TRTEIMPL_TRTEVENDORFRAMELENGTH_SHIFT                     = 24;
localparam NTR_TRTEIMPL_TRTEVENDORFRAMELENGTH_LOW                       = 24;
localparam NTR_TRTEIMPL_TRTEVENDORFRAMELENGTH_HIGH                      = 27;
localparam NTR_TRTEIMPL_TRTEVENDORFRAMELENGTH_WIDTH                     = 4;

localparam NTR_TRTEIMPL_TRTECLATRIGGERENABLE_MASK                       = 32'h10000000;
localparam NTR_TRTEIMPL_TRTECLATRIGGERENABLE_SHIFT                      = 28;
localparam NTR_TRTEIMPL_TRTECLATRIGGERENABLE_LOW                        = 28;
localparam NTR_TRTEIMPL_TRTECLATRIGGERENABLE_HIGH                       = 28;
localparam NTR_TRTEIMPL_TRTECLATRIGGERENABLE_WIDTH                      = 1;

localparam NTR_TRTEIMPL_TRTETRACEPATCHENABLE_MASK                       = 32'h20000000;
localparam NTR_TRTEIMPL_TRTETRACEPATCHENABLE_SHIFT                      = 29;
localparam NTR_TRTEIMPL_TRTETRACEPATCHENABLE_LOW                        = 29;
localparam NTR_TRTEIMPL_TRTETRACEPATCHENABLE_HIGH                       = 29;
localparam NTR_TRTEIMPL_TRTETRACEPATCHENABLE_WIDTH                      = 1;

localparam NTR_TRTEIMPL_RSVD3130_MASK                                   = 32'hC0000000;
localparam NTR_TRTEIMPL_RSVD3130_SHIFT                                  = 30;
localparam NTR_TRTEIMPL_RSVD3130_LOW                                    = 30;
localparam NTR_TRTEIMPL_RSVD3130_HIGH                                   = 31;
localparam NTR_TRTEIMPL_RSVD3130_WIDTH                                  = 2;

localparam NTR_TRTEINSTFEATURES_TRTEINSTNOADDRDIFF_MASK                 = 32'h1;
localparam NTR_TRTEINSTFEATURES_TRTEINSTNOADDRDIFF_SHIFT                = 0;
localparam NTR_TRTEINSTFEATURES_TRTEINSTNOADDRDIFF_LOW                  = 0;
localparam NTR_TRTEINSTFEATURES_TRTEINSTNOADDRDIFF_HIGH                 = 0;
localparam NTR_TRTEINSTFEATURES_TRTEINSTNOADDRDIFF_WIDTH                = 1;

localparam NTR_TRTEINSTFEATURES_TRTEINSTNOTRAPADDR_MASK                 = 32'h2;
localparam NTR_TRTEINSTFEATURES_TRTEINSTNOTRAPADDR_SHIFT                = 1;
localparam NTR_TRTEINSTFEATURES_TRTEINSTNOTRAPADDR_LOW                  = 1;
localparam NTR_TRTEINSTFEATURES_TRTEINSTNOTRAPADDR_HIGH                 = 1;
localparam NTR_TRTEINSTFEATURES_TRTEINSTNOTRAPADDR_WIDTH                = 1;

localparam NTR_TRTEINSTFEATURES_RSVD72_MASK                             = 32'hFC;
localparam NTR_TRTEINSTFEATURES_RSVD72_SHIFT                            = 2;
localparam NTR_TRTEINSTFEATURES_RSVD72_LOW                              = 2;
localparam NTR_TRTEINSTFEATURES_RSVD72_HIGH                             = 7;
localparam NTR_TRTEINSTFEATURES_RSVD72_WIDTH                            = 6;

localparam NTR_TRTEINSTFEATURES_TRTEINSTENREPEATEDHISTORY_MASK          = 32'h100;
localparam NTR_TRTEINSTFEATURES_TRTEINSTENREPEATEDHISTORY_SHIFT         = 8;
localparam NTR_TRTEINSTFEATURES_TRTEINSTENREPEATEDHISTORY_LOW           = 8;
localparam NTR_TRTEINSTFEATURES_TRTEINSTENREPEATEDHISTORY_HIGH          = 8;
localparam NTR_TRTEINSTFEATURES_TRTEINSTENREPEATEDHISTORY_WIDTH         = 1;

localparam NTR_TRTEINSTFEATURES_RSVD159_MASK                            = 32'hFE00;
localparam NTR_TRTEINSTFEATURES_RSVD159_SHIFT                           = 9;
localparam NTR_TRTEINSTFEATURES_RSVD159_LOW                             = 9;
localparam NTR_TRTEINSTFEATURES_RSVD159_HIGH                            = 15;
localparam NTR_TRTEINSTFEATURES_RSVD159_WIDTH                           = 7;

localparam NTR_TRTEINSTFEATURES_TRTESRCID_MASK                          = 32'hFFF0000;
localparam NTR_TRTEINSTFEATURES_TRTESRCID_SHIFT                         = 16;
localparam NTR_TRTEINSTFEATURES_TRTESRCID_LOW                           = 16;
localparam NTR_TRTEINSTFEATURES_TRTESRCID_HIGH                          = 27;
localparam NTR_TRTEINSTFEATURES_TRTESRCID_WIDTH                         = 12;

localparam NTR_TRTEINSTFEATURES_TRTESRCBITS_MASK                        = 32'hF0000000;
localparam NTR_TRTEINSTFEATURES_TRTESRCBITS_SHIFT                       = 28;
localparam NTR_TRTEINSTFEATURES_TRTESRCBITS_LOW                         = 28;
localparam NTR_TRTEINSTFEATURES_TRTESRCBITS_HIGH                        = 31;
localparam NTR_TRTEINSTFEATURES_TRTESRCBITS_WIDTH                       = 4;

localparam NTR_TRTEINSTFILTERS_TRTEINSTFILTERS_MASK                     = 32'hFFFF;
localparam NTR_TRTEINSTFILTERS_TRTEINSTFILTERS_SHIFT                    = 0;
localparam NTR_TRTEINSTFILTERS_TRTEINSTFILTERS_LOW                      = 0;
localparam NTR_TRTEINSTFILTERS_TRTEINSTFILTERS_HIGH                     = 15;
localparam NTR_TRTEINSTFILTERS_TRTEINSTFILTERS_WIDTH                    = 16;

localparam NTR_TRTEINSTFILTERS_RSVD3116_MASK                            = 32'hFFFF0000;
localparam NTR_TRTEINSTFILTERS_RSVD3116_SHIFT                           = 16;
localparam NTR_TRTEINSTFILTERS_RSVD3116_LOW                             = 16;
localparam NTR_TRTEINSTFILTERS_RSVD3116_HIGH                            = 31;
localparam NTR_TRTEINSTFILTERS_RSVD3116_WIDTH                           = 16;

localparam NTR_TRTEFILTER0CONTROL_TRTEFILTERENABLE_MASK                 = 32'h1;
localparam NTR_TRTEFILTER0CONTROL_TRTEFILTERENABLE_SHIFT                = 0;
localparam NTR_TRTEFILTER0CONTROL_TRTEFILTERENABLE_LOW                  = 0;
localparam NTR_TRTEFILTER0CONTROL_TRTEFILTERENABLE_HIGH                 = 0;
localparam NTR_TRTEFILTER0CONTROL_TRTEFILTERENABLE_WIDTH                = 1;

localparam NTR_TRTEFILTER0CONTROL_TRTEFILTERMATCHPRIVILEGE_MASK         = 32'h2;
localparam NTR_TRTEFILTER0CONTROL_TRTEFILTERMATCHPRIVILEGE_SHIFT        = 1;
localparam NTR_TRTEFILTER0CONTROL_TRTEFILTERMATCHPRIVILEGE_LOW          = 1;
localparam NTR_TRTEFILTER0CONTROL_TRTEFILTERMATCHPRIVILEGE_HIGH         = 1;
localparam NTR_TRTEFILTER0CONTROL_TRTEFILTERMATCHPRIVILEGE_WIDTH        = 1;

localparam NTR_TRTEFILTER0CONTROL_RSVD312_MASK                          = 32'hFFFFFFFC;
localparam NTR_TRTEFILTER0CONTROL_RSVD312_SHIFT                         = 2;
localparam NTR_TRTEFILTER0CONTROL_RSVD312_LOW                           = 2;
localparam NTR_TRTEFILTER0CONTROL_RSVD312_HIGH                          = 31;
localparam NTR_TRTEFILTER0CONTROL_RSVD312_WIDTH                         = 30;

localparam NTR_TRTEFILTER0MATCHINST_TRTEFILTERMATCHCHOICEPRIVILEGE_MASK   = 32'hFF;
localparam NTR_TRTEFILTER0MATCHINST_TRTEFILTERMATCHCHOICEPRIVILEGE_SHIFT   = 0;
localparam NTR_TRTEFILTER0MATCHINST_TRTEFILTERMATCHCHOICEPRIVILEGE_LOW   = 0;
localparam NTR_TRTEFILTER0MATCHINST_TRTEFILTERMATCHCHOICEPRIVILEGE_HIGH   = 7;
localparam NTR_TRTEFILTER0MATCHINST_TRTEFILTERMATCHCHOICEPRIVILEGE_WIDTH   = 8;

localparam NTR_TRTEFILTER0MATCHINST_RSVD318_MASK                        = 32'hFFFFFF00;
localparam NTR_TRTEFILTER0MATCHINST_RSVD318_SHIFT                       = 8;
localparam NTR_TRTEFILTER0MATCHINST_RSVD318_LOW                         = 8;
localparam NTR_TRTEFILTER0MATCHINST_RSVD318_HIGH                        = 31;
localparam NTR_TRTEFILTER0MATCHINST_RSVD318_WIDTH                       = 24;

localparam NTR_TRTSCONTROL_TRTSACTIVE_MASK                              = 32'h1;
localparam NTR_TRTSCONTROL_TRTSACTIVE_SHIFT                             = 0;
localparam NTR_TRTSCONTROL_TRTSACTIVE_LOW                               = 0;
localparam NTR_TRTSCONTROL_TRTSACTIVE_HIGH                              = 0;
localparam NTR_TRTSCONTROL_TRTSACTIVE_WIDTH                             = 1;

localparam NTR_TRTSCONTROL_TRTSCOUNT_MASK                               = 32'h2;
localparam NTR_TRTSCONTROL_TRTSCOUNT_SHIFT                              = 1;
localparam NTR_TRTSCONTROL_TRTSCOUNT_LOW                                = 1;
localparam NTR_TRTSCONTROL_TRTSCOUNT_HIGH                               = 1;
localparam NTR_TRTSCONTROL_TRTSCOUNT_WIDTH                              = 1;

localparam NTR_TRTSCONTROL_TRTSRESET_MASK                               = 32'h4;
localparam NTR_TRTSCONTROL_TRTSRESET_SHIFT                              = 2;
localparam NTR_TRTSCONTROL_TRTSRESET_LOW                                = 2;
localparam NTR_TRTSCONTROL_TRTSRESET_HIGH                               = 2;
localparam NTR_TRTSCONTROL_TRTSRESET_WIDTH                              = 1;

localparam NTR_TRTSCONTROL_TRTSRUNINDEBUG_MASK                          = 32'h8;
localparam NTR_TRTSCONTROL_TRTSRUNINDEBUG_SHIFT                         = 3;
localparam NTR_TRTSCONTROL_TRTSRUNINDEBUG_LOW                           = 3;
localparam NTR_TRTSCONTROL_TRTSRUNINDEBUG_HIGH                          = 3;
localparam NTR_TRTSCONTROL_TRTSRUNINDEBUG_WIDTH                         = 1;

localparam NTR_TRTSCONTROL_TRTSTYPE_MASK                                = 32'h70;
localparam NTR_TRTSCONTROL_TRTSTYPE_SHIFT                               = 4;
localparam NTR_TRTSCONTROL_TRTSTYPE_LOW                                 = 4;
localparam NTR_TRTSCONTROL_TRTSTYPE_HIGH                                = 6;
localparam NTR_TRTSCONTROL_TRTSTYPE_WIDTH                               = 3;

localparam NTR_TRTSCONTROL_RSVD77_MASK                                  = 32'h80;
localparam NTR_TRTSCONTROL_RSVD77_SHIFT                                 = 7;
localparam NTR_TRTSCONTROL_RSVD77_LOW                                   = 7;
localparam NTR_TRTSCONTROL_RSVD77_HIGH                                  = 7;
localparam NTR_TRTSCONTROL_RSVD77_WIDTH                                 = 1;

localparam NTR_TRTSCONTROL_TRTSPRESCALE_MASK                            = 32'h300;
localparam NTR_TRTSCONTROL_TRTSPRESCALE_SHIFT                           = 8;
localparam NTR_TRTSCONTROL_TRTSPRESCALE_LOW                             = 8;
localparam NTR_TRTSCONTROL_TRTSPRESCALE_HIGH                            = 9;
localparam NTR_TRTSCONTROL_TRTSPRESCALE_WIDTH                           = 2;

localparam NTR_TRTSCONTROL_RSVD1410_MASK                                = 32'h7C00;
localparam NTR_TRTSCONTROL_RSVD1410_SHIFT                               = 10;
localparam NTR_TRTSCONTROL_RSVD1410_LOW                                 = 10;
localparam NTR_TRTSCONTROL_RSVD1410_HIGH                                = 14;
localparam NTR_TRTSCONTROL_RSVD1410_WIDTH                               = 5;

localparam NTR_TRTSCONTROL_TRTSENABLE_MASK                              = 32'h8000;
localparam NTR_TRTSCONTROL_TRTSENABLE_SHIFT                             = 15;
localparam NTR_TRTSCONTROL_TRTSENABLE_LOW                               = 15;
localparam NTR_TRTSCONTROL_TRTSENABLE_HIGH                              = 15;
localparam NTR_TRTSCONTROL_TRTSENABLE_WIDTH                             = 1;

localparam NTR_TRTSCONTROL_RSVD2316_MASK                                = 32'hFF0000;
localparam NTR_TRTSCONTROL_RSVD2316_SHIFT                               = 16;
localparam NTR_TRTSCONTROL_RSVD2316_LOW                                 = 16;
localparam NTR_TRTSCONTROL_RSVD2316_HIGH                                = 23;
localparam NTR_TRTSCONTROL_RSVD2316_WIDTH                               = 8;

localparam NTR_TRTSCONTROL_TRTSWIDTH_MASK                               = 32'h3F000000;
localparam NTR_TRTSCONTROL_TRTSWIDTH_SHIFT                              = 24;
localparam NTR_TRTSCONTROL_TRTSWIDTH_LOW                                = 24;
localparam NTR_TRTSCONTROL_TRTSWIDTH_HIGH                               = 29;
localparam NTR_TRTSCONTROL_TRTSWIDTH_WIDTH                              = 6;

localparam NTR_TRTSCONTROL_RSVD3130_MASK                                = 32'hC0000000;
localparam NTR_TRTSCONTROL_RSVD3130_SHIFT                               = 30;
localparam NTR_TRTSCONTROL_RSVD3130_LOW                                 = 30;
localparam NTR_TRTSCONTROL_RSVD3130_HIGH                                = 31;
localparam NTR_TRTSCONTROL_RSVD3130_WIDTH                               = 2;

localparam NTR_CDBGNTRACEFRAMECFG_TRACESOURCEID_MASK                    = 32'hF;
localparam NTR_CDBGNTRACEFRAMECFG_TRACESOURCEID_SHIFT                   = 0;
localparam NTR_CDBGNTRACEFRAMECFG_TRACESOURCEID_LOW                     = 0;
localparam NTR_CDBGNTRACEFRAMECFG_TRACESOURCEID_HIGH                    = 3;
localparam NTR_CDBGNTRACEFRAMECFG_TRACESOURCEID_WIDTH                   = 4;

localparam NTR_CDBGNTRACEFRAMECFG_TRACEFRAMEFILLBYTE_MASK               = 32'hFF0;
localparam NTR_CDBGNTRACEFRAMECFG_TRACEFRAMEFILLBYTE_SHIFT              = 4;
localparam NTR_CDBGNTRACEFRAMECFG_TRACEFRAMEFILLBYTE_LOW                = 4;
localparam NTR_CDBGNTRACEFRAMECFG_TRACEFRAMEFILLBYTE_HIGH               = 11;
localparam NTR_CDBGNTRACEFRAMECFG_TRACEFRAMEFILLBYTE_WIDTH              = 8;

localparam NTR_CDBGNTRACEFRAMECFG_FRAMELENGHTINBYTES_MASK               = 32'hF000;
localparam NTR_CDBGNTRACEFRAMECFG_FRAMELENGHTINBYTES_SHIFT              = 12;
localparam NTR_CDBGNTRACEFRAMECFG_FRAMELENGHTINBYTES_LOW                = 12;
localparam NTR_CDBGNTRACEFRAMECFG_FRAMELENGHTINBYTES_HIGH               = 15;
localparam NTR_CDBGNTRACEFRAMECFG_FRAMELENGHTINBYTES_WIDTH              = 4;

localparam NTR_CDBGNTRACEFRAMECFG_RSVD1916_MASK                         = 32'hF0000;
localparam NTR_CDBGNTRACEFRAMECFG_RSVD1916_SHIFT                        = 16;
localparam NTR_CDBGNTRACEFRAMECFG_RSVD1916_LOW                          = 16;
localparam NTR_CDBGNTRACEFRAMECFG_RSVD1916_HIGH                         = 19;
localparam NTR_CDBGNTRACEFRAMECFG_RSVD1916_WIDTH                        = 4;

localparam NTR_CDBGNTRACEFRAMECFG_FRAMEMODEENABLE_MASK                  = 32'h100000;
localparam NTR_CDBGNTRACEFRAMECFG_FRAMEMODEENABLE_SHIFT                 = 20;
localparam NTR_CDBGNTRACEFRAMECFG_FRAMEMODEENABLE_LOW                   = 20;
localparam NTR_CDBGNTRACEFRAMECFG_FRAMEMODEENABLE_HIGH                  = 20;
localparam NTR_CDBGNTRACEFRAMECFG_FRAMEMODEENABLE_WIDTH                 = 1;

localparam NTR_CDBGNTRACEFRAMECFG_FRAMECLOSUREMODE_MASK                 = 32'h200000;
localparam NTR_CDBGNTRACEFRAMECFG_FRAMECLOSUREMODE_SHIFT                = 21;
localparam NTR_CDBGNTRACEFRAMECFG_FRAMECLOSUREMODE_LOW                  = 21;
localparam NTR_CDBGNTRACEFRAMECFG_FRAMECLOSUREMODE_HIGH                 = 21;
localparam NTR_CDBGNTRACEFRAMECFG_FRAMECLOSUREMODE_WIDTH                = 1;

localparam NTR_CDBGNTRACEFRAMECFG_RSVD3122_MASK                         = 32'hFFC00000;
localparam NTR_CDBGNTRACEFRAMECFG_RSVD3122_SHIFT                        = 22;
localparam NTR_CDBGNTRACEFRAMECFG_RSVD3122_LOW                          = 22;
localparam NTR_CDBGNTRACEFRAMECFG_RSVD3122_HIGH                         = 31;
localparam NTR_CDBGNTRACEFRAMECFG_RSVD3122_WIDTH                        = 10;

localparam NTR_SCRATCHLO_DATA_MASK                                      = 32'hFFFFFFFF;
localparam NTR_SCRATCHLO_DATA_SHIFT                                     = 0;
localparam NTR_SCRATCHLO_DATA_LOW                                       = 0;
localparam NTR_SCRATCHLO_DATA_HIGH                                      = 31;
localparam NTR_SCRATCHLO_DATA_WIDTH                                     = 32;

localparam NTR_SCRATCHHI_DATA_MASK                                      = 32'hFFFFFFFF;
localparam NTR_SCRATCHHI_DATA_SHIFT                                     = 0;
localparam NTR_SCRATCHHI_DATA_LOW                                       = 0;
localparam NTR_SCRATCHHI_DATA_HIGH                                      = 31;
localparam NTR_SCRATCHHI_DATA_WIDTH                                     = 32;

localparam NTR_NUM_REGISTERS                                            = 10;

typedef struct packed {
  logic               NtrMmrTrtecontrolHit;
  logic               NtrMmrTrteimplHit;
  logic               NtrMmrTrteinstfeaturesHit;
  logic               NtrMmrTrteinstfiltersHit;
  logic               NtrMmrTrtefilter0ControlHit;
  logic               NtrMmrTrtefilter0MatchinstHit;
  logic               NtrMmrTrtscontrolHit;
  logic               NtrMmrCdbgntraceframecfgHit;
  logic               NtrMmrScratchloHit;
  logic               NtrMmrScratchhiHit;
} NtrMmrHit_s;

typedef struct packed {
    logic    [4:0]        Rsvd3127 ;
    logic    [2:0]        Trteformat ;
    logic    [3:0]        Trtesyncmax ;
    logic    [1:0]        Rsvd1918 ;
    logic    [1:0]        Trtesyncmode ;
    logic    [0:0]        Trteinhibitsrc ;
    logic    [0:0]        Rsvd1414 ;
    logic    [0:0]        Trteinststallena ;
    logic    [0:0]        Trteinststalloroverflow ;
    logic    [0:0]        Trteinsttriggerenable ;
    logic    [0:0]        Rsvd1010 ;
    logic    [0:0]        Trtecontext ;
    logic    [1:0]        Rsvd87 ;
    logic    [2:0]        Trteinstmode ;
    logic    [0:0]        Trteempty ;
    logic    [0:0]        Trteinsttracing ;
    logic    [0:0]        Trteenable ;
    logic    [0:0]        Trteactive ;
} NtrTrtecontrolMmr_s;

typedef struct packed {
    logic    [1:0]        Rsvd3130 ;
    logic    [0:0]        Trtetracepatchenable ;
    logic    [0:0]        Trteclatriggerenable ;
    logic    [3:0]        Trtevendorframelength ;
    logic    [3:0]        Trteprotocolminor ;
    logic    [3:0]        Trteprotocolmajor ;
    logic    [3:0]        Rsvd1512 ;
    logic    [3:0]        Trtecomptype ;
    logic    [3:0]        Trteverminor ;
    logic    [3:0]        Trtevermajor ;
} NtrTrteimplMmr_s;

typedef struct packed {
    logic    [3:0]        Trtesrcbits ;
    logic   [11:0]        Trtesrcid ;
    logic    [6:0]        Rsvd159 ;
    logic    [0:0]        Trteinstenrepeatedhistory ;
    logic    [5:0]        Rsvd72 ;
    logic    [0:0]        Trteinstnotrapaddr ;
    logic    [0:0]        Trteinstnoaddrdiff ;
} NtrTrteinstfeaturesMmr_s;

typedef struct packed {
    logic   [15:0]        Rsvd3116 ;
    logic   [15:0]        Trteinstfilters ;
} NtrTrteinstfiltersMmr_s;

typedef struct packed {
    logic   [29:0]        Rsvd312 ;
    logic    [0:0]        Trtefiltermatchprivilege ;
    logic    [0:0]        Trtefilterenable ;
} NtrTrtefilter0ControlMmr_s;

typedef struct packed {
    logic   [23:0]        Rsvd318 ;
    logic    [7:0]        Trtefiltermatchchoiceprivilege ;
} NtrTrtefilter0MatchinstMmr_s;

typedef struct packed {
    logic    [1:0]        Rsvd3130 ;
    logic    [5:0]        Trtswidth ;
    logic    [7:0]        Rsvd2316 ;
    logic    [0:0]        Trtsenable ;
    logic    [4:0]        Rsvd1410 ;
    logic    [1:0]        Trtsprescale ;
    logic    [0:0]        Rsvd77 ;
    logic    [2:0]        Trtstype ;
    logic    [0:0]        Trtsrunindebug ;
    logic    [0:0]        Trtsreset ;
    logic    [0:0]        Trtscount ;
    logic    [0:0]        Trtsactive ;
} NtrTrtscontrolMmr_s;

typedef struct packed {
    logic    [9:0]        Rsvd3122 ;
    logic    [0:0]        FrameClosureMode ;
    logic    [0:0]        FrameModeEnable ;
    logic    [3:0]        Rsvd1916 ;
    logic    [3:0]        FrameLenghtInBytes ;
    logic    [7:0]        TraceFrameFillByte ;
    logic    [3:0]        TraceSourceId ;
} NtrCdbgntraceframecfgMmr_s;

typedef struct packed {
    logic   [31:0]        Data ;
} NtrScratchloMmr_s;

typedef struct packed {
    logic   [31:0]        Data ;
} NtrScratchhiMmr_s;

typedef struct packed {
    logic    [4:0]        Rsvd3127 ;
    logic    [2:0]        Trteformat ;
    logic    [3:0]        Trtesyncmax ;
    logic    [1:0]        Rsvd1918 ;
    logic    [1:0]        Trtesyncmode ;
    logic    [0:0]        Trteinhibitsrc ;
    logic    [0:0]        Rsvd1414 ;
    logic    [0:0]        Trteinststallena ;
    logic    [0:0]        Trteinststalloroverflow ;
    logic    [0:0]        Trteinsttriggerenable ;
    logic    [0:0]        Rsvd1010 ;
    logic    [0:0]        Trtecontext ;
    logic    [1:0]        Rsvd87 ;
    logic    [2:0]        Trteinstmode ;
    logic    [0:0]        Trteempty ;
    logic    [0:0]        Trteinsttracing ;
    logic    [0:0]        Trteenable ;
    logic    [0:0]        Trteactive ;
} NtrTrtecontrolMmrUnpack_s;

typedef struct packed {
    logic    [1:0]        Rsvd3130 ;
    logic    [0:0]        Trtetracepatchenable ;
    logic    [0:0]        Trteclatriggerenable ;
    logic    [3:0]        Trtevendorframelength ;
    logic    [3:0]        Trteprotocolminor ;
    logic    [3:0]        Trteprotocolmajor ;
    logic    [3:0]        Rsvd1512 ;
    logic    [3:0]        Trtecomptype ;
    logic    [3:0]        Trteverminor ;
    logic    [3:0]        Trtevermajor ;
} NtrTrteimplMmrUnpack_s;

typedef struct packed {
    logic    [3:0]        Trtesrcbits ;
    logic   [11:0]        Trtesrcid ;
    logic    [6:0]        Rsvd159 ;
    logic    [0:0]        Trteinstenrepeatedhistory ;
    logic    [5:0]        Rsvd72 ;
    logic    [0:0]        Trteinstnotrapaddr ;
    logic    [0:0]        Trteinstnoaddrdiff ;
} NtrTrteinstfeaturesMmrUnpack_s;

typedef struct packed {
    logic   [15:0]        Rsvd3116 ;
    logic   [15:0]        Trteinstfilters ;
} NtrTrteinstfiltersMmrUnpack_s;

typedef struct packed {
    logic   [29:0]        Rsvd312 ;
    logic    [0:0]        Trtefiltermatchprivilege ;
    logic    [0:0]        Trtefilterenable ;
} NtrTrtefilter0ControlMmrUnpack_s;

typedef struct packed {
    logic   [23:0]        Rsvd318 ;
    logic    [7:0]        Trtefiltermatchchoiceprivilege ;
} NtrTrtefilter0MatchinstMmrUnpack_s;

typedef struct packed {
    logic    [1:0]        Rsvd3130 ;
    logic    [5:0]        Trtswidth ;
    logic    [7:0]        Rsvd2316 ;
    logic    [0:0]        Trtsenable ;
    logic    [4:0]        Rsvd1410 ;
    logic    [1:0]        Trtsprescale ;
    logic    [0:0]        Rsvd77 ;
    logic    [2:0]        Trtstype ;
    logic    [0:0]        Trtsrunindebug ;
    logic    [0:0]        Trtsreset ;
    logic    [0:0]        Trtscount ;
    logic    [0:0]        Trtsactive ;
} NtrTrtscontrolMmrUnpack_s;

typedef struct packed {
    logic    [9:0]        Rsvd3122 ;
    logic    [0:0]        FrameClosureMode ;
    logic    [0:0]        FrameModeEnable ;
    logic    [3:0]        Rsvd1916 ;
    logic    [3:0]        FrameLenghtInBytes ;
    logic    [7:0]        TraceFrameFillByte ;
    logic    [3:0]        TraceSourceId ;
} NtrCdbgntraceframecfgMmrUnpack_s;

typedef struct packed {
    logic   [31:0]        Data ;
} NtrScratchloMmrUnpack_s;

typedef struct packed {
    logic   [31:0]        Data ;
} NtrScratchhiMmrUnpack_s;

typedef struct packed {
    NtrTrtecontrolMmr_s   Data;
    logic                 TrteinststalloroverflowWrEn ;
    logic                 TrteemptyWrEn ;
    logic                 TrteinsttracingWrEn ;
} NtrTrtecontrolMmrWr_s;

typedef struct packed {
    NtrTrtecontrolMmr_s   Trtecontrol;
    NtrTrteimplMmr_s      Trteimpl;
    NtrTrteinstfeaturesMmr_s Trteinstfeatures;
    NtrTrteinstfiltersMmr_s Trteinstfilters;
    NtrTrtefilter0ControlMmr_s Trtefilter0Control;
    NtrTrtefilter0MatchinstMmr_s Trtefilter0Matchinst;
    NtrTrtscontrolMmr_s   Trtscontrol;
    NtrCdbgntraceframecfgMmr_s Cdbgntraceframecfg;
    NtrScratchloMmr_s     Scratchlo;
    NtrScratchhiMmr_s     Scratchhi;
} NtrMmrs_s;

typedef struct packed {
    NtrTrtecontrolMmrWr_s TrtecontrolWr;
} NtrMmrsWr_s;

function automatic NtrTrtecontrolMmrUnpack_s unpack_NtrTrtecontrolMmr;
input NtrTrtecontrolMmr_s packed_mmr;
begin
    unpack_NtrTrtecontrolMmr = '0;
    unpack_NtrTrtecontrolMmr.Trteactive = packed_mmr.Trteactive;
    unpack_NtrTrtecontrolMmr.Trteenable = packed_mmr.Trteenable;
    unpack_NtrTrtecontrolMmr.Trteinsttracing = packed_mmr.Trteinsttracing;
    unpack_NtrTrtecontrolMmr.Trteempty = packed_mmr.Trteempty;
    unpack_NtrTrtecontrolMmr.Trteinstmode = packed_mmr.Trteinstmode;
    unpack_NtrTrtecontrolMmr.Rsvd87 = packed_mmr.Rsvd87;
    unpack_NtrTrtecontrolMmr.Trtecontext = packed_mmr.Trtecontext;
    unpack_NtrTrtecontrolMmr.Rsvd1010 = packed_mmr.Rsvd1010;
    unpack_NtrTrtecontrolMmr.Trteinsttriggerenable = packed_mmr.Trteinsttriggerenable;
    unpack_NtrTrtecontrolMmr.Trteinststalloroverflow = packed_mmr.Trteinststalloroverflow;
    unpack_NtrTrtecontrolMmr.Trteinststallena = packed_mmr.Trteinststallena;
    unpack_NtrTrtecontrolMmr.Rsvd1414 = packed_mmr.Rsvd1414;
    unpack_NtrTrtecontrolMmr.Trteinhibitsrc = packed_mmr.Trteinhibitsrc;
    unpack_NtrTrtecontrolMmr.Trtesyncmode = packed_mmr.Trtesyncmode;
    unpack_NtrTrtecontrolMmr.Rsvd1918 = packed_mmr.Rsvd1918;
    unpack_NtrTrtecontrolMmr.Trtesyncmax = packed_mmr.Trtesyncmax;
    unpack_NtrTrtecontrolMmr.Trteformat = packed_mmr.Trteformat;
    unpack_NtrTrtecontrolMmr.Rsvd3127 = packed_mmr.Rsvd3127;
end
endfunction

function automatic NtrTrteimplMmrUnpack_s unpack_NtrTrteimplMmr;
input NtrTrteimplMmr_s packed_mmr;
begin
    unpack_NtrTrteimplMmr = '0;
    unpack_NtrTrteimplMmr.Trtevermajor = packed_mmr.Trtevermajor;
    unpack_NtrTrteimplMmr.Trteverminor = packed_mmr.Trteverminor;
    unpack_NtrTrteimplMmr.Trtecomptype = packed_mmr.Trtecomptype;
    unpack_NtrTrteimplMmr.Rsvd1512 = packed_mmr.Rsvd1512;
    unpack_NtrTrteimplMmr.Trteprotocolmajor = packed_mmr.Trteprotocolmajor;
    unpack_NtrTrteimplMmr.Trteprotocolminor = packed_mmr.Trteprotocolminor;
    unpack_NtrTrteimplMmr.Trtevendorframelength = packed_mmr.Trtevendorframelength;
    unpack_NtrTrteimplMmr.Trteclatriggerenable = packed_mmr.Trteclatriggerenable;
    unpack_NtrTrteimplMmr.Trtetracepatchenable = packed_mmr.Trtetracepatchenable;
    unpack_NtrTrteimplMmr.Rsvd3130 = packed_mmr.Rsvd3130;
end
endfunction

function automatic NtrTrteinstfeaturesMmrUnpack_s unpack_NtrTrteinstfeaturesMmr;
input NtrTrteinstfeaturesMmr_s packed_mmr;
begin
    unpack_NtrTrteinstfeaturesMmr = '0;
    unpack_NtrTrteinstfeaturesMmr.Trteinstnoaddrdiff = packed_mmr.Trteinstnoaddrdiff;
    unpack_NtrTrteinstfeaturesMmr.Trteinstnotrapaddr = packed_mmr.Trteinstnotrapaddr;
    unpack_NtrTrteinstfeaturesMmr.Rsvd72 = packed_mmr.Rsvd72;
    unpack_NtrTrteinstfeaturesMmr.Trteinstenrepeatedhistory = packed_mmr.Trteinstenrepeatedhistory;
    unpack_NtrTrteinstfeaturesMmr.Rsvd159 = packed_mmr.Rsvd159;
    unpack_NtrTrteinstfeaturesMmr.Trtesrcid = packed_mmr.Trtesrcid;
    unpack_NtrTrteinstfeaturesMmr.Trtesrcbits = packed_mmr.Trtesrcbits;
end
endfunction

function automatic NtrTrteinstfiltersMmrUnpack_s unpack_NtrTrteinstfiltersMmr;
input NtrTrteinstfiltersMmr_s packed_mmr;
begin
    unpack_NtrTrteinstfiltersMmr = '0;
    unpack_NtrTrteinstfiltersMmr.Trteinstfilters = packed_mmr.Trteinstfilters;
    unpack_NtrTrteinstfiltersMmr.Rsvd3116 = packed_mmr.Rsvd3116;
end
endfunction

function automatic NtrTrtefilter0ControlMmrUnpack_s unpack_NtrTrtefilter0ControlMmr;
input NtrTrtefilter0ControlMmr_s packed_mmr;
begin
    unpack_NtrTrtefilter0ControlMmr = '0;
    unpack_NtrTrtefilter0ControlMmr.Trtefilterenable = packed_mmr.Trtefilterenable;
    unpack_NtrTrtefilter0ControlMmr.Trtefiltermatchprivilege = packed_mmr.Trtefiltermatchprivilege;
    unpack_NtrTrtefilter0ControlMmr.Rsvd312 = packed_mmr.Rsvd312;
end
endfunction

function automatic NtrTrtefilter0MatchinstMmrUnpack_s unpack_NtrTrtefilter0MatchinstMmr;
input NtrTrtefilter0MatchinstMmr_s packed_mmr;
begin
    unpack_NtrTrtefilter0MatchinstMmr = '0;
    unpack_NtrTrtefilter0MatchinstMmr.Trtefiltermatchchoiceprivilege = packed_mmr.Trtefiltermatchchoiceprivilege;
    unpack_NtrTrtefilter0MatchinstMmr.Rsvd318 = packed_mmr.Rsvd318;
end
endfunction

function automatic NtrTrtscontrolMmrUnpack_s unpack_NtrTrtscontrolMmr;
input NtrTrtscontrolMmr_s packed_mmr;
begin
    unpack_NtrTrtscontrolMmr = '0;
    unpack_NtrTrtscontrolMmr.Trtsactive = packed_mmr.Trtsactive;
    unpack_NtrTrtscontrolMmr.Trtscount = packed_mmr.Trtscount;
    unpack_NtrTrtscontrolMmr.Trtsreset = packed_mmr.Trtsreset;
    unpack_NtrTrtscontrolMmr.Trtsrunindebug = packed_mmr.Trtsrunindebug;
    unpack_NtrTrtscontrolMmr.Trtstype = packed_mmr.Trtstype;
    unpack_NtrTrtscontrolMmr.Rsvd77 = packed_mmr.Rsvd77;
    unpack_NtrTrtscontrolMmr.Trtsprescale = packed_mmr.Trtsprescale;
    unpack_NtrTrtscontrolMmr.Rsvd1410 = packed_mmr.Rsvd1410;
    unpack_NtrTrtscontrolMmr.Trtsenable = packed_mmr.Trtsenable;
    unpack_NtrTrtscontrolMmr.Rsvd2316 = packed_mmr.Rsvd2316;
    unpack_NtrTrtscontrolMmr.Trtswidth = packed_mmr.Trtswidth;
    unpack_NtrTrtscontrolMmr.Rsvd3130 = packed_mmr.Rsvd3130;
end
endfunction

function automatic NtrCdbgntraceframecfgMmrUnpack_s unpack_NtrCdbgntraceframecfgMmr;
input NtrCdbgntraceframecfgMmr_s packed_mmr;
begin
    unpack_NtrCdbgntraceframecfgMmr = '0;
    unpack_NtrCdbgntraceframecfgMmr.TraceSourceId = packed_mmr.TraceSourceId;
    unpack_NtrCdbgntraceframecfgMmr.TraceFrameFillByte = packed_mmr.TraceFrameFillByte;
    unpack_NtrCdbgntraceframecfgMmr.FrameLenghtInBytes = packed_mmr.FrameLenghtInBytes;
    unpack_NtrCdbgntraceframecfgMmr.Rsvd1916 = packed_mmr.Rsvd1916;
    unpack_NtrCdbgntraceframecfgMmr.FrameModeEnable = packed_mmr.FrameModeEnable;
    unpack_NtrCdbgntraceframecfgMmr.FrameClosureMode = packed_mmr.FrameClosureMode;
    unpack_NtrCdbgntraceframecfgMmr.Rsvd3122 = packed_mmr.Rsvd3122;
end
endfunction

function automatic NtrScratchloMmrUnpack_s unpack_NtrScratchloMmr;
input NtrScratchloMmr_s packed_mmr;
begin
    unpack_NtrScratchloMmr = '0;
    unpack_NtrScratchloMmr.Data = packed_mmr.Data;
end
endfunction

function automatic NtrScratchhiMmrUnpack_s unpack_NtrScratchhiMmr;
input NtrScratchhiMmr_s packed_mmr;
begin
    unpack_NtrScratchhiMmr = '0;
    unpack_NtrScratchhiMmr.Data = packed_mmr.Data;
end
endfunction

function automatic NtrTrtecontrolMmr_s pack_NtrTrtecontrolMmr;
input NtrTrtecontrolMmrUnpack_s unpacked_mmr;
begin
    pack_NtrTrtecontrolMmr.Trteactive = unpacked_mmr.Trteactive;
    pack_NtrTrtecontrolMmr.Trteenable = unpacked_mmr.Trteenable;
    pack_NtrTrtecontrolMmr.Trteinsttracing = unpacked_mmr.Trteinsttracing;
    pack_NtrTrtecontrolMmr.Trteempty = unpacked_mmr.Trteempty;
    pack_NtrTrtecontrolMmr.Trteinstmode = unpacked_mmr.Trteinstmode;
    pack_NtrTrtecontrolMmr.Rsvd87 = unpacked_mmr.Rsvd87;
    pack_NtrTrtecontrolMmr.Trtecontext = unpacked_mmr.Trtecontext;
    pack_NtrTrtecontrolMmr.Rsvd1010 = unpacked_mmr.Rsvd1010;
    pack_NtrTrtecontrolMmr.Trteinsttriggerenable = unpacked_mmr.Trteinsttriggerenable;
    pack_NtrTrtecontrolMmr.Trteinststalloroverflow = unpacked_mmr.Trteinststalloroverflow;
    pack_NtrTrtecontrolMmr.Trteinststallena = unpacked_mmr.Trteinststallena;
    pack_NtrTrtecontrolMmr.Rsvd1414 = unpacked_mmr.Rsvd1414;
    pack_NtrTrtecontrolMmr.Trteinhibitsrc = unpacked_mmr.Trteinhibitsrc;
    pack_NtrTrtecontrolMmr.Trtesyncmode = unpacked_mmr.Trtesyncmode;
    pack_NtrTrtecontrolMmr.Rsvd1918 = unpacked_mmr.Rsvd1918;
    pack_NtrTrtecontrolMmr.Trtesyncmax = unpacked_mmr.Trtesyncmax;
    pack_NtrTrtecontrolMmr.Trteformat = unpacked_mmr.Trteformat;
    pack_NtrTrtecontrolMmr.Rsvd3127 = unpacked_mmr.Rsvd3127;
end
endfunction

function automatic NtrTrteimplMmr_s pack_NtrTrteimplMmr;
input NtrTrteimplMmrUnpack_s unpacked_mmr;
begin
    pack_NtrTrteimplMmr.Trtevermajor = unpacked_mmr.Trtevermajor;
    pack_NtrTrteimplMmr.Trteverminor = unpacked_mmr.Trteverminor;
    pack_NtrTrteimplMmr.Trtecomptype = unpacked_mmr.Trtecomptype;
    pack_NtrTrteimplMmr.Rsvd1512 = unpacked_mmr.Rsvd1512;
    pack_NtrTrteimplMmr.Trteprotocolmajor = unpacked_mmr.Trteprotocolmajor;
    pack_NtrTrteimplMmr.Trteprotocolminor = unpacked_mmr.Trteprotocolminor;
    pack_NtrTrteimplMmr.Trtevendorframelength = unpacked_mmr.Trtevendorframelength;
    pack_NtrTrteimplMmr.Trteclatriggerenable = unpacked_mmr.Trteclatriggerenable;
    pack_NtrTrteimplMmr.Trtetracepatchenable = unpacked_mmr.Trtetracepatchenable;
    pack_NtrTrteimplMmr.Rsvd3130 = unpacked_mmr.Rsvd3130;
end
endfunction

function automatic NtrTrteinstfeaturesMmr_s pack_NtrTrteinstfeaturesMmr;
input NtrTrteinstfeaturesMmrUnpack_s unpacked_mmr;
begin
    pack_NtrTrteinstfeaturesMmr.Trteinstnoaddrdiff = unpacked_mmr.Trteinstnoaddrdiff;
    pack_NtrTrteinstfeaturesMmr.Trteinstnotrapaddr = unpacked_mmr.Trteinstnotrapaddr;
    pack_NtrTrteinstfeaturesMmr.Rsvd72 = unpacked_mmr.Rsvd72;
    pack_NtrTrteinstfeaturesMmr.Trteinstenrepeatedhistory = unpacked_mmr.Trteinstenrepeatedhistory;
    pack_NtrTrteinstfeaturesMmr.Rsvd159 = unpacked_mmr.Rsvd159;
    pack_NtrTrteinstfeaturesMmr.Trtesrcid = unpacked_mmr.Trtesrcid;
    pack_NtrTrteinstfeaturesMmr.Trtesrcbits = unpacked_mmr.Trtesrcbits;
end
endfunction

function automatic NtrTrteinstfiltersMmr_s pack_NtrTrteinstfiltersMmr;
input NtrTrteinstfiltersMmrUnpack_s unpacked_mmr;
begin
    pack_NtrTrteinstfiltersMmr.Trteinstfilters = unpacked_mmr.Trteinstfilters;
    pack_NtrTrteinstfiltersMmr.Rsvd3116 = unpacked_mmr.Rsvd3116;
end
endfunction

function automatic NtrTrtefilter0ControlMmr_s pack_NtrTrtefilter0ControlMmr;
input NtrTrtefilter0ControlMmrUnpack_s unpacked_mmr;
begin
    pack_NtrTrtefilter0ControlMmr.Trtefilterenable = unpacked_mmr.Trtefilterenable;
    pack_NtrTrtefilter0ControlMmr.Trtefiltermatchprivilege = unpacked_mmr.Trtefiltermatchprivilege;
    pack_NtrTrtefilter0ControlMmr.Rsvd312 = unpacked_mmr.Rsvd312;
end
endfunction

function automatic NtrTrtefilter0MatchinstMmr_s pack_NtrTrtefilter0MatchinstMmr;
input NtrTrtefilter0MatchinstMmrUnpack_s unpacked_mmr;
begin
    pack_NtrTrtefilter0MatchinstMmr.Trtefiltermatchchoiceprivilege = unpacked_mmr.Trtefiltermatchchoiceprivilege;
    pack_NtrTrtefilter0MatchinstMmr.Rsvd318 = unpacked_mmr.Rsvd318;
end
endfunction

function automatic NtrTrtscontrolMmr_s pack_NtrTrtscontrolMmr;
input NtrTrtscontrolMmrUnpack_s unpacked_mmr;
begin
    pack_NtrTrtscontrolMmr.Trtsactive = unpacked_mmr.Trtsactive;
    pack_NtrTrtscontrolMmr.Trtscount = unpacked_mmr.Trtscount;
    pack_NtrTrtscontrolMmr.Trtsreset = unpacked_mmr.Trtsreset;
    pack_NtrTrtscontrolMmr.Trtsrunindebug = unpacked_mmr.Trtsrunindebug;
    pack_NtrTrtscontrolMmr.Trtstype = unpacked_mmr.Trtstype;
    pack_NtrTrtscontrolMmr.Rsvd77 = unpacked_mmr.Rsvd77;
    pack_NtrTrtscontrolMmr.Trtsprescale = unpacked_mmr.Trtsprescale;
    pack_NtrTrtscontrolMmr.Rsvd1410 = unpacked_mmr.Rsvd1410;
    pack_NtrTrtscontrolMmr.Trtsenable = unpacked_mmr.Trtsenable;
    pack_NtrTrtscontrolMmr.Rsvd2316 = unpacked_mmr.Rsvd2316;
    pack_NtrTrtscontrolMmr.Trtswidth = unpacked_mmr.Trtswidth;
    pack_NtrTrtscontrolMmr.Rsvd3130 = unpacked_mmr.Rsvd3130;
end
endfunction

function automatic NtrCdbgntraceframecfgMmr_s pack_NtrCdbgntraceframecfgMmr;
input NtrCdbgntraceframecfgMmrUnpack_s unpacked_mmr;
begin
    pack_NtrCdbgntraceframecfgMmr.TraceSourceId = unpacked_mmr.TraceSourceId;
    pack_NtrCdbgntraceframecfgMmr.TraceFrameFillByte = unpacked_mmr.TraceFrameFillByte;
    pack_NtrCdbgntraceframecfgMmr.FrameLenghtInBytes = unpacked_mmr.FrameLenghtInBytes;
    pack_NtrCdbgntraceframecfgMmr.Rsvd1916 = unpacked_mmr.Rsvd1916;
    pack_NtrCdbgntraceframecfgMmr.FrameModeEnable = unpacked_mmr.FrameModeEnable;
    pack_NtrCdbgntraceframecfgMmr.FrameClosureMode = unpacked_mmr.FrameClosureMode;
    pack_NtrCdbgntraceframecfgMmr.Rsvd3122 = unpacked_mmr.Rsvd3122;
end
endfunction

function automatic NtrScratchloMmr_s pack_NtrScratchloMmr;
input NtrScratchloMmrUnpack_s unpacked_mmr;
begin
    pack_NtrScratchloMmr.Data = unpacked_mmr.Data;
end
endfunction

function automatic NtrScratchhiMmr_s pack_NtrScratchhiMmr;
input NtrScratchhiMmrUnpack_s unpacked_mmr;
begin
    pack_NtrScratchhiMmr.Data = unpacked_mmr.Data;
end
endfunction

endpackage

`endif
