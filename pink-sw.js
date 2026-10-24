const CACHE_NAME='pink-paradise-shell-v1';
const APP_URL='https://lkwebforge-design.github.io/Daily-Command-Center-/pink-paradise.html';
self.addEventListener('install',event=>{event.waitUntil(self.skipWaiting());});
self.addEventListener('activate',event=>{event.waitUntil((async()=>{const keys=await caches.keys();await Promise.all(keys.filter(k=>k.startsWith('pink-paradise-shell-')&&k!==CACHE_NAME).map(k=>caches.delete(k)));await self.clients.claim();})());});
self.addEventListener('push',event=>{
 let data={title:'Pink Paradise',body:'A gentle reminder for you.',url:APP_URL+'?source=notification#reminders'};
 try{if(event.data)data={...data,...event.data.json()}}catch(_){if(event.data)data.body=event.data.text()}
 event.waitUntil(self.registration.showNotification(data.title||'Pink Paradise',{
  body:data.body||'A gentle reminder for you.',
  icon:'https://lkwebforge-design.github.io/Daily-Command-Center-/pink-icon.svg',
  badge:'https://lkwebforge-design.github.io/Daily-Command-Center-/pink-icon.svg',
  data:{url:APP_URL+'?source=notification#reminders'},tag:data.tag||'pink-paradise-reminder'
 }));
});
self.addEventListener('notificationclick',event=>{
 event.notification.close();
 const target=APP_URL+'?source=notification#reminders';
 event.waitUntil((async()=>{
  const list=await self.clients.matchAll({type:'window',includeUncontrolled:true});
  for(const client of list){
   if(client.url.startsWith(APP_URL)&&'focus'in client){await client.focus();if('navigate'in client){await client.navigate(target);return;}return;}
  }
  await self.clients.openWindow(target);
 })());
});