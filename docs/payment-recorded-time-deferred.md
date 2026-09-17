# P1 — Payment Recorded Time

Phase 1H-H Payment History displays the business payment date only. Backend
timestamps and all payment records remain unchanged.

Defer Recorded time until the API provides an authoritative `recorded_at`
instant in ISO-8601 with explicit offset or UTC, and Company Settings provides
an authoritative tenant/company timezone. Do not guess a timezone for existing
offset-free timestamps or apply an offset twice.
