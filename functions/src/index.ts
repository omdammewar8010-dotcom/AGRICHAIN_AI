import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

/**
 * 1. Event trigger when a new crop batch is created
 * - Automatically registers the initial traceability event (Harvest stage)
 * - Writes an audit trail log
 * - Sends confirmation notification to the farmer
 */
export const onBatchCreated = functions.firestore
  .document("crop_batches/{batchId}")
  .onCreate(async (snap, context) => {
    const batchData = snap.data();
    const batchId = context.params.batchId;

    try {
      // 1. Initial Traceability Event
      const eventRef = db.collection("batch_events").doc();
      await eventRef.set({
        eventId: eventRef.id,
        batchId: batchId,
        stage: "harvest",
        type: "batch_registered",
        location: batchData.origin || { latitude: 0, longitude: 0, address: "Farm Origin" },
        temperature: batchData.preferredTemperature ? batchData.preferredTemperature.min : 20.0,
        humidity: batchData.preferredHumidity ? batchData.preferredHumidity.min : 65.0,
        performedBy: batchData.farmerId || "system",
        role: "farmer",
        description: `Batch registered: ${batchData.quantity} ${batchData.unit} of ${batchData.cropName}. Grade ${batchData.qualityGrade || "A"}.`,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 2. Audit Log
      await db.collection("audit_logs").add({
        action: "BATCH_CREATED",
        entityType: "crop_batches",
        entityId: batchId,
        performedBy: batchData.farmerId || "system",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          cropName: batchData.cropName,
          quantity: batchData.quantity,
          unit: batchData.unit,
        },
      });

      // 3. User Notification
      if (batchData.farmerId) {
        await db.collection("notifications").add({
          userId: batchData.farmerId,
          title: "Batch Created Successfully",
          body: `Batch ${batchId} for ${batchData.cropName} (${batchData.quantity} ${batchData.unit}) is now registered.`,
          type: "batch_created",
          severity: "INFO",
          read: false,
          relatedBatchId: batchId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      console.log(`Successfully processed initial lifecycle for batch ${batchId}`);
    } catch (error) {
      console.error(`Error processing onBatchCreated for batch ${batchId}:`, error);
    }
  });

/**
 * 2. Event trigger when ML risk score exceeds threshold or critical risk is predicted
 * - Creates an actionable alert in alerts/
 * - Broadcasts FCM push notifications to transporter, farmer, and admin
 */
export const onRiskThresholdExceeded = functions.firestore
  .document("risk_predictions/{predictionId}")
  .onCreate(async (snap, context) => {
    const riskData = snap.data();
    const predictionId = context.params.predictionId;

    if (riskData.overallRisk >= 70 || riskData.riskLevel === "CRITICAL" || riskData.riskLevel === "HIGH") {
      try {
        const alertRef = db.collection("alerts").doc();
        await alertRef.set({
          alertId: alertRef.id,
          batchId: riskData.batchId,
          shipmentId: riskData.shipmentId || null,
          title: `High Risk Detected: ${riskData.riskLevel} (${Math.round(riskData.overallRisk)}/100)`,
          description: riskData.recommendedAction || "Cold chain violation or extreme route delay detected.",
          severity: riskData.riskLevel,
          status: "open",
          factors: riskData.topFactors || [],
          predictionId: predictionId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Update active shipment document with current risk status
        if (riskData.shipmentId) {
          await db.collection("shipments").doc(riskData.shipmentId).set({
            overallRisk: riskData.overallRisk,
            riskLevel: riskData.riskLevel,
            spoilageRisk: riskData.spoilageRisk,
            delayMinutes: riskData.delayMinutes || 0,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });
        }

        // Send FCM notification topic broadcast
        const payload: admin.messaging.MessagingPayload = {
          notification: {
            title: `⚠️ Cold Chain Alert: ${riskData.riskLevel}`,
            body: `Batch ${riskData.batchId} risk score reached ${Math.round(riskData.overallRisk)}/100. Action required!`,
            sound: "default",
          },
          data: {
            batchId: String(riskData.batchId),
            shipmentId: String(riskData.shipmentId || ""),
            riskLevel: String(riskData.riskLevel),
          },
        };

        await messaging.sendToTopic("critical_alerts", payload);
        console.log(`Alert and push notification dispatched for prediction ${predictionId}`);
      } catch (error) {
        console.error(`Error in onRiskThresholdExceeded:`, error);
      }
    }
  });

/**
 * 3. Event trigger when shipment status transitions
 * - Logs traceability event when status changes to 'in_transit' or 'delivered'
 * - Updates corresponding crop_batch document status
 */
export const onShipmentStatusChanged = functions.firestore
  .document("shipments/{shipmentId}")
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    const shipmentId = context.params.shipmentId;

    if (beforeData.status !== afterData.status) {
      try {
        const stage = afterData.status === "delivered" ? "destination_hub" : "transport";
        const type = afterData.status === "delivered" ? "shipment_delivered" : "transit_checkpoint";

        // Create traceability log event
        await db.collection("batch_events").add({
          batchId: afterData.batchId,
          shipmentId: shipmentId,
          stage: stage,
          type: type,
          location: afterData.currentLocation || afterData.destination,
          temperature: afterData.temperature || 20.0,
          humidity: afterData.humidity || 65.0,
          performedBy: afterData.transporterId || "transporter",
          role: "transporter",
          description: `Shipment status updated from ${beforeData.status} to ${afterData.status}.`,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Mirror status to crop_batch
        if (afterData.batchId) {
          await db.collection("crop_batches").doc(afterData.batchId).set({
            currentStatus: afterData.status,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });
        }

        console.log(`Shipment ${shipmentId} transitioned to ${afterData.status}`);
      } catch (error) {
        console.error(`Error updating shipment status lifecycle for ${shipmentId}:`, error);
      }
    }
  });
