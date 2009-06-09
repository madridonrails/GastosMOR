function showDiv (el, div, text, alignX, alignY) {
    if (document.getElementById){
        var i = document.getElementById(el);
        var c = document.getElementById(div);
        if (c.style.display != "block"){
            var l=0; var t=0;
            aTag = i;
            do {
                aTag = aTag.offsetParent;
                l += aTag.offsetLeft;
                t += aTag.offsetTop;
            } while (aTag.offsetParent && aTag.tagName != 'BODY');
            var left =  i.offsetLeft + l;
            var top = i.offsetTop + t + i.offsetHeight + 2;
            if (alignX == 'left' && c.style.width){
                left = left - parseInt(c.style.width);
            }
            if (alignY == 'top' && c.style.height){
                top = top - parseInt(c.style.height) -25;
            }           
            c.style.position = 'absolute';                        
            c.style.left = left+'px';
            c.style.top = top+'px';
            c.style.display = "block";
            c.innerHTML = text;            
        } else {
            c.style.display="none";
        }
    }
}

function hideDiv (div) {  
    var c=document.getElementById(div);
    if (c){
        c.style.display="none";
    }
}
