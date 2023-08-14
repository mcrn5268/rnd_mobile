importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

//Using singleton breaks instantiating messaging()
// App firebase = FirebaseWeb.instance.app;


const firebaseConfig = {
    apiKey: "AIzaSyAqX9tCKb9Ce2rb5d_rShSNEjDjXoIADSc",
    authDomain: "prime-software-62e3a.firebaseapp.com",
    projectId: "prime-software-62e3a",
    storageBucket: "prime-software-62e3a.appspot.com",
    messagingSenderId: "431428997513",
    appId: "1:431428997513:web:beb46636c4b5b39bf59158",
    measurementId: "G-ZBLHPQ84LL"
};

firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();


messaging.onBackgroundMessage(function (payload) {
    console.log('Received background message ', payload);

    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
    };

    self.registration.showNotification(notificationTitle,
        notificationOptions);
});

messaging.setBackgroundMessageHandler(function (payload) {
    console.log('Received background message ', payload);
    const promiseChain = clients
        .matchAll({
            type: "window",
            includeUncontrolled: true
        })
        .then(windowClients => {
            for (let i = 0; i < windowClients.length; i++) {
                const windowClient = windowClients[i];
                windowClient.postMessage(payload);
            }
        })
        .then(() => {
            return registration.showNotification("New Message");
        });
    return promiseChain;
});
self.addEventListener('notificationclick', function (event) {
    console.log('notification received: ', event)
});