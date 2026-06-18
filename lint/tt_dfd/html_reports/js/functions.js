// JavaScript Document

function checkConfiguration(){

	var overlayStartDiv="<div id=\"overlayDivForIncompatible\" style=\"display:none\">";
	overlayStartDiv+="<div class=\"ui-state-highlight ui-corner-all\" style=\"padding: 20px; padding-top:10px; height:250px; margin: 100px;\">";
	overlayStartDiv+="<img src=\"img/spyglass_logo_white.jpg\" style=\"margin-right:50px;margin-bottom:200px;margin-top:50px;\" height=\"67\" align=\"left\" width=\"208\">";	
	overlayStartDiv+="<h1>SpyGlass SoC Dashboard - PRE ALPHA (Testing)</h1>";
	overlayStartDiv+="<strong>Before you Proceed, please see if these reports will work on Your Browser:</strong>";
	overlayStartDiv+="<ul>";
	overlayStartDiv+="<li>This Dashboard is tested on: IE 8+, Firefox 10+. <br><strong>Your Browser Details: </strong>" + getBrowser()+"  Version:"+getBrowserFullVersion();
	if(isValidBrowser()){
		overlayStartDiv+="<br><strong style=\"color:red;\">Your Browser is not VALID!!!</strong>";
	} 
	overlayStartDiv+="<li>Minimum Screen Width Required: 1280px. <br><strong>On Your System:</strong> ("+$(window).width()+"X"+$(window).height()+")";
	if(isValidResolution()){
		overlayStartDiv+="<br><strong style=\"color:red;\">Resolution Not VALID!!!</strong>";
	} 
	overlayStartDiv+="<li>Javascript must be Enabled.";
	overlayStartDiv+="</ul>"
	overlayStartDiv+="<input type=\"button\" class=\"ui-button1\" value=\"take me to dashboard\" id=\"btnCloseOverlayDivForIncompatible\">";
	overlayStartDiv+="</div></div>";
	
	$('body').append(overlayStartDiv);
	$('#overlayDivForIncompatible').show("highlight"); 
	$('#overlayDivForIncompatible').attr("class","ui-widget-overlay");
	
}



function getFileContents(filepath)
{
		var return_data;
		$.ajax({
			url: filepath,
			type: 'GET',
			dataType: 'xml',
			async: false,
			timeout: 10000,
			error: function(){
				alert('Error loading : '+filepath);
			},
			success: function(data){
				return_data=data;
				
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
			ticks.push($(this).attr('name'));
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



function drawTopLevelChart(xmlDocTopSummary, theChartObj, theTargetDiv)
{
	
	var strTopSummary_title = getSingleNodeValue(xmlDocTopSummary, "title");
	var strTopSummary_ticks= getTopSummaryTicks(xmlDocTopSummary);
	var strTopSummary_passValues= getTopSummaryPassValues(xmlDocTopSummary);
	var strTopSummary_inProgressValues= getTopSummaryinProgressValues(xmlDocTopSummary);
	var strTopSummary_failValues= getTopSummaryFailValues(xmlDocTopSummary);
	
	var theChartObj=$.jqplot(theTargetDiv, [strTopSummary_passValues, strTopSummary_inProgressValues, strTopSummary_failValues],
		{
			// Tell the plot to stack the bars.
			stackSeries: true,
			captureRightClick: true,
			animate: true,
			animateReplot: true,
			//title:strTopSummary_title,
			title:"Composite Status",
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
			seriesColors: chart_series_colors,
							
			axes: 
			{
				xaxis: 
				{
					renderer: $.jqplot.CategoryAxisRenderer,
					tickRenderer: $.jqplot.CanvasAxisTickRenderer,
					ticks: strTopSummary_ticks,
					tickOptions: {fontSize: '8pt', angle: -30}
				},
				yaxis:
				{ 
					pad: 1, tickOptions: {formatString: '%d%'},
					min:0, max:100
				}
			},
			/*
			legend: 
			{
				show: true,
				location: 's',
				placement: 'outsideGrid',
				
				
			},
			*/
			grid: {
				drawGridLines: true,
				background: '#FFFFFF', 
				shadow: true,
				shadowAngle: 30,
				drawBorder:true,
				shadowOffset :3
				
			},
			
			 highlighter: {
				show: true,
				showMarker: false,
				tooltipLocation: 's',
				
				tooltipOffset:40,
				tooltipFadeSpeed:'fast',
				
				
     		 }
				
		});
}//function getTopLevelChart


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
			animate: true,
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
			seriesColors: chart_series_colors,
							
			axes: 
			{
				xaxis: 
				{
					renderer: $.jqplot.CategoryAxisRenderer,
					tickRenderer: $.jqplot.CanvasAxisTickRenderer,
					ticks: strQualSummary_ticks,
					tickOptions: {fontSize: '8pt', angle: -30}
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
				shadow: true,
				shadowAngle: 30,
				drawBorder:true,
				shadowOffset :3
				
			},
			 highlighter: {
				show: true,
				showMarker: false,
				tooltipLocation: 's',
				
				tooltipOffset:40,
				tooltipFadeSpeed:'fast',
				
				
     		 }
			
				
		});
		
		return opt;

}//function getTopLevelCategoryChartOptions ends


///////////////////////////////////////////////
/* function ends for DB_TOP_SUMMARY.XML		*/
///////////////////////////////////////////////



//////////////////////////////////////////////////
/* function starts for DB_BLOCK_SUMMARY.XML		*/
//////////////////////////////////////////////////


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




function createMainBlockTab(){

			var strBlockSummary=XMLToString(getFileContents("dashboard_data_files/DB_Block_Summary.xml"));
			var xmlDocBlockSummary = $($.parseXML(strBlockSummary));
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
			var arrBlockSummaryGoalNames=getBlockSummaryDistinctQualityGoals(xmlDocBlockSummary);
			tblBlockSummaryQualityGoalsCols=arrBlockSummaryGoalNames.length;
			tblBlockSummaryCols+=tblBlockSummaryQualityGoalsCols;
			tblBlockSummaryCols+=2;//2 more cols for modulename and last update date	

			
			 
			//console.log(getBlockSummaryDistinctQualityGoals(xmlDocBlockSummary));
			
			
			var tblBlockSummary="<table class=\"dataTable1\" style=\"font-size:9px;\">";
			
			//creating first row
			tblBlockSummary+="<tr><td>&nbsp;</td><td colspan=\""+(tblBlockSummaryDesignObjectiveCols)+"\"><h3 class=\"ui-header\">Design Objectives</h3></td>";
			tblBlockSummary+="<td colspan=\""+(tblBlockSummaryQualityGoalsCols)+"\"><h3 class=\"ui-header\">Quality Goals</h3></td>";
			tblBlockSummary+="<td>&nbsp;</td></tr>";	
			//creating first row ends here
			
			
			//creating second row
			tblBlockSummary+="<tr>";
			tblBlockSummary+="<td style=\"text-align:center;font-size:13px;\">&nbsp;</td>";
			$.each(arrBlockSummaryDesignObjectives, function(key, value){
				var colspan_len=arrBlockSummaryDesignObjectivesMulti[value].length;				
				tblBlockSummary+="<td colspan=\""+(colspan_len)+"\" style=\"text-align:center;font-size:13px;\">"+value+"</td>";
			});
			
			var colspan_len=arrBlockSummaryGoalNames.length;				
			tblBlockSummary+="<td colspan=\""+(colspan_len)+"\" style=\"text-align:center;font-size:13px;\">Goal Names</td>";
				
			tblBlockSummary+="<td>&nbsp;</td>";
			tblBlockSummary+="</tr>";
			//creating second row ends here
			
			//creating third row
			tblBlockSummary+="<tr>";
			tblBlockSummary+="<th><strong>module</strong></th>";
			
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
					tblBlockSummary+="<th  style=\"text-align:center;\"><a onclick=\"createBlockHeadingSummaryTab('"+tmp_header_xml_link+"', '"+value+" - "+value1+"')\" href=\"javascript:void(0);\">"+value1+"</a></th>";
				});		
			});	
			
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
				tblBlockSummary+="<th  style=\"text-align:center;\"><a onclick=\"createBlockHeadingGoalSummaryTab('"+tmp_header_xml_link+"', '"+value+"')\" href=\"javascript:void(0);\">"+value.replace(/_/g," ")+"</a></th>";
			});	
			
			
			
			tblBlockSummary+="<th>Last Updated On</th>";
			tblBlockSummary+="</tr>";
			//creating third row ends here
			
			//creating fourth(onward) row - all modules 
			$.each(getBlockSummaryModules(xmlDocBlockSummary), function(key, value){
					tblBlockSummary+="<tr>";
					tblBlockSummary+="<td class=\"sideHeader\"><a onClick=\"createBlockSummaryTab('dashboard_data_files/DashBoard_Main.xml', '"+value+"')\" href=\"javascript:void(0);\" title=\"Open Dashboard for: "+value+"\"><strong>"+value+"</strong></a></td>";
					
					$.each(arrBlockSummaryDesignObjectives, function(key1, value1){
						$.each(arrBlockSummaryDesignObjectivesMulti[value1], function(key2, value2){
							//value:modulename, value2: design objective, value 3: design objective item
							var status_node=$(xmlDocBlockSummary).find("module[name='"+value+"']").find("category[name='"+value1+"']").find("item[name='"+value2+"']");
							var status=$.trim(status_node.attr("pass_status")).toLowerCase();
							var cell_link=status_node.attr("cell_link");
							var cell_last_update=status_node.attr("date_time");
							var cell_class="";
							if(status=="pass"){
								//cell_class= "ui-icon ui-icon-check";
								cell_class= "pass_val";
							}else if(status=="in-process"){
								//cell_class= "ui-icon ui-icon-notice";
								cell_class= "unknown_val";
								//cell_class= "";
							}
							else if(status=="fail"){
								//cell_class= "ui-icon ui-icon-closethick";
								cell_class= "fail_val";
							}
							else if(status==undefined){
								cell_class= "";
							}
							else{
								cell_class= "";
							}
							//tblBlockSummary+="<td  style=\"text-align:center;\">"+value+"<br>"+value1+"<br>"+value2+"</td>";
							//
							tblBlockSummary+="<td><a onClick=\"createBlockSummaryTrendGraph('"+cell_link+"')\" href=\"javascript:void(0);\" title=\"Last Updated On: "+cell_last_update+"\"><span class=\""+cell_class+"\" ></span></a></td>";
							//tblBlockSummary+="<td  style=\"text-align:center;\"><a onClick=\"createGraph('"+cell_link+"')\">"+status+"</a></td>";
						});		
					});	
					
					
					$.each(arrBlockSummaryGoalNames, function(key1, value1){
							var status_node=$(xmlDocBlockSummary).find("module[name='"+value+"']").find("quality_goals").find("goal[name='"+value1+"']");
							var status=$.trim(status_node.attr("pass_status")).toLowerCase();
							var cell_link=status_node.attr("cell_link");
							var cell_last_update=status_node.attr("date_time");
							var cell_class="";
							if(status=="pass"){
								//cell_class= "ui-icon ui-icon-check";
								cell_class= "pass_val";
							}else if(status=="in-process"){
								//cell_class= "ui-icon ui-icon-notice";
								cell_class= "unknown_val";
								//cell_class= "";
							}
							else if(status=="fail"){
								//cell_class= "ui-icon ui-icon-closethick";
								cell_class= "fail_val";
							}
							else if(status==undefined){
								cell_class= "";
							}
							else{
								cell_class= "";
							}
					 	
						tblBlockSummary+="<td><a onClick=\"createBlockSummaryTrendGraph('"+cell_link+"')\" href=\"javascript:void(0);\" title=\"Last Updated On: "+cell_last_update+"\"><span class=\""+cell_class+"\" ></span></a></td>";
					});
					
					
					
					
					
					var last_updated_on=$(xmlDocBlockSummary).find("module[name='"+value+"']").find("oldest_update").text();		
					tblBlockSummary+="<td>"+last_updated_on+"</td>";
					tblBlockSummary+="</tr>";
			});	
			//creating fourth(onward) row ends here
			
			
			
			
			
			tblBlockSummary+="</table>";
			
			return tblBlockSummary;


}//function createMainBlockTab





function createBlockSummaryTrendGraph(xmlFilePath){
	//xmlFilePath=xmlFilePath.replace(/dashboard_data_files/g,"XML");
	var xmlGraph=XMLToString(getFileContents(xmlFilePath));
	xmlObj=$($.parseXML(xmlGraph));
	
	//alert(xmlFilePath);
	$('#trendChartDiv').remove();
	$('#trendChartGraphDiv').remove();
	$('#trendChartLegendDiv').remove();
	
	var trendChartDiv="<div id=\"trendChartDiv\"  style=\"width:650px;height:450px;border:1px solid #CCCCCC;\"><div id=\"trendChartGraphDiv\" style=\"width:450px;height:350px;float:left\"></div><div id=\"trendChartLegendDiv\" style=\"float:left;border:1px solid #CCCCCC;width:130px;margin-top:100px;\"></div></div>";
	
	$('body').append(trendChartDiv);
	
	var all_trend_lines=Array();
	var all_trend_lines_legend=Array();
	
	if($(xmlObj).find("target_line").length>0){
		
			$(xmlObj).find("target_line").each(function(key, val){
				all_trend_lines_legend.push($(this).attr('goal'));
				var trend_line=Array();
				$(this).find("data_point").each(function(key1, val1){
					trend_line.push(Array($(this).attr('date_time'), parseInt($(this).attr('value'))));
					
					
				});//data point each line
				all_trend_lines.push(trend_line);
			});//$(xmlObj).find("target_line").each(
			
			$(xmlObj).find("actual_line").each(function(key, val){
				//all_trend_lines_legend.push("{label: '"+$(this).attr('goal')+"'}");
				all_trend_lines_legend.push($(this).attr('goal'));
				var trend_line=Array();
				$(this).find("data_point").each(function(key1, val1){
					trend_line.push(Array($(this).attr('date_time'), parseInt($(this).attr('value'))));
					
				});//data point each line
				all_trend_lines.push(trend_line);
			});//$(xmlObj).find("target_line").each(
	}//if($(xmlObj).find("target_line"))
	
	if($(xmlObj).find("severity").length>0){
			
			$(xmlObj).find("severity").each(function(key, val){
				all_trend_lines_legend.push($(this).attr('name'));
				var trend_line=Array();
				$(this).find("data_point").each(function(key1, val1){
					trend_line.push(Array($(this).attr('date_time'), parseInt($(this).attr('value'))));
					
					
				});//data point each line
				all_trend_lines.push(trend_line);
			});
	}
	
			
	//console.log(xmlFilePath);
	//trendChart.destroy();  
	
	var legend_table="<table>";
	$.each(all_trend_lines_legend, function(key, val){
		legend_table+="<tr>";
		legend_table+="<td><div style=\"background-color:"+chart_series_colors[key]+";height:10px; width:10px;\"></div></td>";
		legend_table+="<td style=\"font-size:10px;\">"+val+"</td></tr>";
	});	
	legend_table+="</table>";
	$('#trendChartLegendDiv').append(legend_table);
	
	var trendChart=$.jqplot ('trendChartGraphDiv', all_trend_lines, {
      // Give the plot a title.
      animate: true,
      axesDefaults: {
        labelRenderer: $.jqplot.CanvasAxisLabelRenderer
      },
	  seriesColors: chart_series_colors,
      series:all_trend_lines_legend,
      axes: {
        // options for each axis are specified in seperate option objects.
        xaxis: {
			renderer: $.jqplot.CategoryAxisRenderer,
			tickRenderer: $.jqplot.CanvasAxisTickRenderer,
			
			tickOptions:{
           		fontSize: '8pt', angle: -30
          	}, 
          	label: $(xmlObj).find("xaxis_label").text(),
          	pad: 1.2
        },
        yaxis: {
          label: $(xmlObj).find("yaxis_label").text(),
		  pad: 1.2
        }
      },
	  highlighter: {
        show: true,
        sizeAdjust: 7.5
      },
      cursor: {
        show: false
      },
	   seriesDefaults:{
        linePattern: 'dashed',
        showMarker: true,
        shadow: true
    	}
    });
	
	 	
	$('#trendChartDiv').dialog({
					title: $(xmlObj).find("title").text()+" "+"<a href=\""+xmlFilePath+"\" style=\"font-size:9px;\" target=\"_blank\">Source</a>",
					autoOpen: false,
					width: 650,
					height: 450
					
				});
	
	$('#trendChartDiv').dialog('open');
	
}

function createBlockHeadingSummaryTab(xmlFilePath, tabTitle){
	//xmlFilePath=xmlFilePath.replace(/dashboard_data_files/g,"XML");
	var xmlGraph=XMLToString(getFileContents(xmlFilePath));
	xmlObj=$($.parseXML(xmlGraph));
	//alert(xmlFilePath);
	var tab_id="#tabs-" + tabTitle.replace(/ /g,"_").replace(/\(/g,"").replace(/\)/g,"_");
	
	//this below code will check if the tab is not opened, if it is opened already, it will just select it
	if($(tab_id).length>0) {	
		var index = $('#tabs a[href="'+tab_id+'"]').parent().index();
		$("#tabs").tabs("select", index);
	}else{
		$('#tabs').tabs( "add", tab_id , tabTitle);
	}
	//this above code will check if the tab is not opened, if it is opened already, it will just select it
	
	
	var tabContent="";
	tabContent+="<img src=\"img/spyglass_logo_white.jpg\"  style=\"margin-right:30px; float:left;\" alt=\"SpyGlass Logo\">";
	tabContent+="<h3 class=\"ui-header\">"+tabTitle+"</h3>";
	tabContent+="<span class=\"ui-text\">Source: <a href=\""+xmlFilePath+"\" target=\"_blank\">"+xmlFilePath+"</a></span><br><br><br>";
	
	tabContent+="<table class=\"dataTable1\" style=\"font-size:9px;width:100%\">";
	tabContent+="<tr>";
	tabContent+="<th>Module</th>";
	tabContent+="<th>Description(Tool Tip)</th>";
	tabContent+="<th>Run Status</th>";
	tabContent+="<th>Success Criteria</th>";
	tabContent+="<th>Pass/Fail Status</th>";	
	tabContent+="</tr>";
	
	
	$(xmlObj).find("module").each(function(key, val){
		
		//each category
		var module_name=$(this).attr('name');
		var module_link=$(this).attr('link');
		$(this).find("item").each(function(key1, val1){
					
					var status=$.trim($(this).attr('pass_status')).toLowerCase();
					var cell_class="";
					if(status=="pass"){
						//cell_class= "ui-icon ui-icon-check";
						cell_class= "pass_val";
					}else if(status=="In-process"){
						//cell_class= "ui-icon ui-icon-notice";
						cell_class= "unknown_val";
					}
					else if(status=="fail"){
						//cell_class= "ui-icon ui-icon-closethick";
						cell_class= "fail_val";
					}
					else{
						cell_class= "";
					}
					
					var temp_child_item_class=module_name+"_childitem_"+key1;
					if(($(this).find("child_item").length)>0)
					{
							tabContent+="<tr>";
							tabContent+="<td><a onClick=\"createBlockSummaryTab('dashboard_data_files/DashBoard_Main.xml', '"+module_name+"')\" href=\"javascript:void(0);\" title=\"Open Dashboard for: "+module_name+"\">"+module_name+"</a></td>";
							tabContent+="<td><a class=\"ui-icon ui-icon-minus\" style=\"border:1px solid #CCCCCC; float:left;\" onclick=\"javascript:toggleHeadingTableRows('"+temp_child_item_class+"',  this)\"></a>&nbsp;<strong>"+$(this).attr('run_status')+"</strong></td>";
							tabContent+="<td><strong>"+$(this).attr('name')+"</strong></td>";
							tabContent+="<td><strong>"+$(this).attr('success_criteria')+"</strong></td>";
							var status=$.trim($(this).attr('pass_status')).toLowerCase();
							tabContent+="<td><a onClick=\"createBlockSummaryTrendGraph('"+$(this).attr('graph')+"')\" href=\"javascript:void(0);\" title=\""+$(this).attr('tooltip')+"\"><span class=\""+cell_class+"\" >&nbsp;</span></a></td>";
							tabContent+="</tr>";	
							
							$(this).find("child_item").each(function()
							{
									tabContent+="<tr class=\""+temp_child_item_class+"\">";
									tabContent+="<td><a onClick=\"createBlockSummaryTab('dashboard_data_files/DashBoard_Main.xml', '"+module_name+"')\" href=\"javascript:void(0);\" title=\"Open Dashboard for: "+module_name+"\">"+module_name+"<//a></td>";
									tabContent+="<td>"+$(this).attr('run_status')+"</td>";
									tabContent+="<td>"+$(this).attr('name')+"</td>";
									tabContent+="<td>"+$(this).attr('success_criteria')+"</td>";
									tabContent+="<td><a onClick=\"createBlockSummaryTrendGraph('"+$(this).attr('graph')+"')\" href=\"javascript:void(0);\" title=\""+$(this).attr('tooltip')+"\"><span class=\""+cell_class+"\" >&nbsp;</span></a></td>";
									tabContent+="</tr>";
							});
					
					}//if td has child values...
					
					else
					{
							tabContent+="<tr>";
							tabContent+="<td><a onClick=\"createBlockSummaryTab('dashboard_data_files/DashBoard_Main.xml', '"+module_name+"')\" href=\"javascript:void(0);\" title=\"Open Dashboard for: "+module_name+"\">"+module_name+"<//a></td>";
							tabContent+="<td>"+$(this).attr('run_status')+"</td>";
							tabContent+="<td>"+$(this).attr('name')+"</td>";
							tabContent+="<td>"+$(this).attr('success_criteria')+"</td>";
							tabContent+="<td><a onClick=\"createBlockSummaryTrendGraph('"+$(this).attr('graph')+"')\" href=\"javascript:void(0);\" title=\""+$(this).attr('tooltip')+"\"><span class=\""+cell_class+"\" >&nbsp;</span></a></td>";
							tabContent+="</tr>";
					}//if td doesnt have child values...
					
					
						
					
					
					
					
		
		
		
		});
		//foreach design_data-> category->items
	});
	//foreach $(xmlObj).find("module[name='"+tabTitle+"']").find("design_data").each
	//design objective table ends creating here
	
	tabContent+="</table>";
	$(tab_id).html(tabContent);
	
}//createBlockHeadingSummaryTab


function createBlockHeadingGoalSummaryTab(xmlFilePath, tabTitle){
	//xmlFilePath=xmlFilePath.replace(/dashboard_data_files/g,"XML");
	var xmlGraph=XMLToString(getFileContents(xmlFilePath));
	
	xmlObj=$($.parseXML(xmlGraph));
	//alert(xmlFilePath);
	var tab_id="#tabs-" + tabTitle.replace(/ /g,"_").replace(/\(/g,"").replace(/\)/g,"_").replace(/\//g,"_");
	
	//this below code will check if the tab is not opened, if it is opened already, it will just select it
	if($(tab_id).length>0) {	
		var index = $('#tabs a[href="'+tab_id+'"]').parent().index();
		$("#tabs").tabs("select", index);
	}else{
		$('#tabs').tabs( "add", tab_id , tabTitle);
	}
	//this above code will check if the tab is not opened, if it is opened already, it will just select it
	
	
	
	var tabContent="";
	tabContent+="<img src=\"img/spyglass_logo_white.jpg\"  style=\"margin-right:30px; float:left;\" alt=\"SpyGlass Logo\">";
	tabContent+="<h3 class=\"ui-header\">"+tabTitle+"</h3>";
	tabContent+="<span class=\"ui-text\">Source: <a href=\""+xmlFilePath+"\" target=\"_blank\">"+xmlFilePath+"</a></span><br><br><br>";
	
	
	
	//goal summary table starts creating here
	tabContent+="<table class=\"dataTable1\" style=\"font-size:9px;width:100%\">";
	tabContent+="<tr>";
	tabContent+="<th rowspan=\"2\">Module Name</th>";
	tabContent+="<th rowspan=\"2\">Quality Goals</th>";
	tabContent+="<th>&nbsp;</th>";
	tabContent+="<th colspan=\"3\"  style=\"text-align:center\">Unresolved</th>";
	tabContent+="<th colspan=\"2\" style=\"text-align:center\">Waived</th>";
	tabContent+="<th>&nbsp;</th>";
	tabContent+="<th>&nbsp;</th>";
	tabContent+="</tr>";
	
	tabContent+="<tr>";
	tabContent+="<th>Run Status</th>";
	tabContent+="<th>Fatal</th>";
	tabContent+="<th>Error</th>";
	tabContent+="<th>Warning</th>";	
	tabContent+="<th>Error</th>";
	tabContent+="<th>Warning</th>";	
	tabContent+="<th>Success Criterea</th>";
	tabContent+="<th>Pass/Fail Status</th>";	
	tabContent+="</tr>";
	
	
	$(xmlObj).find("module").each(function(key, val){
		var module_name=$(this).attr('name');
		var module_link=$(this).attr('link');
		$(this).find("goal").each(function(key1, val1){
					tabContent+="<tr>";
					tabContent+="<td>"+module_name+"</td>";
					tabContent+="<td><a href=\"javascript:void(0);\" onclick=\"createIframeReport('"+$(this).attr('link')+"', '"+$(this).attr('name')+"', '"+$(this).attr('name')+"')\">"+$(this).attr('name')+"</a></td>";
					tabContent+="<td>"+$(this).attr('run_status')+"</td>";
					tabContent+="<td>"+$(this).attr('fatal')+"</td>";
					tabContent+="<td>"+$(this).attr('error')+"</td>";
					tabContent+="<td>"+$(this).attr('warning')+"</td>";
					tabContent+="<td>"+$(this).attr('waived-error')+"</td>";
					tabContent+="<td>"+$(this).attr('waived-warning')+"</td>";
					tabContent+="<td>"+$(this).attr('success_criteria')+"</td>";
					var pass_status=$.trim($(this).attr('pass_status')).toLowerCase();
			;
					if(pass_status=="pass"){
						//cell_class= "ui-icon ui-icon-check";
						cell_class= "pass_val";
					}else if(pass_status=="in-process"){
						//cell_class= "ui-icon ui-icon-notice";
						cell_class= "unknown_val";
					}
					else if(pass_status=="fail"){
						//cell_class= "ui-icon ui-icon-closethick";
						cell_class= "fail_val";
					}
					else{
						cell_class= "";
					}
					tabContent+="<td><a onClick=\"createBlockSummaryTrendGraph('"+$(this).attr('graph')+"')\" href=\"javascript:void(0);\"><span class=\""+cell_class+"\" >&nbsp;</span></a></td>";
					
					tabContent+="</tr>";
		});//foreach design_data-> category->items
	});//$(xmlObj).find("module").each(function(key, val){
	
	/*
	tabContent+="<tr>";
	tabContent+="<th>"+$(xmlObj).find("module[name='"+tabTitle+"']").find("quality_data").find("summary").attr("name")+"</th>";
	tabContent+="<th>"+$(xmlObj).find("module[name='"+tabTitle+"']").find("quality_data").find("summary").attr("run_status")+"</th>";
	tabContent+="<th>"+$(xmlObj).find("module[name='"+tabTitle+"']").find("quality_data").find("summary").attr("fatal")+"</th>";
	tabContent+="<th>"+$(xmlObj).find("module[name='"+tabTitle+"']").find("quality_data").find("summary").attr("error")+"</th>";
	tabContent+="<th>"+$(xmlObj).find("module[name='"+tabTitle+"']").find("quality_data").find("summary").attr("warning")+"</th>";
	tabContent+="<th>"+$(xmlObj).find("module[name='"+tabTitle+"']").find("quality_data").find("summary").attr("waived-error")+"</th>";
	tabContent+="<th>"+$(xmlObj).find("module[name='"+tabTitle+"']").find("quality_data").find("summary").attr("waived-warning")+"</th>";
	tabContent+="<th>"+$(xmlObj).find("module[name='"+tabTitle+"']").find("quality_data").find("summary").attr("success_criteria")+"</th>";
	tabContent+="<th>"+$(xmlObj).find("module[name='"+tabTitle+"']").find("quality_data").find("summary").attr("pass_status")+"</th>";	
	tabContent+="</tr>";
	*/
	
	tabContent+="</table>";
	
	$(tab_id).html(tabContent);
}//createBlockHeadingGoalSummaryTab







function createBlockSummaryTab(xmlFilePath, tabTitle){
	//xmlFilePath=xmlFilePath.replace(/dashboard_data_files/g,"XML");
	var xmlGraph=XMLToString(getFileContents(xmlFilePath));
	xmlObj=$($.parseXML(xmlGraph));
	//alert(xmlGraph);
	var tab_id="#tabs-" + tabTitle;
	
	//this below code will check if the tab is not opened, if it is opened already, it will just select it
	if($(tab_id).length>0) {	
		var index = $('#tabs a[href="'+tab_id+'"]').parent().index();
		$("#tabs").tabs("select", index);
	}else{
		$('#tabs').tabs( "add", tab_id , tabTitle);
	}
	//this above code will check if the tab is not opened, if it is opened already, it will just select it
	
	var tabContent="";
	tabContent+="<img src=\"img/spyglass_logo_white.jpg\"  style=\"margin-right:30px; float:left;\" alt=\"SpyGlass Logo\">";
	tabContent+="<h3 class=\"ui-header\">"+$(xmlObj).find("title").text()+"</h3>";
	tabContent+="<span class=\"ui-text\">"+$(xmlObj).find("label").text()+"</span><br><br>";
	
	//design objective table starts creating here
	tabContent+="<table class=\"dataTable1\" style=\"font-size:9px;width:100%\">";
	tabContent+="<tr>";
	tabContent+="<th>Category</th>";
	tabContent+="<th>Run Status</th>";
	tabContent+="<th>Design Objective</th>";
	tabContent+="<th>Success Criteria</th>";
	tabContent+="<th>Pass/Fail Status</th>";	
	tabContent+="</tr>";
	
	
	$(xmlObj).find("module[name='"+tabTitle+"']").find("design_data").find("category").each(function(){
		//each category
		
		var num_items=$(this).find("item").length;
		num_items+=$(this).find("item").find("child_item").length;
		
		var category_name=$(this).attr('name');
		$(this).find("item").each(function(key, value){
			var status=$.trim($(this).attr('pass_status')).toLowerCase();
			var cell_class="";
			if(status=="pass"){	cell_class= "pass_val";		}
			else if(status=="In-process"){	cell_class= "unknown_val";	}
			else if(status=="fail"){	cell_class= "fail_val";}
			else{	cell_class= "";}
			
			var temp_parent_td_id="td_"+category_name+"_category";
			
			if(($(this).find("child_item").length)>0)
			{
				var temp_child_item_class=category_name+"_childitem_"+key;
				
				var temp_child_item_count=$(this).find("child_item").length;
				//alert(temp_child_item_class);
				
				tabContent+="<tr>";
				if(key==0)
				{
					tabContent+="<td rowspan=\""+num_items+"\" id=\""+temp_parent_td_id+"\">"+category_name+"</td>";	
				}
				
				tabContent+="<td><a class=\"ui-icon ui-icon-minus\" style=\"border:1px solid #CCCCCC; float:left;\" onclick=\"javascript:toggleTableRows('"+temp_child_item_class+"', '"+temp_parent_td_id+"', '"+temp_child_item_count+"', this)\"></a>&nbsp;<strong>"+$(this).attr('run_status')+"</strong></td>";
				tabContent+="<td><strong>"+$(this).attr('name')+"</strong></td>";
				tabContent+="<td><strong>"+$(this).attr('success_criteria')+"</strong></td>";
				tabContent+="<td><a onClick=\"createBlockSummaryTrendGraph('"+$(this).attr('graph')+"')\" href=\"javascript:void(0);\" title=\""+$(this).attr('tooltip')+"\"><span class=\""+cell_class+"\" >&nbsp;</span></a></td>";
				tabContent+="</tr>";
				
				$(this).find("child_item").each(function(){
					var status=$.trim($(this).attr('pass_status')).toLowerCase();
					var cell_class="";
					if(status=="pass"){	cell_class= "pass_val";		}
					else if(status=="In-process"){	cell_class= "unknown_val";	}
					else if(status=="fail"){	cell_class= "fail_val";}
					else{	cell_class= "";}
					//alert(temp_child_item_class);
					tabContent+="<tr class=\""+temp_child_item_class+"\">";
					tabContent+="<td>"+$(this).attr('run_status')+"</td>";
					tabContent+="<td>"+$(this).attr('name')+"</td>";
					tabContent+="<td>"+$(this).attr('success_criteria')+"</td>";
					tabContent+="<td><a onClick=\"createBlockSummaryTrendGraph('"+$(this).attr('graph')+"')\" href=\"javascript:void(0);\" title=\""+$(this).attr('tooltip')+"\"><span class=\""+cell_class+"\" >&nbsp;</span></a></td>";
					tabContent+="</tr>";
				});
				
					
			}//if td has child values...
			else{
				tabContent+="<tr>";
				if(key==0){
					tabContent+="<td rowspan=\""+num_items+"\"  id=\""+temp_parent_td_id+"\">"+category_name+"</td>";	
				}
				
				tabContent+="<td>"+$(this).attr('run_status')+"</td>";
				tabContent+="<td>"+$(this).attr('name')+"</td>";
				tabContent+="<td>"+$(this).attr('success_criteria')+"</td>";
				tabContent+="<td><a onClick=\"createBlockSummaryTrendGraph('"+$(this).attr('graph')+"')\" href=\"javascript:void(0);\" title=\""+$(this).attr('tooltip')+"\"><span class=\""+cell_class+"\" >&nbsp;</span></a></td>";
				tabContent+="</tr>";
			}//if td doesnt have child values...
			
			
				
			
			
		});
		
		//foreach design_data-> category->items
	});
	//foreach $(xmlObj).find("module[name='"+tabTitle+"']").find("design_data").each
	//design objective table ends creating here
	tabContent+="<tr>";
	tabContent+="<th>"+$(xmlObj).find("module[name='"+tabTitle+"']").find("design_data").find("summary").attr("name")+"</th>";
	tabContent+="<th>"+$(xmlObj).find("module[name='"+tabTitle+"']").find("design_data").find("summary").attr("run_status")+"</th>";
	tabContent+="<th>&nbsp;</th>";
	tabContent+="<th>"+$(xmlObj).find("module[name='"+tabTitle+"']").find("design_data").find("summary").attr("success_criteria")+"</th>";
	tabContent+="<th>"+$(xmlObj).find("module[name='"+tabTitle+"']").find("design_data").find("summary").attr("pass_status")+"</th>";	
	tabContent+="</tr>";
	tabContent+="</table>";
	
	//design objective table ends creating here
	
	//alert(tabContent);
	
	tabContent+="<br><br>";
	
	
	
	
	
	
	//goal summary table starts creating here
	tabContent+="<table class=\"dataTable1\" style=\"font-size:9px;width:100%\">";
	tabContent+="<tr>";
	tabContent+="<th rowspan=\"2\">Quality Goals</th>";
	tabContent+="<th>&nbsp;</th>";
	tabContent+="<th colspan=\"3\"  style=\"text-align:center\">Unresolved</th>";
	tabContent+="<th colspan=\"2\" style=\"text-align:center\">Waived</th>";
	tabContent+="<th>&nbsp;</th>";
	tabContent+="<th>&nbsp;</th>";
	tabContent+="</tr>";
	
	tabContent+="<tr>";
	tabContent+="<th>Run Status</th>";
	tabContent+="<th>Fatal</th>";
	tabContent+="<th>Error</th>";
	tabContent+="<th>Warning</th>";	
	tabContent+="<th>Error</th>";
	tabContent+="<th>Warning</th>";	
	tabContent+="<th>Success Criterea</th>";
	tabContent+="<th>Pass/Fail Status</th>";	
	tabContent+="</tr>";
	
	
	$(xmlObj).find("module[name='"+tabTitle+"']").find("quality_data").find("goal").each(function(){
		//each category
		tabContent+="<tr>";
		tabContent+="<td><a href=\"javascript:void(0);\" onclick=\"createIframeReport('"+$(this).attr('link')+"', '"+tabTitle+"', '"+$(this).attr('name')+"')\">"+$(this).attr('name')+"</a></td>";
		tabContent+="<td>"+$(this).attr('run_status')+"</td>";
		tabContent+="<td>"+$(this).attr('fatal')+"</td>";
		tabContent+="<td>"+$(this).attr('error')+"</td>";
		tabContent+="<td>"+$(this).attr('warning')+"</td>";
		tabContent+="<td>"+$(this).attr('waived-error')+"</td>";
		tabContent+="<td>"+$(this).attr('waived-warning')+"</td>";
		tabContent+="<td>"+$(this).attr('success_criteria')+"</td>";
		var pass_status=$.trim($(this).attr('pass_status')).toLowerCase();
;
		if(pass_status=="pass"){
			//cell_class= "ui-icon ui-icon-check";
			cell_class= "pass_val";
		}else if(pass_status=="in-process"){
			//cell_class= "ui-icon ui-icon-notice";
			cell_class= "unknown_val";
		}
		else if(pass_status=="fail"){
			//cell_class= "ui-icon ui-icon-closethick";
			cell_class= "fail_val";
		}
		else{
			cell_class= "";
		}
		tabContent+="<td><a onClick=\"createBlockSummaryTrendGraph('"+$(this).attr('graph')+"')\" href=\"javascript:void(0);\"><span class=\""+cell_class+"\" >&nbsp;</span></a></td>";
		
		tabContent+="</tr>";			
		//foreach design_data-> category->items
	});
	//foreach $(xmlObj).find("module[name='"+tabTitle+"']").find("design_data").each
	
	tabContent+="<tr>";
	tabContent+="<th>"+$(xmlObj).find("module[name='"+tabTitle+"']").find("quality_data").find("summary").attr("name")+"</th>";
	tabContent+="<th>"+$(xmlObj).find("module[name='"+tabTitle+"']").find("quality_data").find("summary").attr("run_status")+"</th>";
	tabContent+="<th>"+$(xmlObj).find("module[name='"+tabTitle+"']").find("quality_data").find("summary").attr("fatal")+"</th>";
	tabContent+="<th>"+$(xmlObj).find("module[name='"+tabTitle+"']").find("quality_data").find("summary").attr("error")+"</th>";
	tabContent+="<th>"+$(xmlObj).find("module[name='"+tabTitle+"']").find("quality_data").find("summary").attr("warning")+"</th>";
	tabContent+="<th>"+$(xmlObj).find("module[name='"+tabTitle+"']").find("quality_data").find("summary").attr("waived-error")+"</th>";
	tabContent+="<th>"+$(xmlObj).find("module[name='"+tabTitle+"']").find("quality_data").find("summary").attr("waived-warning")+"</th>";
	tabContent+="<th>"+$(xmlObj).find("module[name='"+tabTitle+"']").find("quality_data").find("summary").attr("success_criteria")+"</th>";
	tabContent+="<th>"+$(xmlObj).find("module[name='"+tabTitle+"']").find("quality_data").find("summary").attr("pass_status")+"</th>";	
	tabContent+="</tr>";
	tabContent+="</table>";
	
	
	
	
	
	//goal summary  table ends creating here
	
	
	
	
	
	//alert(tabContent);
	//var tabContent=
	$(tab_id).html(tabContent);
	
	
}






//////////////////////////////////////////////////
/* function ENDS for DB_BLOCK_SUMMARY.XML		*/
//////////////////////////////////////////////////



function createIframeReport(xmlFilePath, moduleName, goalName){
	//xmlFilePath=xmlFilePath.replace(/dashboard_data_files/g,"XML");
	var xmlGraph=XMLToString(getFileContents(xmlFilePath));
	xmlObj=$($.parseXML(xmlGraph));
	$('#iFrameReportDiv').remove();
	var iFrameReportDiv="<div id=\"iFrameReportDiv\">";
	iFrameReportDiv+="<div><strong>Module:</strong> "+$(xmlObj).find("module").attr("name")+"&nbsp;&nbsp;";
	iFrameReportDiv+="<strong>Goal Name: </strong>"+$(xmlObj).find("goal").attr("name")+"</div>";
	$(xmlObj).find("report").each(function(){
		iFrameReportDiv+="<a href=\""+$(this).attr("link")+"\" target=\"iframeReport\" class=\"linkBtn1\">"+$(this).attr("name")+" Report</a>&nbsp;&nbsp;";		
	});
	
	iFrameReportDiv+="<iframe style=\"height:85%;width:100%; border:0px;border-top:1px dotted #CCCCCC;margin-top:3px;\" id=\"iframeReport\" name=\"iframeReport\">";
	iFrameReportDiv+="</div>";
	$('body').append(iFrameReportDiv);
	//$().src=
	
	//alert($(xmlObj).find('report').eq(0).attr("link"));
	$("#iframeReport").attr("src", $(xmlObj).find('report').eq(0).attr("link"));
	
		$('#iFrameReportDiv').dialog({
					title: "Report for "+moduleName+" - "+goalName+" <a href=\""+xmlFilePath+"\" style=\"font-size:9px;\" target=\"_blank\">Source</a>",
					autoOpen: false,
					width: $(window).width()-50,
					height: $(window).height()-50
					
				});
	
	$('#iFrameReportDiv').dialog('open');
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
