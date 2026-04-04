import 'package:intl/intl.dart';

// ──────────────────────────────────────────────────────────────────────────
// User & Auth Models
// ──────────────────────────────────────────────────────────────────────────

class User {
  final String id;
  final String fullName;
  final String mobile;
  final String? email;
  final String? city;
  final String? aadhaar;
  final String? pan;
  final bool mobileVerified;

  User({
    required this.id,
    required this.fullName,
    required this.mobile,
    this.email,
    this.city,
    this.aadhaar,
    this.pan,
    this.mobileVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'],
      city: json['city'],
      aadhaar: json['aadhaar'],
      pan: json['pan'],
      mobileVerified: json['mobile_verified'] ?? json['mobileVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'mobile': mobile,
    'email': email,
    'city': city,
    'aadhaar': aadhaar,
    'pan': pan,
    'mobile_verified': mobileVerified,
  };
}

class WorkerProfile {
  final String id;
  final String userId;
  final String platform; // SWIGGY or ZOMATO
  final String partnerId;
  final double weeklyIncome;
  final String riskZone; // Z1, Z2, Z3, Z4
  final String? drivingLicense;
  final List<String>? zones;

  WorkerProfile({
    required this.id,
    required this.userId,
    required this.platform,
    required this.partnerId,
    required this.weeklyIncome,
    required this.riskZone,
    this.drivingLicense,
    this.zones,
  });

  factory WorkerProfile.fromJson(Map<String, dynamic> json) {
    return WorkerProfile(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      platform: json['platform'] ?? '',
      partnerId: json['partner_id'] ?? json['partnerId'] ?? '',
      weeklyIncome: (json['weekly_income'] ?? json['weeklyIncome'] ?? 0).toDouble(),
      riskZone: json['risk_zone'] ?? json['riskZone'] ?? 'Z1',
      drivingLicense: json['driving_license'] ?? json['drivingLicense'],
      zones: List<String>.from(json['zones'] ?? []),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Plan Models
// ──────────────────────────────────────────────────────────────────────────

class Plan {
  final String id;
  final String tier; // ESSENTIAL, STANDARD, PREMIUM
  final String name;
  final String tagline;
  final double monthlyPrice;
  final double workerContribution;
  final double subsidy;
  final double maxPayout;
  final List<String> coverage;
  final bool isActive;

  Plan({
    required this.id,
    required this.tier,
    required this.name,
    required this.tagline,
    required this.monthlyPrice,
    required this.workerContribution,
    required this.subsidy,
    required this.maxPayout,
    required this.coverage,
    required this.isActive,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    List<String> parseCoverage(dynamic coverage) {
      if (coverage is List) {
        return List<String>.from(coverage);
      } else if (coverage is String) {
        return coverage.split(',').map((e) => e.trim()).toList();
      }
      return [];
    }

    return Plan(
      id: json['id'] ?? '',
      tier: json['tier'] ?? '',
      name: json['name'] ?? '',
      tagline: json['tagline'] ?? '',
      monthlyPrice: (json['monthly_price'] ?? json['monthlyPrice'] ?? 0).toDouble(),
      workerContribution: (json['worker_contribution'] ?? json['workerContribution'] ?? 0).toDouble(),
      subsidy: (json['subsidy'] ?? 0).toDouble(),
      maxPayout: (json['max_payout'] ?? json['maxPayout'] ?? 0).toDouble(),
      coverage: parseCoverage(json['coverage']),
      isActive: json['is_active'] ?? json['isActive'] ?? true,
    );
  }

  String get displayPrice => '₹${monthlyPrice.toStringAsFixed(0)}/mo';
}

// ──────────────────────────────────────────────────────────────────────────
// Policy Models
// ──────────────────────────────────────────────────────────────────────────

class Policy {
  final String id;
  final String userId;
  final String planId;
  final Plan plan;
  final String status; // ACTIVE, LAPSED, CANCELLED
  final DateTime effectiveDate;
  final DateTime? renewalDate;
  final int claimsUsed;
  final int claimsLimit;
  final double premiumAmount;
  final String? blockchainTxHash;
  final String? mandateId;
  final String? walletAddress;

  Policy({
    required this.id,
    required this.userId,
    required this.planId,
    required this.plan,
    required this.status,
    required this.effectiveDate,
    this.renewalDate,
    required this.claimsUsed,
    required this.claimsLimit,
    required this.premiumAmount,
    this.blockchainTxHash,
    this.mandateId,
    this.walletAddress,
  });

  factory Policy.fromJson(Map<String, dynamic> json) {
    return Policy(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      planId: json['plan_id'] ?? json['planId'] ?? '',
      plan: Plan.fromJson(json['plan'] ?? {}),
      status: json['status'] ?? 'ACTIVE',
      effectiveDate: DateTime.parse(json['effective_date'] ?? json['effectiveDate'] ?? DateTime.now().toString()),
      renewalDate: json['renewal_date'] != null ? DateTime.parse(json['renewal_date']) : null,
      claimsUsed: json['claims_used'] ?? json['claimsUsed'] ?? 0,
      claimsLimit: json['claims_limit'] ?? json['claimsLimit'] ?? 5,
      premiumAmount: (json['premium_amount'] ?? json['premiumAmount'] ?? 0).toDouble(),
      blockchainTxHash: json['blockchain_tx_hash'] ?? json['blockchainTxHash'],
      mandateId: json['mandate_id'] ?? json['mandateId'],
      walletAddress: json['wallet_address'] ?? json['walletAddress'],
    );
  }

  int get daysUntilRenewal {
    if (renewalDate == null) return 0;
    return renewalDate!.difference(DateTime.now()).inDays;
  }

  String get statusBadge {
    switch (status) {
      case 'ACTIVE':
        return 'Active';
      case 'LAPSED':
        return 'Lapsed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  double get claimsRemaining => (claimsLimit - claimsUsed).toDouble();
}

// ──────────────────────────────────────────────────────────────────────────
// Claim Models
// ──────────────────────────────────────────────────────────────────────────

class Claim {
  final String id;
  final String userId;
  final String policyId;
  final String type; // Accident, ExtremeWeather, Curfew, VehicleDamage
  final String description;
  final DateTime incidentDate;
  final String status; // PENDING, AUDITING, APPROVED, REJECTED
  final double? payoutAmount;
  final String? rejectionReason;
  final double trustScore;
  final DateTime createdAt;
  final String? blockchainTxHash;

  Claim({
    required this.id,
    required this.userId,
    required this.policyId,
    required this.type,
    required this.description,
    required this.incidentDate,
    required this.status,
    this.payoutAmount,
    this.rejectionReason,
    required this.trustScore,
    required this.createdAt,
    this.blockchainTxHash,
  });

  factory Claim.fromJson(Map<String, dynamic> json) {
    return Claim(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      policyId: json['policy_id'] ?? json['policyId'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      incidentDate: DateTime.parse(json['incident_date'] ?? json['incidentDate'] ?? DateTime.now().toString()),
      status: json['status'] ?? 'PENDING',
      payoutAmount: json['payout_amount'] != null ? (json['payout_amount']).toDouble() : null,
      rejectionReason: json['rejection_reason'] ?? json['rejectionReason'],
      trustScore: (json['trust_score'] ?? json['trustScore'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toString()),
      blockchainTxHash: json['blockchain_tx_hash'] ?? json['blockchainTxHash'],
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'PENDING':
        return 'Pending Review';
      case 'AUDITING':
        return 'Under Audit';
      case 'APPROVED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  String get typeDisplay {
    switch (type) {
      case 'Accident':
        return 'Accident';
      case 'ExtremeWeather':
        return 'Extreme Weather';
      case 'Curfew':
        return 'Curfew Disruption';
      case 'VehicleDamage':
        return 'Vehicle Damage';
      default:
        return type;
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Monitoring Models
// ──────────────────────────────────────────────────────────────────────────

class SensorData {
  final double lat;
  final double lng;
  final double speedKmh;
  final double battery;
  final bool isMoving;
  final String weatherCondition;
  final DateTime timestamp;

  SensorData({
    required this.lat,
    required this.lng,
    required this.speedKmh,
    required this.battery,
    required this.isMoving,
    required this.weatherCondition,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
    'speed_kmh': speedKmh,
    'battery': battery,
    'is_moving': isMoving,
    'weather_condition': weatherCondition,
    'timestamp': timestamp.toIso8601String(),
  };
}

enum MonitoringStatus { inactive, active, paused, alert }

class MonitoringState {
  final MonitoringStatus status;
  final DateTime? lastUpdate;
  final String? alertMessage;

  MonitoringState({
    required this.status,
    this.lastUpdate,
    this.alertMessage,
  });
}
