// JavaScript Document





/*
function getMainBlockSummaryTable(){

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
			tblBlockSummary+="<thead>";
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
					tblBlockSummary+="<th  style=\"text-align:center;\"><a onclick=\"createBlockHeadingSummaryTab('"+tmp_header_xml_link+"', '"+value+" - "+value1+"')\" href=\"javascript:void(0);\" title=\""+value+" - "+value1+"\">"+updateBlockSummaryTitle(value1)+"</a></th>";
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
			tblBlockSummary+="</thead>";
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
							var cell_class=getCellClassFromStatus(status);
							
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
							
							var cell_class=getCellClassFromStatus(status);
							
							tblBlockSummary+="<td class=\""+cell_class+"\"><a onClick=\"createBlockSummaryTrendGraph('"+cell_link+"')\" href=\"javascript:void(0);\" title=\"Last Updated On: "+cell_last_update+"\">"+status+"</a></td>";
					});
					
					
					
					
					
					var last_updated_on=$(xmlDocBlockSummary).find("module[name='"+value+"']").find("oldest_update").text();		
					tblBlockSummary+="<td style=\"white-space:nowrap;\">"+last_updated_on+"</td>";
					tblBlockSummary+="</tr>";
			});	
			//creating fourth(onward) row ends here
			
			
			
			
			
			tblBlockSummary+="</table>";
			
			return tblBlockSummary;



}//function getMainBlockSummaryTable
*/
