---
name: execute
description: Ingests and executes a technical plan markdown file step-by-step with testing barriers. Use when implementing a previously planned feature, refactor, or architectural change from a plan file.
---

# Execute Technical Plan

## Critical Directive
You are tasked with executing a pre-written technical plan markdown file (located in the `plan/` directory or provided as an argument). Your goal is to implement the plan precisely, step-by-step, adhering strictly to the defined logical chunks and test barriers. 

Even if you have lower context or knowledge than an expert architect, you can successfully implement this plan by following every instruction methodically in exact order. Do not skip steps, do not guess beyond the plan's instructions, and do not proceed past a test barrier until all tests pass.

## Use This Skill When
- A plan file (`*-PLAN.md`) has been created (e.g. via the `plan` skill) and is ready for implementation.
- You need to execute complex changes in a structured, verifiable, chunk-by-chunk manner.

## Execution Process

### Step 1: Plan Discovery & Ingestion
1. Locate and read the target plan file (e.g., inside `plan/` directory or specified via `/skill:execute path/to/plan.md`). If multiple plan files exist, list them and ask the user which one to execute, or pick the most recent one if unambiguous.
2. Read the entire plan document thoroughly to build mental context of:
   - Intent & Scope (In Scope / Out of Scope)
   - The ordered list of Logical Chunks and Test Barriers
   - Detailed step-by-step file modifications
   - Test suites, test cases, and acceptance criteria
3. Review Section 4 (Review / Risks) for architectural warnings, package naming conventions, or configuration constraints.

### Step 2: Sequential Execution Protocol
Execute the plan strictly in the order defined in **Section 2 & 3** of the plan file. For each item in the execution sequence:

#### If the item is a Logical Chunk:
1. **Understand Context:** Read the brief context and planned modifications for this logical chunk.
2. **Ensure Directory Structure:** 
   - Before writing or modifying any file, ensure its parent directories exist (e.g. using `mkdir -p` or creating directories via tool calls).
3. **Implement Step-by-Step:**
   - For each file specified in the chunk, locate or create the file and apply the exact steps described.
   - Use precise edits (`edit` tool) or complete file creation (`write` tool for new files).
   - Ensure syntax correctness, type safety, package/module import consistency, and alignment with surrounding code. This may involve running linters or building code.
   - Ensure code is properly documented (code comments or readme.md files if code comments are not applicable)
   - Prefer maintainable code over overly-optimized code (someone completely new should be able to understand the code. no sphaghetti code.)
4. **Self-Check:** Review your changes against the step-by-step instructions before moving on.

#### If the item is a Test Barrier:
1. **Review Test Overview & Acceptance Criteria:** Understand what scenarios and assertions must pass.
2. **Execute Testing Plan:**
   - Set up or implement the test cases, test suites, or verification scripts outlined.
   - Run the relevant tests using available test execution tools (e.g., `bash` tool with `mvn test`, `npm test`, `pytest`, etc.).
3. **Verify Assertions:**
   - Ensure all assertions and acceptance criteria pass successfully.
   - **CRITICAL:** If any test fails or assertion does not pass, STOP. Diagnose the root cause, fix the implementation or test, and re-run until 100% of test barrier criteria pass.
   - Do NOT proceed to the next logical chunk until the current test barrier is fully cleared.
   - If the test barrier cannot be overcome provide a detailed error to the user and the context of the component being tested along with the testing environment with the goal that the user can adjust the execution plan or test case for you to overcome the barrier. 

### Step 3: Final Verification & Completion
1. Run the full test suite or all test barriers to ensure no regressions.
2. Provide a concise summary of implemented changes, files modified, and test results to the user. This can go into an output "{plan_name}-CHANGES.md"
3. Provide README's for guidance on using the generated output
   - READMEs should include:
      - any dependencies needed
      - commands to run for setup and usage of the system
      - behavior of the system
4. Ensure a minimum (80%) level of code coverage of the entire coverable project if applicable
   - code coverage should only consider code files (no configuration files, deployment scripts, etc.)
   - If we are under this threshold, determine where there are gaps to reach 80% but do not think hard about how to rectify them
      - Output all the files where we are lacking coverage and the current coverage for those files into a file named "{plan_name}-TESTING-GAPS.md"
        
