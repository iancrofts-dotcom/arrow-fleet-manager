class CentralOrganisationSettings {
  const CentralOrganisationSettings({
    required this.id,
    required this.name,
    required this.slug,
    required this.ownerUserId,
    this.legalName = '',
    this.contactEmail = '',
    this.phone = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.townCity = '',
    this.postcode = '',
    this.companyNumber = '',
    this.reportFooter = '',
  });

  final String id;
  final String name;
  final String slug;
  final String ownerUserId;
  final String legalName;
  final String contactEmail;
  final String phone;
  final String addressLine1;
  final String addressLine2;
  final String townCity;
  final String postcode;
  final String companyNumber;
  final String reportFooter;

  factory CentralOrganisationSettings.fromJson(Map<String, dynamic> json) =>
      CentralOrganisationSettings(
        id: json['id'] as String,
        name: (json['name'] as String?)?.trim() ?? '',
        slug: (json['slug'] as String?)?.trim() ?? '',
        ownerUserId: (json['owner_user_id'] as String?)?.trim() ?? '',
        legalName: (json['legal_name'] as String?)?.trim() ?? '',
        contactEmail: (json['contact_email'] as String?)?.trim() ?? '',
        phone: (json['phone'] as String?)?.trim() ?? '',
        addressLine1: (json['address_line1'] as String?)?.trim() ?? '',
        addressLine2: (json['address_line2'] as String?)?.trim() ?? '',
        townCity: (json['town_city'] as String?)?.trim() ?? '',
        postcode: (json['postcode'] as String?)?.trim() ?? '',
        companyNumber: (json['company_number'] as String?)?.trim() ?? '',
        reportFooter: (json['report_footer'] as String?)?.trim() ?? '',
      );
}
