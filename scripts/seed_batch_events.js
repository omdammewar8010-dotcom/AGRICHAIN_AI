/**
 * Seed batch_events and crop_batches for AGRI-2026-TOM-000124
 */

const fs = require('fs');
const path = require('path');

const configPath = path.join(process.env.USERPROFILE, '.config', 'configstore', 'firebase-tools.json');
const configstore = JSON.parse(fs.readFileSync(configPath, 'utf8'));
const ra = require('C:/Users/omdam/AppData/Roaming/npm/node_modules/firebase-tools/lib/requireAuth.js');
const { Client } = require('C:/Users/omdam/AppData/Roaming/npm/node_modules/firebase-tools/lib/apiv2.js');

const PROJECT_ID = 'agrichain-ai-hackathon';

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

async function run() {
  await ra.requireAuth({ tokens: configstore.tokens, user: configstore.user });
  const firestore = new Client({ urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1' });

  async function writeDoc(collection, docId, data) {
    const fields = {};
    for (const [k, v] of Object.entries(data)) {
      fields[k] = toFirestoreValue(v);
    }
    const docPath = `/projects/${PROJECT_ID}/databases/(default)/documents/${collection}/${docId}`;
    const res = await firestore.patch(docPath, { fields });
    console.log(`  ✓ ${collection}/${docId} (${res.status})`);
  }

  console.log('Seeding batch_events for AGRI-2026-TOM-000124...');
  const events = [
    {
      id: 'EVT-TOM-01',
      data: {
        eventId: 'EVT-TOM-01',
        batchId: 'AGRI-2026-TOM-000124',
        shipmentId: 'SHIP-2026-0916-01',
        stage: 'harvest',
        type: 'harvest_registered',
        location: {
          address: 'Sahyadri Agro Farms, Nashik',
          latitude: 19.9975,
          longitude: 73.7898
        },
        temperature: 20.5,
        humidity: 65.0,
        performedBy: 'Rahul Patil (Farmer)',
        role: 'farmer',
        description: 'Harvested 1,200 kg Roma Tomatoes. Graded Grade A. Pre-cooled to 20°C in packhouse.',
        timestamp: '2026-09-16 06:30 AM'
      }
    },
    {
      id: 'EVT-TOM-02',
      data: {
        eventId: 'EVT-TOM-02',
        batchId: 'AGRI-2026-TOM-000124',
        shipmentId: 'SHIP-2026-0916-01',
        stage: 'collection',
        type: 'intake_inspection',
        location: {
          address: 'Dindori Rural Collection Center',
          latitude: 19.8500,
          longitude: 73.7100
        },
        temperature: 21.0,
        humidity: 68.0,
        performedBy: 'Suresh More (Inspector)',
        role: 'collection_center',
        description: 'QC Verified: Brix 5.2, Firmness 4.8kg/cm2. QR code tag affixed. Loaded into Reefer MH-15-EG-8842.',
        timestamp: '2026-09-16 08:15 AM'
      }
    },
    {
      id: 'EVT-TOM-03',
      data: {
        eventId: 'EVT-TOM-03',
        batchId: 'AGRI-2026-TOM-000124',
        shipmentId: 'SHIP-2026-0916-01',
        stage: 'transport',
        type: 'transit_checkpoint',
        location: {
          address: 'Igatpuri Logistics Checkpoint (KM 45)',
          latitude: 19.6948,
          longitude: 73.5601
        },
        temperature: 20.8,
        humidity: 67.2,
        performedBy: 'Vikram Shinde (Transporter)',
        role: 'transporter',
        description: 'Reefer compressor active. IoT Node ESP32-TRUCK-001 operational. Telemetry nominal.',
        timestamp: '2026-09-16 09:10 AM'
      }
    }
  ];

  for (const e of events) {
    await writeDoc('batch_events', e.id, e.data);
  }

  console.log('Seeding crop_batches for AGRI-2026-TOM-000124...');
  await writeDoc('crop_batches', 'AGRI-2026-TOM-000124', {
    batchId: 'AGRI-2026-TOM-000124',
    cropName: 'Tomato (Roma Hybrid)',
    cropCategory: 'Vegetable',
    quantity: 1200.0,
    unit: 'kg',
    farmerId: 'USER-001',
    farmId: 'FARM-NASHIK-01',
    harvestDate: '2026-09-16',
    expectedShelfLifeHours: 96.0,
    preferredTemperature: { min: 18.0, max: 22.0 },
    preferredHumidity: { min: 60.0, max: 75.0 },
    qualityGrade: 'A',
    currentStatus: 'in_transit',
    origin: {
      address: 'Sahyadri Agro Farms, Nashik, Maharashtra',
      latitude: 19.9975,
      longitude: 73.7898
    },
    destination: {
      address: 'APMC Central Terminal, Vashi, Navi Mumbai',
      latitude: 19.0760,
      longitude: 72.8777
    },
    activeShipmentId: 'SHIP-2026-0916-01'
  });

  console.log('Done seeding batch_events and crop_batches!');
}

run().catch(console.error);
