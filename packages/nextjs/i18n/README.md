# Internationalization (i18n) Implementation

This document describes the internationalization implementation for the StarkLotto application using `react-i18next`.

## Overview

The application now supports multiple languages with a complete internationalization system that includes:

- **Language Detection**: Automatic detection of user's preferred language
- **Language Switching**: Smooth language switching with persistence
- **Translation Management**: Organized translation files for easy maintenance
- **Component Integration**: All UI components use translation keys

## Supported Languages

- **English (en)**: Default language
- **Spanish (es)**: Secondary language

## File Structure

```
i18n/
├── config.ts              # i18next configuration
├── locales/
│   ├── en.json           # English translations
│   └── es.json           # Spanish translations
└── README.md             # This file
```

## Components

### I18nProvider

Wraps the application and provides translation context.

### LanguageSwitcher

A dropdown component that allows users to switch between languages.

### useLanguage Hook

Custom hook for managing language state and providing language switching functionality.

## Usage

### Basic Translation

```tsx
import { useTranslation } from "react-i18next";

function MyComponent() {
  const { t } = useTranslation();

  return <h1>{t("home.hero.title")}</h1>;
}
```

### Translation with Variables

```tsx
const { t } = useTranslation();

// In translation file: "balance": "Balance: {{balance}} $tarkPlay"
<p>{t("buyTickets.balance", { balance: 1000 })}</p>;
```

### Translation with Arrays

```tsx
const { t } = useTranslation();

// In translation file: "rules": ["Rule 1", "Rule 2", "Rule 3"]
{
  t("buyTickets.gameRules.rules", { returnObjects: true }).map(
    (rule: string, index: number) => <li key={index}>{rule}</li>,
  );
}
```

### Language Switching

```tsx
import { useLanguage } from "../hooks/useLanguage";

function MyComponent() {
  const { changeLanguage, currentLanguage } = useLanguage();

  return (
    <button onClick={() => changeLanguage("es")}>Switch to Spanish</button>
  );
}
```

## Translation Keys Structure

### BuyTicketsModal

- `buyTickets.title`: Modal title
- `buyTickets.nextDraw`: Next draw label
- `buyTickets.countdown.*`: Countdown labels (days, hours, minutes, seconds)
- `buyTickets.balance`: Balance display
- `buyTickets.pricePerTicket`: Price per ticket
- `buyTickets.ticketCount`: Ticket count with pluralization
- `buyTickets.randomForAll`: Random for all button
- `buyTickets.random`: Random button
- `buyTickets.ticketNumber`: Ticket number display
- `buyTickets.totalCost`: Total cost label
- `buyTickets.buyButton`: Buy button text
- `buyTickets.gameRules.*`: Game rules section

### Navigation

- `navigation.home`: Home link
- `navigation.howItWorks`: How it works link
- `navigation.rewards`: Rewards link
- `navigation.faq`: FAQ link

### Home Page

- `home.hero.title`: Hero section title
- `home.hero.subtitle`: Hero section subtitle
- `home.hero.playNow`: Play now button
- `home.hero.learnMore`: Learn more button

## Adding New Languages

1. Create a new translation file in `locales/` (e.g., `fr.json`)
2. Add the language to the `resources` object in `config.ts`
3. Add the language to the `languages` array in `LanguageSwitcher.tsx`

Example for French:

```tsx
// In config.ts
import fr from "./locales/fr.json";

const resources = {
  en: { translation: en },
  es: { translation: es },
  fr: { translation: fr }, // Add this
};
```

```tsx
// In LanguageSwitcher.tsx
const languages = [
  { code: "en", name: "English", flag: "🇺🇸" },
  { code: "es", name: "Español", flag: "🇪🇸" },
  { code: "fr", name: "Français", flag: "🇫🇷" }, // Add this
];
```

## Best Practices

1. **Use descriptive keys**: Use hierarchical keys like `buyTickets.title` instead of just `title`
2. **Keep translations organized**: Group related translations together
3. **Use variables for dynamic content**: Use interpolation for values that change
4. **Test all languages**: Ensure all translations work correctly
5. **Maintain consistency**: Use consistent terminology across translations

## Demo Page

Visit `/i18n-demo` to see the internationalization features in action. This page demonstrates:

- Language switching
- BuyTicketsModal with translations
- Game rules with array translations
- Countdown timer with translated labels

## Persistence

Language preferences are automatically saved to localStorage and restored on page reload. The system also detects the user's browser language on first visit.

## Performance

- Translations are loaded on-demand
- Language detection is optimized
- No unnecessary re-renders during language switching
