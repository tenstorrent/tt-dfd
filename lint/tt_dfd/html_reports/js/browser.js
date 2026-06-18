		// JavaScript Document

		var nVer100 = navigator.appVersion;
		var nAgt100 = navigator.userAgent;
		var browserName100  = navigator.appName;
		var fullVersion100  = ''+parseFloat(navigator.appVersion); 
		var majorVersion100 = parseInt(navigator.appVersion,10);
		var nameOffset100,verOffset100,ix100;
		
		if ((verOffset100=nAgt100.indexOf("Opera"))!=-1)
		{
			browserName100 = "OP";
			fullVersion100 = nAgt100.substring(verOffset100+6);
			if ((verOffset100=nAgt100.indexOf("Version"))!=-1) 
			{
				fullVersion100 = nAgt100.substring(verOffset100+8);
			}
		}
		// In MSIE, the true version is after "MSIE" in userAgent
		else if ((verOffset100=nAgt100.indexOf("MSIE"))!=-1) 
		{
			browserName100 = "IE";
			fullVersion100 = nAgt100.substring(verOffset100+5);
		}
		// In Chrome, the true version is after "Chrome" 
		else if ((verOffset100=nAgt100.indexOf("Chrome"))!=-1) 
		{
			browserName100 = "CH";
			fullVersion100 = nAgt100.substring(verOffset100+7);
		}
		
		else if ((verOffset100=nAgt100.indexOf("Safari"))!=-1) 
		{
			browserName100 = "SA";
			fullVersion100 = nAgt100.substring(verOffset100+7);
			if ((verOffset100=nAgt100.indexOf("Version"))!=-1)
			{ 
				fullVersion100 = nAgt100.substring(verOffset100+8);
			}
		}// In Safari, the true version is after "Safari" or after "Version" 
		
		else if ((verOffset100=nAgt100.indexOf("Firefox"))!=-1) {
			browserName100 = "FF";
			fullVersion100 = nAgt100.substring(verOffset100+8);
		}// In Firefox, the true version is after "Firefox" 
		
		
		// In most other browsers, "name/version" is at the end of userAgent 
		else if ( (nameOffset100=nAgt100.lastIndexOf(' ')+1) < (verOffset100=nAgt100.lastIndexOf('/')) ) 
		{
			browserName100 = nAgt100.substring(nameOffset100,verOffset100);
			fullVersion100 = nAgt.substring(verOffset100+1);
			if (browserName100.toLowerCase()==browserName100.toUpperCase()) {
		  		browserName100 = navigator.appName;
		 	}
		}
		// trim the fullVersion string at semicolon/space if present
		if ((ix100=fullVersion100.indexOf(";"))!=-1)
			fullVersion100=fullVersion100.substring(0,ix100);
		if ((ix100=fullVersion100.indexOf(" "))!=-1)
			fullVersion100=fullVersion100.substring(0,ix100);
		
		majorVersion100 = parseInt(''+fullVersion100,10);
		if (isNaN(majorVersion100)) 
		{
			fullVersion100  = ''+parseFloat(navigator.appVersion); 
			majorVersion100 = parseInt(navigator.appVersion,10);
		}




		function getBrowser()
		{
			return browserName100;
		}
		
		function getBrowserVersion()
		{
			return majorVersion100;
		}
		
		function getBrowserFullVersion()
		{
			return fullVersion100;
		}
		
		