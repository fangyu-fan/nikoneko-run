# App Store Connect privacy questionnaire — working answers

Use these answers only after checking the exact distribution archive. The current code has no analytics SDK, ad SDK, login, or network data service, and stores the SwiftData model locally (`cloudKitDatabase: .none`).

## Recommended answers for the current build

| Question | Answer |
|---|---|
| Does this app collect data? | **No**, provided the uploaded archive has no enabled server analytics, CloudKit store, or third-party SDK that transmits data. |
| Does the app track users? | **No**. No advertising identifier, tracking SDK, or cross-app tracking. |
| Account required? | **No**. |
| Health / fitness data | Used only on device for the requested run experience and HealthKit write-back. It is not collected by a developer-controlled server. |
| User content | No public user-generated content. A user-created CSV export is handled by the iOS share sheet. |
| Encryption export compliance | No custom or proprietary encryption is implemented. Confirm the final archive’s use of only Apple platform security before selecting the App Store Connect exemption answer. |

## If the archive changes

Re-check the questionnaire if CloudKit is enabled, a crash/analytics service is added, a web API is introduced, or any third-party Lottie/SDK asset sends diagnostics. In that case, describe the transmitted data, purpose, linkage, retention, and deletion path accurately rather than using the answers above.
