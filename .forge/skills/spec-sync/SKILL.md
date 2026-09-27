---
name: spec-sync
description: Audit traceability between OpenSpec specs and Minitest tests. Use when checking coverage gaps, finding untested specs, or verifying @spec tags are correct.
---

# Spec Sync — OpenSpec / Minitest Traceability Audit

Produces a traceability report showing which OpenSpec requirements and scenarios have test coverage, which tests reference specs, and where gaps exist.

**Input**: Optionally specify one or more spec names to scope the audit (e.g., `/spec-sync phone-identity`). If omitted, audit all specs.

## Steps

### 1. Collect specs

Read every `openspec/specs/*/spec.md` file. For each spec, extract:

- **Spec name** — the folder name (e.g., `phone-identity`)
- **Requirements** — each `### Requirement: <name>` heading
- **Scenarios** — each `#### Scenario: <name>` under a requirement

Build a map:

```
spec-name:
  Requirement: <name>
    - Scenario: <name>
    - Scenario: <name>
  Requirement: <name>
    - Scenario: <name>
```

If a spec name argument was provided, filter to only those specs (warn if a name doesn't match any folder).

### 2. Collect test tags

Search all files under `test/` for `# @spec` comments. For each match, extract:

- **File path** and line number
- **Spec references** — parse the `# @spec` value, which may contain:
  - Simple refs: `# @spec phone-identity`
  - Scenario refs: `# @spec phone-identity:Reject duplicate phone number`
  - Multi refs: `# @spec phone-identity, verification-codes`
  - Multi scenario refs: `# @spec phone-identity:Reject duplicate phone number, verification-codes:Generate code`
- **Test name** — the test method name from the next `test "..."` line (or the class name for file-level tags)
- **Scope** — whether the tag is file-level (before the class definition or at class level before any test) or inline (immediately before a specific test)

Build a map:

```
spec-name:
  - test: "test name"
    file: test/path/file_test.rb:42
    scenario: null | "Scenario name"
  - ...
```

### 3. Cross-reference and classify

For each spec, determine coverage status:

| Status | Meaning |
|--------|---------|
| **Covered** | At least one test references this spec (or a scenario within it) |
| **Partially covered** | Some scenarios are referenced by tests, others are not |
| **Uncovered** | No tests reference this spec at all |

For each test tag, validate:
- The referenced spec folder exists in `openspec/specs/`
- If a scenario is referenced, it exists in the spec file
- Flag **orphan references** — `@spec` tags pointing to nonexistent specs or scenarios

### 4. Output the report

Display a traceability matrix grouped by spec. Use this format:

```
## Spec Traceability Report

### phone-identity (3/5 scenarios covered)

| Scenario | Status | Test |
|----------|--------|------|
| Normalize various phone formats | Covered | test/models/phone_number_test.rb:15 — "normalizes various formats to E.164 during validation" |
| Assume US country code | Gap | — |
| Reject duplicate phone number | Covered | test/models/phone_number_test.rb:40 — "rejects duplicate phone number" |
| Reject blank phone number | Covered | test/models/phone_number_test.rb:34 — "requires number to be present" |
| Create user with phone number | Gap | — |
| Reject user without phone number | Gap | — |

**Tests without scenario specificity:**
- test/models/user_test.rb:6 — (file-level) `# @spec phone-identity`

---

### verification-codes (4/4 scenarios covered)
...

---

## Summary

| Spec | Scenarios | Covered | Gaps |
|------|-----------|---------|------|
| phone-identity | 5 | 3 | 2 |
| verification-codes | 4 | 4 | 0 |
| phone-verification-flow | 3 | 1 | 2 |
| ... | ... | ... | ... |
| **Total** | **20** | **14** | **6** |

### Uncovered specs (no tests at all)
- rate-limiting
- session-management

### Orphan references (tag points to nonexistent spec or scenario)
- test/foo_test.rb:12 — `# @spec nonexistent-spec` (spec not found)
```

### 5. Matching tests to scenarios

When a test tag references a spec **without** a scenario suffix (e.g., `# @spec phone-identity`), try to match it to a scenario by comparing the test name to scenario names using these heuristics:

1. **Exact substring** — the test name contains the scenario name (case-insensitive)
2. **Key phrase overlap** — significant words from the scenario name appear in the test name
3. **Contextual proximity** — if the test clearly validates the behavior described by a scenario

If a match is found, mark the scenario as covered and note the match was inferred (not explicit). If no match, list the test under "Tests without scenario specificity" for that spec — these tests provide spec-level coverage but don't pin to a specific scenario.

### 6. Suggest improvements (optional)

After the report, offer to:

1. **Add missing `@spec` tags** — for tests that clearly map to a spec but lack the tag
2. **Add scenario specificity** — upgrade `# @spec phone-identity` to `# @spec phone-identity:Reject duplicate phone number` where the match is unambiguous
3. **List scenarios that need tests** — the uncovered scenarios, with a suggested test level (unit/controller/system) based on what the scenario describes

Only make changes if the user confirms. Never auto-edit test files.

## Guardrails

- Read-only by default — this skill produces a report, it does not modify files unless the user explicitly asks
- Don't invent coverage — if a test doesn't reference a spec via `@spec`, don't count it as coverage even if the test name seems related. Only count `@spec`-tagged tests.
- Exception to above: in Step 5, inferred matches are clearly labeled as inferred, not treated the same as explicit tags
- Validate spec names against actual folder names in `openspec/specs/`
- Validate scenario names against actual `#### Scenario:` headings in the spec file
- If no specs exist, say so and exit
- If no `@spec` tags exist in tests, report all specs as uncovered
