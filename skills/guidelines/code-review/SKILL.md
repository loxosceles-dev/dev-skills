---
name: code-review
description: Multi-perspective code review strategy covering architecture, security, performance, and quality. Follow when reviewing code or analyzing changes.
type: guideline
---

# Code Review Guidelines

**This is a strict guideline.** Follow these rules exactly.

Multi-perspective code analysis strategy for comprehensive reviews.

---

## Review Strategy

Analyze code from four parallel perspectives:

1. **Architecture** - Alignment with patterns and principles
2. **Security** - Vulnerabilities and risks
3. **Performance** - Optimization opportunities
4. **Quality** - Maintainability and conventions

---

## Architecture Review

**Check for:**
- Alignment with CORE_PRINCIPLES
- Consistency with established patterns (see INDEX.md)
- Proper separation of concerns
- Module boundaries and dependencies
- File organization

**Report:**
- Pattern violations with doc references
- Architectural inconsistencies
- Recommendations for better alignment

---

## Security Review

**Check for:**
- Environment variable handling
- Authentication and authorization flows
- API endpoint security
- Input validation and sanitization
- Token/credential storage
- Sensitive data exposure

**Report:**
- Security vulnerabilities (critical)
- Potential risks (warnings)
- Best practice recommendations

---

## Performance Review

**Check for:**
- Inefficient algorithms or data structures
- Unnecessary computations
- Resource-intensive operations
- Caching opportunities
- Bundle size impact (frontend)
- Database query optimization (backend)

**Report:**
- Performance bottlenecks
- Optimization opportunities
- Trade-offs to consider

---

## Quality Review

**Check for:**
- Code readability and clarity
- Naming conventions
- Error handling
- Code duplication
- Test coverage
- Documentation completeness

**Report:**
- Code quality issues
- Maintainability concerns
- Convention violations

---

## Output Format

Structure findings as:

### ✅ Strengths
Brief acknowledgment of what works well

### 🔴 Critical Issues
Must be fixed (security, broken functionality, principle violations)

### 🟡 Improvements
Important but not urgent (performance, maintainability)

### 💡 Suggestions
Nice-to-have enhancements (style, minor optimizations)

### 📋 Action Items
Numbered list of specific changes with file references

---

## Review Process

1. **Analyze in parallel** - Run all four perspectives simultaneously
2. **Synthesize findings** - Combine results, remove duplicates
3. **Prioritize** - Critical → Improvements → Suggestions
4. **Be specific** - Reference files, patterns, and principles
5. **Be constructive** - Acknowledge good patterns, explain reasoning

---

## Responding to PR Review Comments

When fixing issues raised in PR review comments, reply to each comment thread with the commit hash that addresses it. Format:

```
Fixed in <commit-hash>
```

This closes the feedback loop and lets the reviewer verify the fix without searching through commits.

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
