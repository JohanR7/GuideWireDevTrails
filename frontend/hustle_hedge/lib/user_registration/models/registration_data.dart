class RegistrationData {
  String? fullName;
  String? residentialAddress;
  String? deliveryPartnerId;
  String? platform;           // swiggy / zomato
  String? dateOfBirth;
  String? aadharNumber;
  String? vehicleType;
  String? drivingLicense;
  String? hadLateDelivery;    // yes / no
  String? lateDeliveryCount;
  String? weeklyIncome;
  String? hasOtherJobs;
  String? otherJobsDescription;

  RegistrationData();

  void setAnswer(String questionId, String value) {
    switch (questionId) {
      case 'full_name':
        fullName = value;
        break;
      case 'residential_address':
        residentialAddress = value;
        break;
      case 'delivery_partner_id':
        deliveryPartnerId = value;
        break;
      case 'platform':
        platform = value;
        break;
      case 'dob':
        dateOfBirth = value;
        break;
      case 'aadhar':
        aadharNumber = value;
        break;
      case 'vehicle_type':
        vehicleType = value;
        break;
      case 'driving_license':
        drivingLicense = value;
        break;
      case 'late_delivery':
        hadLateDelivery = value;
        break;
      case 'late_delivery_count':
        lateDeliveryCount = value;
        break;
      case 'weekly_income':
        weeklyIncome = value;
        break;
      case 'has_other_jobs':
        hasOtherJobs = value;
        break;
      case 'other_jobs_description':
        otherJobsDescription = value;
        break;
    }
  }

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'residential_address': residentialAddress,
        'delivery_partner_id': deliveryPartnerId,
        'platform': platform,
        'date_of_birth': dateOfBirth,
        'aadhar_number': aadharNumber,
        'vehicle_type': vehicleType,
        'driving_license': drivingLicense,
        'had_late_delivery': hadLateDelivery,
        'late_delivery_count': lateDeliveryCount,
        'weekly_income': weeklyIncome,
        'has_other_jobs': hasOtherJobs,
        'other_jobs_description': otherJobsDescription,
      };
}