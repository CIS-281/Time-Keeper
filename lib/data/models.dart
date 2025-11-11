// lib/data/models.dart
// Data models with optional companyId support to match the v3 schema.

class JobSite {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final int radiusM;
  final String? companyId;

  JobSite({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusM,
    this.companyId,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'radius_m': radiusM,
    'company_id': companyId,
  };

  factory JobSite.fromMap(Map<String, Object?> m) => JobSite(
    id: (m['id'] as num?)?.toInt(),
    name: m['name'] as String,
    latitude: (m['latitude'] as num).toDouble(),
    longitude: (m['longitude'] as num).toDouble(),
    radiusM: (m['radius_m'] as num).toInt(),
    companyId: m['company_id'] as String?,
  );
}

class Employee {
  final int? id;
  final String fullName;
  final int payRateCents;
  final String? companyId;

  Employee({
    this.id,
    required this.fullName,
    required this.payRateCents,
    this.companyId,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'full_name': fullName,
    'pay_rate_cents': payRateCents,
    'company_id': companyId,
  };

  factory Employee.fromMap(Map<String, Object?> m) => Employee(
    id: (m['id'] as num?)?.toInt(),
    fullName: m['full_name'] as String,
    payRateCents: (m['pay_rate_cents'] as num).toInt(),
    companyId: m['company_id'] as String?,
  );
}

class Job {
  final String id; // UUID string
  final String name;
  final int hourlyRateCents;
  final int lateGraceMins;
  final bool allowAutoClockIn;
  final int? jobSiteId;
  final String? companyId;

  Job({
    required this.id,
    required this.name,
    required this.hourlyRateCents,
    required this.lateGraceMins,
    required this.allowAutoClockIn,
    this.jobSiteId,
    this.companyId,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'hourly_rate_cents': hourlyRateCents,
    'late_grace_mins': lateGraceMins,
    'allow_auto_clock_in': allowAutoClockIn ? 1 : 0,
    'job_site_id': jobSiteId,
    'company_id': companyId,
  };

  factory Job.fromMap(Map<String, Object?> m) => Job(
    id: m['id'] as String,
    name: m['name'] as String,
    hourlyRateCents: (m['hourly_rate_cents'] as num).toInt(),
    lateGraceMins: (m['late_grace_mins'] as num).toInt(),
    allowAutoClockIn: (m['allow_auto_clock_in'] as num) == 1,
    jobSiteId: (m['job_site_id'] as num?)?.toInt(),
    companyId: m['company_id'] as String?,
  );
}

class Shift {
  final String id; // UUID
  final int employeeId;
  final String jobId;
  final int clockInUtc; // seconds
  final int? clockOutUtc; // seconds
  final String status; // 'clocked_in', 'auto_clocked_in', 'on_break', 'clocked_out'
  final double? avgAccuracyM;
  final String? companyId;

  Shift({
    required this.id,
    required this.employeeId,
    required this.jobId,
    required this.clockInUtc,
    this.clockOutUtc,
    required this.status,
    this.avgAccuracyM,
    this.companyId,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'employee_id': employeeId,
    'job_id': jobId,
    'clock_in_utc': clockInUtc,
    'clock_out_utc': clockOutUtc,
    'status': status,
    'avg_accuracy_m': avgAccuracyM,
    'company_id': companyId,
  };

  factory Shift.fromMap(Map<String, Object?> m) => Shift(
    id: m['id'] as String,
    employeeId: (m['employee_id'] as num).toInt(),
    jobId: m['job_id'] as String,
    clockInUtc: (m['clock_in_utc'] as num).toInt(),
    clockOutUtc: (m['clock_out_utc'] as num?)?.toInt(),
    status: m['status'] as String,
    avgAccuracyM: (m['avg_accuracy_m'] as num?)?.toDouble(),
    companyId: m['company_id'] as String?,
  );
}

class ClockEvent {
  final int? id;
  final int employeeId;
  final int? jobSiteId;
  final String clockType; // 'IN','OUT','AUTO_IN','AUTO_OUT'
  final int tsUtc; // seconds
  final double? lat;
  final double? lon;
  final String? source;
  final String? shiftId;
  final double? accuracyM;
  final String? companyId;

  ClockEvent({
    this.id,
    required this.employeeId,
    this.jobSiteId,
    required this.clockType,
    required this.tsUtc,
    this.lat,
    this.lon,
    this.source,
    this.shiftId,
    this.accuracyM,
    this.companyId,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'employee_id': employeeId,
    'job_site_id': jobSiteId,
    'clock_type': clockType,
    'ts_utc': tsUtc,
    'lat': lat,
    'lon': lon,
    'source': source,
    'shift_id': shiftId,
    'accuracy_m': accuracyM,
    'company_id': companyId,
  };

  factory ClockEvent.fromMap(Map<String, Object?> m) => ClockEvent(
    id: (m['id'] as num?)?.toInt(),
    employeeId: (m['employee_id'] as num).toInt(),
    jobSiteId: (m['job_site_id'] as num?)?.toInt(),
    clockType: m['clock_type'] as String,
    tsUtc: (m['ts_utc'] as num).toInt(),
    lat: (m['lat'] as num?)?.toDouble(),
    lon: (m['lon'] as num?)?.toDouble(),
    source: m['source'] as String?,
    shiftId: m['shift_id'] as String?,
    accuracyM: (m['accuracy_m'] as num?)?.toDouble(),
    companyId: m['company_id'] as String?,
  );
}

/// From SQL view vw_shift_summary
class ShiftSummary {
  final String shiftId;
  final int employeeId;
  final String jobId;
  final String jobName;
  final int hourlyRateCents;
  final int clockInUtc;
  final int? clockOutUtc;
  final String status;
  final int workedSeconds;
  final int earningsCents;
  final String? companyId;

  ShiftSummary({
    required this.shiftId,
    required this.employeeId,
    required this.jobId,
    required this.jobName,
    required this.hourlyRateCents,
    required this.clockInUtc,
    required this.clockOutUtc,
    required this.status,
    required this.workedSeconds,
    required this.earningsCents,
    this.companyId,
  });

  factory ShiftSummary.fromMap(Map<String, Object?> m) => ShiftSummary(
    shiftId: m['shift_id'] as String,
    employeeId: (m['employee_id'] as num).toInt(),
    jobId: m['job_id'] as String,
    jobName: m['job_name'] as String,
    hourlyRateCents: (m['hourly_rate_cents'] as num).toInt(),
    clockInUtc: (m['clock_in_utc'] as num).toInt(),
    clockOutUtc: (m['clock_out_utc'] as num?)?.toInt(),
    status: m['status'] as String,
    workedSeconds: (m['worked_seconds'] as num).toInt(),
    earningsCents: (m['earnings_cents'] as num).toInt(),
    companyId: m['company_id'] as String?,
  );
}

// -----------------------------------------------------------------------------
// New model added for device-specific user profile
// -----------------------------------------------------------------------------
class DeviceProfile {
  final String? fullName;
  final String? email;
  final String? phone;
  final String? role;
  final String? avatarPath;
  final String? deviceLabel;

  const DeviceProfile({
    this.fullName,
    this.email,
    this.phone,
    this.role,
    this.avatarPath,
    this.deviceLabel,
  });

  Map<String, dynamic> toMap() => {
    'id': 1,
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'role': role,
    'avatar_path': avatarPath,
    'device_label': deviceLabel,
  };

  static DeviceProfile fromMap(Map<String, Object?> m) => DeviceProfile(
    fullName: m['full_name'] as String?,
    email: m['email'] as String?,
    phone: m['phone'] as String?,
    role: m['role'] as String?,
    avatarPath: m['avatar_path'] as String?,
    deviceLabel: m['device_label'] as String?,
  );

  bool get isComplete => (fullName?.isNotEmpty ?? false);
}
