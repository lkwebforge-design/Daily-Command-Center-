const CACHE_NAME='dcc-shell-v2';
const APP_URL='https://lkwebforge-design.github.io/Daily-Command-Center/';
self.addEventListener('install',event=>{event.waitUntil(self.skipWaiting());});
self.addEventListener('activate',event=>{event.waitUntil(self.clients.claim());});
self.addEventListener('push',event=>{
 let data={title:'Daily Command Center',body:'You have a reminder.',url:APP_URL+'#reminders'};
 try{if(event.data)data={...data,...event.data.json()}}catch(_){if(event.data)data.body=event.data.text()}
 const target=APP_URL+'#reminders';
 event.waitUntil(self.registration.showNotification(data.title||'Daily Command Center',{
  body:data.body||'You have a reminder.',
  icon:APP_URL+'app-icon.svg',badge:APP_URL+'app-icon.svg',
  data:{url:target},tag:data.tag||'dcc-reminder'
 }));
});
self.addEventListener('notificationclick',event=>{
 event.notification.close();
 const target=APP_URL+'#reminders';
 event.waitUntil(self.clients.matchAll({type:'window',includeUncontrolled:true}).then(async list=>{
  for(const client of list){
   if(client.url.startsWith(APP_URL)&&'focus'in client){
    const focused=await client.focus();
    if('navigate'in focused) return focused.navigate(target);
    return focused;
   }
  }
  return self.clients.openWindow(target);
 }));
});