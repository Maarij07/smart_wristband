# Smart Wristband App - Design Guide

## Overview
This document outlines the design principles, components, and guidelines for the Smart Wristband Flutter application. All developers should follow these standards to ensure a consistent and cohesive user experience.

## Design System
The application follows the **shadcn/ui** design system for a modern, professional dark theme interface. All colors, components, and interactions are based on the official shadcn dark theme specification.

## Color Palette (shadcn Dark Theme)

### Core shadcn Colors
All colors are defined in `colors.json` and accessible via `AppColors` utility class.

- **background**: `#020817` - Main application background
- **foreground**: `#f1f5f9` - Primary text and content
- **card**: `#1e293b` - Card backgrounds and containers
- **cardForeground**: `#f1f5f9` - Text on cards
- **popover**: `#1e293b` - Popover/modal backgrounds
- **popoverForeground**: `#f1f5f9` - Text in popovers
- **primary**: `#3b82f6` - Primary actions and interactive elements
- **primaryForeground**: `#f8fafc` - Text on primary elements
- **secondary**: `#1e293b` - Secondary actions
- **secondaryForeground**: `#e2e8f0` - Text on secondary elements
- **muted**: `#cbd5e1` - Muted text and supporting content
- **mutedForeground**: `#94a3b8` - Secondary text and placeholders
- **accent**: `#334155` - Accent elements and highlights
- **accentForeground**: `#e2e8f0` - Text on accent elements
- **destructive**: `#ef4444` - Destructive actions (delete, error)
- **destructiveForeground**: `#f8fafc` - Text on destructive elements
- **border**: `#334155` - Borders and dividers
- **input**: `#0f172a` - Input field backgrounds
- **ring**: `#3b82f6` - Focus rings and active states

### Chart Colors
- **chart1**: `#3b82f6` - Blue charts
- **chart2**: `#8b5cf6` - Purple charts
- **chart3**: `#ec4899` - Pink charts
- **chart4**: `#f59e0b` - Amber charts
- **chart5**: `#10b981` - Green charts

### Legacy Colors (Deprecated)
The following legacy colors are maintained for backward compatibility but should not be used in new components:
- **black**: `#000000`
- **darkGrey**: `#121212`
- **smokeBlack**: `#1a1a1a`
- **smokeyGrey**: `#2d2d2d`
- **successMain**: `#4caf50`
- **warningMain**: `#ff9800`
- **errorMain**: `#f44336`
- **infoMain**: `#2196f3`

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
- Use shadcn_flutter's Button component with `AppColors.primaryButtonStyle()`
- Primary buttons: `background: primary (#3b82f6)`, `foregroundColor: primaryForeground (#f8fafc)`
- Secondary buttons: Use `AppColors.outlineButtonStyle()` with border color `#334155`
- All buttons: 44dp height, 8dp corner radius
- Touch target minimum: 48x48dp
- Hover states: Slight elevation change (2dp) with smooth transition

### Cards
- Background: `card (#1e293b)`
- Border: `border (#334155)` with 1px width
- Shadow: Custom shadow with 24px blur, 8px offset, 30% opacity
- Padding: 32dp for main cards, 16dp for smaller components
- Corner radius: 16dp for cards, 8dp for inputs
- Use `AppColors.cardDecoration()` for consistent styling

### Lists
- Dividers: `border (#334155)` with 1px height
- Item padding: 16dp horizontal, 12dp vertical
- Secondary text: `mutedForeground (#94a3b8)`
- Active items: Highlight with `accent (#334155)` background
- Hover effects: Subtle opacity change (hover:bg-accent)

### Navigation
- Inactive items: `mutedForeground (#94a3b8)`
- Active items: `foreground (#f1f5f9)`
- Selected indicator: `primary (#3b82f6)` underline or dot
- Background: `background (#020817)` or `card (#1e293b)`
- Hover states: `accent (#334155)` background with smooth transition

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

### shadcn Dark Theme Standards
- **Background**: `background (#020817)` - Primary app background
- **Surfaces**: `card (#1e293b)` - Elevated containers and cards
- **Inputs**: `input (#0f172a)` - Form field backgrounds
- **Borders**: `border (#334155)` - All divider lines

### Text Hierarchy
1. **Primary**: `foreground (#f1f5f9)` - Headlines, main content
2. **Secondary**: `muted (#cbd5e1)` - Supporting text
3. **Tertiary**: `mutedForeground (#94a3b8)` - Labels, placeholders
4. **Interactive**: `primary (#3b82f6)` - Links, active states

### Accessibility Compliance
- All text maintains minimum 4.5:1 contrast ratio
- Focus states clearly visible with `ring (#3b82f6)`
- Touch targets meet 48x48dp minimum
- Semantic HTML structure for screen readers

## Iconography
- **Standard icons**: 20x20dp with `mutedForeground (#94a3b8)`
- **Large icons**: 24x24dp for primary actions
- **Interactive icons**: `foreground (#f1f5f9)` when active
- **Inactive icons**: `mutedForeground (#94a3b8)`
- **Accent icons**: `primary (#3b82f6)` for important actions
- Stroke width: 1.5px for consistent line weight

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

## Premium Design Approach (shadcn Style)

### Core Philosophy
Follow shadcn's design philosophy: clean, minimal, and highly functional. Every element serves a purpose with intentional spacing, consistent typography, and thoughtful interactions.

### Component Architecture
```
shadcn System → Color Tokens → Components → Features → Screens
```

### Interaction Design
- **Hover states**: Subtle background changes using `accent (#334155)`
- **Focus states**: Clear `ring (#3b82f6)` indication with 2px width
- **Active states**: Color changes with smooth 150ms transitions
- **Loading states**: Skeleton loaders matching exact component dimensions
- **Transitions**: `Curves.easeInOutCubic` for natural movement

### Animation Standards
- **Micro-interactions**: 150-200ms duration
- **Page transitions**: 300ms with fade + slide combinations
- **Modal entrances**: 250ms scale + fade effect
- **Staggered animations**: 50-100ms delays between elements
- **Performance**: Locked at 60fps with hardware acceleration

### Visual Design Principles

#### Depth & Layering
- Cards float above background with subtle shadows
- Inputs have clear visual hierarchy with proper borders
- Overlays use semi-transparent backgrounds (`rgba(15, 23, 42, 0.8)`)

#### Typography System
- **Font**: Inter with optical sizing
- **Hierarchy**: Clear distinction between display, body, and caption text
- **Line heights**: 1.5x for body text, 1.2x for headings
- **Letter spacing**: Tight tracking for headings (-0.5px to -1px)

#### Color Strategy
- **Functional use**: Colors serve specific purposes (primary for actions, destructive for warnings)
- **Consistent application**: Same color meanings across all components
- **Accessibility first**: All color combinations pass WCAG AA standards
- **Theme flexibility**: Easy to adapt to different color schemes

## Responsive Design
- Design for various screen sizes and orientations
- Implement flexible grids and layouts
- Adapt touch targets for different screen densities
- Ensure content remains readable on all devices
- Test on common device sizes regularly

## Implementation Standards

### Color Management
All colors must be accessed through the `AppColors` utility class:

```dart
import '../utils/colors.dart';

// Good - Using color constants
Container(
  color: AppColors.card,
  child: Text('Content', style: TextStyle(color: AppColors.foreground)),
)

// Bad - Hardcoded colors
Container(
  color: const Color(0xFF1e293b), // ❌ Don't do this
  child: Text('Content', style: TextStyle(color: const Color(0xFFf1f5f9))),
)
```

### Helper Methods
Use provided utility methods for consistent styling:

```dart
// Card styling
Container(
  decoration: AppColors.cardDecoration(),
  child: childWidget,
)

// Input fields
TextField(
  decoration: AppColors.textFieldInputDecoration(
    labelText: 'Email',
    hintText: 'Enter your email',
  ),
)

// Buttons
ElevatedButton(
  style: AppColors.primaryButtonStyle(),
  onPressed: () {},
  child: Text('Submit'),
)
```

### Font Implementation
Typography uses Google Fonts Inter with proper shadcn weights:

```dart
Text(
  'Welcome back',
  style: GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w800,  // Extra bold for headers
    color: AppColors.foreground,
    letterSpacing: -0.8,
  ),
)

Text(
  'Sign in to your account',
  style: GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,  // Regular for body text
    color: AppColors.mutedForeground,
  ),
)
```

### File Structure
```
lib/
├── screens/
│   ├── splash_screen.dart
│   └── signin_screen.dart
├── utils/
│   └── colors.dart          ← Color constants and helpers
└── main.dart

assets/
└── colors.json              ← Source of truth for all colors
```

### Development Workflow
1. Reference colors from `colors.json` first
2. Add new colors to `AppColors` class
3. Use helper methods instead of manual styling
4. Test color contrast with accessibility tools
5. Maintain consistency across all components