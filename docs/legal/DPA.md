# FleetIQ Data Processing Addendum — Launch Candidate v2026-09-15.2

This DPA forms part of the agreement between the subscribing customer (the **Controller**) and **Ian Crofts trading as FleetIQ**, 20 Tunstall Drive, Nottingham, NG5 1LZ, United Kingdom (**FleetIQ** or the **Processor**) where FleetIQ processes personal data on the customer's behalf.

## 1. Processing instructions
FleetIQ will process customer personal data only on documented instructions from the Controller, including the agreement, this DPA and documented support/configuration instructions, unless UK law requires otherwise. FleetIQ will inform the Controller if an instruction appears to infringe applicable data-protection law where required/permitted to do so.

## 2. Confidentiality and security
FleetIQ will ensure persons authorised to process customer personal data are subject to appropriate confidentiality obligations and will maintain technical and organisational measures appropriate to the risk. Current measures include authenticated access, organisation-scoped tenancy, database row-level security, membership roles/custom permissions, tenant-scoped document paths, controlled privileged operations and tenant-scoped resilience/recovery controls.

## 3. Subprocessors
The Controller gives FleetIQ general written authorisation to use the subprocessors identified in the current FleetIQ Subprocessor Register. FleetIQ will impose appropriate written data-protection obligations on subprocessors and will remain responsible for its obligations to the Controller. FleetIQ will provide reasonable advance notice of a material new subprocessor used to process customer personal data and a reasonable opportunity to raise a data-protection objection.

## 4. Data-subject rights
Taking account of the nature of processing, FleetIQ will provide reasonable technical and organisational assistance to help the Controller respond to applicable data-subject requests. FleetIQ will not independently decide a Controller's response where FleetIQ acts only as processor unless required by law.

## 5. Security incidents and regulatory assistance
FleetIQ will notify the Controller without undue delay after becoming aware of a personal-data breach affecting customer personal data and will provide information reasonably available to support the Controller's assessment and notifications. Taking account of the processing and information available, FleetIQ will reasonably assist with security obligations, breach notifications, DPIAs and prior consultation where applicable.

## 6. Return and deletion
At the end of the service, FleetIQ will return/export and/or delete customer personal data in accordance with the agreement, documented customer instructions and Retention & Deletion Policy, unless UK law requires retention. Data in protected backups may remain inaccessible to normal use until expiry through the documented backup lifecycle.

## 7. Information and audits
FleetIQ will make information reasonably necessary to demonstrate compliance with Article 28 obligations available to the Controller. Audits should first use current security/compliance information and reasonable written enquiries. Where an on-site or additional audit is reasonably required, the parties will agree scope, timing, confidentiality, security and costs so that the audit does not compromise other customers or the service.

## Schedule 1 — Processing description
**Subject matter:** provision and support of the FleetIQ fleet-management SaaS service.  
**Duration:** subscription term plus the agreed export/deletion period and protected backup lifecycle.  
**Nature/purpose:** hosting, organising, displaying, securing, backing up and processing fleet-management records and customer-directed workflows.  
**Data subjects:** customer users, employees, drivers, contractors and other individuals represented in customer-supplied fleet records/evidence.  
**Personal data:** identity/contact/account data; driver/licence/compliance data; assignments; inspection/defect/repair/workshop records; uploaded documents/evidence; audit/security metadata and support-related information supplied by the customer.  
**Controller rights/obligations:** determine lawful purposes/instructions; provide required privacy information; configure authorised users/permissions; respond to rights requests and meet controller obligations.

## Schedule 2 — Security measures
Organisation-scoped tenancy and RLS; authenticated access; membership-specific roles and custom permissions; tenant-scoped storage paths; server-side privileged operations; controlled offline cache/queue scoping; idempotent supported mutation replay; secure secret separation (no Supabase service-role key in client apps); release testing; and documented incident/recovery procedures. Operational controls are reviewed as FleetIQ's production infrastructure evolves.

## Schedule 3 — Subprocessors
See the current FleetIQ Subprocessor Register. At this release, Supabase is the confirmed central infrastructure subprocessor. Other production suppliers are added only after selection, contract/privacy review and recording of processing/transfer details.

**Status:** launch-candidate DPA. Final solicitor/data-protection review is required before signature with paying customers.
