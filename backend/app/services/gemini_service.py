import logging
from datetime import datetime, timezone
from typing import Dict, Any, List
import google.generativeai as genai

from app.config import settings
from app.models.ai import AIChatRequest, AIChatResponse, ShipmentContext

logger = logging.getLogger("agrichain.ai.gemini")


class GeminiAgriAssistant:
    def __init__(self):
        self.api_key = settings.GEMINI_API_KEY
        self.model = None
        if self.api_key:
            try:
                genai.configure(api_key=self.api_key)
                self.model = genai.GenerativeModel("gemini-1.5-flash")
                logger.info("Google Gemini 1.5 Flash initialized successfully.")
            except Exception as e:
                logger.warning(f"Could not configure Gemini client: {e}. Fallback knowledge engine active.")
        else:
            logger.info("No GEMINI_API_KEY detected. Running with built-in Agricultural Agronomic Knowledge Engine.")

    async def answer_query(self, req: AIChatRequest) -> AIChatResponse:
        ctx = req.context or ShipmentContext()

        # Build domain grounding context
        grounding_prompt = (
            f"You are AgriChain AI, an expert agricultural supply chain diagnostic assistant. "
            f"Ground your answer STRICTLY in the following real-time telemetry:\n"
            f"- Batch ID: {ctx.batchId or 'N/A'}\n"
            f"- Crop Name: {ctx.cropName}\n"
            f"- Current Temperature: {ctx.currentTemperature}°C (Safe Range: {ctx.preferredTempMin}°C to {ctx.preferredTempMax}°C)\n"
            f"- Current Humidity: {ctx.currentHumidity}%\n"
            f"- Route Delay: +{ctx.delayMinutes} minutes\n"
            f"- Predicted Risk Score: {ctx.riskScore}/100 ({ctx.riskLevel})\n"
            f"- Current Location: {ctx.currentLocation}\n"
            f"- Final Destination: {ctx.destination}\n\n"
            f"User Question: {req.message}\n"
            f"Provide a clear, authoritative, and actionable diagnostic response. "
            f"Explain physiological impacts on the crop and provide practical next steps."
        )

        if self.model:
            try:
                response = self.model.generate_content(grounding_prompt)
                reply_text = response.text
                return self._format_response(reply_text, ctx)
            except Exception as e:
                logger.error(f"Gemini API call failed: {e}. Using expert fallback.")

        # Expert deterministic knowledge engine fallback
        return self._expert_fallback(req.message, ctx)

    def _expert_fallback(self, query: str, ctx: ShipmentContext) -> AIChatResponse:
        q = query.lower()
        temp_excess = max(0.0, (ctx.currentTemperature or 20.0) - (ctx.preferredTempMax or 22.0))
        delay = ctx.delayMinutes or 0.0

        if "why" in q and "risk" in q:
            reply = (
                f"Batch {ctx.batchId or 'in transit'} is currently classified as {ctx.riskLevel} (Risk: {ctx.riskScore}/100) "
                f"primarily because the container temperature is {ctx.currentTemperature}°C, which is +{temp_excess:.1f}°C "
                f"above the optimal upper threshold for {ctx.cropName} ({ctx.preferredTempMax}°C). "
                f"Furthermore, a transit delay of +{int(delay)} minutes has prolonged thermal exposure, accelerating respiration "
                f"and ethylene gas accumulation."
            )
            key_takeaways = [
                f"Refrigeration excursion of +{temp_excess:.1f}°C above maximum allowable limit.",
                f"Cumulative delay of {int(delay)} minutes depleting remaining shelf-life buffer.",
                "Ethylene accumulation hazard threatening premature ripening."
            ]
            actions = [
                "Adjust reefer thermostat down immediately and inspect door seals.",
                "Divert to closest cold hub if arrival cannot be completed within 60 minutes."
            ]
        elif "delay" in q or "traffic" in q:
            reply = (
                f"The shipment has incurred a {int(delay)} minute delay along the corridor near {ctx.currentLocation}. "
                f"This delay reduces the effective freshness window of {ctx.cropName} by approximately 18%."
            )
            key_takeaways = [
                f"Traffic delay: +{int(delay)} minutes near {ctx.currentLocation}.",
                f"Arrival rescheduled for {ctx.destination}."
            ]
            actions = [
                "Activate alternative expressway corridor to bypass local congestion.",
                "Notify destination warehouse manager to prepare for priority rapid unloading."
            ]
        elif "action" in q or "transporter" in q or "what should" in q:
            reply = (
                f"Recommended immediate action protocol for {ctx.cropName}:\n"
                f"1. Transporter must verify vehicle auxiliary alternator power powering the refrigeration unit.\n"
                f"2. If temperature remains above {ctx.preferredTempMax}°C for more than 30 minutes, utilize the route "
                f"optimizer to divert to the nearest registered cold warehouse.\n"
                f"3. Maintain constant speed above 45 km/h to promote airflow through condenser coils."
            )
            key_takeaways = [
                "Immediate auxiliary power check required.",
                "Prepare diversion to emergency cold storage if cooling is not restored."
            ]
            actions = [
                "Check reefer compressor power switch.",
                "Notify dispatch control room."
            ]
        else:
            reply = (
                f"Regarding your inquiry for {ctx.cropName} batch {ctx.batchId or 'in transit'}: "
                f"The cargo is currently located at {ctx.currentLocation}, moving towards {ctx.destination}. "
                f"Monitored conditions show {ctx.currentTemperature}°C and {ctx.currentHumidity}% relative humidity. "
                f"Overall health assessment is {ctx.riskLevel} with a risk index of {ctx.riskScore}/100."
            )
            key_takeaways = [
                f"Current temperature: {ctx.currentTemperature}°C",
                f"Location: {ctx.currentLocation}",
                f"Status: {ctx.riskLevel}"
            ]
            actions = [
                "Maintain scheduled route monitoring.",
                "Review live telemetry graph on dashboard."
            ]

        return AIChatResponse(
            reply=reply,
            keyTakeaways=key_takeaways,
            suggestedActions=actions,
            timestamp=datetime.now(timezone.utc).isoformat(),
        )

    def _format_response(self, text: str, ctx: ShipmentContext) -> AIChatResponse:
        return AIChatResponse(
            reply=text,
            keyTakeaways=[
                f"Cargo: {ctx.cropName} at {ctx.currentTemperature}°C",
                f"Risk state: {ctx.riskLevel} ({ctx.riskScore}/100)",
                f"Location: {ctx.currentLocation}"
            ],
            suggestedActions=[
                "Verify reefer cooling efficiency",
                "Evaluate optimized bypass routes"
            ],
            timestamp=datetime.now(timezone.utc).isoformat(),
        )


gemini_assistant = GeminiAgriAssistant()
