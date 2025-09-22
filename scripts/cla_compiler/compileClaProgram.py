# SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
# SPDX-License-Identifier: Apache-2.0

import os
import sys
import yaml
import json
import logging
from enum import Enum
import re
import argparse
import shutil
import math
import traceback


###################################
# Global vars
###################################
g_program_version = "1.1.0"


def getLogger(name, console="WARNING", outputdir="", logFile=True, fileLevel="DEBUG"):
	'''
	Returns logger object
	'''

	#Make sure output dir exists
	outputHier = os.path.normpath(outputdir)
	outputHierList = outputHier.split(os.sep)
	currentPath = ""
	for folder in outputHierList:
		currentPath = os.path.join(currentPath, folder)
		if not (os.path.exists(currentPath)):
			os.mkdir(currentPath)

	#Instantiate logger
	logger = logging.getLogger(name)
	logger.setLevel(logging.DEBUG)

	# create file handler which logs even debug messages
	fh = None
	if (logFile):
		logPath = os.path.join(outputdir, "{}".format(name).replace(":", "_"))
		fh = logging.FileHandler(logPath, mode="w")
		fh.setLevel(logging.DEBUG)
		if (fileLevel=="CRITICAL"):
			fh.setLevel(logging.CRITICAL)
		if (fileLevel=="ERROR"):
			fh.setLevel(logging.ERROR)
		if (fileLevel=="WARNING"):
			fh.setLevel(logging.WARNING)
		if (fileLevel=="INFO"):
			fh.setLevel(logging.INFO)
		if (fileLevel=="DEBUG"):
			fh.setLevel(logging.DEBUG)

	# create console handler with a higher log level
	ch = logging.StreamHandler()
	ch.setLevel(logging.INFO)
	if (console=="CRITICAL"):
		ch.setLevel(logging.CRITICAL)
	if (console=="ERROR"):
		ch.setLevel(logging.ERROR)
	if (console=="WARNING"):
		ch.setLevel(logging.WARNING)
	if (console=="INFO"):
		ch.setLevel(logging.INFO)
	if (console=="DEBUG"):
		ch.setLevel(logging.DEBUG)

	# create formatter and add it to the handlers
	formatter = logging.Formatter('(%(asctime)s) %(levelname)s: compileClaProgram(v{}): %(message)s'.format(g_program_version), datefmt='%H:%M:%S')
	if (logFile):
		fh.setFormatter(formatter)
	ch.setFormatter(formatter)

	# add the handlers to the logger
	if (logFile):
		logger.addHandler(fh)
	logger.addHandler(ch)

	return logger

g_logger = None

g_debugSignals = {}
g_debugMuxes = {}
g_busConfigProvided = False
g_claCounterAliases = []

g_claDebugInputWidth = 64
g_availableMatchRegs = 4
g_availableCounters = 4
g_availableEdgeDetects = 2
g_availableTransitionDetects = 1
g_availableCountOneRegs = 1
g_availableAnyChangeRegs = 1
g_availableNodes = 4
g_availableEventsPerEap = 3
g_availableEapsPerNode = 4
g_availableActionsPerEap = 4
g_availableCustomActionsPerEap = 2
g_logicalOpcodes = {
  "OR": 0x0,
  "NOR": 0x3,
  "AND": 0x1,
  "NONE": 0x2
}
g_actionOpcodes = {
  "NULL": 0x0,
  "CLOCK_HALT": 0x1,
  "DEBUG_INTERRUPT": 0x2,
  "TOGGLE_GPIO": 0x3,
  "START_TRACE": 0x4,
  "STOP_TRACE": 0x5,
  "TRACE_PULSE": 0x6,
  "CROSS_TRIGGER_0": 0x7,
  "CROSS_TRIGGER_1": 0x8,
  "XTRIGGER_0": 0x7,
  "XTRIGGER_1": 0x8,
  "INCREMENT_COUNTER_0": 0x10,
  "CLEAR_COUNTER_0": 0x11,
  "AUTO_INCREMENT_COUNTER_0": 0x12,
  "STOP_AUTO_INCREMENT_COUNTER_0": 0x13,
  "INCREMENT_COUNTER_1": 0x14,
  "CLEAR_COUNTER_1": 0x15,
  "AUTO_INCREMENT_COUNTER_1": 0x16,
  "STOP_AUTO_INCREMENT_COUNTER_1": 0x17,
  "INCREMENT_COUNTER_2": 0x18,
  "CLEAR_COUNTER_2": 0x19,
  "AUTO_INCREMENT_COUNTER_2": 0x1a,
  "STOP_AUTO_INCREMENT_COUNTER_2": 0x1b,
  "INCREMENT_COUNTER_3": 0x1c,
  "CLEAR_COUNTER_3": 0x1d,
  "AUTO_INCREMENT_COUNTER_3": 0x1e,
  "STOP_AUTO_INCREMENT_COUNTER_3": 0x1f
}
g_customActionOpcodes = {}
g_eventOpcodes = {
  "DISABLE": 0x0,
  "ALWAYS_ON": 0x1,
  "MATCH_0": 0x2,
  "NOT_MATCH_0": 0x3,
  "MATCH_1": 0x4,
  "NOT_MATCH_1": 0x5,
  "EDGE_DETECT_0": 0x6,
  "EDGE_DETECT_1": 0x7,
  "TRANSITION": 0x8,
  "XTRIGGER_0": 0x9,
  "XTRIGGER_1": 0xa,
  "ONES_COUNT": 0xb,
  "DEBUG_SIGNALS_CHANGE": 0xc,
  "PERIOD_TICK": 0xd,
  "COUNTER_0_EQUAL_TARGET": 0x10,
  "COUNTER_0_GREATER_TARGET": 0x11,
  "COUNTER_0_LESS_TARGET": 0x12,
  "COUNTER_1_EQUAL_TARGET": 0x13,
  "COUNTER_1_GREATER_TARGET": 0x14,
  "COUNTER_1_LESS_TARGET": 0x15,
  "COUNTER_2_EQUAL_TARGET": 0x16,
  "COUNTER_2_GREATER_TARGET": 0x17,
  "COUNTER_2_LESS_TARGET": 0x18,
  "COUNTER_3_EQUAL_TARGET": 0x19,
  "COUNTER_3_GREATER_TARGET": 0x1a,
  "COUNTER_3_LESS_TARGET": 0x1b,
  "MATCH_2": 0x1c,
  "NOT_MATCH_2": 0x1d,
  "MATCH_3": 0x1e,
  "NOT_MATCH_3": 0x1f
}

g_eap_keywords = [
  "debug_mux_reg",
  "event_triggers",
  "event_logical_op",
  "actions",
  "custom_actions",
  "snapshot_signals",
  "next_state_node"
]

###################################
# Misc Helper Functions
###################################
def str2int(valueStr):
  if isinstance(valueStr, int):
    return valueStr

  valueBase = 10
  if (len(valueStr) > 3):
    if (valueStr[0:2] == "0x"):
      valueBase = 16

  valueStr = valueStr.replace("0x", "0x0")
  value = int(valueStr, valueBase)
  return value

def getBinaryList(value, width=None):
  blist = [int(x) for x in bin(value)[2:]]
  if not (width is None):
    bLength = len(blist)
    if (bLength > width):
      raise ValueError("Specified width {} is smaller than required width {} for value={}".format(width, len(blist), value))
    elif (bLength < width):
      blist = [0 for i in range(width-bLength)] + blist

  return blist

###################################
# Program Parsing
###################################
class TRIGGER_TYPE(Enum):
  ALWAYS = 1
  EQUAL = 2
  NOT_EQUAL = 3
  GREATER = 4
  LESS = 5
  POSEDGE = 6
  NEGEDGE = 7
  XTRIGGER_0 = 8
  XTRIGGER_1 = 9
  ANY_CHANGE = 10
  TRANSITION = 11
  COUNT_ONES = 12
  PERIOD_TICK = 13

class TriggerCondition:
  def __init__ (self, parentEventTrigger, conditionStr):
    self.parentEventTrigger = parentEventTrigger

    if not isinstance(conditionStr, str):
      g_logger.error("Non-string trigger condition defined for \"{}.{}.{}\"".format(self.parentEventTrigger.parentEap.parentNode.name, self.parentEventTrigger.parentEap.name, self.parentEventTrigger.name))
      sys.exit()

    self.conditionStr = conditionStr
    self.type, self.signal, self.value, self.from_value = self.parseCondition(conditionStr)

  def __str__(self):
    return "type={}, signal={}, value={}".format(self.type, self.signal, self.value)

  def parseCondition(self, conditionStr):
    g_logger.debug("Parsing TriggerCondition \"{}\" in event {}.{}.{}".format(conditionStr, self.parentEventTrigger.parentEap.parentNode.name, self.parentEventTrigger.parentEap.name, self.parentEventTrigger.name))
    triggerType = None
    signal = None
    value = None
    from_value = None
    unsuportedCondition = False

    #Equals
    if ("==" in conditionStr):
      triggerType = TRIGGER_TYPE.EQUAL
      #Parse operands
      operandList = conditionStr.split("==")
      if (len(operandList) != 2):
        g_logger.error("Invalid expression \"{}\" defined for event \"{}.{}.{}\"".format(conditionStr, self.parentEventTrigger.parentEap.parentNode.name, self.parentEventTrigger.parentEap.name, self.parentEventTrigger.name))
        sys.exit()
      #Get signal name
      signal = operandList[0].strip()
      #Get comparison value
      value = operandList[1].strip()
      try:
        value = str2int(value)
      except:
        g_logger.error("Could not convert RHS of \"{}\" into a numerical value in \"{}.{}.{}\"".format(conditionStr, self.parentEventTrigger.parentEap.parentNode.name, self.parentEventTrigger.parentEap.name, self.parentEventTrigger.name))
        sys.exit()
      
    #Not equals
    if ("!=" in conditionStr):
      triggerType = TRIGGER_TYPE.NOT_EQUAL
      #Parse operands
      operandList = conditionStr.split("!=")
      if (len(operandList) != 2):
        g_logger.error("Invalid expression \"{}\" defined for event \"{}.{}.{}\"".format(conditionStr, self.parentEventTrigger.parentEap.parentNode.name, self.parentEventTrigger.parentEap.name, self.parentEventTrigger.name))
        sys.exit()
      #Get signal name
      signal = operandList[0].strip()
      if (signal in g_claCounterAliases):
        g_logger.error("Invalid condition \"{}\" defined for event \"{}.{}.{}\"".format(conditionStr, self.parentEventTrigger.parentEap.parentNode.name, self.parentEventTrigger.parentEap.name, self.parentEventTrigger.name))
        g_logger.error("Not equals comparison not supported for CLA counters")
        sys.exit()
      #Get comparison value
      value = operandList[1].strip()
      try:
        value = str2int(value)
      except:
        g_logger.error("Could not convert RHS of \"{}\" into a numerical value in event \"{}.{}.{}\"".format(conditionStr, self.parentEventTrigger.parentEap.parentNode.name, self.parentEventTrigger.parentEap.name, self.parentEventTrigger.name))
        sys.exit()

    #Greater than
    if (">" in conditionStr):
      triggerType = TRIGGER_TYPE.GREATER
      #Check operation
      if (">=" in conditionStr):
        unsuportedCondition = True
      #Parse operands
      operandList = conditionStr.split(">")
      if (len(operandList) != 2):
        g_logger.error("Invalid expression \"{}\" defined for event \"{}.{}.{}\"".format(conditionStr, self.parentEventTrigger.parentEap.parentNode.name, self.parentEventTrigger.parentEap.name, self.parentEventTrigger.name))
        sys.exit()
      #Get signal name
      signal = operandList[0].strip()
      if not (signal in g_claCounterAliases):
        g_logger.error("Invalid condition \"{}\" defined for event \"{}.{}.{}\"".format(conditionStr, self.parentEventTrigger.parentEap.parentNode.name, self.parentEventTrigger.parentEap.name, self.parentEventTrigger.name))
        g_logger.error("Greater than comparison only supported for CLA counters. \"{}\" not found in the program counters list {}".format(signal, g_claCounterAliases))
        sys.exit()
      #Get comparison value
      value = operandList[1].strip()
      try:
        value = str2int(value)
      except:
        g_logger.error("Could not convert RHS of \"{}\" into a numerical value in event \"{}.{}.{}\"".format(conditionStr, self.parentEventTrigger.parentEap.parentNode.name, self.parentEventTrigger.parentEap.name, self.parentEventTrigger.name))
        sys.exit()

    #Less than
    if ("<" in conditionStr):
      triggerType = TRIGGER_TYPE.LESS
      #Check operation
      if ("<=" in conditionStr):
        unsuportedCondition = True
      #Parse operands
      operandList = conditionStr.split("<")
      if (len(operandList) != 2):
        g_logger.error("Invalid expression \"{}\" defined for event \"{}.{}.{}\"".format(conditionStr, self.parentEventTrigger.parentEap.parentNode.name, self.parentEventTrigger.parentEap.name, self.parentEventTrigger.name))
        sys.exit()
      #Get signal name
      signal = operandList[0].strip()
      if not (signal in g_claCounterAliases):
        g_logger.error("Invalid condition \"{}\" defined for event \"{}.{}.{}\"".format(conditionStr, self.parentEventTrigger.parentEap.parentNode.name, self.parentEventTrigger.parentEap.name, self.parentEventTrigger.name))
        g_logger.error("Greater than comparison only supported for CLA counters. \"{}\" not found in the program counters list {}".format(signal, g_claCounterAliases))
        sys.exit()
      #Get comparison value
      value = operandList[1].strip()
      try:
        value = str2int(value)
      except:
        g_logger.error("Could not convert RHS of \"{}\" into a numerical value in event \"{}.{}.{}\"".format(conditionStr, self.parentEventTrigger.parentEap.parentNode.name, self.parentEventTrigger.parentEap.name, self.parentEventTrigger.name))
        sys.exit()

    #Posedge
    if (re.search(r"posedge\s", conditionStr)):
      triggerType = TRIGGER_TYPE.POSEDGE
      #Get signal name
      signal = conditionStr[conditionStr.find("posedge")+len("posedge"):].strip()
      if (len(signal) < 1):
        g_logger.error("Signal name not found in condition \"{}\" defined for event \"{}.{}.{}\"".format(conditionStr, self.parentEventTrigger.parentEap.parentNode.name, self.parentEventTrigger.parentEap.name, self.parentEventTrigger.name))
        sys.exit()

    #Negedge
    if (re.search(r"negedge\s", conditionStr)):
      triggerType = TRIGGER_TYPE.NEGEDGE
      #Get signal name
      signal = conditionStr[conditionStr.find("negedge")+len("negedge"):].strip()

    #External triggers
    if ("XTRIGGER_0" in conditionStr):
      triggerType = TRIGGER_TYPE.XTRIGGER_0

    if ("XTRIGGER_1" in conditionStr):
      triggerType = TRIGGER_TYPE.XTRIGGER_1

    #Always on
    if ("ALWAYS_ON" in conditionStr):
      triggerType = TRIGGER_TYPE.ALWAYS

    #Period tick
    if ("PERIOD_TICK" in conditionStr):
      triggerType = TRIGGER_TYPE.PERIOD_TICK

    #Any change
    if (re.search(r"anychange\s*\(", conditionStr)):
      triggerType = TRIGGER_TYPE.ANY_CHANGE

      #Get signal name
      try:
        signal = conditionStr[conditionStr.find("(")+1:conditionStr.find(")")].strip()
        if (len(signal) < 1):
          g_logger.error("Signal name not found in condition \"{}\" defined for event \"{}.{}.{}\"".format(conditionStr, self.parentEventTrigger.parentEap.parentNode.name, self.parentEventTrigger.parentEap.name, self.parentEventTrigger.name))
          sys.exit()
        if (len(signal.split(",")) > 1):
          g_logger.error("{} arguments \"{}\" defined for anychange trigger in event \"{}.{}.{}\". Only one argument expected".format(len(signal.split(",")), conditionStr, self.parentEventTrigger.parentEap.parentNode.name, self.parentEventTrigger.parentEap.name, self.parentEventTrigger.name))
          sys.exit()
      except:
        g_logger.error("Could not parse anychange condition \"{}\" defined for event \"{}.{}.{}\"".format(conditionStr, self.parentEventTrigger.parentEap.parentNode.name, self.parentEventTrigger.parentEap.name, self.parentEventTrigger.name))
        sys.exit()

    #Transition
    if (re.search(r"transition\s*\(", conditionStr)):
      triggerType = TRIGGER_TYPE.TRANSITION
      #Parse transition args
      try:
        transitionArgs = conditionStr[conditionStr.find("(")+1:conditionStr.find(")")].strip().split(",")
        if (len(transitionArgs) != 3):
          g_logger.error("Could not parse transition condition \"{}\" defined for event \"{}.{}.{}\". 3 transition arguments required, only {} provided".format(conditionStr, self.parentEventTrigger.parentEap.parentNode.name, self.parentEventTrigger.parentEap.name, self.parentEventTrigger.name, len(transitionArgs)))
          sys.exit()

        #Get signal name
        signal = transitionArgs[0].strip()
        if (len(signal) < 1):
          g_logger.error("Signal name not found in condition \"{}\" defined for event \"{}.{}.{}\"".format(conditionStr, self.parentEventTrigger.parentEap.parentNode.name, self.parentEventTrigger.parentEap.name, self.parentEventTrigger.name))
          sys.exit()

        #Get transition values
        try:
          from_value = str2int(transitionArgs[1].strip())
          value = str2int(transitionArgs[2].strip())
        except:
          g_logger.error("Invalid value defined for transition condition \"{}\" in event \"{}.{}.{}\"".format(conditionStr, self.parentEventTrigger.parentEap.parentNode.name, self.parentEventTrigger.parentEap.name, self.parentEventTrigger.name))
          sys.exit()
      except:
        g_logger.error("Could not parse transition condition \"{}\" defined for event \"{}.{}.{}\"".format(conditionStr, self.parentEventTrigger.parentEap.parentNode.name, self.parentEventTrigger.parentEap.name, self.parentEventTrigger.name))
        sys.exit()

    #Count ones
    if (re.search(r"countones\s*\(", conditionStr)):
      triggerType = TRIGGER_TYPE.COUNT_ONES
      #Parse operands
      operandList = conditionStr.split("==")
      if (len(operandList) != 2):
        g_logger.error("Invalid expression \"{}\" defined for event \"{}.{}.{}\"".format(conditionStr, self.parentEventTrigger.parentEap.parentNode.name, self.parentEventTrigger.parentEap.name, self.parentEventTrigger.name))
        sys.exit()

      #Get comparison value
      value = operandList[1].strip()
      try:
        value = str2int(value)
      except:
        g_logger.error("Could not convert RHS of \"{}\" into a numerical value in event \"{}.{}.{}\"".format(conditionStr, self.parentEventTrigger.parentEap.parentNode.name, self.parentEventTrigger.parentEap.name, self.parentEventTrigger.name))
        sys.exit()

      #Get signal name
      #TODO: Add support for multiple signals?
      try:
        signal = conditionStr[conditionStr.find("(")+1:conditionStr.find(")")].strip()
        if (len(signal) < 1):
          g_logger.error("Signal name not found in condition \"{}\" defined for event \"{}.{}.{}\"".format(conditionStr, self.parentEventTrigger.parentEap.parentNode.name, self.parentEventTrigger.parentEap.name, self.parentEventTrigger.name))
          sys.exit()
        if (len(signal.split(",")) > 1):
          g_logger.error("{} arguments \"{}\" defined for count ones trigger in event \"{}.{}.{}\". Only one argument expected".format(len(signal.split(",")), conditionStr, self.parentEventTrigger.parentEap.parentNode.name, self.parentEventTrigger.parentEap.name, self.parentEventTrigger.name))
          sys.exit()
      except:
        g_logger.error("Could not parse count ones condition \"{}\" defined for event \"{}.{}.{}\"".format(conditionStr, self.parentEventTrigger.parentEap.parentNode.name, self.parentEventTrigger.parentEap.name, self.parentEventTrigger.name))
        sys.exit()

    #Unsupported
    if ((triggerType is None) or unsuportedCondition):
      g_logger.error("Unsupported or invalid condition \"{}\" defined for event \"{}.{}.{}\"".format(conditionStr, self.parentEventTrigger.parentEap.parentNode.name, self.parentEventTrigger.parentEap.name, self.parentEventTrigger.name))
      sys.exit()

    return triggerType, signal, value, from_value

  def getHash(self):
    return hash("{}.{}.{}".format(self.type, self.signal, self.value))

  def generateComment(self):
    if (self.type == TRIGGER_TYPE.ALWAYS):
      return "(ALWAYS)"
    if (self.type == TRIGGER_TYPE.PERIOD_TICK):
      return "(PERIOD_TICK)"
    if (self.type == TRIGGER_TYPE.EQUAL):
      return "({} == {})".format(self.signal, self.value)
    if (self.type == TRIGGER_TYPE.NOT_EQUAL):
      return "({} != {})".format(self.signal, self.value)
    if (self.type == TRIGGER_TYPE.GREATER):
      return "({} > {})".format(self.signal, self.value)
    if (self.type == TRIGGER_TYPE.LESS):
      return "({} < {})".format(self.signal, self.value)
    if (self.type == TRIGGER_TYPE.POSEDGE):
      return "(posedge {})".format(self.signal)
    if (self.type == TRIGGER_TYPE.NEGEDGE):
      return "(negedge {})".format(self.signal)
    if (self.type == TRIGGER_TYPE.XTRIGGER_0):
      return "(XTRIGGER_0)"
    if (self.type == TRIGGER_TYPE.XTRIGGER_1):
      return "(XTRIGGER_1)"
    if (self.type == TRIGGER_TYPE.ANY_CHANGE):
      return "(anychange({}))".format(self.signal)
    if (self.type == TRIGGER_TYPE.TRANSITION):
      return "(transition({},{},{}))".format(self.signal, self.from_value, self.value)
    if (self.type == TRIGGER_TYPE.COUNT_ONES):
      return "(countones({}) == {})".format(self.signal, self.value)

class EventTrigger:
  def __init__ (self, parentEap, eventName, triggerList):
    g_logger.debug("Constructing EventTrigger {}.{}.{}".format(parentEap.parentNode.name, parentEap.name, eventName))
    self.name = eventName
    self.parentEap = parentEap

    self.triggerConditions = self.extractTriggerConditions(triggerList)

  def extractTriggerConditions(self, triggerList):
    if (not isinstance(triggerList, list)) and (not isinstance(triggerList, str)):
      g_logger.error("Triggers for event \"{}.{}.{}\" not defined as a list or string".format(self.parentEap.parentNode.name, self.parentEap.name, self.name))
      sys.exit()

    triggerConditions = []
    if isinstance(triggerList, str):
      triggerConditions.append(TriggerCondition(self, triggerList))
    else:
      for conditionStr in triggerList:
        triggerConditions.append(TriggerCondition(self, conditionStr))

    #Make sure there are not conflicts with multiple trigger types
    triggerTypes = {}
    for triggerCondition in triggerConditions:
      if not (triggerCondition.type in triggerTypes):
        triggerTypes[triggerCondition.type] = []
      triggerTypes[triggerCondition.type].append(triggerCondition)

    triggerSignalCounter = False
    triggerSignalMux = False
    for triggerCondition in triggerConditions:
      triggerSignalCounter = triggerSignalCounter or (triggerCondition.signal in g_claCounterAliases)
      triggerSignalMux = triggerSignalMux or (not (triggerCondition.signal in g_claCounterAliases))
    eventTypeConflict = triggerSignalCounter and triggerSignalMux

    if (len(triggerTypes) > 1) or eventTypeConflict:
      g_logger.error("Multiple event types {} implied by trigger conditions for event \"{}.{}.{}\"".format(list(triggerTypes.keys()), self.parentEap.parentNode.name, self.parentEap.name, self.name))
      sys.exit()

    for triggerType in triggerTypes:
      if ((triggerType != TRIGGER_TYPE.EQUAL) and (triggerType != TRIGGER_TYPE.TRANSITION) and (triggerType != TRIGGER_TYPE.ANY_CHANGE)) and (len(triggerTypes[triggerType]) > 1):
        g_logger.error("Multiple cases not supported by {} for event \"{}.{}.{}\"".format(triggerType, self.parentEap.parentNode.name, self.parentEap.name, self.name))
        sys.exit()
      
    return triggerConditions

  def getHash(self):
    selfHashList = list(set([trigger.getHash() for trigger in self.triggerConditions]))
    selfHashList.sort()

    return hash("{}".format(selfHashList))

  def __eq__(self, other):
    selfHashSet = set([trigger.getHash() for trigger in self.triggerConditions])
    otherHashSet = set([trigger.getHash() for trigger in other.triggerConditions])

    return (selfHashSet == otherHashSet)

  def generateComment(self):
    commentList = [trigger.generateComment() for trigger in self.triggerConditions]
    if (self.triggerConditions[0].type == TRIGGER_TYPE.ANY_CHANGE):
      commentStr = " | ".join(commentList)
    else:
      commentStr = " & ".join(commentList)
    return commentStr
    

class EventActionPair:
  def __init__ (self, parentNode, eapName, eapDict):
    g_logger.debug("Constructing EventActionPair {}.{}".format(parentNode.name, eapName))
    self.name = eapName
    self.parentNode = parentNode
    self.eapDict = eapDict

    eapFieldsUsed = eapDict.keys()
    for fieldName in eapFieldsUsed:
      if not (fieldName in g_eap_keywords):
        g_logger.warning("Unrecognized EAP field \"{}\" defined for EventActionPair {}.{}. This likely indicates a whitespace issue in the CLA source program".format(fieldName, parentNode.name, eapName))
        g_logger.warning("Ignoring EAP field \"{}\" defined for EventActionPair {}.{}.".format(fieldName, parentNode.name, eapName))

    self.debug_mux_reg = self.extractDebugMux(eapDict)
    self.event_triggers = self.extractEventTriggers(eapDict)
    self.event_indexes = self.assignEventIndexes(self.event_triggers)
    self.event_logical_op = self.extractLogicalOp(eapDict)
    self.actions = self.extractActions(eapDict)
    self.custom_actions = self.extractCustomActions(eapDict)
    self.snapshot_signals = self.extractSnapshotSignals(eapDict)
    self.next_state_node = self.extractNextNode(eapDict)

  def extractDebugMux(self, eapDict):
    g_logger.debug("Extracting debug mux for EventActionPair {}.{}".format(self.parentNode, self.name))
    if not ("debug_mux_reg" in eapDict):
      g_logger.info("Optional field \"debug_mux_reg\" not defined for EAP \"{}.{}\". Will attempt to use default CSR".format(self.parentNode.name, self.name))
      return None

    debug_mux_reg = eapDict["debug_mux_reg"]
    if not isinstance(debug_mux_reg, str):
      g_logger.error("\"{}.{}\" Field \"debug_mux_reg\" must be a string".format(self.parentNode.name, self.name))
      sys.exit()

    return debug_mux_reg

  def extractEventTriggers(self, eapDict):
    g_logger.debug("Extracting event triggers for EventActionPair {}.{}".format(self.parentNode.name, self.name))
    event_triggers = {}
    if not ("event_triggers" in eapDict):
      return event_triggers

    if not isinstance(eapDict["event_triggers"], dict):
      g_logger.error("Field \"event_triggers\" must be a dict")
      sys.exit()

    #Check for keywords in event names for possible whitespace issues
    eventNameList = eapDict["event_triggers"].keys()
    g_logger.debug("Event names = {}".format(eventNameList))
    for eventName in eventNameList:
      if (eventName in g_eap_keywords):
        g_logger.warning("EAP keyword \"{}\" defined as an event trigger name inside {}.{}.event_triggers. This likely indicates a whitespace issue in the CLA source program".format(eventName, self.parentNode.name, self.name))

    for eventName in eapDict["event_triggers"]:
      if (eventName in event_triggers):
        g_logger.error("Event \"{}\" already defined for  \"{}.{}\"".format(eventName, self.parentNode.name, self.name))
        sys.exit()

      if (len(event_triggers) >= g_availableEventsPerEap):
        g_logger.error("More than {} events defined for  \"{}.{}\"".format(g_availableEventsPerEap, self.parentNode.name, self.name))
        sys.exit()

      event_triggers[eventName] = EventTrigger(self, eventName, eapDict["event_triggers"][eventName])

    return event_triggers

  def assignEventIndexes(self, event_triggers):
    g_logger.debug("Assigning event indexes for EventActionPair {}.{}".format(self.parentNode.name, self.name))
    event_indexes = {}
    eventIndx = 0
    for eventName in event_triggers:
      event_indexes[eventName] = eventIndx
      eventIndx += 1

    g_logger.debug("Event indexes for EventActionPair {}.{} = {}".format(self.parentNode.name, self.name, event_indexes))

    return event_indexes

  def extractLogicalOp(self, eapDict):
    g_logger.debug("Extracting logical op for EventActionPair {}.{}".format(self.parentNode.name, self.name))
    if not ("event_logical_op" in eapDict):
      g_logger.error("Required field \"event_logical_op\" not defined for EAP \"{}.{}\"".format(self.parentNode.name, self.name))
      sys.exit()

    event_logical_op = eapDict["event_logical_op"]
    if not isinstance(event_logical_op, str):
      g_logger.error("\"{}.{}\" Field \"event_logical_op\" must be a string".format(self.parentNode.name, self.name))
      sys.exit()

    event_logical_op = event_logical_op.strip()
    if (event_logical_op in g_logicalOpcodes):
      g_logger.error("Deprecated logical opcode \"{}\" defined for \"{}.{}\". Logical opcodes are no longer supported. Use a logical expression instead".format(event_logical_op, self.parentNode.name, self.name))
      sys.exit()

    return event_logical_op

  def extractActions(self, eapDict):
    g_logger.debug("Extracting actions for EventActionPair {}.{}".format(self.parentNode.name, self.name))
    actions = []
    if ("actions" in eapDict):
      actions = eapDict["actions"]

    if not isinstance(actions, list):
      g_logger.error("\"{}.{}\" Field \"actions\" must be a list".format(self.parentNode.name, self.name))
      sys.exit()

    if (len(actions) > g_availableActionsPerEap):
      g_logger.error("More than {} actions defined for \"{}.{}\"".format(g_availableActionsPerEap, self.parentNode.name, self.name))
      sys.exit()

    return actions

  def extractCustomActions(self, eapDict):
    g_logger.debug("Extracting custom actions for EventActionPair {}.{}".format(self.parentNode.name, self.name))
    custom_actions = []
    if ("custom_actions" in eapDict):
      custom_actions = eapDict["custom_actions"]

    if not isinstance(custom_actions, list):
      g_logger.error("\"{}.{}\" Field \"custom_actions\" must be a list".format(self.parentNode.name, self.name))
      sys.exit()

    if (len(custom_actions) > g_availableCustomActionsPerEap):
      g_logger.error("More than {} custom actions defined for \"{}.{}\"".format(g_availableCustomActionsPerEap, self.parentNode.name, self.name))
      sys.exit()

    return custom_actions

  def extractSnapshotSignals(self, eapDict):
    g_logger.debug("Extracting snapshot signals for EventActionPair {}.{}".format(self.parentNode.name, self.name))
    snapshot_signals = []
    if ("snapshot_signals" in eapDict):
      snapshot_signals = eapDict["snapshot_signals"]

    if not isinstance(snapshot_signals, list):
      g_logger.error("\"{}.{}\" Field \"snapshot_signals\" must be a list".format(self.parentNode.name, self.name))
      sys.exit()

    return snapshot_signals

  def extractNextNode(self, eapDict):
    g_logger.debug("Extracting next node for EventActionPair {}.{}".format(self.parentNode.name, self.name))
    next_state_node = []
    if ("next_state_node" in eapDict):
      next_state_node = eapDict["next_state_node"]

    if not isinstance(next_state_node, str):
      g_logger.error("\"{}.{}\" Field \"next_state_node\" must be a string".format(self.parentNode.name, self.name))
      sys.exit()

    return next_state_node

class StateNode:
  def __init__ (self, nodeName, nodeDict):
    g_logger.debug("Constructing StateNode {}".format(nodeName))
    self.name = nodeName
    self.nodeDict = nodeDict

    self.eaps = {}
    for eapName in nodeDict:
      self.addEap(eapName, nodeDict[eapName])

  def addEap(self, eapName, eapDict):
    g_logger.debug("Adding EAP {} to StateNode {}".format(eapName, self.name))
    if (len(self.eaps) >= g_availableEapsPerNode):
      g_logger.error("More than {} event actions pairs defined for state node \"{}\"".format(g_availableEapsPerNode, self.name))
      sys.exit()
    if (eapName in self.eaps):
      g_logger.error("Event action pair \"{}\" already defined for state node \"{}\"".format(eapName, self.name))
      sys.exit()

    self.eaps[eapName] = EventActionPair(self, eapName, eapDict)

class DebugMux():
  def __init__ (self, instanceName, output_signalname, mux_select_csr, mux_id=0, lane_width=16, output_width=64, cla_input_signalname="", additional_output_stages=0):
    self.name = instanceName
    self.output = output_signalname
    self.output_cycle_delay = 1 + additional_output_stages

    self.final_mux = (output_signalname == cla_input_signalname)

    self.mux_select_csrs = None
    if (isinstance(mux_select_csr, list)):
      self.mux_select_csrs = [str(i).strip() for i in mux_select_csr]
    elif (isinstance(mux_select_csr, str) or isinstance(mux_select_csr, unicode)):
      self.mux_select_csrs = [str(mux_select_csr)]
    else:
      raise TypeError("Invalid mux_select_csr type \"{}\" defined for DebugMux".format(type(mux_select_csr)))
      
    self.mux_id = mux_id
    self.lane_width = int(lane_width)
    self.output_lanes = int(int(output_width)/int(lane_width))

    self.required_input_sigs = {}
    for csrName in self.mux_select_csrs:
      self.required_input_sigs[csrName] = []

    self.required_input_lanes = {}
    for csrName in self.mux_select_csrs:
      self.required_input_lanes[csrName] = []

    self.output_lane_mappings = {}
    for csrName in self.mux_select_csrs:
      self.output_lane_mappings[csrName] = [i for i in range(0, self.output_lanes)]

    self.output_signals = []

  def addRequiredInputSignal(self, signal_obj):
    csrName = signal_obj.muxsel_csr
    if (csrName is None):
      csrName = self.mux_select_csrs[0]

    if not (csrName in self.mux_select_csrs):
      g_logger.error("Specified CSR reg \"{}\" is not connected to mux instance \"{}\" needed for signal \"{}\". Connected csrs = {}. Check your CLA config file".format(csrName, self.name, signal_obj.name, self.mux_select_csrs, self.name))
      sys.exit()

    self.required_input_sigs[csrName].append(signal_obj)

  def calcReuiredInputLanes(self):
    #Reset output_lane_mappings in case this function is called multiple times 
    self.required_input_lanes = {}
    for csrName in self.mux_select_csrs:
      self.required_input_lanes[csrName] = []

    for csrName in self.required_input_sigs:
      lanes = []
      for dbmSignalObj in self.required_input_sigs[csrName]:
        lanes += dbmSignalObj.getLaneList()

      lanes = list(set(lanes))
      lanes.sort()
      if (len(lanes) > self.output_lanes):
        g_logger.error("Too many lanes used for debug mux \"{}\" CSR \"{}\". Up to {} lanes can be used at once, but selected signals require {} lanes : {}".format(self.name, csrName, self.output_lanes, len(lanes), lanes))
        listStr = "Selected signals: "
        for dbmSignalObj in self.required_input_sigs[csrName]:
          listStr += "\n{}".format(str(dbmSignalObj))
        g_logger.error(listStr)
        sys.exit()

      self.required_input_lanes[csrName] = lanes

  def allocateOutputLanes(self):
    #Reset output_lane_mappings in case this function is called multiple times 
    self.output_lane_mappings = {}
    for csrName in self.mux_select_csrs:
      self.output_lane_mappings[csrName] = [i for i in range(0, self.output_lanes)]

    for csrName in self.required_input_lanes:
      lanes = self.required_input_lanes[csrName]

      #Assign input lanes to output lanes
      outputLaneMap = {}
      for inLaneNum in lanes:
        if (inLaneNum < self.output_lanes):
          outputLaneMap[inLaneNum] = inLaneNum

      availLanes = [i for i in range(0, self.output_lanes) if (not (i in outputLaneMap))]
      for inLaneNum in lanes:
        if not (inLaneNum in outputLaneMap):
          outLane = availLanes.pop(0)
          outputLaneMap[outLane] = inLaneNum

      laneAssignments = [i for i in range(self.output_lanes)]
      for outLane in outputLaneMap:
        laneAssignments[outLane] = outputLaneMap[outLane]
      
      self.output_lane_mappings[csrName] = laneAssignments

  def generateOutputSignals(self):
    #Reset output_signals in case this function is called multiple times 
    self.output_signals = []

    #Make sure this mux does not have multiple in-use select CSRs if it in the middle of a nested mux network
    #TODO: Figure out a way to support switching between mux select MMRs for nested muxes
    if ((len(self.required_input_sigs) > 1) and (not self.final_mux)):
      usedCsrs = []
      for csrName in self.required_input_sigs:
        if (len(self.required_input_sigs[csrName]) > 0):
          usedCsrs.append(csrName)

      if (len(usedCsrs) > 1):
        g_logger.error("Mux output signals required for the next mux level are unclear due to multiple mux select CSRs {} in use for \"{}\"".format(usedCsrs, self.name))
        sys.exit()

    #TODO: Add comment
    for csrName in self.mux_select_csrs:
      for input_sig_obj in self.required_input_sigs[csrName]:
        #Reset loaded_signals list in case this function is called multiple times 
        input_sig_obj.loaded_signals = []

        #Get output parent signal
        if not (self.output in g_debugSignals):
          raise IndexError("\"{}\" not found in g_debugSignals".format(self.output))
        output_parent_signal = g_debugSignals[self.output]

        #Generate bitwise output signals
        for indx in range(input_sig_obj.width):
          dbmInputLane, laneIndx = input_sig_obj.getBitPlacement(indx)
          output_lane = self.output_lane_mappings[csrName].index(dbmInputLane)
          output_bit = (output_lane * self.lane_width) + laneIndx

          output_signalname = "{}[{}]".format(self.output, output_bit)
          output_signal_obj = DebugBusSignal(output_signalname)
          output_signal_obj.copy(output_parent_signal)
          output_signal_obj.parseIndeces()

          input_sig_obj.loaded_signals.insert(0, output_signal_obj)
          output_signal_obj.driving_signal = input_sig_obj
          output_signal_obj.cycle_delay = input_sig_obj.cycle_delay + self.output_cycle_delay

          self.output_signals.append(output_signal_obj)

  def pushOutputsToNextMuxes(self):
    loaded_muxes = []
    for output_signal_obj in self.output_signals:
      load_mux = output_signal_obj.input_mux
      if not (load_mux is None):
        load_mux.addRequiredInputSignal(output_signal_obj)
        loaded_muxes.append(load_mux)

    loaded_muxes = list(set(loaded_muxes))
    for load_mux in loaded_muxes:
      load_mux.calcOutputSignals()

  def calcOutputSignals(self):
    self.calcReuiredInputLanes()
    self.allocateOutputLanes()
    self.generateOutputSignals()
    self.pushOutputsToNextMuxes()

  def logPrintMuxInfo(self):
    for csrName in self.output_lane_mappings:
      laneAssignments = self.output_lane_mappings[csrName]
      g_logger.debug("{}({}) selected mux output lanes = {}".format(self.name, csrName, laneAssignments))

    for output_signal_obj in self.output_signals:
      driving_signal_chain_str = " <- ".join([str(sig.name) for sig in output_signal_obj.getDrivingSignalChain()])
      g_logger.debug("{}: Generated mux output signal \"{}\"(propogation_delay = {} cycles). Signal drivers: {} <- {}".format(self.name, output_signal_obj.name, output_signal_obj.cycle_delay, output_signal_obj.name, driving_signal_chain_str))
    

class DebugBusSignal:
  def __init__ (self, signalName, input_mux=None, busDict=None, muxsel_csr=None):
    self.name = signalName
    self.input_mux = input_mux
    self.muxsel_csr = muxsel_csr

    self.driving_signal = None
    self.loaded_signals = []
    self.cycle_delay = 0

    self.type = None
    self.width = None
    self.lower_lane = None
    self.lower_lane_index = None
    self.upper_lane = None
    self.upper_lane_index = None

    self.indexesParsed = False
    self.upper_signal_index = None
    self.lower_signal_index = None

    if (not (busDict is None)):
      self.type = busDict["Type"]
      self.width = int(busDict["Bit Width"])
      self.lower_lane = int(busDict["Lane Lower"])
      self.lower_lane_index = int(busDict["Lane Lower Index"])
      self.upper_lane = int(busDict["Lane Upper"])
      self.upper_lane_index = int(busDict["Lane Upper Index"])

  def __str__(self):
    driving_signal_chain_str = ""
    if (isinstance(self.driving_signal, DebugBusSignal)):
      driving_signal_chain_str = ", Drivers: {} <- {}".format(self.name, " <- ".join([str(sig.name) for sig in self.getDrivingSignalChain()]))
      
    return "(name: {}, width: {}, indexes: [{}:{}],Lower Lane: {}[{}], Upper Lane: {}[{}]{}, Propogation delay = {} cycles)".format(self.name, self.width, self.upper_signal_index, self.lower_signal_index, self.lower_lane, self.lower_lane_index, self.upper_lane, self.upper_lane_index, driving_signal_chain_str, self.cycle_delay)

  def __repr__(self):
    return str(self)

  def copy(self, dbmSignalObj):
    self.input_mux = dbmSignalObj.input_mux
    self.muxsel_csr = dbmSignalObj.muxsel_csr
    self.driving_signal = dbmSignalObj.driving_signal
    self.loaded_signals = dbmSignalObj.loaded_signals
    self.type = dbmSignalObj.type
    self.width = dbmSignalObj.width
    self.lower_lane = dbmSignalObj.lower_lane
    self.lower_lane_index = dbmSignalObj.lower_lane_index
    self.upper_lane = dbmSignalObj.upper_lane
    self.upper_lane_index = dbmSignalObj.upper_lane_index
    self.cycle_delay = dbmSignalObj.cycle_delay

  def getLaneList(self):
    laneList = []

    for lane in range(self.lower_lane, self.upper_lane+1):
      laneList.append(lane)

    return laneList

  def getDrivingSignalChain(self):
    drivingSignalsChain = []
    if isinstance(self.driving_signal, DebugBusSignal):
      drivingSignalsChain.append(self.driving_signal)
      drivingSignalsChain += self.driving_signal.getDrivingSignalChain()

    return drivingSignalsChain

  def parseIndeces(self):
    if (self.indexesParsed):
      return

    if (("[" in self.name) or ("]" in self.name)):
      #Index definition detected. Extract substring
      indxStart = self.name.find("[")
      indxEnd = self.name.find("]")
      if ((indxEnd == -1) or (indxStart == -1) or (indxStart >= len(self.name))):
        g_logger.error("Could not parse bit indeces for \"{}\"".format(self.name))
        sys.exit()

      indexStr = self.name[indxStart+1:indxEnd]

      #Extract upper and lower index from substring
      upperIndx = None
      lowerIndx = None

      if (":" in indexStr):
        indecesSplit = [i.strip() for i in indexStr.split(":")]
        #Calc upper index
        if (len(indecesSplit[0]) == 0):
          upperIndx = self.width-1
        else:
          try:
            upperIndx = int(indecesSplit[0])
          except:
            upperIndx = None
        #Calc lower index
        if (len(indecesSplit[1]) == 0):
          lowerIndx = 0
        else:
          try:
            lowerIndx = int(indecesSplit[1])
          except:
            lowerIndx = None

      else:
        if (len(indexStr) == 0):
          upperIndx = self.width-1
          lowerIndx = 0
        if (len(indexStr) > 0):
          try:
            indxValue = int(indexStr)
            upperIndx = indxValue
            lowerIndx = indxValue
          except:
            pass

      #Check index values
      if ((upperIndx is None) or (lowerIndx is None)):
        g_logger.error("Could not parse bit indeces for \"{}\"".format(self.name))
        sys.exit()

      if (upperIndx < lowerIndx):
        g_logger.error("Invalid bit indeces for \"{}\"".format(self.name))
        sys.exit()

      if (lowerIndx < 0):
        g_logger.error("Invalid bit indeces for \"{}\"".format(self.name))
        sys.exit()

      if (upperIndx >= self.width):
        g_logger.error("Index out of bounds for \"{}\". Signal width is {} bits".format(self.name, self.width))
        sys.exit()

      if (lowerIndx >= self.width):
        g_logger.error("Index out of bounds for \"{}\". Signal width is {} bits".format(self.name, self.width))
        sys.exit()

      #Modify width and lane indexes
      if isinstance(self.input_mux, DebugMux):
        self.lower_lane += int((self.lower_lane_index + lowerIndx)/self.input_mux.lane_width)
        self.lower_lane_index = int((self.lower_lane_index + lowerIndx)%self.input_mux.lane_width)
        self.upper_lane += int(math.floor((self.upper_lane_index - (self.width-upperIndx-1))/self.input_mux.lane_width))
        self.upper_lane_index = int((self.upper_lane_index - (self.width-upperIndx-1))%self.input_mux.lane_width)

      self.width = upperIndx-lowerIndx+1

      #Update parent signal indexes
      self.upper_signal_index = upperIndx
      self.lower_signal_index = lowerIndx

    else:
      self.upper_signal_index = self.width-1
      self.lower_signal_index = 0


    self.indexesParsed = True

  def getBitPlacement(self, bitIndex):
    if (bitIndex >= self.width):
      raise IndexError("Index {} > width {}".format(bitIndex, self.width))

    lane = self.lower_lane + int((self.lower_lane_index + bitIndex)/self.input_mux.lane_width)
    laneIndx = int((self.lower_lane_index + bitIndex)%self.input_mux.lane_width)
    
    return lane, laneIndx

  def expandBitwise(self):
    if (not self.indexesParsed):
      self.parseIndeces()

    bitwiseSignals = []
    for indx in range(self.lower_signal_index, self.upper_signal_index+1):
      #Create new signal object for this bit
      signalName = "{}[{}]".format(self.name.split("[")[0].strip(), indx)
      bitSignalObj = DebugBusSignal(signalName)
      bitSignalObj.copy(self)

      #Update width and indexes
      bitSignalObj.width = 1
      bitSignalObj.lower_signal_index = indx
      bitSignalObj.upper_signal_index = indx
      if isinstance(self.input_mux, DebugMux):
        bitSignalObj.lower_lane += int((self.lower_lane_index + (indx-self.lower_signal_index))/self.input_mux.lane_width)
        bitSignalObj.lower_lane_index = int((self.lower_lane_index + (indx-self.lower_signal_index))%self.input_mux.lane_width)
        bitSignalObj.upper_lane = bitSignalObj.lower_lane
        bitSignalObj.upper_lane_index = bitSignalObj.lower_lane_index

      bitSignalObj.indexesParsed = True

      #Update loaded signals list
      bitSignalObj.loaded_signals = [self.loaded_signals[indx-self.lower_signal_index]]

      #Append bit signal to list
      bitwiseSignals.insert(0, bitSignalObj)

    return bitwiseSignals


def flattenDebuBusSignals(inputMuxObj, busList, parentBus=None):
  for subDict in busList:
    signalName = str(subDict["Name"])
    if (parentBus):
      signalName = "{}.{}".format(parentBus, signalName)

    g_debugSignals[signalName] = DebugBusSignal(signalName, inputMuxObj, subDict)

    flattenDebuBusSignals(inputMuxObj, subDict["Sub Buses"], signalName)


###################################
# Register Allocation
###################################
def generateMuxGroupings(nodeDict):
  g_logger.debug("Generating mux select signal groups")

  requiredSignals = []
  #Extract list of all signals needed
  for nodeName in nodeDict:
    nodeObj = nodeDict[nodeName]
    for eapName in nodeObj.eaps:
      eapObj = nodeObj.eaps[eapName]
      #Gather signals needed for snapshots
      for signalName in eapObj.snapshot_signals:
        requiredSignals.append(signalName)

      #Gather signals needed for event triggers
      for eventName in eapObj.event_triggers:
        eventTrigger = eapObj.event_triggers[eventName]
        for triggerCondition in eventTrigger.triggerConditions:
          if ((triggerCondition.type == TRIGGER_TYPE.EQUAL) or (triggerCondition.type == TRIGGER_TYPE.NOT_EQUAL) or (triggerCondition.type == TRIGGER_TYPE.POSEDGE) or (triggerCondition.type == TRIGGER_TYPE.NEGEDGE) or (triggerCondition.type == TRIGGER_TYPE.TRANSITION)  or (triggerCondition.type == TRIGGER_TYPE.COUNT_ONES) or (triggerCondition.type == TRIGGER_TYPE.ANY_CHANGE)) and (not (triggerCondition.signal in g_claCounterAliases)):
            #This trigger condition requires a debug mux signal. Add to muxGroups dict
            requiredSignals.append(triggerCondition.signal)

  #Lookup signal names in debug signals dict
  signal_obj_dict = {}
  for signalName in requiredSignals:
    #Remove bit indexes from signal search
    signalRegex = signalName
    if ("[" in signalRegex):
      signalRegex = signalRegex[:signalRegex.find("[")]
      signalRegex = signalRegex.strip()

    #Get all signals that match this name
    nameMatches = []
    for debugSignal in g_debugSignals:
      if (signalRegex in debugSignal):
        nameMatches.append(debugSignal)

    #Reduce matches to largest parent buses
    reducedMatches = []
    for name in nameMatches:
      endIndx = name[name.find(signalRegex)+len(signalRegex):].find(".")
      reducedName = name
      if (endIndx != -1):
        reducedName = name[:endIndx+name.find(signalRegex)+len(signalRegex)]

      reducedMatches.append(reducedName)

    reducedMatches = list(set(reducedMatches))

    #Check for exact match
    if (signalRegex in reducedMatches):
      #Exact match is found. Use that signal
      reducedMatches = [signalRegex]

    #Ensure only one match is found
    if (len(reducedMatches) == 0):
      g_logger.error("Could not find rtl signal \"{}\"".format(signalName))
      if (not g_busConfigProvided):
        g_logger.error("No debug bus config file was provided. Without a mux config file, you can only use the signal name \"debug_signals\" in your CLA program description, which is the 64b input to the CLA module.".format(signalName))
      sys.exit()
    if (len(reducedMatches) > 1):
      g_logger.error("Multiple matches found for signal \"{}\" : {}".format(signalName, reducedMatches))
      sys.exit()

    #Generate DebugBusSignal obj
    dbmSignalObj = DebugBusSignal(signalName)
    dbmSignalObj.copy(g_debugSignals[reducedMatches[0]])
    dbmSignalObj.parseIndeces()

    signal_obj_dict[signalName] = dbmSignalObj

  #Determine signals needed for each mux group
  muxGroups = {}
  for nodeName in nodeDict:
    nodeObj = nodeDict[nodeName]
    for eapName in nodeObj.eaps:
      eapObj = nodeObj.eaps[eapName]
      #Gather signals needed for snapshots
      for signalName in eapObj.snapshot_signals:
        mux_name = signal_obj_dict[signalName].input_mux.name
        specified_muxsel_csr = eapObj.debug_mux_reg

        if (not (mux_name in muxGroups)):
          muxGroups[mux_name] = []
        muxGroups[mux_name].append((signalName, specified_muxsel_csr))

      #Gather signals needed for event triggers
      for eventName in eapObj.event_triggers:
        eventTrigger = eapObj.event_triggers[eventName]
        for triggerCondition in eventTrigger.triggerConditions:
          if ((triggerCondition.type == TRIGGER_TYPE.EQUAL) or (triggerCondition.type == TRIGGER_TYPE.NOT_EQUAL) or (triggerCondition.type == TRIGGER_TYPE.POSEDGE) or (triggerCondition.type == TRIGGER_TYPE.NEGEDGE) or (triggerCondition.type == TRIGGER_TYPE.TRANSITION)  or (triggerCondition.type == TRIGGER_TYPE.COUNT_ONES) or (triggerCondition.type == TRIGGER_TYPE.ANY_CHANGE)) and (not (triggerCondition.signal in g_claCounterAliases)):
            #This trigger condition requires a debug mux signal. Add to muxGroups dict
            mux_name = signal_obj_dict[triggerCondition.signal].input_mux.name
            specified_muxsel_csr = eapObj.debug_mux_reg

            if (not (mux_name in muxGroups)):
              muxGroups[mux_name] = []
            muxGroups[mux_name].append((triggerCondition.signal, specified_muxsel_csr))

  #Reduce signal lists
  for muxName in muxGroups:
    muxGroups[muxName] = list(set(muxGroups[muxName]))

  #Lookup signal names in debug signals dict
  muxGroupsLinked = {}
  for muxName in muxGroups:
    muxGroupsLinked[muxName] = {}
    for signalName, specified_muxsel_csr in muxGroups[muxName]:
      signal_obj_dict[signalName].muxsel_csr = specified_muxsel_csr
      muxGroupsLinked[muxName][signalName] = signal_obj_dict[signalName]

  return muxGroupsLinked


def generateMuxLanes(muxSignals):
  g_logger.debug("Generating mux select lanes")

  #Add initial required debug signals to 1st level mux objs
  for muxName in muxSignals:
    muxObj = g_debugMuxes[muxName]
    for signalName in muxSignals[muxName]:
      dbmSignalObj = muxSignals[muxName][signalName]
      muxObj.addRequiredInputSignal(dbmSignalObj)

  #Calculate output lanes and signals for all muxes in tree
  for muxName in muxSignals:
    muxObj = g_debugMuxes[muxName]
    muxObj.calcOutputSignals()

'''
def generateMuxLanes_old(muxSignals):
  g_logger.debug("Generating mux select lanes")

  muxLanes = {}
  for muxName in muxSignals:
    muxObj = g_debugMuxes[muxName] #TODO: Handle when user-specified mux csr is not found in g_debugMuxes

    #Get list of input lanes
    lanes = []
    for signalName in muxSignals[muxName]:
      dbmSignalObj = muxSignals[muxName][signalName]
      lanes += dbmSignalObj.getLaneList()

    lanes = list(set(lanes))
    lanes.sort()
    if (len(lanes) > muxObj.output_lanes):
      g_logger.error("Too many lanes used for debug mux select \"{}\". Up to {} lanes can be used at once, but selected signals require {} lanes : {}".format(muxName, muxObj.output_lanes, len(lanes), lanes))
      for signalName in muxSignals[muxName]:
        dbmSignalObj = muxSignals[muxName][signalName]
        g_logger.error(str(dbmSignalObj))
      sys.exit()

    #Assign input lanes to output lanes
    outputLaneMap = {}
    for inLaneNum in lanes:
      if (inLaneNum < muxObj.output_lanes):
        outputLaneMap[inLaneNum] = inLaneNum

    availLanes = [i for i in range(0, muxObj.output_lanes) if (not (i in outputLaneMap))]
    for inLaneNum in lanes:
      if not (inLaneNum in outputLaneMap):
        outLane = availLanes.pop(0)
        outputLaneMap[outLane] = inLaneNum

    laneAssignments = [i for i in range(muxObj.output_lanes)]
    for outLane in outputLaneMap:
      laneAssignments[outLane] = outputLaneMap[outLane]
    g_logger.debug("{} lanes = {}".format(muxName, laneAssignments))
    
    muxLanes[muxName] = laneAssignments

  return muxLanes
'''

def allocateCfgRegisters(nodeDict):
  g_logger.debug("Allocating CLA config registers")

  #Split triggers into match, edge_detect, and counters
  matchTriggers = {}
  edgeTriggers = {}
  counterTriggers = {}
  transitionTriggers = {}
  countOneTriggers = {}
  anyChangeTriggers = {}
  for nodeName in nodeDict:
    nodeObj = nodeDict[nodeName]
    for eapName in nodeObj.eaps:
      eapObj = nodeObj.eaps[eapName]

      for eventName in eapObj.event_triggers:
        eventTrigger = eapObj.event_triggers[eventName]
        for triggerCondition in eventTrigger.triggerConditions:
          if ((triggerCondition.type == TRIGGER_TYPE.EQUAL) or (triggerCondition.type == TRIGGER_TYPE.NOT_EQUAL)) and (not triggerCondition.signal in g_claCounterAliases):
            #This trigger condition requires a debug signal match
            matchTriggers[eventTrigger.getHash()] = eventTrigger
          if ((triggerCondition.type == TRIGGER_TYPE.POSEDGE) or (triggerCondition.type == TRIGGER_TYPE.NEGEDGE)):
            #This trigger condition requires an edge detect
            edgeTriggers[eventTrigger.getHash()] = eventTrigger
          if ((triggerCondition.type == TRIGGER_TYPE.EQUAL) or (triggerCondition.type == TRIGGER_TYPE.GREATER) or (triggerCondition.type == TRIGGER_TYPE.LESS)) and (triggerCondition.signal in g_claCounterAliases):
            #This trigger condition requires a CLA counter
            counterTriggers[eventTrigger.getHash()] = eventTrigger
          if (triggerCondition.type == TRIGGER_TYPE.TRANSITION):
            #This trigger condition requires a transition match
            transitionTriggers[eventTrigger.getHash()] = eventTrigger
          if (triggerCondition.type == TRIGGER_TYPE.COUNT_ONES):
            #This trigger condition requires a count ones match
            countOneTriggers[eventTrigger.getHash()] = eventTrigger
          if (triggerCondition.type == TRIGGER_TYPE.ANY_CHANGE):
            #This trigger condition requires a count ones match
            anyChangeTriggers[eventTrigger.getHash()] = eventTrigger
          break

  #Allocate event triggers to match regs
  if (len(matchTriggers) > g_availableMatchRegs):
    g_logger.error("{} match/mask registers required to implement program. Only {} available".format(len(matchTriggers), g_availableMatchRegs))
    sys.exit()

  matchRegAllocations = {}
  for triggerHash in matchTriggers:
    matchRegAllocations[triggerHash] = len(matchRegAllocations)

  #Allocate counter triggers to counter regs
  counterRegAllocations = {}
  for counterName in g_claCounterAliases:
    counterRegAllocations[counterName] = {}
    counterRegAllocations[counterName]["register"] = len(counterRegAllocations)-1
    counterRegAllocations[counterName]["target"] = None

  for triggerHash in counterTriggers:
    eventTrigger = counterTriggers[triggerHash]
    if (len(eventTrigger.triggerConditions) > 1):
      g_logger.error("Multiple counter comparisons used in {}.{}.{}. Only one counter comparison per event is supported".format(eventTrigger.parentEap.parentNode.name, eventTrigger.parentEap.name, eventTrigger.name))
      sys.exit()

    triggerCondition = eventTrigger.triggerConditions[0]
    if (counterRegAllocations[triggerCondition.signal]["target"] is None):
      counterRegAllocations[triggerCondition.signal]["target"] = triggerCondition.value
    else:
      existingTarget = counterRegAllocations[triggerCondition.signal]["target"]
      if (triggerCondition.value != existingTarget):
        g_logger.error("Multiple target values used for CLA counter \"{}\". Only one target value per counter is supported".format(triggerCondition.signal))
        sys.exit()

  #Allocate edge triggers to edge reg
  edgeRegAllocations = {}
  for triggerHash in edgeTriggers:
    edgeRegAllocations[triggerHash] = len(edgeRegAllocations)

  if (len(edgeRegAllocations) > g_availableEdgeDetects):
    g_logger.error("{} edge detects required to implement program. Only {} available".format(len(edgeRegAllocations), g_availableEdgeDetects))
    sys.exit()

  #Allocate transition triggers to transition reg
  transitionRegAllocations = {}
  for triggerHash in transitionTriggers:
    transitionRegAllocations[triggerHash] = len(transitionRegAllocations)

  if (len(transitionRegAllocations) > g_availableTransitionDetects):
    g_logger.error("{} transition detects required to implement program. Only {} available".format(len(transitionRegAllocations), g_availableTransitionDetects))
    sys.exit()

  #Allocate count ones triggers to count ones reg
  countOneRegAllocations = {}
  for triggerHash in countOneTriggers:
    countOneRegAllocations[triggerHash] = len(countOneRegAllocations)

  if (len(countOneRegAllocations) > g_availableCountOneRegs):
    g_logger.error("{} ones_count registers required to implement program. Only {} available".format(len(countOneRegAllocations), g_availableCountOneRegs))
    sys.exit()

  #Allocate anychange triggers to anychange reg
  anyChangeRegAllocations = {}
  for triggerHash in anyChangeTriggers:
    anyChangeRegAllocations[triggerHash] = len(anyChangeRegAllocations)

  if (len(anyChangeRegAllocations) > g_availableAnyChangeRegs):
    g_logger.error("{} any change mask registers required to implement program. Only {} available".format(len(anyChangeRegAllocations), g_availableAnyChangeRegs))
    sys.exit()

  return matchRegAllocations, counterRegAllocations, edgeRegAllocations, transitionRegAllocations, countOneRegAllocations, anyChangeRegAllocations

###################################
# Register Classes
###################################
def getRegDict(regObj, fieldList):
  regDict = {}
  regDict["fields"] = {}
  concatBinList = []
  for field in fieldList:
    if (field.value is None):
      field.value = 0
    regDict["fields"][field.name] = "0x%x" % field.value  #Convert to hex
    # if ("L") in str(regDict["fields"][field.name]):
    #   print("#########")
    #   print(field.value)
    #   print(hex(field.value))
    #   k = "0x%x" % field.value
    #   print(k)
    try:
      concatBinList += getBinaryList(field.value, width=field.width)
    except TypeError:
      g_logger.error("Could not convert value=\"{}\" into binary for field {}.{}".format(field.value, regObj.name, field.name))
      sys.exit()
    except ValueError:
      g_logger.error("Field {}.{}[{}:0] is not wide enough for value={}".format(regObj.name, field.name, field.width-1, field.value))
      sys.exit()

  regDict["value"] = "0x%x" % int("".join([str(i) for i in concatBinList]), 2)

  return regDict

class RegField:
  def __init__ (self, name, width, value=0, comment=None):
    self.name = name
    self.width = width
    self.value = value
    self.comment = comment

class CounterCfgReg:
  def __init__ (self, name, comment=None):
    self.name = name
    self.comment = comment

    #Register fields
    self.rsvd = RegField("rsvd", width=1, value=0)
    self.upper_target = RegField("upper_target", width=15, value=0)
    self.upper_counter = RegField("upper_counter", width=15, value=0)
    self.reset_on_target = RegField("reset_on_target", width=1, value=0)
    self.target = RegField("target", width=16, value=0)
    self.counter = RegField("counter", width=16, value=0)

  def getDict(self):
    fieldList = [self.rsvd, self.upper_target, self.upper_counter, self.reset_on_target, self.target, self.counter]
    return getRegDict(self, fieldList)

  def getComments(self):
    commentDict = {}
    if not (self.comment is None):
      commentDict[self.name] = self.comment

    fieldList = [self.rsvd, self.upper_target, self.upper_counter, self.reset_on_target, self.target, self.counter]

    for field in fieldList:
      if not (field.comment is None):
        commentDict[field.name] = field.comment

    return commentDict

class EapReg:
  def __init__ (self, name, comment=None):
    self.name = name
    self.comment = comment

    #Register fields
    self.action3 = RegField("action3", width=6, value=0)
    self.action2 = RegField("action2", width=6, value=0)
    self.udf = RegField("udf", width=8, value=0)
    self.event_type2 = RegField("event_type2", width=6, value=0)
    self.custom_action1_enable = RegField("custom_action1_enable", width=1, value=0)
    self.custom_action0_enable = RegField("custom_action0_enable", width=1, value=0)
    self.custom_action_1 = RegField("custom_action_1", width=4, value=0)
    self.custom_action_0 = RegField("custom_action_0", width=4, value=0)
    self.event_type1 = RegField("event_type1", width=6, value=0)
    self.event_type0 = RegField("event_type0", width=6, value=0)
    self.logical_op = RegField("logical_op", width=2, value=0)
    self.action1 = RegField("action1", width=6, value=0)
    self.action0 = RegField("action0", width=6, value=0)
    self.dest_node = RegField("dest_node", width=2, value=0)

  def getDict(self):
    fieldList = [
        self.action3,
        self.action2,
        self.udf,
        self.event_type2,
        self.custom_action1_enable,
        self.custom_action0_enable,
        self.custom_action_1,
        self.custom_action_0,
        self.event_type1,
        self.event_type0,
        self.logical_op,
        self.action1,
        self.action0,
        self.dest_node
      ]
    return getRegDict(self, fieldList)

  def getComments(self):
    commentDict = {}
    if not (self.comment is None):
      commentDict[self.name] = self.comment

    fieldList = [
        self.action3,
        self.action2,
        self.event_type2,
        self.custom_action1_enable,
        self.custom_action0_enable,
        self.custom_action_1,
        self.custom_action_0,
        self.event_type1,
        self.event_type0,
        self.logical_op,
        self.action1,
        self.action0,
        self.dest_node
      ]

    for field in fieldList:
      if not (field.comment is None):
        commentDict[field.name] = field.comment

    return commentDict

class SignalMaskReg:
  def __init__ (self, name, comment=None):
    self.name = name
    self.comment = comment

    #Register fields
    self.value = RegField("value", width=64, value=0)

  def getDict(self):
    fieldList = [self.value]
    return getRegDict(self, fieldList)

  def getComments(self):
    commentDict = {}
    if not (self.comment is None):
      commentDict[self.name] = self.comment

    fieldList = [self.value]

    for field in fieldList:
      if not (field.comment is None):
        commentDict[field.name] = field.comment

    return commentDict

class SignalMatchReg:
  def __init__ (self, name, comment=None):
    self.name = name
    self.comment = comment

    #Register fields
    self.value = RegField("value", width=64, value=0)

  def getDict(self):
    fieldList = [self.value]
    return getRegDict(self, fieldList)

  def getComments(self):
    commentDict = {}
    if not (self.comment is None):
      commentDict[self.name] = self.comment

    fieldList = [self.value]

    for field in fieldList:
      if not (field.comment is None):
        commentDict[field.name] = field.comment

    return commentDict

class EdgeDetectCfgReg:
  def __init__ (self, name, comment=None):
    self.name = name
    self.comment = comment

    #Register fields
    self.pos_edge_signal1 = RegField("pos_edge_signal1", width=1, value=0)
    self.signal1_select = RegField("signal1_select", width=6, value=0)
    self.pos_edge_signal0 = RegField("pos_edge_signal0", width=1, value=0)
    self.signal0_select = RegField("signal0_select", width=6, value=0)

  def getDict(self):
    fieldList = [self.pos_edge_signal1, 
        self.signal1_select, 
        self.pos_edge_signal0, 
        self.signal0_select
      ]
    return getRegDict(self, fieldList)

  def getComments(self):
    commentDict = {}
    if not (self.comment is None):
      commentDict[self.name] = self.comment

    fieldList = [self.pos_edge_signal1, 
        self.signal1_select, 
        self.pos_edge_signal0, 
        self.signal0_select
      ]

    for field in fieldList:
      if not (field.comment is None):
        commentDict[field.name] = field.comment

    return commentDict

class TransitionMaskReg:
  def __init__ (self, name, comment=None):
    self.name = name
    self.comment = comment

    #Register fields
    self.value = RegField("value", width=64, value=0)

  def getDict(self):
    fieldList = [self.value]
    return getRegDict(self, fieldList)

  def getComments(self):
    commentDict = {}
    if not (self.comment is None):
      commentDict[self.name] = self.comment

    fieldList = [self.value]

    for field in fieldList:
      if not (field.comment is None):
        commentDict[field.name] = field.comment

    return commentDict

class TransitionFromValueReg:
  def __init__ (self, name, comment=None):
    self.name = name
    self.comment = comment

    #Register fields
    self.value = RegField("value", width=64, value=0)

  def getDict(self):
    fieldList = [self.value]
    return getRegDict(self, fieldList)

  def getComments(self):
    commentDict = {}
    if not (self.comment is None):
      commentDict[self.name] = self.comment

    fieldList = [self.value]

    for field in fieldList:
      if not (field.comment is None):
        commentDict[field.name] = field.comment

    return commentDict

class TransitionToValueReg:
  def __init__ (self, name, comment=None):
    self.name = name
    self.comment = comment

    #Register fields
    self.value = RegField("value", width=64, value=0)

  def getDict(self):
    fieldList = [self.value]
    return getRegDict(self, fieldList)

  def getComments(self):
    commentDict = {}
    if not (self.comment is None):
      commentDict[self.name] = self.comment

    fieldList = [self.value]

    for field in fieldList:
      if not (field.comment is None):
        commentDict[field.name] = field.comment

    return commentDict

class OnesCountMaskReg:
  def __init__ (self, name, comment=None):
    self.name = name
    self.comment = comment

    #Register fields
    self.value = RegField("value", width=64, value=0)

  def getDict(self):
    fieldList = [self.value]
    return getRegDict(self, fieldList)

  def getComments(self):
    commentDict = {}
    if not (self.comment is None):
      commentDict[self.name] = self.comment

    fieldList = [self.value]

    for field in fieldList:
      if not (field.comment is None):
        commentDict[field.name] = field.comment

    return commentDict

class OnesCountValueReg:
  def __init__ (self, name, comment=None):
    self.name = name
    self.comment = comment

    #Register fields
    self.value = RegField("value", width=64, value=0)

  def getDict(self):
    fieldList = [self.value]
    return getRegDict(self, fieldList)

  def getComments(self):
    commentDict = {}
    if not (self.comment is None):
      commentDict[self.name] = self.comment

    fieldList = [self.value]

    for field in fieldList:
      if not (field.comment is None):
        commentDict[field.name] = field.comment

    return commentDict

class AnyChangeReg:
  def __init__ (self, name, comment=None):
    self.name = name
    self.comment = comment

    #Register fields
    self.mask = RegField("mask", width=64, value=0)

  def getDict(self):
    fieldList = [self.mask]
    return getRegDict(self, fieldList)

  def getComments(self):
    commentDict = {}
    if not (self.comment is None):
      commentDict[self.name] = self.comment

    fieldList = [self.mask]

    for field in fieldList:
      if not (field.comment is None):
        commentDict[field.name] = field.comment

    return commentDict

class MuxSelectReg:
  def __init__ (self, name, comment=None):
    self.name = name
    self.comment = comment

    #Register fields
    self.Muxselseg7 = RegField("Muxselseg7", width=6, value=0)
    self.Muxselseg6 = RegField("Muxselseg6", width=6, value=0)
    self.Muxselseg5 = RegField("Muxselseg5", width=6, value=0)
    self.Muxselseg4 = RegField("Muxselseg4", width=6, value=0)
    self.Muxselseg3 = RegField("Muxselseg3", width=6, value=0)
    self.Muxselseg2 = RegField("Muxselseg2", width=6, value=0)
    self.Muxselseg1 = RegField("Muxselseg1", width=6, value=0)
    self.Muxselseg0 = RegField("Muxselseg0", width=6, value=0)
    self.rsvd = RegField("rsvd", width=8, value=0)
    self.DbmId = RegField("DbmId", width=6, value=0)
    self.DbmMode = RegField("DbmMode", width=2, value=1)

  def getDict(self):
    fieldList = [self.Muxselseg7, self.Muxselseg6, self.Muxselseg5, self.Muxselseg4, self.Muxselseg3, self.Muxselseg2, self.Muxselseg1, self.Muxselseg0, self.rsvd, self.DbmId, self.DbmMode]
    return getRegDict(self, fieldList)

  def getComments(self):
    commentDict = {}
    if not (self.comment is None):
      commentDict[self.name] = self.comment

    fieldList = [self.Muxselseg7, self.Muxselseg6, self.Muxselseg5, self.Muxselseg4, self.Muxselseg3, self.Muxselseg2, self.Muxselseg1, self.Muxselseg0, self.rsvd, self.DbmId, self.DbmMode]

    for field in fieldList:
      if not (field.comment is None):
        commentDict[field.name] = field.comment

    return commentDict

class DebugSignalDelayReg:
  def __init__ (self, name, comment=None):
    self.name = name
    self.comment = comment

    #Register fields
    self.Muxselseg7 = RegField("Muxselseg7", width=2, value=0)
    self.Muxselseg6 = RegField("Muxselseg6", width=2, value=0)
    self.Muxselseg5 = RegField("Muxselseg5", width=2, value=0)
    self.Muxselseg4 = RegField("Muxselseg4", width=2, value=0)
    self.Muxselseg3 = RegField("Muxselseg3", width=2, value=0)
    self.Muxselseg2 = RegField("Muxselseg2", width=2, value=0)
    self.Muxselseg1 = RegField("Muxselseg1", width=2, value=0)
    self.Muxselseg0 = RegField("Muxselseg0", width=2, value=0)
    self.rsvd = RegField("rsvd", width=48, value=0)

  def getDict(self):
    fieldList = [self.rsvd, self.Muxselseg7, self.Muxselseg6, self.Muxselseg5, self.Muxselseg4, self.Muxselseg3, self.Muxselseg2, self.Muxselseg1, self.Muxselseg0]
    return getRegDict(self, fieldList)

  def getComments(self):
    commentDict = {}
    if not (self.comment is None):
      commentDict[self.name] = self.comment

    fieldList = [self.rsvd, self.Muxselseg7, self.Muxselseg6, self.Muxselseg5, self.Muxselseg4, self.Muxselseg3, self.Muxselseg2, self.Muxselseg1, self.Muxselseg0]

    for field in fieldList:
      if not (field.comment is None):
        commentDict[field.name] = field.comment

    return commentDict

class ClaValues:
  def __init__ (self, name=None):
    self.name = name

    #Registers
    self.registers = {}
    for i in range(g_availableCounters):
      self.addRegister(CounterCfgReg("dbg_cla_counter{}_cfg".format(i)))
    
    for i in range(g_availableNodes):
      for j in range(g_availableEapsPerNode):
        self.addRegister(EapReg("dbg_node{}_eap{}".format(i, j)))

    for i in range(g_availableMatchRegs):
      self.addRegister(SignalMaskReg("dbg_signal_mask{}".format(i)))
      self.addRegister(SignalMatchReg("dbg_signal_match{}".format(i)))

    self.addRegister(EdgeDetectCfgReg("dbg_signal_edge_detect_cfg"))
    self.addRegister(TransitionMaskReg("dbg_transition_mask"))
    self.addRegister(TransitionFromValueReg("dbg_transition_from_value"))
    self.addRegister(TransitionToValueReg("dbg_transition_to_value"))
    self.addRegister(OnesCountMaskReg("dbg_ones_count_mask"))
    self.addRegister(OnesCountValueReg("dbg_ones_count_value"))
    self.addRegister(AnyChangeReg("dbg_any_change"))
    self.addRegister(DebugSignalDelayReg("dbg_signal_delay_mux_sel"))

  def addRegister(self, registerObj):
    registerName = registerObj.name
    if (len(registerName) == 0):
      raise ValueError("Empty register name defined for {}".format(registerObj))

    #Handle Mux ID overloading
    if (isinstance(registerObj, MuxSelectReg)):
      registerName = "{}__ID_{}".format(registerName, registerObj.DbmId.value)
      if (registerName in self.registers):
        g_logger.error("Multiple debug mux instances connected to select csr \"{}\" have the same mux ID \"{}\"".format(registerObj.name, registerObj.DbmId))
        sys.exit()

    self.registers[registerName] = registerObj

  def writeToYamlFile(self, outputPath, removeHexQuotes=True):
    #Generate value dict
    valueDict = {}
    for registerName in self.registers:
      valueDict[registerName] = self.registers[registerName].getDict()

    #Convert value dict to yaml string
    yamlStr = yaml.dump(valueDict, default_flow_style=False)

    #Add comments to yaml string
    lineList = yamlStr.split("\n")
    fileLines = []
    currentCommentDict = {}
    for line in lineList:
      #Remove quotes from hex strings
      if (removeHexQuotes) and ("'0x" in line):
        line = line[:-1].replace("'0x", "0x")

      #Add comment
      fieldStr = line.split(":")[0].strip()
      if fieldStr in self.registers:
        currentCommentDict = self.registers[fieldStr].getComments()
        #Handle register renames for mux ID overloading
        if not (self.registers[fieldStr].comment is None):
          currentCommentDict[fieldStr] = self.registers[fieldStr].comment
        
      if (fieldStr in currentCommentDict):
        line += "  # {}".format(currentCommentDict[fieldStr])

      fileLines.append(line)

    #Output to file
    fileTxt = "\n".join(fileLines)
    outputFile = open(outputPath, "w")
    outputFile.write(fileTxt)
    outputFile.close()

  def writeToCsvFile(self, outputPath):
    #Generate value dict
    valueDict = {}
    for registerName in self.registers:
      valueDict[registerName] = self.registers[registerName].getDict()

    #Output to file
    outputFile = open(outputPath, "w")
    header = "mmr_name,hex_value\n"
    outputFile.write(header)
    for registerName in self.registers:
      hexValStr = valueDict[registerName]["value"]
      rowStr = "{},{}\n".format(registerName, hexValStr)
      outputFile.write(rowStr)
    outputFile.close()
    

###################################
# Compilation
###################################
def compileMuxCsrs(csrValues):
  g_logger.debug("Compiling mux select registers")
  for muxName in g_debugMuxes:
    muxObj = g_debugMuxes[muxName]
    muxObj.logPrintMuxInfo()

    for registerName in muxObj.output_lane_mappings:
      if (len(registerName) == 0):
        g_logger.error("Invalid CSR name \"{}\" defined for debug mux instance \"{}\"".format(registerName, muxObj.name))
        sys.exit()
      
      laneValues = muxObj.output_lane_mappings[registerName]

      #Populate mux reg
      muxReg = MuxSelectReg(registerName)
      muxReg.comment = ", ".join([sig.name for sig in muxObj.required_input_sigs[registerName]])
      if (len(muxReg.comment) == 0):
        muxReg.comment = None
      muxReg.DbmId.value = int(muxObj.mux_id)

      outputSet = 0
      for laneNum in laneValues:
        #Convert lane to set select values
        # selectValBin = [str(int((indx+4) <= laneNum)) for indx in range(8)]
        # selectValBin.reverse()
        # selectVal = int("".join(selectValBin), 2)
        
        selectVal = laneNum - muxObj.output_lanes + 1
        if (selectVal < 0):
          selectVal = 0
        
        #Populate new mux reg with select values
        if (outputSet == 0):
          muxReg.Muxselseg0.value = selectVal
          muxReg.Muxselseg0.comment = "Lane {}".format(laneNum)
        elif (outputSet == 1):
          muxReg.Muxselseg1.value = selectVal
          muxReg.Muxselseg1.comment = "Lane {}".format(laneNum)
        elif (outputSet == 2):
          muxReg.Muxselseg2.value = selectVal
          muxReg.Muxselseg2.comment = "Lane {}".format(laneNum)
        elif (outputSet == 3):
          muxReg.Muxselseg3.value = selectVal
          muxReg.Muxselseg3.comment = "Lane {}".format(laneNum)
        elif (outputSet == 4):
          muxReg.Muxselseg4.value = selectVal
          muxReg.Muxselseg4.comment = "Lane {}".format(laneNum)
        elif (outputSet == 5):
          muxReg.Muxselseg5.value = selectVal
          muxReg.Muxselseg5.comment = "Lane {}".format(laneNum)
        elif (outputSet == 6):
          muxReg.Muxselseg6.value = selectVal
          muxReg.Muxselseg6.comment = "Lane {}".format(laneNum)
        elif (outputSet == 7):
          muxReg.Muxselseg7.value = selectVal
          muxReg.Muxselseg7.comment = "Lane {}".format(laneNum)

        #Increment output set
        outputSet += 1

      #Add register to csrValues
      csrValues.addRegister(muxReg)


def compileCounterCsrs(counterRegAllocations, csrValues):
  g_logger.debug("Compiling counter registers")
  for counterName in counterRegAllocations:
    registerIndx = counterRegAllocations[counterName]["register"]
    registerName = "dbg_cla_counter{}_cfg".format(registerIndx)
    target = counterRegAllocations[counterName]["target"]

    csrValues.registers[registerName].comment = counterName
    csrValues.registers[registerName].target.value = target  #TODO: Take into account upper_target field if target value is too large

def getCustomOpcode(customActStr):
  opcodeVal = None
  if (customActStr in g_customActionOpcodes):
    opcodeVal = g_customActionOpcodes[customActStr]
  else:
    try:
      opcodeVal = str2int(customActStr)
    except:
      g_logger.error("Unkown custom action \"{}\"".format(customActStr))
      sys.exit()

  return opcodeVal

def getActionOpcode(actionStr, counterRegAllocations):
  opcodeVal = None
  g_logger.debug("Getting opcode for action \"{}\"".format(actionStr))

  #Handle NULL -> NoneType conversions
  if (actionStr is None):
    actionStr = "NULL"

  if not (isinstance(actionStr, str)):
    g_logger.error("Invalid type {} used for actionStr arg \"{}\"".format(type(actionStr), actionStr))
    sys.exit()

  #Handle static opcodes
  if (actionStr in g_actionOpcodes):
    opcodeVal = g_actionOpcodes[actionStr]
    return opcodeVal

  #Handle counter opcodes
  if (re.search("CLEAR\s", actionStr)):
    counterName = actionStr.replace("CLEAR", "").strip()
    if not (counterName in counterRegAllocations):
      g_logger.error("Unkown counter in action \"{}\"".format(actionStr))
      sys.exit()
    
    counterRegIndx = counterRegAllocations[counterName]["register"]
    linkedOpcode = "CLEAR_COUNTER_{}".format(counterRegIndx)
    opcodeVal = g_actionOpcodes[linkedOpcode]
    return opcodeVal

  if (re.search("STOP_AUTO_INCREMENT\s", actionStr)):
    counterName = actionStr.replace("STOP_AUTO_INCREMENT", "").strip()
    if not (counterName in counterRegAllocations):
      g_logger.error("Unkown counter in action \"{}\"".format(actionStr))
      sys.exit()
    
    counterRegIndx = counterRegAllocations[counterName]["register"]
    linkedOpcode = "STOP_AUTO_INCREMENT_COUNTER_{}".format(counterRegIndx)
    opcodeVal = g_actionOpcodes[linkedOpcode]
    return opcodeVal

  if (re.search("AUTO_INCREMENT\s", actionStr)):
    counterName = actionStr.replace("AUTO_INCREMENT", "").strip()
    if not (counterName in counterRegAllocations):
      g_logger.error("Unkown counter in action \"{}\"".format(actionStr))
      sys.exit()
    
    counterRegIndx = counterRegAllocations[counterName]["register"]
    linkedOpcode = "AUTO_INCREMENT_COUNTER_{}".format(counterRegIndx)
    opcodeVal = g_actionOpcodes[linkedOpcode]
    return opcodeVal

  if (re.search("INCREMENT\s", actionStr)):
    counterName = actionStr.replace("INCREMENT", "").strip()
    if not (counterName in counterRegAllocations):
      g_logger.error("Unkown counter in action \"{}\"".format(actionStr))
      sys.exit()
    
    counterRegIndx = counterRegAllocations[counterName]["register"]
    linkedOpcode = "INCREMENT_COUNTER_{}".format(counterRegIndx)
    opcodeVal = g_actionOpcodes[linkedOpcode]
    return opcodeVal
  
  #Handle numerical opcodes
  try:
    opcodeVal = str2int(actionStr)
    return opcodeVal
  except:
    g_logger.error("Unkown action \"{}\"".format(actionStr))
    sys.exit()

  return opcodeVal

def getEventOpcode(eventObj, matchRegAllocations, counterRegAllocations, edgeRegAllocations, transitionRegAllocations, countOneRegAllocations, anyChangeRegAllocations):
  opcodeVal = None
  eventHash = eventObj.getHash()
  triggerCondition = eventObj.triggerConditions[0]
  
  #Always
  if (triggerCondition.type == TRIGGER_TYPE.ALWAYS):
    opcodeStr = "ALWAYS_ON"
    opcodeVal = g_eventOpcodes[opcodeStr]
    return opcodeVal

  #Period tick
  if (triggerCondition.type == TRIGGER_TYPE.PERIOD_TICK):
    opcodeStr = "PERIOD_TICK"
    opcodeVal = g_eventOpcodes[opcodeStr]
    return opcodeVal

  #Link match events
  if (eventHash in matchRegAllocations):
    matchRegIndx = matchRegAllocations[eventHash]
    if (triggerCondition.type == TRIGGER_TYPE.EQUAL):
      opcodeStr = "MATCH_{}".format(matchRegIndx)
      opcodeVal = g_eventOpcodes[opcodeStr]
      return opcodeVal
    if (triggerCondition.type == TRIGGER_TYPE.NOT_EQUAL):
      opcodeStr = "NOT_MATCH_{}".format(matchRegIndx)
      opcodeVal = g_eventOpcodes[opcodeStr]
      return opcodeVal

  #Link edge events
  if (eventHash in edgeRegAllocations):
    edgeRegIndx = edgeRegAllocations[eventHash]
    opcodeStr = "EDGE_DETECT_{}".format(edgeRegIndx)
    opcodeVal = g_eventOpcodes[opcodeStr]
    return opcodeVal

  #Link xtrigger events
  if (triggerCondition.type == TRIGGER_TYPE.XTRIGGER_0):
    opcodeStr = "XTRIGGER_0"
    opcodeVal = g_eventOpcodes[opcodeStr]
    return opcodeVal
  if (triggerCondition.type == TRIGGER_TYPE.XTRIGGER_1):
    opcodeStr = "XTRIGGER_1"
    opcodeVal = g_eventOpcodes[opcodeStr]
    return opcodeVal

  #Link transition events
  if (eventHash in transitionRegAllocations):
    opcodeStr = "TRANSITION"
    opcodeVal = g_eventOpcodes[opcodeStr]
    return opcodeVal

  #Link count ones events
  if (eventHash in countOneRegAllocations):
    opcodeStr = "ONES_COUNT"
    opcodeVal = g_eventOpcodes[opcodeStr]
    return opcodeVal

  #Link any change events
  if (eventHash in anyChangeRegAllocations):
    opcodeStr = "DEBUG_SIGNALS_CHANGE"
    opcodeVal = g_eventOpcodes[opcodeStr]
    return opcodeVal

  #Link counter events
  counterName = triggerCondition.signal
  if not (counterName in counterRegAllocations):
    raise ValueError("\"{}\" not in {}".format(counterName, counterRegAllocations))

  counterIndx = counterRegAllocations[counterName]["register"]
  if (triggerCondition.type == TRIGGER_TYPE.EQUAL):
    opcodeStr = "COUNTER_{}_EQUAL_TARGET".format(counterIndx)
    opcodeVal = g_eventOpcodes[opcodeStr]
    return opcodeVal
  if (triggerCondition.type == TRIGGER_TYPE.GREATER):
    opcodeStr = "COUNTER_{}_GREATER_TARGET".format(counterIndx)
    opcodeVal = g_eventOpcodes[opcodeStr]
    return opcodeVal
  if (triggerCondition.type == TRIGGER_TYPE.LESS):
    opcodeStr = "COUNTER_{}_LESS_TARGET".format(counterIndx)
    opcodeVal = g_eventOpcodes[opcodeStr]
    return opcodeVal

  return opcodeVal


def compileLogicalUdf(eapObj):
  g_logger.debug("Compiling logic UDF for for EAP \"{}.{}\"".format(eapObj.parentNode.name, eapObj.name))

  #Replace verilog logical operators with bitwise operators for easier parsing
  logical_expression = str(eapObj.event_logical_op)
  logical_expression = logical_expression.replace("&&", "&")
  logical_expression = logical_expression.replace("||", "|")
  logical_expression = logical_expression.replace("!", "~")

  #Replace verilog operators with python operators
  logical_expression = logical_expression.replace("&", " and ")
  logical_expression = logical_expression.replace("|", " or ")
  logical_expression = logical_expression.replace("~", " not ")

  #Remove double whitespace
  while ("  " in logical_expression):
    logical_expression = logical_expression.replace("  ", " ")

  #Check for undefined event names
  event_indexes = eapObj.event_indexes
  expression_events = logical_expression.replace("(", "").replace(")", "").split()
  for eventName in expression_events:
    if (not (eventName in event_indexes)) and (not (eventName in ["and", "or", "not", "(", ")"])):
      g_logger.error("Event name \"{}\" used in logical expression \"{}\" not defined for EAP \"{}.{}\"".format(eventName, eapObj.event_logical_op, eapObj.parentNode.name, eapObj.name))
      sys.exit()

  #Replace user event names with EAP event names
  for eventName in event_indexes:
    logical_expression = logical_expression.replace(eventName, "event_{}".format(event_indexes[eventName]))

  #Determine UDF bits
  udf_table_str = "E2\tE1\tE0\tUDF Bit\tUDF Bit Value"
  udf_bits = []
  for event_2 in [False, True]:
    for event_1 in [False, True]:
      for event_0 in [False, True]:
        try:
          udf_bit_val = int(eval(logical_expression))
          udf_table_str += "\n{} \t{} \t{} \t{}      \t{}".format(int(event_2), int(event_1), int(event_0), len(udf_bits), udf_bit_val)
          udf_bits.append(udf_bit_val)
        except:
          g_logger.error("Could not evaluate python expression \"{}\" generated from verilog expression \"{}\"".format(logical_expression, eapObj.event_logical_op))
          sys.exit()

  #Conver bit list into int
  udf_bits.reverse()
  udf_value = int("".join([str(i) for i in udf_bits]), 2)

  #Print logical parsing info into log
  g_logger.debug("Event indexes for EventActionPair {}.{} = {}".format(eapObj.parentNode.name, eapObj.name, event_indexes))
  g_logger.debug("User defined logical expression \"{}\" => \"{}\"".format(eapObj.event_logical_op, logical_expression))
  g_logger.debug("UDF field table:\n{}".format(udf_table_str))
  g_logger.debug("UDF field value = {}".format(udf_value))

  return udf_value

def compileEapCsrs(nodeDict, startNode, matchRegAllocations, counterRegAllocations, edgeRegAllocations, transitionRegAllocations, countOneRegAllocations, anyChangeRegAllocations, csrValues):
  g_logger.debug("Compiling EAP registers")
  #Allocate node indexes
  freeNodes = [i for i in range(1,g_availableNodes)]
  nodeAllocations = {}
  for nodeName in nodeDict:
    nodeIndex = None
    if (nodeName == startNode):
      nodeIndex = 0
    else:
      nodeIndex = freeNodes.pop(0)

    nodeAllocations[nodeName] = nodeIndex

  #Populate node registers
  for nodeName in nodeDict:
    nodeIndex = nodeAllocations[nodeName]

    #Populate EAP regs for this node
    nodeObj = nodeDict[nodeName]
    freeEaps = [i for i in range(0,g_availableEapsPerNode)]
    for eapName in nodeObj.eaps:
      #Allocate EAP register
      eapObj = nodeObj.eaps[eapName]
      eapInx = freeEaps.pop(0)
      registerName = "dbg_node{}_eap{}".format(nodeIndex, eapInx)

      eapReg = csrValues.registers[registerName]
      eapReg.comment = "{}.{}".format(eapObj.parentNode.name, eapObj.name)

      #Populate destination node
      if not (eapObj.next_state_node in nodeAllocations):
        g_logger.error("Unkown destination node \"{}\" in {}.{}".format(eapObj.next_state_node, eapObj.parentNode.name, eapObj.name))
        sys.exit()

      destinationNodeIndx = nodeAllocations[eapObj.next_state_node]
      eapReg.dest_node.value = destinationNodeIndx
      eapReg.dest_node.comment = eapObj.next_state_node

      #Populate logical op and udf
      eapReg.logical_op.value = g_logicalOpcodes["NONE"]  #Disable logical_op for all cases, since compiler just uses the UDF for everything
      eapReg.logical_op.comment = "NONE"

      eapReg.udf.comment = eapObj.event_logical_op
      eapReg.udf.value = compileLogicalUdf(eapObj)

      #Populate event types
      for eventName in eapObj.event_triggers:
        #Determine opcode value
        eventObj = eapObj.event_triggers[eventName]
        eventIndx = eapObj.event_indexes[eventName]
        opcodeVal = getEventOpcode(eventObj, matchRegAllocations, counterRegAllocations, edgeRegAllocations, transitionRegAllocations, countOneRegAllocations, anyChangeRegAllocations)

        #Set field values
        if (eventIndx == 0):
          eapReg.event_type0.value = opcodeVal
          eapReg.event_type0.comment = eventObj.generateComment()
        elif (eventIndx == 1):
          eapReg.event_type1.value = opcodeVal
          eapReg.event_type1.comment = eventObj.generateComment()
        elif (eventIndx == 2):
          eapReg.event_type2.value = opcodeVal
          eapReg.event_type2.comment = eventObj.generateComment()
        else:
          raise ValueError("Event index {} out of bounds".format(eventIndx))

      #Populate custom actions
      customIndx = 0
      for customAct in eapObj.custom_actions:
        #Determine opcode value
        opcodeVal = getCustomOpcode(customAct)

        #Set field values
        if (customIndx == 0):
          eapReg.custom_action_0.value = opcodeVal
          eapReg.custom_action_0.comment = customAct
          eapReg.custom_action0_enable.value = 1;
        elif (customIndx == 1):
          eapReg.custom_action_1.value = opcodeVal
          eapReg.custom_action_1.comment = customAct
          eapReg.custom_action1_enable.value = 1;
        else:
          raise ValueError("Custom action index {} out of bounds".format(customIndx))

        #Mode on to next action
        customIndx += 1

      #Populate actions
      actionIndx = 0
      for action in eapObj.actions:
        #Determine opcode value
        opcodeVal = getActionOpcode(action, counterRegAllocations)

        #Set field values
        if (actionIndx == 0):
          eapReg.action0.value = opcodeVal
          eapReg.action0.comment = action
        elif (actionIndx == 1):
          eapReg.action1.value = opcodeVal
          eapReg.action1.comment = action
        elif (actionIndx == 2):
          eapReg.action2.value = opcodeVal
          eapReg.action2.comment = action
        elif (actionIndx == 3):
          eapReg.action3.value = opcodeVal
          eapReg.action3.comment = action
        else:
          raise ValueError("Action index {} out of bounds".format(actionIndx))

        #Mode on to next action
        actionIndx += 1


class DbmBitIndex:
  def __init__ (self, inputSignalObj, target=None):
    self.target = target

    #Check width of inputSignalObj
    self.inputSignalObj = inputSignalObj
    if (self.inputSignalObj.width != 1):
      raise IndexError("DebugBusSignal object of width {} used to instantiate DbmBitIndex. Only single bit signals are supported".format(self.inputSignalObj.width))

    self.dbmInputLane, self.laneIndx = inputSignalObj.getBitPlacement(0)

    #Fetch final dbm output signal
    self.output_signal_obj = inputSignalObj
    while True:
      if (len(self.output_signal_obj.loaded_signals) == 0):
        break
      if (len(self.output_signal_obj.loaded_signals) > 1):
        g_logger.error("Too many loaded signals found for edge detect signal \"{}\"->\"{}\". Loaded signals = {}. Only single bit signals are supported for edge events".format(inputSignalObj.name, output_signal_obj.name, output_signal_obj.loaded_signals))
        sys.exit()

      self.output_signal_obj = self.output_signal_obj.loaded_signals[0]

    if (self.output_signal_obj == inputSignalObj):
      g_logger.error("Could not find loaded output signal of \"{}\"".format(inputSignalObj.name))
      sys.exit()
    
    self.outputBitIndx = self.output_signal_obj.lower_signal_index

  def __str__(self):
    return "TODO"

'''
class DbmBitIndex_OLD:
  def __init__ (self, dbmInputLane, laneIndx, target=None):
    self.target = target
    self.dbmInputLane = dbmInputLane
    self.laneIndx = laneIndx
    self.dbmOutputLane = None
    self.outputBitIndx = None

  def __str__(self):
    return "INPUT_LANE_{}[{}] = OUTPUT_LANE_{}[{}] = DEBUG_BUS[{}] == {}".format(self.dbmInputLane, self.laneIndx, self.dbmOutputLane, self.laneIndx, self.outputBitIndx, self.target)
'''

def expandBitwise(triggerCondition, muxSignals, from_value=False):
  matchBits = []
  #Fetch DebugBusSignal object
  dbmSignalObj = None
  for muxName in muxSignals:
    if (triggerCondition.signal in muxSignals[muxName]):
      dbmSignalObj = muxSignals[muxName][triggerCondition.signal]
      break

  #Convert target value into binary list
  try:
    if (from_value):
      targetBitList = getBinaryList(triggerCondition.from_value, width=dbmSignalObj.width)
    elif (triggerCondition.type == TRIGGER_TYPE.ANY_CHANGE):
      targetBitList = [0 for i in range(dbmSignalObj.width)]
    else:
      targetBitList = getBinaryList(triggerCondition.value, width=dbmSignalObj.width)
  except ValueError:
    g_logger.error("Signal \"{}\" is not wide enough to compare to value \"{}\"".format(triggerCondition.signal, triggerCondition.value))
    sys.exit()

  targetBitList.reverse()

  #Generate list of DbmBitIndex objects
  bitwiseSignals = dbmSignalObj.expandBitwise()
  for indx in range(dbmSignalObj.width):
    targetValue = targetBitList[indx]
    bitSignalObj = bitwiseSignals[indx]
    matchBits.append(DbmBitIndex(bitSignalObj, target=targetValue))

  return matchBits

def compileMatchMaskCsrs(nodeDict, matchRegAllocations, muxSignals, csrValues):
  g_logger.debug("Compiling match/mask registers")
  #Get event objects
  matchRegEvents = {}
  matchRegMuxNames = {}
  for nodeName in nodeDict:
    nodeObj = nodeDict[nodeName]
    for eapName in nodeObj.eaps:
      eapObj = nodeObj.eaps[eapName]
      for eventName in eapObj.event_triggers:
        eventObj = eapObj.event_triggers[eventName]
        eventHash = eventObj.getHash()
        
        if (eventHash in matchRegAllocations):
          regindx = matchRegAllocations[eventHash]
          matchRegEvents[regindx] = eventObj
          matchRegMuxNames[regindx] = eapObj.debug_mux_reg

  #Expand match triggers per bit
  matchMaskLists = {}
  for regIndx in matchRegEvents:
    #Generate list of DbmBitIndex objs
    matchMaskBitList = []
    eventObj = matchRegEvents[regIndx]
    for triggerCondition in eventObj.triggerConditions:
      matchMaskBitList += expandBitwise(triggerCondition, muxSignals)

    matchMaskLists[regIndx] = matchMaskBitList

  #Generate match and mask values
  for regIndx in matchMaskLists:
    maskBinList = [0 for i in range(g_claDebugInputWidth)]
    matchBinList = [0 for i in range(g_claDebugInputWidth)]

    for matchBitObj in matchMaskLists[regIndx]:
      maskBinList[matchBitObj.outputBitIndx] = 1
      matchBinList[matchBitObj.outputBitIndx] = matchBitObj.target

    maskBinList.reverse()
    matchBinList.reverse()
    
    maskValue = int("".join([str(i) for i in maskBinList]), 2)
    matchValue = int("".join([str(i) for i in matchBinList]), 2)

    #Populate CSR values
    maskRegisterName = "dbg_signal_mask{}".format(regIndx)
    csrValues.registers[maskRegisterName].value.value = maskValue
    maskComment = ", ".join([triggerCondition.signal for triggerCondition in matchRegEvents[regIndx].triggerConditions])
    csrValues.registers[maskRegisterName].comment = maskComment

    matchRegisterName = "dbg_signal_match{}".format(regIndx)
    matchComment = matchRegEvents[regIndx].generateComment()
    csrValues.registers[matchRegisterName].value.value = matchValue
    csrValues.registers[matchRegisterName].comment = matchComment


def compileEdgeDetectCsrs(nodeDict, edgeRegAllocations, muxSignals, csrValues):
  g_logger.debug("Compiling edge detect registers")
  #Get event objects
  edgeRegEvents = {}
  edgeRegMuxNames = {}
  for nodeName in nodeDict:
    nodeObj = nodeDict[nodeName]
    for eapName in nodeObj.eaps:
      eapObj = nodeObj.eaps[eapName]
      for eventName in eapObj.event_triggers:
        eventObj = eapObj.event_triggers[eventName]
        eventHash = eventObj.getHash()
        
        if (eventHash in edgeRegAllocations):
          regindx = edgeRegAllocations[eventHash]
          edgeRegEvents[regindx] = eventObj
          edgeRegMuxNames[regindx] = eapObj.debug_mux_reg  #TODO: Fixme

  #Compile edge events
  for regIndx in edgeRegEvents:
    #Fetch driving DebugBusSignal object
    eventObj = edgeRegEvents[regIndx]
    triggerCondition = eventObj.triggerConditions[0]

    inputSignalObj = None
    for muxName in muxSignals:
      if (triggerCondition.signal in muxSignals[muxName]):
        inputSignalObj = muxSignals[muxName][triggerCondition.signal]
        break

    #Generate DbmBitIndex obj
    targetValue = triggerCondition.type
    edgeBitObj = DbmBitIndex(inputSignalObj, target=targetValue)

    #Populate CSR value
    if (regIndx == 0):
      csrValues.registers["dbg_signal_edge_detect_cfg"].signal0_select.value = edgeBitObj.outputBitIndx
      csrValues.registers["dbg_signal_edge_detect_cfg"].signal0_select.comment = inputSignalObj.name

      csrValues.registers["dbg_signal_edge_detect_cfg"].pos_edge_signal0.value = int(triggerCondition.type == TRIGGER_TYPE.POSEDGE)
    elif (regIndx == 1):
      csrValues.registers["dbg_signal_edge_detect_cfg"].signal1_select.value = edgeBitObj.outputBitIndx
      csrValues.registers["dbg_signal_edge_detect_cfg"].signal1_select.comment = inputSignalObj.name

      csrValues.registers["dbg_signal_edge_detect_cfg"].pos_edge_signal1.value = int(triggerCondition.type == TRIGGER_TYPE.POSEDGE)
    else:
      raise ValueError("Out of bounds index {}".format(regIndx))


def compileTransitionCsrs(nodeDict, transitionRegAllocations, muxSignals, csrValues):
  g_logger.debug("Compiling transtion match/mask registers")
  #Get event objects
  matchRegEvents = {}
  matchRegMuxNames = {}
  for nodeName in nodeDict:
    nodeObj = nodeDict[nodeName]
    for eapName in nodeObj.eaps:
      eapObj = nodeObj.eaps[eapName]
      for eventName in eapObj.event_triggers:
        eventObj = eapObj.event_triggers[eventName]
        eventHash = eventObj.getHash()
        
        if (eventHash in transitionRegAllocations):
          regindx = transitionRegAllocations[eventHash]
          matchRegEvents[regindx] = eventObj
          matchRegMuxNames[regindx] = eapObj.debug_mux_reg

  #Expand match triggers per bit
  toMatchMaskLists = {}
  fromMatchMaskLists = {}
  for regIndx in matchRegEvents:
    #Generate list of DbmBitIndex objs
    toMatchMaskBitList = []
    fromMatchMaskBitList = []
    eventObj = matchRegEvents[regIndx]
    for triggerCondition in eventObj.triggerConditions:
      toMatchMaskBitList += expandBitwise(triggerCondition, muxSignals)
      fromMatchMaskBitList += expandBitwise(triggerCondition, muxSignals, from_value=True)

    toMatchMaskLists[regIndx] = toMatchMaskBitList
    fromMatchMaskLists[regIndx] = fromMatchMaskBitList

  #Generate match and mask values
  for regIndx in toMatchMaskLists:
    maskBinList = [0 for i in range(g_claDebugInputWidth)]
    matchBinList = [0 for i in range(g_claDebugInputWidth)]

    for matchBitObj in toMatchMaskLists[regIndx]:
      maskBinList[matchBitObj.outputBitIndx] = 1
      matchBinList[matchBitObj.outputBitIndx] = matchBitObj.target

    maskBinList.reverse()
    matchBinList.reverse()
    
    maskValue = int("".join([str(i) for i in maskBinList]), 2)
    matchValue = int("".join([str(i) for i in matchBinList]), 2)

    #Populate CSR values
    maskRegisterName = "dbg_transition_mask"
    csrValues.registers[maskRegisterName].value.value = maskValue
    maskComment = ", ".join([triggerCondition.signal for triggerCondition in matchRegEvents[regIndx].triggerConditions])
    csrValues.registers[maskRegisterName].comment = maskComment

    matchRegisterName = "dbg_transition_to_value"
    matchComment = " & ".join(["({} == {})".format(triggerCondition.signal, triggerCondition.value) for triggerCondition in matchRegEvents[regIndx].triggerConditions])
    csrValues.registers[matchRegisterName].value.value = matchValue
    csrValues.registers[matchRegisterName].comment = matchComment

  for regIndx in fromMatchMaskLists:
    matchBinList = [0 for i in range(g_claDebugInputWidth)]

    for matchBitObj in fromMatchMaskLists[regIndx]:
      matchBinList[matchBitObj.outputBitIndx] = matchBitObj.target

    matchBinList.reverse()
    matchValue = int("".join([str(i) for i in matchBinList]), 2)

    #Populate CSR values
    matchRegisterName = "dbg_transition_from_value"
    matchComment = " & ".join(["({} == {})".format(triggerCondition.signal, triggerCondition.from_value) for triggerCondition in matchRegEvents[regIndx].triggerConditions])
    csrValues.registers[matchRegisterName].value.value = matchValue
    csrValues.registers[matchRegisterName].comment = matchComment


def compileAnyChangeMaskCsrs(nodeDict, anyChangeRegAllocations, muxSignals, csrValues):
  g_logger.debug("Compiling any change mask registers")
  #Get event objects
  anyChangeRegEvents = {}
  anyChangeRegMuxNames = {}
  for nodeName in nodeDict:
    nodeObj = nodeDict[nodeName]
    for eapName in nodeObj.eaps:
      eapObj = nodeObj.eaps[eapName]
      for eventName in eapObj.event_triggers:
        eventObj = eapObj.event_triggers[eventName]
        eventHash = eventObj.getHash()
        
        if (eventHash in anyChangeRegAllocations):
          regindx = anyChangeRegAllocations[eventHash]
          anyChangeRegEvents[regindx] = eventObj
          anyChangeRegMuxNames[regindx] = eapObj.debug_mux_reg

  #Expand triggers per bit
  anyChangeMaskLists = {}
  for regIndx in anyChangeRegEvents:
    #Generate list of DbmBitIndex objs
    anyChangeMaskBitList = []
    eventObj = anyChangeRegEvents[regIndx]
    for triggerCondition in eventObj.triggerConditions:
      anyChangeMaskBitList += expandBitwise(triggerCondition, muxSignals)

    anyChangeMaskLists[regIndx] = anyChangeMaskBitList

  #Generate mask values
  for regIndx in anyChangeMaskLists:
    maskBinList = [0 for i in range(g_claDebugInputWidth)]
    for matchBitObj in anyChangeMaskLists[regIndx]:
      maskBinList[matchBitObj.outputBitIndx] = 1
    maskBinList.reverse()
    
    maskValue = int("".join([str(i) for i in maskBinList]), 2)

    #Populate CSR values
    maskRegisterName = "dbg_any_change"
    csrValues.registers[maskRegisterName].mask.value = maskValue
    maskComment = ", ".join([triggerCondition.signal for triggerCondition in anyChangeRegEvents[regIndx].triggerConditions])
    csrValues.registers[maskRegisterName].comment = maskComment


def compileOnesCountCsrs(nodeDict, countOneRegAllocations, muxSignals, csrValues):
  g_logger.debug("Compiling count ones registers")
  #Get event objects
  countOnesRegEvents = {}
  countOnesRegMuxNames = {}
  for nodeName in nodeDict:
    nodeObj = nodeDict[nodeName]
    for eapName in nodeObj.eaps:
      eapObj = nodeObj.eaps[eapName]
      for eventName in eapObj.event_triggers:
        eventObj = eapObj.event_triggers[eventName]
        eventHash = eventObj.getHash()
        
        if (eventHash in countOneRegAllocations):
          regindx = countOneRegAllocations[eventHash]
          countOnesRegEvents[regindx] = eventObj
          countOnesRegMuxNames[regindx] = eapObj.debug_mux_reg

  #Expand triggers per bit
  countOnesMaskLists = {}
  for regIndx in countOnesRegEvents:
    #Generate list of DbmBitIndex objs
    countOnesMaskBitList = []
    eventObj = countOnesRegEvents[regIndx]
    for triggerCondition in eventObj.triggerConditions:
      countOnesMaskBitList += expandBitwise(triggerCondition, muxSignals)

    countOnesMaskLists[regIndx] = countOnesMaskBitList

  #Generate mask values
  for regIndx in countOnesMaskLists:
    maskBinList = [0 for i in range(g_claDebugInputWidth)]
    for matchBitObj in countOnesMaskLists[regIndx]:
      maskBinList[matchBitObj.outputBitIndx] = 1
    maskBinList.reverse()
    
    maskValue = int("".join([str(i) for i in maskBinList]), 2)

    #Populate CSR values
    maskRegisterName = "dbg_ones_count_mask"
    csrValues.registers[maskRegisterName].value.value = maskValue
    maskComment = ", ".join([triggerCondition.signal for triggerCondition in countOnesRegEvents[regIndx].triggerConditions])
    csrValues.registers[maskRegisterName].comment = maskComment

    valueRegisterName = "dbg_ones_count_value"
    valueComment = " & ".join(["(countones({}) == {})".format(triggerCondition.signal, triggerCondition.value) for triggerCondition in countOnesRegEvents[regIndx].triggerConditions])
    csrValues.registers[valueRegisterName].value.value = int(triggerCondition.value)
    csrValues.registers[valueRegisterName].comment = valueComment


def compileSignalDelayCsr(nodeDict, countOneRegAllocations, muxSignals, csrValues):
  g_logger.debug("Compiling debug signal delay register")
  
  #Fetch all final CLA input signals
  claInputSignals = []
  muxInstanceFound = False
  for muxName in g_debugMuxes:
    muxObj = g_debugMuxes[muxName]
    if (muxObj.final_mux):
      muxInstanceFound = True
      claInputSignals = muxObj.output_signals
      break

  if (not muxInstanceFound):
    g_logger.error("Unable to find final mux instance that feeds CLA debug bus")
    sys.exit()

  #Get per-lane propogation delays
  laneDelays = {}
  for signal_obj in claInputSignals:
    if (signal_obj.lower_signal_index != signal_obj.upper_signal_index):
      raise IndexError("Multibit signal \"{}\" cannot be use for propogation delay compensation calculation".format(signal_obj.name))

    inputLaneIndx = int((signal_obj.lower_signal_index) / 8)
    if not (inputLaneIndx in laneDelays):
      laneDelays[inputLaneIndx] = {"Lane Index": inputLaneIndx, "Signals": [], "Delays": []}

    laneDelays[inputLaneIndx]["Signals"].append(signal_obj)
    laneDelays[inputLaneIndx]["Delays"].append(signal_obj.cycle_delay)
  
  #Remove duplicate delays
  for laneIndx in laneDelays:
    laneDelays[laneIndx]["Delays"] = list(set(laneDelays[laneIndx]["Delays"]))
    g_logger.debug("CLA input lane #{} propogation delays = {}".format(laneIndx, laneDelays[laneIndx]["Delays"]))

  #Find maximum lane delay
  maxDelay = None
  for laneIndx in laneDelays:
    #Ensure all signals in a given lane have the same propogation delay
    if (len(laneDelays[laneIndx]["Delays"]) > 1):
      g_logger.warning("CLA input lane #{} has driving signals with different propogation delays. Unable to determine correct values for debug signal delay register".format(laneIndx))

      debugStr = "CLA input lane #{} driving signals:".format(laneIndx)
      for signal_obj in laneDelays[laneIndx]["Signals"]:
        debugStr += "\n{}".format(signal_obj)
      g_logger.warning(debugStr)
      return

    lanePropDelay = laneDelays[laneIndx]["Delays"][0]
    if (maxDelay is None):
      maxDelay = lanePropDelay

    if (lanePropDelay > maxDelay):
      maxDelay = lanePropDelay
  
  g_logger.debug("Maximum CLA input propogation delay = {} cycles".format(maxDelay))

  #Determine required staging per lane
  for laneIndx in laneDelays:
    lanePropDelay = laneDelays[laneIndx]["Delays"][0]
    requiredStaging = maxDelay - lanePropDelay
    laneDelays[laneIndx]["Required staging"] = requiredStaging
    g_logger.debug("CLA input lane #{} required staging = {}".format(laneIndx, requiredStaging))

  #Update CSR values
  for laneIndx in laneDelays:
    requiredStaging = laneDelays[laneIndx]["Required staging"]

    if (laneIndx == 0):
      csrValues.registers["dbg_signal_delay_mux_sel"].Muxselseg0.value = requiredStaging
    if (laneIndx == 1):
      csrValues.registers["dbg_signal_delay_mux_sel"].Muxselseg1.value = requiredStaging
    if (laneIndx == 2):
      csrValues.registers["dbg_signal_delay_mux_sel"].Muxselseg2.value = requiredStaging
    if (laneIndx == 3):
      csrValues.registers["dbg_signal_delay_mux_sel"].Muxselseg3.value = requiredStaging
    if (laneIndx == 4):
      csrValues.registers["dbg_signal_delay_mux_sel"].Muxselseg4.value = requiredStaging
    if (laneIndx == 5):
      csrValues.registers["dbg_signal_delay_mux_sel"].Muxselseg5.value = requiredStaging
    if (laneIndx == 6):
      csrValues.registers["dbg_signal_delay_mux_sel"].Muxselseg6.value = requiredStaging
    if (laneIndx == 7):
      csrValues.registers["dbg_signal_delay_mux_sel"].Muxselseg7.value = requiredStaging


def compileCsrValues(nodeDict, startNode):
  csrValues = ClaValues()

  #Allocate match/mask, counter, edge cfg, and transition registers
  matchRegAllocations, counterRegAllocations, edgeRegAllocations, transitionRegAllocations, countOneRegAllocations, anyChangeRegAllocations = allocateCfgRegisters(nodeDict)

  #Determine mux select lanes
  muxSignals = generateMuxGroupings(nodeDict)
  generateMuxLanes(muxSignals)

  #Compile mux select register values
  if (g_busConfigProvided):
    compileMuxCsrs(csrValues)

  #Compile counter register values
  compileCounterCsrs(counterRegAllocations, csrValues)

  #Compile edge detect register value
  compileEdgeDetectCsrs(nodeDict, edgeRegAllocations, muxSignals, csrValues)

  #Compile match/mask register values
  compileMatchMaskCsrs(nodeDict, matchRegAllocations, muxSignals, csrValues)

  #Compile EAP register values
  compileEapCsrs(nodeDict, startNode, matchRegAllocations, counterRegAllocations, edgeRegAllocations, transitionRegAllocations, countOneRegAllocations, anyChangeRegAllocations, csrValues)

  #Compile transition mask/match register values
  compileTransitionCsrs(nodeDict, transitionRegAllocations, muxSignals, csrValues)

  #Compile any change mask register values
  compileAnyChangeMaskCsrs(nodeDict, anyChangeRegAllocations, muxSignals, csrValues)

  #Compile ones count register values
  compileOnesCountCsrs(nodeDict, countOneRegAllocations, muxSignals, csrValues)

  #Compile signal delay register value
  compileSignalDelayCsr(nodeDict, countOneRegAllocations, muxSignals, csrValues)

  return csrValues


###################################
# Main
###################################
def escapeBazelSandbox(filePath):
  absolutePath = None

  cwd = str(os.getcwd())
  #Try to find file in repo root
  suffixSplitStr = "build/bazel_output_base"
  if (suffixSplitStr in cwd):
    repoRoot = cwd.split(suffixSplitStr)[0]
    prefixSplitStr = "user_regr/"
    if (prefixSplitStr in repoRoot):
      repoRoot = repoRoot[repoRoot.find(prefixSplitStr)+len(prefixSplitStr):]
      repoRoot = os.path.join("/proj_risc/user_dev/", repoRoot)
    potentialPath = os.path.join(repoRoot, filePath)
    g_logger.debug("Checking if \"{}\" exists".format(potentialPath))
    if (os.path.exists(potentialPath)):
      absolutePath = potentialPath
      return absolutePath

  #Try to find file in sandbox
  if (absolutePath is None):
    prefixSplitStr = "bazel-out/k8-opt/bin/"
    if (prefixSplitStr in filePath):
      sandboxRoot = os.path.join(cwd.split("processwrapper-sandbox")[0], "processwrapper-sandbox")
      sandboxSuffix = "execroot{}".format(cwd.split("execroot")[-1])
      sandboxIndexes = os.listdir(sandboxRoot)
      g_logger.debug("Sandbox indexes = {}".format(sandboxIndexes))
      for i in sandboxIndexes:
        g_logger.debug("Searching sanbox {}".format(i))
        potentialPathRoot = os.path.join(sandboxRoot, i, sandboxSuffix)
        for potentialSuffix in [filePath.split(prefixSplitStr)[-1], os.path.basename(filePath), filePath]:
          potentialPath = os.path.join(potentialPathRoot, potentialSuffix)
          g_logger.debug("Checking if \"{}\" exists".format(potentialPath))
          if (os.path.exists(potentialPath)):
            absolutePath = potentialPath
            return absolutePath

  return absolutePath
  

def main():
  #Get args 
  parser = argparse.ArgumentParser(description='(Version {}) Compile CLA program description into CSR field values'.format(g_program_version))
  parser.add_argument("programPath", type=str, help='Path to the yaml file that describes the desired CLA program')
  parser.add_argument('--busInfoPath', type=str, help='Path to the json file that contains information on the debug bus implementation. This json can be generated using generateClaDoc.py')
  parser.add_argument("--outputPath", type=str, help="Output path for where CSR fields will be dumped in a yaml file")
  parser.add_argument("--logName", type=str, default="compileClaProgram.log", help="Name of output log file")
  args = parser.parse_args()

  global g_logger
  g_logger = getLogger(args.logName)

  try:
    claInfoPath = args.busInfoPath
    programPath = args.programPath
    outputPath = "value_dump.{}".format(os.path.basename(programPath))
    if (args.outputPath):
      outputPath = str(args.outputPath)

    #Open CLA program description
    g_logger.info("Opening program description \"{}\"".format(programPath))
    if (not os.path.exists(programPath)):
      g_logger.info("\"{}\" not found. Searching for file outside of bazel sandbox".format(programPath))
      absolutePath = escapeBazelSandbox(programPath)
      if (absolutePath is None):
        g_logger.error("Path \"{}\" does not exist".format(programPath))
        g_logger.error("CWD={}".format(os.getcwd()))
        sys.exit()
      g_logger.info("\"{}\" found at \"{}\"".format(programPath, absolutePath))
      programPath = absolutePath

    programFile = open(programPath, "r")
    programDict = yaml.load(programFile, Loader=yaml.SafeLoader)
    programFile.close()

    #Extract counter aliases
    if ("COUNTERS" in programDict):
      g_logger.info("Parsing CLA counters")
      counterNameList = programDict["COUNTERS"]
      if (not isinstance(counterNameList, list)):
        g_logger.error("\"COUNTERS\" must be a list of strings")
        sys.exit()

      for counterName in counterNameList:
        if (not isinstance(counterName, str)):
          g_logger.error("\"COUNTERS\" must be a list of strings")
          sys.exit()

        g_claCounterAliases.append(counterName)

    if (len(g_claCounterAliases) > g_availableCounters):
      g_logger.error("{} counters defined. Only {} supported".format(len(g_claCounterAliases), g_availableCounters))
      sys.exit()

    #Extract custom opcodes
    if ("CUSTOM_ACTIONS" in programDict):
      g_logger.info("Parsing custom action aliases")
      for actionName in programDict["CUSTOM_ACTIONS"]:
        opcodeVal = programDict["CUSTOM_ACTIONS"][actionName]
        try:
          g_customActionOpcodes[str(actionName)] = str2int(opcodeVal)
        except:
          g_logger.error("Could not parse custom action \"{}\"".format(actionNames))
          g_logger.error("Field value must be either int or hex")
          sys.exit()

    #Generate state node objs
    g_logger.info("Constructing node dictionary")
    nodeDict = {}
    for nodeName in programDict["NODES"]:
      g_logger.info("Parsing node \"{}\"".format(nodeName))
      nodeDict[nodeName] = StateNode(nodeName, programDict["NODES"][nodeName])

    #Get CLA debug bus info
    global g_busConfigProvided
    claInfoDict = {}
    if (claInfoPath is None):
      #No debug bus info provided. Create dummy debug mux
      g_logger.warning("No debug bus config provided. Instantiating default dummy mux")
      g_busConfigProvided = False
      claInfoDict = {
                      "CLA Input": "dbm_out", 
                      "Debug Mux Instances": {
                        "debug_bus_mux_A": {
                          "DEBUG_MUX_ID": 0, 
                          "DbgMuxSelCsr": "default_dummy_mux", 
                          "Debug Bus Inputs": [
                            {
                              "Bit Width": 64, 
                              "Bus Lower Index": 0, 
                              "Bus Upper Index": 63, 
                              "Lane Lower": 0, 
                              "Lane Lower Index": 0, 
                              "Lane Upper": 3, 
                              "Lane Upper Index": 15, 
                              "Name": "debug_signals", 
                              "Sub Buses": [], 
                              "Type": "logic [63:0]"
                            }
                          ], 
                          "Debug Bus Output": "dbm_out", 
                          "LANE_WIDTH": 16
                        }
                      }
                    }

    else:
      #Debug bus info path provided. Parse json file
      g_busConfigProvided = True
      g_logger.info("Parsing debug mux info \"{}\"".format(claInfoPath))
      if (not os.path.exists(claInfoPath)):
        g_logger.info("\"{}\" not found. Searching for file outside of bazel sandbox".format(claInfoPath))
        absolutePath = escapeBazelSandbox(claInfoPath)
        if (absolutePath is None):
          g_logger.error("Path \"{}\" does not exist".format(claInfoPath))
          g_logger.error("CWD={}".format(os.getcwd()))
          sys.exit()
        g_logger.info("\"{}\" found at \"{}\"".format(claInfoPath, absolutePath))
        claInfoPath = absolutePath

      claInfoFile = open(claInfoPath, "r")
      claInfoDict = json.load(claInfoFile)
      claInfoFile.close()

    #Parse CLA unit info
    global g_debugMuxes
    try:
      #Add CLA input signal to g_debugSignals
      claInputSignalName = claInfoDict["CLA Input"]
      claInputSignalName = str(claInputSignalName).strip()
      if (len(claInputSignalName) == 0):
        g_logger.error("Invalid \"CLA Input\" \"\" defined in \"{}\"".format(claInfoPath))
        sys.exit()

      g_debugSignals[claInputSignalName] = DebugBusSignal(claInputSignalName, busDict={
                                                                                        "Bit Width": g_claDebugInputWidth, 
                                                                                        "Bus Lower Index": 0, 
                                                                                        "Bus Upper Index": g_claDebugInputWidth-1, 
                                                                                        "Lane Lower": -1, 
                                                                                        "Lane Lower Index": -1, 
                                                                                        "Lane Upper": -1, 
                                                                                        "Lane Upper Index": -1, 
                                                                                        "Name": claInputSignalName, 
                                                                                        "Sub Buses": [], 
                                                                                        "Type": "logic [{}:0]".format(g_claDebugInputWidth-1)
                                                                                      })

      #Flatten all mux input signals
      for mux_name in claInfoDict["Debug Mux Instances"]:
        mux_info = claInfoDict["Debug Mux Instances"][mux_name]
        additional_output_stages = 0
        if ("additional_output_stages" in mux_info):
          additional_output_stages = mux_info["additional_output_stages"]

        muxObj = DebugMux(mux_name, output_signalname=mux_info["Debug Bus Output"], mux_select_csr=mux_info["DbgMuxSelCsr"], mux_id=mux_info["DEBUG_MUX_ID"], lane_width=mux_info["LANE_WIDTH"], output_width=64, cla_input_signalname=claInputSignalName, additional_output_stages=additional_output_stages)
        g_debugMuxes[mux_name] = muxObj

        flattenDebuBusSignals(muxObj, claInfoDict["Debug Mux Instances"][mux_name]["Debug Bus Inputs"])
    except:
      g_logger.error(traceback.format_exc())
      g_logger.error("Error while parsing \"{}\"".format(claInfoPath))
      sys.exit()

    #Calculate CSR values
    if not ("START_NODE" in programDict):
      g_logger.error("Required field \"START_NODE\" is not defined")
      sys.exit()
    startNode = programDict["START_NODE"]
    g_logger.info("Compiling CLA CSR field values")
    csrValues = compileCsrValues(nodeDict, startNode)

    #Output CSR values to file
    g_logger.info("Writing field values to \"{}\"".format(outputPath))
    csrValues.writeToYamlFile(outputPath)

    csvOutputPath = outputPath.replace(".yaml", ".csv")
    g_logger.info("Writing field values to \"{}\"".format(csvOutputPath))
    csrValues.writeToCsvFile(csvOutputPath)

    g_logger.info("Compilation success")
  except Exception as e:
      g_logger.error(traceback.format_exc())
      g_logger.critical("UNHANDLED ERROR!")
      sys.exit()

  
if __name__ == "__main__":
  main()
