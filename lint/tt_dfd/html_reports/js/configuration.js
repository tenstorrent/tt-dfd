// JavaScript Document

	
	var curBrowserName=getBrowser();
	var curBrowserVersion=getBrowserVersion();
	var curBrowserFullVersion=getBrowserFullVersion();
	var curScreenWidth=$(window).width();
	var curScreenHeight=$(window).height();
	
	var jsDir="js";
	var xmlDir="dashboard_data_files";	
	
	var failColor="#F41403";
	var ipColor="#FDF400";
	var passColor="#008106";
	var fipColors=new Array(failColor, ipColor, passColor);
	
	var seriesColors=new Array("#008106", "#FDF400", "#F41403", "#409DB8", "#AE40B8", "#B8A340");
	//var severityColors=new Array("#FF33CC", "#FF0000", "#FF9900", "#64389A", "#FFFF00", "#6794CA");
	var productColors=new Array("#FF00D8", "#00C0FF", "#00FF0C", "#FF8400", "#D2FF00");
	var isBrowserIncompatible=false;
	
	var arrLogErrors=new Array();
	
	
	var tmp_all_filters=Array("Show All", "Pass", "Fail");
	
	var all_unresolved_severity=Array("fatal","error","warning","info");
	var all_waived_severity=Array("waived-error","waived-warning","waived-info");
	
	var active_unresolved_severity=Array();
	var active_waived_severity=Array();
	
	var flag_debug=false;
	
	var run_link=false;