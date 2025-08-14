# Contributing to Phim

First off, thank you for considering contributing to Phim! It's people like you that make Phim such a great tool.

## Code of Conduct

By participating in this project, you are expected to uphold our simple code: be respectful and constructive.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples**
- **Include macOS version and hardware info**
- **Include crash logs if applicable**

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear and descriptive title**
- **Provide a detailed description of the suggested enhancement**
- **Explain why this enhancement would be useful**
- **List some examples of how it would be used**

### Pull Requests

1. Fork the repo and create your branch from `main`
2. Make your changes following the existing code style
3. Test your changes thoroughly
4. Update documentation if needed
5. Create a pull request with a clear description

## Development Setup

```bash
# Clone your fork
git clone https://github.com/your-username/phim.git
cd phim

# Build the app
./build.sh

# Test your changes
./phim https://example.com
```

## Style Guidelines

### Swift Style

- Follow Swift API Design Guidelines
- Use clear, descriptive names
- Keep functions focused and small
- Add comments for complex logic
- Maintain the existing code formatting

### Commit Messages

- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit first line to 72 characters
- Reference issues and pull requests when relevant

Example:
```
Add vibrancy toggle keyboard shortcut

- Implements ⌘⇧V to toggle vibrancy on/off
- Stores preference in UserDefaults
- Updates UI immediately on toggle

Fixes #123
```

## Testing

Before submitting a pull request:

1. Test with various websites (light/dark themes)
2. Test all keyboard shortcuts
3. Test clipboard integration
4. Verify no memory leaks
5. Check console for errors

## Questions?

Feel free to open an issue with the "question" label or reach out via GitHub discussions.

Thank you for contributing! 🎉