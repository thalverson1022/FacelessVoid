const {chromium}=require('C:/Users/tommh/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('node:fs'),path=require('node:path'),{pathToFileURL}=require('node:url'),assert=require('node:assert/strict');
(async()=>{
 const out=path.resolve('project/reports/p6_m7_t3_design');
 const browser=await chromium.launch({channel:'msedge',headless:true});
 const page=await browser.newPage();const errors=[],checks=[];page.on('pageerror',e=>errors.push(e.message));
 try{
 await page.goto(pathToFileURL(path.join(out,'review-preview.html')).href);
 const frame=page.frames().find(f=>f!==page.mainFrame());await frame.locator('.message').first().waitFor();
 for(const [width,height,panelWidth] of [[1280,720,680],[1600,900,850],[1920,1080,1020],[360,900,336]]){
  await page.setViewportSize({width,height});
  await frame.evaluate(w=>{const r=document.getElementById('m7-review');r.style.maxWidth=w+'px';r.style.margin='0 auto';},panelWidth);
  for(const design of ['lanes','ledger']){
   await frame.evaluate(design=>{for(const s of document.querySelectorAll('[data-variant]'))s.hidden=s.querySelector('.fv').dataset.design!==design;},design);
   const panel=frame.locator(`[data-design="${design}"]`);
   for(const scenario of ['dense','spent','overflow','empty']){
    await panel.locator('select').selectOption(scenario);
    for(const enlarged of [false,true]){
     const button=panel.locator('.text-scale');if((await button.getAttribute('aria-pressed')==='true')!==enlarged)await button.click();
     assert.equal(await panel.evaluate(p=>p.scrollWidth<=p.clientWidth+1),true,`${width}/${design}/${scenario} overflow`);
     assert.equal(await panel.locator('.message').count(),scenario==='dense'||scenario==='overflow'?3:scenario==='spent'?2:1);
     checks.push(`${width}/${design}/${scenario}/${enlarged?'125':'100'}: bounded, messages rendered`);
    }
    await panel.locator('.inspect-button').click();assert(await panel.locator('.inspector:not(.log)').isVisible());
    assert.equal(await panel.locator('.effect-details .line').count(),scenario==='overflow'?10:scenario==='empty'?2:3);
    await panel.locator('.inspector:not(.log) .close').press('Escape');assert(await panel.locator('.inspector:not(.log)').isHidden());
    assert(await panel.locator('.inspect-button').evaluate(e=>e===document.activeElement));
   }
   await panel.locator('select').selectOption('dense');if(await panel.locator('.text-scale').getAttribute('aria-pressed')==='true')await panel.locator('.text-scale').click();
   await panel.screenshot({path:path.join(out,`${design}-${width}.png`)});
  }
 }
 await page.setViewportSize({width:1280,height:720});await frame.evaluate(()=>document.getElementById('m7-review').style.maxWidth='680px');
 const panel=frame.locator('[data-design="ledger"]');await panel.locator('select').selectOption('spent');await panel.locator('.text-scale').click();await panel.screenshot({path:path.join(out,'spent-text125.png')});await panel.locator('.text-scale').click();await panel.locator('select').selectOption('overflow');await panel.locator('.inspect-button').click();
 await panel.screenshot({path:path.join(out,'overflow-inspector.png')});await panel.locator('.inspector:not(.log) .close').click();
 await panel.locator('summary').click();assert(await panel.locator('.icon-examples img').evaluateAll(imgs=>imgs.every(i=>i.complete&&i.naturalWidth===32)));
 await panel.locator('details').screenshot({path:path.join(out,'actual-size-icons.png')});
 await panel.locator('.log-button').click();assert(await panel.locator('.log').isVisible());await panel.locator('.motion').check();assert((await panel.locator('.readout').innerText()).includes('Reduced motion'));
 assert.deepEqual(errors,[]);
 fs.writeFileSync(path.join(out,'prototype-checks.json'),JSON.stringify({passed:true,checks,errors,scope:'Synthetic component mockups, not Godot runtime validation. Widths 680/850/1020 represent combat panels in 1280/1600/1920 screens; 336 tests narrow review surface.'},null,2));
 console.log('PASS '+checks.length+' layout/state checks plus inspector focus, log, motion toggle and native assets');
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1});
