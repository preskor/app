# Preskor

Web-first crypto football prediction market app.

## Tech Stack

- **Web App**: React with TypeScript (Next.js)
- **API**: NestJS with TypeScript
- **Shared Logic**: TypeScript package for probabilities, odds, quotes
- **Monorepo**: Turborepo with Yarn Workspaces

## Design

- Light theme with #00885B (teal) as primary accent color
- Web-first responsive design

## Development

```bash
# Install dependencies
yarn install

# Start development servers
yarn dev

# Build all packages
yarn build

# Run tests
yarn test

# Lint code
yarn lint
```

## Project Structure

```
preskor/
├── apps/
│   ├── web/             # Next.js web app
│   └── api/             # NestJS API
├── packages/
│   └── shared/          # Shared logic (probabilities, odds, quotes)
├── turbo.json           # Turborepo configuration
└── package.json         # Workspace configuration
```
