<!--
SYNC IMPACT REPORT
==================
Version change: (none) → 1.0.0 (initial ratification)

Modified principles: N/A — initial ratification; no prior principles to rename.

Added sections:
  - Core Principles (4 principles: I. Code Quality, II. Test-First,
    III. User Experience Consistency, IV. Performance by Default)
  - Quality Gates
  - Development Workflow
  - Governance

Removed sections: N/A — initial document.

Templates requiring updates:
  - .specify/templates/plan-template.md  ✅ compatible — Constitution Check section
      already derives gates from this file; no edits required.
  - .specify/templates/spec-template.md  ✅ compatible — Success Criteria and User
      Scenarios sections align with UX-consistency and performance principles.
  - .specify/templates/tasks-template.md ✅ compatible — test-first task ordering
      (tests written before implementation) matches Principle II.
  - .claude/commands/ (all *.md)         ✅ compatible — commands use generic agent
      guidance; no CLAUDE-only specific references found that conflict.

Deferred TODOs: None — all placeholders resolved.
-->

# niessl.org.recipes Constitution

## Core Principles

### I. Code Quality

All production code MUST meet a consistent quality bar before merging. The following
rules are non-negotiable:

- Every function or method MUST have a single, clearly stated responsibility (SRP).
- Code MUST pass linting and formatting checks with zero warnings before any merge.
- No commented-out code or dead code MUST be committed to the main branch.
- All public interfaces MUST use names that express intent without requiring comments.
- Complexity MUST be justified: abstractions are introduced only when the same logic
  appears three or more times (Rule of Three); premature abstraction is prohibited.
- Dependencies MUST be reviewed for security and maintenance status before adoption.

**Rationale**: A consistent quality bar reduces cognitive overhead during review and
maintenance, lowers defect rates, and keeps the codebase approachable as the recipe
platform grows.

### II. Test-First (NON-NEGOTIABLE)

Tests MUST be written and confirmed to fail before implementation begins. No exceptions.

- The Red-Green-Refactor cycle MUST be followed: failing test → minimal implementation
  → refactor.
- Unit tests MUST cover all business logic with ≥80% line coverage on changed code.
- Integration tests MUST cover every acceptance scenario defined in a feature's spec.md.
- Tests MUST be independent: no test MUST rely on execution order or shared mutable state.
- Flaky tests MUST be fixed or removed within one sprint of detection; they MUST NOT
  be silenced or skipped as a permanent workaround.

**Rationale**: Test-first development on a content-rich recipes platform ensures
regressions are caught before users see them, and guarantees every implementation
decision traces back to a real user scenario.

### III. User Experience Consistency

The user interface MUST follow a single enforced design system across all pages.

- All UI components MUST derive from the shared component library; bespoke one-off
  styles are prohibited unless the deviation is documented and approved in the PR.
- Interaction patterns — navigation, error states, loading states, empty states — MUST
  be consistent across all features and pages.
- Accessible markup is non-negotiable: WCAG 2.1 Level AA compliance is the minimum
  standard; no critical or serious axe violations MUST be introduced.
- Typography, color, and spacing MUST use design tokens; raw hard-coded values are not
  permitted in production code.
- Copy (labels, error messages, placeholders) MUST follow the established tone guide;
  inconsistent terminology across pages is treated as a defect.

**Rationale**: Recipe browsing is a highly visual, repeated experience. Inconsistent UI
erodes user trust and raises cognitive load when users are trying to cook in real time.

### IV. Performance by Default

Every feature MUST satisfy defined performance budgets before shipping. Performance is
a feature, not an afterthought.

- Largest Contentful Paint (LCP) MUST be ≤2.5 s on a simulated 4G connection.
- Time to Interactive (TTI) MUST be ≤3.5 s on a mid-range reference device.
- API response time MUST be ≤200 ms at p95 under expected production load.
- Images MUST be served in a modern format (WebP or AVIF) with explicit `width` and
  `height` attributes; Cumulative Layout Shift (CLS) MUST be ≤0.1.
- CI MUST enforce a Lighthouse performance budget: any PR that degrades a tracked
  Lighthouse score by more than 5 points MUST pass a performance review before merge.
- No synchronous blocking operations MUST be introduced in the critical render path.

**Rationale**: A slow recipe site drives users away, especially on mobile devices used
in the kitchen. Treating performance budgets as hard gates prevents gradual degradation.

## Quality Gates

All of the following gates MUST pass before a feature is considered complete and
mergeable. Gates MUST NOT be bypassed without a documented exception approved by two
team members and recorded in the PR description.

1. **Green tests**: All unit, integration, and contract tests pass. Zero failures.
2. **Coverage threshold**: ≥80% line coverage on changed code, as reported by CI.
3. **Lint + format clean**: Zero linting errors; code formatter reports no diffs.
4. **Performance budget met**: Lighthouse CI confirms LCP ≤2.5 s, TTI ≤3.5 s,
   CLS ≤0.1 on the affected pages.
5. **Accessibility verified**: No new critical or serious axe violations introduced.
6. **Design system compliance**: UI review confirms no raw hard-coded values and no
   out-of-system components have been introduced.
7. **Peer review approved**: At least one developer other than the author has approved
   the PR after reviewing for constitution compliance.

## Development Workflow

1. **Specify first**: All non-trivial features begin with a written spec
   (`/speckit.specify`).
2. **Plan before coding**: An implementation plan (`/speckit.plan`) is required for any
   feature touching more than two files.
3. **Write tests first**: Tests MUST be written, reviewed, and confirmed failing before
   implementation begins (Principle II).
4. **Implement incrementally**: Work in user-story-sized increments; each increment
   MUST be independently testable and demonstrable.
5. **Clear all quality gates**: See Quality Gates section — all seven gates MUST pass.
6. **Review and merge**: Peer review MUST be complete and CI MUST be green.
7. **Update documentation**: Any behavior change MUST be reflected in the relevant spec,
   plan, or quickstart documents before the PR is merged.

## Governance

This constitution supersedes all other development practices, team conventions, and
informal agreements. When a conflict arises between this document and any other guidance,
the constitution is the authoritative source.

- **Amendments**: Any change to a principle MUST be proposed as a PR updating this file.
  The PR requires approval from at least two team members and MUST increment the version
  number according to the versioning policy below.
- **Versioning policy**:
  - MAJOR — principle removals, redefinitions, or backward-incompatible governance changes.
  - MINOR — new principles, new sections, or materially expanded guidance.
  - PATCH — clarifications, wording improvements, and non-semantic refinements.
- **Compliance review**: Every PR description MUST include a "Constitution Check" section
  confirming compliance with all four core principles, or documenting any justified
  exceptions with a remediation plan.
- **Exceptions**: Exceptions to any principle MUST be documented in the PR with a
  rationale and a concrete plan for removing the exception in a future iteration.
  Permanent exceptions are not permitted.

**Version**: 1.0.0 | **Ratified**: 2026-02-19 | **Last Amended**: 2026-02-19
