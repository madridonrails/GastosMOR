// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function tbodyHasRowIds(tbodyId, rowIds){
  var obj = document.getElementById(tbodyId);
  if(obj){
    var nChildren = obj.rows.length;
    var nChildNames = rowIds.length;
    for(var i=0; i<nChildren; i++){
      for(var j=0; j<nChildNames; j++){
	    if(obj.rows[i].id.indexOf(rowIds[j]) >= 0){
		  return true;
		}
	  }
    }
  }
  return false;
}

//Upload de fichero
function handleResponse(documentObject,stringToEvaluate) {
 
	window.eval(stringToEvaluate);
	if (documentObject.location){ // Should be usefull for IE only .. but I cannot test it
		if(documentObject.location != "") documentObject.location.replace('about:blank');
	}		
	
}