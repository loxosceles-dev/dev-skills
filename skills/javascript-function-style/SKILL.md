---
name: javascript-function-style
description: When to use arrow functions vs function declarations. Follow when writing JavaScript or TypeScript functions.
type: guideline
---

# JavaScript/TypeScript Function Style

**This is a strict guideline.** Follow these rules exactly.

How to write functions in JavaScript and TypeScript projects.

---

## Function Declarations vs Arrow Functions

**Use `function` keyword for:**
- Regular function definitions
- Top-level functions
- Named functions that need hoisting

**Use arrow functions for:**
- Array methods (`.map()`, `.filter()`, `.reduce()`)
- Inline callbacks
- React component props
- When you need lexical `this` binding

---

## Examples

```typescript
// ✅ Regular functions
function calculateTotal(items: Item[]): number {
  return items.reduce((sum, item) => sum + item.price, 0);
}

function UserProfile({ userId }: Props) {
  return <div>{userId}</div>;
}

// ✅ Arrow functions in appropriate contexts
const numbers = [1, 2, 3].map(n => n * 2);

const handleClick = () => {
  console.log('clicked');
};

<Button onClick={() => handleSubmit()} />
```

---

## Why This Pattern

- **Consistency**: Clear rule makes codebase predictable
- **Readability**: Function declarations are more explicit
- **Flexibility**: Arrow functions where they provide value (conciseness, lexical scope)

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
