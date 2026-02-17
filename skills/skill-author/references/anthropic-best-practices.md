# Skill authoring best practices

> Learn how to write effective Skills that Gemini can discover and use successfully.

Good Skills are concise, well-structured, and tested with real usage. This guide provides practical authoring decisions to help you write Skills that Gemini can discover and use effectively.

## Core principles

### Concise is key

The context window is a public good. Your Skill shares the context window with everything else Gemini needs to know, including:

* The system prompt
* Conversation history
* Other Skills' metadata
* Your actual request

Not every token in your Skill has an immediate cost. At startup, only the metadata (name and description) from all Skills is pre-loaded. Gemini reads SKILL.md only when the Skill becomes relevant, and reads additional files only as needed. However, being concise in SKILL.md still matters: once Gemini loads it, every token competes with conversation history and other context.

**Default assumption**: Gemini is already very smart

Only add context Gemini doesn't already have. Challenge each piece of information:

* "Does Gemini really need this explanation?"
* "Can I assume Gemini knows this?"
* "Does this paragraph justify its token cost?"

**Good example: Concise** (approximately 50 tokens):

````markdown
## Extract PDF text

Use pdfplumber for text extraction:

```python
import pdfplumber

with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```
````

**Bad example: Too verbose** (approximately 150 tokens):

```markdown
## Extract PDF text

PDF (Portable Document Format) files are a common file format that contains
text, images, and other content. To extract text from a PDF, you'll need to
use a library. There are many libraries available for PDF processing, but we
recommend pdfplumber because it's easy to use and handles most cases well.
First, you'll need to install it using pip. Then you can use the code below...
```

The concise version assumes Gemini knows what PDFs are and how libraries work.

### Set appropriate degrees of freedom

Match the level of specificity to the task's fragility and variability.

**High freedom** (text-based instructions):

Use when:

* Multiple approaches are valid
* Decisions depend on context
* Heuristics guide the approach

Example:

```markdown
## Code review process

1. Analyze the code structure and organization
2. Check for potential bugs or edge cases
3. Suggest improvements for readability and maintainability
4. Verify adherence to project conventions
```

**Medium freedom** (pseudocode or scripts with parameters):

Use when:

* A preferred pattern exists
* Some variation is acceptable
* Configuration affects behavior

Example:

````markdown
## Generate report

Use this template and customize as needed:

```python
def generate_report(data, format="markdown", include_charts=True):
    # Process data
    # Generate output in specified format
    # Optionally include visualizations
```
````

**Low freedom** (specific scripts, few or no parameters):

Use when:

* Operations are fragile and error-prone
* Consistency is critical
* A specific sequence must be followed

Example:

````markdown
## Database migration

Run exactly this script:

```bash
python scripts/migrate.py --verify --backup
```

Do not modify the command or add additional flags.
````

**Analogy**: Think of Gemini as a robot exploring a path:

* **Narrow bridge with cliffs on both sides**: There's only one safe way forward. Provide specific guardrails and exact instructions (low freedom). Example: database migrations that must run in exact sequence.
* **Open field with no hazards**: Many paths lead to success. Give general direction and trust Gemini to find the best route (high freedom). Example: code reviews where context determines the best approach.

### Test with all models you plan to use

Skills act as additions to models, so effectiveness depends on the underlying model. Test your Skill with all the models you plan to use it with.

## Skill structure

**YAML Frontmatter**: The SKILL.md frontmatter supports two fields:

* `name` - Human-readable name of the Skill (64 characters maximum)
* `description` - One-line description of what the Skill does and when to use it (1024 characters maximum)

### Naming conventions

Use consistent naming patterns to make Skills easier to reference and discuss. We recommend using **gerund form** (verb + -ing) for Skill names, as this clearly describes the activity or capability the Skill provides.

**Good naming examples (gerund form)**:

* "Processing PDFs"
* "Analyzing spreadsheets"
* "Managing databases"
* "Testing code"
* "Writing documentation"

Consistent naming makes it easier to:

* Reference Skills in documentation and conversations
* Understand what a Skill does at a glance
* Organize and search through multiple Skills
* Maintain a professional, cohesive skill library

### Writing effective descriptions

The `description` field enables Skill discovery and should include both what the Skill does and when to use it.

**Always write in third person**. The description is injected into the system prompt, and inconsistent point-of-view can cause discovery problems.

* **Good:** "Processes Excel files and generates reports"
* **Avoid:** "I can help you process Excel files"
* **Avoid:** "You can use this to process Excel files"

**Be specific and include key terms**. Include both what the Skill does and specific triggers/contexts for when to use it.

### Progressive disclosure patterns

SKILL.md serves as an overview that points Gemini to detailed materials as needed, like a table of contents in an onboarding guide.

**Practical guidance:**

* Keep SKILL.md body under 500 lines for optimal performance
* Split content into separate files when approaching this limit
* Use patterns to organize instructions, code, and resources effectively

The complete Skill directory structure might look like this:

```
pdf/
├── SKILL.md              # Main instructions (loaded when triggered)
├── FORMS.md              # Form-filling guide (loaded as needed)
├── reference.md          # API reference (loaded as needed)
├── examples.md           # Usage examples (loaded as needed)
└── scripts/
    ├── analyze_form.py   # Utility script (executed, not loaded)
    ├── fill_form.py      # Form filling script
    └── validate.py       # Validation script
```

Gemini loads FORMS.md, REFERENCE.md, or EXAMPLES.md only when needed.

### Avoid deeply nested references

Gemini may partially read files when they're referenced from other referenced files. When encountering nested references, Gemini might use commands like `head -100` to preview content rather than reading entire files, resulting in incomplete information.

**Keep references one level deep from SKILL.md**. All reference files should link directly from SKILL.md to ensure Gemini reads complete files when needed.

### Structure longer reference files with table of contents

For reference files longer than 100 lines, include a table of contents at the top. This ensures Gemini can see the full scope of available information even when previewing with partial reads.

## Workflows and feedback loops

### Use workflows for complex tasks

Break complex operations into clear, sequential steps. For particularly complex workflows, provide a checklist that Gemini can copy into its response and check off as it progresses.

**Example: Research synthesis workflow**:

````markdown
## Research synthesis workflow

Copy this checklist and track your progress:

```
Research Progress:
- [ ] Step 1: Read all source documents
- [ ] Step 2: Identify key themes
- [ ] Step 3: Cross-reference claims
- [ ] Step 4: Create structured summary
- [ ] Step 5: Verify citations
```
````

### Implement feedback loops

**Common pattern**: Run validator → fix errors → repeat

This pattern greatly improves output quality.

## Content guidelines

### Avoid time-sensitive information

Don't include information that will become outdated.

### Use consistent terminology

Choose one term and use it throughout the Skill. Consistency helps Gemini understand and follow instructions.

## Common patterns

### Template pattern

Provide templates for output format. Match the level of strictness to your needs.

### Examples pattern

For Skills where output quality depends on seeing examples, provide input/output pairs just like in regular prompting.

## Evaluation and iteration

### Build evaluations first

**Create evaluations BEFORE writing extensive documentation.** This ensures your Skill solves real problems rather than documenting imagined ones.

### Develop Skills iteratively with Gemini

The most effective Skill development process involves Gemini itself. Work with one instance of Gemini ("Gemini A") to create a Skill that will be used by other instances ("Gemini B"). Gemini A helps you design and refine instructions, while Gemini B tests them in real tasks.

### Observe how Gemini navigates Skills

As you iterate on Skills, pay attention to how Gemini actually uses them in practice.

## Advanced: Skills with executable code

### Solve, don't punt

When writing scripts for Skills, handle error conditions rather than punting to Gemini.

### Provide utility scripts

Even if Gemini could write a script, pre-made scripts offer advantages:

* More reliable than generated code
* Save tokens
* Save time
* Ensure consistency

### Use visual analysis

When inputs can be rendered as images, have Gemini analyze them using its vision capabilities.

### Create verifiable intermediate outputs

The "plan-validate-execute" pattern catches errors early by having Gemini first create a plan in a structured format, then validate that plan with a script before executing it.

### Runtime environment

Skills run in a code execution environment with filesystem access, bash commands, and code execution capabilities.

### MCP tool references

If your Skill uses MCP (Model Context Protocol) tools, always use fully qualified tool names to avoid "tool not found" errors.

**Format**: `ServerName:tool_name`

### Avoid assuming tools are installed

Don't assume packages are available. Be explicit about dependencies.