set_option language_mode mixed
set_option designread_enable_synthesis no
set_option designread_disable_flatten no
set_option enableSV yes
set_option enableSV09 yes
set_option active_methodology $SPYGLASS_HOME/GuideWare/latest/block/rtl_handoff
set_option report_incr_messages no
set_parameter handle_large_bus yes


# Increase the threshold for memory size
set_option mthresh 65536

# Enabled better memory abstraction to avoid increasing mthresh
set_option handlememory yes

set_option ignorerules NoGenLabel-ML
set_option ignorerules W443
set_option ignorerules NoAssignX-ML
set_option ignorerules ReserveName
set_option ignorerules STARC05-1.1.1.1
set_option non_lrm_options allow_assert_final

set_option ignorerules SYNTH_5064
set_option ignorerules STARC-2.3.4.3

set_option overloadrules WRN_70+severity=Error
set_option overloadrules SYNTH_5058+severity=Error

set_option overloadrules STARC05-1.3.1.3+severity=Info
set_option overloadrules W240+severity=Info
set_option overloadrules SGDCWRN_129+severity=Info
set_option overloadrules W401+severity=Info
set_option overloadrules W415a+severity=Info
set_option overloadrules W528+severity=Info
set_option overloadrules W287b+severity=Info
