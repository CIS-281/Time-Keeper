// lib/services/job_service.dart
// High-level helper for getting jobs visible on this device.

import 'package:time_keeper/data/job_repo.dart';
import 'package:time_keeper/services/org_service.dart';

class JobService {
  final JobRepo _repo = JobRepo();
  final OrgService _org = OrgService();

  Future<List<JobRow>> visibleJobsForDevice() async {
    final cid = await _org.activeCompanyId();
    // If no company chosen yet, just show all jobs (or empty)
    return _repo.forCompany(cid);
  }
}
