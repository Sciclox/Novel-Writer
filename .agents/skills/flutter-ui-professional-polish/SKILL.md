---
name: flutter-ui-professional-polish
description: Improve, review, or redesign Flutter UI screens, widgets, navigation surfaces, forms, dashboards, and interactive controls with professional frontend standards. Use when asked to make a Flutter interface look more polished, modern, consistent, responsive, accessible, or production-ready; when replacing ad hoc controls with shared design-system widgets; or when fixing visual quality issues such as cramped layouts, weak hierarchy, overflow, poor hover/focus states, inconsistent colors, or bad input practices.
---

# Flutter UI Professional Polish

## Core Workflow

1. Read the target widget/screen and nearby shared UI primitives first.
2. Identify the local design system: theme, colors, typography, spacing, shared inputs, dropdowns, buttons, cards, empty states, and navigation patterns.
3. Keep the change scoped. Prefer existing `AppColors`, `ThemeData`, shared widgets, and local interaction patterns over new one-off styling.
4. Improve hierarchy before decoration: layout density, scanning order, state clarity, labels, grouping, alignment, and spacing.
5. Make controls production-grade: proper controllers/focus nodes lifecycle, semantic labels/tooltips, keyboard behavior where relevant, stable sizing, disabled/loading/empty states, and responsive constraints.
6. Validate with `dart format` and `flutter analyze <changed files>`. Run broader tests/analyze when the blast radius is larger.

## UI Quality Checklist

- Use theme tokens and shared widgets instead of hard-coded white/black opacity styling.
- Avoid one-note palettes. Use a restrained base plus purposeful accents for state, category, or hierarchy.
- Keep radius moderate and consistent. Cards and controls should feel related to the app, not independently designed.
- Ensure text fits inside controls at small and large widths. Prefer wrapping, constraints, or ellipsis over overflow.
- Give primary actions, destructive actions, selected state, hover, focus, and disabled state distinct treatments.
- Prefer icons for familiar actions and include tooltips for icon-only buttons.
- Avoid creating `TextEditingController`, `FocusNode`, or animation controllers inside `build`.
- Debounce database or disk writes triggered by text input unless immediate writes are explicitly required.
- Use `LayoutBuilder`, `Wrap`, `Flexible`, `Expanded`, and max-width constraints to make desktop Flutter layouts resilient.
- Do not add decorative gradients, blobs, or oversized hero treatments to dense productivity screens unless the existing app already relies on them.

## Forms And Inputs

- Use `TextField` or `TextFormField` with clear labels or contextual section labels.
- Set `keyboardType`, `textInputAction`, `minLines/maxLines`, and `onEditingComplete` intentionally.
- Keep placeholders helpful but short.
- Make multiline inputs visually stable; avoid layout jumps while typing.
- Persist edited values without recreating controllers on every rebuild.

## Navigation And Docks

- The active destination must be obvious without relying on subtle glow alone.
- Navigation should be discoverable when collapsed and efficient when expanded.
- Make dimensions responsive to item count and viewport size instead of using only fixed widths.
- Support mouse hover and keyboard activation for desktop surfaces where practical.
- Keep animations fast enough for repeated navigation, usually 200-450 ms.

## Final QA

Before finishing, report:

- Files changed.
- Formatting/analyze/test commands run.
- Any remaining warnings that are outside the changed files.
