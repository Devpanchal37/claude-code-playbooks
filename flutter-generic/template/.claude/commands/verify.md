# Verification Command — Flutter

Run comprehensive verification on current Flutter codebase state.

## Instructions

Execute verification in this exact order:

1. **Analyze**
   - Run `flutter analyze`
   - If it fails, report errors and STOP

2. **Auto-fix**
   - Run `dart fix --apply`
   - Run `dart format . --set-exit-if-changed`
   - Re-run `flutter analyze` after fixes

3. **Test Suite**
   - Run `flutter test`
   - Report pass/fail count
   - If `--coverage` flag: run `flutter test --coverage` and report coverage %

4. **Build Check**
   - Run `flutter build apk --debug`
   - Report success or build errors

5. **Debug Output Audit**
   - Search for `print(` in `lib/` source files
   - Report locations (should be removed before commits)

6. **Security Quick Scan**
   - Search for hardcoded `http://` URLs
   - Search for `badCertificateCallback`
   - Search for `SharedPreferences` storing tokens

7. **Git Status**
   - Show uncommitted changes
   - Show files modified since last commit

## Output

Produce a concise verification report:

```
VERIFICATION: [PASS/FAIL]

Analyze:  [OK / X errors]
Fix:      [X issues auto-fixed]
Tests:    [X/Y passed, Z% coverage]
Build:    [OK/FAIL]
Prints:   [OK / X found in lib/]
Security: [OK / X issues]
Git:      [X files changed]

Ready for commit: [YES/NO]
```

If any critical issues found, list them with fix suggestions.

## Arguments

`$ARGUMENTS` can be:
- `quick` — analyze + tests only
- `full` — all checks (default)
- `pre-commit` — analyze + tests + security scan
- `pre-pr` — full checks + build verification

## Flutter Commands Used

```bash
flutter analyze
dart fix --apply
dart format . --set-exit-if-changed
flutter test
flutter test --coverage
flutter build apk --debug
grep -rn "print(" lib/ --include="*.dart"
grep -rn "http://" lib/ --include="*.dart"
grep -rn "badCertificateCallback" lib/ --include="*.dart"
git status
git diff --stat
```
