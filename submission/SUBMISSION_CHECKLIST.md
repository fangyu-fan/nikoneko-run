# Niko Neko Run — submission checklist

## Prepared in this folder

- [x] Localized App Store metadata (繁體中文 + English)
- [x] Promotional text, keywords, description, and What's New
- [x] App Review notes and test path
- [x] Privacy policy draft and deployable HTML draft
- [x] App privacy questionnaire working answers
- [x] 6.7-inch and 6.5-inch screenshot candidates
- [x] 1024 × 1024 app icon copy
- [x] Screenshot index and captions

## Must complete before pressing Submit for Review

- [ ] Create and publish the privacy policy URL; replace `<your-domain>` in App Store Connect.
- [ ] Create and publish the support URL; replace `<your-domain>` in App Store Connect.
- [ ] Confirm bundle ID, Team, signing, version 1.0, and build number 1 in the archive.
- [ ] Decide whether the on-device display name should be localized (`Nikoneko Run` is currently in `Info.plist`); add localized `InfoPlist.strings` if the Chinese name should appear under the icon.
- [ ] Run the final archive on a clean iPhone: onboarding, permission denied, timer, stop, report, settings, export, widgets, and Live Activity.
- [ ] Replace screenshot candidates with final-binary captures if any UI or copy differs.
- [ ] Confirm App Store icon has no transparency and is the intended final artwork.
- [ ] Verify all Lottie character animation licenses/attributions before distribution.
- [ ] Complete age rating, content rights, pricing/availability, and export-compliance questions.
- [ ] Re-check App Privacy answers against the final archive and enabled capabilities.
- [ ] If iCloud remains local-only, remove iCloud Sync marketing copy and consider removing unused CloudKit capability before upload.

## Recommended App Store Connect settings

- Availability: all intended territories
- Price: Free (confirm the business decision)
- Age rating: complete the questionnaire; no gambling, violence, sexual content, or user-generated content is expected
- App Review contact: add the owner’s current name, phone, and email
