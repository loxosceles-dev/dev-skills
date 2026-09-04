---
name: frontend-code-quality
description: "Essential guidelines for clear, maintainable frontend code — naming, component structure, state management, prop patterns. Follow when writing or reviewing frontend components, composables, or pages. For file/directory layout use component-organization. For visual design, UX, and UI critique use impeccable."
type: guideline
---

# Frontend Code Quality Guidelines

**This is a strict guideline.** Follow these rules exactly.

Essential guidelines for writing clear, maintainable frontend code.

---

## 1. Component Simplicity

**Guideline**: Keep components focused on a single responsibility.

```tsx
// ❌ Avoid: Component doing too much
function UserDashboard() {
  const [user, setUser] = useState(null);
  const [posts, setPosts] = useState([]);
  const [comments, setComments] = useState([]);
  
  useEffect(() => {
    fetch('/api/user').then(r => r.json()).then(setUser);
    fetch('/api/posts').then(r => r.json()).then(setPosts);
    fetch('/api/comments').then(r => r.json()).then(setComments);
  }, []);
  
  return (
    <div>
      {/* Complex rendering logic for user, posts, comments */}
    </div>
  );
}

// ✅ Preferred: Split into focused components
function UserDashboard() {
  return (
    <div>
      <UserProfile />
      <UserPosts />
      <UserComments />
    </div>
  );
}
```

**Guidelines**:
- Keep files focused on a single responsibility. A cohesive module with a simple interface can exceed 200 lines (up to ~400) — depth beats line count. Only split when the file has multiple unrelated concerns, not to hit a length target.
- Extract complex logic to custom hooks or utility functions when it serves a separate concern
- Avoid nested ternaries and complex conditionals in JSX

```tsx
// ❌ Avoid: Complex nested conditionals
{isLoading ? <Spinner /> : error ? <Error /> : data ? <Content data={data} /> : <Empty />}

// ✅ Preferred: Early returns or extracted logic
if (isLoading) return <Spinner />;
if (error) return <Error />;
if (!data) return <Empty />;
return <Content data={data} />;
```

---

## 2. State Management Clarity

**Guideline**: Keep state as close to its usage as possible.

```tsx
// ❌ Avoid: Unnecessary state lifting
function App() {
  const [modalOpen, setModalOpen] = useState(false);
  return <UserProfile modalOpen={modalOpen} setModalOpen={setModalOpen} />;
}

// ✅ Preferred: State where it's used
function UserProfile() {
  const [modalOpen, setModalOpen] = useState(false);
  return <Modal open={modalOpen} onClose={() => setModalOpen(false)} />;
}
```

**Guidelines**:
- Lift state only when multiple components need to share it
- Use context sparingly (auth, theme, global config only)
- Avoid prop drilling beyond 2-3 levels - use composition or context instead

```tsx
// ❌ Avoid: Deep prop drilling
<Parent user={user}>
  <Child user={user}>
    <GrandChild user={user}>
      <GreatGrandChild user={user} />
    </GrandChild>
  </Child>
</Parent>

// ✅ Preferred: Context for deeply shared data
const UserContext = createContext<User | null>(null);

function Parent() {
  const user = useUser();
  return (
    <UserContext.Provider value={user}>
      <Child />
    </UserContext.Provider>
  );
}

function GreatGrandChild() {
  const user = useContext(UserContext);
  return <div>{user.name}</div>;
}
```

---

## 3. Type Safety

**Guideline**: Define explicit types for all component interfaces.

```tsx
// ❌ Avoid: Implicit or missing types
function UserCard({ user, onEdit }) {
  return <div onClick={onEdit}>{user.name}</div>;
}

// ✅ Preferred: Explicit types
interface UserCardProps {
  user: {
    id: string;
    name: string;
    email: string;
  };
  onEdit: (userId: string) => void;
}

function UserCard({ user, onEdit }: UserCardProps) {
  return <div onClick={() => onEdit(user.id)}>{user.name}</div>;
}
```

**Guidelines**:
- Avoid `any` - use `unknown` if type is truly unknown
- Use discriminated unions for variant components
- Type event handlers explicitly

```tsx
// ✅ Discriminated unions for variants
type ButtonProps = 
  | { variant: 'primary'; onClick: () => void }
  | { variant: 'link'; href: string };

function Button(props: ButtonProps) {
  if (props.variant === 'link') {
    return <a href={props.href}>Link</a>;
  }
  return <button onClick={props.onClick}>Button</button>;
}

// ✅ Explicit event handler types
function SearchInput() {
  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    console.log(e.target.value);
  };
  
  return <input onChange={handleChange} />;
}
```

---

## 4. Data Fetching Patterns

**Guideline**: Separate data fetching from presentation.

```tsx
// ❌ Avoid: Fetching in component
function UserList() {
  const [users, setUsers] = useState([]);
  
  useEffect(() => {
    fetch('/api/users').then(r => r.json()).then(setUsers);
  }, []);
  
  return <ul>{users.map(u => <li key={u.id}>{u.name}</li>)}</ul>;
}

// ✅ Preferred: Custom hook for data fetching
function useUsers() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  useEffect(() => {
    fetch('/api/users')
      .then(r => r.json())
      .then(setUsers)
      .catch(setError)
      .finally(() => setLoading(false));
  }, []);
  
  return { users, loading, error };
}

function UserList() {
  const { users, loading, error } = useUsers();
  
  if (loading) return <Spinner />;
  if (error) return <Error message={error.message} />;
  
  return <ul>{users.map(u => <li key={u.id}>{u.name}</li>)}</ul>;
}
```

**Guidelines**:
- Handle loading, error, and empty states explicitly
- Avoid fetching in render - use hooks or effects
- Cache and deduplicate requests when using data fetching libraries

```tsx
// ✅ Handle all states
function DataDisplay() {
  const { data, loading, error } = useData();
  
  if (loading) return <LoadingState />;
  if (error) return <ErrorState error={error} />;
  if (!data || data.length === 0) return <EmptyState />;
  
  return <DataList data={data} />;
}
```

---

## 5. Naming Conventions

**Guideline**: Use consistent, descriptive names that reveal intent.

```tsx
// ❌ Avoid: Unclear or inconsistent names
function Card({ data, fn, flag }) {
  return <div onClick={fn}>{flag && data.txt}</div>;
}

// ✅ Preferred: Clear, consistent names
function UserCard({ user, onEdit, isEditable }: UserCardProps) {
  return <div onClick={onEdit}>{isEditable && user.name}</div>;
}
```

**Conventions**:
- **Components**: PascalCase (`UserProfile.tsx`)
- **Hooks**: camelCase with `use` prefix (`useUserData.ts`)
- **Utilities**: camelCase (`formatDate.ts`)
- **Constants**: UPPER_SNAKE_CASE (`API_BASE_URL`)
- **Boolean props/variables**: `is`, `has`, `should` prefix

```tsx
// ✅ Boolean naming
interface ModalProps {
  isOpen: boolean;
  hasCloseButton: boolean;
  shouldShowOverlay: boolean;
}

// ✅ Event handler naming
interface FormProps {
  onSubmit: (data: FormData) => void;
  onChange: (field: string, value: string) => void;
  onValidate: (data: FormData) => ValidationResult;
}
```

---

## 6. File Organization

**Guideline**: Organize by type, not by feature.

```
frontend/
├── components/          # All components
│   ├── ui/             # Reusable UI components
│   │   ├── Button.tsx
│   │   ├── Input.tsx
│   │   └── Modal.tsx
│   ├── UserProfile.tsx
│   ├── UserSettings.tsx
│   ├── PostList.tsx
│   └── PostCard.tsx
├── hooks/              # Custom hooks
│   ├── useUser.ts
│   ├── usePost.ts
│   └── useAuth.ts
├── lib/                # Utilities and helpers
│   ├── api/
│   ├── auth/
│   └── utils/
├── types/              # Type definitions
│   ├── user.ts
│   └── post.ts
└── queries/            # API queries (GraphQL, etc.)
    ├── user.ts
    └── post.ts
```

**Why organize by type**:
- High reusability makes feature boundaries blurry
- Easier to find components when they're used across multiple features
- Natural fit for component libraries and shared utilities

**Guidelines**:
- Group highly related files in subdirectories (e.g., `components/ui/`)
- Keep shared/reusable code accessible in `lib/` or `utils/`
- Separate business logic from UI logic

---

## Related Patterns

- **[Component Organization](component-organization.md)** - Directory structure patterns
- **[Core Principles](../../CORE_PRINCIPLES.md)** - Universal coding principles

---

**For AI Assistants**: Follow these guidelines when writing or reviewing frontend code. Prioritize clarity and maintainability over cleverness.

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
