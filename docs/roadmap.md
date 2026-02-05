# Roadmap EV Charge Tracker

## Features

- [x] EVF-1. Add wheel details to the vehicle page. Wheel pairs might be different, so there should be option to save two values. The settings should be available on the Car Edit page from User Settings View.
- [x] EVF-2. Make records on "Planned Maintenance" view slidable. Sliding to left - mark as done and create a related expense record (EVF-3). Sliding to right - edit/delete the record.
- [x] EVF-3. When user mark Planned Maintenance Record as "Done", the "Add Expense" screen should appear. Title field and notes should be pre-filled with the data from the Planned Maintenance record.
- [x] EVF-4. Create "Planned Maintenance Details" screen that should open when user clicks on item in the list of planned maintenance records. On the screen all details should be visible including "created_at" date in format YYYY-MM-DD. There should be buttons "Mark as Done", "edit", "Delete", and "Duplicate".
- [x] EVF-5. Filters. Read file /docs/plans/filters.md
- [ ] EVF-6. Export to CSV from User Settings view


## Ideas

- [ ] EVI-1. Check if we can to draw cars with SVG
- [ ] EVI-2. Create a separate Cars page and remove the block from settings. On the screen, there will be a car management and short stats available.
- [ ] EVI-3. Add Document storage to the app. User might want to attach documents to the vehicle or expense (PDF, images, pictures from gallery, etc)