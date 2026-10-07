---
name: testing-gaps
description: Ingests a markdown file listing current gaps in code coverage of the project. Used when not all code was covered during implementation of a feature.
---

# Execute Technical Plan

## Critical Directive
You are tasked with figuring out how to obtain additional coverage of the code in this project. We require at least 80% code coverage of our project. 
You are given:
- a markdown file with the name {problem}-TESTING-GAPS.md : pieces of code which are lacking in coverage
- a markdown file with the name {problem}-PLAN.md : the initial plan that gives context on the execution
- a markdown file with the name {problem}-CHANGES.md: the specific changes which were done to execute on the *-PLAN.md.

## Use This Skill When
- A plan file (`*-PLAN.md`) has been created (e.g. via the `plan` skill).
- A changes file (`*-CHANGES.md`) has been created (i.e via the `execute` skill).
- A testing gap file (`*-TESTING-GAPS.md`) has been created (i.e via the `execute` skill)
- and the project-level code coverage is below 80% as a whole and we need to reach 80% coverage.

## Execution Process

### Step 1: Review Test Cases From Plan
1. Review the PLAN.md file for the context on the implementation.
2. Based on the PLAN.md context think about test case scenarios that would cover the PLAN.md file acceptance criteria for completion of the plan without referencing the CHANGES.md file

### Step 2: Cross Referencing Thoughts with the Actual Execution
1. Cross reference your test case scenarios against the actual scenarios made in CHANGES.md and see if any scenarios are missing
2. If any scenarios are missing, it is paramount to inform the user and ask them to implement the scenario with rationale on why the scenario is required before implementation

### Step 3: Final Gaps
1. Compute the project-level code coverage again only if you had to add extra scenarios and we can jump to the next step (step 4) if the project-level code coverage is 80% or higher
2. Inspect the *-TESTING-GAPS.md file and determine which lines code lines in the files mentioned are not covered
3. Implement test cases to cover the code lines which are not covered.
   - It is not too important to try and cover every little thing
   - It is advised to focus on the easier, discrete things that are not covered first instead of trying to cover individual lines
      - i.e if a method is not covered, a getter/setter is not covered, or a logical branch (if statement clause) is not covered, write tests for those to get easy coverage first
   - **CRITICAL** Code changes to the source file that is being tested at this point are extremely discouraged to get increased code coverage. If they are absolutely necessary, prompt the user first and inform them why changes to the source might be needed
   - **IMPORTANT** new test cases added should have documentation (i.e code comments of the scenario that is being tested)
4. Test periodically as you make more test cases and get project-level code coverage. If at any point we reach 80% or more coverage, we can jump to the next step (step 4)
5. If you think it is impossible to try and get 80% code coverage for the project, review the PLAN.md and CHANGES.md file one more time before making that final decision to stop. Inform the user with context as to why this is impossible and move onto the next step.

### Step 4: Final Output
1. Provide a short summary on what was changed
2. Provide the before and after project-level coverage
3. If there were any shortcomings during the execution of this skill, document that to the user
4. Output the final report to a {problem}-TESTING-GAP-EXECUTION.md

        
