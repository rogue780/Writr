# Contributing to Writr

Thank you for your interest in contributing to Writr! This document provides guidelines and information for contributors.

## Development Setup

### Prerequisites
- Flutter SDK 3.0.0 or higher
- Android SDK (API level 21+)
- Git
- A code editor (VS Code, Android Studio, or IntelliJ IDEA recommended)

### Getting Started
1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/Writr.git
   cd Writr
   ```
3. Add the upstream remote:
   ```bash
   git remote add upstream https://github.com/rogue780/Writr.git
   ```
4. Install dependencies:
   ```bash
   flutter pub get
   ```
5. Run the app:
   ```bash
   flutter run
   ```

## Development Workflow

### Creating a Feature Branch
```bash
git checkout -b feature/your-feature-name
```

### Making Changes
1. Write clean, documented code
2. Follow the existing code style
3. Add tests for new functionality
4. Update documentation as needed

### Code Style
- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format .` before committing
- Run `flutter analyze` to check for issues
- Ensure all tests pass with `flutter test`

### Commit Messages
Use clear, descriptive commit messages:
```
feat: Add dark mode support
fix: Resolve cloud sync issue
docs: Update installation instructions
test: Add tests for Scrivener parser
```

### Running Tests
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```

### Building APKs Locally
```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release
```

## Pull Request Process

### Before Submitting
- [ ] Code follows the project style
- [ ] All tests pass locally
- [ ] New tests added for new features
- [ ] Documentation updated
- [ ] Commit messages are clear

### Submitting a PR
1. Push your branch to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```
2. Open a Pull Request on GitHub
3. Fill out the PR template with:
   - Description of changes
   - Related issue numbers
   - Testing performed
   - Screenshots (if UI changes)

### CI/CD Checks
When you submit a PR, GitHub Actions will automatically:
1. Verify code formatting
2. Run static analysis
3. Execute test suite
4. Build debug and release APKs

All checks must pass before the PR can be merged.

### Review Process
- Maintainers will review your PR
- Address any feedback or requested changes
- Once approved, a maintainer will merge your PR

## Areas for Contribution

### High Priority
- RTF formatting support
- Improved cloud storage authentication
- Sync conflict resolution
- Dark mode theme
- Search functionality

### Documentation
- API documentation
- User guides
- Code examples
- Tutorial videos

### Testing
- Unit tests
- Widget tests
- Integration tests
- Manual testing on various devices

### UI/UX
- Design improvements
- Accessibility features
- Localization/translations
- Responsive layouts

## Reporting Issues

### Bug Reports
When reporting bugs, please include:
- Device and Android version
- App version
- Steps to reproduce
- Expected vs actual behavior
- Screenshots/logs if applicable

### Feature Requests
For feature requests, describe:
- The problem you're trying to solve
- Proposed solution
- Alternative solutions considered
- Why this would benefit users

## Code Review Guidelines

### For Reviewers
- Be respectful and constructive
- Focus on code quality and maintainability
- Suggest improvements, don't just criticize
- Approve PRs that improve the codebase

### For Authors
- Be open to feedback
- Explain your reasoning
- Make requested changes promptly
- Ask questions if unclear

## Community Guidelines

### Be Respectful
- Treat everyone with respect
- Welcome newcomers
- Be patient with questions
- Give credit where due

### Be Collaborative
- Share knowledge
- Help others learn
- Work together on solutions
- Celebrate successes

### Be Professional
- Keep discussions on topic
- Avoid inflammatory language
- Focus on the code, not the person
- Maintain a positive environment

## Getting Help

- **Questions**: Open a GitHub Discussion
- **Bugs**: Create an issue with bug report template
- **Chat**: Join our community (link TBD)
- **Docs**: Check the README and wiki

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Writr! Your efforts help make this a better tool for writers everywhere.
