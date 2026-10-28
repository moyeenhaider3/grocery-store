<!-- GSD:project-start source:PROJECT.md -->
## Project

**ShopKart**

ShopKart is a single-store e-commerce app. Customers browse and search a product catalog, add items to a cart, check out with cash on delivery (or a mock payment step), and track their orders. Admins run the store from the same app: they manage products, categories, stock, orders and user accounts, and see a sales dashboard. It is built as a learning-grade but production-deployed full-stack app, following the patterns proven in the sibling project `shortly`.

**Core Value:** A customer can find a product, put it in the cart, and place an order that an admin can see and move through to delivery, with stock and prices kept correct on the server.

### Constraints

- **Tech stack**: Node.js 18+, TypeScript, Express 5, MongoDB (Mongoose), JWT, bcryptjs — same as shortly, so patterns transfer
- **Tech stack**: Flutter (Dart ^3.x), flutter_bloc, Dio, go_router, shared_preferences — same as shortly
- **Hosting**: Render free tier (cold starts ~30-60 s, no persistent disk), MongoDB Atlas free tier, GitHub Pages under a subpath
- **Repo layout**: one repo, `backend/` and `frontend/` folders, like shortly
- **Security**: prices, totals and stock are always computed on the server; never trust client-sent prices. Admin checks are enforced in the backend, not just hidden in the UI
- **Data integrity**: placing an order must not oversell stock (atomic conditional decrement or a transaction)
- **Config**: no host hardcoded in UI code; everything flows from `API_BASE_URL`
- **Testing / simplicity (MVP)**: no automated tests for now. Do not add test frameworks or test files (no vitest/jest/supertest/mongodb-memory-server, no flutter_test/bloc_test/mocktail suites) and do not plan TDD tasks. Verify manually: build/typecheck (`tsc`, `flutter analyze`), curl against the local API, and clicking through the app. Keep the MVP as simple as possible: no extra layers, packages or abstractions unless a requirement needs them
<!-- GSD:project-end -->

<!-- GSD:stack-start source:STACK.md -->
## Technology Stack

Technology stack not yet documented. Will populate after codebase mapping or first phase.
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
