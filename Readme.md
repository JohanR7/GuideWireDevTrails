# Resilience Engine: AI-Powered Parametric Income Protection for India's Food Delivery Workforce

## Project Overview

The Resilience Engine is an AI-native parametric insurance platform purpose-built to protect the livelihoods of food delivery partners operating on platforms such as Swiggy and Zomato. In an environment where extreme weather events, civic disruptions, and environmental degradation can erode 20–30% of a delivery partner's monthly income, traditional insurance models are ill-suited to respond. Their high administrative overhead and slow claims cycles make them structurally incompatible with the weekly income rhythms and day-to-day financial realities of gig workers.

The Resilience Engine addresses this gap through a high-frequency, weekly premium model powered by automated parametric triggers, enabling near-instant financial relief when a covered disruption occurs. The platform insures against loss of income—not physical assets, health, life, accidents, or vehicle damage—making it a focused and compliant financial safety net for the delivery workforce.

---

## Target Persona: The Food Delivery Partner

The primary beneficiary of this platform is the food delivery partner working within India's tier-1 urban centres. This demographic is the operational core of platforms like Swiggy and Zomato, yet remains among the most financially exposed segments of the workforce.

**Key Characteristics:**

- Approximately 40% of food delivery partners earn below Rs. 15,000 per month.
- Income is highly variable and directly tied to hours logged and orders completed.
- Workers typically operate in a cash-in-hand mode with minimal financial buffers.
- They are acutely sensitive to external disruptions that prevent active delivery.

**Coverage Scope — Income Loss Only:**

This platform exclusively covers loss of income arising from external disruptions. The following are explicitly excluded from all coverage:

- Health and medical expenses
- Life insurance or accidental death benefits
- Accident-related injury claims
- Vehicle repair or asset damage

---

## Covered Disruptions

The following disruption categories represent the primary external triggers for income loss among Swiggy and Zomato delivery partners. These are not exhaustive; the risk model is designed to accommodate additional parameters as data matures.

| Disruption Category | Specific Triggers | Income Impact |
|---|---|---|
| Environmental | Extreme heat (above 42°C), heavy rainfall (above 50mm/hour), severe flooding, hazardous air quality (AQI above 400) | 20–30% reduction in monthly income; full halt to deliveries in affected zones |
| Social | Unplanned civic curfews, localised political strikes, sudden closure of commercial markets or delivery zones | Total loss of daily wages for the duration of the disruption |
| Technical | Platform application outages, cloud service failures affecting order dispatch | Inability to accept or fulfil orders during peak demand windows |

---

## Financial and Actuarial Model

### Weekly Premium Structure

Premiums are calculated and charged on a weekly basis, deliberately aligned with the payout cycles typical of gig platforms. This structure ensures that protection renews in step with how workers earn and spend, reducing the cognitive and financial friction of participation.

Premiums are not static. Each weekly calculation incorporates hyper-local risk factors and the individual worker's behavioural and telematics profile. The predicted claim intensity for a worker *i* at week *t* is modelled as:

```
P_it = P_base,i * exp(B_it^T * alpha + C_it^T * gamma)
```

Where:
- `P_base,i` is the baseline premium derived from the worker's delivery zone and historical activity profile.
- `B_it` is a vector of telematics-based risk factors, such as the frequency of deliveries in flood-prone or heat-exposed zones.
- `C_it` is a vector of environmental forecasts for the upcoming week, sourced from verified meteorological feeds.

A modified Poisson model governs claim frequency, allowing the system to price risk dynamically rather than relying on static actuarial tables that would quickly become obsolete in India's rapidly changing urban climate.

### Funding Mechanism: Tip-Based Micro-Insurance

To maximise participation without placing the full burden of premium payments on workers earning below Rs. 15,000 per month, the platform supports a tip-based funding model. A defined percentage—typically 20%—of customer tips or a mandated platform handling fee is pooled into a collective insurance fund. This mechanism extends coverage to a significantly larger proportion of the workforce without requiring substantial out-of-pocket contributions from the worker.

### Reinforcement Learning for Premium Optimisation

A Proximal Policy Optimisation (PPO) agent continuously calibrates the premium-to-payout ratio. The agent's reward function monitors three primary objectives:

1. **Surplus Maintenance:** Ensuring the liquidity pool remains solvent across claim cycles.
2. **Customer Lifetime Value:** Keeping weekly premiums affordable enough to prevent voluntary exits from the programme.
3. **Fraud Suppression:** Reducing reward signals when payouts are issued to nodes that carry a high relational risk score.

---

## AI-Powered Risk Assessment

### Dynamic Risk Profiling

Upon onboarding, each delivery partner receives a risk profile constructed from their historical delivery data, zone behaviour, device telemetry, and environmental exposure. This profile is updated continuously and feeds directly into the weekly premium calculation.

The risk profiling engine uses a hybrid Transformer-CNN-LSTM architecture:

- **Convolutional Neural Networks (CNN):** Analyse grid-structured signal power and spectral representations to identify spatial anomalies in positioning data.
- **Long Short-Term Memory (LSTM):** Model the sequential patterns of a worker's trajectory, capturing velocity profiles—acceleration, deceleration at signals, route deviation—that are characteristic of genuine urban delivery work.
- **Transformer Architectures:** Provide long-range contextual awareness, ensuring that a worker's reported movement is globally consistent with the city's current traffic state and environmental conditions.

This hybrid architecture achieves anomaly detection accuracy between 95% and 99.99%.

---

## Adversarial Defense and Anti-Spoofing Strategy

### The Threat

Following confirmed exploitation of parametric insurance platforms by coordinated fraud syndicates—specifically, groups of delivery workers using GPS-spoofing applications to simulate presence in high-risk zones while remaining at home—the Resilience Engine incorporates a dedicated, multi-layered adversarial defense architecture. Basic GPS verification is treated as an insufficient and obsolete signal for claim validation.

### 1. The Differentiation: Multi-Modal Contextual Validation

The Resilience Engine does not rely on a single location signal. Instead, it validates the **physical coherence** of the device's entire reported environment. A spoofing application typically overrides location data at the Android software layer (the Location Provider API) but cannot simultaneously fabricate the full spectrum of environmental sensor readings that would correspond to a genuine outdoor environment in a specific urban zone.

The core instrument of this differentiation is the **GPS Drift Index (GDI)**, which quantifies spatial inconsistency across independent positioning sources:

```
GDI_i = sqrt((lat_x,i - lat_y,i)^2 + (lon_x,i - lon_y,i)^2 + (alt_x,i - alt_y,i)^2)
```

Where `lat`, `lon`, and `alt` are derived from two independent sensors (x and y). A moving average with window size `w = 5` smooths the index to reduce noise:

```
GDI_smooth(i) = (1/w) * SUM[j=i-w+1 to i] GDI(j)
```

Genuine delivery movement in cities such as Mumbai or Delhi exhibits a stable, low-variance GDI. Spoofing attempts manifest as abrupt spikes and right-skewed distributions with high-drift outliers, since the attacker cannot perfectly synchronise fabricated GPS signals with independent sources such as cellular tower triangulation or Wi-Fi Round-Trip Time (RTT).

### 2. The Data: High-Dimensional Sensor Fusion

The system analyses between 49 and 84 telemetry attributes per session. These extend far beyond GPS coordinates and focus on the physical footprint of the delivery partner in their claimed environment.

**Physical and Environmental Sensors:**

| Sensor | Data Point | Role in Fraud Detection |
|---|---|---|
| Inertial Measurement Unit (IMU) | Accelerometer and gyroscope readings | A motorbike in heavy rain or wind produces a specific vibrational signature. A static indoor device shows unnatural stillness or synthetic jitter that lacks the stochastic character of real road surfaces. |
| Barometer | Atmospheric pressure | Validates weather-based triggers. Pressure drops during storms are measurable and must correspond to reported zone conditions. |
| Ambient Light Sensor | Lux levels | Distinguishes indoor from outdoor environments. A worker claiming to be caught in a downpour should not show indoor-constant lighting levels. |
| Magnetometer | Magnetic field intensity | Detects the ferromagnetic interference characteristic of indoor structures, flagging workers who claim to be outdoors. |
| GSM / Cellular Module | Signal Strength (RSSI) | Tower signal patterns can identify deep-indoor environments with high accuracy, contradicting claims of outdoor presence. |

**Network and Telemetry Signals:**

The platform monitors network-layer attributes to identify the use of VPNs, proxies, or device emulators—tools commonly employed for location manipulation. Advanced device fingerprinting generates a stable identifier that persists even if the user rotates their IP address or clears application data.

A **Proof of Location (PoL)** mechanism is implemented using network latency measurements. The device must respond to UDP pings from a set of known-location validator nodes. By computing a latency-to-distance mapping, the system can cryptographically confirm that the device is physically present within the claimed region, independent of what the GPS reports.

**Signal Layer Observables:**

For high-stakes claims, the platform accesses raw GNSS observables—specifically the Carrier-to-Noise Density (C/N0) time series. During a spoofing attack, the C/N0 values across multiple satellites become highly cross-correlated, because they are generated by a single localised source rather than disparate satellites in orbit. A cross-correlation analysis using Pearson's coefficients can raise a spoofing alarm within five seconds, with a false alarm probability as low as 1.5%.

**Graph Neural Networks for Ring Detection:**

A coordinated fraud syndicate is a relational problem, not merely an individual anomaly. The platform models the entire delivery ecosystem as a dynamic, heterogeneous graph:

- **Nodes:** Workers, Devices, IP Addresses, Bank Accounts, Merchant Locations.
- **Edges:** Transactions, Shared Device Logs, Proximity Events, Joint Claim Triggers.

Fraud rings form statistically improbable dense subgraphs within this graph. The Graph Neural Network (GNN) uses message-passing mechanisms (1-hop and 2-hop) to allow each worker node to learn from the behaviour of its network neighbours. If a worker's device has been previously associated with a flagged account, or if multiple workers simultaneously trigger claims from the same residential IP range, the GNN assigns an elevated Relational Risk Score, escalating the claim for review.

### 3. The UX Balance: Handling Flagged Claims Without Penalising Honest Workers

A fundamental design principle of the Resilience Engine is that the anti-spoofing architecture must never become an instrument of unjust denial for genuine workers. A delivery partner caught in a severe weather event may experience a network drop, degraded sensor readings, or semi-outdoor conditions (such as sheltering under a flyover) that could superficially resemble spoofing signals.

The platform manages this uncertainty through a Bayesian reasoning framework and a tiered workflow:

**Tier 1 — Instant Payout (High Trust):**
Workers with a sustained history of verified activity and a high sensor-coherence score receive automatic payouts, processed instantly via smart contract. Example notification: *"Your income for the next 4 hours is protected due to severe rain. Payout of Rs. 200 sent to your wallet."*

**Tier 2 — Asynchronous Integrity Monitoring (Medium Risk / Network Drop):**
If a network outage occurs during a weather event, the mobile SDK does not immediately flag the claim as fraudulent. Instead, it stores encrypted, timestamped sensor packets in a local secure enclave and uploads them once connectivity is restored. This prevents honest workers in connectivity-degraded zones from being unfairly penalised.

**Tier 3 — Friction-Aware Step-Up Verification (Elevated Risk):**
When a claim is flagged, the worker is not presented with a denial screen. Instead, the interface uses Explainable AI (XAI) to communicate transparently: *"Your environmental data suggests you may currently be indoors. To complete your claim, please provide a 5-second live video of your surroundings."* This creates a clear and dignified pathway for workers in ambiguous environments to validate their position.

Every flag is accompanied by a transparent rationale generated using SHAP values. Auditors can inspect the exact features driving a decision—such as "High GDI Variance" or "Inconsistent Ambient Light"—eliminating the black-box problem and supporting regulatory compliance.

**Differentiable Architecture Search (DARTS) for Edge Inference:**
Because many delivery partners use budget Android smartphones with limited processing capacity, spoofing detection is performed on-device using compact neural architectures generated through Differentiable Architecture Search. This ensures that detection happens locally before a fraudulent claim is even initiated, reducing both false positives and server-side load.

---

## Parametric Automation and Claims Workflow

The end-to-end claims experience is designed to be zero-touch for the worker during a crisis.

**Step 1 — Trigger Detection:**
A city-wide disruption (for example, heavy rainfall exceeding 50mm in Zone A) is detected by the decentralised oracle network, which aggregates data from the India Meteorological Department (IMD) and verified secondary sources.

**Step 2 — Automated Triage:**
The system identifies all insured, active delivery partners within the affected zone.

**Step 3 — Adversarial Audit (Three Layers):**
- The Signal Layer checks for GNSS cross-correlation anomalies.
- The Context Layer verifies that the device's barometer and ambient light readings are consistent with the reported storm conditions.
- The Relational Layer (GNN) evaluates whether the worker belongs to a newly formed payout-seeking cluster.

**Step 4 — Decision and Payout:**
- Trust Score above 0.9: Instant payout via smart contract.
- Trust Score below 0.7: Step-up verification is requested (biometric liveness check or a location-tagged photograph).

---

## Technical Architecture

### Decentralised Infrastructure

| Component | Role |
|---|---|
| Smart Contracts (Hyperledger Fabric) | Automates policy issuance and claim settlement with a tamper-proof audit trail. |
| Decentralised Oracles (Chainlink) | Feeds verified real-world weather and AQI data into smart contracts, ensuring the trigger is independent of both insurer and insured. |
| Proof of Location (Witness Chain / DePIN) | Latency-based verification confirming a device's physical coordinates, independent of GPS. |

### Tech Stack

| Layer | Component | Implementation |
|---|---|---|
| Mobile SDK | Android / Kotlin | Raw GNSS Observable API, Sensor Fusion via Fused Location Provider |
| Security | PRESENT-128 | Lightweight block cipher in CBC mode for on-device telemetry encryption |
| ML Engine | NVIDIA RAPIDS / H2O | Accelerated GNN and Gradient Boosting (XGBoost) for real-time risk scoring; hybrid Transformer-CNN-LSTM architecture for anomaly detection and risk profiling |
| On-Device Inference | DARTS (Differentiable Architecture Search) | Auto-generates compact neural architectures optimised for real-time spoofing detection on budget Android smartphones |
| Reinforcement Learning | Proximal Policy Optimisation (PPO) | Continuous weekly premium optimisation balancing liquidity solvency, worker affordability, and fraud suppression |
| Oracles | Chainlink / OpenWeatherMap / IMD | Multi-source weather and AQI validation; IMD feeds ingested via Chainlink to minimise basis risk |
| Payments | UPI / Razorpay Sandbox | Instant settlement of lost wages to the worker's digital wallet |
| Backend Framework | Django (Python) | Handles API requests between the mobile SDK, ML scoring engine, oracle feeds, and payment layer; exposes REST endpoints for policy issuance, claim initiation, and trust score retrieval |
| Database | PostgreSQL | Persistent storage for worker profiles, policy records, premium history, and claim audit logs |
| Cloud Infrastructure | AWS (EC2 / EKS / S3) | Hosts the backend services, ML engine, and Kafka cluster; S3 for secure enclave packet storage; EKS for containerised microservice orchestration |
| API Gateway | AWS API Gateway | Manages traffic, authentication, and rate limiting between the mobile application and backend microservices |
| Containerisation | Docker / Kubernetes | Ensures consistent deployment of ML models, backend services, and oracle connectors across environments |


---

## Integration Capabilities

- **Weather APIs:** IMD data feeds via Chainlink oracles; OpenWeatherMap as a secondary validation source.
- **Traffic Data:** City-level traffic state feeds used to validate trajectory coherence in the Transformer model.
- **Platform APIs:** Simulated integration with Swiggy and Zomato order management systems for active-session validation.
- **Payment Systems:** UPI and Razorpay sandbox for instant wallet disbursement.

---

## Analytics Dashboard

The platform provides a real-time analytics dashboard for operations teams and actuarial review, surfacing the following metrics:

- Weekly claim volume by disruption category and zone.
- Liquidity pool balance and projected solvency horizon.
- Fraud detection rate and false positive rate, segmented by trust tier.
- Average claim settlement time (target: under 10 minutes for parametric triggers).
- Worker retention and premium collection rates by cohort.
- GNN Relational Risk Score distribution across the active worker network.
- SHAP feature importance summaries for auditable claim decisions.

---

## Operational Targets

| Metric | Target | Basis |
|---|---|---|
| Claim Settlement Time | Under 10 minutes (parametric) | Instant payouts versus the weeks typical of traditional indemnity claims |
| Fraud Detection Accuracy | Above 99% | Multi-layered hybrid model and sensor fusion significantly outperform rule-based systems |
| Operational Cost Reduction | 20–30% | Automation of manual reconciliation and claims handling via blockchain |
| Income Protection Coverage | 100% of covered disruption hours | Safeguarding the 20–30% of income typically lost to environmental and social disruptions |

---

## Future Outlook

As the adversarial landscape evolves, more sophisticated spoofing attacks will attempt to mimic genuine environmental sensor noise. The Resilience Engine's next phase of development will incorporate **Behavioural Biometrics** as a continuous passive authentication layer. Each delivery partner has a unique digital signature in the way they interact with their device—the angle at which they hold their phone while riding, their screen-swipe patterns, and the pressure they apply during task completion. Building a mathematical model of these passive biometrics will make account takeover and automated spoofing attempts structurally impractical, without introducing any additional friction for the legitimate worker.

The Resilience Engine is not solely a fraud prevention tool. It is a foundational layer for a more equitable gig economy—one where the financial burden of climate change and urban volatility is distributed across platforms, customers, and insurers, rather than falling entirely on the shoulders of the delivery partner.

---

## Works Cited

1. Market Crash Scenario — Phase 1 internal document.
2. Take-up and Impacts of Parametric Insurance for Labor Supply under Climate Change. Poverty Action Lab. https://www.povertyactionlab.org/initiative-project/take-and-impacts-parametric-insurance-labor-supply-under-climate-change
3. GigZo: Protecting India's Delivery Workforce with AI-Powered Parametric Insurance. Medium, March 2026. https://medium.com/@abhinavpreet/gigzo-protecting-indias-delivery-workforce-with-ai-powered-parametric-insurance-5c161aa6deee
4. Advancing GPS Spoofing Detection for Autonomous Vehicles through Deep Learning and Hybrid Architectures. ResearchGate. https://www.researchgate.net/publication/396657332
5. Multi-Layer AI Sensor System for Real-Time GPS Spoofing Detection. PMC. https://pmc.ncbi.nlm.nih.gov/articles/PMC12899299/
6. Mobile User Indoor-Outdoor Detection through Physical Daily Activities. PMC. https://pmc.ncbi.nlm.nih.gov/articles/PMC6387420/
7. Device Fingerprinting and User Tracking. Veratad API Documentation. https://api.veratad.com/vx/device-fingerprinting
8. Verifying the Physical World: Witness Chain and Proof of Location on EigenCloud. https://blog.eigencloud.xyz/verifying-the-physical-world/
9. Detecting GNSS Jamming and Spoofing on Android Devices. ResearchGate. https://www.researchgate.net/publication/363424347
10. Graph Neural Networks for Real-Time Financial Fraud Detection. ResearchGate. https://www.researchgate.net/publication/397588550
11. How Explainable AI (XAI) Can Enhance Trust in Insurance Claims UX. f1Studioz. https://f1studioz.com/blog/how-explainable-ai-xai-can-enhance-trust-in-insurance-claims-ux/
12. Decentralised Insurance Protocol: Transforming Risk Management Through Blockchain Technology. OpenCover. https://opencover.com/learn-and-resources/transforming-risk-management/
13. Tip-Based Micro-Insurance for Gig Workers. AWS / Insuring the Invisibles. https://iai-files.s3.ap-south-1.amazonaws.com/assets/files/articles/insuring_the_invisibles.pdf
14. A Hybrid Framework for Reinsurance Optimisation: Integrating Generative Models and Reinforcement Learning. arXiv. https://arxiv.org/html/2501.06404v1
15. What Is Behavioral Biometrics. IBM. https://www.ibm.com/think/topics/behavioral-biometrics