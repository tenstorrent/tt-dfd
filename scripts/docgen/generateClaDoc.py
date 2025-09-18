import os
import math
import traceback
import json
import argparse
import sys
import logging
import re


###################################
# Logging
###################################
g_program_version = "1.2.0"

def getLogger(name, console="ERROR", outputdir="", logFile=True, fileLevel="DEBUG"):
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
	formatter = logging.Formatter('(%(asctime)s) %(levelname)s: generateClaDoc(v{}): %(message)s'.format(g_program_version), datefmt='%H:%M:%S')
	if (logFile):
		fh.setFormatter(formatter)
	ch.setFormatter(formatter)

	# add the handlers to the logger
	if (logFile):
		logger.addHandler(fh)
	logger.addHandler(ch)

	return logger

g_logger = None

###################################
# Verilog Source Parsing
###################################
class StructField:
  def __init__(self, name, fieldType):
    self.name = name
    self.fieldType = fieldType
    self.bitWidth = None

  def __str__(self):
    selfDict = {}
    selfDict["name"] = self.name
    selfDict["fieldType"] = self.fieldType
    selfDict["bitWidth"] = self.bitWidth
    
    return str(selfDict)

  def __repr__(self):
    return str(self)

  def replaceParam(self, paramDefObj):
    #Replace paramter in bit width
    if not (self.bitWidth is None):
      if (isinstance(self.bitWidth, str)):
        self.bitWidth = self.bitWidth.replace("{}{}".format(paramDefObj.packagePrefix, paramDefObj.name), str("({})".format(paramDefObj.paramValue)))
        self.bitWidth = self.bitWidth.replace(paramDefObj.name, str("({})".format(paramDefObj.paramValue)))
    #Replace paramter in field type
    if not (self.fieldType is None):
      if (isinstance(self.fieldType, str)):
        self.fieldType = self.fieldType.replace("{}{}".format(paramDefObj.packagePrefix, paramDefObj.name), str("({})".format(paramDefObj.paramValue)))
        self.fieldType = self.fieldType.replace(paramDefObj.name, str("({})".format(paramDefObj.paramValue)))

  def caclulateBitWidth(self, definitionDict):
    #Check if bit width is already calculated
    if (isinstance(self.bitWidth, int)):
      return

    #Get bit width based on field type
    if ("logic" in self.fieldType):
      #Get bitwidth expression if field type is logic
      bitWidth = 1
      if ("[" in self.fieldType):
        bitWidth = None
        widthExpression = extractBitWidthExpr(self.fieldType)
        try:
          bitWidth = int(eval(widthExpression))
        except:
          g_logger.warning(traceback.format_exc())
          raise ValueError("Could not evaluate bitwidth expression \"{}\"".format(widthExpression))

      if (isinstance(bitWidth, int)):
        self.bitWidth = bitWidth
    else:
      if (self.fieldType in definitionDict):
        defObj = definitionDict[self.fieldType]
        defObj.caclulateBitWidth(definitionDict)
        if not (defObj.bitWidth is None):
          self.bitWidth = defObj.bitWidth
      else:
        g_logger.warning(self)
        raise ValueError("Could not find \"{}\" definition. Make sure you specified all required pkg files".format(self.fieldType))

class Definition:
  def __init__(self, name, parentPackageName, defType, text):
    self.name = name
    
    self.parentPackageName = parentPackageName
    self.packagePrefix = ""
    if (len(self.parentPackageName) > 0):
      self.packagePrefix = "{}::".format(self.parentPackageName)

    if (name == "logic"):
      #print(name)
      #print(defType)
      #print(text)
      raise ValueError()
    self.defType = defType
    self.text = text

    self.paramValue = None
    self.structFields = None
    self.enumNames = None

    self.bitWidth = None
    self.bitWidthError = False

  def __str__(self):
    selfDict = {}
    selfDict["name"] = self.name
    selfDict["defType"] = self.defType
    
    return str(selfDict)

  def __repr__(self):
    return str(self)

  def setParamValue(self, value):
    self.paramValue = value

  def addStructField(self, fieldObj):
    if (self.structFields is None):
      self.structFields = []

    self.structFields.append(fieldObj)

  def addEnumName(self, name, value):
    if (self.enumNames is None):
      self.enumNames = {}

    self.enumNames[name] = value

  def setBitWidth(self, value):
    self.bitWidth = value

  def replaceParam(self, paramDefObj):
    try:
      #Replace paramter in bit width
      if not (self.bitWidth is None):
        if (isinstance(self.bitWidth, str)):
          self.bitWidth = self.bitWidth.replace("{}{}".format(paramDefObj.packagePrefix, paramDefObj.name), str(paramDefObj.paramValue))
          self.bitWidth = self.bitWidth.replace(paramDefObj.name, str(paramDefObj.paramValue))
      #Replace paramter in param value
      if not (self.paramValue is None):
        if (isinstance(self.paramValue, str)):
          self.paramValue = self.paramValue.replace("{}{}".format(paramDefObj.packagePrefix, paramDefObj.name), str(paramDefObj.paramValue))
          self.paramValue = self.paramValue.replace(paramDefObj.name, str(paramDefObj.paramValue))
      #Replace paramter in struct fields
      if not (self.structFields is None):
        for fieldObj in self.structFields:
          fieldObj.replaceParam(paramDefObj)
      #Replace paramter in enums
      if not (self.enumNames is None):
        for enum in self.enumNames:
          if not (self.enumNames[enum] is None):
            self.enumNames[enum] = self.enumNames[enum].replace("{}{}".format(paramDefObj.packagePrefix, paramDefObj.name), str(paramDefObj.paramValue))
            self.enumNames[enum] = self.enumNames[enum].replace(paramDefObj.name, str(paramDefObj.paramValue))
    except:
      g_logger.error(traceback.format_exc())
      g_logger.error("Could not replace parameter {} in {}".format(paramDefObj, self))
      sys.exit()

  def caclulateBitWidth(self, definitionDict):
    try:
      #Check if bit width calculation would be valid
      if (self.defType == "localparam"):
        return 

      #Check if bit width is already calculated
      if (isinstance(self.bitWidth, int)):
        return

      #Check if bit width is can be calculated from expression
      if (isinstance(self.bitWidth, str)):
        try:
          value = int(eval(self.bitWidth))
          if (isinstance(value, int)):
              self.bitWidth = value
              return
        except:
          g_logger.warning(traceback.format_exc())
          raise ValueError("Could not evaluate bitwidth expression \"{}\"".format(self.bitWidth))

      #Calculate bitwidth by summing all struct fields
      if (self.defType == "struct"):
        widthSum = 0
        for fieldObj in self.structFields:
          try:
            fieldObj.caclulateBitWidth(definitionDict)
          except:
            g_logger.warning(traceback.format_exc())
            raise ValueError("Could not calculate bit width for struct field \"{}\"".format(fieldObj))

          if not (fieldObj.bitWidth is None):
            widthSum += fieldObj.bitWidth

        self.bitWidth = widthSum
    except:
      self.bitWidthError = True
      g_logger.warning(traceback.format_exc())
      raise ValueError("Could not calculate bit width for \"{}{}\" definition".format(self.packagePrefix, self.name))


def cleanLine(text):
  cleanLine = text

  longCommentStartIndex = cleanLine.find("/*")
  longCommentEndIndex = cleanLine.find("*/")
  shortCommentStartIndex = cleanLine.find("//")

  if (("/*" in cleanLine) and ((longCommentStartIndex < shortCommentStartIndex) or (shortCommentStartIndex == -1))):
    if ("*/" in cleanLine):
        if ((cleanLine.find("*/")+2) < len(cleanLine)):
          cleanLine = cleanLine[0:cleanLine.find("/*")] + cleanLine[cleanLine.find("*/")+2:]
        else:
          cleanLine = cleanLine[0:cleanLine.find("/*")]
    else:
      cleanLine = cleanLine[0:cleanLine.find("/*")] 
  if (("*/" in cleanLine) and ((longCommentEndIndex < shortCommentStartIndex) or (shortCommentStartIndex == -1))):
    if ((cleanLine.find("*/")+2) < len(cleanLine)):
      cleanLine = cleanLine[cleanLine.find("*/")+2:]
    else:
      cleanLine = ""
  if ("//" in cleanLine):
    cleanLine = cleanLine[0:cleanLine.find("//")]

  cleanLine = cleanLine.strip() + " " 

  return cleanLine


def getDefinitionStrings(text):
  definitionStrings = []
  currentPackageName = ""
  stringAccumulator = ""
  typedef = False
  for string in text.split(";"):
    if (re.search("^\s*package\s", string)):
      packageName = string.replace("package", "").strip()
      if (len(packageName) > 0):
        if (len(packageName.split()) == 1):
          currentPackageName = packageName

    if ("localparam" in string):
      definitionStrings.append((string, currentPackageName))
      continue

    if ("typedef" in string):
      typedef = True

    if (typedef):
      stringAccumulator += string + ";"
      if ("}" in string):
        typedef = False
        definitionStrings.append((stringAccumulator, currentPackageName))
        stringAccumulator = ""
        continue

  return definitionStrings
    

def evalInlineConditionals(string):
  #Recursion base case
  if not ("?" in string):
    return string

  #Find first "?"
  first_question_indx  = None
  current_parenthesis_depth = 0
  pareDepthList = []
  first_question_parenthesis_depth = None
  for charIndx in range(len(string)):
    char = string[charIndx]

    if (char == "("):
      pareDepthList.append(current_parenthesis_depth)
      current_parenthesis_depth += 1
    elif (char == ")"):
      current_parenthesis_depth -= 1
      pareDepthList.append(current_parenthesis_depth)
    else:
      pareDepthList.append(current_parenthesis_depth)

    if (char == "?"):
      first_question_indx = charIndx
      first_question_parenthesis_depth = current_parenthesis_depth

  #Isolate first "?" expression within its parenthesis depth
  startIdx = first_question_indx
  endIdx = first_question_indx

  for charIndx in range(first_question_indx, -1, -1):
    current_parenthesis_depth = pareDepthList[charIndx]
    if (current_parenthesis_depth < first_question_parenthesis_depth):
      break
    startIdx = charIndx

  for charIndx in range(first_question_indx, len(pareDepthList), 1):
    current_parenthesis_depth = pareDepthList[charIndx]
    if (current_parenthesis_depth < first_question_parenthesis_depth):
      break
    endIdx = charIndx

  expression_string = string[startIdx:endIdx+1]

  #Split expression_string into condition_expr, true_expr, false_expr
  first_question_indx  = None
  last_colon_indx = None
  for charIndx in range(len(expression_string)):
    char = expression_string[charIndx]

    if (char == "?") and (first_question_indx is None):
      first_question_indx = charIndx
    if (char == ":"):
      last_colon_indx = charIndx
  
  condition_expr = expression_string[0:first_question_indx].strip()
  true_expr = expression_string[first_question_indx+1:last_colon_indx].strip()
  false_expr = expression_string[last_colon_indx+1:].strip()

  #Handle nested conditionals recursively
  condition_expr = evalInlineConditionals(condition_expr)
  true_expr = evalInlineConditionals(true_expr)
  false_expr = evalInlineConditionals(false_expr)

  #Evaluate condition
  condition_true = None
  try:
    condition_true = bool(eval(condition_expr))
  except Exception as e:
    g_logger.warning(traceback.format_exc())
    if (re.search("[A-Za-z]", condition_expr)):
      g_logger.warning("Looks like not all paramters were replaced in the conditional expression\"{}\". Make sure you have included paths to all package file dependancies in the flop info file".format(condition_expr))
    raise ValueError("Could not evaluate the condition \"{}\" inside the conditional expression \"{}\"".format(condition_expr, expression_string))

  if (condition_true):
    return string.replace(expression_string, true_expr)
  else:
    return string.replace(expression_string, false_expr)


def extractBitWidthExpr(widthString):
  while ("?" in widthString):
    widthString = evalInlineConditionals(widthString)

  bitIndexes = widthString[widthString.find("[")+1:widthString.find("]")]
  widthExpression = "({})+1".format(bitIndexes.replace(":", ")-("))
  widthExpression = widthExpression.replace(" ", "").strip()
  if ("$clog2" in widthExpression):
    startIndx = widthExpression.find("$clog2")
    openIndx = None
    endIndx = None
    openParenCnt = 0
    closeParenCnt = 0
    for charIndx in range(startIndx, len(widthExpression)):
      if (widthExpression[charIndx] == "("):
        openParenCnt += 1
        if (openParenCnt == 1):
          openIndx = charIndx
      if (widthExpression[charIndx] == ")"):
        closeParenCnt += 1

      if (openParenCnt > 0) and (openParenCnt==closeParenCnt):
        endIndx = charIndx
        break

    logOperand = widthExpression[openIndx+1:endIndx]
    widthExpression = "math.ceil({}math.log({},2){})".format(widthExpression[0:startIndx], logOperand, widthExpression[endIndx+1:])

  return widthExpression


def calcLogicBitWidth(defString):
  #Get list of array dimension expressions
  widthExpressions = defString.replace("logic", "").strip().split("]")
  widthExpressions = ["{}]".format(i.strip()) for i in widthExpressions if len(i.strip()) > 0]

  finalWidth = None
  for exprStr in widthExpressions:
    #Determine width of this dimension
    expr = extractBitWidthExpr(exprStr)
    dimBitWidth = None
    try:
      dimBitWidth = int(eval(expr))
    except:
      g_logger.warning(traceback.format_exc())
      raise ValueError("Could not evaluate bitwidth expression \"{}\" extracted from \"{}\" in \"{}\"".format(expr, exprStr, defString))

    #Update finalWidth
    if (finalWidth is None):
      #This is the first dimension
      finalWidth = dimBitWidth
    else:
      #Multidimensional array. Multiply bit widths
      finalWidth = finalWidth*dimBitWidth

  if (finalWidth is None):
    #No dimensions defined. Must be a 1 bit logic
    finalWidth = 1

  return finalWidth


def parseParameter(string, packageName):
  g_logger.debug("Parsing parameter \"{}\"".format(string))

  name = string.split("=")[0].split()[-1]
  value = string[string.find("=")+1:].strip()

  defObj = Definition(name=name, parentPackageName=packageName, defType="localparam", text=string)
  defObj.setParamValue(value)

  return defObj


def parseEnum(string, packageName):
  g_logger.debug("Parsing enum \"{}\"".format(string))

  name = string.split("}")[-1].strip().replace(";","")
  defObj = Definition(name=name, parentPackageName=packageName, defType="enum", text=string)

  #Determine width of enum
  widthString = string.split("{")[0].split("enum")[-1]
  widthExpression = extractBitWidthExpr(widthString)
  defObj.setBitWidth(widthExpression)

  #Extract enum names and values
  enumDefList = string[string.find("{")+1:string.find("}")].split(",")
  for enumDef in enumDefList:
    try:
      name = enumDef.split("=")[0].strip()
      
      value = None
      if (len(enumDef.split("=")) > 1):
        value = enumDef.split("=")[1].strip()
        
      defObj.addEnumName(name, value)
    except:
      g_logger.error(traceback.format_exc())
      g_logger.error("Error parsing \"{}\"".format(enumDef))
      sys.exit()

  return defObj


def parseStruct(string, packageName):
  g_logger.debug("Parsing struct \"{}\"".format(string))

  name = string.split("}")[-1].strip().replace(";","")
  defObj = Definition(name=name, parentPackageName=packageName, defType="struct", text=string)

  #Extract struct fields
  fieldDefList = string[string.find("{")+1:string.find("}")].split(";")
  for fieldDef in fieldDefList:
    fieldDefSplit = fieldDef.replace("]", "] ").replace("[", "[ ").strip().split()
    if (len(fieldDefSplit) > 1):
      name = fieldDefSplit[-1]
      fieldType = " ".join(fieldDefSplit[0:-1])
      fieldObj = StructField(name=name, fieldType=fieldType)
      defObj.addStructField(fieldObj)

  return defObj


def parseDefinition(string, packageName):
  defObj = None

  if ("localparam" in string):
    defObj = parseParameter(string, packageName)
  if ("typedef" in string):
    defType = string.split()[1]
    if ("enum" in defType):
      defObj = parseEnum(string, packageName)
    if ("struct" in defType):
      defObj = parseStruct(string, packageName)

  return defObj


def extractMacroDefines(pkgTxt, macroDefines):
  searchTxt = pkgTxt

  #Find all defined macros in pkgTxt
  newMacros = []
  nxt_define_indx  = searchTxt.find("`define")
  while(nxt_define_indx != -1):
    searchTxt = searchTxt[nxt_define_indx+len("`define"):].strip()
    macroName = searchTxt.split()[0]
    newMacros.append(macroName)

    searchTxt = searchTxt[searchTxt.find(macroName)+len(macroName):]
    nxt_define_indx  = searchTxt.find("`define")

  #Remove macro definitions from pkgTxt
  pkgTxt = pkgTxt.replace("`define", "")
  for macroName in newMacros:
    pkgTxt = pkgTxt.replace(macroName, "")

  macroDefines += newMacros
  
  return (pkgTxt, macroDefines)


def evalCompilationFlags(pkgTxt, macroDefines):
  #Find first "`if"
  first_ifdef_indx  = pkgTxt.find("`if")

  #Update defined macros for everything preceeding first_ifdef_indx
  preceedingTxt = pkgTxt[:first_ifdef_indx+1]
  preceedingTxt, macroDefines = extractMacroDefines(preceedingTxt, macroDefines)

  #Recursion base case
  if (first_ifdef_indx == -1):
    return pkgTxt

  g_logger.debug("Currently defined macros = {}. Evaluating compilation flags in \"{}\"".format(macroDefines, pkgTxt))

  #Isolate first "`if" expression within its endif depth
  startIdx = first_ifdef_indx
  endIdx = len(pkgTxt)

  ifDepth = [0 for i in range(startIdx)]
  for charIndx in range(startIdx, len(pkgTxt)):
    subStr = pkgTxt[startIdx:charIndx+1]
    currentIfDepth = subStr.count("`ifdef ") + subStr.count("`ifndef ") - subStr.count("`endif ")

    ifDepth.append(currentIfDepth)
    if (ifDepth[-2] > 0) and (currentIfDepth == 0):
      endIdx = charIndx
      break
    
  ifdefExpr = pkgTxt[startIdx:endIdx+1].strip()
  ifDepth = ifDepth[startIdx:]

  #Extraction condition type and condition macro
  conditionStart = 0
  conditionEnd = None

  macroStarted = False
  for charIndx in range(len(ifdefExpr)):
    if (not (re.search("\s", ifdefExpr[charIndx]))) and (ifDepth[charIndx] > 0):
      macroStarted = True
    if ((re.search("\s", ifdefExpr[charIndx])) and macroStarted):
      conditionEnd = charIndx
      break

  condition_expr = ifdefExpr[conditionStart:conditionEnd]
  conditionType = condition_expr.strip().split()[0]
  conditionMacro = condition_expr.strip().split()[-1]

  #Determine if this ifdef has an else block
  maskedExpr = ""
  for charIndx in range(len(ifdefExpr)):
    if (ifDepth[charIndx] > 1):
      maskedExpr += " "
    else:
      maskedExpr += ifdefExpr[charIndx]

  elseIndx = maskedExpr.find("`else")
  
  #Extract true string and false string
  true_str = ifdefExpr[conditionEnd:-1*len("`endif ")]
  false_str = ""

  if (elseIndx >= 0):
    true_str = ifdefExpr[conditionEnd:elseIndx]
    false_str = ifdefExpr[elseIndx+len("`else"):-1*len("`endif ")]

  #Evaluate conidtion
  insertedText = ""
  if (conditionType == "`ifdef") and (conditionMacro in macroDefines):
    insertedText = evalCompilationFlags(true_str, macroDefines)
  elif (conditionType == "`ifndef") and (not (conditionMacro in macroDefines)):
    insertedText = evalCompilationFlags(true_str, macroDefines)
  else:
    insertedText = evalCompilationFlags(false_str, macroDefines)

  #Replace ifdef expression in package text
  finalTxt = "{} {} {}".format(preceedingTxt, insertedText, pkgTxt[endIdx:])
  
  return finalTxt


def parsePkgFile(filePath, macroDefines):
  g_logger.info("Parsing package file \"{}\"".format(filePath))

  pkgFile = open(filePath, "r")

  #Sanatize text from file. Remove comments
  line = pkgFile.readline()
  cleanText = ""
  longComment = False
  while(line):
    if ("*/" in line):
      longComment = False
    if (not longComment):
      cleanText += cleanLine(line)
    if (("/*" in line) and (not ("*/" in line))):
      longComment = True

    line = pkgFile.readline()

  pkgFile.close()

  #Evaluate all compilation flags
  while ("`if" in cleanText) or ("`define" in cleanText):
    cleanText = evalCompilationFlags(cleanText, macroDefines)

  #Split file text into definitions
  definitionStrings = getDefinitionStrings(cleanText)
  
  #Parse definition strings
  definitionDict = {}
  for stringTup in definitionStrings:
    string, packageName = stringTup
    defObj = parseDefinition(string, packageName)
    if not (defObj is None):
      definitionDict[defObj.name] = defObj

  return definitionDict


def replaceAllParameters(definitionDict):
  g_logger.info("Replacing all parameters with values")

  #Replace paramters from longest length to shortest
  defNameList = sorted(list(definitionDict.keys()), key=len)
  defNameList.reverse()

  for defName in defNameList:
    defObj = definitionDict[defName]
    if (defObj.defType == "localparam"):
      #Replace all uses of this paremter with parameter value
      for targetName in definitionDict:
        targetDef = definitionDict[targetName]
        targetDef.replaceParam(defObj)


def calculateBitWidths(definitionDict):
  g_logger.debug("Calculating bit widths")
  for defName in definitionDict:
    defObj = definitionDict[defName]
    try:
      defObj.caclulateBitWidth(definitionDict)
    except:
      pass
      g_logger.warning(traceback.format_exc())
      g_logger.warning("BIT WIDTH CALCULATION ERROR \"{}\"\n\n".format(defName))


def replaceAllCfgParameters(definitionDict, inputDict):
  g_logger.info("Replacing all parameters used in cfg file with values")

  #Replace paramters from longest length to shortest
  defNameList = sorted(list(definitionDict.keys()), key=len)
  defNameList.reverse()

  inputDictStr = json.dumps(inputDict, indent=2, sort_keys=True)

  for defName in defNameList:
    defObj = definitionDict[defName]
    if (defObj.defType == "localparam"):
      #Replace all uses of this paremter with parameter value
      inputDictStr = inputDictStr.replace(defObj.name, str(defObj.paramValue))

  #Return new dict with replaces params
  sanitizedDict = json.loads(inputDictStr)
  return sanitizedDict

###################################
# Bus Index and Lane Calculation
###################################
class BusInfo:
  def __init__(self, name, varType, upperIndx, lowerIndx, laneWidth, definitionDict):
    self.name = name
    self.varType = varType
    self.upperIndx = upperIndx
    self.lowerIndx = lowerIndx
    self.laneWidth = laneWidth
    self.laneUpper = int(self.upperIndx/laneWidth)
    self.laneLower = int(self.lowerIndx/laneWidth)
    self.laneUpperIndx = int(self.upperIndx%laneWidth)
    self.laneLowerIndx = int(self.lowerIndx%laneWidth)
    self.width = self.upperIndx - self.lowerIndx + 1

    #Get bus info for all sub buses
    self.subBuses = []
    if (self.varType in definitionDict):
      defObj = definitionDict[self.varType]
      if (defObj.defType == "struct"):
        fieldUpperInx = self.upperIndx
        for fieldObj in defObj.structFields:
          fieldName = fieldObj.name
          fieldType = fieldObj.fieldType
          fieldWidth = fieldObj.bitWidth
          fieldLowerIndx = fieldUpperInx-fieldWidth+1

          fieldBusInfo = BusInfo(fieldName, fieldType, fieldUpperInx, fieldLowerIndx, self.laneWidth, definitionDict)
          self.subBuses.append(fieldBusInfo)

          fieldUpperInx = fieldLowerIndx-1

  def __str__(self):
    selfDict = {}
    selfDict["name"] = self.name
    selfDict["varType"] = self.varType
    selfDict["width"] = self.width
    selfDict["bitIndexes"] = "[{}:{}]".format(self.upperIndx, self.lowerIndx)
    
    return str(selfDict)

  def __repr__(self):
    return str(self)

  def getDict(self):
    infoDict = {}
    infoDict["Name"] = self.name
    infoDict["Type"] = self.varType
    infoDict["Bit Width"] = self.width
    infoDict["Bus Upper Index"] = self.upperIndx
    infoDict["Bus Lower Index"] = self.lowerIndx
    infoDict["Lane Upper"] = self.laneUpper
    infoDict["Lane Lower"] = self.laneLower
    infoDict["Lane Upper Index"] = self.laneUpperIndx
    infoDict["Lane Lower Index"] = self.laneLowerIndx

    infoDict["Sub Buses"] = []
    for subBus in self.subBuses:
      infoDict["Sub Buses"].append(subBus.getDict())

    return infoDict

  def getFieldDepth(self):
    if (len(self.subBuses) == 0):
      return 1
    else:
      maxFieldDepth = 0
      for subBus in self.subBuses:
        subBusDepth = subBus.getFieldDepth()
        if (subBusDepth > maxFieldDepth):
          maxFieldDepth = subBusDepth

      return maxFieldDepth + 1

  def getCsvString(self):
    csvStr = "[{}:{}],LANE_{}[{}] : LANE_{}[{}],{}\n".format(self.upperIndx, self.lowerIndx, self.laneUpper, self.laneUpperIndx, self.laneLower, self.laneLowerIndx, self.name)
    if (len(self.subBuses) > 0):
      for subBus in self.subBuses:
        subBusStr = subBus.getCsvString()
        subBusStr = ",,,{}".format(subBusStr)
        subBusStr = subBusStr.replace("\n,,,","\n,,,,,,")
        csvStr += subBusStr

    return csvStr


def isLogicDef(defString):
  return (defString.strip().split()[0] == "logic")

def calculateBusIndexes(busInputList, laneWidth, definitionDict):
  #Get total bit width of debug bus inputs
  totalBitWidth = 0
  for variableDict in busInputList:
    varName = str(variableDict["Name"])
    varType = str(variableDict["Type"])
    if (varType in definitionDict):
      defObj = definitionDict[varType]
      if (defObj.bitWidthError):
        raise ValueError("Could not calculate bus indexes. Bus input \"{}\" has an unknown bitwith".format(varName))
      totalBitWidth += defObj.bitWidth
    elif (isLogicDef(varType)):
      totalBitWidth += calcLogicBitWidth(varType)
    else:
      raise ValueError("Could not find definition for variable type \"{}\". Make sure you specified all required pkg files".format(varType))

  #Generate per-variable bus info
  busIndxList = []
  upperIndx = totalBitWidth-1
  for variableDict in busInputList:
    varName = str(variableDict["Name"])
    varType = str(variableDict["Type"])

    bitWidth = None
    lowerIndx = None
    if (varType in definitionDict):
      defObj = definitionDict[varType]
      
      bitWidth = defObj.bitWidth
      lowerIndx = upperIndx-(bitWidth-1)
    elif (isLogicDef(varType)):
      bitWidth = calcLogicBitWidth(varType)
      lowerIndx = upperIndx-(bitWidth-1)
    else:
      raise ValueError("Could not find definition for variable type \"{}\". Make sure you specified all required pkg files".format(varType))

    busInfoObj = BusInfo(name=varName, varType=varType, upperIndx=upperIndx, lowerIndx=lowerIndx, laneWidth=laneWidth, definitionDict=definitionDict)
    busIndxList.append(busInfoObj)

    upperIndx = lowerIndx-1

  return busIndxList


###################################
# Main
###################################
def escapeBazelSandbox(filePath):
  absolutePath = None

  cwd = str(os.getcwd())
  suffixSplitStr = "build/bazel_output_base"
  if (suffixSplitStr in cwd):
    repoRoot = cwd.split(suffixSplitStr)[0]
    prefixSplitStr = "user_regr/"
    if (prefixSplitStr in repoRoot):
      repoRoot = repoRoot[repoRoot.find(prefixSplitStr)+len(prefixSplitStr):]
      repoRoot = os.path.join("/proj_risc/user_dev/", repoRoot)
    potentialPath = os.path.join(repoRoot, filePath)
    if (os.path.exists(potentialPath)):
      absolutePath = potentialPath

  return absolutePath

def main():
  #Get args
  parser = argparse.ArgumentParser(description='(Version {}) Generate CLA debug bus documentation. Extracts bit indexes and debug lanes for each input signal going into the debug mux.'.format(g_program_version))
  parser.add_argument('muxCfgPath', help='Path to the input json file. This specifies paths to the pkg dependencies and the inputs to your debug mux')
  parser.add_argument("--jsonOutputPath", type=str, default="debugBusInfo.json", help="Output path for where debug mux info json will be written")
  parser.add_argument("--csvOutputPath", type=str, default="debugBusInfo.csv", help="Output path for where debug mux info csv will be written")
  parser.add_argument("--logName", type=str, default="generateClaDoc.log", help="Name of output log file")
  args = parser.parse_args()

  global g_logger
  g_logger = getLogger(args.logName)
  g_logger.info("CWD={}".format(os.getcwd()))

  #Read json input file
  inputJsonPath = args.muxCfgPath
  if not (os.path.exists(inputJsonPath)):
    absolutePath = escapeBazelSandbox(inputJsonPath)
    if not (absolutePath is None):
      inputJsonPath = absolutePath
    else:
      g_logger.error("Mux config file \"{}\" does not exist".format(inputJsonPath))
      sys.exit()

  inputFile = open(inputJsonPath, "r")
  inputDict = json.load(inputFile)
  inputFile.close()

  #Parse pkg files
  pkgPaths = inputDict["Package Files"]
  macroDefines = []
  if ("Macro Defines" in inputDict):
    macroDefines = inputDict["Macro Defines"]

  definitionDict = {}
  for filePath in pkgPaths:
    if not (os.path.exists(filePath)):
      absolutePath = escapeBazelSandbox(filePath)
      if not (absolutePath is None):
        filePath = absolutePath
      else:
        g_logger.error("Package file \"{}\" does not exist".format(filePath))
        sys.exit()

    definitionDict.update(parsePkgFile(filePath, macroDefines))

  #Replace parameters in pkg definitions
  replaceAllParameters(definitionDict)

  #Calculate bit widths for all defined types
  calculateBitWidths(definitionDict)

  #Replace parameters in debug bus info file
  inputDict = replaceAllCfgParameters(definitionDict, inputDict)

  #Parse debug bus info file
  dbmInstances = {}
  for muxName in inputDict["Debug Mux Instances"]:
    muxInfo = inputDict["Debug Mux Instances"][muxName]
    busInputList = muxInfo["debug_signals_in"]
    
    laneWidth = muxInfo["LANE_WIDTH"]
    try:
      laneWidth = int(laneWidth)
    except:
      g_logger.warning(traceback.format_exc())
      g_logger.error("Invalid lane width \"{}\" defined for \"{}\"".format(laneWidth, muxName))
      sys.exit()
    
    busIndxList = []
    try:
      busIndxList = calculateBusIndexes(busInputList, laneWidth, definitionDict)
    except:
      g_logger.error(traceback.format_exc())
      g_logger.error("BUS INDEX CALCULATION ERROR")
      sys.exit()

    dbmInstances[muxName] = busIndxList

  g_logger.info("RTL Parsing Successful")

  #Dump info into JSON
  debugBusInfoDict = {}
  debugBusInfoDict["CLA Input"] = inputDict["CLA Input"]
  debugBusInfoDict["Debug Mux Instances"] = {}
  for muxName in dbmInstances:
    muxInfo = {}

    muxInfo["Debug Bus Output"] = inputDict["Debug Mux Instances"][muxName]["debug_bus_out"]
    muxInfo["DbgMuxSelCsr"] = inputDict["Debug Mux Instances"][muxName]["DbgMuxSelCsr"]
    muxInfo["LANE_WIDTH"] = int(inputDict["Debug Mux Instances"][muxName]["LANE_WIDTH"])
    muxInfo["DEBUG_MUX_ID"] = inputDict["Debug Mux Instances"][muxName]["DEBUG_MUX_ID"]
    muxInfo["additional_output_stages"] = 0
    if ("additional_output_stages" in inputDict["Debug Mux Instances"][muxName]):
      muxInfo["additional_output_stages"] = int(inputDict["Debug Mux Instances"][muxName]["additional_output_stages"])

    muxInfo["Debug Bus Inputs"] = []
    for inputInfo in dbmInstances[muxName]:
      muxInfo["Debug Bus Inputs"].append(inputInfo.getDict())

    debugBusInfoDict["Debug Mux Instances"][muxName] = muxInfo

  jsonPath = args.jsonOutputPath
  jsonFile = open(jsonPath, "w")
  jsonFile.write(json.dumps(debugBusInfoDict, indent=2, sort_keys=True))
  jsonFile.close()

  g_logger.info("CLA MUX info dumped to \"{}\"".format(os.path.join(os.getcwd(), jsonPath)))

  #Dump info into CSV
  #TODO: Add support for multiple muxes
  csvStr = ""
  maxFieldDepth = 0
  for inputInfo in busIndxList:
    fieldDepth = inputInfo.getFieldDepth()
    if (fieldDepth > maxFieldDepth):
      maxFieldDepth = fieldDepth

  for i in range(0, maxFieldDepth):
    csvStr += "Debug Bus Bit Indexes,Debug Bus Lanes,Signal Name,"
  csvStr += "\n"

  for inputInfo in busIndxList:
    csvStr += inputInfo.getCsvString()

  csvStr.replace("\n\n\n", "\n")

  csvPath = args.csvOutputPath
  csvFile = open(csvPath, "w")
  csvFile.write(csvStr)
  csvFile.close()

  g_logger.info("CLA MUX documentation created in \"{}\"".format(os.path.join(os.getcwd(), csvPath)))

main()