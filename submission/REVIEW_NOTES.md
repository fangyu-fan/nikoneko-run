# App Review notes — Niko Neko Run

## Reviewer summary

Niko Neko Run is a slow-jogging timer and personal activity log. It does not require an account, login, paid subscription, or server connection. All core timer and report flows work offline. Apple Health, Motion, and Notifications are optional permissions.

## Suggested review path

1. Install on an iPhone running iOS 17 or later.
2. On first launch, complete onboarding. Tap **Skip** for any permission you do not want to grant; the app remains usable.
3. On the timer screen, leave the default 15-minute countdown and tap **Start**.
4. To finish a test session, press and hold the round stop button for two seconds. Sessions shorter than one minute are intentionally not saved.
5. Open **Report** from the chart icon. Review Day / Week / Month / Year tabs and open a session row for details.
6. Open **Settings** from the gear icon. Theme, language, timer mode, metrics, metronome, notification, data export, and character choices are available there.
7. To test widgets, long-press the Home Screen, tap **+**, search **Niko Neko**, and add any widget size. Widgets populate from the app’s local summary data.
8. On a Dynamic Island device, start a run and lock the phone to inspect the Live Activity. On devices without Dynamic Island, inspect the Lock Screen Live Activity instead.

## Permission explanations

| Permission | Why it is requested | What happens if declined |
|---|---|---|
| HealthKit | Read heart rate, body mass, and height when available; write the completed running workout, active energy, and walking/running distance. | Timer and local session log still work. Health metrics remain unavailable. |
| Motion & Fitness | Read step count and distance during a run and estimate calories/cadence. | Timer still works; steps, distance, calories, and cadence remain unavailable. |
| Notifications | Schedule an optional daily reminder chosen by the user. | No reminder is scheduled. |

## Test data and hardware

- No demo account or credentials are needed.
- A physical iPhone is recommended for HealthKit, Motion, haptics, audio, and Live Activity testing.
- An Apple Watch is optional. If no heart-rate source is available, heart rate displays as unavailable and the rest of the run remains functional.
- The reviewer may use any duration; a session must reach one minute to appear in the report.

## Data and monetization

- No sign-in, user account, social features, ads, tracking SDK, or subscription.
- Local SwiftData stores the run log on the device. CSV export is user initiated and uses the system share sheet.
- The current app store configuration uses a local SwiftData store (`cloudKitDatabase: .none`). Do not describe iCloud sync as available until that implementation is enabled and verified in the archive.

## Known review checklist before upload

- Replace the placeholder Privacy Policy and Support URLs in App Store Connect.
- Test the exact archived build on a clean device, including onboarding and permission-denied paths.
- Confirm the HealthKit capability and usage descriptions match the uploaded bundle.
- Confirm all Lottie character files have redistribution rights documented by the team.
