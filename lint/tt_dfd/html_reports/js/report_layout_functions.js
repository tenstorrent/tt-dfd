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
	var tmpHeaderStr="<div id=\"mainHeader\"><table style=\"width:100%;\"><tr><td style=\"width:40%\"><img src=\"img/atrenta_web_logo_alpha_png.png\" alt=\"SpyGlass Logo\" id=\"mainHeaderLogo\"><div id=\"mainHeaderTitleLeft\" style=\"font-size:18px;\">SpyGlass Reports</div><br><div id=\"mainHeaderDescription\" style=\"font-size:14px;font-weight:bold;line-height:30px;\">Please Wait...</div></td><td style=\"width:40%;color:#FFFFFF;font-family:arial;\"><!--Change Goal: <select id=\"selGoalNames\"></select>--></td><td style=\"width:20%\"><img  alt=\"\" id=\"imgCustomerLogo\"></td></tr></table></div>";
	//alert(tmpHeaderStr);
	$('#'+theDiv).html(tmpHeaderStr);
}
function drawMainHeaderWithSelectBox(theDiv){
	var tmpHeaderStr="<div id=\"mainHeader\"><table style=\"width:100%;\"><tr><td style=\"width:40%\"><img src=\"img/atrenta_web_logo_alpha_png.png\" alt=\"SpyGlass Logo\" id=\"mainHeaderLogo\"><div id=\"mainHeaderTitleLeft\" style=\"font-size:18px;\">SpyGlass Reports</div><br><div id=\"mainHeaderDescription\" style=\"font-size:14px;font-weight:bold;line-height:30px;\">Please Wait...</div></td><td style=\"width:40%;color:#FFFFFF;font-family:arial;\">Change Goal: <select id=\"selGoalNames\"></select></td><td style=\"width:20%\"><img  alt=\"\" id=\"imgCustomerLogo\"></td></tr></table></div>";
	//alert(tmpHeaderStr);
	$('#'+theDiv).html(tmpHeaderStr);
}

function updateMainHeaderDescription(theText){
	$("#mainHeaderDescription").html(theText);
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
