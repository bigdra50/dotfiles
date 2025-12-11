---
allowed-tools: [Read, Edit, Grep, Glob, TodoWrite, MultiEdit]
description: Refactor code comments following industry best practices and remove anti-patterns
---

# /refactor:clean-comments

Analyze and refactor code comments according to industry best practices, automatically removing common anti-patterns and suggesting improvements.

## Supported Languages

- C# (`.cs`)
- TypeScript/JavaScript (`.ts`, `.tsx`, `.js`, `.jsx`)
- Python (`.py`)
- Java (`.java`)
- Go (`.go`)

## Detected Anti-Patterns

### Automatically Removed

1. **Commented-out code blocks**: Dead code should be managed via version control (Git), not comments
   ```csharp
   // var oldImplementation = DoSomething(); // DELETE
   var newImplementation = DoSomethingBetter();
   ```

2. **Redundant comments**: Comments that merely translate code to natural language
   ```csharp
   i++; // increment i by 1 // DELETE - this is obvious
   ```

3. **Trivial documentation**: Self-explanatory properties/methods with obvious comments
   ```csharp
   /// <summary>Gets or sets the name.</summary> // DELETE if trivial
   public string Name { get; set; }
   ```

4. **Deletion reason comments**: Implementation decisions belong in commit messages
   ```csharp
   // Removed because already registered in XYZ // DELETE
   ```

5. **Excessive region directives** (C# specific): Overuse of `#region`/`#endregion` often indicates poor code organization
   ```csharp
   #region Private Fields // CONSIDER REMOVING
   private int _value;
   #endregion
   ```

6. **Abandoned TODO/FIXME**: Long-standing markers should be tracked in issue management systems
   ```csharp
   // TODO: Fix this later (2+ months old) // FLAG for review
   ```

### Improvement Suggestions

1. **Missing "why" explanations**: Complex logic needs context, not just "what"
   - Non-obvious performance optimizations
   - Business rule implementations
   - Workarounds for external library bugs

2. **Missing documentation for public APIs**: Public interfaces should have clear contracts
   - Parameters: purpose, constraints, valid ranges
   - Return values: meaning, possible states
   - Exceptions: when and why they're thrown

3. **External references without sources**: Citations need verification paths
   ```csharp
   // Based on RFC 3986 section 3.2 ✓ GOOD
   // Uses a complex algorithm ✗ BAD - which algorithm?
   ```

## Good Comment Examples

### Explaining "Why"
```csharp
// Use binary search instead of linear scan due to dataset size (10k+ items)
// Benchmark: 50ms → 2ms average lookup time
var index = BinarySearch(largeDataset, target);
```

### Business Rule Context
```csharp
// Per legal requirement: customer data must be retained for 7 years
// Reference: GDPR Article 17, Company Policy DOC-2023-045
var retentionPeriod = TimeSpan.FromDays(365 * 7);
```

### Workaround Documentation
```csharp
// WORKAROUND: ThirdPartyLib v2.3 has a race condition in async disposal
// Issue: https://github.com/vendor/lib/issues/1234
// Remove this delay when upgrading to v2.4+
await Task.Delay(100);
await resource.DisposeAsync();
```

## Arguments

```
/refactor:clean-comments <path> [options]
```

- `<path>`: File or directory path (required)
- Options:
  - `--dry-run`: Preview changes without modifying files
  - `--auto`: Only apply automatic deletions (skip improvement suggestions)
  - `--lang <language>`: Target specific language (cs, ts, py, java, go)

## Workflow

1. **Scan**: Parse comments in target files
2. **Classify**: Categorize into auto-remove / suggest improvement
3. **Process**:
   - Auto-remove: Delete anti-patterns (commented code, redundant comments)
   - Suggest: List issues for manual review
4. **Report**: Display summary of changes

## Usage Examples

```bash
# Single file cleanup
/refactor:clean-comments src/services/AuthService.cs

# Directory scan with preview
/refactor:clean-comments src/core --dry-run

# Auto-fix only (no manual review prompts)
/refactor:clean-comments src/utils --auto

# Target specific language
/refactor:clean-comments src --lang ts
```

## Best Practices Applied

Based on industry standards:

- **Code Tells "What", Comments Tell "Why"**: Prefer self-documenting code
- **DRY for Comments**: Don't repeat information already in code
- **Document Contracts, Not Implementations**: Focus on API behavior, not internals
- **Version Control Over Comments**: Historical context belongs in Git history
- **Issue Trackers for TODOs**: Long-term work items need proper tracking

## Safety Notes

- **Backup First**: Commit your work before bulk refactoring
- **Review Output**: Use `--dry-run` for large directories
- **Public API Caution**: Preserve minimal documentation for public members
- **External References**: Protect comments with RFC numbers, formula citations, or bug tracker links

## Post-Processing Recommendations

After running the command:

1. **Review changes**: `git diff` to verify modifications
2. **Run tests**: Ensure no behavioral changes
3. **Commit**: Create a focused commit with clear message
   ```bash
   git add .
   git commit -m "refactor: clean up code comments and remove anti-patterns"
   ```

## References

- [Google Engineering Practices](https://google.github.io/eng-practices/review/reviewer/looking-for.html)
- [Clean Code by Robert C. Martin](https://www.oreilly.com/library/view/clean-code-a/9780136083238/)
- [Microsoft C# Coding Conventions](https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions)
