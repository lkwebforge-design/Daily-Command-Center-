const CACHE_NAME='dcc-shell-v1';
self.addEventListener('install',event=>{event.waitUntil(self.skipWaiting());});
self.addEventListener('activate',event=>{event.waitUntil(self.clients.claim());});
self.addEventListener('push',event=>{
 let data={title:'Daily Command Center',body:'You have a reminder.',url:'./'};
 try{if(event.data)data={...data,...event.data.json()}}catch(_){if(event.data)data.body=event.data.text()}
 event.waitUntil(self.registration.showNotification(data.title||'Daily Command Center',{
  body:data.body||'You have a reminder.',
  icon:'./app-icon.svg',badge:'./app-icon.svg',
  data:{url:data.url||'./'},tag:data.tag||'dcc-reminder'
 }));
});
self.addEventListener('notificationclick',event=>{
 event.notification.close();
 const target=new URL(event.notification.data?.url||'./',self.location.origin).href;
 event.waitUntil(self.clients.matchAll({type:'window',includeUncontrolled:true}).then(list=>{
  for(const client of list){if(client.url.startsWith(self.location.origin)&&'focus'in client)return client.focus().then(c=>{if('navigate'in c)return c.navigate(target);return c;});}
  return self.clients.openWindow(target);
 }));
});