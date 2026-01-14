# OE Platform Modules

Vetted OpenTofu/Terraform modules for [OE Platform](https://github.com/ordinaryexperts/platform) clients.

## Usage

Reference modules from client config repositories:

```hcl
module "bucket" {
  source = "github.com/ordinaryexperts/platform-modules//modules/s3-bucket?ref=s3-bucket/v1.0.0"

  bucket_name = "my-app-data"
  # ...
}
```

## Available Modules

See the [modules/](./modules) directory for all available modules.

Each module includes:
- `README.md` - Usage documentation and examples
- `variables.tf` - Input variables with descriptions
- `outputs.tf` - Output values
- `main.tf` - Resource definitions
- `versions.tf` - Provider version constraints

## Versioning

Modules are versioned independently using **path-based git tags** following [Semantic Versioning](https://semver.org/):

```
<module-name>/v<major>.<minor>.<patch>
```

Examples:
- `s3-bucket/v1.0.0`
- `vpc/v2.1.0`
- `rds-postgres/v1.0.3`

### Version Guidelines

- **Major (v2.0.0)**: Breaking changes - removed variables, renamed outputs, changed behavior
- **Minor (v1.1.0)**: New features - added variables, new resources, backwards compatible
- **Patch (v1.0.1)**: Bug fixes - no interface changes

## Development

This repository uses [Git Flow](https://nvie.com/posts/a-successful-git-branching-model/) branching:

- `main` - Production-ready releases only
- `develop` - Integration branch for features
- `feature/*` - New modules or enhancements
- `release/*` - Release preparation
- `hotfix/*` - Urgent fixes to production

### Workflow

1. **New module or feature:**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/new-module-name
   # ... make changes ...
   git push -u origin feature/new-module-name
   # Create PR to develop
   ```

2. **Release a module:**
   ```bash
   git checkout main
   git pull origin main
   # Tag the specific module with its version
   git tag -a "s3-bucket/v1.0.0" -m "s3-bucket v1.0.0: Initial release"
   git push origin "s3-bucket/v1.0.0"
   ```

3. **Hotfix:**
   ```bash
   git checkout -b hotfix/s3-bucket-fix main
   # ... fix the issue ...
   # Merge to both main and develop
   ```

### Module Standards

All modules must include:

- [ ] `README.md` with usage example
- [ ] All variables have `description` and `type`
- [ ] All outputs have `description`
- [ ] `versions.tf` with provider constraints
- [ ] Pass `tofu fmt` and `tofu validate`

## License

Apache License 2.0 - See [LICENSE](./LICENSE)
