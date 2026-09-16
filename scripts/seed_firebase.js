/**
 * AgriChain AI - Firebase Live Database Seeder
 * Populates Firestore collections (users, batches, shipments, audit_events)
 * and Realtime Database live nodes (live/shipments, live/devices)
 */

const fs = require('fs');
const path = require('path');

// Load CLI credentials
const configPath = path.join(process.env.USERPROFILE, '.config', 'configstore', 'firebase-tools.json');
if (!fs.existsSync(configPath)) {
  console.error('Firebase CLI configstore not found at:', configPath);
  process.exit(1);
}

const configstore = JSON.parse(fs.readFileSync(configPath, 'utf8'));
const ra = require('C:/Users/omdam/AppData/Roaming/npm/node_modules/firebase-tools/lib/requireAuth.js');
const { Client } = require('C:/Users/omdam/AppData/Roaming/npm/node_modules/firebase-tools/lib/apiv2.js');

const PROJECT_ID = 'agrichain-ai-hackathon';

async function seed() {
  console.log('Authenticating with Firebase tools session...');
  await ra.requireAuth({ tokens: configstore.tokens, user: configstore.user });

  const firestore = new Client({
    urlPrefix: 'https://firestore.googleapis.com',
    apiVersion: 'v1'
  });

  const rtdb = new Client({
    urlPrefix: 'https://agrichain-ai-hackathon-default-rtdb.firebaseio.com'
  });

  console.log('Seeding Cloud Firestore collections...');

  // Helper to convert JS object to Firestore Document fields
  function toFirestoreValue(val) {
    if (val === null || val === undefined) return { nullValue: null };
    if (typeof val === 'boolean') return { booleanValue: val };
    if (typeof val === 'number') {
      if (Number.isInteger(val)) return { integerValue: val.toString() };
      return { doubleValue: val };
    }
    if (typeof val === 'string') return { stringValue: val };
    if (Array.isArray(val)) return { arrayValue: { values: val.map(toFirestoreValue) } };
    if (typeof val === 'object') {
      const fields = {};
      for (const [k, v] of Object.entries(val)) {
        fields[k] = toFirestoreValue(v);
      }
      return { mapValue: { fields } };
    }
    return { stringValue: String(val) };
  }

  async function writeFirestoreDoc(collection, docId, data) {
    const fields = {};
    for (const [k, v] of Object.entries(data)) {
      fields[k] = toFirestoreValue(v);
    }
    const docPath = `/projects/${PROJECT_ID}/databases/(default)/documents/${collection}/${docId}`;
    const res = await firestore.patch(docPath, { fields });
    console.log(`  ✓ Firestore: ${collection}/${docId} (${res.status})`);
  }

  // 1. Users
  const users = [
    {
      id: 'M7qGjwEsFocBV4m8wbnDyhGNROo1',
      data: {
        userId: 'M7qGjwEsFocBV4m8wbnDyhGNROo1',
        name: 'Rahul Patil',
        email: 'farmer@agrichain.ai',
        phone: '+91 98230 45678',
        role: 'FARMER',
        farmId: 'FARM-NASHIK-01',
        createdAt: new Date().toISOString()
      }
    },
    {
      id: 'USER-001',
      data: {
        userId: 'USER-001',
        name: 'Rahul Patil (Demo)',
        email: 'farmer@agrichain.ai',
        phone: '+91 98230 45678',
        role: 'FARMER',
        farmId: 'FARM-NASHIK-01',
        createdAt: new Date().toISOString()
      }
    },
    {
      id: 'A6Co7c7TPxSSfWZBuAKjPr3HxQC3',
      data: {
        userId: 'A6Co7c7TPxSSfWZBuAKjPr3HxQC3',
        name: 'Vikram Shinde',
        email: 'transporter@agrichain.ai',
        phone: '+91 98200 12345',
        role: 'TRANSPORTER',
        vehicleId: 'MH-15-8842',
        createdAt: new Date().toISOString()
      }
    },
    {
      id: 'oSjHxFAcvdMXV36Nn5bBPNNWN1H2',
      data: {
        userId: 'oSjHxFAcvdMXV36Nn5bBPNNWN1H2',
        name: 'Reliance Fresh Sourcing',
        email: 'buyer@agrichain.ai',
        phone: '+91 98211 54321',
        role: 'BUYER',
        facilityId: 'WH-MUMBAI-APMC',
        createdAt: new Date().toISOString()
      }
    },
    {
      id: 'RzpdXhsvmxYuCDTfcdA8VF1pKZ43',
      data: {
        userId: 'RzpdXhsvmxYuCDTfcdA8VF1pKZ43',
        name: 'Admin Command Control',
        email: 'admin@agrichain.ai',
        phone: '+91 98222 99999',
        role: 'ADMIN',
        createdAt: new Date().toISOString()
      }
    }
  ];

  for (const u of users) {
    await writeFirestoreDoc('users', u.id, u.data);
  }

  // 2. Batches
  const batches = [
    {
      id: 'BATCH-2026-TOM-001',
      data: {
        batchId: 'BATCH-2026-TOM-001',
        cropName: 'Tomato (Hybrid Roma)',
        cropCategory: 'Vegetable',
        quantity: 1200.0,
        unit: 'kg',
        farmerId: 'M7qGjwEsFocBV4m8wbnDyhGNROo1',
        farmId: 'FARM-NASHIK-01',
        harvestDate: '2026-09-15T06:30:00Z',
        expectedShelfLifeHours: 96.0,
        preferredTemperature: { min: 10.0, max: 15.0 },
        preferredHumidity: { min: 85.0, max: 92.0 },
        qualityGrade: 'A+',
        currentStatus: 'in_transit',
        origin: {
          name: 'Nashik Valley Greenhouse Hub',
          latitude: 19.9975,
          longitude: 73.7898
        },
        destination: {
          name: 'Vashi APMC Central Terminal, Mumbai',
          latitude: 19.0760,
          longitude: 72.8777
        },
        activeShipmentId: 'SHIP-2026-0881',
        createdAt: new Date().toISOString()
      }
    },
    {
      id: 'BATCH-2026-GRA-002',
      data: {
        batchId: 'BATCH-2026-GRA-002',
        cropName: 'Thompson Seedless Grapes',
        cropCategory: 'Fruit',
        quantity: 2500.0,
        unit: 'kg',
        farmerId: 'M7qGjwEsFocBV4m8wbnDyhGNROo1',
        farmId: 'FARM-NASHIK-01',
        harvestDate: '2026-09-15T08:00:00Z',
        expectedShelfLifeHours: 168.0,
        preferredTemperature: { min: 0.0, max: 2.0 },
        preferredHumidity: { min: 90.0, max: 95.0 },
        qualityGrade: 'Export-Grade',
        currentStatus: 'registered',
        origin: {
          name: 'Dindori Vineyard Plot 4B',
          latitude: 20.1983,
          longitude: 73.8327
        },
        destination: {
          name: 'JNPT Cold Chain Export Terminal, Nhava Sheva',
          latitude: 18.9499,
          longitude: 72.9515
        },
        activeShipmentId: 'SHIP-2026-0942',
        createdAt: new Date().toISOString()
      }
    }
  ];

  for (const b of batches) {
    await writeFirestoreDoc('batches', b.id, b.data);
  }

  // 3. Shipments
  const shipments = [
    {
      id: 'SHIP-2026-0881',
      data: {
        shipmentId: 'SHIP-2026-0881',
        batchId: 'BATCH-2026-TOM-001',
        transporterId: 'A6Co7c7TPxSSfWZBuAKjPr3HxQC3',
        vehicleId: 'MH-15-8842 (Reefer 3.5T)',
        iotDeviceId: 'ESP32-NODE-01',
        status: 'in_transit',
        origin: {
          name: 'Nashik Valley Greenhouse Hub',
          latitude: 19.9975,
          longitude: 73.7898
        },
        destination: {
          name: 'Vashi APMC Central Terminal, Mumbai',
          latitude: 19.0760,
          longitude: 72.8777
        },
        currentLocation: {
          latitude: 19.4521,
          longitude: 73.3421
        },
        distanceKm: 165.0,
        remainingDistanceKm: 68.4,
        currentSpeed: 52.3,
        delayMinutes: 14.5,
        spoilageRisk: 0.184,
        overallRisk: 0.22,
        riskLevel: 'LOW',
        activeRouteId: 'ROUTE-OPTIMIZED-ALPHA',
        updatedAt: new Date().toISOString()
      }
    },
    {
      id: 'SHIP-2026-0942',
      data: {
        shipmentId: 'SHIP-2026-0942',
        batchId: 'BATCH-2026-GRA-002',
        transporterId: 'A6Co7c7TPxSSfWZBuAKjPr3HxQC3',
        vehicleId: 'MH-15-7719 (Cold Van)',
        iotDeviceId: 'ESP32-NODE-02',
        status: 'assigned',
        origin: {
          name: 'Dindori Vineyard Plot 4B',
          latitude: 20.1983,
          longitude: 73.8327
        },
        destination: {
          name: 'JNPT Cold Chain Export Terminal',
          latitude: 18.9499,
          longitude: 72.9515
        },
        currentLocation: {
          latitude: 20.1983,
          longitude: 73.8327
        },
        distanceKm: 210.0,
        remainingDistanceKm: 210.0,
        currentSpeed: 0.0,
        delayMinutes: 0.0,
        spoilageRisk: 0.04,
        overallRisk: 0.05,
        riskLevel: 'LOW',
        updatedAt: new Date().toISOString()
      }
    }
  ];

  for (const s of shipments) {
    await writeFirestoreDoc('shipments', s.id, s.data);
  }

  // 4. Audit Trail (Immutable traceability logs)
  const auditLogs = [
    {
      id: 'EVT-001',
      data: {
        eventId: 'EVT-001',
        batchId: 'BATCH-2026-TOM-001',
        eventType: 'HARVESTED',
        actorRole: 'FARMER',
        actorId: 'M7qGjwEsFocBV4m8wbnDyhGNROo1',
        location: 'Nashik Greenhouse Plot 3',
        timestamp: '2026-09-15T06:30:00Z',
        payloadHash: '0x8f3c4d12e4b6a9871029c3f41209b6',
        details: 'Harvested 1,200kg Roma tomatoes at optimal Brix 4.8'
      }
    },
    {
      id: 'EVT-002',
      data: {
        eventId: 'EVT-002',
        batchId: 'BATCH-2026-TOM-001',
        eventType: 'QUALITY_CERTIFIED',
        actorRole: 'INSPECTOR',
        actorId: 'AGRI-INSPECT-04',
        location: 'Nashik Regional Packhouse',
        timestamp: '2026-09-15T08:15:00Z',
        payloadHash: '0x7e2a9b44c1d8e630291a5c4e9981f2',
        details: 'Graded Grade A+ Organic Certification #ORG-MH-2026-99'
      }
    },
    {
      id: 'EVT-003',
      data: {
        eventId: 'EVT-003',
        batchId: 'BATCH-2026-TOM-001',
        eventType: 'DISPATCHED',
        actorRole: 'TRANSPORTER',
        actorId: 'A6Co7c7TPxSSfWZBuAKjPr3HxQC3',
        location: 'Nashik Cold Hub Bay 2',
        timestamp: '2026-09-15T09:45:00Z',
        payloadHash: '0x3d91f4c78a02b6e511478c90981e4a',
        details: 'Loaded onto Reefer Truck MH-15-8842, IoT telemetry active'
      }
    }
  ];

  for (const a of auditLogs) {
    await writeFirestoreDoc('audit_events', a.id, a.data);
  }

  // 5. Seed Realtime Database
  console.log('Seeding Firebase Realtime Database live telemetry nodes...');

  const liveShipmentPayload = {
    shipmentId: 'SHIP-2026-0881',
    batchId: 'BATCH-2026-TOM-001',
    deviceId: 'ESP32-NODE-01',
    temperature: 13.8,
    humidity: 87.5,
    ethylene: 14.2,
    shock: 0.15,
    speed: 52.3,
    latitude: 19.4521,
    longitude: 73.3421,
    spoilageRisk: 0.184,
    delayMinutes: 14.5,
    riskLevel: 'LOW',
    reeferState: 'COOLING_ACTIVE',
    coolingSetpoint: 12.0,
    timestamp: Date.now()
  };

  const rtdbRes = await rtdb.put('/live/shipments/SHIP-2026-0881.json', liveShipmentPayload);
  console.log('  ✓ RTDB: /live/shipments/SHIP-2026-0881 (' + rtdbRes.status + ')');

  const liveDevicePayload = {
    deviceId: 'ESP32-NODE-01',
    firmwareVersion: 'v2.4.1',
    batteryVoltage: 3.94,
    batteryPercent: 88,
    wifiRssi: -62,
    gpsFix: true,
    satellites: 9,
    status: 'ONLINE',
    lastPing: Date.now()
  };

  const devRes = await rtdb.put('/live/devices/ESP32-NODE-01.json', liveDevicePayload);
  console.log('  ✓ RTDB: /live/devices/ESP32-NODE-01 (' + devRes.status + ')');

  console.log('\nAll Firebase Firestore & RTDB seed data deployed successfully!');
}

seed().catch((err) => {
  console.error('Seeding error:', err);
  process.exit(1);
});
