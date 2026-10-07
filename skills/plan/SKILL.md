---
name: plan
description: Forces the agent to understand the problem, ask clarifying questions, and output a strict, atomic technical plan with testing barriers before any implementation begins.
---

# Create Implementation Plan

## Critical Directive
DO NOT write, modify, or update any functional application source files while using this skill. Your sole purpose is to analyze the request and generate an execution plan. 
DO NOT make any assumptions. For any unknowns, list possible assumptions to make, and then prompt the user to proceed with an assumption or provide one. 

## Use This Skill When
- The user requests a new feature, a code refactor, or an architectural change.
- A task is too complex for immediate execution and requires a phased roadmap.
- You need to establish concrete file scopes and boundaries before writing code.
- A plan needs to be generated that can be executed by others without needing additional context

## When NOT to Use
- The user explicitly bypasses planning (e.g., "just fix this typo immediately").
- Standard debugging or exploratory research is requested without execution goals.

## Execution Process

### Step 1: Context Gathering & Analysis
1. Inspect the local codebase, repository structures, and relevant files to understand the impact of the request, while prompting the user for additional context as needed.
2. Partition the implementation of solving the task into logically separate chunks. Ideally, each chunk is separate and can be implemented and tested independently of others, but this is not always the case. The simplest execution plan in terms of Software Lines of Code or maintainability should be preferred. If there are multiple valid plans, propose them to the user to pick one.  
3. Define the test barriers for the plan. Test barriers are tests performed to ensure that each logically separate chunk or groups of them are performing as expected. For testing individual logical chunks, we should prefer fast unit tests over longer integration tests. Prompt the user for acceptable testing criteria/acceptance criteria as needed. 
4. After creating each logical chunk and test barrier, review the plan so far and ensure that the implementation of the logical chunks and test barriers will solve the overarching problem. Reach out to the user for context and adjust the plan as necessary to add/remove logical chunks and test barriers if we are duplicating work or if we do not have enough work to solve the problem. 
5. After review of the plan, if the plan is very large in scope and can be split up into groups of discrete logical chunks and test barriers that are absolutely independent, suggest to the user to put these groups into their own plan files. These absolutely independent groups of logical chunks and test barriers can go into their own plan files in the format defined in the #plan section and must each solve a unique problem that contributes to the overall problem/feature at large. 
6. Keep a general note on what dependencies (environment/package/etc.) may be required to execute the plan. If programming languages or technologies are specified, these would include build tools or linters. 

### Step 2: Output the Plan File
Create and save a markdown plan file inside the `/plan/` directory following the naming convention: `[problem]-PLAN.md` (e.g., `implementing-auth-PLAN.md`). 

The document must strictly adhere to the following Markdown template without any conversational meta-introductions:

"""
# Plan: [Brief Title]

## 1. Intent & Scope
[Write one concise paragraph explaining the core approach and architectural intent.]
- **In Scope:** [Bullet items]
- **Out of Scope:** [Bullet items]
- **Dependencies:** [Bullet items] This is a list of dependencies that may be needed to execute the plan.

## 2. List of logical chunks and test barriers
Define the list explicit logical chunks for this task that make up the solution for the problem at large. In addition, list the test barriers for the plan. This list should follow implementation order. Logical chunks should be prefixed with "Logical:" and test barriers should be prefixed with "Test:". There should be no descriptions here, just names to identify the logical chunks and test barriers.  
- **Logical Chunks:** (implementation of a discrete component to help solve the problem)
- **Test Barriers:** (testing plans to ensure that each logical chunk or groups of them are working as expected)
## 3. Execution Plan
For each item in the list of chunks of execution (item 2.) we provide an execution plan subsection. This subsection provides the context and steps to execute the plan so that anyone can execute it.
If the item is a logical chunk the execution plan is formatted as follows:
- Header: Name of the logical chunk as a markdown header
- Brief Context: Small 3-5 sentence context on what this logical chunk does and how we plan to modify it.
- Step by Step Plan:
  - File: this is the file to modify or add
    - Step: Each file has steps of what to modify in the file to complete the logical chunk 
If the item is a test barrier the execution plan is formatted as follows:
- Header: Name of the test barrier as a markdown header
- Test Overview: Small 3-5 sentence context on the test and what it accomplishes
- Acceptance Criteria: Bulleted list of what scenarios need to pass for the logical chunk(s)
- Testing Plan:
  - Test Suite: A test suite is a list of test cases
    - Test Case: An independent test scenario that is a list of assertions
      - Assertions: An assertion is a rule that must pass for the test case to pass

## 4. Review
- [List max 3 risks or remaining unknowns, if any]
- [Inspect each step of the execution plan to ensure that even the dumbest agent can implement it given only the plan and no other context.]
"""