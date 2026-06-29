# Glossary for Web Developers

If you're a web developer new to Roblox scripting, the file names and concepts can feel alien. This guide maps each Roblox concept to its web equivalent so the codebase makes sense.

## File types

| Roblox | Web equivalent | What it is |
|---|---|---|
| `LocalScript` | A `<script>` tag that runs in the browser | Code that runs on the client (player's device) |
| `ModuleScript` | An ES module (`export.js`) | A reusable module that returns a value when `require()`d |
| `Script` | A Node.js server file | Code that runs on the Roblox server (we don't use these — we're client-side only) |
| `.lua` / `.luau` | `.js` / `.ts` | Luau is Roblox's typed Lua superset |

In our project, **every file is a ModuleScript-style module** that returns a table (like `module.exports = {}`). We `require()` them or load them via `loadstring(game:HttpGet(...))`.

## Core Roblox concepts

| Roblox | Web equivalent | What it is |
|---|---|---|
| `game` | `window` / `document` | The root of the Roblox world |
| `game:GetService("Players")` | `import { Players } from 'roblox'` | A singleton service (cached in `src/game/services.lua`) |
| `Workspace` | The 3D scene / `<canvas>` | Where all 3D objects live |
| `ReplicatedStorage` | A shared CDN | Where the game stores assets + remote events that both client and server can see |
| `Players.LocalPlayer` | `window.currentUser` | The current user |
| `LocalPlayer.Character` | The player's 3D avatar | A `Model` containing `Humanoid` + body parts |
| `HumanoidRootPart` | The player's center / collider | The part used for movement + position |
| `Humanoid` | The player's "controller" | Has `Health`, `WalkSpeed`, `JumpPower` |
| `Head`, `Torso`, etc. | Body parts | Individual `Part` instances inside the Character |
| `Camera` | The viewport / `<canvas>` | `Workspace.CurrentCamera` |
| `Camera:WorldToViewportPoint(Vector3)` | WebGL `project()` | Converts a 3D world position to 2D screen pixels |
| `Instance.new("Frame")` | `document.createElement("div")` | Creates a Roblox UI element |
| `ScreenGui` | The root `<div>` for UI | Container for all 2D UI (drawn on top of the 3D world) |
| `Frame` | `<div>` | A rectangular container |
| `TextLabel` | `<span>` | Non-interactive text |
| `TextButton` | `<button>` | Interactive text/button |
| `ImageLabel` | `<img>` | Image element |
| `TextBox` | `<input type="text">` | Text input |
| `ScrollingFrame` | `<div style="overflow:auto">` | Scrollable container |
| `UIListLayout` | CSS `display:flex` with `flex-direction` | Auto-arranges children |
| `UIPadding` | CSS `padding` | Adds padding inside a frame |
| `UICorner` | CSS `border-radius` | Rounds corners |
| `UIStroke` | CSS `border` | Adds a border/stroke |
| `UIGradient` | CSS `linear-gradient` | Color gradient |
| `UIScale` | CSS `transform: scale()` | Scales a UI element |
| `TweenService` | `gsap.to()` / CSS transitions | Animates properties |
| `UserInputService` | `addEventListener('click', ...)` | Input events |
| `RunService.Heartbeat` | `requestAnimationFrame` | Fires every frame (after physics) |
| `RunService.RenderStepped` | `requestAnimationFrame` (before render) | Fires every frame (before render) |
| `task.spawn(fn)` | `setTimeout(fn, 0)` / `Promise.resolve().then(fn)` | Runs a function in a new thread |
| `task.wait(seconds)` | `await new Promise(r => setTimeout(r, ms))` | Yields the thread |
| `pcall(fn)` | `try { fn() } catch (e) { ... }` | Protected call (error doesn't propagate) |
| `BindableEvent` | `EventEmitter` | A signal you can fire + listen to |
| `RemoteEvent` | `fetch('/api/endpoint', { method: 'POST' })` | Client → server network call (one-way) |
| `RemoteFunction` | `fetch('/api/endpoint')` then `await response.json()` | Client → server → client network call |
| `CollectionService:GetTagged('bed')` | `document.querySelectorAll('[data-bed]')` | Find all objects with a tag |

## Bedwars-specific concepts

| Concept | What it means |
|---|---|
| **Knit** | A Roblox-TS framework (like Next.js for Roblox). Controllers are like React components but for game logic. |
| **Flamework** | A dependency injection framework that sits on top of Knit. |
| **@rbxts/net** | The networking library Knit uses. `Client:Get('RemoteName')` returns a remote handle. |
| **Zap networking** | A typed event system Bedwars uses for some events (e.g. `BreakBlockEventZap`). |
| **CollectionService tag** | A string label on an Instance. Like a `data-*` attribute in HTML. `CollectionService:GetTagged('bed')` returns all Instances with that tag. |
| **BrickColor** | Roblox's named color enum (e.g. "Bright red" = id 21). Bedwars uses these for team colors in the UI, but uses numeric team ids for gameplay logic. |
| **`debug.getupvalue` / `debug.getconstants`** | Luau introspection. Like JavaScript's `Function.prototype.toString()` but actually useful — lets you read closed-over variables and constants of a function. This is how we extract remote names from Knit controller methods. |
| **`hookmetamethod`** | Executor-only function. Lets you intercept a metamethod (like `__namecall`, which fires whenever `:method()` is called on an Instance). Used for the remote Spy. |
| **Drawing API** | Executor-only 2D drawing (`Drawing.new('Square')`, `'Line'`, `'Text'`, `'Circle'`). Renders on top of the game, separate from the GUI system. Perfect for ESP. UNC-standard. |

## Mental model for this project

If you're a web dev, think of it like this:

- `main.lua` is your `index.js` — boots the app, wires everything together.
- `src/ui/library.lua` is your component library (like a hand-rolled React + Tailwind).
- `src/ui/theme.lua` is your `tailwind.config.js` + `design-tokens.json`.
- `src/features/*.lua` are your React hooks (each one is a self-contained feature with a `setEnabled` API).
- `src/game/remotes.lua` is your API client (like an `api.js` with `fetch` calls).
- `src/game/workspace.lua` is your Zustand store (cached entities that features read from).
- `src/config.lua` is your `localStorage` + `useLocalStorage` hook.

## Common gotchas

1. **Roblox is single-threaded but coroutine-based.** `task.spawn` creates a coroutine, not an OS thread. Don't expect true parallelism.
2. **`wait()` is deprecated.** Use `task.wait(seconds)`.
3. **`Instance.new` is expensive.** Don't create UI elements in a hot loop. Cache them.
4. **`GetService` is cheap but not free.** We cache it in `services.lua`.
5. **`Player.Team` doesn't work in Bedwars.** Use `Player:GetAttribute('Team')`.
6. **`Humanoid.Health` doesn't work in Bedwars.** Use `Character:GetAttribute('Health')`.
7. **Remotes are NOT in ReplicatedStorage in Bedwars.** They're Knit-managed. See [`REMOTES.md`](REMOTES.md).
8. **Mobile has no hover.** Don't rely on `MouseEnter`/`MouseLeave` for core interactions.
9. **`Drawing.new` is executor-only.** It's not part of vanilla Roblox. It's UNC-standard though, so all major mobile executors support it.
10. **`gethui()` is executor-only.** It returns a safe parent for your ScreenGui (CoreGui is locked in vanilla Roblox). We try `gethui()` first, fall back to `CoreGui`, then `PlayerGui`.
