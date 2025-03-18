## Strategic Approach for Continuous Integration Using GitHub Actions

### Overview of the Recommended CI Process

The following outlines a structured yet flexible approach to organizing and managing changes and releases in a GitHub repository using GitHub Actions. This strategy ensures clean merges, reliable builds, automated versioning, and streamlined deployments, aligning seamlessly with Continuous Delivery (CD) processes managed by ArgoCD, GitOps, Artifactory, and Azure Storage.

### Branch and PR Management

- **Branch Protection**: Enable branch protection rules on the `main` branch requiring pull requests (PRs) to merge. This prevents direct pushes to `main`.

### Branch Naming and PR Traceability

- Clearly name branches by incorporating relevant information such as issue numbers (e.g., `feature/123-improve-ui`).

Example branch creation commands:

**For a feature branch:**
```bash
# Create and switch to a new feature branch
git checkout -b feature/123-new-feature main
```

**For a bug fix branch:**
```bash
# Create and switch to a new bug fix branch
git checkout -b fix/456-login-issue main
```

Note: Always create branches from the latest `main`:
```bash
git checkout main
git pull
git checkout -b feature/123-new-feature
```

### Automated Workflows

1. **PR Validation Workflow**
   - Runs on PR creation/update
   - Validates code quality, tests, security
   - Ensures build artifacts can be created
   - Blocks merge if checks fail

2. **Version Management Workflow** 
   - Runs on merge to main
   - Determines semantic version bump
   - Creates Git tag and GitHub release
   - Updates version in package files

3. **Artifact Publishing Workflow**
   - Runs after version workflow
   - Builds and publishes artifacts
   - Updates deployment manifests
   - Triggers downstream deployments

Example workflow sequence:



#### Workflow 1: Validate PR

Trigger: Pull requests created against `main`

Tasks:
- **Mandatory**: Validate packaging logic (build artifacts, container images).
- **Mandatory**: Run tests, static analysis, security checks.

Example:
```yaml
# File: .github/workflows/ci-validate.yaml
name: CI Validation

on:
  pull_request:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Docker
        uses: docker/setup-buildx-action@v3
      - name: Build Docker Image
        run: docker build -t my-app:${{ github.sha }} .
      - name: Run Tests
        run: |
          npm install
          npm test
```

#### Workflow 2: Automated Semantic Release

Trigger: Push to `main`

Tasks:
- **Mandatory**: Create releases based on semantic commit messages and PR labels.
- **Optional**: Automatically update version numbers.

Use Release Drafter to automate GitHub Releases:
`https://github.com/release-drafter/release-drafter`

First, create the release drafter configuration:

```yaml:.github/release-drafter.yml
name-template: 'v$RESOLVED_VERSION'
tag-template: 'v$RESOLVED_VERSION'
categories:
  - title: '🚀 Features'
    labels:
      - 'feature'
      - 'enhancement'
      - 'feat'
  - title: '🐛 Bug Fixes'
    labels:
      - 'fix'
      - 'bugfix'
      - 'bug'
  - title: '🧰 Maintenance'
    labels:
      - 'chore'
      - 'docs'
      - 'refactor'
      
change-template: '- $TITLE @$AUTHOR (#$NUMBER)'

version-resolver:
  major:
    labels:
      - 'major'
      - 'breaking'
  minor:
    labels:
      - 'minor'
      - 'feature'
      - 'feat'
  patch:
    labels:
      - 'patch'
      - 'fix'
      - 'bugfix'
      - 'chore'
      - 'docs'
  default: patch

template: |
  ## What's Changed
  $CHANGES
  
  **Full Changelog**: https://github.com/$OWNER/$REPOSITORY/compare/$PREVIOUS_TAG...v$RESOLVED_VERSION
```

Then create the workflow:

```yaml:.github/workflows/release-drafter.yml
name: Release Drafter

on:
  push:
    branches:
      - main
  # Allows manual triggering of the workflow
  workflow_dispatch:

permissions:
  contents: read
  pull-requests: write

jobs:
  update_release_draft:
    permissions:
      contents: write
      pull-requests: write
    runs-on: ubuntu-latest
    steps:
      - uses: release-drafter/release-drafter@v5
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

This pattern provides several benefits:
1. **Automated Release Notes**: Automatically generates changelog based on merged PRs
2. **Smart Versioning**: 
   - Major version bump for breaking changes
   - Minor version bump for new features
   - Patch version bump for fixes and maintenance
3. **Categorized Changes**: Groups changes by type (features, fixes, maintenance)
4. **PR Integration**: Works with PR labels to determine version bumps and categories

To use this workflow effectively:
1. Label your PRs appropriately (`feature`, `fix`, `chore`, etc.)
2. Use semantic commit messages
3. PRs will automatically be categorized and included in the next release draft
4. Release notes are automatically generated and kept up-to-date
5. When ready to release, publish the draft release in GitHub

Example PR labels and their effects:
- `breaking` or `major`: Triggers major version bump (1.0.0 → 2.0.0)
- `feature` or `enhancement`: Triggers minor version bump (1.0.0 → 1.1.0)
- `fix` or `bugfix`: Triggers patch version bump (1.0.0 → 1.0.1)

### Commit Message Guidelines

Use semantic commit messages to clearly communicate the nature of changes. The commit message structure should be:

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

**Types and Their Impact:**
- `feat`: Introduces a new feature (triggers minor version bump)
- `fix`: Corrects a bug (triggers patch version bump)
- `docs`: Documentation updates (triggers patch version bump)
- `chore`: Maintenance tasks (triggers patch version bump)
- `refactor`: Code improvements (triggers patch version bump)
- `perf`: Performance improvements (triggers patch version bump)
- `style`: Code style changes (triggers patch version bump)
- `test`: Adding or updating tests
- `ci`: Changes to CI configuration files
- `build`: Changes affecting build system

**Breaking Changes:**
To indicate a breaking change, add `BREAKING CHANGE:` in the commit footer or append `!` after the type:

```bash
# Using footer
git commit -m "feat: add user authentication API
BREAKING CHANGE: completely new auth flow"

# Using ! syntax
git commit -m "feat!: change authentication API structure"
```

**Examples of Good Commit Messages:**

```bash
# Feature with scope
git commit -m "feat(auth): add OAuth2 login support"

# Bug fix with issue reference
git commit -m "fix(api): correct rate limiting logic (#123)"

# Breaking change with detailed description
git commit -m "feat(api)!: change user endpoints
    
Previous user endpoints are now deprecated.
New endpoints follow REST principles more closely.

BREAKING CHANGE: /api/v1/user/* endpoints now require authentication"

# Documentation update
git commit -m "docs(readme): update deployment instructions"

# Performance improvement
git commit -m "perf(database): optimize query performance"
```

**Working with Release Drafter:**

1. **Creating a Feature Branch and Commits:**
```bash
# Create feature branch
git checkout -b feature/user-auth

# Make changes and commit
git add .
git commit -m "feat(auth): implement user authentication
    
- Add login endpoint
- Implement JWT token generation
- Add password hashing"

# Push changes
git push origin feature/user-auth
```

2. **Creating a PR with Appropriate Labels:**
```bash
# Using GitHub CLI
gh pr create \
  --title "feat(auth): implement user authentication" \
  --body "Adds complete user authentication system" \
  --label "feature" \
  --label "enhancement"
```

3. **Updating PR with Additional Changes:**
```bash
# Make additional changes
git add .
git commit -m "test(auth): add authentication unit tests"
git push origin feature/user-auth

# Add more changes in separate commit
git add .
git commit -m "docs(auth): add API documentation for auth endpoints"
git push origin feature/user-auth
```

4. **Squash Merging with Semantic Message:**
When merging the PR, use a squash merge with a semantic commit message that summarizes all changes:

```bash
# If using GitHub CLI
gh pr merge feature/user-auth \
  --squash \
  --title "feat(auth): implement user authentication system (#123)" \
  --body "Added complete authentication system including:
- Login endpoints
- JWT implementation
- Password hashing
- Unit tests
- API documentation"
```

**Version Bump Examples:**
- A commit with `feat:` → Minor version bump (1.0.0 → 1.1.0)
- A commit with `fix:` → Patch version bump (1.0.0 → 1.0.1)
- A commit with `feat!:` or `BREAKING CHANGE:` → Major version bump (1.0.0 → 2.0.0)

**Version Bumping Mechanics:**

1. **Automatic Version Bumping:**
   The release-drafter determines the version bump based on two factors:
   ```bash
   # 1. PR Labels - Add these when creating the PR
   gh pr create \
     --title "Add new authentication system" \
     --label "feature"    # Triggers minor bump
     --label "breaking"   # Triggers major bump
     --label "fix"        # Triggers patch bump

   # 2. Commit Message Conventions
   # Major bump (2.0.0)
   git commit -m "feat!: completely new auth system"
   # or
   git commit -m "feat: new auth system
   
   BREAKING CHANGE: This replaces the old auth system"

   # Minor bump (1.1.0)
   git commit -m "feat: add new login method"

   # Patch bump (1.0.1)
   git commit -m "fix: correct login validation"
   ```

2. **Manual Version Control:**
   You can manually control version bumping by:
   ```bash
   # Create a PR with specific version intent
   gh pr create \
     --title "feat: add new feature" \
     --label "minor" \
     --label "feature" \
     --body "This PR implements feature X
     
     Version bump: minor"

   # Force a specific version through release UI
   gh release create v1.2.0 \
     --title "v1.2.0" \
     --notes "Release notes..." \
     --target main
   ```

3. **Version Bump Hierarchy:**
   When multiple changes are present, the highest-impact change determines the version:
   ```bash
   # These changes in one PR:
   git commit -m "fix: update error handling"
   git commit -m "feat: add new endpoint"
   git commit -m "docs: update README"
   # Results in minor bump (1.1.0) because feat > fix > docs
   
   # If any breaking change exists, it takes precedence:
   git commit -m "fix: update error handling"
   git commit -m "feat!: breaking API change"
   # Results in major bump (2.0.0)
   ```

4. **Release Workflow:**
   ```bash
   # 1. Create feature branch
   git checkout -b feature/new-auth

   # 2. Make changes and commit with semantic messages
   git commit -m "feat(auth): add OAuth support"

   # 3. Create PR with appropriate labels
   gh pr create \
     --title "feat(auth): add OAuth support" \
     --label "feature" \
     --body "Adds OAuth authentication support"

   # 4. After PR is merged, release-drafter will:
   # - Update draft release
   # - Determine version bump
   # - Generate changelog
   
   # 5. Publish release (manual or automated)
   gh release create v1.1.0 \
     --draft=false \
     --title "v1.1.0" \
     --notes-file CHANGELOG.md
   ```

**Best Practices for Version Management:**
1. Always use semantic commit messages
2. Label PRs consistently with version intent
3. Include breaking change notices in commit messages when applicable
4. Review draft releases before publishing
5. Keep one significant change per PR for clear version bumping
6. Document version bumps in PR descriptions

### GitHub CLI Commit and PR Examples

Use GitHub CLI to streamline commits and PR creation with semantic commit messages and labeling, integrating with the semantic versioning action:

**Commit and Push Changes:**
```bash
git checkout -b feature/123-improve-ui
git add .
git commit -m "feat: add responsive navbar component"
git push origin feature/123-improve-ui
```

**Create a PR with labels using GitHub CLI:**
```bash
gh pr create --title "feat: improve UI responsiveness (#123)" --body "Implements responsive layout improvements \n\nCloses #123" --label minor,feature
```

To ensure semantic tags trigger version increments properly, PR labels should align clearly:
- Use `major` for breaking changes (`BREAKING CHANGE` or `feat!`)
- Use `minor` for new features (`feat`)
- Use `patch` for fixes, chores, docs, and refactors

### Workflow 3: Publish to Artifactory

Trigger: Release published

Tasks:
- **Mandatory**: Package and publish artifacts to Artifactory, making them available for deployment via ArgoCD.
- **Optional**: Notify stakeholders or trigger subsequent deployment workflows.

Example:
```yaml
# File: .github/workflows/publish-to-artifactory.yaml
name: Publish to Artifactory

on:
  release:
    types: [published]

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup JFrog CLI
        uses: jfrog/setup-jfrog-cli@v4
        env:
          JF_URL: ${{ secrets.JF_URL }}
          JF_USER: ${{ secrets.JF_USER }}
          JF_PASSWORD: ${{ secrets.JF_PASSWORD }}
      - name: Build and Publish Artifacts
        run: |
          jf rt ping
          jfrog rt build-docker-create my-app:${{ github.event.release.tag_name }} --build-name=my-app
          jf rt docker-push my-app:${{ github.event.release.tag_name }} docker-local
          jf rt build-publish
```

### Integration with Continuous Delivery (CD)

These CI workflows integrate directly into the Continuous Delivery process using ArgoCD and GitOps principles. After artifacts are published to Artifactory, ArgoCD automatically monitors repository changes defined in your GitOps repository structure, triggering deployments to Kubernetes-based environments:

- **Kustomize and Helm** are utilized to customize deployments for development and QA environments.
- **Azure Blob Storage** handles direct deployments for UX zip artifacts using ArgoCD Workflow Templates.
- Separate ApplicationSets ensure independent and manageable deployments for API and UX components.

### Best Practices for CI/CD Integration

- Maintain modular workflows to isolate tasks.
- Clearly document and comment workflows for ease of maintenance and onboarding.
- Utilize marketplace actions for rapid implementation and reliability.

Following this strategic integration of GitHub Actions with ArgoCD, GitOps, Artifactory, and Azure ensures a robust, scalable, and efficient CI/CD pipeline.

