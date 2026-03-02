# Feature Matrix

Status legend: `Implemented` = working in code, `Partial` = present with known gaps, `Planned` = documented but not implemented.

| Area | Feature | Status | Notes |
|---|---|---|---|
| Core tracking | Multi-car support | Implemented | Add/edit/delete cars, select active tracking car, per-car currency/mileage. |
| Core tracking | Charging session logging | Implemented | Detailed add/edit flow, charger type, energy, cost, odometer. |
| Core tracking | Non-charging expenses | Implemented | Maintenance, repair, carwash, other expense types. |
| Stats | Cost per km (charging only + total) | Implemented | Computed in stats view model. |
| Stats | CO2 saved estimation | Implemented | Uses configurable coefficient from env. |
| Stats | Energy efficiency (kWh/100km) | Implemented | Based on charging and total mileage. |
| Stats | Expense charts | Implemented | Monthly chart with type filters (last N months, default 6). |
| Stats | Daily/weekly/monthly summaries | Partial | Monthly view is implemented; explicit daily/weekly summary modes are not. |
| Expenses list | Filtering by type | Implemented | Chips for all expense types. |
| Expenses list | Sorting + persistence | Implemented | Sort by creation date/odometer, saved in settings table. |
| Expenses list | Pagination | Implemented | 10 items per page with next/previous controls. |
| Maintenance | Date + odometer reminders | Implemented | Supports either/both triggers. |
| Maintenance | Overdue/due soon/scheduled filters | Implemented | Repository-level filtering logic exists. |
| Maintenance | Swipe actions + detail screen | Implemented | Mark done, edit, delete, duplicate, full details screen. |
| Maintenance | Mark done creates expense | Implemented | Opens prefilled expense form and removes task. |
| Notifications | Local notification scheduling/cancel | Implemented | Date-based scheduling tied to maintenance records. |
| Settings | Runtime language switching | Implemented | en/de/ru/kk/tr/uk via custom localization manager. |
| Settings | Appearance mode | Implemented | system/light/dark persisted in UserDefaults. |
| Settings | App update badge/check | Implemented | Checks App Store version via lookup API. |
| Backup | Export to JSON + share sheet | Implemented | Temporary export file generation with metadata. |
| Backup | Import JSON with validation + preview | Implemented | Includes destructive confirmation and safety checks. |
| Backup | Safety backup + rollback on failed import | Implemented | Automatic pre-import backup and restore path. |
| Backup | iCloud backup list/create/restore/delete | Implemented | Includes delete single and delete all. |
| Backup | Automatic background backups | Partial | BG task + toggle exists; exactly-midnight behavior is best-effort. |
| Data portability | CSV export | Planned | Roadmap item not implemented. |
| Onboarding | First-launch onboarding flow | Implemented | Language selection + intro pages + skip/finish. |
| Developer tools | Hidden developer mode | Implemented | 15-tap unlock, debug/test actions. |
| Testing | Automated tests | Partial | Maintenance-focused tests exist; broader feature coverage is limited. |

