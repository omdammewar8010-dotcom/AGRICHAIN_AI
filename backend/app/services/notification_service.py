import logging
from typing import Optional, Dict, Any
from firebase_admin import messaging

logger = logging.getLogger("agrichain.notifications")


class NotificationService:
    @staticmethod
    def send_risk_alert_push(
        batch_id: str,
        risk_score: float,
        risk_level: str,
        title: str,
        body: str,
        fcm_token: Optional[str] = None
    ) -> bool:
        """
        Sends an FCM push notification for high or critical risk events.
        If fcm_token is supplied, sends to specific device; otherwise publishes to 'critical_alerts' topic.
        """
        try:
            notification = messaging.Notification(
                title=title,
                body=body,
            )
            data_payload = {
                "batchId": str(batch_id),
                "riskScore": str(round(risk_score, 1)),
                "riskLevel": str(risk_level),
                "click_action": "FLUTTER_NOTIFICATION_CLICK"
            }

            if fcm_token:
                message = messaging.Message(
                    notification=notification,
                    data=data_payload,
                    token=fcm_token
                )
            else:
                message = messaging.Message(
                    notification=notification,
                    data=data_payload,
                    topic="critical_alerts"
                )

            response = messaging.send(message)
            logger.info(f"FCM notification sent successfully: {response}")
            return True
        except Exception as e:
            logger.warning(f"Could not send FCM notification (likely running in demo/offline mode): {e}")
            return False


notification_service = NotificationService()
