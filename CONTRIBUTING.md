# Contributing to Salesforce Portfolio

Thank you for your interest in this portfolio project! While this is primarily a portfolio repository showcasing professional Salesforce development skills, feedback and suggestions are welcome.

## 🎯 Purpose

This repository serves as a demonstration of:

- Enterprise Salesforce development patterns
- Testing strategies and best practices
- CI/CD implementation with GitHub Actions
- Code quality and documentation standards

## 💡 How to Contribute

### Reporting Issues

If you find bugs or have suggestions for improvements:

1. **Check existing issues** - Search the issue tracker to avoid duplicates
2. **Create a detailed issue** - Include:
   - Clear description of the issue/suggestion
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - Screenshots (if applicable)
   - Salesforce org type and API version

### Suggesting Enhancements

For feature suggestions:

1. Describe the enhancement clearly
2. Explain the use case and benefits
3. Consider providing implementation ideas
4. Note any potential breaking changes

## 🔧 Development Setup

If you want to explore or test the code locally:

### Prerequisites

- Salesforce CLI (sf or sfdx)
- Node.js v18+ and npm
- Git
- VS Code with Salesforce Extensions (recommended)

### Setup Steps

1. **Fork and clone**

   ```bash
   git clone https://github.com/YOUR-USERNAME/SalesforcePortfolio.git
   cd SalesforcePortfolio
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Create a scratch org**

   ```bash
   sf org create scratch -f config/project-scratch-def.json -a portfolio-dev
   ```

4. **Deploy metadata**

   ```bash
   sf project deploy start
   ```

5. **Run tests**
   ```bash
   sf apex run test --test-level RunLocalTests --result-format human
   ```

## 📝 Code Quality Standards

This project maintains high code quality standards:

### Formatting

- **Prettier** for consistent code formatting
- Automatic formatting on commit via Husky
- Run manually: `npm run prettier`

### Linting

- **ESLint** for JavaScript/LWC code
- Configuration in `eslint.config.js`
- Run: `npm run lint`

### Testing

- **Apex Tests**: Minimum 75% coverage required (current: 71%, target: 90%+)
- **LWC Tests**: Jest for component testing
- **Test Factories**: Use `TestDataFactory` and `TestScenarioFactory`
- Run: `npm run test:unit`

### Commit Messages

Follow conventional commit format:

```
type(scope): subject

body (optional)

footer (optional)
```

**Types:**

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `refactor`: Code refactoring
- `test`: Test additions/modifications
- `chore`: Build process or auxiliary tool changes
- `style`: Code style changes (formatting, etc.)

**Examples:**

```
feat(subscription): add trial period expiration handling
fix(invoice): correct total calculation for multi-currency
docs(readme): update setup instructions
refactor(trigger): extract duplicate code to utility method
```

## 🏗️ Architecture Guidelines

When suggesting code changes, consider:

### Trigger Pattern

- All business logic in handler classes
- Handlers implement `IHandler` interface
- Use `TriggerFramework` base class
- One trigger per object

### Service Layer

- Business logic in service classes
- Bulkified operations
- Reusable methods
- Clear separation of concerns

### Validation

- Dedicated validator classes
- Centralized validation logic
- Consistent error messages
- Use Custom Labels for user-facing text

### Testing

- Test all scenarios (positive, negative, bulk)
- Use test factories for data creation
- Mock external callouts
- Verify governor limit handling

## 🔒 Security Considerations

- Always check FLS and CRUD permissions
- Use `WITH SECURITY_ENFORCED` in SOQL
- Sanitize user inputs
- Follow principle of least privilege
- Never commit credentials or sensitive data

## 📋 Pull Request Process

1. **Create a feature branch**

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow coding standards
   - Add/update tests
   - Update documentation

3. **Test thoroughly**

   ```bash
   npm run lint
   npm run prettier:verify
   npm run test:unit
   sf apex run test --test-level RunLocalTests
   ```

4. **Commit your changes**

   ```bash
   git commit -m "feat: add your feature"
   ```

5. **Push to your fork**

   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create Pull Request**
   - Provide clear description
   - Reference any related issues
   - Include test results
   - Add screenshots for UI changes

## ❓ Questions?

For questions about the code or architecture:

- Open an issue for discussion
- Email: antoniofranco.99@outlook.com
- Check existing documentation in `/docs`

## 📄 License

This project is for portfolio and educational purposes. Please respect the intellectual property and give appropriate credit if using any patterns or code.

## 🙏 Acknowledgments

Thank you for taking the time to contribute or provide feedback!

---

**Note**: This is primarily a portfolio project. Contributions are welcome but the project direction and final decisions rest with the repository owner.
