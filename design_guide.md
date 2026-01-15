# Smart Wristband App - Design Guide

## Overview
This document outlines the design principles, components, and guidelines for the Smart Wristband Flutter application. All developers should follow these standards to ensure a consistent and cohesive user experience.

## Color Palette

### Primary Colors
- **Black**: `#000000` - Used for primary backgrounds and text
- **Dark Grey**: `#121212` - Secondary backgrounds
- **Smoke Black**: `#1a1a1a` - Surface elements

### Secondary Colors
- **Smokey Grey**: `#2d2d2d` - Cards and containers
- **Light Smokey Grey**: `#404040` - Borders and dividers
- **Medium Grey**: `#666666` - Disabled elements
- **Ash Grey**: `#808080` - Secondary text

### Accent Colors
- **Charcoal**: `#2f2f2f` - Interactive elements
- **Slate**: `#3c3c3c` - Hover states
- **Graphite**: `#4a4a4a` - Active states
- **Stone**: `#555555` - Selection indicators

### Status Colors
- **Success**: `#4caf50` - Success messages and positive feedback
- **Warning**: `#ff9800` - Warning messages and cautionary elements
- **Error**: `#f44336` - Error messages and destructive actions
- **Info**: `#2196f3` - Informational messages and notifications

### Text Colors
- **Primary Text**: `#ffffff` - Primary content text
- **Secondary Text**: `#b3b3b3` - Supporting text and labels
- **Disabled Text**: `#666666` - Inactive elements

## Typography

### Font Sizes
- **Headline Large**: 32sp (for main titles)
- **Headline Medium**: 28sp (for section headers)
- **Headline Small**: 24sp (for component headers)
- **Body Large**: 16sp (for primary body text)
- **Body Medium**: 14sp (for secondary body text)
- **Body Small**: 12sp (for captions and helper text)
- **Label Large**: 14sp (for active navigation items)
- **Label Medium**: 12sp (for icon labels and small buttons)
- **Label Small**: 11sp (for overlines and badges)

### Font Weights
- **Regular**: 400 - Standard body text
- **Medium**: 500 - Subtle emphasis
- **Semibold**: 600 - Important labels
- **Bold**: 700 - Headers and strong emphasis

## Component Guidelines

### Buttons
- Use shadcn_flutter's Button component
- Primary buttons should use the main accent color
- Secondary buttons should use light smokey grey with transparent background
- All buttons should have appropriate padding: 16dp horizontal, 8dp vertical for medium size
- Include ripple effect for touch feedback
- Minimum touch target: 48x48dp

### Cards
- Use smoke black (`#1a1a1a`) as the background
- Apply subtle elevation shadows for depth
- Maintain 16dp padding inside cards
- Use rounded corners with 8dp radius
- Include consistent spacing between elements

### Lists
- Use medium grey (`#666666`) dividers between items
- Apply 16dp horizontal padding for list items
- Maintain 8dp vertical padding for list items
- Use ash grey (`#808080`) for secondary information

### Navigation
- Bottom navigation should use slate color (`#3c3c3c`) for inactive items
- Active navigation items should use primary text color (`#ffffff`)
- Drawer navigation should maintain dark theme with proper contrast ratios

## Spacing System
- Base unit: 4dp
- 1x: 4dp - Small gaps and padding
- 2x: 8dp - Between minor elements
- 3x: 12dp - Around small components
- 4x: 16dp - Standard padding and margins
- 6x: 24dp - Section separations
- 8x: 32dp - Major visual breaks

## Layout Principles
- Use consistent margins of 16dp from screen edges
- Maintain visual hierarchy with proper contrast and sizing
- Ensure adequate touch targets (minimum 48x48dp)
- Implement responsive design for different screen sizes
- Follow platform conventions for iOS and Android

## Dark Theme Implementation
- Main background: Black (`#000000`)
- Surface elements: Smoke Black (`#1a1a1a`)
- Cards and elevated surfaces: Dark Grey (`#121212`)
- Text hierarchy maintained with proper contrast ratios
- Ensure accessibility compliance (minimum 4.5:1 contrast ratio)

## Iconography
- Use Material Icons or Cupertino Icons as appropriate for platform
- Consistent icon size: 24x24dp for standard icons
- 32x32dp for larger interactive elements
- Maintain consistent stroke width and style
- Apply primary text color for active icons
- Use secondary text color for inactive icons

## Accessibility
- Maintain sufficient color contrast ratios
- Provide alternative text for images and icons
- Support screen readers with semantic markup
- Enable dynamic text scaling
- Include keyboard navigation where applicable

## Animation Principles
- Use subtle transitions (150-300ms duration)
- Implement smooth micro-interactions
- Follow platform animation standards
- Maintain 60fps for all animations
- Provide reduced motion option for users who need it

## Premium Design Approach

### Core Philosophy
Maintain a unified design language throughout the application. Every component should feel intentionally designed as part of a cohesive system rather than assembled from disparate sources.

### Component Hierarchy
```
Design System → Foundation → Layout → Feature → Pages
```

### Micro-interactions
- Subtle hover states with 2-3% opacity changes
- Smooth elevation transitions (150ms ease-in-out)
- Loading skeletons matching exact component shapes
- Staggered entrance animations (50-100ms delays)

### Animation Framework
- Natural physics: `Curves.easeInOutCubic`
- Timing standards:
  - Quick actions: 150-200ms
  - Page transitions: 300-400ms
  - Modal entrances: 250-350ms
- Performance requirement: 60fps minimum

### Premium Visual Elements

#### Glass Morphism Effects
- Backdrop blur + transparency combinations
- Subtle inner shadows instead of heavy outer ones
- Consistent 16dp padding with optical adjustments
- Micro-rounded corners (6-8dp) for premium feel

#### Typography System
- Primary font: Inter (clean, professional)
- Strict 4px baseline grid
- Optical sizing for different weights
- Dynamic scaling based on content density

#### Color Application
- Primary black (#000000) for structural elements
- Smokey grey gradients for depth layers
- Accent colors only for interactive states
- Subtle transparency (8%, 12%, 16%) for overlays

## Responsive Design
- Design for various screen sizes and orientations
- Implement flexible grids and layouts
- Adapt touch targets for different screen densities
- Ensure content remains readable on all devices
- Test on common device sizes regularly

## Font Family Installation

Added Inter font family for premium typography:

```yaml
dependencies:
  google_fonts: ^6.1.0
```

Usage in components:
```dart
import 'package:google_fonts/google_fonts.dart';

Text(
  'Dashboard',
  style: GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  ),
)
```