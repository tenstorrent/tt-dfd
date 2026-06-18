

function getFileContents(filepath)
{
		var return_data;
		$.ajax({
			url: filepath,
			type: 'GET',
			dataType: ($.browser.msie) ? "text" : "xml",
			async: false,
			timeout: 10000,
			error: function(){
				logError("'"+filepath+"' not loaded. Check file path.");
			},
			success: function(data){
				 var xml;
				 if (typeof data == "string") {
				   xml = new ActiveXObject("Microsoft.XMLDOM");
				   xml.async = false;
				   xml.loadXML(data);
				   return_data=xml;
				 } else {
				   return_data = data;
				 }
			}
		});
		
		return return_data;
}


function getCSVFileContents(filepath)
{
		var return_data;
		$.ajax({
			url: filepath,
			type: 'GET',
			dataType: "text",
			async: false,
			timeout: 10000,
			error: function(){
				logError("'"+filepath+"' not loaded. Check file path.");
			},
			success: function(data){
				 return_data = data;
			}
		});
		return return_data;
}





function XMLToString(oXML) 
{   
	if (window.ActiveXObject) {     
		return oXML.xml;
	} 
	else{
		return (new XMLSerializer()).serializeToString(oXML);
	}
}

function htmlspecialchars(str)
{ 
	return $('<span>').text(str).html();
}





////////////////////////////////////////////
/* function starts for DB_TOP_SUMMARY.XML*/
////////////////////////////////////////////

function getSingleNodeValue(xmlObj, key)
{
	return xmlObj.find(key).text();
}

function getTopSummaryCustomLogo(xmlObj)
{
	return getSingleNodeValue(xmlObj, "custom_logo");
	//return xmlObj.find("custom_logo").text();
}

function getTopSummaryTicks(xmlObj)
{
	//gets "items->category->attr_name" 
	var ticks =new Array();
	
	$(xmlObj).find('category').each(function(){
		ticks.push($(this).attr('name'));
	});//find category	
	
	return ticks;
	
}

function getTopSummaryCategoryTicks(xmlObj, category)
{
	
	var ticks =new Array();
	
		
	$(xmlObj).find("category[name='"+category+"']").find("item").each(function(){
		if(category=="Quality"){
			var temp_chunks=getUnslashedStr($(this).attr('name'));
			ticks.push(temp_chunks);
		}
		else{
			ticks.push(updateBlockSummaryTitle($(this).attr('name')));
		}
	});
			
	return ticks;
	
}


function getTopSummaryPassValues(xmlObj)
{
	//gets "items->category->attr_name" 
	var ticks =new Array();
	
	$(xmlObj).find('category').each(function(){
		//alert($(this).attr('pass'));
		ticks.push(parseInt($(this).attr('pass')));
	});//find category	
	
	
	return ticks;
	
}

function getTopSummaryCategoryPassValues(xmlObj, category)
{
	//gets "items->category->attr_name" 
	var ticks =new Array();
	$(xmlObj).find("category[name='"+category+"']").find("item").each(function(){
			ticks.push(parseInt($(this).attr('pass')));
	});//find items
	
	return ticks;
	
}





function getTopSummaryinProgressValues(xmlObj)
{
	//gets "items->category->attr_name" 
	var ticks =new Array();
	
	$(xmlObj).find('category').each(function(){
		//alert($(this).attr('in-process'));
		ticks.push(parseInt($(this).attr('in-process')));
	});//find category	
	return ticks;
	
}


function getTopSummaryCategoryinProcessValues(xmlObj, category)
{
	//gets "items->category->attr_name" 
	var ticks =new Array();
	$(xmlObj).find("category[name='"+category+"']").find("item").each(function(){
			ticks.push(parseInt($(this).attr('in-process')));
	});//find items
	
	return ticks;
	
}



function getTopSummaryFailValues(xmlObj)
{
	//gets "items->category->attr_name" 
	var ticks =new Array();
	xmlObj.find("items").each( function (){
		$(this).find('category').each(function(){
			//alert($(this).attr('fail'));
			ticks.push(parseInt($(this).attr('fail')));
		});//find category	
	});//find items
	return ticks;
	
}

function getTopSummaryCategoryFailValues(xmlObj, category)
{
	//gets "items->category->attr_name" 
	var ticks =new Array();
	$(xmlObj).find("category[name='"+category+"']").find("item").each(function(){
			ticks.push(parseInt($(this).attr('fail')));
	});//find items
	
	return ticks;
	
}

function getTopLevelCategoryNameByKey(xmlObj, key){
	return ($(xmlObj).find('category').eq(key).attr('name'));
}



function getBlockSummaryModules(xmlObj){
	var ticks =new Array();
	xmlObj.find("module").each( function (){
		ticks.push($(this).attr('name'));
		
	});//find items
	return ticks;
}
//function getBlockSummaryModules(xmlObj)

function getBlockSummaryDesignObjectivesByModuleName(xmlObj, moduleName){
	var ticks =new Array();
	$(xmlObj).find("module[name='"+moduleName+"']").find("design_objectives").find("category").each(function(){
			ticks.push($(this).attr('name'));
	});//find items
	return ticks;
}
//function getBlockSummaryDesignObjectivesByModuleName

function getBlockSummaryDistinctDesignObjectives(xmlObj){
	var ticks =new Array();
	$(xmlObj).find("module").find("design_objectives").find("category").each(function(){
		if(jQuery.inArray($(this).attr('name'),ticks) <= -1){
				ticks.push($(this).attr('name'));
		}
	});//find items
	return ticks;
	
}
//function getBlockSummaryDistinctDesignObjectives

function getBlockSummaryDistinctItemsByCategory(xmlObj, category){
	var ticks =new Array();
	$(xmlObj).find("module").find("design_objectives").find("category[name='"+category+"']").find("item").each(function(){
		if(jQuery.inArray($(this).attr('name'),ticks) <= -1){
				ticks.push($(this).attr('name'));
		}
	});//find items
	return ticks;
	
}
//function getBlockSummaryDistinctDesignObjectives





function getBlockSummaryQualityGoalsByModuleName(xmlObj, moduleName){
	var ticks =new Array();
	$(xmlObj).find("module[name='"+moduleName+"']").find("quality_goals").find("goal").each(function(){
			ticks.push($(this).attr('name'));
	});//find items
	return ticks;
}
//function getBlockSummaryQualityGoalsByModuleName


function getBlockSummaryDistinctQualityGoals(xmlObj){
	var ticks =new Array();
	$(xmlObj).find("module").find("quality_goals").find("goal").each(function(){
		if(jQuery.inArray($(this).attr('name'),ticks) <= -1){
				ticks.push($(this).attr('name'));
		}
	});//find items
	return ticks;
	
}
//function getBlockSummaryDistinctQualityGoals


function getAllActiveUnresolvedSeverity(){
	var strDashBoardMainXML=XMLToString(getFileContents("dashboard_data_files/DashBoard_Main.xml"));
	var xmlObj = $($.parseXML(strDashBoardMainXML));
	var ticks =new Array();
	for(var i=0; i<all_unresolved_severity.length;i++){
		if($(xmlObj).find("goal").eq(0).attr(all_unresolved_severity[i])){
			ticks.push(all_unresolved_severity[i]);
		}
	}
	return ticks;
}

function getAllActiveWaivedSeverity(){
	var strDashBoardMainXML=XMLToString(getFileContents("dashboard_data_files/DashBoard_Main.xml"));
	var xmlObj = $($.parseXML(strDashBoardMainXML));
	var ticks =new Array();
	for(var i=0; i<all_waived_severity.length;i++){
		if($(xmlObj).find("goal").eq(0).attr(all_waived_severity[i])){
			ticks.push(all_waived_severity[i]);
		}
	}
	return ticks;
}


function updateBlockSummaryTitle(title){
	var ret_val="";
	if(title=="Synchronization coverage"){ret_val= "Sync cov";}
	else if(title=="Failed properties"){ret_val= "Failures";}
	else if(title=="Partially-proven properties"){ret_val= "Partials";}
	else if(title=="Average depth of partially-proven properties"){ret_val= "Avg depth";}
	else if(title=="Minimum depth of partially-proven properties"){ret_val= "Min Depth";}
	else if(title=="Unsynchronized crossings"){ret_val= "Unsync";}
	else if(title=="Switching Power"){ret_val= "Switch pwr";}
	else if(title=="Internal Power"){ret_val= "Internal pwr";}
	else if(title=="Leakage Power"){ret_val= "Leakage pwr";}
	else if(title=="Total Power"){ret_val= "Total pwr";}
	else if(title=="Predicted power savings"){ret_val= "Power Savings";}
	else if(title=="Number of non gated registers"){ret_val= "# Non-gated flops";}
	else if(title=="Clock Gating percentage"){ret_val= "CG Status %";}
	else if(title=="Clock Gating efficiency"){ret_val= "CG Efficiency %";}
	else if(title=="Number of registers with new enable(ODC)"){ret_val= "# New-ODC";}
	else if(title=="Number of registers with new enable(STC)"){ret_val= "# New-STC";}
	else if(title=="Number of registers with stronger enable(ODC)"){ret_val= "# Strong-ODC";}
	else if(title=="Number of registers with stronger enable(STC)"){ret_val= "# Strong-STC";}
	else if(title=="Stuck at fault coverage"){ret_val= "Stuck-at fault cov";}
	else if(title=="Stuck at test coverage"){ret_val= "Stuck-at test cov";}
	else if(title=="Stuck-at fault coverage"){ret_val= "Stuck-at fault cov";}
	else if(title=="Stuck-at test coverage"){ret_val= "Stuck-at test cov";}
	else if(title=="Transition fault coverage"){ret_val= "Trans fault cov";}
	else if(title=="Transition test coverage"){ret_val= "Trans test cov";}
	else if(title=="Percentage of scannable flops"){ret_val= "% scannable flops";}
	else if(title=="Number of unverified false paths" || title=="Number of unverified FP"){ret_val= "# unverified FP";}
	else if(title=="Number of unverified multi-cycle paths" || title=="Number of unverified MCP"){ret_val= "# unverified MCP";}
	else if(title=="Percentage of ports constrained"){ret_val= "% ports constr";}
	else if(title=="Percentage of registers constrained"){ret_val= "% reg constr";}
	else if(title=="Maximum cyclomatic complexity"){ret_val= "Max complexity";}
	else if(title=="Registers"){ret_val= "Reg";}
	else if(title=="Synthesizable gates (NAND2 equivalent)"){ret_val= "Gates";}
	else if(title=="Total area"){ret_val= "Area";}
	else if(title=="Number of congested module instances"){ret_val= "Congestion";}
	else if(title=="Number of timing paths failing in core"){ret_val= "Timing (core)";}
	else if(title=="Number of timing paths failing on periphery"){ret_val= "Timing (periphery)";}
	else if(title=="Top module congestion"){ret_val= "Congestion";}
	else if(title=="Maximum logic levels in core"){ret_val= "Logic levels (core)";}
	else if(title=="Maximum logic levels on periphery"){ret_val= "Logic levels (periphery)";}
	else if(title=="Timing slack in core"){ret_val= "Timing slack (core)";}
	else if(title=="Timing slack on periphery"){ret_val= "Timing slack (periphery)";}
	else if(title=="Floorplan timing slack in core"){ret_val= "Floorplan slack (core)";}
	else if(title=="Floorplan timing slack on periphery"){ret_val= "Floorplan slack (periphery)";}
	else {ret_val= title.replace(/_/g," ");}
	
	return ret_val;
	
}


function addDotsToLongHeadings(str){
	var ret_val;
	if(str.length>=15){
		ret_val=str.substring(0, 10)+"..";
	}else{
		ret_val=str;
	}
	return ret_val;
}

function getUnslashedStr(str){
	var slash_exists=str.indexOf("/");
	if(slash_exists<=-1){
		return str;
	}else{
		var tmp_arr=str.split("/")
		var tmp_arr_length=tmp_arr.length;
		
		return tmp_arr[tmp_arr_length-1];
	}
}

function getFileExtensionByPath(filePath){
	var slash_exists=filePath.indexOf(".");
	if(slash_exists<=-1){
		return filePath;
	}else{
		var tmp_arr=filePath.split(".")
		var tmp_arr_length=tmp_arr.length;
		
		return tmp_arr[tmp_arr_length-1];
	}
}

function getColorForSeverity(str){
	sevName=$.trim(str).toLowerCase();
	if(sevName=="fatal"){return "#FF33CC";}
	if(sevName=="error"){return "#FF0000";}
	if(sevName=="warning"){return "#FF9900";}
	if(sevName=="info"){return "#6794CA";}
	if(sevName=="waived-error"){return "#64389A";}
	if(sevName=="waived-warning"){return "#FFFF00";}
	if(sevName=="waived-info"){return "#CCCCCC";}
	else{return "#000000";}
}
