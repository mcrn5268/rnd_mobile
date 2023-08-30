const admin = require('firebase-admin');
const express = require('express');
const bodyParser = require('body-parser');
const axios = require('axios');

const app = express();
app.use(bodyParser.json());

// Load the service account key file
const serviceAccount = require('./prime-software-62e3a-firebase-adminsdk-5h08t-6de7fc478e.json');

// Initialize Firebase Admin SDK
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});


const db = admin.firestore();
db.settings({ ignoreUndefinedProperties: true });

app.post('/send-push-notification', async (req, res) => {
    try {
        const { usernames, title, body, type, poNum, poDate, delvDate, purpose, remarks, preqNum, requestDate, reference, warehouse, requestedBy, reason } = req.body;

        const notificationBody = body ?? `${type === 'PR' ? 'Request' : 'Order'} Number: ${type === 'PR' ? preqNum : poNum}`;
        // if (body != null) {
        //     notificationBody = body;
        // } else if (type === 'PR') {
        //     notificationBody = `Request Number: ${preqNum}\nRequest Date: ${requestDate}\nReference: ${reference}\nWarehouse: ${warehouse}\nRequested By: ${requestedBy}\nReason: ${reason}`;
        // } else if (type === 'PO') {
        //     notificationBody = `Order Number: ${poNum}\nOrder Date: ${poDate}\Delivery Date: ${delvDate}\nReference: ${reference}\nWarehouse: ${warehouse}\nPurpose: ${purpose}\nRemarks: ${remarks}`;
        // }

        const messageData = body ? { type, body } : { type, [type === 'PR' ? 'preqNum' : 'poNum']: type === 'PR' ? preqNum : poNum };

        for (const username of usernames) {
            const docRef = db.collection('tokens').doc(username);
            const doc = await docRef.get();

            if (doc.exists) {
                const mobile = doc.get('tokens');
                if (mobile != undefined) {
                    const tokensList = Object.keys(mobile).map((key) => mobile[key]);
                    let notificationTitle;
                    if (type == "PR") {
                        notificationTitle = "New Purchase Request!";
                    } else if (type == "PO") {
                        notificationTitle = "New Purchase Order!";
                    }

                    if (tokensList.length > 0) {
                        const message = {
                            notification: {
                                title: title || notificationTitle,
                                body: notificationBody,
                            },
                            data: messageData,
                            tokens: tokensList,
                        };

                        // Send the message to the devices corresponding to the provided FCM tokens
                        await admin.messaging().sendEachForMulticast(message);
                        console.log('Successfully sent message:', message);
                    }

                }

                const nonMobile = doc.get('nonMobile');
                if (nonMobile != undefined || nonMobile === true) {
                    const collectionRef = db.collection('notifications');
                    const docRef = collectionRef.doc(username);

                    await db.runTransaction(async transaction => {
                        const docSnapshot = await transaction.get(docRef);
                        let data = docSnapshot.data();
                        const serverTime = admin.firestore.Timestamp.now().toMillis();
                        if (!data || !data.notifications) {
                            // Initialize the notifications array if it doesn't exist
                            data = { notifications: [], triggerStream: true };
                        }
                        if(!data.triggerStream){
                            data.triggerStream = true;
                        }
                        if (data.notifications.length < 20) {
                            // Add a new element to the notifications array
                            data.notifications.push({
                                ...messageData,
                                timestamp: serverTime,
                                seen: false,
                            });
                            transaction.set(docRef, data);
                        } else {
                            // Remove the first element from the notifications array and add a new element at the end
                            data.notifications.shift();
                            data.notifications.push({
                                ...messageData,
                                timestamp: serverTime,
                                seen: false,
                            });
                            transaction.set(docRef, data);
                        }
                    });
                }
            } else {
                console.log('No such document for username:', username);
            }
        }

        res.status(200).send('Notifications sent successfully');
    } catch (err) {
        console.error('Error sending notifications:', err);
        res.status(500).send('Error sending notifications: ' + err.message);
    }
});


app.post('/send-push-notification-group', async (req, res) => {
    try {
        const { group, type, title, body } = req.body;
        const db = admin.firestore();
        const docRef = db.collection('groups').doc(group);
        const doc = await docRef.get();

        if (doc.exists) {
            const data = doc.data();
            const usernames = Object.keys(data);
            console.log('usernames: ' + usernames);
            if (usernames.length > 0) {
                // Call the /send-push-notification endpoint
                const response = await axios.post('http://localhost:3000/send-push-notification', {
                    usernames,
                    type,
                    title,
                    body,
                });

                res.status(200).send(response.data);
            } else {
                res.status(200).send('There is no usernames subscribed to this group');
            }
        } else {
            console.log('No such document for group:', group);
            res.status(404).send('Group not found');
        }
    } catch (err) {
        console.error('Error sending notification:', err);
        res.status(500).send('Error sending notification: ' + err.message);
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server listening on port ${PORT}`);
});

// curl -X POST -H "Content-Type: application/json" -d "{\"usernames\":[\"admin\"],\"preqNum\":\"16\",\"requestDate\":\"16\",\"reference\":\"16\",\"warehouse\":\"16\",\"requestedBy\":\"16\",\"reason\":\"16\"}" http://192.168.254.163:3000/send-push-notification
// curl -X POST -H "Content-Type: application/json" -d "{\"group\":\"groupname\",\"type\":\"group\",\"title\":\"Group Notif Title\",\"body\":\"group notif test\"}" http://192.168.254.163:3000/send-push-notification-group
