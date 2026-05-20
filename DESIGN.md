# DESIGN.md – AfriMarket Design System

## Visual Rationale

Our team chose a design direction rooted in trust, nature, and local identity. The dominant green palette draws directly from Rwanda's landscape — the terraced hills, the agriculture, the green flag — and connects the app emotionally to the context it serves. We wanted users who open AfriMarket to feel immediately that this was built for them and their environment, not imported from a generic global template. The secondary orange accent adds warmth and draws attention to actions like pricing and payment, referencing the energy and colour of Kigali's open-air markets. We avoided clinical whites and blue-heavy schemes used by most generic e-commerce apps because AfriMarket's users interact with physical, earthy goods — the design should reflect that tangibility.

---

## Color Palette

| Role | Name | Hex | Usage |
|---|---|---|---|
| Primary | Forest Green | `#2E7D32` | AppBar, buttons, active nav, badges, prices |
| Primary Light | Medium Green | `#4CAF50` | Hover states, secondary actions |
| Secondary | Burnt Orange | `#E65100` | Featured badges, highlights, CTA accents |
| Surface | Warm Off-White | `#F5F5F0` | Page backgrounds |
| Card | Pure White | `#FFFFFF` | Cards, input fields, bottom sheets |
| Text Primary | Near Black | `#1A1A1A` | Headings, primary content |
| Text Secondary | Medium Gray | `#616161` | Body text, descriptions |
| Text Muted | Light Gray | `#9E9E9E` | Labels, metadata, timestamps |
| Border | Soft Gray | `#E0E0E0` | Card borders, dividers, input borders |
| Success | Green Tint | `#E8F5E9` | In-stock indicators, confirmation banners |
| Warning | Amber Tint | `#FFF9C4` | Pickup info, reminders |

---

## Typography

| Style | Size | Weight | Usage |
|---|---|---|---|
| Display Large | 28px | 700 | Page headings |
| Headline Medium | 20px | 700 | Section titles |
| Title Large | 16px | 700 | Card titles, screen titles |
| Title Medium | 14px | 600 | Seller names, product names |
| Body Large | 14px | 400 | Descriptions, body content |
| Body Medium | 13px | 400 | Metadata, secondary content |
| Label Small | 11px | 600 | Badges, chips, nav labels |

Font family: Roboto (Material Design 3 default, ships with Flutter)

---

## Corner Radius

| Component | Radius |
|---|---|
| Cards | 12px |
| Buttons | 12px |
| Input fields | 10px |
| Chips / badges | 8px |
| Avatars / icons | 10px |
| Dialogs | 16px |
| Circular elements | 50% |

---

## Card Style

Cards use a white background (`#FFFFFF`) with a 1px solid border (`#EEEEEE`) and a subtle shadow (`elevation: 1, shadowColor: Colors.black12`). No heavy elevation. This keeps cards feeling light and clean without floating unnaturally above the warm off-white page background.

```dart
CardTheme(
  color: Color(0xFFFFFFFF),
  elevation: 1,
  shadowColor: Colors.black12,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
)
```

---

## Flutter ThemeData Mapping

```dart
ColorScheme.fromSeed(
  seedColor: Color(0xFF2E7D32),   // primaryGreen
  primary: Color(0xFF2E7D32),
  secondary: Color(0xFFE65100),
  surface: Color(0xFFF5F5F0),
  onPrimary: Colors.white,
  brightness: Brightness.light,
)
```

---

## Screen Mockups

Mockup images are in the `/design/` folder:

| File | Screen |
|---|---|
| `01_home_screen.png` | Buyer home — seller list + product grid + search |
| `02_detail_screen.png` | Seller profile — stats, products, order CTA |
| `03_form_screen.png` | Register — buyer/seller toggle + validated form fields |

---

*Design system version 1.0 — Week 1 AfriMarket Project*
