enum CommercialRole {
  owner,
  admin,
  staff;

  static CommercialRole parse(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'owner':
        return CommercialRole.owner;
      case 'administrator':
      case 'admin':
      case 'manager':
      case 'finance':
        return CommercialRole.admin;
      default:
        return CommercialRole.staff;
    }
  }

  bool get canManageCompany =>
      this == CommercialRole.owner || this == CommercialRole.admin;
  bool get canManageTeam =>
      this == CommercialRole.owner || this == CommercialRole.admin;
  bool get isStaff => this == CommercialRole.staff;
}

Map<String, dynamic> _jsonMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.displayName,
    required this.email,
  });

  factory CurrentUser.fromJson(Map<String, dynamic> json) => CurrentUser(
    id: (json['id'] as num?)?.toInt() ?? 0,
    displayName: json['display_name'] as String? ?? '',
    email: json['email'] as String? ?? '',
  );

  final int id;
  final String displayName;
  final String email;
}

class TenantWorkspace {
  const TenantWorkspace({
    required this.id,
    required this.companyName,
    required this.status,
    this.slug = '',
    this.currency = 'GBP',
    this.timezone = '',
  });

  factory TenantWorkspace.fromJson(Map<String, dynamic> json) =>
      TenantWorkspace(
        id: (json['id'] as num?)?.toInt() ?? 0,
        companyName: json['company_name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        status: json['status'] as String? ?? '',
        currency: json['currency'] as String? ?? 'GBP',
        timezone: json['timezone'] as String? ?? '',
      );

  final int id;
  final String companyName;
  final String slug;
  final String status;
  final String currency;
  final String timezone;

  bool get isActive => status == 'active';
}

class TenantMembership {
  const TenantMembership({
    required this.role,
    required this.status,
    required this.active,
    this.roleLabel = '',
  });

  factory TenantMembership.fromJson(Map<String, dynamic> json) =>
      TenantMembership(
        role: CommercialRole.parse(json['role'] as String?),
        roleLabel: json['role_label'] as String? ?? '',
        status: json['status'] as String? ?? '',
        active: json['active'] == true,
      );

  final CommercialRole role;
  final String roleLabel;
  final String status;
  final bool active;
}

class PlanSummary {
  const PlanSummary({
    required this.key,
    required this.label,
    required this.description,
    required this.internalOnly,
  });

  factory PlanSummary.fromJson(Map<String, dynamic> json) => PlanSummary(
    key: json['key'] as String? ?? '',
    label: json['label'] as String? ?? '',
    description: json['description'] as String? ?? '',
    internalOnly: json['internal_only'] == true,
  );

  final String key;
  final String label;
  final String description;
  final bool internalOnly;
}

class FeatureEntitlement {
  const FeatureEntitlement({
    required this.key,
    required this.allowed,
    required this.reason,
    required this.message,
    this.label = '',
  });

  factory FeatureEntitlement.fromJson(String key, Map<String, dynamic> json) =>
      FeatureEntitlement(
        key: key,
        allowed: json['allowed'] == true,
        reason:
            json['reason'] as String? ?? json['reason_code'] as String? ?? '',
        message: json['message'] as String? ?? '',
        label: json['label'] as String? ?? '',
      );

  final String key;
  final bool allowed;
  final String reason;
  final String message;
  final String label;
}

class UsageLimit {
  const UsageLimit({
    required this.key,
    required this.usage,
    this.limit,
    this.label = '',
  });

  factory UsageLimit.fromJson(String key, dynamic json, {dynamic limit}) {
    if (json is Map) {
      final values = _jsonMap(json);
      return UsageLimit(
        key: key,
        usage:
            (values['usage'] as num?)?.toInt() ??
            (values['used'] as num?)?.toInt() ??
            (values['count'] as num?)?.toInt() ??
            0,
        limit: (values['limit'] as num?)?.toInt(),
        label: values['label'] as String? ?? '',
      );
    }
    return UsageLimit(
      key: key,
      usage: (json as num?)?.toInt() ?? 0,
      limit: (limit as num?)?.toInt(),
    );
  }

  final String key;
  final int usage;
  final int? limit;
  final String label;
}

class EntitlementSummary {
  const EntitlementSummary({
    required this.plan,
    required this.status,
    required this.features,
    required this.usage,
    required this.upgradeRequired,
    this.placeholderNotice = '',
  });

  factory EntitlementSummary.fromJson(Map<String, dynamic> json) {
    final featuresJson = _jsonMap(json['features']);
    final usageJson = _jsonMap(json['usage']);
    final limitsJson = _jsonMap(json['limits']);
    return EntitlementSummary(
      plan: PlanSummary.fromJson(_jsonMap(json['plan'])),
      status: json['status'] as String? ?? '',
      features: featuresJson.map(
        (key, value) =>
            MapEntry(key, FeatureEntitlement.fromJson(key, _jsonMap(value))),
      ),
      usage: usageJson.map(
        (key, value) => MapEntry(
          key,
          UsageLimit.fromJson(key, value, limit: limitsJson[key]),
        ),
      ),
      upgradeRequired: json['upgrade_required'] == true,
      placeholderNotice: json['placeholder_notice'] as String? ?? '',
    );
  }

  final PlanSummary plan;
  final String status;
  final Map<String, FeatureEntitlement> features;
  final Map<String, UsageLimit> usage;
  final bool upgradeRequired;
  final String placeholderNotice;
}

class CompanyProfile {
  const CompanyProfile({
    required this.companyName,
    this.tradingName = '',
    this.email = '',
    this.phone = '',
    this.website = '',
    this.currency = 'GBP',
    this.canEdit = false,
  });

  factory CompanyProfile.fromJson(Map<String, dynamic> json) => CompanyProfile(
    companyName: json['company_name'] as String? ?? '',
    tradingName: json['trading_name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    website: json['website'] as String? ?? '',
    currency: json['currency'] as String? ?? 'GBP',
    canEdit: json['can_edit'] == true,
  );

  final String companyName;
  final String tradingName;
  final String email;
  final String phone;
  final String website;
  final String currency;
  final bool canEdit;
}

class BrandingSummary {
  const BrandingSummary({
    required this.displayName,
    this.logoUrl = '',
    this.initials = '',
    this.accentColor = '#147DE8',
    this.canEdit = false,
  });

  factory BrandingSummary.fromJson(Map<String, dynamic> json) =>
      BrandingSummary(
        displayName: json['display_name'] as String? ?? '',
        logoUrl: json['logo_url'] as String? ?? '',
        initials: json['initials'] as String? ?? '',
        accentColor: json['accent_color'] as String? ?? '#147DE8',
        canEdit: json['can_edit'] == true,
      );

  final String displayName;
  final String logoUrl;
  final String initials;
  final String accentColor;
  final bool canEdit;
}

class CommercialSession {
  const CommercialSession({
    required this.user,
    required this.tenant,
    required this.membership,
    required this.entitlements,
    required this.companyProfile,
    required this.branding,
  });

  factory CommercialSession.fromJson(
    Map<String, dynamic> json,
  ) => CommercialSession(
    user: CurrentUser.fromJson(_jsonMap(json['user'])),
    tenant: TenantWorkspace.fromJson(_jsonMap(json['tenant'])),
    membership: TenantMembership.fromJson(_jsonMap(json['membership'])),
    entitlements: EntitlementSummary.fromJson(_jsonMap(json['entitlements'])),
    companyProfile: CompanyProfile.fromJson(_jsonMap(json['company_profile'])),
    branding: BrandingSummary.fromJson(_jsonMap(json['branding'])),
  );

  final CurrentUser user;
  final TenantWorkspace tenant;
  final TenantMembership membership;
  final EntitlementSummary entitlements;
  final CompanyProfile companyProfile;
  final BrandingSummary branding;

  bool get hasActiveWorkspace =>
      tenant.isActive && membership.active && tenant.id > 0;
}
