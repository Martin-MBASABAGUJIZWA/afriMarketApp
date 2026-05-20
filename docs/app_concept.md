# App Concept Document – AfriMarket
**Version:** 1.0
**Team:** [flutterv1]
**Date:** Week 1

---

## 1. App Overview

**App Name:** AfriMarket
**Tagline:** *Find it nearby. Buy with trust.*

AfriMarket is a localized mobile marketplace app designed specifically for buyers and sellers in Rwandan urban markets. It connects buyers who need to find trusted nearby sellers with clear prices to informal and semi-formal sellers who currently rely on WhatsApp, word of mouth, and physical presence to conduct business.

---

## 2. Problem-Solution Fit

### The Problem (from field research)

Buyers in Kigali's local markets struggle to find trusted sellers with clear prices nearby, while sellers struggle to reach and retain customers without managing multiple unreliable platforms like WhatsApp and phone calls.

This creates two forms of economic loss:
- **Seller-side:** Lost sales due to poor discoverability and no digital presence
- **Buyer-side:** Wasted time due to no structured way to find products, compare prices, or verify seller reputation

### The Solution

AfriMarket creates a unified, low-data mobile marketplace where:
- Sellers list products with prices and photos once, and buyers can find them instantly
- Buyers search by location proximity and see seller ratings before visiting or ordering
- Payments are handled natively through MoMo (MTN Mobile Money / Airtel Money)
- Sellers receive orders and inquiries in one inbox instead of scattered across platforms

---

## 3. Target Users

### Primary User – Buyer
**Profile:** Urban residents aged 18–40 in Kigali who regularly buy household goods, food, clothing, or services from local informal sellers.
**Motivation:** Save time, find good prices, avoid the frustration of walking to unavailable sellers.
**Digital profile:** Smartphone user, uses WhatsApp daily, some experience with mobile apps.

### Secondary User – Seller
**Profile:** Informal market vendors, home-based sellers, and small shop owners aged 20–50.
**Motivation:** Reach more customers, reduce time answering repetitive questions on WhatsApp, accept payments smoothly.
**Digital profile:** Smartphone user, WhatsApp-comfortable, limited experience with formal e-commerce tools.

---

## 4. Core Value Proposition

| For Buyers | For Sellers |
|---|---|
| Discover nearby sellers with real stock and clear prices | Be found by customers who are actively looking |
| See seller ratings and reviews before buying | Manage products, orders, and payments in one place |
| Pay via MoMo without negotiating payment method | Receive notifications and manage your shop on a simple interface |
| Browse offline when connectivity is limited | Reach customers beyond your physical location |

---

## 5. MVP Feature List

### Feature 1: Location-Based Seller Discovery
**What it does:** Buyers open the app and see a map or list of nearby sellers sorted by proximity. Sellers show their distance, category, and a preview of available products.
**Why it solves the friction:** Eliminates the need to physically walk around looking for a product. Directly addresses the observation that buyers waste significant time searching.
**Constraint addressed:** Works with low data — map tiles are cached, seller list loads as compressed JSON.

### Feature 2: Product Listings with Clear Pricing
**What it does:** Sellers create simple product cards with a photo (optional), product name, price, and availability status (In Stock / Out of Stock).
**Why it solves the friction:** Addresses the complete absence of visible pricing in field observations. Transparent prices eliminate the trust barrier between buyer and first contact.
**Constraint addressed:** Photo upload is optional and compressed — supports sellers with limited data. Text-only listings still work.

### Feature 3: Seller Profiles with Ratings and Reviews
**What it does:** Each seller has a public profile showing their name, photo, product categories, operating hours, location, and a star rating with written reviews from past buyers.
**Why it solves the friction:** Directly addresses the trust gap identified in all three research sessions. New buyers need a way to assess sellers they have never met.
**Constraint addressed:** Builds local social trust digitally — mirrors the "reputation by word of mouth" system that already exists offline.

### Feature 4: In-App MoMo Payment Integration
**What it does:** Buyers can pay via MTN MoMo or Airtel Money directly within the app. Sellers receive payment notifications in the app. No cash negotiation required for digital orders.
**Why it solves the friction:** Observed MoMo confusion at every research site. A structured in-app flow removes ambiguity from both sides.
**Constraint addressed:** Mobile money is the dominant payment method in Rwanda — this is not an add-on feature, it is the primary payment infrastructure.

### Feature 5: Simple Order and Message Inbox
**What it does:** Buyers can send an order or inquiry to a seller from within the app. Sellers see all messages in a single inbox with product context attached — no need to manage WhatsApp groups.
**Why it solves the friction:** Sellers reported WhatsApp fatigue from answering the same questions repeatedly across multiple groups. A structured inbox with product context reduces that friction.
**Constraint addressed:** Replaces multi-platform communication overhead with one unified channel.

---

## 6. Constraint Integration Plan

| Progressive Project Guide Constraint | How AfriMarket Addresses It |
|---|---|
| **Low internet / offline support** | App uses local caching for recently viewed seller profiles and product listings. Map tiles are pre-cached per district. Listings can be browsed offline after first load. |
| **Mobile Money payment** | MoMo is the default and only payment method at launch. The payment flow uses MTN and Airtel APIs and is built into the checkout flow, not an optional add-on. |
| **Low digital literacy** | Seller onboarding uses a step-by-step guided flow with icons and minimal text entry. Product listing is a 3-tap flow: photo, price, name. Kinyarwanda language support included. |
| **Data minimization** | Images are compressed on upload. API responses use pagination. The app defaults to list view (text-only) and makes map view optional. |

---

## 7. Innovation and Differentiation

AfriMarket is not a copy of Jumia or Alibaba. It is purpose-built for Kigali's informal economy with three key differentiators:

1. **Hyper-local by design:** The discovery experience defaults to walking distance (under 2 km), not nationwide delivery. This serves the 90% of transactions that are still local and in-person.

2. **Seller-first onboarding:** Most e-commerce apps are built for buyers. AfriMarket's seller interface is as simple as posting to WhatsApp, but organized, structured, and connected to payments.

3. **Trust infrastructure for informal trade:** Unlike WhatsApp groups where seller reputation is invisible to strangers, AfriMarket builds a public reputation layer — making the informal economy more trustworthy without requiring formal business registration.

---

## 8. Initial User Flow Diagrams

### Buyer Flow
1. Open app → see nearby sellers sorted by distance
2. Tap a seller → view profile, rating, and product list
3. Tap a product → see price, photos, availability
4. Tap "Order" or "Contact Seller"
5. Confirm order → choose MoMo payment → complete transaction
6. Leave a review after pickup or delivery

### Seller Flow
1. Register → enter name, location, product category, phone number
2. Add products → photo (optional), name, price, stock status
3. Go live → profile visible to nearby buyers
4. Receive order notification → confirm or decline
5. Complete transaction → receive MoMo payment in app
6. View dashboard: orders, ratings, messages

---

## 9. Wireframe Reference

See `/wireframes/` folder for:
- Buyer home screen (map + list toggle)
- Seller profile screen
- Product listing card
- Checkout/MoMo payment flow
- Seller dashboard

---

*Built with Flutter and Dart. All features are scoped to skills covered in the Flutter Widgets & UI Design course.*
