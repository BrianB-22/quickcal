# QuickCal — TODO

## Calendar

- [ ] **Date range selection** — shift-click to select a range; show day count in the stats area
- [ ] **Mini month preview** — small prev/next month thumbnails on hover of the nav arrows

## Calendar Stats Panel

- [ ] **This Day in History** — 1–2 notable events for today's date from a local hardcoded database
- [ ] **Upcoming holidays** — next 2–3 holidays across all enabled countries with a live day countdown
- [ ] **Mini countdowns** — user-pinned events (name + date) with a live day counter; add via + button; persisted in UserDefaults

## World Clock

- [ ] **Empty state** — first-time prompt with inline city suggestion chips when no zones added
- [ ] **Full IANA search** — already ships; consider continent grouping in results

## Q&A Engine

- [ ] **Smarter fallback** — when query almost matches, suggest closest pattern
- [ ] **Time conversion** — "convert 3pm EST to London time"

## System Integration

- [ ] **Calendar.app events** — read system calendar via EventKit; show colored dots on days with events; tooltip lists event titles

## UX Polish

- [ ] **Keyboard navigation** — arrow keys move the selected day on the calendar
- [ ] **Copy date on click** — clicking an already-selected date copies it to clipboard (MM/DD/YYYY, long form, or ISO 8601 — configurable)
- [ ] **Custom hotkey** — let user change the global hotkey from ⌥Space in Settings
- [ ] **Compact mode** — smaller popover option (calendar only, no clock panel)

---

## Future Polish

- [ ] **Light mode text contrast** — secondary and tertiary text (city labels, dates, stats strip, offset labels) may be too light in light mode; review and darken where needed for readability

## Before Release

- [ ] **App icon** — 1024×1024 PNG master + all required sizes in AppIcon.appiconset; needs to look good at 16pt (menu bar) and 512pt (App Store)

## Future Maintenance

- [ ] **Extend lunar holiday tables to 2040** — India (Holi, Diwali, Eid ×2, Dussehra), Singapore (CNY, Vesak, Hari Raya ×2, Deepavali), South Korea (Seollal, Chuseok, Buddha's Birthday), Japan (equinox dates) are hardcoded through 2030. Add the next decade's dates before releasing a 2030 update. *(No urgency until ~2029)*

---

## Shipped ✓

### Calendar
- [x] Month calendar with navigation, Today button
- [x] Week starts on Monday option
- [x] ISO week numbers in left gutter
- [x] Holiday dots — orange (national), teal (regional), hollow ring (observed weekend shift)
- [x] Multi-country holidays — 16 countries: US, India, UK, Canada, Australia, France, Germany, Italy, Japan, Brazil, Mexico, Netherlands, Poland, Singapore, South Korea, Spain
- [x] Holiday dot legend + accuracy note in Settings
- [x] Default enabled countries match default clock zones (US on first launch)

### Calendar Stats Panel
- [x] Moon phase — SF Symbol icon + name, computed locally
- [x] Season — meteorological, day within season
- [x] Year progress bar with percentage
- [x] Day stats strip — day #, week #, days left in year, business days left in month
- [x] Updates to show selected date stats when a date is clicked

### World Clock
- [x] Local time panel with flag, live seconds
- [x] Zone panels — flag, time, AM/PM, city label, date, offset (UTC or local)
- [x] UTC/Local offset toggle in header bar
- [x] Offset display — short format (+5:30, −4) without UTC prefix
- [x] Drag to reorder panels
- [x] ⓘ edit popover — rename, delete, IANA identifier shown read-only
- [x] Pin timezone to menu bar — two separate NSStatusItems, arrow always aligned
- [x] Pin persists across restarts; auto-unpins if zone deleted
- [x] Add Time Zone sheet — 30 popular suggestions + full 600+ IANA search fallback
- [x] First-launch defaults: New York, London, Paris, Singapore, Mumbai, Tokyo, Sydney

### Q&A Engine
- [x] Contraction normalization (what's, when's, it's, etc.)
- [x] Time in place — "time in SF", "tokyo time", "what time in London"
- [x] Relative dates — next Friday, last Monday, in 3 days, in 2 weeks, this Thursday
- [x] Business day math — +N business days from date
- [x] Days/weeks until, days since, days between
- [x] Date arithmetic — today + 45 days, June 1 minus 3 weeks, add 2 months to date
- [x] Age — how old is someone born June 5 1990
- [x] Duration breakdown — how long between X and Y (years, months, days)
- [x] Days in month — how many days in February 2028
- [x] Days left in year / month / quarter / period
- [x] Business days in month/quarter, business days between two dates
- [x] Month anchors — what day does August start on / end on
- [x] Nth weekday — first Monday in October, last Friday of November
- [x] Quarter info — what quarter is it, when does Q3 start/end
- [x] Leap year check
- [x] Holiday lookup and holiday check
- [x] 80+ timezone aliases

### Settings & App
- [x] 12/24h toggle in header + Settings
- [x] UTC/Local offset toggle in header + Settings
- [x] Show holidays toggle with per-country checkboxes
- [x] Week starts on Monday, show week numbers
- [x] Launch at login, global hotkey (⌥Space)
- [x] Settings footer — version, dejatechsolutions.com, copyright
- [x] Right-click menu bar icon → About QuickCal (with GitHub + website links), Quit
- [x] GitHub repo: github.com/BrianB-22/quickcal
- [x] .gitignore — excludes Xcode state, DerivedData, .DS_Store, .claude/
