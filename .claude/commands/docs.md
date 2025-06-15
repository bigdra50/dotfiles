Generate documentation for code files and projects.

Workflow:
1. Analyze project structure and identify main entry points
2. Read and understand code files, focusing on:
   - Public APIs and exported functions
   - Class definitions and methods
   - Configuration options
   - Usage patterns
3. Generate appropriate documentation based on file types:
   - README.md for project overview
   - API documentation for libraries
   - Code comments for complex functions
   - Practical usage examples
4. Follow existing documentation style in the project
5. Write clear, concise explanations without excessive technical jargon
6. Include relevant practical examples
7. Create or update documentation files as needed

Documentation types:
- Project README with setup and usage instructions
- Function and class documentation with parameters and return values
- Configuration file explanations
- API endpoint documentation
- Code comments for complex algorithms

Guidelines:
- Use simple, clear language
- Avoid excessive formatting
- Focus on practical usage
- Include concrete examples
- Explain the "why" not just the "what"
- Keep documentation up to date with code changes

Usage: claude /docs [file-path-or-directory]
If $ARGUMENTS is provided, focus documentation on specified files or directories.
If no $ARGUMENTS, analyze entire project for documentation needs.