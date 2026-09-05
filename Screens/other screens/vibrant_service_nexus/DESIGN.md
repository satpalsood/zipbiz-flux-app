---
name: Vibrant Service Nexus
colors:
  surface: '#fbf9f8'
  surface-dim: '#dcd9d9'
  surface-bright: '#fbf9f8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f3f2'
  surface-container: '#f0eded'
  surface-container-high: '#eae8e7'
  surface-container-highest: '#e4e2e1'
  on-surface: '#1b1c1c'
  on-surface-variant: '#5a4136'
  inverse-surface: '#303030'
  inverse-on-surface: '#f3f0f0'
  outline: '#8e7164'
  outline-variant: '#e2bfb0'
  surface-tint: '#a04100'
  primary: '#a04100'
  on-primary: '#ffffff'
  primary-container: '#ff6b00'
  on-primary-container: '#572000'
  inverse-primary: '#ffb693'
  secondary: '#6b4ea4'
  on-secondary: '#ffffff'
  secondary-container: '#bfa1fe'
  on-secondary-container: '#4f3287'
  tertiary: '#0062a1'
  on-tertiary: '#ffffff'
  tertiary-container: '#059eff'
  on-tertiary-container: '#003357'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdbcc'
  primary-fixed-dim: '#ffb693'
  on-primary-fixed: '#351000'
  on-primary-fixed-variant: '#7a3000'
  secondary-fixed: '#eaddff'
  secondary-fixed-dim: '#d2bbff'
  on-secondary-fixed: '#25005a'
  on-secondary-fixed-variant: '#52358a'
  tertiary-fixed: '#d0e4ff'
  tertiary-fixed-dim: '#9ccaff'
  on-tertiary-fixed: '#001d35'
  on-tertiary-fixed-variant: '#00497b'
  background: '#fbf9f8'
  on-background: '#1b1c1c'
  surface-variant: '#e4e2e1'
  status-closed: '#D32F2F'
  status-open: '#2E7D32'
  surface-subtle: '#F5F5F7'
  accent-purple-light: '#6B4FA3'
typography:
  display-lg:
    fontFamily: Hanken Grotesk
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Hanken Grotesk
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Hanken Grotesk
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
  headline-md:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-sm:
    fontFamily: Hanken Grotesk
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Work Sans
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Work Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Work Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-lg:
    fontFamily: Work Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.05em
  label-md:
    fontFamily: Work Sans
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  container-margin-mobile: 16px
  container-margin-desktop: 64px
  gutter: 24px
  section-gap-lg: 80px
  section-gap-sm: 40px
---

## Brand & Style

The design system is built to facilitate immediate trust and efficiency for a dual-sided marketplace. It balances the high-energy urgency of home repairs with the professional reliability required for domestic services.

The visual style is **Corporate / Modern** with subtle **Tactile** influences. It prioritizes clarity and functional density to ensure users can find, vet, and book professionals with minimal cognitive load. The aesthetic avoids unnecessary decoration, using structural color and purposeful elevation to guide the user through the booking funnel.

**Key Attributes:**
- **Professional:** Clean layouts that communicate legitimacy.
- **Urgent but Calm:** High-visibility CTAs balanced by generous whitespace.
- **Approachable:** Friendly rounded corners and clear, humanist typography.

## Colors

The palette is driven by the vibrant orange (`#FF6B00`), used strategically for primary actions, notifications, and brand-critical touchpoints to evoke energy and promptness. The deep purple (`#4B2E83`) provides a grounding contrast, used for navigation, headers, and secondary UI elements to establish an aura of institutional stability.

- **Primary:** Reserved for high-priority interactive elements (Search buttons, "Book Now").
- **Secondary:** Used for structural elements and secondary interactive roles to prevent visual fatigue from the primary orange.
- **Neutral:** A deep charcoal is used for primary text to maintain high legibility against the white background.
- **Functional:** Red is strictly reserved for "Closed" statuses or errors, while a balanced green is introduced for "Verified" badges or "Available Now" indicators.

## Typography

This design system utilizes a dual-font approach to maximize readability and brand distinction. **Hanken Grotesk** is used for headlines to provide a sharp, contemporary edge that feels modern and tech-forward. **Work Sans** is employed for body and label text due to its exceptional clarity at small sizes and neutral tone.

**Usage Guidelines:**
- **Headlines:** Use Hanken Grotesk for all titles. Keep tracking tight on larger sizes to maintain a punchy, editorial feel.
- **Body:** Work Sans is the workhorse for testimonials, service descriptions, and form labels.
- **Labels:** Use uppercase for `label-lg` in category tags and metadata to create visual hierarchy without increasing font size.

## Layout & Spacing

The layout follows a **Fixed Grid** model on desktop and a **Fluid Grid** on mobile devices. A 12-column system is used for wide screens, while a 4-column system is standard for mobile.

**Spacing Rhythm:**
- A base unit of **8px** governs all padding and margins.
- **Service Listings:** Displayed in a card-based grid with 24px gutters to allow each provider's information sufficient breathing room.
- **Information Density:** High density is permitted within cards and search results to facilitate quick comparison, but section-level margins are generous to prevent visual overwhelm.

## Elevation & Depth

Hierarchy is established through **Tonal Layers** supplemented by **Ambient Shadows**.

- **Level 0 (Background):** Pure white or `#F5F5F7` for secondary sections.
- **Level 1 (Cards/Inputs):** White surface with a very soft, diffused shadow (10% opacity) and a 1px subtle border (`#EEEEEE`). This level is used for service provider cards and category icons.
- **Level 2 (Modals/Dropdowns):** Higher elevation with increased shadow spread to indicate interactive priority over the main content.
- **Interaction:** On hover/active states, cards should lift slightly (shadow deepens) to provide tactile feedback.

## Shapes

The shape language is **Rounded**, utilizing an 8px (`0.5rem`) base radius for standard components. This softening of the UI helps the platform feel more approachable and user-friendly, balancing the professional corporate typography.

- **Standard (8px):** Buttons, Input fields, Service cards.
- **Large (16px):** Promotional banners, Hero containers.
- **Full (Pill):** Category chips, "Verified" badges, and navigation toggles.

## Components

### Buttons
- **Primary:** Vibrant Orange (`#FF6B00`) with white text. Bold, 8px rounded corners.
- **Secondary:** Deep Purple (`#4B2E83`) or Purple Outline. Used for less urgent actions like "View Profile."
- **Ghost:** Minimal padding, used for "See All" or secondary navigation links.

### Cards
Service cards are the primary vessel for information. They must include:
- A clear profile image with 8px radius.
- Star rating and review count.
- Status badge (e.g., "Available Now" or "Closed").
- Clear pricing or "Get Quote" CTA.

### Form Fields
Inputs use a subtle light gray background (`#F5F5F7`) with an 8px radius. On focus, the border transitions to Primary Orange. Error states use the Status-Closed red for both the border and descriptive text.

### Chips & Badges
- **Categories:** Pill-shaped with light purple backgrounds and dark purple text.
- **Verification:** Small, circular green checkmark icon accompanying the professional's name.

### Toggle
The Customer/Provider switch should be a prominent pill-shaped toggle, using the Deep Purple as the active track color to distinguish user roles clearly.