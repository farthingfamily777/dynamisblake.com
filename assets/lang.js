/* Dynamis Blake: English | Español toggle. Translations live in each page's <script type="application/json" id="i18n-es">. */
(function(){
  var KEY="dbLang", dict={}, pats=[], orig=new WeakMap(), attrs=["aria-label","placeholder","title","alt"];
  var el=document.getElementById("i18n-es");
  if(el){try{var j=JSON.parse(el.textContent);pats=(j._patterns||[]).map(function(p){return [new RegExp(p[0]),p[1]]});delete j._patterns;dict=j;}catch(e){}}
  var norm=function(s){return s.replace(/\s+/g," ").trim()};
  function tr(s){var n=norm(s);if(!n)return null;if(dict[n]!=null)return dict[n];
    for(var i=0;i<pats.length;i++){if(pats[i][0].test(n))return n.replace(pats[i][0],pats[i][1]);}return null;}
  var lang=localStorage.getItem(KEY)==="es"?"es":"en", busy=false, title0=document.title;
  function doNode(n,es){
    if(n.nodeType===3){var p=n.parentNode;if(!p||/^(SCRIPT|STYLE|NOSCRIPT)$/.test(p.nodeName)||p.closest(".lang-toggle"))return;
      var o=orig.get(n);
      if(es){if(o===undefined){var t=tr(n.nodeValue);if(t==null)return;o=n.nodeValue;orig.set(n,o);}else{var t=tr(o);}
        var m=o.match(/^\s*/)[0],e=o.match(/\s*$/)[0];var v=m+t+e;if(n.nodeValue!==v)n.nodeValue=v;}
      else if(o!==undefined&&n.nodeValue!==o){n.nodeValue=o;}
    }else if(n.nodeType===1){
      if(n.closest&&n.closest(".lang-toggle"))return;
      attrs.forEach(function(a){if(!n.hasAttribute(a))return;var k="data-en-"+a;
        if(es){var o=n.getAttribute(k)||n.getAttribute(a);var t=tr(o);if(t!=null){n.setAttribute(k,o);n.setAttribute(a,t);}}
        else if(n.hasAttribute(k)){n.setAttribute(a,n.getAttribute(k));}});
      for(var c=n.firstChild;c;c=c.nextSibling)doNode(c,es);
    }}
  function apply(){busy=true;var es=lang==="es";
    document.documentElement.lang=es?"es":"en";
    var t=tr(title0);document.title=es&&t!=null?t:title0;
    doNode(document.body,es);
    document.querySelectorAll(".lang-toggle button").forEach(function(b){var on=b.dataset.lang===lang;b.classList.toggle("on",on);b.setAttribute("aria-pressed",on);});
    busy=false;}
  function set(l){lang=l;try{localStorage.setItem(KEY,l)}catch(e){}apply();}
  function init(){
    var w=document.createElement("div");w.className="lang-toggle";w.setAttribute("role","group");w.setAttribute("aria-label","Language / Idioma");
    w.innerHTML='<button type="button" data-lang="en" lang="en">English</button><span aria-hidden="true">|</span><button type="button" data-lang="es" lang="es">Español</button>';
    w.addEventListener("click",function(e){var b=e.target.closest("button");if(b)set(b.dataset.lang);});
    document.body.appendChild(w);apply();
    new MutationObserver(function(ms){if(busy||lang!=="es")return;busy=true;ms.forEach(function(m){m.addedNodes.forEach(function(n){doNode(n,true)});if(m.type==="characterData")doNode(m.target,true);});busy=false;})
      .observe(document.body,{childList:true,subtree:true,characterData:true});
  }
  if(document.readyState==="loading")document.addEventListener("DOMContentLoaded",init);else init();
})();
