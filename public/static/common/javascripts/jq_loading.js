LoadingSpinner = {
	setup: function(){
		if(window["loading spinner"] == undefined)
		{
			window["loading spinner"] = 0;
		}
	},
	start: function(){
		// console.log("start spinner");
		// console.trace();
		this.setup();
		this.callStartCallback();
		window["loading spinner"]++;	
		// console.log("started" + window["loading spinner"]);
	},
	stop: function(){
		// console.log("stop spinner");
		// console.trace();
		this.setup();
		if(this.isLoading())
		{
			window["loading spinner"]--;	
		}
		// console.log("stopped" + window["loading spinner"]);
		if(!this.isLoading())
		{
			// console.log("call stop");
			this.callStopCallback();
		}
	},
	setStartCallback: function(arg){
		window["loading spinner start callback"] = arg;
	},
	setStopCallback: function(arg){
		window["loading spinner stop callback"] = arg;		
	},
	callStartCallback: function(){
		if(window["loading spinner start callback"])
		{
			window["loading spinner start callback"]();
		}
	},
	callStopCallback: function(){
		if(window["loading spinner stop callback"])
		{
			window["loading spinner stop callback"]();
		}
	},
	isLoading: function(){
		this.setup();
		return window["loading spinner"] > 0;
	}
};

// NOTE : this takes care of all the places we use prototype.js for AJAX calls and showing/hiding the "Loading ..." indicator
Ajax.Responders.register({
	onCreate: function() {
		LoadingSpinner.start();
		update_notice_flash("");
		update_error_flash(""); 
	},
	onComplete: function() {
		LoadingSpinner.stop();
	}
});

// NOTE : this takes care of all the places we use the YUI for AJAX calls and showing/hiding the "Loading ..." indicator
if( window["YAHOO"] && YAHOO.util.Connect.createXhrObject ){
	var start_event = function(){
		LoadingSpinner.start();
	}
	var complete_event = function(){
		LoadingSpinner.stop();
	}
	
	YAHOO.util.Connect.startEvent.subscribe(start_event); 
	YAHOO.util.Connect.completeEvent.subscribe(complete_event); 
	// YAHOO.util.Connect.successEvent.subscribe(globalEvents.success); 
	// YAHOO.util.Connect.failureEvent.subscribe(globalEvents.failure); 
  YAHOO.util.Connect.abortEvent.subscribe(complete_event);
}

if(jQuery){
  jQuery().ajaxStart(function(){
		update_notice_flash("");
		update_error_flash(""); 
  	LoadingSpinner.start();
  });
  jQuery().ajaxStop(function(){
  	LoadingSpinner.stop();
  });  
}
