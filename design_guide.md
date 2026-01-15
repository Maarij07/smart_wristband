# Smart Wristband Design Guide

## Overview
This document outlines the design principles and component guidelines for the Smart Wristband application, following Apple's Human Interface Guidelines with strict black/white minimalism.

## Core Philosophy
- **Minimalist**: Black and white only with maximum 10% accent usage
- **Typography-driven**: Clear visual hierarchy through font weights and sizes
- **Generous whitespace**: Ample padding and breathing room
- **Pixel-perfect**: Precise alignment and measurements
- **Functional beauty**: Form follows function

## Color System

### Primary Palette
- **Black**: #000000 (Primary text, accents)
- **White**: #FFFFFF (Background, surfaces)
- **Near Black**: #111111 (Secondary text)
- **Near White**: #FAFAFA (Subtle backgrounds)
- **Medium Gray**: #888888 (Disabled text, secondary content)
- **Light Gray**: #CCCCCC (Borders, disabled states)
- **Very Light Gray**: #EEEEEE (Dividers, subtle backgrounds)

### Usage Rules
- **Maximum accent usage**: 10% of total interface
- **Primary text**: Black (#000000)
- **Secondary text**: Medium Gray (#888888)
- **Disabled text**: Light Gray (#CCCCCC)
- **Surfaces**: White (#FFFFFF) or Near White (#FAFAFA)
- **Dividers**: Very Light Gray (#EEEEEE)

## Typography

### Font Family
- **Primary**: San Francisco (iOS) / SF Pro
- **Fallback**: System font stack

### Hierarchy
- **Display**: 36px, Extra Bold (Main headers - "Welcome back", "Forgot your password?")
- **Headings**: 32px, Bold (Secondary headers)
- **Subheadings**: 24px, Semi-bold (Section titles)
- **Body Large**: 18px, Regular (Main content)
- **Body**: 16px, Regular (Standard text)
- **Caption**: 14px, Regular (Supporting text, labels)
- **Small**: 12px, Regular (Fine print, footnotes)

## Layout & Spacing

### Grid System
- **Base unit**: 8px
- **Padding scale**: 8px, 16px, 24px, 32px, 40px, 48px, 64px, 80px
- **Component heights**: 44px minimum, 48px preferred

### Screen Structure
- **Direct screen usage**: Content uses screen padding directly, no unnecessary containers
- **Consistent vertical positioning**: 80px top padding for content alignment across screens
- **Natural scrolling**: Full-width content with appropriate edge padding
- **SafeArea integration**: Proper handling of device notches and bars

### Spacing Principles
- **Generous whitespace**: Ample breathing room between elements
- **Visual rhythm**: Consistent 8px baseline grid
- **Content hierarchy**: Clear spacing relationships between sections
- **Edge harmony**: Balanced margins that respect screen boundaries

## Components

### Buttons
- **Height**: 48px preferred (44px minimum)
- **Width**: Full-width on mobile
- **Padding**: 16px horizontal, 16px vertical
- **Corner radius**: 8px
- **Typography**: 16px Semi-bold
- **States**: Default, Loading, Disabled
- **Primary**: Black background, White text
- **Secondary**: White background, Black border, Black text

### Text Fields
- **Height**: 48px (increased for better touch targets)
- **Padding**: 16px horizontal, 16px vertical
- **Border**: 1px solid Very Light Gray (#EEEEEE)
- **Focus state**: 2px solid Black
- **Error state**: 1px solid Black
- **Typography**: 16px Regular with 1.4 line height

### Cards
- **Usage**: Minimal - direct screen content preferred
- **When used**: Subtle containers for grouped related elements
- **Padding**: 24px
- **Corner radius**: 12px
- **Border**: 1px solid Very Light Gray (#EEEEEE)
- **No shadows**: Flat, clean surfaces

## Apple Design Principles

### Clarity
- **Legible typography**: Clear font choices and sizing
- **Intentional whitespace**: Purposeful empty space
- **Visual hierarchy**: Clear content organization

### Deference
- **Content first**: Interface supports, not competes
- **Subtle interactions**: Minimal visual feedback
- **Clean surfaces**: Uncluttered presentation

### Depth
- **Layered interfaces**: Clear visual levels
- **Meaningful transitions**: Purposeful animations
- **Contextual relationships**: Logical grouping

## Mobile-First Approach

### Touch Targets
- **Minimum size**: 44px x 44px
- **Spacing**: 8px minimum between interactive elements
- **Gestures**: Tap, swipe, long press support

### Responsive Behavior
- **Portrait**: Single column layout
- **Landscape**: Optimized for wider screens
- **Adaptive**: Component resizing based on screen dimensions

### Performance
- **Smooth animations**: 60fps transitions
- **Efficient rendering**: Minimal redraw operations
- **Fast interactions**: Immediate response to user input