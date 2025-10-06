// Tobias Cash
// 10/01/2025
// Data models used by repositories and services.
// same as in *app_db* ask Tobias for advice or changes!
// if needed for UI design, try out changes only on work branches.

class JobSite {
  final int? id;
  final String name;
  final double latitude, longitude;
  final int radiusM;

  JobSite({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusM = 100,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'radius_m': radiusM,
  };

  factory JobSite.fromMap(Map<String, Object?> m) => JobSite(
    id: m['id'] as int?,
    name: m['name'] as String,
    latitude: (m['latitude'] as num).toDouble(),
    longitude: (m['longitude'] as num).toDouble(),
    radiusM: (m['radius_m'] as num).toInt(),
  );
}

class Employee {
  final int? id;
  final String fullName;
  final int payRateCents;

  Employee({this.id, required this.fullName, required this.payRateCents});

  Map<String, Object?> toMap() => {
    'id': id,
    'full_name': fullName,
    'pay_rate_cents': payRateCents,
  };

  factory Employee.fromMap(Map<String, Object?> m) => Employee(
    id: m['id'] as int?,
    fullName: m['full_name'] as String,
    payRateCents: (m['pay_rate_cents'] as num).toInt(),
  );
}

class ClockType {
  static const inMan = 'IN';
  static const outMan = 'OUT';
  static const inAuto = 'AUTO_IN';
  static const outAuto = 'AUTO_OUT';
}

class ClockEvent {
  final int? id;
  final int employeeId;
  final int? jobSiteId;
  final String clockType;
  final int tsUtc; // milliseconds since epoch (UTC)
  final double? lat, lon;
  final String? source; // manual, manual+gps, geofence, etc.

  ClockEvent({
    this.id,
    required this.employeeId,
    this.jobSiteId,
    required this.clockType,
    required this.tsUtc,
    this.lat,
    this.lon,
    this.source,
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
  };

  factory ClockEvent.fromMap(Map<String, Object?> m) => ClockEvent(
    id: m['id'] as int?,
    employeeId: (m['employee_id'] as num).toInt(),
    jobSiteId: m['job_site_id'] as int?,
    clockType: m['clock_type'] as String,
    tsUtc: (m['ts_utc'] as num).toInt(),
    lat: (m['lat'] as num?)?.toDouble(),
    lon: (m['lon'] as num?)?.toDouble(),
    source: m['source'] as String?,
  );
}
