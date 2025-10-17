---
allowed-tools: [Read, Write, Bash, TodoWrite, Task]
argument-hint: <file> [--type graph|form|tree|table] [--port 3000] [--output dir]
description: Generate an interactive web-based visual editor for any data structure (JSON, YAML, Unity assets, etc.)
---

# Create Visual Editor for Data Structures

Automatically generates a web-based visual editor for any data structure format (JSON, YAML, Unity ScriptableObject, etc.) with live editing and save capabilities.

## Overview

This command creates a complete React-based visual editor that can:
- Parse and visualize data structures
- Provide interactive editing (add/edit/delete)
- Save changes back to original format
- Support various data formats (JSON, YAML, Unity assets)

## Workflow

### 1. Data Analysis
- Analyze the target data file structure
- Identify data types and relationships
- Extract schema/type information

### 2. Project Setup
- Create a new web tool directory
- Set up React + TypeScript project
- Install required dependencies (React Flow for graphs, js-yaml for YAML, etc.)

### 3. Type Generation
- Generate TypeScript interfaces from data structure
- Create utility functions for parsing/serialization

### 4. UI Implementation
- Choose appropriate visualization (graph for node-based, form for structured data)
- Implement CRUD operations
- Add file load/save functionality

### 5. Development Server
- Start local development server
- Provide access URL (localhost:3000)

## Usage Examples

### For Unity ScriptableObject:
```
/visual-editor @path/to/asset.asset
```

### For JSON configuration:
```
/visual-editor @config.json --type form
```

### For YAML with graph structure:
```
/visual-editor @workflow.yaml --type graph
```

## Options

- `--type`: Visualization type (graph|form|tree|table)
- `--port`: Development server port (default: 3000)
- `--output`: Output directory (default: tools/[name]-editor)

## Supported Formats

- **JSON**: Automatic schema detection
- **YAML**: Full YAML 1.1 support
- **Unity Assets**: ScriptableObject YAML format
- **XML**: Structured data visualization
- **Custom**: Define your own parser

## Generated Project Structure

```
tools/[data-name]-editor/
├── src/
│   ├── types/          # Auto-generated TypeScript types
│   ├── utils/          # Parser and converter utilities
│   ├── components/     # React components
│   └── App.tsx         # Main application
├── public/             # Sample data files
├── package.json        # Dependencies
└── README.md          # Usage documentation
```

## Key Features

- **Auto Type Detection**: Analyzes data and generates appropriate TypeScript types
- **Interactive Editing**: Add, modify, delete data elements
- **Format Preservation**: Maintains original file format when saving
- **Hot Reload**: Live updates during development
- **Export/Import**: Load and save files directly from browser

## Error Handling

- Validates data structure before processing
- Provides clear error messages for unsupported formats
- Gracefully handles parsing errors
- Maintains data integrity during save operations