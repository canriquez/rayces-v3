# Execute BASE PRP

Execute the requirements of a PRP file.

## PRP File: $ARGUMENTS
3
## Execution Process

1. **Load PRP**
   - Read the specified PRP file on /PRPs/{{$ARGUMENTS}}.md
   - Understand all context and requirements
   - Follow all instructions in the PRP and extend the research if needed
   - Ensure you have all needed context to implement the PRP fully
   - Do more web searches and codebase exploration as needed

2. **ULTRATHINK**
   - Think hard before you execute the plan. Create a comprehensive plan addressing all requirements.
   - Break down complex tasks into smaller, manageable steps using your todos tools.
   - Use the TodoWrite tool to create and track your implementation plan.
   - Identify implementation patterns from existing code to follow.

3. **Execute the plan**
   - Execute the PRP
   - Implement all the code
   - If in the middle of the process you auto compact the context, after compactation you must read the current prp file on /PRPs/{{$ARGUMENTS}}.md file refresh again the plan and compare against your current progress.

   **Keep a Log of every step of the plan executed***
   - While executing the plan, kep a log on a file called  /PRPs/{{$ARGUMENTS}}-execution-log.md
   - Every learning point, or command that you tired and worked, keep it on the execution-log so you can re use this strategy again.
   - Execute every step so after an interruption you can go back to this file /PRPs/{{$ARGUMENTS}}-execution-log.md, and learn where you are against the plan.


4. **Validate**
   - Run each validation command
   - Fix any failures
   - Re-run until all pass

5. **Complete**
   - Ensure all checklist items done
   - Run final validation suite
   - Report completion status
   - Read the PRP again to ensure you have implemented everything
   - Make sure all related tests are passing before call this prp complete. This point is a MUST HAVE on the PRP execution.

6. **Update Final Status**
   - Update final test suite status for PRP that is under work
   - Document completion percentage and status of each major component
   - Identify any remaining issues or blockers

7. **Generate Results Documentation**
   - THIS IS SUPER IMPORTANT. DO NOT FORGET: Generate a final `$ARGUMENTS-results.md` file in the PRPs directory
   - Include all important information for the next PRP execution to review
   - Document completed tasks, pending work, and continuity requirements
   - Ensure nothing is forgotten for future development

8. **Reference the PRP**
   - You can always reference the PRP again if needed

Note: If validation fails, use error patterns in PRP to fix and retry.