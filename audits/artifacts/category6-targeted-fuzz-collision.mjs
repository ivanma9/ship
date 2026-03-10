import { chromium } from '@playwright/test';
import fs from 'fs';

const BASE_URL='http://localhost:5173';
const out='audits/artifacts';
fs.mkdirSync(out,{recursive:true});

async function login(page){
  await page.goto(`${BASE_URL}/login`);
  const setup = page.getByRole('button',{name:/create admin account/i});
  const signIn = page.getByRole('button',{name:'Sign in', exact:true});
  await setup.or(signIn).first().waitFor({state:'visible', timeout:10000});
  if(await setup.isVisible().catch(()=>false)){
    await page.locator('#name').fill('Dev User');
    await page.locator('#email').fill('dev@ship.local');
    await page.locator('#password').fill('admin123');
    await page.locator('#confirmPassword').fill('admin123');
    await setup.click();
    await page.waitForURL((u)=>!u.toString().includes('/setup'), {timeout:10000});
  } else {
    await page.locator('#email').fill('dev@ship.local');
    await page.locator('#password').fill('admin123');
    await signIn.click();
    await page.waitForURL((u)=>!u.toString().includes('/login'), {timeout:10000});
  }
}

async function createDoc(page){
  await page.goto(`${BASE_URL}/docs`);
  await page.waitForTimeout(1500);
  const old=page.url();
  const btn = page.getByRole('button',{name:/new document/i}).last();
  await btn.waitFor({state:'visible',timeout:15000});
  await btn.click();
  await page.waitForFunction((o)=>location.href!==o && /\/documents\/[a-f0-9-]+/.test(location.href), old, {timeout:15000});
  return page.url().split('/documents/')[1];
}

const browser=await chromium.launch({headless:true});
const c1=await browser.newContext();
const p1=await c1.newPage();
await login(p1);
const docId=await createDoc(p1);
const title1=p1.locator('textarea[placeholder="Untitled"]');
const ed1=p1.locator('.ProseMirror');
await ed1.waitFor({state:'visible',timeout:10000});

await title1.fill('');
await p1.waitForTimeout(600);
const huge='X'.repeat(52000);
await title1.fill(huge);
await p1.waitForTimeout(1200);
const xss=`<script>alert('x')</script> \"' OR 1=1; --`;
await title1.fill(xss);
await ed1.click();
await p1.keyboard.type(xss);
await p1.waitForTimeout(800);
const html=await ed1.innerHTML();

const c2=await browser.newContext();
const p2=await c2.newPage();
await login(p2);
await p2.goto(`${BASE_URL}/documents/${docId}`);
await p2.locator('.ProseMirror').waitFor({state:'visible',timeout:10000});
const title2=p2.locator('textarea[placeholder="Untitled"]');

const v1=`CollisionA-${Date.now()}`;
const v2=`CollisionB-${Date.now()}`;
await Promise.all([
  (async()=>{await title1.click(); await title1.fill(v1);})(),
  (async()=>{await p2.waitForTimeout(50); await title2.click(); await title2.fill(v2);})(),
]);
await p1.waitForTimeout(2500);
await p2.waitForTimeout(2500);

const final1=await title1.inputValue();
const final2=await title2.inputValue();

const results={docId, fuzz:{hugeLength:huge.length, xssRawScriptTagInEditor:/<script>alert\('x'\)<\/script>/i.test(html)}, collision:{v1,v2,final1,final2,inference: final1===final2?'Last-Write-Wins/Convergent':'Divergence'}};
fs.writeFileSync(`${out}/category6-targeted.json`, JSON.stringify(results,null,2));
console.log(JSON.stringify(results,null,2));
await c1.close();
await c2.close();
await browser.close();
