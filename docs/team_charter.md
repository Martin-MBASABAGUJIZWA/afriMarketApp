# Team Charter – AfriMarket Project
**Course:** Flutter Widgets & UI Design
**Project Duration:** Weeks 1–9
**Last Updated:** Week 1

---

## 1. Team Identity

**Team Name:** [Your Team Name]
**Project:** AfriMarket – Local Marketplace App
**Mission:** Build a functional, user-tested Flutter marketplace app that genuinely solves a problem we observed in Kigali's local markets.

---

## 2. Team Members and Initial Roles

| Name | Role | Primary Responsibilities |
|---|---|---|
| [Member 1] | UI Lead | Wireframes, screen design, Flutter widget implementation |
| [Member 2] | Research Lead | Field research coordination, user testing, documentation |
| [Member 3] | Backend/Logic Lead | App state management, data models, MoMo integration logic |
| All members | Co-developers | Flutter screens, testing, weekly reviews |

Roles are flexible and will evolve as the project progresses. No single person owns any feature exclusively — all members review each other's work before it is considered done.

---

## 3. Communication Protocols

**Primary communication channel:** WhatsApp group (team only)
**Secondary channel:** GitHub Issues for technical tasks and bugs
**File sharing:** GitHub repository for all code; Google Drive for research notes and design files

**Meeting schedule:**
- Weekly check-in: Every Monday, 6:00 PM (in person or video call)
- Pre-submission review: 48 hours before any deadline
- Ad hoc messages: Respond within 24 hours on normal days, within 4 hours the day before a deadline

**Decision-making process:** Decisions are made by majority agreement. If the team is evenly split, the Research Lead has a tie-breaking vote for user-facing decisions; the UI Lead has the tie-breaking vote for design decisions.

---

## 4. Working Protocols

- All code goes through the GitHub repository — no emailing files between members
- Every feature must be reviewed by at least one other team member before merging
- No one pushes directly to the main branch — use feature branches and pull requests
- Document blockers immediately in the WhatsApp group — do not wait for the weekly meeting
- If a team member cannot complete their assigned task, they inform the group at least 48 hours before the deadline so responsibilities can be redistributed

---

## 5. Project Roadmap – Week 1 to Week 9

### Phase 1 – Foundation (Weeks 1–2)
**Goal:** Problem validated, concept defined, repository set up.
- Week 1: Field research, problem statement, app name, initial concept
- Week 2: Wireframes, user flows, Flutter project initialized, GitHub repository structured

**Milestone 1 Deliverable:** Field research doc, app concept doc, team charter, wireframes

### Phase 2 – Core Build (Weeks 3–5)
**Goal:** Core UI screens built and navigable.
- Week 3: Buyer home screen (product/seller list), bottom navigation bar
- Week 4: Seller profile screen, product detail screen
- Week 5: MoMo payment flow screen, order confirmation screen

**Milestone 2 Deliverable:** Working app prototype with core navigation and screens

### Phase 3 – Features and Polish (Weeks 6–7)
**Goal:** Key features functional, app works end to end.
- Week 6: Seller dashboard, product listing form, order inbox
- Week 7: Ratings and reviews UI, search and filter functionality

**Milestone 3 Deliverable:** Feature-complete prototype ready for user testing

### Phase 4 – Testing and Showcase (Weeks 8–9)
**Goal:** Tested, polished, and presentation-ready.
- Week 8: User testing with 3–5 real users (buyers and sellers), bug fixes based on feedback
- Week 9: Final polish, presentation slides, live demo preparation

**Milestone 4 Deliverable:** Showcase-ready app + presentation

---

## 6. Phase 4 Showcase Success Criteria

Our Phase 4 showcase will be considered successful if:

1. **The app runs live on a device** without crashing during the demo.
2. **A real user can complete the full buyer flow** (discover seller → view products → initiate checkout) in under 2 minutes without assistance.
3. **The seller listing flow** (add a product with photo, name, and price) takes under 3 minutes for a first-time user.
4. **We can articulate clearly** how every feature connects to a specific friction point from our field research.
5. **The UI is polished enough** that a stranger would trust it as a real product — not a student prototype.
6. **We include one piece of real user feedback** incorporated from Week 8 testing in the final demo.

---

## 7. GitHub Repository Structure

```
afrimarket/
├── lib/
│   ├── main.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── seller_profile_screen.dart
│   │   ├── product_detail_screen.dart
│   │   ├── checkout_screen.dart
│   │   └── seller_dashboard_screen.dart
│   ├── widgets/
│   │   ├── seller_card.dart
│   │   ├── product_card.dart
│   │   └── rating_bar.dart
│   └── models/
│       ├── seller.dart
│       ├── product.dart
│       └── order.dart
├── docs/
│   ├── field_research.md
│   ├── app_concept.md
│   └── team_charter.md
├── wireframes/
│   └── [PNG wireframe files]
└── README.md
```

All team members have been added as collaborators with write access. The main branch is protected — all changes go through pull requests.

---

## 8. Academic Integrity Commitment

All research in this project was conducted in the field by team members. All user interviews were with real people. The app concept was developed by the team based on our own observations. Any external tools or references used (including any AI tools for grammar checking or ideation) are disclosed below.

**Tools used:**
- Flutter and Dart (primary development platform)
- Figma / paper sketches (wireframing)
- GitHub (version control and collaboration)

---

*This charter is a living document. It will be updated at the start of each new phase.*
