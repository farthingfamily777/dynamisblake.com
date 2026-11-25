/* Music page cosmos: canvas starfield, scroll and pointer parallax, shooting stars, reveal on scroll.
   Respects prefers-reduced-motion and has a pause button. Pauses when the tab is hidden. */
(function(){
  var doc=document.documentElement, body=document.body;
  body.classList.add('cz-js');
  var mq=window.matchMedia('(prefers-reduced-motion: reduce)');
  var reduced=mq.matches, paused=false;
  var cv=document.getElementById('cz-stars'), ctx=cv&&cv.getContext('2d');
  var W=0,H=0,dpr=1,stars=[],shooters=[],scrollY=0,lastScroll=0,warp=0,px=0,py=0,tx=0,ty=0,t0=performance.now(),raf=0;
  var COLORS=['255,255,255','255,255,255','255,255,255','156,192,255','200,218,255','255,150,160'];
  function size(){
    dpr=Math.min(window.devicePixelRatio||1,1.5);W=innerWidth;H=innerHeight;
    cv.width=Math.round(W*dpr);cv.height=Math.round(H*dpr);ctx.setTransform(dpr,0,0,dpr,0,0);
    var n=Math.min(520,Math.round(W*H/2600));stars=[];
    for(var i=0;i<n;i++){var z=Math.random();stars.push({x:Math.random()*W,y:Math.random()*H*3,z:z,r:.35+z*z*1.7,c:COLORS[(Math.random()*COLORS.length)|0],tw:Math.random()*6.28,ts:.5+Math.random()*2});}
  }
  function draw(now){
    var t=(now-t0)/1000;
    ctx.clearRect(0,0,W,H);
    px+=(tx-px)*.05;py+=(ty-py)*.05;
    var sy=scrollY, v=sy-lastScroll; lastScroll=sy; warp+=(Math.min(Math.abs(v),60)-warp)*.12;
    for(var i=0;i<stars.length;i++){
      var s=stars[i], depth=.15+s.z*.85;
      var y=((s.y - sy*depth*.35 + py*depth*18)%(H*3)+H*3)%(H*3); if(y>H+4)continue;
      var x=s.x + px*depth*24;
      var a=reduced?.8:(.55+.45*Math.sin(t*s.ts+s.tw));
      var len=warp*depth*.9;
      ctx.fillStyle='rgba('+s.c+','+a.toFixed(3)+')';
      if(len>1.5){ctx.fillRect(x-s.r/2,y-len*(v>0?0:1),s.r,len+s.r);}
      else{ctx.beginPath();ctx.arc(x,y,s.r,0,6.283);ctx.fill();
        if(s.r>1.6){ctx.fillStyle='rgba('+s.c+','+(a*.18).toFixed(3)+')';ctx.beginPath();ctx.arc(x,y,s.r*3.2,0,6.283);ctx.fill();}}
    }
    if(!reduced){
      if(Math.random()<.012&&shooters.length<3)shooters.push({x:Math.random()*W*.8+W*.2,y:Math.random()*H*.5,vx:-(6+Math.random()*6),vy:2.5+Math.random()*3,life:1,red:Math.random()<.4});
      for(var j=shooters.length-1;j>=0;j--){var sh=shooters[j];sh.x+=sh.vx;sh.y+=sh.vy;sh.life-=.018;
        if(sh.life<=0||sh.x<-100){shooters.splice(j,1);continue;}
        var g=ctx.createLinearGradient(sh.x,sh.y,sh.x-sh.vx*12,sh.y-sh.vy*12);
        var col=sh.red?'255,120,135':'210,225,255';
        g.addColorStop(0,'rgba('+col+','+sh.life+')');g.addColorStop(1,'rgba('+col+',0)');
        ctx.strokeStyle=g;ctx.lineWidth=2;ctx.beginPath();ctx.moveTo(sh.x,sh.y);ctx.lineTo(sh.x-sh.vx*12,sh.y-sh.vy*12);ctx.stroke();}
    }
  }
  var nebs=[].slice.call(document.querySelectorAll('[data-depth]'));
  function parallax(){
    for(var i=0;i<nebs.length;i++){var d=parseFloat(nebs[i].dataset.depth);
      nebs[i].style.transform='translate3d('+(px*d*40).toFixed(1)+'px,'+(-scrollY*d).toFixed(1)+'px,0)';}
  }
  function loop(now){raf=0;scrollY=window.scrollY||doc.scrollTop;draw(now);parallax();if(!reduced&&!paused&&!document.hidden)raf=requestAnimationFrame(loop);}
  function kick(){if(!raf)raf=requestAnimationFrame(loop);}
  function still(){scrollY=window.scrollY||doc.scrollTop;draw(performance.now());parallax();}
  if(ctx){size();
    addEventListener('resize',function(){size();reduced||paused?still():kick();});
    addEventListener('scroll',function(){if(reduced||paused){still();}else kick();},{passive:true});
    addEventListener('pointermove',function(e){tx=(e.clientX/W-.5)*2;ty=(e.clientY/H-.5)*2;},{passive:true});
    document.addEventListener('visibilitychange',function(){if(!document.hidden&&!reduced&&!paused)kick();});
    reduced?still():kick();
  }
  /* reveal panels */
  var panels=document.querySelectorAll('.cz-panel');
  if('IntersectionObserver' in window&&!reduced){
    var io=new IntersectionObserver(function(es){es.forEach(function(e){if(e.isIntersecting){e.target.classList.add('cz-in');io.unobserve(e.target);}});},{rootMargin:'0px 0px -8% 0px',threshold:.08});
    panels.forEach(function(p){io.observe(p);});
  }else panels.forEach(function(p){p.classList.add('cz-in');});
  /* pause button */
  var btn=document.querySelector('.cz-motion');
  if(btn&&!reduced){btn.hidden=false;
    btn.addEventListener('click',function(){paused=!paused;body.classList.toggle('cz-still',paused);btn.setAttribute('aria-pressed',paused);
      btn.textContent=paused?'Play motion':'Pause motion';paused?still():kick();});}
  mq.addEventListener&&mq.addEventListener('change',function(e){reduced=e.matches;reduced?still():kick();});
})();
