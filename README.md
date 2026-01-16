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

This repository uses **trunk-based development**:

```
main           <-- trunk (always deployable)
  ^
feature/*      <-- short-lived feature branches
  |
  +-- tags     <-- module-name/v1.0.0 (release points)
```

### Workflow

1. **Create a feature branch from main:**
   ```bash
   git checkout main
   git pull origin main
   git checkout -b feature/my-change
   ```

2. **Make your changes and push:**
   ```bash
   # ... make changes ...
   git add .
   git commit -m "feat: add new capability"
   git push -u origin feature/my-change
   ```

3. **Open PR to main and merge after review**

4. **Tag a release when ready:**
   ```bash
   git checkout main
   git pull origin main
   git tag -a "s3-bucket/v1.0.0" -m "s3-bucket v1.0.0: Initial release"
   git push origin "s3-bucket/v1.0.0"
   ```

**Key principles:**
- Keep feature branches short-lived (hours to days, not weeks)
- Merge to main frequently
- Main should always be deployable
- Dev environments track main directly
- Staging/prod environments use versioned tags

### Module Standards

All modules must include:

- [ ] `README.md` with usage example
- [ ] All variables have `description` and `type`
- [ ] All outputs have `description`
- [ ] `versions.tf` with provider constraints
- [ ] Pass `tofu fmt` and `tofu validate`

## License

Apache License 2.0 - See [LICENSE](./LICENSE)
