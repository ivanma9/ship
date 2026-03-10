import { chromium } from '@playwright/test';
const b=await chromium.launch({headless:true});
const c=await b.newContext();
const p=await c.newPage();
await p.goto('http://localhost:5173/login');
const setup=p.getByRole('button',{name:/create admin account/i});
const signIn=p.getByRole('button',{name:'Sign in', exact:true});
await setup.or(signIn).first().waitFor({state:'visible',timeout:10000});
if(await setup.isVisible().catch(()=>false)){
 await p.locator('#name').fill('Dev User');
 await p.locator('#email').fill('dev@ship.local');
 await p.locator('#password').fill('admin123');
 await p.locator('#confirmPassword').fill('admin123');
 await setup.click();
 await p.waitForTimeout(1500);
} else {
 await p.locator('#email').fill('dev@ship.local');
 await p.locator('#password').fill('admin123');
 await signIn.click();
 await p.waitForTimeout(1500);
}
await p.goto('http://localhost:5173/docs');
await p.waitForTimeout(3000);
const buttons=await p.locator('button').allTextContents();
console.log(JSON.stringify(buttons,null,2));
await p.screenshot({path:'audits/artifacts/docs-page.png', fullPage:true});
await b.close();
