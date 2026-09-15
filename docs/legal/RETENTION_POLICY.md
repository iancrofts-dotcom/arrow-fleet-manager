# FleetIQ Retention & Deletion Policy — Launch Candidate v2026-09-15.2

FleetIQ uses purpose-based retention and does not indiscriminately delete fleet compliance/audit history when a request is submitted.

## Production retention schedule
| Record | Operational retention target |
|---|---|
| Customer-controlled fleet, driver, compliance, inspection, defect, repair, workshop and document records | For the active subscription and then through the contracted offboarding/export period; deletion follows documented customer instruction unless a legal hold or other lawful retention requirement applies. |
| Organisation membership and permission history needed for security/audit | While the organisation is active and for the offboarding/security investigation period reasonably required to protect the service and evidence access decisions. |
| Legal document acceptances | Retained as evidence of the version accepted and acceptance time for the period reasonably necessary to establish/defend contractual or compliance matters. |
| Privacy/data-rights and offboarding request records | Retained after closure for the period reasonably necessary to demonstrate handling of the request and meet accountability/dispute requirements. |
| Security/technical logs | Kept for a proportionate security/diagnostic period determined by the production logging platform and risk assessment; the exact platform period must be recorded before launch. |
| Support communications | Kept while needed to resolve/support the account and thereafter for a proportionate business/dispute period. |
| Accounting, invoices and tax/business records | Kept for the period required by applicable UK tax/accounting law and any longer period reasonably required for live disputes. |
| Backups | Not used as an archive. Deleted data may persist in protected backups until expiry under the production backup provider's documented lifecycle, after which it is overwritten/deleted. Exact backup/PITR periods must match the selected Supabase production plan and be recorded in the operations register. |

## Offboarding
An authorised organisation administrator/owner requests offboarding. FleetIQ confirms scope and authority, provides any contracted export, revokes access at the appropriate point, deletes or returns customer personal data according to documented instructions, and records completion. Legal holds or mandatory retention are documented and restricted from normal use.

## Individual rights
An erasure request triggers review; it does not automatically destroy operational or audit evidence. FleetIQ determines whether it is controller or processor for the affected data, coordinates with the customer controller where appropriate, applies applicable rights/exemptions and records the outcome.

## Review
Retention settings are reviewed when infrastructure, law, customer contracts or processing purposes change. Exact technical log and backup periods must be locked to the production providers before first paid customer.
