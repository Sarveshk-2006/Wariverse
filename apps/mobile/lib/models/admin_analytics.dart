/// Top-level analytics model for admin dashboard.
class AdminAnalytics {
  final int totalPilgrims;
  final int activeVolunteers;
  final int openSosIncidents;
  final int crowdAlerts;
  final Map<String, dynamic> raw;

  const AdminAnalytics({
    required this.totalPilgrims,
    required this.activeVolunteers,
    required this.openSosIncidents,
    required this.crowdAlerts,
    required this.raw,
  });

  factory AdminAnalytics.fromJson(Map<String, dynamic> json) => AdminAnalytics(
        totalPilgrims: json['total_pilgrims'] as int? ?? 0,
        activeVolunteers: json['active_volunteers'] as int? ?? 0,
        openSosIncidents: json['open_sos_incidents'] as int? ?? 0,
        crowdAlerts: json['crowd_alerts'] as int? ?? 0,
        raw: json,
      );
}

/// Police route model from /police/routes.
class PoliceRoute {
  final String id;
  final String routeName;
  final String status;
  final String advisory;
  final int activePilgrims;

  const PoliceRoute({
    required this.id,
    required this.routeName,
    required this.status,
    required this.advisory,
    required this.activePilgrims,
  });

  factory PoliceRoute.fromJson(Map<String, dynamic> json) => PoliceRoute(
        id: json['id'] as String? ?? '',
        routeName: json['route_name'] as String? ?? '',
        status: json['status'] as String? ?? 'CLEAR',
        advisory: json['advisory'] as String? ?? '',
        activePilgrims: json['active_pilgrims'] as int? ?? 0,
      );
}

/// Volunteer summary from /ngo/volunteers.
class VolunteerSummary {
  final String id;
  final String name;
  final String phone;
  final String area;
  final String status;
  final int tasksCompleted;

  const VolunteerSummary({
    required this.id,
    required this.name,
    required this.phone,
    required this.area,
    required this.status,
    required this.tasksCompleted,
  });

  factory VolunteerSummary.fromJson(Map<String, dynamic> json) =>
      VolunteerSummary(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        area: json['area'] as String? ?? '',
        status: json['status'] as String? ?? 'AVAILABLE',
        tasksCompleted: json['tasks_completed'] as int? ?? 0,
      );
}

/// Resource inventory item from /ngo/resources.
class ResourceInventoryItem {
  final String id;
  final String itemName;
  final int allocated;
  final int remaining;
  final String riskLevel;

  const ResourceInventoryItem({
    required this.id,
    required this.itemName,
    required this.allocated,
    required this.remaining,
    required this.riskLevel,
  });

  double get usagePct => allocated > 0 ? (allocated - remaining) / allocated : 0;

  factory ResourceInventoryItem.fromJson(Map<String, dynamic> json) =>
      ResourceInventoryItem(
        id: json['id'] as String? ?? '',
        itemName: json['item_name'] as String? ?? '',
        allocated: json['allocated'] as int? ?? 0,
        remaining: json['remaining'] as int? ?? 0,
        riskLevel: json['risk_level'] as String? ?? 'LOW',
      );
}
