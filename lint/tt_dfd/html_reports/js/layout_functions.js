// JavaScript Document
function checkConfiguration(){
		
		if(curBrowserName=="CH"){
			var tempXML=getFileContents(xmlDir+"/DB_Top_Summary.xml");
			if(tempXML==="" || typeof(tempXML)==="undefined"){
				displayIncompatibleOverlay(1);
				delete tempXML;
			}
		}//Chrome
		
		else if(curBrowserName=="IE"){
			if(curBrowserFullVersion<8){
				
				displayIncompatibleOverlay(2);
			}
		}//ie
		else if(curBrowserName=="FF"){
			if(curBrowserFullVersion<1){
				displayIncompatibleOverlay(3);
			}
		}//FF
		
		else{
			var tempXML=getFileContents(xmlDir+"/DB_Top_Summary.xml");
			if(tempXML==="" || typeof(tempXML)==="undefined"){
				displayIncompatibleOverlay(4);//1:browsername not ok
				delete tempXML;
			}
			
		}//any other browser (not compatible)
		
		
		
}//checkConfiguration






function displayIncompatibleOverlay(etype){
		var theDiv="dvIncompatibleOverlay";
		isBrowserIncompatible=true;//global var
		var tempDiv="<div  id=\""+theDiv+"\"  style=\"display:none\">";
		tempDiv+="<div class=\"ui-state-highlight ui-corner-all\" style=\"padding: 20px; padding-top:10px; height:300px; margin: 100px; \">";
		tempDiv+="<img src=\"img/spyglass_logo_white.jpg\" style=\"margin-right:50px;margin-bottom:200px;margin-top:10px;\" height=\"49\" align=\"left\" width=\"150\">";	
		
		if(etype=="1")
		{
			tempDiv+="<div><h3 style=\"color:#C40E00;\">Unable to open the SpyGlass DashBoard in Google Chrome("+curBrowserFullVersion+")</h3></div>";
			
			tempDiv+="<div><p>SpyGlass DashBoard is currently compatible with:</p><p><img src=\"./img/ie.png\" style=\"height:32px;width:32px;vertical-align:middle;padding-right:10px;\">Internet Explorer 8+ </p><p><img src=\"./img/ff.png\" style=\"height:32px;width:32px;vertical-align:middle;padding-right:10px;\">Firefox</p><p><strong>Please use a compatible HTML browser or <a href=\"./instructions.html#chrome\" target=\"_blank\">click here</a> for further instructions for Chrome</strong></p></div>";
		
		}
		
		if(etype=="2")
		{
			tempDiv+="<div  class=\"ui-state-error ui-corner-all\"><span class=\"ui-icon ui-icon-alert\" style=\"float: left; margin-right: .3em;\"></span>Outdated HTML Browser</div>";
			tempDiv+="<div><p>SpyGlass DashBoard is currently compatible with:</p><img src=\"./img/ie.png\" style=\"height:32px;width:32px;vertical-align:middle;padding-right:10px;\">Internet Explorer 8+ </p><p><img src=\"./img/ff.png\" style=\"height:32px;width:32px;vertical-align:middle;padding-right:10px;\">Firefox</p><p><strong>Please upgrade your browser to Internet Explorer 8 or Later.</strong></p></div>";
		
		}
		
		if(etype=="3")
		{
			tempDiv+="<div  class=\"ui-state-error ui-corner-all\"><span class=\"ui-icon ui-icon-alert\" style=\"float: left; margin-right: .3em;\"></span>Outdated HTML Browser</div>";
			tempDiv+="<div><p>SpyGlass DashBoard is currently compatible with:</p><p><img src=\"./img/ie.png\" style=\"height:32px;width:32px;vertical-align:middle;padding-right:10px;\">Internet Explorer 8+ </p><p><img src=\"./img/ff.png\" style=\"height:32px;width:32px;vertical-align:middle;padding-right:10px;\">Firefox 1.0+</p><p><strong>Please upgrade your Firefox browser</strong></p></div>";
		
		}
		if(etype=="4")
		{
			tempDiv+="<div  class=\"ui-state-error ui-corner-all\"><span class=\"ui-icon ui-icon-alert\" style=\"float: left; margin-right: .3em;\"></span>Incompatible HTML Browser</div>";
			tempDiv+="<div><p>SpyGlass DashBoard is currently compatible with:</p><p><img src=\"./img/ie.png\" style=\"height:32px;width:32px;vertical-align:middle;padding-right:10px;\">Internet Explorer 8+ </p><p><img src=\"./img/ff.png\" style=\"height:32px;width:32px;vertical-align:middle;padding-right:10px;\">Firefox</p><p><strong>Please open the DashBoard in any of the compatible browser from above list</div>";
		
		}
		tempDiv+="<p>&nbsp;</p><p>For further assistance, please contact <a href=\"mailto:spyglass_supprt@synopsys.com\"><strong>spyglass_support@synopsys.com</strong></a></p>";
		tempDiv+="<a onclick=\"closeOverlay('"+theDiv+"')\" href=\"javascript:void(0);\" class=\"linkBtn1\">Close this Window</a>";
		
		tempDiv+="</div></div></div>";
	
		$('body').append(tempDiv);
		$('#'+theDiv).show("highlight"); 
		$('#'+theDiv).attr("class","ui-widget-overlay");
}//function checkConfiguration







function logError(strError){	
	//arrLogErrors.push(strError);
	if(flag_debug){
		alert(strError);
	}
}







function displayErrorOverlay(){
	var theDiv="dvErrorLog";
	var tempDiv="<div id=\""+theDiv+"\" style=\"display:none\">";
	
	tempDiv+="<div class=\"ui-state-error ui-corner-all\" style=\"padding: 20px; padding-top:10px; height:250px; margin: 100px;\">";
	tempDiv+="<h1>SpyGlass SoC Dashboard - Error Log</h1>";
	tempDiv+="<h3>We are trying to track if any errors occurs during the dashboard run. This will help us improving the app.</h3>";
	if(arrLogErrors.length>0){
		tempDiv+="<ul>";
		for(var i=0;i<arrLogErrors.length;i++){
			tempDiv+="<li><span class=\"ui-icon ui-icon-alert\" style=\"float: left; margin-right: .3em;\"></span>"+arrLogErrors[i]+"</li>";
		}
		tempDiv+="</ul>";
		tempDiv+="<p>For any other clarifications, please contact <a href=\"mailto:spyglass_supprt@synopsys.com\"><strong>spyglass_support@synopsys.com</strong></a></p>";
	}else{
		tempDiv+="<p><strong>Good News:</strong> You have no errors recorded in this Dashboard session.</p>";
	}		
	
	tempDiv+="<a onclick=\"closeOverlay('"+theDiv+"')\" href=\"javascript:void(0);\">Close this Window</a>";
	tempDiv+="</div></div>";
	$('body').append(tempDiv);
	$('#'+theDiv).show("highlight"); 
	$('#'+theDiv).attr("class","ui-widget-overlay");
	
	
}






function closeOverlay(theDiv){
	$('#'+theDiv).hide("highlight");
}









function drawMainHeader(theDiv){
	var tmpHeaderStr="<div id=\"mainHeader\"><table style=\"width:100%\"><tr><td><img src=\"img/atrenta_web_logo_alpha_png.png\" alt=\"SpyGlass Logo\" id=\"mainHeaderLogo\"><div id=\"mainHeaderTitleLeft\">Please wait</div><br><div id=\"mainHeaderDescription\">while values and graphs will load...</div></td><td><img  alt=\"\" id=\"imgCustomerLogo\"></td></tr></table></div>";
	//alert(tmpHeaderStr);
	$('#'+theDiv).html(tmpHeaderStr);
}
function updateMainHeaderTitle(theText){
	if(theText!=""){
		$("#mainHeaderTitleLeft").html("SpyGlass DashBoard - "+theText);
	}else{
		$("#mainHeaderTitleLeft").html("SpyGlass DashBoard");
	}
}
function updateMainHeaderDescription(theText){
	$("#mainHeaderDescription").html(theText);
}
function updateCustomerLogo(imgPath, width, height, alt){
	$("#imgCustomerLogo").attr("src",imgPath);
	$("#imgCustomerLogo").attr("alt",alt);
	$("#imgCustomerLogo").css("width",width);
	$("#imgCustomerLogo").css("height",height);
}





function createTab(tabId, tabTitle, tabContent){
	
	var tabContainerId="cntMainTabs";
	var tabId="#tb-" + tabId;
	//alert(tabId+" : "+tabTitle);
	if($(tabId).length<=0) {	
		$('#'+tabContainerId).tabs( "add", tabId , tabTitle);
		$(tabId).html(tabContent);
	}
	
	if(tabId!="#tb-tbSummary" && tabId!="#tb-tbBlockSummaryDO" && tabId!="#tb-tbBlockSummaryQG"){
		var index = $('#'+tabContainerId+' a[href="'+tabId+'"]').parent().index();
		$(tabId).html(tabContent);
		$('#'+tabContainerId).tabs("select", index);
	}
	$(".ui-tabs-panel").height($(window).height()-135);

}




function drawMainTabs(tabContainerDiv){
	
	//initiate closable tabs, 
	//also sets focus on tab as soon as its created
	$('#'+tabContainerDiv).tabs({closable: true});
	$('#'+tabContainerDiv).tabs('remove', 0);

	/*
	$('#'+tabContainerDiv).bind("tabsadd", function(e, tab){
		$('#'+tabContainerDiv).tabs("select", tab.index);
	});
	*/
	
	var strTopSummaryXML=XMLToString(getFileContents("dashboard_data_files/DB_Top_Summary.xml"));
	var xmlDocTopSummary = $($.parseXML(strTopSummaryXML));
	
	var strDashBoardMainXML=XMLToString(getFileContents("dashboard_data_files/DashBoard_Main.xml"));
	var xmlDocDashboardMain = $($.parseXML(strDashBoardMainXML));
	
			
	var strBlockSummaryXML=XMLToString(getFileContents("dashboard_data_files/DB_Block_Summary.xml"));
	var xmlDocBlockSummary = $($.parseXML(strBlockSummaryXML));
			

	var tmpNumModules=$(xmlDocDashboardMain).find("module").length;
	
	run_link=getSingleNodeValue(xmlDocDashboardMain, "run_link");
	
	
	
	if(tmpNumModules>1)
	{
		//create all three four tabs
		//alert(tmpNumModules+" Modules Found, will now run conventional dashboard");
		updateMainHeaderTitle(getSingleNodeValue(xmlDocTopSummary, "title"));
		updateMainHeaderDescription(getSingleNodeValue(xmlDocTopSummary, "label"));
		updateCustomerLogo($(xmlDocTopSummary).find("custom_logo").attr("url"), $(xmlDocTopSummary).find("custom_logo").attr("width"), $(xmlDocTopSummary).find("custom_logo").attr("height"), $(xmlDocTopSummary).find("custom_logo").attr("alttext"));
		//create first tab
		var tblBlockSummary=getMainSummaryTable();
		createTab("tbSummary","Summary", tblBlockSummary);
		drawTopLevelChart(xmlDocTopSummary,"top_level_chart", "div_top_level_chart");
		drawTopCategoryLevelChart(xmlDocTopSummary,"top_category_level_chart", "div_qual_level_chart", "Quality");
		
		//create second tab : Block Summary Qgoals
		var tblBlockSummaryQGoals=getMainBlockSummaryQGoalsTable();
		createTab("tbBlockSummaryQG","Quality Goals", tblBlockSummaryQGoals);
			
		//create third tab: Block Summary DesignObjs
		var tblBlockSummaryDesObj=getMainBlockSummaryDesObjTable(xmlDocBlockSummary);
		createTab("tbBlockSummaryDO","Design Objectives", tblBlockSummaryDesObj);
		
		//create third tab: Block Summary DesignObjs
		
		//var tblCustomReport=getMainCustomReport();
		//createTab("tbCustomReport","Custom Reports", tblCustomReport);
		
		
		document.title = 'SpyGlass DashBoard';
		
	}//if there is only one module
	else
	{
		//create only one tab here
		//alert(tmpNumModules+" Modules Found, so it wont show the summary and block summary tabs");
		tabTitle=$(xmlDocDashboardMain).find("module").attr("name");
		updateMainHeaderTitle(getSingleNodeValue(xmlDocDashboardMain, "title"));
		updateMainHeaderDescription(getSingleNodeValue(xmlDocDashboardMain, "label"));
		updateCustomerLogo($(xmlDocDashboardMain).find("custom_logo").attr("url"), $(xmlDocDashboardMain).find("custom_logo").attr("width"), $(xmlDocDashboardMain).find("custom_logo").attr("height"), $(xmlDocDashboardMain).find("custom_logo").attr("alttext"));
		
		var tempTabId="tabs-" + tabTitle.replace(/ /g,"_").replace(/\(/g,"").replace(/\)/g,"");
		var tempTabContent="";
		
		createBlockSummaryTab("dashboard_data_files/DashBoard_Main.xml", tabTitle, "All");
		document.title = "SpyGlass DashBoard - "+tabTitle;
		//createTab(tempTabId,tempTabTitle, tempTabContent);
		
	}//if multiple modules, therefor multiple tabs 
	
	
}






function getPassFailLegendTable(){

	tempHTML="<table style=\"border:1px solid #CCCCCC;\"><tr><td><div style=\"background-color:"+passColor+";height:10px; width:10px;\"></div></td><td style=\" text-align:left;font-size:12px;color:#333333\"> Pass </td><td><div style=\"background-color:"+ipColor+";height:10px; width:10px;\"></div></td><td style=\" text-align:left;font-size:12px;color:#333333\">In-process</td><td><div style=\"background-color:"+failColor+";height:10px; width:10px;\"></div></td><td style=\" text-align:left;font-size:12px;color:#333333\"> Fail </td></tr><tr><td colspan=\"6\"><strong>Note: </strong>Click on Bars to Get Itemized View</td></tr></table>";
	
	return tempHTML;

}

function getMainSummaryTable(){
	var tabContent="";
	tabContent+="<table>";
	tabContent+="<tr>"
	tabContent+="<td style=\"text-align:left; vertical-align:top;width:530px;\">";
	tabContent+="<div id=\"div_top_level_chart\" style=\"width:450px; height:280px;\"></div>";
	tabContent+="</td>";
	tabContent+="<td style=\"text-align:left;vertical-align:top;\">";
	tabContent+="<div id=\"div_qual_level_chart\" style=\"width:700px; height:330px;\"></div>";
	tabContent+="</td>";
	tabContent+="</tr>";
	tabContent+="<tr>";
	tabContent+="<td style=\"text-align:left;font-size:12px;color:#333333; padding-left:40px;\">"+getPassFailLegendTable()+"</td>";
	tabContent+="<td>&nbsp;</td>";
	tabContent+="</tr>";
	tabContent+="</table>";
	return tabContent;
}






function drawTopLevelChart(xmlDocTopSummary, theChartObj, theTargetDiv)
{
	
	//var strTopSummary_title = getSingleNodeValue(xmlDocTopSummary, "title");
	var strTopSummary_ticks= getTopSummaryTicks(xmlDocTopSummary);
	var strTopSummary_passValues= getTopSummaryPassValues(xmlDocTopSummary);
	var strTopSummary_inProgressValues= getTopSummaryinProgressValues(xmlDocTopSummary);
	var strTopSummary_failValues= getTopSummaryFailValues(xmlDocTopSummary);
	
	var theChartObj=$.jqplot(theTargetDiv, [strTopSummary_passValues, strTopSummary_inProgressValues, strTopSummary_failValues],
		{
			// Tell the plot to stack the bars.
			stackSeries: true,captureRightClick: true, 
			//animate: !$.jqplot.use_excanvas,
			animate: false, 
			animateReplot: true,
			title:"Composite Status",//title:strTopSummary_title,
			seriesDefaults:
			{
				renderer:$.jqplot.BarRenderer,
				rendererOptions:
				{
					barMargin: 30,	barWidth:45, highlightMouseDown: true   
				},
				pointLabels: {show: false}
			},
			series:[{label:'Pass'},{label:'In Progress'},{label:'Fail'}],
			seriesColors: seriesColors,
			axes: {
				xaxis: 
				{
					renderer: $.jqplot.CategoryAxisRenderer,
					tickRenderer: $.jqplot.CanvasAxisTickRenderer,
					ticks: strTopSummary_ticks,
					tickOptions: {fontSize: '8pt', angle: -30}
				},
				yaxis:
				{ 
					pad: 1, tickOptions: {formatString: '%d%'},	min:0, max:100
				}
			},
			/*legend: {show: false, location: 's', placement: 'outsideGrid'},*/
			grid: {
				drawGridLines: false, background: '#FFFFFF',  drawBorder:true
			},
			
			 highlighter: {
				show: true, showMarker: false, tooltipLocation: 's', tooltipOffset:-25, tooltipFadeSpeed:'fast'
			}
				
		});
}//function getTopLevelChart


function drawTopCategoryLevelChart(xmlDocTopSummary, theChartObj, theTargetDiv, category){
			
			var qual_summary_header_val=category;
			var strQualSummary_passValues= getTopSummaryCategoryPassValues(xmlDocTopSummary, qual_summary_header_val);
			var strQualSummary_inProgressValues= getTopSummaryCategoryinProcessValues(xmlDocTopSummary, qual_summary_header_val);
			var strQualSummary_failValues= getTopSummaryCategoryFailValues(xmlDocTopSummary, qual_summary_header_val);
			$('#'+theTargetDiv).html("");
			theChartObj=$.jqplot(theTargetDiv, [strQualSummary_passValues, strQualSummary_inProgressValues, strQualSummary_failValues], getTopLevelCategoryChartOptions(xmlDocTopSummary, qual_summary_header_val));
}







function getTopLevelCategoryChartOptions(xmlDocTopSummary, category)
{
	
	var strQualSummary_title = category;
	var strQualSummary_ticks= getTopSummaryCategoryTicks(xmlDocTopSummary, category);
	var bar_width=(category=="Quality")?8:45;
	
	var opt=
		({
			// Tell the plot to stack the bars.
			stackSeries: true,
			captureRightClick: true,
			//animate: !$.jqplot.use_excanvas,
animate: false,
			animateReplot: true,
			title:strQualSummary_title,
			seriesDefaults:
			{
				renderer:$.jqplot.BarRenderer,
				rendererOptions:
				{
					barMargin: 30,	barWidth:bar_width	, highlightMouseDown: true   
				},
				pointLabels: {show: false}
			},
			
			series:[{label:'Pass'},{label:'In Progress'},{label:'Fail'}],
			seriesColors: seriesColors,
							
			axes: 
			{
				xaxis: 
				{
					renderer: $.jqplot.CategoryAxisRenderer,
					tickRenderer: $.jqplot.CanvasAxisTickRenderer,
					ticks: strQualSummary_ticks,
					tickOptions: {fontSize: '8pt', angle: -35}
				},
				yaxis:
				{ 
					pad: 1, tickOptions: {formatString: '%d%'},
					min:0, max:100
					
				}
			},
			/*legend: 
			{
				show: true,
				location: 'e',
				placement: 'outside'
				
				
			},*/
			grid: {
				drawGridLines: true,
				background: '#FFFFFF', 
				drawBorder:true
				
			},
			 highlighter: {
				show: true,
				showMarker: false,
				tooltipLocation: 's',
				
				tooltipOffset:-20,
				tooltipFadeSpeed:'fast'
				
				
     		 }
			
				
		});
		
		return opt;

}//function getTopLevelCategoryChartOptions ends










function getMainBlockSummaryDesObjTable(xmlDocBlockSummary){

			var tblBlockSummaryCols=0;
			
			//creating design objectives here
			var arrBlockSummaryDesignObjectives=getBlockSummaryDistinctDesignObjectives(xmlDocBlockSummary);
			var arrBlockSummaryDesignObjectivesMulti=[];
			$.each(arrBlockSummaryDesignObjectives, function(key, value){
				
				arrBlockSummaryDesignObjectivesMulti[value]=getBlockSummaryDistinctItemsByCategory(xmlDocBlockSummary, value);
				tblBlockSummaryCols+=getBlockSummaryDistinctItemsByCategory(xmlDocBlockSummary, value).length;
				
			});
			//design objectives ends here
			tblBlockSummaryDesignObjectiveCols=tblBlockSummaryCols;
			//tblBlockSummaryCols+=2;//2 more cols for modulename and last update date	
			tblBlockSummaryCols+=1;
			
			 
			//console.log(getBlockSummaryDistinctQualityGoals(xmlDocBlockSummary));
			
			
			var tblBlockSummary="<table class=\"dataTable1\">";
			
			
			//creating second row
			tblBlockSummary+="<tr>";
			tblBlockSummary+="<td style=\"text-align:center;font-size:13px;\">&nbsp;</td>";
			//tblBlockSummary+="<td>&nbsp;</td>";
			$.each(arrBlockSummaryDesignObjectives, function(key, value){
				var colspan_len=arrBlockSummaryDesignObjectivesMulti[value].length;				
				tblBlockSummary+="<td colspan=\""+(colspan_len)+"\" style=\"text-align:center;font-size:13px;\">"+value+"</td>";
			});
			
			tblBlockSummary+="</tr>";
			//creating second row ends here
			
			//creating third row
			
			tblBlockSummary+="<tr>";
			tblBlockSummary+="<th><strong>Module/Variant</strong></th>";
			//tblBlockSummary+="<th>Last Updated On</th>";
			$.each(arrBlockSummaryDesignObjectives, function(key, value){
				$.each(arrBlockSummaryDesignObjectivesMulti[value], function(key1, value1){
					//creating each heading at block level.....
					var tmp_header_xml_link="";
					$(xmlDocBlockSummary).find("category[name='"+value+"']").find("item[name='"+value1+"']").each(function(){
						if($(this).attr("header_link")!=""){
							tmp_header_xml_link=$(this).attr("header_link");
							//break;
						}
						
					});
					tblBlockSummary+="<th  style=\"text-align:center;\"><a onclick=\"createDOHeadingDashboard('"+tmp_header_xml_link+"', '"+value+" - "+value1+"', 'All')\" href=\"javascript:void(0);\" title=\""+value+" - "+value1+"\">"+addDotsToLongHeadings(updateBlockSummaryTitle(value1))+"</a></th>";
				});		
			});	
			
			
			tblBlockSummary+="</thead>";
			tblBlockSummary+="</tr>";
			//creating third row ends here
			
			//creating fourth(onward) row - all modules 
			$.each(getBlockSummaryModules(xmlDocBlockSummary), function(key, value){
					tblBlockSummary+="<tr>";
					tblBlockSummary+="<td><a onClick=\"createBlockSummaryTab('dashboard_data_files/DashBoard_Main.xml', '"+value+"', 'All')\" href=\"javascript:void(0);\" title=\"Open Dashboard for: "+value+"\"><strong>"+value+"</strong></a></td>";
					
					var last_updated_on=$(xmlDocBlockSummary).find("module[name='"+value+"']").find("oldest_update").text();		
					/*
					tblBlockSummary+="<td  class=\"sideHeader\" style=\"white-space:nowrap;\">"+last_updated_on+"</td>";
					*/
					$.each(arrBlockSummaryDesignObjectives, function(key1, value1){
						$.each(arrBlockSummaryDesignObjectivesMulti[value1], function(key2, value2){
							//value:modulename, value2: design objective, value 3: design objective item
							var status_node=$(xmlDocBlockSummary).find("module[name='"+value+"']").find("category[name='"+value1+"']").find("item[name='"+value2+"']");
							var status=$.trim(status_node.attr("pass_status"));
							var cell_link=status_node.attr("cell_link");
							var cell_last_update=status_node.attr("date_time");
							var cell_class=getCellClassFromStatus(status);
							
							//tblBlockSummary+="<td  style=\"text-align:center;\">"+value+"<br>"+value1+"<br>"+value2+"</td>";
							//
							
							var balloon_title="";
							if(status=="Pass" || status=="Fail"){
								balloon_title="Status: "+status+" <br> Last Updated On: "+cell_last_update;
							}
							else if(status=="No Data"){
								balloon_title="Status: Data expected but not available";
							}
							else if(status=="Data"){
								balloon_title="Status: Data available for display only <br> Last Updated On:"+cell_last_update;
							}
							
							
							tblBlockSummary+="<td class=\""+cell_class+"\"><a onClick=\"createTrendChartForDO('"+cell_link+"')\" href=\"javascript:void(0);\" title=\""+balloon_title+"\">"+status+"</a></td>";
							//tblBlockSummary+="<td  style=\"text-align:center;\"><a onClick=\"createGraph('"+cell_link+"')\">"+status+"</a></td>";
						});		
					});	
					tblBlockSummary+="</tr>";
			});	
			//creating fourth(onward) row ends here
			
			
			
			
			
			tblBlockSummary+="</table>";
			
			return tblBlockSummary;



}//function getMainBlockSummaryTable








function getMainBlockSummaryQGoalsTable(){

			var strBlockSummary=XMLToString(getFileContents("dashboard_data_files/DB_Block_Summary.xml"));
			var xmlDocBlockSummary = $($.parseXML(strBlockSummary));
			var tblBlockSummaryCols=0;
			
			var arrBlockSummaryGoalNames=getBlockSummaryDistinctQualityGoals(xmlDocBlockSummary);
			tblBlockSummaryQualityGoalsCols=arrBlockSummaryGoalNames.length;
			tblBlockSummaryCols+=tblBlockSummaryQualityGoalsCols;
			//tblBlockSummaryCols+=2;//2 more cols for modulename and last update date	
			tblBlockSummaryCols+=1;
			
			 
			//console.log(getBlockSummaryDistinctQualityGoals(xmlDocBlockSummary));
			
			
			var tblBlockSummary="<table class=\"dataTable1\">";
			
			//creating first row
			tblBlockSummary+="<thead>";	
			tblBlockSummary+="<tr>";
			tblBlockSummary+="<th><strong>Module/Variant</strong></th>";
			//tblBlockSummary+="<th>Last Updated On</th>";
			
			$.each(arrBlockSummaryGoalNames, function(key, value){
				//var colspan_len=arrBlockSummaryGoalNamesMulti[value].length;
				var tmp_header_xml_link="";
					$(xmlDocBlockSummary).find("goal[name='"+value+"']").each(function(){
						if($(this).attr("header_link")!=""){
							tmp_header_xml_link=$(this).attr("header_link");
							//break;
						}
						
					});				
				//tblBlockSummary+="<th style=\"text-align:center;\">"+value.replace(/_/g," ")+"</th>";
				
				
				var value1=getUnslashedStr(value);
				tblBlockSummary+="<th  style=\"text-align:center;\"><a onclick=\"createQGHeadingDashboard('"+tmp_header_xml_link+"', '"+value+"','All')\" href=\"javascript:void(0);\" title=\""+value+"\">"+addDotsToLongHeadings(updateBlockSummaryTitle(value1))+"</a></th>";
			});	
			
			
			
			
			tblBlockSummary+="</thead>";
			tblBlockSummary+="</tr>";
			//creating first row ends here
			
			//creating fourth(onward) row - all modules 
			$.each(getBlockSummaryModules(xmlDocBlockSummary), function(key, value){
					tblBlockSummary+="<tr>";
					tblBlockSummary+="<td class=\"sideHeader\"><a onClick=\"createBlockSummaryTab('dashboard_data_files/DashBoard_Main.xml', '"+value+"', 'All')\" href=\"javascript:void(0);\" title=\"Open Dashboard for: "+value+"\"><strong>"+value+"</strong></a></td>";
					
					var last_updated_on=$(xmlDocBlockSummary).find("module[name='"+value+"']").find("oldest_update").text();		
					/*
					tblBlockSummary+="<td style=\"white-space:nowrap;\">"+last_updated_on+"</td>";
					*/
					$.each(arrBlockSummaryGoalNames, function(key1, value1){
							var status_node=$(xmlDocBlockSummary).find("module[name='"+value+"']").find("quality_goals").find("goal[name='"+value1+"']");
							var status=$.trim(status_node.attr("pass_status"));
							var cell_link=status_node.attr("cell_link");
							var cell_last_update=status_node.attr("date_time");
							
							var cell_class=getCellClassFromStatus(status);
							
							var balloon_title="";
							if(status=="Pass" || status=="Fail"){
								balloon_title="Status: "+status+" <br> Last Updated On: "+cell_last_update;
							}
							else if(status=="Unknown"){
								balloon_title="Status: Goal not completed";
							}
							
							
							
							
							tblBlockSummary+="<td class=\""+cell_class+"\"><a onClick=\"createTrendChartForQG('"+cell_link+"')\" href=\"javascript:void(0);\" title=\""+balloon_title+"\">"+status+"</a></td>";
					});
					
					
					
					
					
					
					tblBlockSummary+="</tr>";
			});	
			//creating fourth(onward) row ends here
			
			
			
			
			
			tblBlockSummary+="</table>";
			
			return tblBlockSummary;



}//function getMainBlockSummaryTable





function getMainCustomReport(){
	var xmlFilePath="./dashboard_data_files/DashBoard_Violation_Count.xml";
	var xmlStr=XMLToString(getFileContents(xmlFilePath));
	
	xmlObj=$($.parseXML(xmlStr));
	
	
	var all_goals=Array();
	var all_goal_rules=Array();
	var num_cols=1;
	$(xmlObj).find("module").find("goal").children("name").each(function(){
		if(jQuery.inArray($(this).text(), all_goals)<=-1){
			all_goals.push($(this).text());
		}
	});
	
	console.log(all_goals);
	$.each(all_goals, function(key, val){
		if(typeof all_goal_rules[val] == 'undefined')
		{
			all_goal_rules[val]=[];
		}		
		//$(xmlObj).find("module").find("goal").find("name='"+val+"'").find("rules").find("rule").find("name").each(function(){
		
			
		var xmlObj1=$(xmlObj).find("module goal name").filter(function(index) { return $(this).text() === val; });
		xmlObj1.parent().find("rules").find("rule").find("name").each(function(){
			if(jQuery.inArray($(this).text(), all_goal_rules[val])<=-1){
				all_goal_rules[val].push($(this).text());
				num_cols++;
			}
		});
		
		
	});
	console.log(all_goal_rules);
	var tblContent="";
	//tblContent="<h1>Table will be added here</h1>";
	tblContent="<table class=\"dataTable2\">";
	
	
	tblContent+="<tr>";
	tblContent+="<th>Modules</th>";
	$.each(all_goals, function(key, val){
		var colspan_size=all_goal_rules[val].length;
		tblContent+="<th colspan=\""+colspan_size+"\">"+val+"</th>";
	});
	tblContent+="</tr>";
	
	tblContent+="<tr>";
	tblContent+="<th>&nbsp;</th>";
	$.each(all_goals, function(key, val){
		
		$.each(all_goal_rules[val],function(key1, val1){
			tblContent+="<th>"+val1+"</th>";
		});	
	});
	tblContent+="</tr>";

	
		
	
	$(xmlObj).find("module").each(function(){
			var module_name=$(this).attr("name");
			tblContent+="<tr><td>"+module_name+"</td>";
			$.each(all_goals, function(key, val){
				$.each(all_goal_rules[val],function(key1, val1){
					//.find("actual_line[goal='"+val+"']").
					var xmlObj1=$(xmlObj).find("module[name='"+module_name+"'] goal name").filter(function(index) { return $(this).text() === val; });
					var xmlObj_final=xmlObj1.parent().find("rules").find("rule").find("name").filter(function(index) { return $(this).text() === val1; });
					
					var violation_file_link=xmlObj_final.parent().find("link").text();
					var violation_count=xmlObj_final.parent().find("violation_count").text();
					if(violation_count!=""){
						tblContent+="<td  style=\"text-align:center;\"><a href=\""+violation_file_link+"\">"+violation_count+"</a></td>";
					}else
					{
						tblContent+="<td style=\"text-align:center;\">N/A</td>";
					}
					//tblContent+="<td>"+val+":"+val1+"</a></td>";
				});
				
				
			});	
	});
	tblContent+="</tr>";
	
	

	
	
	tblContent+="</table>";
	
	return tblContent;
}

































function createTrendChartForDO(xmlFilePath){

	var xmlGraph=XMLToString(getFileContents(xmlFilePath));
	xmlObj=$($.parseXML(xmlGraph));
	var all_desObjs=Array();
	
	var graphhasfloatingpoint=false;
	
	
	if($(xmlObj).find("target_line").length>0 && $(xmlObj).find("actual_line").length>0 && $(xmlObj).find("target_line").length==$(xmlObj).find("actual_line").length)
	{

		$('#trendChartDiv').remove();
		$('#trendChartGraphDiv').remove();
			
		var trendChartDiv="<div id=\"trendChartDiv\"  style=\"width:650px;height:450px;border:1px solid #CCCCCC;\"><div id=\"trendChartGraphDiv\" style=\"width:700px;height:350px;float:left;\"></div><div id=\"trendChartLegendDiv\" style=\"float:left;border:1px solid #CCCCCC;width:200px;margin-top:50px;font-size:12px; line-height:20px;padding:5px;\"></div><div style=\"float:left;text-align:left;font-size:12px;\">Drag on to Trend Chart to <strong>ZOOM-IN</strong> | <a href=\"javascript:void(0);\" onclick=\"trendChart.resetZoom();\" style=\"font-size:12px;font-weight:bold;\">Reset Zoom</a><br>You can also <strong>click on legend labels to show/hide</strong> trend lines <a href=\""+xmlFilePath+"\" target=\"_blank\">..</a></div></div>";
		$('body').append(trendChartDiv);
		
		
		$(xmlObj).find("actual_line").each(function(key, val){
			all_desObjs.push($(this).attr("goal"));
		});
		var all_trend_lines=Array();
		var all_trend_lines_style=Array();
		
		var arr_trend_days=Array();	
		for(var key=0; key<all_desObjs.length; key++){
		
				val=all_desObjs[key];
				
				var actual_trend_line=Array();
				var target_trend_line=Array();	
				
				$(xmlObj).find("actual_line[goal='"+val+"']").find("data_point").each(function(key1, val1){
					//fix of plotting a datechart having single date points
					var temp_date_only_arr=$(this).attr('date_time').split(" (");
					var temp_date_only=temp_date_only_arr[0];
					if(jQuery.inArray(temp_date_only, arr_trend_days)<=-1){
					
						arr_trend_days.push(temp_date_only);
					}
					//fix of plotting a datechart having single date points
					
					if($(this).attr('value')!="" && !isNaN(parseInt($(this).attr('value')))){
						actual_trend_line.push(Array($(this).attr('date_time'), parseFloat($(this).attr('value'))));
						if($(this).attr('value').indexOf(".")>-1){
							graphhasfloatingpoint=true;
						}
					}
					else{
						actual_trend_line.push(Array($(this).attr('date_time'), 0));
					}	
				});
				$(xmlObj).find("target_line[goal='"+val+"']").find("data_point").each(function(key1, val1){
					if($(this).attr('value')!="" && !isNaN(parseInt($(this).attr('value'))) ){
						if($(this).attr('value').indexOf(".")>-1){
							graphhasfloatingpoint=true;
						}
						target_trend_line.push(Array($(this).attr('date_time'), parseFloat($(this).attr('value'))));
					}else{
						target_trend_line.push(Array($(this).attr('date_time'), 0));
					}	
				});
				
				all_trend_lines.push(actual_trend_line);
				var tmp_trend_style={linePattern: 'solid', lineWidth:1, color:productColors[key], label: $(this).attr("goal"), showMarker:true,  markerOptions: {show: true, style: 'filledCircle',size: 5}};
				all_trend_lines_style.push(tmp_trend_style);
				
				all_trend_lines.push(target_trend_line);
				var tmp_trend_style={linePattern: 'solid', lineWidth:2, color:productColors[key],showMarker:false};
				all_trend_lines_style.push(tmp_trend_style);
				var temNewKey=key*2;
				
				var href_id="legHref"+key;
				$('#trendChartLegendDiv').append("<div style=\"background-color:"+productColors[key]+";height:10px; width:10px; float:left;\"></div><div style=\"float:left;margin-left:5px;\"><a href=\"javascript:void(0);\" id=\""+href_id+"\" style=\"text-decoration:none\" onclick=\"toggleLegendSeries('trendChart', '"+temNewKey+"', '"+href_id+"')\">"+val+"</a></div><br>");
			}
			
			$('#trendChartLegendDiv').append("<br><br><img src=\"img/dashed.png\" style=\"align:left;margin-right:5px;text-align:middle;\">Actual<br>");
			$('#trendChartLegendDiv').append("<img src=\"img/solid.png\" style=\"align:left;margin-right:5px;text-align:middle;\">Success Criteria<br>");			
			
			trendChart=$.jqplot ('trendChartGraphDiv', all_trend_lines, {
			  // Give the plot a title.
			  //animate: !$.jqplot.use_excanvas,
			  animate: false,
			  title: $(xmlObj).find("title").text(),
			  axesDefaults: {
				labelRenderer: $.jqplot.CanvasAxisLabelRenderer
			  },
			  axes: {
					xaxis: {
						renderer:(arr_trend_days.length>1) ? $.jqplot.DateAxisRenderer: $.jqplot.CategoryAxisRenderer,
						//renderer: $.jqplot.CategoryAxisRenderer,
						tickRenderer: $.jqplot.CanvasAxisTickRenderer,
						tickOptions:{fontSize: '8pt', angle: -30}, 
						label: $(xmlObj).find("xaxis_label").text(),
						pad: 1.2
					},
					yaxis: {
						label: $(xmlObj).find("yaxis_label").text(),
						pad: 1,
						tickOptions:{
            				formatString:(graphhasfloatingpoint)? '%.2f':'%d'
            			}
					},
					y2axis: {
						pad: 1.2
					}
			  },
			cursor:{
					show:true,
					zoom:true,
					showTooltip:false,
					showTooltipOutsideZoom: true,
					constrainOutsideZoom: false
			},
			series:all_trend_lines_style,
			
			highlighter: {
					show: true,
					sizeAdjust: 7.5
			}	
			
			});
			
			
			
				
			$('#trendChartDiv').dialog({
				//title: $(xmlObj).find("title").text()+" "+"<a href=\""+xmlFilePath+"\" style=\"font-size:9px;\" target=\"_blank\">Source</a>",
				title: $(xmlObj).find("title").text(),
				autoOpen: false,
				width: 950,
				height: 450
			});
			
			$('#trendChartDiv').dialog('open');
			
			
			
	}//if($(xmlObj).find("target_line"))
	else{
		//alert("Couldnt understand the tags in "+xmlFilePath+". It must have severity tags like target_line/actual_line");
		alert("Cannot create Trend Chart. Source file has no data points");
	}		
	
}//createTrendChartForDO



function createTrendChartForQG(xmlFilePath){
	//xmlFilePath=xmlFilePath.replace(/dashboard_data_files/g,"XML");
	
	var xmlGraph=XMLToString(getFileContents(xmlFilePath));
	
	xmlObj=$($.parseXML(xmlGraph));
	
	if($(xmlObj).find("severity_lines").length>0 && $(xmlObj).find("severity").length>0){
			$('#trendChartDiv').remove();
	
			$('#trendChartLegendDiv').remove();
			
			var trendChartDiv="<div id=\"trendChartDiv\"  style=\"width:650px;height:450px;border:1px solid #CCCCCC;\"><div id=\"trendChartGraphDiv\" style=\"width:900px;height:350px;float:left;\"></div><!--div id=\"trendChartLegendDiv\" style=\"float:left;border:1px solid #CCCCCC;width:130px;margin-top:20px;\"></div--><div style=\"text-align:left;font-size:12px;\">Drag on to Trend Chart to <strong>ZOOM-IN</strong> | <a href=\"javascript:void(0);\" onclick=\"trendChart.resetZoom();\" style=\"font-size:12px;font-weight:bold;\">Reset Zoom</a><br>You can also <strong>click on legend labels to show/hide</strong> trend lines <a href=\""+xmlFilePath+"\" target=\"_blank\">..</a></div></div>";
			
			$('body').append(trendChartDiv);
			
			var all_trend_lines=Array();
			var all_trend_lines_style=Array();
			var arr_trend_days=Array();
			$(xmlObj).find("severity").each(function(key, val){
				var trend_line=Array();
	
				$(this).find("data_point").each(function(key1, val1){
				
					//fix of plotting a datechart having single date points
					var temp_date_only_arr=$(this).attr('date_time').split(" (");
					var temp_date_only=temp_date_only_arr[0];
					if(jQuery.inArray(temp_date_only, arr_trend_days) <= -1){
						arr_trend_days.push(temp_date_only);
					}
					//fix of plotting a datechart having single date points
					
					if($(this).attr('value')!="" && !isNaN(parseInt($(this).attr('value')))){
						trend_line.push(Array($(this).attr('date_time'), parseInt($(this).attr('value'))));
					}
					else{
						trend_line.push(Array($(this).attr('date_time'), 0));
					}
					
				});//data point each line
				all_trend_lines.push(trend_line);
				var tmp_trend_style={linePattern: 'solid', showMarker: true, color:getColorForSeverity($(this).attr('name')), label: $(this).attr('name'), showMarker:true,  lineWidth:1,   markerOptions: {show: true, style: 'filledCircle',size: 5}};
				all_trend_lines_style.push(tmp_trend_style);

			});
	
	
			trendChart=$.jqplot ('trendChartGraphDiv', all_trend_lines, {
			  // Give the plot a title.
			  //animate: !$.jqplot.use_excanvas,
				animate: false,
			  title: $(xmlObj).find("title").text(),
			  axesDefaults: {
				labelRenderer: $.jqplot.CanvasAxisLabelRenderer
			  },
			  axes: {
					xaxis: {
						renderer:(arr_trend_days.length>1) ? $.jqplot.DateAxisRenderer: $.jqplot.CategoryAxisRenderer,
						tickRenderer: $.jqplot.CanvasAxisTickRenderer,
						tickOptions:{fontSize: '8pt', angle: -30}, 
						label: $(xmlObj).find("xaxis_label").text(),
						pad: 1
					},
					yaxis: {
						label: $(xmlObj).find("yaxis_label").text(),
						pad: 1
					}
			  },
			cursor:{
					show:true,
					zoom:true,
					showTooltip:false,
					showTooltipOutsideZoom: true,
					constrainOutsideZoom: false
			},
			series:all_trend_lines_style,
			highlighter: {
					show: true,
					sizeAdjust: 7.5
			},
			legend:{
				renderer: $.jqplot.EnhancedLegendRenderer,
				show:true,
				fontSize:'8pt',
				placement:'outsideGrid'
			}	
			
			});
			
				
			$('#trendChartDiv').dialog({
				//title: $(xmlObj).find("title").text()+" "+"<a href=\""+xmlFilePath+"\" style=\"font-size:9px;\" target=\"_blank\">Source</a>",
				title: $(xmlObj).find("title").text(),
				autoOpen: false,
				width: 950,
				height: 450
			});
			
			$('#trendChartDiv').dialog('open');
	
	}
	else{
		alert("Cannot create Trend Chart. Source file has no data points");
	}

}//createTrendChartForQG









function createDOHeadingDashboard(xmlFilePath, tabTitle, dCellStatus){
	//xmlFilePath=xmlFilePath.replace(/dashboard_data_files/g,"XML");
	//creates tab for  design objective tab headings
	//alert(xmlFilePath);
	var xmlGraph=XMLToString(getFileContents(xmlFilePath));
	xmlObj=$($.parseXML(xmlGraph));
	
	var table_id="tbl-" + tabTitle.replace(/ /g,"_").replace(/\(/g,"").replace(/\)/g,"_");
	var tgltblLink_id="tgl"+table_id;
	var tabContent="";
	
	
	tabContent+="<table style=\"width:1024px;font-size:12px;\">";
	tabContent+="<tr><td style=\"width:3%\">&nbsp;</td><td style=\"width:98%;text-align:right\">";
	//tabContent+="<td>Showing "+dCellStatus+" values &nbsp;|&nbsp;";
	
	for(var i=0;i<tmp_all_filters.length;i++){
		if(tmp_all_filters[i]=="Pass"){
			tabContent+="<img src=\"./img/pass_val.png\" style=\"align:left; padding-right:5px; padding-left:5px\">";
		}
		else if(tmp_all_filters[i]=="Fail"){
			tabContent+="<img src=\"./img/fail_val.png\" style=\"align:left; padding-right:5px; padding-left:5px\">";
		}
		
		if(dCellStatus==tmp_all_filters[i]){
			tabContent+="<strong>"+tmp_all_filters[i]+"</strong>";
		}
		else{
			tabContent+="<a href=\"javascript:void(0);\" onclick=\"javascript:createDOHeadingDashboard('"+xmlFilePath+"', '"+tabTitle+"', '"+tmp_all_filters[i]+"')\">"+tmp_all_filters[i]+"</a>";
		}
			
		if(i!=tmp_all_filters.length - 1){
			tabContent+="&nbsp;&nbsp;|&nbsp;&nbsp;";
		}
	}
	
	tabContent+="</td>";
	tabContent+="</tr>";
	
	
	
	tabContent+="<tr><td style=\"vertical-align:top; text-align:center;padding-top:5px;\">";
	tabContent+="<a href=\"javascript:void(0);\" onclick=\"javascript:toggleAllDataRows('"+table_id+"', '"+tgltblLink_id+"')\" class=\"link_expand_collapse\" id=\""+tgltblLink_id+"\">-</a>";
	tabContent+="</td>";
	tabContent+="<td style=\"vertical-align:top;\">";
	
	tabContent+="<table class=\"dataTable1\"  id=\""+table_id+"\">";
	tabContent+="<thead>";
	tabContent+="<tr>";
	tabContent+="<th style=\"width:20%\">Module/Variant</th>";
	//tabContent+="<th style=\"width:17%\">Run Status</th>";
	tabContent+="<th style=\"width:30%\">Design Objective</th>";
	tabContent+="<th style=\"width:30%\">Success Criteria</th>";
	tabContent+="<th style=\"width:10%;text-align:center\" >Status</th>";
	
	if(run_link=="true")
	{	
		tabContent+="<th style=\"width:10%;text-align:center\" >View Results</th>";	
	}
	
	tabContent+="</tr>";
	tabContent+="</thead>";
	
	$(xmlObj).find("module").each(function(key, val){
		
		//each category
		var module_name=$(this).attr('name');
		var module_link=$(this).attr('link');
		$(this).find("item").each(function(key1, val1){
					
					var status=$.trim($(this).attr('pass_status'));
					var cell_class=getCellClassFromStatus(status);
					
					
					var temp_child_item_class=module_name+"_childitem_"+key1;
					if(dCellStatus=="Show All" || dCellStatus=="All")
						{
										if(($(this).find("child_item").length)>0)
										{
												tabContent+="<tr>";
												tabContent+="<td><a onClick=\"createBlockSummaryTab('dashboard_data_files/DashBoard_Main.xml', '"+module_name+"', 'All')\" href=\"javascript:void(0);\" title=\"Open Dashboard for: "+module_name+"\">"+module_name+"</a></td>";
												//tabContent+="<td><strong>"+$(this).attr('run_status')+"</strong></td>";
												tabContent+="<td><a class=\"ui-icon ui-icon-plus\" style=\"border:1px solid #CCCCCC; float:left;\" onclick=\"javascript:toggleHeadingTableRows('"+temp_child_item_class+"',  this)\"></a>&nbsp;<strong>"+$(this).attr('name')+"</strong></td>";
												tabContent+="<td><strong>"+$(this).attr('success_criteria')+"</strong></td>";
												var status=$.trim($(this).attr('pass_status')).toLowerCase();
												tabContent+="<td class=\""+cell_class+"\"><a onClick=\"createTrendChartForDO('"+$(this).attr('graph')+"')\" href=\"javascript:void(0);\" title=\""+$(this).attr('tooltip')+"\">"+status+"</a></td>";
												
												
												if(run_link=="true")
												{	
													
													if($.trim($(this).attr('run_link'))!="")
													{
														tabContent+="<td style=\"text-align:center\"><a href=\""+$(this).attr('run_link')+"\">Open</a></td>";	
													}
													else
													{
														tabContent+="<td>&nbsp;</td>";
													}
												}
																							
												
												
												tabContent+="</tr>";	
												
												$(this).find("child_item").each(function()
												{
														tabContent+="<tr class=\""+temp_child_item_class+"\">";
														tabContent+="<td><a onClick=\"createBlockSummaryTab('dashboard_data_files/DashBoard_Main.xml', '"+module_name+"', 'All')\" href=\"javascript:void(0);\" title=\"Open Dashboard for: "+module_name+"\">"+module_name+"</a></td>";
														//tabContent+="<td>"+$(this).attr('run_status')+"</td>";
														tabContent+="<td>"+$(this).attr('name')+"</td>";
														tabContent+="<td>"+$(this).attr('success_criteria')+"</td>";
														tabContent+="<td class=\""+cell_class+"\"><a onClick=\"createTrendChartForDO('"+$(this).attr('graph')+"')\" href=\"javascript:void(0);\" title=\""+$(this).attr('tooltip')+"\">"+status+"</a></td>";
														
														
														
														if(run_link=="true")
														{	
															
															if($.trim($(this).attr('run_link'))!="")
															{
																
																tabContent+="<td style=\"text-align:center\"><a href=\""+$(this).attr('run_link')+"\">Open</a></td>";	
															}
															else
															{
																
																tabContent+="<td>&nbsp;</td>";
															}
														}
														
														
														tabContent+="</tr>";
												});
										
										}//if td has child values...
										
										else
										{
												tabContent+="<tr>";
												tabContent+="<td><a onClick=\"createBlockSummaryTab('dashboard_data_files/DashBoard_Main.xml', '"+module_name+"', 'All')\" href=\"javascript:void(0);\" title=\"Open Dashboard for: "+module_name+"\">"+module_name+"</a></td>";
												//tabContent+="<td>"+$(this).attr('run_status')+"</td>";
												tabContent+="<td>"+$(this).attr('name')+"</td>";
												tabContent+="<td>"+$(this).attr('success_criteria')+"</td>";
												tabContent+="<td class=\""+cell_class+"\"><a onClick=\"createTrendChartForDO('"+$(this).attr('graph')+"')\" href=\"javascript:void(0);\" title=\""+$(this).attr('tooltip')+"\">"+status+"</a></td>";;
												
												if(run_link=="true")
												{	
														
													if($.trim($(this).attr('run_link'))!="")
													{
														tabContent+="<td style=\"text-align:center\"><a href=\""+$(this).attr('run_link')+"\">Open</a></td>";	
													}
													else
													{
														tabContent+="<td>&nbsp;</td>";
													}
												}
												
												
												tabContent+="</tr>";
										}//if td doesnt have child values...
					}//if dellstatus is all/select all
					else if(dCellStatus.toLowerCase()=="pass" || dCellStatus.toLowerCase()=="fail")
					{
										var tmp_parent_do_chunks=$(this).attr('name').split("(");
										var tmp_parent_do_name=tmp_parent_do_chunks[0];
										tmp_parent_do_title=$(this).attr('name');
										if(($(this).find("child_item").length)>0)
										{
												$(this).find("child_item").each(function()
												{
														var tmp_child_do_chunks=$(this).attr('name').split("=");
														var tmp_child_do_name=tmp_child_do_chunks[1];
														var tmp_name=tmp_parent_do_name+"="+tmp_child_do_name;
														var pass_status=$.trim($(this).attr('pass_status'));
														var cell_class=getCellClassFromStatus(pass_status);
														if(dCellStatus.toLowerCase()==pass_status.toLowerCase())
														{
															tabContent+="<tr class=\""+temp_child_item_class+"\">";
															tabContent+="<td><a onClick=\"createBlockSummaryTab('dashboard_data_files/DashBoard_Main.xml', '"+module_name+"', 'All')\" href=\"javascript:void(0);\" title=\"Open Dashboard for: "+module_name+"\">"+module_name+"</a></td>";
															//tabContent+="<td>"+$(this).attr('run_status')+"</td>";
															tabContent+="<td>"+tmp_name+"</td>";
															tabContent+="<td>"+$(this).attr('success_criteria')+"</td>";
															tabContent+="<td class=\""+cell_class+"\"><a onClick=\"createTrendChartForDO('"+$(this).attr('graph')+"')\" href=\"javascript:void(0);\" title=\""+$(this).attr('tooltip')+"\">"+status+"</a></td>";
															
															if(run_link=="true")
															{	
																	
																if($.trim($(this).attr('run_link'))!="")
																{
																	tabContent+="<td style=\"text-align:center\"><a href=\""+$(this).attr('run_link')+"\">Open</a></td>";	
																}
																else
																{
																	tabContent+="<td>&nbsp;</td>";
																}
															}
															
															tabContent+="</tr>";
														}
												});
										
										}//if td has child values...
										
										else
										{
												var pass_status=$.trim($(this).attr('pass_status'));
												var cell_class=getCellClassFromStatus(status);
									
												if(dCellStatus.toLowerCase()==pass_status.toLowerCase())
												{
													tabContent+="<tr>";
													tabContent+="<td><a onClick=\"createBlockSummaryTab('dashboard_data_files/DashBoard_Main.xml', '"+module_name+"', 'All')\" href=\"javascript:void(0);\" title=\"Open Dashboard for: "+module_name+"\">"+module_name+"</a></td>";
													//tabContent+="<td>"+$(this).attr('run_status')+"</td>";
													tabContent+="<td>"+$(this).attr('name')+"</td>";
													tabContent+="<td>"+$(this).attr('success_criteria')+"</td>";
													tabContent+="<td class=\""+cell_class+"\"><a onClick=\"createTrendChartForDO('"+$(this).attr('graph')+"')\" href=\"javascript:void(0);\" title=\""+$(this).attr('tooltip')+"\">"+status+"</a></td>";;
													
													if(run_link=="true")
													{	
															
														if($.trim($(this).attr('run_link'))!="")
														{
															tabContent+="<td style=\"text-align:center\"><a href=\""+$(this).attr('run_link')+"\">Open</a></td>";	
														}
														else
														{
															tabContent+="<td>&nbsp;</td>";
														}
													}
													
													tabContent+="</tr>";
												}	
										}//if td doesnt have child values...
					}//else if status is pass or fail...
		});//foreach design_data-> category->items
	});	//foreach $(xmlObj).find("module[name='"+tabTitle+"']").find("design_data").each
	
	tabContent+="</table>";
	
	
	
	
	tabContent+="</td></tr></table>";
	
	var tab_id="cntMainTabs-" + tabTitle.replace(/ /g,"_").replace(/\(/g,"").replace(/\)/g,"_");
	createTab(tab_id, tabTitle, tabContent);
	
	toggleAllChildren(table_id);
	
}//createDOHeadingDashboard







function createQGHeadingDashboard(xmlFilePath, tabTitle, dCellStatus)
{
	//alert(xmlFilePath);
	var xmlGraph=XMLToString(getFileContents(xmlFilePath));
	xmlObj=$($.parseXML(xmlGraph));
	
	var tabContent="";
	var table_id="tbl-" + tabTitle.replace(/ /g,"_").replace(/\(/g,"").replace(/\)/g,"_").replace(/\//g,"_");
	var tgltblLink_id="tgl"+table_id;
	//goal summary table starts creating here
	
	tabContent+="<table style=\"width:1024px;font-size:12px;\">";
	tabContent+="<tr><td style=\"width:3%\">&nbsp;</td><td style=\"width:98%;text-align:right\">";
	//tabContent+="<td>Showing "+dCellStatus+" values &nbsp;|&nbsp;";
	
	for(var i=0;i<tmp_all_filters.length;i++){
		if(tmp_all_filters[i]=="Pass"){
			tabContent+="<img src=\"./img/pass_val.png\" style=\"align:left; padding-right:5px; padding-left:5px\">";
		}
		else if(tmp_all_filters[i]=="Fail"){
			tabContent+="<img src=\"./img/fail_val.png\" style=\"align:left; padding-right:5px; padding-left:5px\">";
		}
		
		if(dCellStatus==tmp_all_filters[i]){
			tabContent+="<strong>"+tmp_all_filters[i]+"</strong>";
		}
		else{
			tabContent+="<a href=\"javascript:void(0);\" onclick=\"javascript:createQGHeadingDashboard('"+xmlFilePath+"', '"+tabTitle+"', '"+tmp_all_filters[i]+"')\">"+tmp_all_filters[i]+"</a>";
		}
			
		if(i!=tmp_all_filters.length - 1){
			tabContent+="&nbsp;&nbsp;|&nbsp;&nbsp;";
		}
	}
	
	tabContent+="</td>";
	tabContent+="</tr>";
	
	
	
	tabContent+="<tr><td style=\"vertical-align:top; text-align:center;padding-top:5px;\">";
	tabContent+="<a href=\"javascript:void(0);\" onclick=\"javascript:toggleAllDataRows('"+table_id+"', '"+tgltblLink_id+"')\" class=\"link_expand_collapse\" id=\""+tgltblLink_id+"\">-</a>";
	tabContent+="</td>";
	tabContent+="<td style=\"vertical-align:top;\">";
		
	
	
	
	tabContent+="<table class=\"dataTable1\"  id=\""+table_id+"\">";
	tabContent+="<thead>";
	tabContent+="<tr>";
	tabContent+="<th rowspan=\"2\">Module Name</th>";
	tabContent+="<th rowspan=\"2\">Quality Goals</th>";
	tabContent+="<th>&nbsp;</th>";
	
	active_unresolved_severity=getAllActiveUnresolvedSeverity();
	active_waived_severity=getAllActiveWaivedSeverity();
	
	if(active_unresolved_severity.length>0){
		tabContent+="<th colspan=\""+(active_unresolved_severity.length)+"\"  style=\"text-align:center\">Unresolved</th>";
	}
	if(active_waived_severity.length>0){
		tabContent+="<th colspan=\""+(active_waived_severity.length)+"\" style=\"text-align:center\">Waived</th>";
	}

	
	tabContent+="<th>&nbsp;</th>";
	tabContent+="<th>&nbsp;</th>";
	if(run_link=="true")
	{	
		tabContent+="<th>&nbsp;</th>";
	}
	
	tabContent+="</tr>";
	
	tabContent+="<tr>";
	tabContent+="<th style=\"width:10%;text-align:center; \">Run Status</th>";
	for(var i=0; i<active_unresolved_severity.length;i++){
		tabContent+="<th style=\"text-align:center;\">"+active_unresolved_severity[i]+"</th>";
	}
	for(var i=0; i<active_waived_severity.length;i++){
		tabContent+="<th style=\"text-align:center;\">"+active_waived_severity[i].replace("waived-", "")+"</th>";
	}
	tabContent+="<th style=\"width:30%\">Success Criteria</th>";
	tabContent+="<th style=\"width:10%;text-align:center\" >Status</th>";	
	if(run_link=="true")
	{	
		tabContent+="<th style=\"width:10%;text-align:center\">View Results</th>";
	}
	tabContent+="</tr>";
	tabContent+="</thead>";
	tabContent+="<tbody>";
	
	$(xmlObj).find("module").each(function(key, val){
		var module_name=$(this).attr('name');
		var module_link=$(this).attr('link');
		$(this).find("goal").each(function(key1, val1){
					var pass_status=$.trim($(this).attr('pass_status'));
					var cell_class=getCellClassFromStatus(pass_status);
					if(dCellStatus=="Show All" || dCellStatus=="All" || dCellStatus.toLowerCase()==pass_status.toLowerCase()){
								tabContent+="<tr>";
								tabContent+="<td><a onClick=\"createBlockSummaryTab('dashboard_data_files/DashBoard_Main.xml', '"+module_name+"', 'All')\" href=\"javascript:void(0);\" title=\"Open Dashboard for: "+module_name+"\">"+module_name+"</a></td>";
								
								
								var tmp_qg_name=getUnslashedStr($(this).attr('name'));
								
								if($(this).attr('link')!="" && typeof($(this).attr('link'))!="undefined"){
									tabContent+="<td><a href=\"javascript:void(0);\" onclick=\"createIframeReport('"+$(this).attr('link')+"', '"+$(this).attr('name')+"', '"+$(this).attr('name')+"')\" title=\""+$(this).attr('name')+"\"><strong>"+tmp_qg_name+"</strong></a></td>";
								}else{
									tabContent+="<td>"+tmp_qg_name+"</td>";
								}
								tabContent+="<td style=\"text-align:center\">"+$(this).attr('run_status')+"</td>";
							
								for(var i=0; i<active_unresolved_severity.length;i++){
									tabContent+="<td style=\"text-align:center\">"+$(this).attr(active_unresolved_severity[i])+"</td>";
								}
								for(var i=0; i<active_waived_severity.length;i++){
									tabContent+="<td style=\"text-align:center\">"+$(this).attr(active_waived_severity[i])+"</td>";
								}

								
								
								
								tabContent+="<td>"+$(this).attr('success_criteria')+"</td>";
								tabContent+="<td class=\""+cell_class+"\"><a onClick=\"createTrendChartForQG('"+$(this).attr('graph')+"')\" href=\"javascript:void(0);\">"+pass_status+"</a></td>";
								
								if(run_link=="true")
								{	
									if($.trim($(this).attr('run_link'))!="")
									{
										tabContent+="<td style=\"text-align:center\"><a href=\""+$(this).attr('run_link')+"\">Open</a></td>";	
									}
									else
									{
										tabContent+="<td>&nbsp;</td>";
									}
								}	
								
								tabContent+="</tr>";
					}//if(dCellStatus=="Show All" || dCellStatus=="All" || dCellStatus.toLowerCase()==pass_status.toLowerCase()){
		});//foreach design_data-> category->items
	});//$(xmlObj).find("module").each(function(key, val){
	tabContent+="</tbody>";
	tabContent+="</table>";
	
	tabContent+="</td></tr></table>";
	
	
	var tab_id="cntMainTabs-" + tabTitle.replace(/ /g,"_").replace(/\(/g,"").replace(/\)/g,"_").replace(/\//g,"_");
	createTab(tab_id, tabTitle, tabContent);
}//createQGHeadingDashboard







function createBlockSummaryTab(xmlFilePath, tabTitle, dCellStatus){
	//alert(xmlFilePath);
	var xmlGraph=XMLToString(getFileContents(xmlFilePath));
	var xmlObj=$($.parseXML(xmlGraph));
	var tabContent="";
	var table_id="tblQG-" + tabTitle.replace(/ /g,"_").replace(/\(/g,"").replace(/\)/g,"_").replace(/\//g,"_");
	var tgltblLink_id="tgl"+table_id;
	//goal summary table starts creating here
	
	
	tabContent+="<table style=\"width:1024px;font-size:12px;\">";
	tabContent+="<tr><td style=\"width:3%\">&nbsp;</td>";
	tabContent+="<td style=\"width:49%; text-align:left;font-size:16px;font-weight:bold;color:#333333\">Module: "+tabTitle+"</td>";
	tabContent+="<td style=\"width:48%; text-align:right;\">";
	//tabContent+="<td>Showing "+dCellStatus+" values &nbsp;|&nbsp;";
	
	for(var i=0;i<tmp_all_filters.length;i++){
		if(tmp_all_filters[i]=="Pass"){
			tabContent+="<img src=\"./img/pass_val.png\" style=\"align:left; padding-right:5px; padding-left:5px\">";
		}
		else if(tmp_all_filters[i]=="Fail"){
			tabContent+="<img src=\"./img/fail_val.png\" style=\"align:left; padding-right:5px; padding-left:5px\">";
		}
		
		if(dCellStatus==tmp_all_filters[i]){
			tabContent+="<strong>"+tmp_all_filters[i]+"</strong>";
		}
		else{
			tabContent+="<a href=\"javascript:void(0);\" onclick=\"javascript:createBlockSummaryTab('"+xmlFilePath+"', '"+tabTitle+"', '"+tmp_all_filters[i]+"')\">"+tmp_all_filters[i]+"</a>";
		}
			
		if(i!=tmp_all_filters.length - 1){
			tabContent+="&nbsp;&nbsp;|&nbsp;&nbsp;";
		}
	}
	
	tabContent+="</td>";
	tabContent+="</tr>";
	
	
	
	tabContent+="<tr><td style=\"vertical-align:top; text-align:center;padding-top:5px;\">";
	tabContent+="<a href=\"javascript:void(0);\" onclick=\"javascript:toggleAllDataRows('"+table_id+"', '"+tgltblLink_id+"')\" class=\"link_expand_collapse\" id=\""+tgltblLink_id+"\">-</a>";
	tabContent+="</td>";
	tabContent+="<td style=\"vertical-align:top;\" colspan=\"2\">";
	
	active_unresolved_severity=getAllActiveUnresolvedSeverity();
	active_waived_severity=getAllActiveWaivedSeverity();
		
	tabContent+="<table class=\"dataTable1\"  id=\""+table_id+"\">";
	tabContent+="<thead>";
	tabContent+="<tr>";
	tabContent+="<th rowspan=\"2\" style=\"width:15%\">Quality Goals</th>";
	tabContent+="<th>&nbsp;</th>";
	tabContent+="<th>&nbsp;</th>";
	tabContent+="<th>&nbsp;</th>";
	
	if(active_unresolved_severity.length>0){
		tabContent+="<th colspan=\""+(active_unresolved_severity.length)+"\"  style=\"text-align:center\">Unresolved</th>";
	}
	if(active_waived_severity.length>0){
		tabContent+="<th colspan=\""+(active_waived_severity.length)+"\" style=\"text-align:center\">Waived</th>";
	}
	tabContent+="<th>&nbsp;</th>";
	tabContent+="<th>&nbsp;</th>";
	
	if(run_link=="true")
	{	
		tabContent+="<th>&nbsp;</th>";
	}
	
	
	tabContent+="</tr>";
	
	tabContent+="<tr>";
	tabContent+="<th style=\"width:15%;text-align:center;\">Run Completed At</th>";
	tabContent+="<th style=\"width:10%;text-align:center;\">Run Time</th>";
	tabContent+="<th style=\"width:10%;text-align:center;\">Run Status</th>";
	for(var i=0; i<active_unresolved_severity.length;i++){
		tabContent+="<th style=\"text-align:center;\">"+active_unresolved_severity[i]+"</th>";
	}
	for(var i=0; i<active_waived_severity.length;i++){
		tabContent+="<th style=\"text-align:center;\">"+active_waived_severity[i].replace("waived-", "")+"</th>";
	}
	tabContent+="<th style=\"width:15%\">Success Criteria</th>";
	tabContent+="<th style=\"width:10%;text-align:center\" >Status</th>";	
	if(run_link=="true")
	{	
		tabContent+="<th style=\"width:10%;text-align:center\">View Results</th>";
	}
	tabContent+="</tr>";
	tabContent+="</thead>";
	
	var QGTempSmrTag="summary_Main";
	if(dCellStatus=="Fail"){QGTempSmrTag="summary_Fail";}
	if(dCellStatus=="Pass"){QGTempSmrTag="summary_Pass";}	
	
	tFoot_pass_status=$(xmlObj).find("module[name='"+tabTitle+"']").find("quality_data").find(QGTempSmrTag).attr("pass_status");
	tFoot_cell_class=getCellClassFromStatus(tFoot_pass_status);
	tFoot_trend_graph=$(xmlObj).find("module[name='"+tabTitle+"']").find("quality_data").find(QGTempSmrTag).attr("graph");
	tabContent+="<tfoot>";
	tabContent+="<tr>";
	tabContent+="<td>"+$(xmlObj).find("module[name='"+tabTitle+"']").find("quality_data").find(QGTempSmrTag).attr("name")+"</td>";
	tabContent+="<td>&nbsp;</td>";
	tabContent+="<td>&nbsp;</td>";
	tabContent+="<td style=\"text-align:center\">"+$(xmlObj).find("module[name='"+tabTitle+"']").find("quality_data").find(QGTempSmrTag).attr("run_status")+"</td>";
	
	for(var i=0; i<active_unresolved_severity.length;i++){
		tabContent+="<td style=\"text-align:center\">"+$(xmlObj).find("module[name='"+tabTitle+"']").find("quality_data").find(QGTempSmrTag).attr(active_unresolved_severity[i])+"</td>";
	}
	for(var i=0; i<active_waived_severity.length;i++){
		tabContent+="<td style=\"text-align:center\">"+$(xmlObj).find("module[name='"+tabTitle+"']").find("quality_data").find(QGTempSmrTag).attr(active_waived_severity[i])+"</td>";
	}
	
	
	tabContent+="<td>"+$(xmlObj).find("module[name='"+tabTitle+"']").find("quality_data").find(QGTempSmrTag).attr("success_criteria")+"</td>";
	tabContent+="<td class=\""+tFoot_cell_class+"\"><!--a onClick=\"createAggregateTrendChartForQG('"+tFoot_trend_graph+"')\" href=\"javascript:void(0);\"-->"+tFoot_pass_status+"<!--/a--></td>";	
	if(run_link=="true")
	{
			tabContent+="<td>&nbsp;</td>";
	}
	
	tabContent+="</tr>";
	tabContent+="</tfoot>";

	
	
	
	
	
	
	tabContent+="<tbody>";
	$(xmlObj).find("module[name='"+tabTitle+"']").find("quality_data").find("goal").each(function(){
		//each category
		var pass_status=$.trim($(this).attr('pass_status'));
		var cell_class=getCellClassFromStatus(pass_status);
		
		if(dCellStatus=="Show All" || dCellStatus=="All" || dCellStatus.toLowerCase()==pass_status.toLowerCase()){
			
			var tmp_qg_name=getUnslashedStr($(this).attr('name'));
			tabContent+="<tr>";
			
			if($(this).attr('link')!="" && typeof($(this).attr('link'))!="undefined")
			{
				
				var filePathExt=getFileExtensionByPath($(this).attr('link'));
				if(filePathExt=="xml")
				{
					tabContent+="<td><a href=\"goals_summary.html?goal="+$(this).attr('link')+"\" title=\""+$(this).attr('name')+"\" target=\"_blank\">"+tmp_qg_name+"</a></td>";
					
				}//if file path is  xml type
				else if(filePathExt=="csv")
				{
					tabContent+="<td><a href=\"csv_reader.html?report="+$(this).attr('link')+"\" title=\""+$(this).attr('name')+"\" target=\"_blank\">"+tmp_qg_name+"</a></td>";
					
				}//if file path is  xml type
				
				else
				{
					tabContent+="<td><a href=\""+$(this).attr('link')+"\" title=\""+$(this).attr('name')+"\" target=\"_blank\">"+tmp_qg_name+"</a></td>";
				}//if file path is not xml type
			
			}else{
				tabContent+="<td>"+tmp_qg_name+"</td>";
			}
			
			
			
			if($(this).attr('end_time')!="" && typeof($(this).attr('end_time'))!="undefined")
			{
				tabContent+="<td style=\"text-align:center\">"+$(this).attr('end_time')+"</td>";
			}
			else 
			{
				tabContent+="<td style=\"text-align:center\">N/A</td>";
			}
			
			
			tabContent+="<td style=\"text-align:center\">"+$(this).attr('run_time')+"</td>";
			tabContent+="<td style=\"text-align:center\">"+$(this).attr('run_status')+"</td>";
			
			
			for(var i=0; i<active_unresolved_severity.length;i++)
			{
				var tmp_seve_name=active_unresolved_severity[i];
				var tmp_seve_val=$(this).attr(tmp_seve_name);
				var tmp_seve_link_key=tmp_seve_name+"-link";
				
				if($(this).attr(tmp_seve_link_key)!="" && typeof($(this).attr(tmp_seve_link_key))!="undefined")
				{
					
					var filePathExt=getFileExtensionByPath($(this).attr(tmp_seve_link_key));
					if(filePathExt=="xml")
					{
						tabContent+="<td style=\"text-align:center\"><a href=\"goals_summary.html?goal="+$(this).attr(tmp_seve_link_key)+"\" title=\""+$(this).attr('name')+"\" target=\"_blank\">"+tmp_seve_val+"</a></td>";
						
					}//if file path is  xml type
					else if(filePathExt=="csv")
					{
						tabContent+="<td style=\"text-align:center\"><a href=\"csv_reader.html?report="+$(this).attr(tmp_seve_link_key)+"\" title=\""+$(this).attr('name')+"\" target=\"_blank\">"+tmp_seve_val+"</a></td>";
						
					}//if file path is  xml type
					
					else
					{
						tabContent+="<td style=\"text-align:center\"><a href=\""+$(this).attr(tmp_seve_link_key)+"\" title=\""+$(this).attr('name')+"\" target=\"_blank\">"+tmp_seve_val+"</a></td>";
					}//if file path is not xml type
				
				}
				else
				{
					tabContent+="<td style=\"text-align:center\">"+tmp_seve_val+"</td>";
				}
				
				//tabContent+="<td style=\"text-align:center\">"+temp_seve_val+"</td>";
			
			
			
				//as on 21st apr 2014, adding links to all severity
			}
			
			
			
			for(var i=0; i<active_waived_severity.length;i++)
			{
			
			
				
			
				var tmp_seve_name=active_waived_severity[i];
				var tmp_seve_val=$(this).attr(tmp_seve_name);
				var tmp_seve_link_key=tmp_seve_name+"-link";
				
				if($(this).attr(tmp_seve_link_key)!="" && typeof($(this).attr(tmp_seve_link_key))!="undefined")
				{
					
					var filePathExt=getFileExtensionByPath($(this).attr(tmp_seve_link_key));
					if(filePathExt=="xml")
					{
						tabContent+="<td style=\"text-align:center\"><a href=\"goals_summary.html?goal="+$(this).attr(tmp_seve_link_key)+"\" title=\""+$(this).attr('name')+"\" target=\"_blank\">"+tmp_seve_val+"</a></td>";
						
					}//if file path is  xml type
					else if(filePathExt=="csv")
					{
						tabContent+="<td style=\"text-align:center\"><a href=\"csv_reader.html?report="+$(this).attr(tmp_seve_link_key)+"\" title=\""+$(this).attr('name')+"\" target=\"_blank\">"+tmp_seve_val+"</a></td>";
						
					}//if file path is  xml type
					
					else
					{
						tabContent+="<td style=\"text-align:center\"><a href=\""+$(this).attr(tmp_seve_link_key)+"\" title=\""+$(this).attr('name')+"\" target=\"_blank\">"+tmp_seve_val+"</a></td>";
					}//if file path is not xml type
				
				}
				else
				{
					tabContent+="<td style=\"text-align:center\">"+tmp_seve_val+"</td>";
				}
				
				//tabContent+="<td style=\"text-align:center\">"+temp_seve_val+"</td>";
			
			
			
				//as on 21st apr 2014, adding links to all severity
			
			}
			
			
			
			tabContent+="<td>"+$(this).attr('success_criteria')+"</td>";
		
			if($(this).attr('graph')!="" && typeof($(this).attr('graph'))!="undefined")
			{
				tabContent+="<td class=\""+cell_class+"\"><a onClick=\"createTrendChartForQG('"+$(this).attr('graph')+"')\" href=\"javascript:void(0);\">"+pass_status+"</a></td>";
			}
			else{
				tabContent+="<td class=\""+cell_class+"\">"+pass_status+"</td>";
			}
			
			
			if(run_link=="true")
			{	
					
				if($.trim($(this).attr('run_link'))!="")
				{
					tabContent+="<td style=\"text-align:center\"><a href=\""+$(this).attr('run_link')+"\">Open</a></td>";	
				}
				else
				{
					tabContent+="<td>&nbsp;</td>";
				}
			}
			
			
			
			tabContent+="</tr>";
		
		}
		
						
		//foreach design_data-> category->items
	});
	//foreach $(xmlObj).find("module[name='"+tabTitle+"']").find("design_data").each
	
	tabContent+="</tbody>";
	tabContent+="</table>";
	tabContent+="</td></tr>";
	
	tabContent+="<tr><td colspan=\"3\">&nbsp;</td></tr>";
	tabContent+="<tr><td>&nbsp;</td><td>&nbsp;</td><td style=\"text-align:right;\">";
	for(var i=0;i<tmp_all_filters.length;i++){
		if(tmp_all_filters[i]=="Pass"){
			tabContent+="<img src=\"./img/pass_val.png\" style=\"align:left; padding-right:5px; padding-left:5px\">";
		}
		else if(tmp_all_filters[i]=="Fail"){
			tabContent+="<img src=\"./img/fail_val.png\" style=\"align:left; padding-right:5px; padding-left:5px\">";
		}
		
		if(dCellStatus==tmp_all_filters[i]){
			tabContent+="<strong>"+tmp_all_filters[i]+"</strong>";
		}
		else{
			tabContent+="<a href=\"javascript:void(0);\" onclick=\"javascript:createBlockSummaryTab('"+xmlFilePath+"', '"+tabTitle+"', '"+tmp_all_filters[i]+"')\">"+tmp_all_filters[i]+"</a>";
		}
			
		if(i!=tmp_all_filters.length - 1){
			tabContent+="&nbsp;&nbsp;|&nbsp;&nbsp;";
		}
	}
	tabContent+="</td></tr>";
	
	
	
	
	var table_id1="tblDO-" + tabTitle.replace(/ /g,"_").replace(/\(/g,"").replace(/\)/g,"_").replace(/\//g,"_");
	var tgltblLink_id1="tgl"+table_id1;
	
	tabContent+="<tr><td style=\"vertical-align:top;text-align:center;padding-top:5px;\">";
	tabContent+="<a href=\"javascript:void(0);\" onclick=\"javascript:toggleAllDataRows('"+table_id1+"', '"+tgltblLink_id1+"')\" class=\"link_expand_collapse\" id=\""+tgltblLink_id1+"\">-</a>";
	tabContent+="</td><td style=\"vertical-align:top;\" colspan=\"2\">";
	//design objective table starts creating here
	tabContent+="<table class=\"dataTable1\"  id=\""+table_id1+"\">";
	tabContent+="<thead>";
	tabContent+="<tr>";
	tabContent+="<th style=\"width:20%\">Category</th>";
	//tabContent+="<th style=\"width:12%\">Run Status</th>";
	tabContent+="<th style=\"width:30%\">Design Objective</th>";
	tabContent+="<th style=\"width:30%\">Success Criteria</th>";
	tabContent+="<th style=\"width:10%;text-align:center\" >Status</th>";	
	
	if(run_link=="true")
	{
		tabContent+="<th style=\"width:10%;text-align:center\">View Results</th>";
	}
	
	tabContent+="</tr>";
	tabContent+="</thead>";
	
	tFoot_pass_status=$(xmlObj).find("module[name='"+tabTitle+"']").find("design_data").find(QGTempSmrTag).attr("pass_status");
	tFoot_cell_class=getCellClassFromStatus(tFoot_pass_status);
	tFoot_trend_graph=$(xmlObj).find("module[name='"+tabTitle+"']").find("design_data").find(QGTempSmrTag).attr("graph");
	
	tabContent+="<tfoot>";
	tabContent+="<tr>";
	tabContent+="<td >"+$(xmlObj).find("module[name='"+tabTitle+"']").find("design_data").find(QGTempSmrTag).attr("name")+"</td>";
	//tabContent+="<td >"+$(xmlObj).find("module[name='"+tabTitle+"']").find("design_data").find(QGTempSmrTag).attr("run_status")+"</td>";
	tabContent+="<td >&nbsp;</td>";
	tabContent+="<td >"+$(xmlObj).find("module[name='"+tabTitle+"']").find("design_data").find(QGTempSmrTag).attr("success_criteria")+"</td>";
	tabContent+="<td class=\""+tFoot_cell_class+"\">"+tFoot_pass_status+"</td>";	
	if(run_link=="true")
	{
		tabContent+="<td>&nbsp;</td>";
	}
	tabContent+="</tr>";
	tabContent+="</tfoot>";
	tabContent+="<tbody>";
	
	$(xmlObj).find("module[name='"+tabTitle+"']").find("design_data").find("category").each(function(){
		var num_items=$(this).find("item").length;
		num_items+=$(this).find("item").find("child_item").length;
		
		var category_name=$(this).attr('name');
		
		$(this).find("item").each(function(key, value){
			var status=$.trim($(this).attr('pass_status'));
			var cell_class=getCellClassFromStatus(status);
			
			var temp_parent_td_id="td_"+category_name+"_category";
			
			if(dCellStatus=="Show All" || dCellStatus=="All")
				{
								if(($(this).find("child_item").length)>0)
								{
									var temp_child_item_class=category_name+"_childitem_"+key;
									var temp_child_item_count=$(this).find("child_item").length;
									
									var pass_status=$.trim($(this).attr('pass_status'));
									var cell_class=getCellClassFromStatus(pass_status);
									
									if(key==0){
										tabContent+="<tr style=\"border-top:2px solid #1A321C\">";
										tabContent+="<td rowspan=\""+num_items+"\" id=\""+temp_parent_td_id+"\"><strong>"+category_name+"</strong></td>";	
									}else{
										tabContent+="<tr>";
									}
									//tabContent+="<td><strong>"+$(this).attr('run_status')+"</strong></td>";
									
									
									var filePathExt="";
									if(typeof($(this).attr('link'))!="undefined"){
										filePathExt=getFileExtensionByPath($(this).attr('link'));
									}
									
									if(filePathExt=="xml"){
										tabContent+="<td><strong><a class=\"ui-icon ui-icon-minus\" style=\"border:1px solid #CCCCCC; float:left;\" onclick=\"javascript:toggleTableRows('"+temp_child_item_class+"', '"+temp_parent_td_id+"', '"+temp_child_item_count+"', this)\"></a>&nbsp;<a href=\"goals_summary.html?goal="+$(this).attr('link')+"\" title=\""+$(this).attr('name')+"\" target=\"_blank\">"+$(this).attr('name')+"</a></strong></td>";
									}
									
									else if(filePathExt=="csv")
									{
										tabContent+="<td><strong><a class=\"ui-icon ui-icon-minus\" style=\"border:1px solid #CCCCCC; float:left;\" onclick=\"javascript:toggleTableRows('"+temp_child_item_class+"', '"+temp_parent_td_id+"', '"+temp_child_item_count+"', this)\"></a>&nbsp;<a href=\"csv_reader.html?report="+$(this).attr('link')+"\" title=\""+$(this).attr('name')+"\" target=\"_blank\">"+$(this).attr('name')+"</a></strong></td>";	
									}//if file path is  xml type
				
									
									
									
									else{
										tabContent+="<td><strong><a class=\"ui-icon ui-icon-minus\" style=\"border:1px solid #CCCCCC; float:left;\" onclick=\"javascript:toggleTableRows('"+temp_child_item_class+"', '"+temp_parent_td_id+"', '"+temp_child_item_count+"', this)\"></a>&nbsp;"+$(this).attr('name')+"</strong></td>";
									}
									
									
									tabContent+="<td><strong>"+$(this).attr('success_criteria')+"</strong></td>";
									
									
									if($(this).attr('graph')!="" && typeof($(this).attr('graph'))!="undefined")
									{
										tabContent+="<td class=\""+cell_class+"\"><a onClick=\"createTrendChartForDO('"+$(this).attr('graph')+"')\" href=\"javascript:void(0);\" title=\""+$(this).attr('tooltip')+"\">"+pass_status+"</a></td>";
									}
									else{
										tabContent+="<td class=\""+cell_class+"\">"+pass_status+"</td>";
									}
									
									if(run_link=="true")
									{	
											
										if($.trim($(this).attr('run_link'))!="")
										{
											tabContent+="<td style=\"text-align:center\"><a href=\""+$(this).attr('run_link')+"\">Open</a></td>";	
										}
										else
										{
											tabContent+="<td>&nbsp;</td>";
										}
									}
									
									
									
									tabContent+="</tr>";
								
									$(this).find("child_item").each(function(){
										var pass_status=$.trim($(this).attr('pass_status'));
										var cell_class=getCellClassFromStatus(pass_status);
										//alert(temp_child_item_class);
										tabContent+="<tr class=\""+temp_child_item_class+"\">";
										/*
										tabContent+="<td rowspan=\""+num_items+"\">"+category_name+"("+num_items+")</td>";
										
										*/
										//tabContent+="<td>"+$(this).attr('run_status')+"</td>";
										
										var filePathExt="";
										if(typeof($(this).attr('link'))!="undefined"){
											filePathExt=getFileExtensionByPath($(this).attr('link'));
										}
									
										if(filePathExt=="xml"){
											tabContent+="<td title=\""+$(this).attr('tooltip')+"\"><a href=\"goals_summary.html?goal="+$(this).attr('link')+"\" title=\""+$(this).attr('name')+"\" target=\"_blank\">"+$(this).attr('name')+"</a></td>";
										}
										
										else if(filePathExt=="csv"){
											tabContent+="<td title=\""+$(this).attr('tooltip')+"\"><a href=\"csv_reader.html?report="+$(this).attr('link')+"\" title=\""+$(this).attr('name')+"\" target=\"_blank\">"+$(this).attr('name')+"</a></td>";
										}
										
										
										else{
											tabContent+="<td title=\""+$(this).attr('tooltip')+"\">"+$(this).attr('name')+"</td>";
										}
										
										
										tabContent+="<td>"+$(this).attr('success_criteria')+"</td>";
										
										if($(this).attr('graph')!="" && typeof($(this).attr('graph'))!="undefined")
										{
											tabContent+="<td class=\""+cell_class+"\"><a onClick=\"createTrendChartForDO('"+$(this).attr('graph')+"')\" href=\"javascript:void(0);\" title=\""+$(this).attr('tooltip')+"\">"+pass_status+"</a></td>";
										}
										else{
											tabContent+="<td class=\""+cell_class+"\">"+pass_status+"</td>";
										}

									
										if(run_link=="true")
										{	
												
											if($.trim($(this).attr('run_link'))!="")
											{
												tabContent+="<td style=\"text-align:center\"><a href=\""+$(this).attr('run_link')+"\">Open</a></td>";	
											}
											else
											{
												tabContent+="<td>&nbsp;</td>";
											}
										}
										
										
										
										tabContent+="</tr>";
									});
								}//if td has child values...
								else{
									var pass_status=$.trim($(this).attr('pass_status'));
									var cell_class=getCellClassFromStatus(status);
									if(key==0){
										tabContent+="<tr style=\"border-top:2px solid #1A321C\">";
										tabContent+="<td rowspan=\""+num_items+"\" id=\""+temp_parent_td_id+"\"><strong>"+category_name+"</strong></td>";	
									}else{
										tabContent+="<tr>";
									}
									//tabContent+="<td>"+$(this).attr('run_status')+"</td>";
									
									
									var filePathExt="";
									if(typeof($(this).attr('link'))!="undefined"){
										filePathExt=getFileExtensionByPath($(this).attr('link'));
									}
									
									if(filePathExt=="xml"){
										tabContent+="<td title=\""+$(this).attr('tooltip')+"\"><a href=\"goals_summary.html?goal="+$(this).attr('link')+"\" title=\""+$(this).attr('name')+"\" target=\"_blank\">"+$(this).attr('name')+"</a></td>";
									}
									
									else if(filePathExt=="csv"){
										tabContent+="<td title=\""+$(this).attr('tooltip')+"\"><a href=\"csv_reader.html?report="+$(this).attr('link')+"\" title=\""+$(this).attr('name')+"\" target=\"_blank\">"+$(this).attr('name')+"</a></td>";
									}
									
									
									else{
										tabContent+="<td title=\""+$(this).attr('tooltip')+"\">"+$(this).attr('name')+"</td>";
									}
									
									
									tabContent+="<td>"+$(this).attr('success_criteria')+"</td>";
									
									if($(this).attr('graph')!="" && typeof($(this).attr('graph'))!="undefined")
									{
										tabContent+="<td class=\""+cell_class+"\"><a onClick=\"createTrendChartForDO('"+$(this).attr('graph')+"')\" href=\"javascript:void(0);\" title=\""+$(this).attr('tooltip')+"\">"+pass_status+"</a></td>";
									}
									else{
										tabContent+="<td class=\""+cell_class+"\">"+pass_status+"</td>";
									}
									
									if(run_link=="true")
									{	
											
										if($.trim($(this).attr('run_link'))!="")
										{
											tabContent+="<td style=\"text-align:center\"><a href=\""+$(this).attr('run_link')+"\">Open</a></td>";	
										}
										else
										{
											tabContent+="<td>&nbsp;</td>";
										}
									}
									
									
									tabContent+="</tr>";
									
								}//if td doesnt have child values...
			}//if(dCellStatus=="Show All" || dCellStatus=="All")
			
			else if(dCellStatus.toLowerCase()=="pass" || dCellStatus.toLowerCase()=="fail"){
					
								var tmp_parent_do_chunks=$(this).attr('name').split("(");
								var tmp_parent_do_name=tmp_parent_do_chunks[0];
								tmp_parent_do_title=$(this).attr('name');
								
								if(($(this).find("child_item").length)>0)
								{
									
									$(this).find("child_item").each(function(){
										var tmp_child_do_chunks=$(this).attr('name').split("=");
										var tmp_child_do_name=tmp_child_do_chunks[1];
										var tmp_name=tmp_parent_do_name+"="+tmp_child_do_name;
										var pass_status=$.trim($(this).attr('pass_status'));
										var cell_class=getCellClassFromStatus(pass_status);
										
										if(dCellStatus.toLowerCase()==pass_status.toLowerCase())
										{
											tabContent+="<tr class=\""+temp_child_item_class+"\">";
											tabContent+="<td >"+category_name+"</td>";
											//tabContent+="<td>"+$(this).attr('run_status')+"</td>";
											
											
											
											
											var filePathExt="";
											if(typeof($(this).attr('link'))!="undefined"){
												filePathExt=getFileExtensionByPath($(this).attr('link'));
											}
											
											if(filePathExt=="xml"){
												tabContent+="<td title=\""+$(this).attr('tooltip')+"\"><a href=\"goals_summary.html?goal="+$(this).attr('link')+"\" title=\""+$(this).attr('name')+"\" target=\"_blank\">"+tmp_name+"</a></td>";
											}
											
											else if(filePathExt=="csv"){
												tabContent+="<td title=\""+$(this).attr('tooltip')+"\"><a href=\"csv_reader.html?report="+$(this).attr('link')+"\" title=\""+$(this).attr('name')+"\" target=\"_blank\">"+tmp_name+"</a></td>";
											}
											
											else{
												tabContent+="<td title=\""+$(this).attr('tooltip')+"\">"+tmp_name+"</td>";
											}
											
											
											
											
											
											tabContent+="<td>"+$(this).attr('success_criteria')+"</td>";
											tabContent+="<td class=\""+cell_class+"\"><a onClick=\"createTrendChartForDO('"+$(this).attr('graph')+"')\" href=\"javascript:void(0);\" title=\""+$(this).attr('tooltip')+"\">"+pass_status+"</a></td>";
											
											if(run_link=="true")
											{	
													
												if($.trim($(this).attr('run_link'))!="")
												{
													tabContent+="<td style=\"text-align:center\"><a href=\""+$(this).attr('run_link')+"\">Open</a></td>";	
												}
												else
												{
													tabContent+="<td>&nbsp;</td>";
												}
											}
											
											
											tabContent+="</tr>";
										}	
									});
								}//if td has child values...
								else{
									var pass_status=$.trim($(this).attr('pass_status'));
									var cell_class=getCellClassFromStatus(status);
									
									if(dCellStatus.toLowerCase()==pass_status.toLowerCase())
									{
										tabContent+="<tr>";
										tabContent+="<td>"+category_name+"</td>";	
										//tabContent+="<td>"+$(this).attr('run_status')+"</td>";
										
										
										
										
										var filePathExt="";
										if(typeof($(this).attr('link'))!="undefined"){
											filePathExt=getFileExtensionByPath($(this).attr('link'));
										}
									
										if(filePathExt=="xml"){
											tabContent+="<td title=\""+$(this).attr('tooltip')+"\"><a href=\"goals_summary.html?goal="+$(this).attr('link')+"\" title=\""+$(this).attr('name')+"\" target=\"_blank\">"+$(this).attr('name')+"</a></td>";
										}
										
										else if(filePathExt=="csv"){
											tabContent+="<td title=\""+$(this).attr('tooltip')+"\"><a href=\"csv_reader.html?report="+$(this).attr('link')+"\" title=\""+$(this).attr('name')+"\" target=\"_blank\">"+$(this).attr('name')+"</a></td>";
										}
										
										else{
											tabContent+="<td title=\""+$(this).attr('tooltip')+"\">"+$(this).attr('name')+"</td>";
										}
										
										
										
										tabContent+="<td>"+$(this).attr('success_criteria')+"</td>";
										tabContent+="<td class=\""+cell_class+"\"><a onClick=\"createTrendChartForDO('"+$(this).attr('graph')+"')\" href=\"javascript:void(0);\" title=\""+$(this).attr('tooltip')+"\">"+pass_status+"</a></td>";
										
										if(run_link=="true")
										{	
												
											if($.trim($(this).attr('run_link'))!="")
											{
												tabContent+="<td style=\"text-align:center\"><a href=\""+$(this).attr('run_link')+"\">Open</a></td>";	
											}
											else
											{
												tabContent+="<td>&nbsp;</td>";
											}
										}
										
										tabContent+="</tr>";
									}								
								}//if td doesnt have child values...
			
			
			}//else if(dCellStatus.toLowerCase()!="pass" or "fail")
			
			
		});
		
		//foreach design_data-> category->items
	});
	//foreach $(xmlObj).find("module[name='"+tabTitle+"']").find("design_data").each
	//design objective table ends creating here
	tabContent+="</tbody>";
	tabContent+="</table>";
	//ending DO table
	tabContent+="</td></tr>";
	tabContent+="</table>";
	//ending main table
	//design objective table ends creating here
	
	
	//goal summary  table ends creating here
	
	var tab_id="cntMainTabs-" + tabTitle.replace(/ /g,"_").replace(/\(/g,"").replace(/\)/g,"_").replace(/\//g,"_");
	createTab(tab_id, tabTitle, tabContent);
	
	if(dCellStatus=="All"){
		toggleAllDataRows(table_id,tgltblLink_id);
		toggleAllDataRows(table_id1, tgltblLink_id1);
	}
	
}


function createAggregateTrendChartForQG(xmlFilePath){
	alert(xmlFilePath);	
}










function createIframeReport(xmlFilePath, moduleName, goalName){
	//xmlFilePath=xmlFilePath.replace(/dashboard_data_files/g,"XML");
	var xmlGraph=XMLToString(getFileContents(xmlFilePath));
	xmlObj=$($.parseXML(xmlGraph));
	$('#iFrameReportDiv').remove();
	var iFrameReportDiv="<div id=\"iFrameReportDiv\">";
	iFrameReportDiv+="<div><strong>Module:</strong> "+$(xmlObj).find("module").attr("name")+"&nbsp;&nbsp;";
	iFrameReportDiv+="<strong>Goal Name: </strong>"+$(xmlObj).find("goal").attr("name")+"</div><br>";
	
	var num_available_reports=0;
	var str_available_report_buttons="";
	$(xmlObj).find("report").each(function(){
		if($(this).attr("link")!=""){
			var btn_id="report_button"+num_available_reports;
			str_available_report_buttons+="<a href=\""+$(this).attr("link")+"\" target=\"iframeReport\" class=\"report_button_normal\" onclick=\"javascript:toggleReportButtons('"+btn_id+"');\" id=\""+btn_id+"\">"+$(this).attr("name")+"</a>&nbsp;&nbsp;";
			num_available_reports++;
		}			
	});
	
	if(num_available_reports>0 && str_available_report_buttons!=""){
		
		iFrameReportDiv+=str_available_report_buttons;
		iFrameReportDiv+="<iframe style=\"height:80%;width:100%; border:0px;border-top:1px solid #CCCCCC;margin-top:3px;\" id=\"iframeReport\" name=\"iframeReport\">";
	}else{
		iFrameReportDiv+="<div style=\"margin-top:10px;color:red;\">No reports available for this Module <strong>("+moduleName+")</strong> and goalName <strong>("+goalName+")</strong></div><br>Press <strong>ESC</strong> to Close this Window";
	}	
	iFrameReportDiv+="</div>";
	$('body').append(iFrameReportDiv);
	
	if(num_available_reports>0 && str_available_report_buttons!=""){
	
		$("#iframeReport").attr("src", $(xmlObj).find('report').eq(0).attr("link"));
		$(".report_button_normal:first").attr("class", "report_button_active");
		$('#iFrameReportDiv').dialog({
			//title: "Report for "+moduleName+" - "+goalName+" <a href=\""+xmlFilePath+"\" style=\"font-size:9px;\" target=\"_blank\">Source</a>",
			title: "Report for "+moduleName+" - "+goalName,
			autoOpen: false,
			width: $(window).width()-50,
			height: $(window).height()-50
					
		});
	}else{
		$('#iFrameReportDiv').dialog({
			title: "Report for "+moduleName+" - "+goalName,
			autoOpen: false,
			width: $(window).width()-50,
			height: 500
		});
	}
		
	
	$('#iFrameReportDiv').dialog('open');
}




function toggleReportButtons(btnObj){
	$(".report_button_active").attr("class", "report_button_normal");
	$("#"+btnObj).attr("class", "report_button_active");
	//alert(btnObj);
}








function toggleTableRows(row_class, category_td, adjust_rows, img_element){
	
	if($('.'+row_class).is(":visible")){
		
		var existing_rowspan=$('#'+category_td).attr('rowspan');
		var new_rowspan=parseInt(existing_rowspan) - parseInt(adjust_rows);
		$('#'+category_td).attr('rowspan',new_rowspan);
		$('.'+row_class).hide();
		$(img_element).attr('class', "ui-icon ui-icon-plus");
	}else{
		var existing_rowspan=$('#'+category_td).attr('rowspan');
		var new_rowspan=parseInt(existing_rowspan) + parseInt(adjust_rows);
		$('#'+category_td).attr('rowspan',new_rowspan);
		$('.'+row_class).show();
		$(img_element).attr('class', "ui-icon ui-icon-minus");
		
	
	}		
	
	
	
}

function toggleHeadingTableRows(row_class,  img_element){
	
	if($('.'+row_class).is(":visible")){
		$('.'+row_class).hide();
		$(img_element).attr('class', "ui-icon ui-icon-plus");
	}else{
		$('.'+row_class).show();
		$(img_element).attr('class', "ui-icon ui-icon-minus");
	}		
	
}

function getCellClassFromStatus(tmpStatus){
	var status=tmpStatus.toLowerCase();
	if(status=="pass"){cell_class= "pass_val";}
	else if(status=="fail"){cell_class= "fail_val";}
	else if(status=="data"){cell_class= "data_val";}
	else if (status==""){cell_class= "";}
	else{cell_class= "unknown_val";}
	return cell_class;
}

function toggleAllChildren(tableId){
	//alert($('#'+tableId).html());
	

	$('#'+tableId+' tbody tr').each(function(key, value){
		
		if($(this).attr("class")!="" && typeof($(this).attr("class"))!="undefined"){
			var classname=$(this).attr("class");
			
			if($('.'+classname).is(":visible")){
				$('.'+classname).hide();
			}else{
				$('.'+classname).show();
			}	
		}
	});
	
	$('#'+tableId+' a[class^="ui-icon"]').each(function(key, value){
		if($(this).attr("class")=="ui-icon ui-icon-plus"){
			$(this).attr("class", "ui-icon ui-icon-minus");
		}else{
			$(this).attr("class", "ui-icon ui-icon-plus");
		}
	});
	
	
	
}


function toggleAllDataRows(tableId, linkObj){
	
	if($('#'+tableId+' tbody tr').first().is(":visible")){
		$('#'+tableId+' tbody tr').each(function(key, value){$(this).hide();});
		$("#"+linkObj).html("+");
	}
	else{
		$('#'+tableId+' tbody tr').each(function(key, value){$(this).show();});
		$("#"+linkObj).html("-");
	}
	/*
	$('#'+tableId+' tbody tr').each(function(key, value){
		if($(this).is(":visible")){
			$(this).hide();
		}else{
			$(this).show();
		}	
	});
	*/
	
}



function toggleLegendSeries(plotName, seriesName, linkId){
	 //var toggle = trendChart.series[2].show;
	 var seriesName1 = parseInt(seriesName) + 1;
	 if($('#'+linkId).css("text-decoration")=="none"){
	 	$('#'+linkId).css("text-decoration", "line-through");	
	 	trendChart.series[seriesName].show = false;
		trendChart.series[seriesName1].show = false;
		//trendChart.series[seriesName+1].show = false;
	 }else{
	 	$('#'+linkId).css("text-decoration", "none");
		trendChart.series[seriesName].show = true;
		trendChart.series[seriesName1].show = true;
		//trendChart.series[seriesName+1].show = true;	
	 }
	 trendChart.replot();
	 
}
