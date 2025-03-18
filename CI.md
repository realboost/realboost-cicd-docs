## Strategic Approach for Continuous Integration Using GitHub Actions

### Overview of the Recommended CI Process

The following outlines a structured yet flexible approach to organizing and managing changes and releases in a GitHub repository using GitHub Actions. This strategy ensures clean merges, reliable builds, automated versioning, and streamlined deployments, aligning seamlessly with Continuous Delivery (CD) processes managed by ArgoCD, GitOps, Artifactory, and Azure Storage.

### Branch and PR Management

- **Branch Protection**: Enable branch protection rules on the `main` branch requiring pull requests (PRs) to merge. This prevents direct pushes to `main`.

### Branch Naming and PR Traceability

- Clearly name branches by incorporating relevant information such as issue numbers (e.g., `feature/123-improve-ui`).

### Automated Workflows

#### Workflow 1: Validate PR

Trigger: Pull requests created against `main`

Tasks:
- **Mandatory**: Validate packaging logic (build artifacts, container images).
- **Optional**: Run tests, static analysis, security checks.

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

Use the following Semantic Version action from GitHub 

`https://github.com/marketplace/actions/git-semantic-version`

Example:
```yaml
# File: .github/workflows/create-release.yaml
name: Semantic Release

on:
  push:
    branches:
      - main

jobs:
  semantic-release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Semantic Versioning
        uses: PaulHatch/semantic-version@v5.4.0
        with:
          tag_prefix: ""
          major_pattern: "(BREAKING CHANGE|feat!)"
          minor_pattern: "^feat"
          patch_pattern: "fix|chore|docs|refactor"
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Commit Message Guidelines

Use semantic commit messages to clearly communicate the nature of changes:

- `feat`: Introduces a new feature or functionality.
- `fix`: Corrects a bug or issue.
- `docs`: Updates or adds documentation.
- `chore`: General maintenance or dependency updates.
- `refactor`: Improves existing code without altering functionality.
- `perf`: Improves performance without changing functionality.
- `style`: Changes related to code formatting or style, without affecting logic.

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

