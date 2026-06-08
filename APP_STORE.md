# App Store — Future Work

## Technical changes required before submission

- **App Sandbox** — must be enabled for Mac App Store distribution
- **Global hotkey** — Carbon `RegisterEventHotKey` needs to be replaced; options:
  - Use `NSEvent.addGlobalMonitorForEvents` (requires Accessibility permission from user)
  - Remove the global hotkey entirely for the App Store version
- **Entitlements file** — create `QuickCal.entitlements` with sandbox entitlements
- **Privacy policy URL** — required even with zero data collection; a simple page on dejatechsolutions.com stating no data is collected is sufficient

## App Store Connect assets needed

- App icon (already have)
- Screenshots at 1280×800 or 1440×900 (Retina: 2560×1600)
- App description (can adapt from README)
- Keywords — 100 character limit, choose carefully
- Support URL — dejatechsolutions.com
- Category — Utilities

## Is it worth it?

Probably not as the primary distribution channel. Reasons:

- Mac App Store discovery for utilities is poor — dominated by established names
- Sandbox requirement adds ongoing maintenance overhead
- $99/year Apple Developer fee regardless of downloads
- Free apps get no revenue, and the App Store doesn't surface free utilities well
- No direct relationship with users (no email, no feedback loop)

**Verdict:** Developer ID + GitHub is the better primary channel. App Store is worth revisiting if the app gets traction and users start asking for it specifically.

---

## Where to actually get noticed

These will drive far more downloads than the App Store for a utility like this:

### Directories (submit free)
- **MacMenuBar.com** — dedicated to macOS menu bar apps, well-trafficked
- **Setapp** — subscription bundle; requires partnership but good exposure
- **AlternativeTo.net** — list as alternative to World Clock Pro, Time Zone Pro
- **Product Hunt** — launch with a proper post; good for initial burst of users
- **Hacker News** — "Show HN" post; global workforce angle resonates with HN audience

### Communities
- **r/macapps** — active community that loves discovering new utilities
- **r/remotework** — the global workforce angle fits perfectly here
- **r/sysadmin / r/devops** — technical users who work across timezones
- **MacRumors forums** — Mac software section
- **Twitter/X** — tag #macOS #menubar #indiedev; reach out to Mac app reviewers

### Reviewers and blogs worth pitching
- **MacStories** — covers Mac utilities
- **AppStorm / MakeUseOf** — "best menu bar apps" articles rank well in search
- **BetterTechTips, OSXDaily** — smaller but targeted Mac audience

### Timing tip
A "Show HN" or Product Hunt launch on a Tuesday or Wednesday gets the most visibility. Lead with the global workforce angle — it's a differentiator that resonates with the tech audience that dominates those platforms.
