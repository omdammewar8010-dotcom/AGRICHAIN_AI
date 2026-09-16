"""
🌾 AgriChain AI - Hackathon Interactive Simulation Runner
Simulates the live 165 km transit from Sahyadri Agro Farm (Nashik) to APMC Market (Vashi, Mumbai).
Can inject real-time anomalies (temperature spikes, humidity shifts, route delay, IoT failure)
and stream live state to FastAPI and Firebase RTDB.
"""

import time
import sys
import requests

API_BASE = "http://127.0.0.1:8000/api/v1/simulation"


def print_banner():
    print("=" * 70)
    print(" 🌾 AgriChain AI - Live Hackathon Simulation Engine")
    print(" Route: Nashik Farm -> Kasara Ghat -> APMC Market Vashi (165 km)")
    print(" Philosophy: DETECT -> PREDICT -> EXPLAIN -> OPTIMIZE -> ACT -> TRACE")
    print("=" * 70)


def get_status():
    try:
        r = requests.get(f"{API_BASE}/status")
        return r.json()
    except Exception as e:
        print(f"Error connecting to FastAPI simulation endpoint: {e}")
        return None


def print_state(state):
    if not state:
        return
    telem = state["telemetry"]
    risk = state["mlRisk"]
    print(f"\n📍 Location: {state['currentWaypoint']} (Step {state['step']+1}/{state['totalSteps']})")
    print(f"   🌡️ Temp: {telem['temperature']}°C | 💧 Hum: {telem['humidity']}% | 🚗 Speed: {telem['speed']} km/h | 🔋 Bat: {telem['battery']}%")
    print(f"   ⚠️ Risk: {risk['overallRisk']}/100 [{risk['riskLevel']}] | Spoilage: {risk['spoilageRisk']}% | Delay: {risk['delayRisk']}%")
    print(f"   💡 Action: {risk['recommendedAction']}")
    if risk.get("topFactors"):
        top = risk["topFactors"][0]
        print(f"   🔍 Primary XAI Factor: {top['factor']} ({top['impact']}%)")


def run_interactive():
    print_banner()
    while True:
        state = get_status()
        print_state(state)
        print("\nCommands:")
        print(" [s] Next transit step along corridor")
        print(" [t] Inject Temperature Spike (33.2°C Reefer Failure)")
        print(" [h] Inject Humidity Spike (94.0% Excess Moisture)")
        print(" [d] Inject Route Delay (+75 min traffic blockade)")
        print(" [f] Inject IoT Battery Failure (6% battery)")
        print(" [n] Reset to Normal Optimal Conditions")
        print(" [q] Quit")

        choice = input("\nSelect Action > ").strip().lower()
        if choice == "s":
            r = requests.post(f"{API_BASE}/step")
        elif choice == "t":
            requests.post(f"{API_BASE}/inject", json={"anomalyType": "temp_spike", "magnitude": 33.2})
            print("\n🚨 [ALERT] Injected Temperature Spike: 33.2°C!")
        elif choice == "h":
            requests.post(f"{API_BASE}/inject", json={"anomalyType": "humidity_spike", "magnitude": 94.0})
            print("\n💧 [ALERT] Injected Humidity Spike: 94.0%!")
        elif choice == "d":
            requests.post(f"{API_BASE}/inject", json={"anomalyType": "route_delay", "magnitude": 75.0})
            print("\n⏱️ [ALERT] Injected Highway Traffic Delay: +75 minutes!")
        elif choice == "f":
            requests.post(f"{API_BASE}/inject", json={"anomalyType": "iot_failure"})
            print("\n🔋 [ALERT] Injected Low Battery & Device Warning!")
        elif choice == "n":
            requests.post(f"{API_BASE}/inject", json={"anomalyType": "normal"})
            print("\n✅ Reset to normal optimal operating conditions.")
        elif choice == "q":
            break
        time.sleep(0.5)


if __name__ == "__main__":
    run_interactive()
