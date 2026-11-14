# Security Policy

## Supported Versions

Security fixes are applied to the latest commit on `main` and to the latest published release.
Older releases may not receive security updates.

## Reporting a Vulnerability

Please do **not** open a public issue for a security vulnerability.

Use one of these private channels:

1. GitHub Security Advisories for this repository:
   <https://github.com/lutqiu1121-cpu/cup-memo/security/advisories/new>
2. If private advisories are unavailable, contact the repository owner through the
   GitHub profile and include the repository name `cup-memo` in the subject.

Please include:

- a concise description and impact;
- affected commit, release, or APK version;
- reproducible steps or a proof of concept;
- logs/screenshots with API keys, tokens, personal data, and device identifiers redacted;
- a suggested mitigation, if known.

## Response Expectations

We will acknowledge a report when possible, investigate privately, and publish a fix or
mitigation after a coordinated disclosure window. Do not include real Provider API keys,
keystores, signing credentials, or private memory/entry content in reports.

## Sensitive Data Notes

Cup Memo stores Provider API Keys through `flutter_secure_storage`. Never report a secret
in an issue, pull request, CI log, or chat transcript. If a key was exposed, revoke it at
the Provider immediately before reporting the incident.
