/** forGL_Load_Run.js   This runs in Browser to support forGL with a HTML GUI
 *
 * @author Randy Maxwell
 */

(function() {
	
	var is_running = false;
	
	var oscpu = window.navigator.oscpu;
//	console.log( "oscpu :" + oscpu );
	
	var verbose_console_log = true;
	
// Set up to use various UI pieces
	var dict_name_element = document.getElementById( "dictionaryNameId" );
	var dict_text_element = document.getElementById( "dictionaryTextId" );
	
	var status_text_element = document.getElementById( "statusId" );
	
	var run_stop_button = document.getElementById( "runButtonId" );
	var user_verb_element = document.getElementById( "userVerbId" );
	
	var verb_colored_element = document.getElementById( "verbColoredTokensId" );
	
	var data_stack_element = document.getElementById( "dataStackId" );
	var op_stack_element   = document.getElementById( "opStackId" );
	var noun_stack_element = document.getElementById( "nounStackId" );
	
	var verb_output_element = document.getElementById( "verbOutputId" );
	
	var messages_element = document.getElementById( "messagesId" );

	var forGL_Worker = document.HTMLElement;
	
	// Create a Web Worker (separate thread from Browser)
	var using_web_worker = false;
	if ( window.Worker )
	{
		forGL_Worker = new Worker( 'forGL_WebWorker.js' );
		using_web_worker = true;
		alert( "using_web_worker !" );
	}
	else
	{
		// Change this to load forGL as JavaScript (but not a Web Worker)
		// 
		
		var msg = 'INTERNAL ERROR: No Web Worker from Browser available. Need to refactor forGL. Stopping.';
		status_text_element.textContent = msg;
		console.log( msg );
		alert( msg );
		document.close();
		return;
	}
	
	if ( verbose_console_log )
	{
		// Set the Check Box 
		
		
	}
	
	var sendRequest = function( request_str, data_str )
	{
		if ( using_web_worker )
		{
			// Send Request and other Data as Array of 2 Strings
			forGL_Worker.postMessage( [ request_str, data_str ] );
		}
		else
		{
			// Put the Request into the queue
			
		}
		
		if ( verbose_console_log )
		{
			var log_msg = 'Message to forGL: '+ request_str + ' data: ' + data_str;
			console.log( log_msg );
		}
	};
	
	
	var msg_result = '';
	var msg_data = '';
	
	forGL_Worker.onmessage = function( msg_back ) 
	{
		msg_result = msg_back.data[ 0 ];
		msg_data   = msg_back.data[ 1 ];
	/*
		if ( verbose_console_log )
		{
			var log_msg = 'forGL Result: '+ msg_result + ' Data: ' + msg_data;
			console.log( log_msg );
		}
	*/
		
		// Save message details as needed into appropriate variables
		switch ( msg_result )
		{
			case "data_stack":
				data_stack_element.textContent = msg_data;
				break;
				
			case "error":
				messages_element.textContent += msg_data;
				status_text_element.textContent = msg_data;
				alert( msg_data );
				break;
			
			case "information":
				messages_element.textContent += msg_data;
				break;
				
			case "message":
				messages_element.textContent += msg_data;
				break;
				
			case "noun_stack":
				noun_stack_element.textContent = msg_data;
				break;
				
			case "op_stack":
				op_stack_element.textContent = msg_data;
				break;
			
			case "status":
				status_text_element.textContent = msg_data;
				break;
				
			case "verb_output":
				verb_output_element.value += msg_data;
				break;
				
			case "verb_tokens":
				verb_colored_element.value = msg_data;
				break;
				
			case "warning":
				messages_element.textContent += msg_data;
				break;
				
			default:
				//if ( ! verbose_console_log )
				//{
					var log_msg = 'forGL Result: ' + msg_result + 'NOT handled. Data: ' + msg_data;
					console.log( log_msg );
				//}
					
				break;
		}
		return;
	};
	
	
	
	
	
	var sendDictionary = function( )
	{
		var dict_text = dict_text_element.srcdoc;
		console.log( dict_text );
		sendRequest( "dictionary", dict_text );
		return;
	};
	
	
	
	run_stop_button.onclick = function( e ) 
	{
		if ( is_running )
		{
			var log_msg = 'STOP Running !';
			console.log( log_msg );
			isRunning = false;
			run_stop_button.textContent = "RUN";
			sendRequest( 'stop', '' );
		}
		else
		{
			var user_verb = user_verb_element.value;
			var log_msg = 'Run User Verb: ' + user_verb;
			console.log( log_msg );
			isRunning = true;
			run_stop_button.textContent = "STOP";
			sendRequest( 'run', user_verb );
		}
		return;
	};
	
	verbose_console_log = false;
	sendRequest( "using_web_worker", using_web_worker );		// Help initialize forGL as Web Worker or not
	sendRequest( "oscpu", oscpu );		
	
	
	sendDictionary();
	
	verbose_console_log = true;
	
	
	
})();