# Relief Dashboard: Presentation

## 1. The Problem

When a disaster strikes, such as a flood, earthquake, or humanitarian crisis, relief operations are often coordinated through fragmented, manual channels: phone calls, group chats, paper forms, and spreadsheets passed between field workers and coordinators.

This causes:
- No real time visibility into what supplies exist, where, and in what quantity.
- Slow, error prone request handling. Volunteers cannot easily report what a community needs, and coordinators cannot see requests as they come in.
- Misallocated resources. Stock gets sent to the wrong location, or critical needs go unmet while other areas are over supplied.
- No prioritization. Without urgency tracking, life threatening requests can sit in the same queue as low priority ones.

### Who it affects
- Field volunteers on the ground, who need a fast way to report needs and locations without technical overhead.
- Coordinators and admins, who are responsible for inventory, allocation, and making sure aid reaches the right place in time.
- Affected communities, who ultimately wait longer or receive less effective aid when coordination breaks down.

---

## 2. The Solution

Relief Dashboard is a role based, real time disaster relief logistics application that connects field volunteers directly to coordinators through a shared, live system of record.

- Field volunteers submit relief requests with location, photo evidence, urgency level, and needed items directly from the field.
- Coordinators and admins see all incoming requests in real time, check inventory across warehouses, and allocate stock with one tap.
- Both roles get a live map view of requests and warehouses, so decisions are made with full geographic context.

### Who it serves
- Field Volunteer role: a lightweight, mobile friendly flow for reporting needs from the field.

  ![Volunteer new request](dashboard/screenshots/volunteer-home.png)

- Coordinator/Admin role: a full operations dashboard for managing warehouses, inventory, requests, and allocation decisions.

  ![Admin requests](dashboard/screenshots/admin-requests.png)

---

## 3. The Impact

- Faster response times. Requests move from submission to allocation in a live pipeline, instead of being lost in chat threads or paperwork.
- Better resource allocation. Coordinators always see current inventory levels and can allocate stock against real, verified requests.
- Prioritized triage. Urgency levels such as critical and high surface the most urgent needs first, both in lists and on the map.
- Transparency for everyone. Volunteers can track the real time status of the requests they submitted, closing the feedback loop.
- Data driven oversight. An analytics dashboard gives coordinators an at a glance view of active requests, priority breakdowns, and status distribution.

![Admin dashboard](dashboard/screenshots/admin-dashboard.png)

---

## 4. The Technology

| Layer | Technology |
|---|---|
| App framework | Flutter (Dart), Material 3 UI |
| Backend and database | Firebase Cloud Firestore, real time streams |
| Authentication | Firebase Authentication (email/password), role based access |
| File storage | Firebase Storage (request photos) |
| Maps | flutter_map with OpenStreetMap tiles, latlong2 |
| Analytics and charts | fl_chart |
| State management | provider |
| Device features | geolocator for location, image_picker for photo capture |

Architecture highlights:
- Role based access control enforced both in the UI and in Firestore security rules.
- Real time data sync via Firestore streams, with no manual refresh needed.
- Cross platform from a single Dart codebase, covering web, Android, iOS, and desktop.

![Admin map](dashboard/screenshots/admin-map.png)

---

## 5. What We Actually Built

- Authentication and onboarding: sign up with role selection (admin/coordinator or field volunteer), secure login, and an auth gate that routes users to the correct experience.

  ![Sign up screen](dashboard/screenshots/signup-screen.png)

- Field Volunteer flow:
  - New request form with location, urgency, items needed, and photo upload.
  - "My Requests" screen with real time status tracking.
  - Map view of submitted request locations.

  ![Volunteer map](dashboard/screenshots/volunteer-map.png)

- Coordinator/Admin flow:
  - Analytics dashboard with active requests, critical/high priority counts, and a status breakdown bar chart.
  - Requests screen, filterable by status, with one tap stock allocation.
  - Inventory screen with items grouped by category, and warehouse and low stock indicators.
  - Interactive map with warehouses and active requests plotted by urgency.

  ![Admin inventory](dashboard/screenshots/admin-inventory.png)

  ![Volunteer requests](dashboard/screenshots/volunteer-requests.png)

- Shared infrastructure: data models for users, requests, inventory, and warehouses; a Firestore service layer; reusable status and urgency badge widgets; an app wide Material 3 theme.
- Demo ready: seeded demo accounts and sample data (a warehouse and inventory across Food, Water, Medicine, Shelter, and Clothing) for live walkthroughs.

### Current status

Fully functional end to end prototype covering both user roles, running on web and mobile from a single Flutter codebase, backed by live Firebase services.
