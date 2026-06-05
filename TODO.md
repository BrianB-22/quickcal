# QuickCal — TODO

## Calendar

- [ ] **Date range selection** — shift-click to select a range; show day count in the stats area
- [ ] **Mini month preview** — small prev/next month thumbnails on hover of the nav arrows

## Calendar Stats Panel

- [ ] **This Day in History** — 1–2 notable events for today's date from a local hardcoded database
- [ ] **Upcoming holidays** — next 2–3 holidays across all enabled countries with a live day countdown
- [ ] **Mini countdowns** — user-pinned events (name + date) with a live day counter; add via + button; persisted in UserDefaults

## World Clock

- [ ] **Full IANA search** — already ships; consider showing continent grouping in results

## Q&A Engine

- [ ] **More patterns** — "is this a leap year", "what quarter is it", "how many weeks until X", "next Friday"
- [ ] **Smarter date parsing** — "next Friday", "third Tuesday in August", "end of month"

## System Integration

- [ ] **Calendar.app events** — read system calendar via EventKit; show colored dots on days with events; tooltip lists event titles

## UX Polish

- [ ] **Keyboard navigation** — arrow keys move the selected day on the calendar
- [ ] **Copy date on click** — clicking an already-selected date copies it to clipboard (MM/DD/YYYY, long form, or ISO 8601 — configurable)
- [ ] **Custom hotkey** — let user change the global hotkey from ⌥Space in Settings
- [ ] **Compact mode** — smaller popover option (calendar only, no clock panel)

---

## Future Maintenance

- [ ] **Extend lunar holiday tables to 2040** — India (Holi, Diwali, Eid ×2, Dussehra), Singapore (CNY, Vesak, Hari Raya ×2, Deepavali), Japan (equinox dates) are hardcoded through 2030. Add the next decade's dates before releasing a 2030 update. *(No urgency until ~2029)*

## Shipped ✓

- [x] Menu bar popover (⌥Space global hotkey)
- [x] Month calendar with navigation
- [x] US federal holidays — orange/teal dots, observed date hollow ring
- [x] International holidays — US, India, UK, Canada, Australia, France, Germany, Poland (multi-select)
- [x] Holiday dot legend in Settings
- [x] Week starts on Monday option
- [x] ISO week numbers in left gutter
- [x] Calendar stats panel — moon phase, season, year progress bar, day stats (updates on date click)
- [x] World clock — local time panel with seconds
- [x] Added timezone panels — time, city label, date, UTC offset
- [x] Drag to reorder timezone panels
- [x] Timezone rename + delete via ⓘ popover (shows IANA identifier read-only)
- [x] Pin timezone to menu bar — flag + time next to icon, persists across restarts
- [x] Add Time Zone sheet — 30 popular suggestions + full IANA search fallback
- [x] Natural language Q&A bar — timezone lookup, business day math, days until/since, holiday lookup, and more
- [x] Settings — 12/24h, holidays, countries, week start, week numbers, launch at login, global hotkey
- [x] dejatechsolutions.com link + v1.0 in Settings footer
