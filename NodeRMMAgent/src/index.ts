import { initializeApp } from "@firebase/app";
import { getFirestore, addDoc, collection, doc, onSnapshot } from "@firebase/firestore";
var snmp = require("net-snmp");

const firebaseConfig = {
  apiKey: "AIzaSyCiiIwgR3-hqUrIeCCdmudOr2nKwmviSyU",
  authDomain: "road-to-iot.firebaseapp.com",
  databaseURL: "https://road-to-iot.firebaseio.com",
  projectId: "road-to-iot",
  storageBucket: "road-to-iot.appspot.com",
  messagingSenderId: "307495712434",
  appId: "1:307495712434:web:6e83ae7a3698dba6f33bab",
  measurementId: "G-1N1NL488BZ"
};

const devId = "Agent1"

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app)

async function main() {
  try {
    const docRef = await addDoc(collection(db, "tmp"), {
      first: "Ada",
      last: "Lovelace",
      born: 1815
    });
    console.log("Document written with ID: ", docRef.id);
  } catch (e) {
    console.error("Error adding document: ", e);
  }
  const unsub = onSnapshot(doc(db, "device", devId), (doc: any) => {
    console.log("Current data: ", doc.data());
  });
}

main();

async function discoveryRange(ipStart: string, ipEnd: string) {
  for (var i = ipv4ton(ipStart); i <= ipv4ton(ipEnd); ++i) {
    console.log(snmpGetNext(ntoipv4(i)));
  }
}

async function snmpGetNext(ip: string): Promise<any> {
  console.log(ip)
  var session = snmp.createSession(ip, "public");
  var oids = ["1.3.6"];
  return await session.getNext(oids, function (error: Number, varbinds: Array<any>) {
    if (error) {
      console.error(error);
      return null;
    } else {
      for (var i = 0; i < varbinds.length; i++) {
        if (snmp.isVarbindError(varbinds[i])) {
          console.error(snmp.varbindError(varbinds[i]));
        } else {
          console.log(varbinds[i].oid + " = " + varbinds[i].value);
        }
      }
      return varbinds;
    }
    session.close();
  });
}

function ipv4ton(ip: string): number {
  return ip.split('.').reduce((a, v, i) => { return (a << 8) + parseInt(v, 10) >>> 0; }, 0);
}
function ntoipv4(n: number): string {
  return "" + ((n >> 24) & 255) + "." + ((n >> 16) & 255) + "." + ((n >> 8) & 255) + "." + (n & 255)
}

