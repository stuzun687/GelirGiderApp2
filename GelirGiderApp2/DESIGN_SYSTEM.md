# GelirGider App Design System

## Design Philosophy
Modern, professional financial management app with a focus on clarity, elegance, and user experience. The design language emphasizes transparency, depth, and visual hierarchy through glassmorphism and thoughtful use of color and typography.

## Core Design Elements

### Colors
- **Primary Colors**
  - Accent Blue: System Accent Color
  - Success Green: For income and positive values
  - Warning Red: For expenses and negative values
  - Neutral Gray: For secondary information

- **Background**
  - Light Mode: Clean white to light gray gradient
  - Dark Mode: Rich dark gradients
  - Glassmorphism effects with 10-20% opacity

### Typography
- **Headings**
  - Font: SF Pro Display (System)
  - Weights: Regular, Medium, Semibold
  - Primary: Title3 (.title3)
  - Secondary: Headline (.headline)

- **Body Text**
  - Font: SF Pro Text (System)
  - Regular text: Body (.body)
  - Secondary text: Subheadline (.subheadline)
  - Captions: Caption (.caption)

### Components

#### Cards
- Corner Radius: 24pt
- Shadow: Subtle (0.05 opacity)
- Glassmorphism overlay
- Gradient stroke for depth
- Padding: 24pt

#### Buttons
- Primary: Filled with accent color
- Secondary: Gray background with icon
- Toggle: With clear visual state
- Corner Radius: 12pt

#### Input Fields
- Clear background
- Subtle border or background
- Corner Radius: 12pt
- Clear labels with icons

### Icons
- SF Symbols
- Consistent weight
- Meaningful and contextual
- Size hierarchy:
  - Primary: 24pt
  - Secondary: 20pt
  - Auxiliary: 16pt

### Visual Effects
1. **Glassmorphism**
   - Background blur
   - Subtle transparency
   - Light gradient overlays
   - Thin borders (1pt)

2. **Animations**
   - Smooth transitions (0.3s)
   - Spring animations for interactions
   - Subtle scale effects
   - Rotation for toggles

3. **Depth**
   - Layer hierarchy
   - Subtle shadows
   - Gradient overlays
   - Card elevation

## Layout Guidelines

### Spacing
- Base unit: 8pt
- Content padding: 24pt
- Section spacing: 24pt
- Element spacing: 16pt
- Inner spacing: 8pt

### Structure
1. **Navigation**
   - Clean navigation bar
   - Clear titles
   - Minimal actions

2. **Content Organization**
   - Card-based layout
   - Clear visual hierarchy
   - Grouped information
   - Progressive disclosure

3. **Lists and Grids**
   - Consistent padding
   - Clear separators
   - Card-style items
   - Smooth transitions

## Transaction Types Visualization

### One-time Transactions
- Simple card design
- Clear date display
- Category icon
- Amount with color coding

### Recurring Transactions
- Special indicator icon
- Frequency badge
- Duration preview
- Next occurrence date
- Visual connection between series

## Feature-Specific Guidelines

### Dashboard
- Summary cards with glassmorphism
- Visual charts and graphs
- Quick action buttons
- Recent transactions preview

### Transaction List
- Grouped by date
- Clear type differentiation
- Smart filters
- Smooth animations

### Add Transaction
- Step-by-step flow
- Clear category selection
- Intuitive recurring setup
- Visual feedback

### Analytics
- Modern charts
- Interactive elements
- Clear legends
- Period selection

## Interaction Patterns

### Gestures
- Smooth swipe actions
- Natural transitions
- Responsive feedback
- Clear hit targets

### Feedback
- Success/error states
- Loading indicators
- Haptic feedback
- Toast messages

## Accessibility
- Clear contrast ratios
- Scalable text
- Voice over support
- Clear touch targets

## Implementation Notes
- Use SwiftUI native components
- Maintain consistent styling
- Reusable modifiers
- Component-based architecture 