################################################################################
#This is an internally genertaed by spyglass to populate Waiver Info for Reports
#Note:Spyglass does not support any perl routine like "spyDecompileWaiverInfo"
#     The routine is purely for internal usage of spyglass
################################################################################


use SpyGlass;

spyClearWaiverHashInPerl(0);

spyComputeWaivedViolCount("totalWaivedViolationCount"=>'56',
                          "totalGeneratedCount"=>'0',
                          "totalReportCount"=>'0'
                         );

spyDecompileWaiverInfo("waive_cmd_id"=>'1',
                       "waiverCmd"=>'q%waive  -regexp  -file "rand_id_queue.sv" -rule "AutomaticFuncTask-ML" -comment "Raises error in enhanced lint"%',
                       "-file"=>'m%rand_id_queue.sv%',
                       "-rule"=>'m%AutomaticFuncTask-ML%',
                       "-regexp"=>'1',
                       "-comment"=>'"Raises error in enhanced lint"',
                       "violations_waived"=>'',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"lint/dfd_top_waiver_file.awl"',
                       "waiverline"=>'4'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'2',
                       "waiverCmd"=>'q%waive  -regexp  -file "axi_id_prepend.sv" -rule "W164b" -comment "Raises error in enhanced lint"%',
                       "-file"=>'m%axi_id_prepend.sv%',
                       "-rule"=>'m%W164b%',
                       "-regexp"=>'1',
                       "-comment"=>'"Raises error in enhanced lint"',
                       "violations_waived"=>'',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"lint/dfd_top_waiver_file.awl"',
                       "waiverline"=>'5'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'3',
                       "waiverCmd"=>'q%waive  -regexp  -file "ecc_pkg.sv" -rule "W416" -comment "Raises error in enhanced lint"%',
                       "-file"=>'m%ecc_pkg.sv%',
                       "-rule"=>'m%W416%',
                       "-regexp"=>'1',
                       "-comment"=>'"Raises error in enhanced lint"',
                       "violations_waived"=>'',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"lint/dfd_top_waiver_file.awl"',
                       "waiverline"=>'6'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'4',
                       "waiverCmd"=>'q%waive -file_lineblock "/proj_risc/user_dev/joeychen/projects/tt-dfd/rtl/common/tt_dfd_generic_fifoMN.sv" 96 98 -rule "ImproperRangeIndex-ML" -comment "RTL_PRAGMA: Waiver pragma in HDL source"%',
                       "-file_lineblock"=>'q%/proj_risc/user_dev/joeychen/projects/tt-dfd/rtl/common/tt_dfd_generic_fifoMN.sv% 96 98',
                       "-rule"=>'q%ImproperRangeIndex-ML%',
                       "-comment"=>'"RTL_PRAGMA: Waiver pragma in HDL source"',
                       "violations_waived"=>'',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"lint/tt_dfd/dfd_top/lint/lint_rtl/spyglass_spysch/waiver/pragma2Waiver.swl"',
                       "waiverline"=>'10'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'5',
                       "waiverCmd"=>'q%waive -file_lineblock "/proj_risc/user_dev/joeychen/projects/tt-dfd/rtl/common/tt_dfd_generic_fifoMN.sv" 122 128 -rule "ImproperRangeIndex-ML" -comment "RTL_PRAGMA: Waiver pragma in HDL source"%',
                       "-file_lineblock"=>'q%/proj_risc/user_dev/joeychen/projects/tt-dfd/rtl/common/tt_dfd_generic_fifoMN.sv% 122 128',
                       "-rule"=>'q%ImproperRangeIndex-ML%',
                       "-comment"=>'"RTL_PRAGMA: Waiver pragma in HDL source"',
                       "violations_waived"=>'',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"lint/tt_dfd/dfd_top/lint/lint_rtl/spyglass_spysch/waiver/pragma2Waiver.swl"',
                       "waiverline"=>'11'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'6',
                       "waiverCmd"=>'q%waive -file_line "/proj_risc/user_dev/joeychen/projects/tt-dfd/rtl/trace/dfd_trace_mem_sink_generic.sv" 79 -rule "W287a" -comment "RTL_PRAGMA: Waiver pragma in HDL source"%',
                       "-file_line"=>'q%/proj_risc/user_dev/joeychen/projects/tt-dfd/rtl/trace/dfd_trace_mem_sink_generic.sv% 79',
                       "-rule"=>'"W287a"',
                       "-comment"=>'"RTL_PRAGMA: Waiver pragma in HDL source"',
                       "violations_waived"=>'8182 8189 8196 8203 8210 8217 8224 8231',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"lint/tt_dfd/dfd_top/lint/lint_rtl/spyglass_spysch/waiver/pragma2Waiver.swl"',
                       "waiverline"=>'12'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'7',
                       "waiverCmd"=>'q%waive -file_line "/proj_risc/user_dev/joeychen/projects/tt-dfd/rtl/trace/dfd_trace_mem_sink_generic.sv" 80 -rule "W287a" -comment "RTL_PRAGMA: Waiver pragma in HDL source"%',
                       "-file_line"=>'q%/proj_risc/user_dev/joeychen/projects/tt-dfd/rtl/trace/dfd_trace_mem_sink_generic.sv% 80',
                       "-rule"=>'"W287a"',
                       "-comment"=>'"RTL_PRAGMA: Waiver pragma in HDL source"',
                       "violations_waived"=>'8183 8190 8197 8204 8211 8218 8225 8232',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"lint/tt_dfd/dfd_top/lint/lint_rtl/spyglass_spysch/waiver/pragma2Waiver.swl"',
                       "waiverline"=>'13'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'8',
                       "waiverCmd"=>'q%waive -file_line "/proj_risc/user_dev/joeychen/projects/tt-dfd/rtl/trace/dfd_trace_mem_sink_generic.sv" 81 -rule "W287a" -comment "RTL_PRAGMA: Waiver pragma in HDL source"%',
                       "-file_line"=>'q%/proj_risc/user_dev/joeychen/projects/tt-dfd/rtl/trace/dfd_trace_mem_sink_generic.sv% 81',
                       "-rule"=>'"W287a"',
                       "-comment"=>'"RTL_PRAGMA: Waiver pragma in HDL source"',
                       "violations_waived"=>'8184 8191 8198 8205 8212 8219 8226 8233',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"lint/tt_dfd/dfd_top/lint/lint_rtl/spyglass_spysch/waiver/pragma2Waiver.swl"',
                       "waiverline"=>'14'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'9',
                       "waiverCmd"=>'q%waive -file_line "/proj_risc/user_dev/joeychen/projects/tt-dfd/rtl/trace/dfd_trace_mem_sink_generic.sv" 82 -rule "W287a" -comment "RTL_PRAGMA: Waiver pragma in HDL source"%',
                       "-file_line"=>'q%/proj_risc/user_dev/joeychen/projects/tt-dfd/rtl/trace/dfd_trace_mem_sink_generic.sv% 82',
                       "-rule"=>'"W287a"',
                       "-comment"=>'"RTL_PRAGMA: Waiver pragma in HDL source"',
                       "violations_waived"=>'8185 8192 8199 8206 8213 8220 8227 8234',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"lint/tt_dfd/dfd_top/lint/lint_rtl/spyglass_spysch/waiver/pragma2Waiver.swl"',
                       "waiverline"=>'15'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'10',
                       "waiverCmd"=>'q%waive -file_line "/proj_risc/user_dev/joeychen/projects/tt-dfd/rtl/trace/dfd_trace_mem_sink_generic.sv" 83 -rule "W287a" -comment "RTL_PRAGMA: Waiver pragma in HDL source"%',
                       "-file_line"=>'q%/proj_risc/user_dev/joeychen/projects/tt-dfd/rtl/trace/dfd_trace_mem_sink_generic.sv% 83',
                       "-rule"=>'"W287a"',
                       "-comment"=>'"RTL_PRAGMA: Waiver pragma in HDL source"',
                       "violations_waived"=>'8186 8193 8200 8207 8214 8221 8228 8235',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"lint/tt_dfd/dfd_top/lint/lint_rtl/spyglass_spysch/waiver/pragma2Waiver.swl"',
                       "waiverline"=>'16'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'11',
                       "waiverCmd"=>'q%waive -file_line "/proj_risc/user_dev/joeychen/projects/tt-dfd/rtl/trace/dfd_trace_mem_sink_generic.sv" 84 -rule "W287a" -comment "RTL_PRAGMA: Waiver pragma in HDL source"%',
                       "-file_line"=>'q%/proj_risc/user_dev/joeychen/projects/tt-dfd/rtl/trace/dfd_trace_mem_sink_generic.sv% 84',
                       "-rule"=>'"W287a"',
                       "-comment"=>'"RTL_PRAGMA: Waiver pragma in HDL source"',
                       "violations_waived"=>'8187 8194 8201 8208 8215 8222 8229 8236',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"lint/tt_dfd/dfd_top/lint/lint_rtl/spyglass_spysch/waiver/pragma2Waiver.swl"',
                       "waiverline"=>'17'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'12',
                       "waiverCmd"=>'q%waive -file_line "/proj_risc/user_dev/joeychen/projects/tt-dfd/rtl/trace/dfd_trace_mem_sink_generic.sv" 85 -rule "W287a" -comment "RTL_PRAGMA: Waiver pragma in HDL source"%',
                       "-file_line"=>'q%/proj_risc/user_dev/joeychen/projects/tt-dfd/rtl/trace/dfd_trace_mem_sink_generic.sv% 85',
                       "-rule"=>'"W287a"',
                       "-comment"=>'"RTL_PRAGMA: Waiver pragma in HDL source"',
                       "violations_waived"=>'8188 8195 8202 8209 8216 8223 8230 8237',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"lint/tt_dfd/dfd_top/lint/lint_rtl/spyglass_spysch/waiver/pragma2Waiver.swl"',
                       "waiverline"=>'18'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'13',
                       "waiverCmd"=>'q%waive -file_line "/proj_risc/user_dev/joeychen/projects/tt-dfd/rtl/trace/dfd_trace_mem_sink_generic.sv" 86 -rule "W287a" -comment "RTL_PRAGMA: Waiver pragma in HDL source"%',
                       "-file_line"=>'q%/proj_risc/user_dev/joeychen/projects/tt-dfd/rtl/trace/dfd_trace_mem_sink_generic.sv% 86',
                       "-rule"=>'"W287a"',
                       "-comment"=>'"RTL_PRAGMA: Waiver pragma in HDL source"',
                       "violations_waived"=>'',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"lint/tt_dfd/dfd_top/lint/lint_rtl/spyglass_spysch/waiver/pragma2Waiver.swl"',
                       "waiverline"=>'19'
                      );

spyWaiversDataCount("totalWaivers"=>'13',
"totalWaiversApplied"=>'13',
"totalWaiversWithRegExp"=>'3',
"totalWaiversWithRuleSpecified"=>'13',
"totalWaiversWithIpSpecified"=>'0',
"totalWaiversWithFileLine"=>'13',
                         );

spyProhibitWaiverRules(                         );

spySetWaivedViolationNumberHash("");

1;
