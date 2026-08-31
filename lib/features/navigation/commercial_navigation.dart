import 'package:flutter/material.dart';

import '../../models/commercial_session.dart';

enum CommercialNavSection { dashboard, work, finance, files, more }

enum NavigationAvailability {
  available,
  unavailable,
  upgradeRequired,
  limitReached,
}

class CommercialNavigationPolicy {
  const CommercialNavigationPolicy(this.session);

  final CommercialSession? session;

  CommercialRole get role => session?.membership.role ?? CommercialRole.staff;

  bool get canManageBusiness => role.canManageCompany;
  bool get canManageTeam => role.canManageTeam;

  NavigationAvailability availabilityFor(String featureKey) {
    final feature = session?.entitlements.features[featureKey];
    if (feature == null || feature.allowed) {
      return NavigationAvailability.available;
    }
    if (feature.reason == 'limit_reached') {
      return NavigationAvailability.limitReached;
    }
    if (feature.reason == 'feature_not_in_plan' ||
        session?.entitlements.upgradeRequired == true) {
      return NavigationAvailability.upgradeRequired;
    }
    return NavigationAvailability.unavailable;
  }

  bool canShowManagementDestination(String key) {
    switch (key) {
      case 'company_profile':
      case 'branding':
        return canManageBusiness;
      case 'team_management':
        return canManageTeam;
      default:
        return true;
    }
  }

  String availabilityMessage(String featureKey) {
    final feature = session?.entitlements.features[featureKey];
    return feature != null && feature.message.isNotEmpty
        ? feature.message
        : 'This feature is not available for this workspace yet.';
  }
}

class CommercialDestination {
  const CommercialDestination({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
    this.featureKey,
    this.managementKey,
    this.comingSoon = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder;
  final String? featureKey;
  final String? managementKey;
  final bool comingSoon;
}
