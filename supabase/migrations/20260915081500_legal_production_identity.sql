begin;

-- Build 17.4.6.20.2: replace implementation-placeholder legal copy with
-- FleetIQ's production operator identity. Prior versions remain retained for
-- acceptance/audit evidence but are no longer current.
update public.fleet_legal_documents
   set active = false
 where kind in ('privacy', 'terms', 'dpa', 'security', 'retention')
   and active = true;

insert into public.fleet_legal_documents
  (kind, version, title, content, requires_acceptance, active, effective_at)
values
(
 'privacy', '2026-09-15.2', 'FleetIQ Privacy Notice',
 'FleetIQ is operated by Ian Crofts trading as FleetIQ, 20 Tunstall Drive, Nottingham, NG5 1LZ, United Kingdom. Website: www.fleetiq.org.uk. Privacy: privacy@fleetiq.org.uk. Support: support@fleetiq.org.uk. FleetIQ provides fleet-management software to subscribing organisations. Customer organisations normally determine why their driver, employee and operational records are processed and FleetIQ normally processes those records to provide the service. FleetIQ separately acts as controller for its own account administration, security, support, legal and business records. Depending on use, personal data may include identity/contact/account details, organisation membership and permissions, driver/licence/compliance information, assignments, inspections, defects, repairs, workshop records, documents/evidence, audit/security metadata and support communications. For FleetIQ-controller processing, lawful bases depend on the activity and principally include contract/pre-contract steps, legitimate interests in operating and securing the SaaS service, and legal obligations. Access is limited to authorised customer users and assessed providers. Supabase is the currently confirmed central infrastructure provider; other providers are added to the published subprocessor register only after selection and assessment. International transfers, where applicable, are documented with an appropriate UK safeguard. Retention follows purpose, customer instructions, contract, security/dispute needs and law; offboarding uses controlled export/deletion rather than uncontrolled immediate deletion. Depending on circumstances, individuals may have rights including access, rectification, erasure, restriction, objection and portability. Requests can be made in the FleetIQ Legal & Privacy Centre or to privacy@fleetiq.org.uk and identity may be verified. Where FleetIQ is processor, requests concerning customer-controlled data will normally be coordinated with the customer controller. Individuals may complain to the UK Information Commissioner''s Office. FleetIQ reviews this notice and may require acceptance of a materially changed version.',
 true, true, now()
),
(
 'terms', '2026-09-15.2', 'FleetIQ SaaS Terms',
 'FleetIQ is supplied by Ian Crofts trading as FleetIQ, 20 Tunstall Drive, Nottingham, NG5 1LZ, United Kingdom. Website: www.fleetiq.org.uk. Support: support@fleetiq.org.uk. These terms provide the FleetIQ subscription framework. The customer receives a limited right for authorised users to use FleetIQ for internal fleet-management activities during the subscription term and is responsible for account security, lawful data entry, appropriate permissions and lawful use of driver/employee information. FleetIQ and its licensors retain intellectual-property rights in the service; the customer retains rights in customer data and grants FleetIQ the rights necessary to provide and secure the service. FleetIQ will use reasonable skill and care but availability can be affected by maintenance, provider/internet failure and events outside reasonable control; no contractual uptime percentage applies unless expressly agreed. Fees, billing, renewal, cancellation and any trial are those in the accepted order/subscription checkout. FleetIQ is currently not VAT registered. Data protection is governed by applicable law and the FleetIQ DPA where FleetIQ processes customer personal data on behalf of the customer. FleetIQ may suspend access where reasonably necessary for security, unlawful use, material breach or non-payment. FleetIQ is a management tool and does not replace the customer''s statutory, roadworthiness, employment, transport-manager or professional responsibilities. Production liability caps/exclusions and final governing-law/commercial provisions must be approved before paid subscriptions are accepted; nothing excludes liability where UK law prohibits exclusion.',
 true, true, now()
),
(
 'dpa', '2026-09-15.2', 'FleetIQ Data Processing Addendum',
 'Where FleetIQ processes customer personal data on behalf of a customer controller, Ian Crofts trading as FleetIQ acts as processor. FleetIQ processes on documented instructions unless UK law requires otherwise; applies confidentiality and appropriate technical/organisational security; uses subprocessors under general written authorisation and appropriate written obligations; assists with applicable data-subject rights; assists with security, breach, DPIA and regulatory obligations taking account of the processing and information available; and returns or deletes customer personal data at end of service as instructed/contracted unless law requires retention. Protected backups may persist until expiry through the documented lifecycle. FleetIQ will provide information reasonably necessary to demonstrate Article 28 compliance and support appropriate audits without compromising other customers or service security. Processing covers provision/support of FleetIQ during the subscription and agreed offboarding period; data subjects may include customer users, employees, drivers and contractors; data may include identity/contact/account, driver/licence/compliance, assignment, inspection, defect, repair/workshop, document/evidence, audit/security and support information. The current Subprocessor Register forms the subprocessor schedule.',
 false, true, now()
),
(
 'security', '2026-09-15.2', 'FleetIQ Security Overview',
 'FleetIQ uses authenticated access, real organisation tenancy, restrictive tenant row-level security, membership-specific roles/custom permissions, protected company ownership, tenant-scoped document paths, server-side privileged operations, tenant/user-scoped cached reads and approved offline queues, and idempotent supported mutation replay. Supabase service-role credentials are not embedded in Flutter clients. Production operations additionally require verified secrets management, backup/PITR and restore testing, dependency/vulnerability review, incident and personal-data-breach response, access reviews, logging/monitoring, secure release/signing practices, business continuity and supplier review. FleetIQ does not claim security certifications it has not obtained.',
 false, true, now()
),
(
 'retention', '2026-09-15.2', 'FleetIQ Retention & Deletion Policy',
 'FleetIQ uses purpose-based retention. Customer-controlled fleet, driver, compliance, inspection, defect, repair, workshop and document records are retained during the active subscription and controlled offboarding/export period, then returned/deleted on documented customer instruction unless a legal hold or other lawful retention requirement applies. Legal acceptance, privacy-request, security, support and business records are retained only for the period reasonably required for their purpose, accountability, disputes and applicable law. Backups are not used as an archive; deleted data may persist in protected backups until expiry under the production provider lifecycle. Exact technical log and backup/PITR periods must match the selected production services and be recorded before first paid customer. Erasure requests are reviewed rather than automatically destroying operational/audit evidence.',
 false, true, now()
)
on conflict (kind, version) do update
set title = excluded.title,
    content = excluded.content,
    requires_acceptance = excluded.requires_acceptance,
    active = excluded.active,
    effective_at = excluded.effective_at;

commit;
