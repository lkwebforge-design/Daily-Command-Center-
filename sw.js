const CACHE_NAME='dcc-shell-v3';
const APP_URL='https://lkwebforge-design.github.io/Daily-Command-Center-/';
self.addEventListener('install',event=>{event.waitUntil(self.skipWaiting());});
self.addEventListener('activate',event=>{event.waitUntil((async()=>{const keys=await caches.keys();await Promise.all(keys.filter(k=>k.startsWith('dcc-shell-')&&k!==CACHE_NAME).map(k=>caches.delete(k)));await self.clients.claim();})());});
self.addEventListener('push',event=>{
 let data={title:'Daily Command Center',body:'You have a reminder.',url:APP_URL+'?source=notification#reminders'};
 try{if(event.data)data={...data,...event.data.json()}}catch(_){if(event.data)data.body=event.data.text()}
 event.waitUntil(self.registration.showNotification(data.title||'Daily Command Center',{
  body:data.body||'You have a reminder.',
  icon:APP_URL+'app-icon.svg',badge:APP_URL+'app-icon.svg',
  data:{url:APP_URL+'?source=notification#reminders'},tag:data.tag||'dcc-reminder'
 }));
});
self.addEventListener('notificationclick',event=>{
 event.notification.close();
 const target=APP_URL+'?source=notification#reminders';
 event.waitUntil((async()=>{
  const list=await self.clients.matchAll({type:'window',includeUncontrolled:true});
  for(const client of list){
   if(client.url.startsWith(APP_URL)&&'focus'in client){
    await client.focus();
    if('navigate'in client){await client.navigate(target);return;}
    return;
   }
  }
  await self.clients.openWindow(target);
 })());
});