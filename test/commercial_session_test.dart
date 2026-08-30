import 'package:daphnex_crm_mobile/models/commercial_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('canonical commercial roles parse legacy aliases centrally', () {
    expect(CommercialRole.parse('owner'), CommercialRole.owner);
    expect(CommercialRole.parse('administrator'), CommercialRole.admin);
    expect(CommercialRole.parse('manager'), CommercialRole.admin);
    expect(CommercialRole.parse('finance'), CommercialRole.admin);
    expect(CommercialRole.parse('staff'), CommercialRole.staff);
    expect(CommercialRole.parse('unknown'), CommercialRole.staff);
  });

  test('commercial session parses company branding and entitlements', () {
    final session = CommercialSession.fromJson({
      'user': {
        'id': 1,
        'display_name': 'Alex Owner',
        'email': 'alex@example.test',
      },
      'tenant': {'id': 2, 'company_name': 'Builder A', 'status': 'active'},
      'membership': {'role': 'admin', 'status': 'active', 'active': true},
      'company_profile': {
        'company_name': 'Builder A Ltd',
        'trading_name': 'Builder A',
        'currency': 'GBP',
      },
      'branding': {
        'display_name': 'Builder A',
        'initials': 'BA',
        'accent_color': '#147DE8',
      },
      'entitlements': {
        'plan': {
          'key': 'pilot',
          'label': 'Pilot',
          'description': 'Pilot workspace',
          'internal_only': true,
        },
        'status': 'active',
        'features': {
          'team_management': {
            'allowed': false,
            'reason': 'feature_not_in_plan',
            'message': 'Upgrade required',
          },
        },
        'limits': {'team_members': 3},
        'usage': {
          'team_members': {'usage': 2, 'limit': 3},
        },
      },
    });

    expect(session.hasActiveWorkspace, isTrue);
    expect(session.membership.role, CommercialRole.admin);
    expect(session.companyProfile.companyName, 'Builder A Ltd');
    expect(session.branding.initials, 'BA');
    expect(session.entitlements.plan.key, 'pilot');
    expect(session.entitlements.features['team_management']?.allowed, isFalse);
    expect(session.entitlements.usage['team_members']?.usage, 2);
  });

  test('inactive tenant or membership does not count as active workspace', () {
    final session = CommercialSession.fromJson({
      'user': {'id': 1},
      'tenant': {'id': 2, 'status': 'suspended'},
      'membership': {'role': 'staff', 'status': 'inactive', 'active': false},
      'company_profile': {},
      'branding': {},
      'entitlements': {'plan': {}, 'features': {}, 'usage': {}},
    });

    expect(session.hasActiveWorkspace, isFalse);
  });
}
