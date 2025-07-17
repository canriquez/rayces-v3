# Execute BASE PRP

Execute the requirements of a PRP file.

## PRP File: $ARGUMENTS

## Execution Process

1. **Load PRP**
   - Read the specified PRP file on /PRPs/{{$ARGUMENTS}}.md
   - Understand all context and requirements
   - Follow all instructions in the PRP and extend the research to the internet if needed
   - Ensure you have all needed context to implement the PRP fully
   - Do more web searches and codebase exploration as needed
   - SUPER IMPORTANT. YOU MUST DO THIS: Check for the existance of the file /PRPs/{{$ARGUMENTS}}-execution-log.md. If this file exists it means that this PR is still work in progress. On that case after reading the  file on /PRPs/{{$ARGUMENTS}}.md, make sure you learn about the latest progress for this prp inside /PRPs/{{$ARGUMENTS}}-execution-log and you then continue with the execution.

2. **ULTRATHINK**
   - Think hard before you execute the plan. Create a comprehensive plan addressing all requirements.
   - Break down complex tasks into smaller, manageable steps using your todos tools.
   - Use the TodoWrite tool to create and track your implementation plan.
   - Identify implementation patterns from existing code to follow.

3. **Execute the plan**
   - Execute the PRP
   - Implement all the code
   - If in the middle of the process you auto compact the context, after compactation you must read the current prp file on /PRPs/{{$ARGUMENTS}}.md file refresh again the plan and compare against your current progress.

   **Execute the plan at all costs**
   - Always create comprehensive tests that test for happy path and common edge cases all the new logic and units that you are creating.
   - ALWAYS, ALWAYS make all the tests pass. For this you will need to adjust the logic and adjust the testing infrastructure if needed.
   - When you fix a test or modify an application logoc code, make sure you review the complete file and clean up old comments that after the fix will just create confusion for the developer when reading the fixed code. Make sure you do this sanity check every time.
   - When finding a fix for a problem exaust all current ideas, PLEASe make sure you do a search on the intenet to look for ideas and related examples or solutions. This has proven in the past that provided great sources to solve really complex issues.
   - YOU CANNOT CALL A PRP DONE WITH TESTS FAILING. YOU HAVE TO FIX THEM ALL ALWAYS. THIS IS A MUST HAVE. NO OTHER WAY ALLOWED.
   - If in the middle of the process you auto compact the context, after compactation you must read the current prp file on /PRPs/{{$ARGUMENTS}}.md file refresh again the plan and compare against your current progress.

   **Keep a Log of every step of the plan executed***
   You will maintain a real-time execution log. Follow these directives precisely:

   - Log File: Create and continuously update the log at /PRPs/{{$ARGUMENTS}}-execution-log.md.
   - Template: Strictly follow the template at PRPs/templates/prp-execution-log.md.
   - Content: Your log must include:
      - All working commands and strategies.
      - "Gold Nuggets": Key learnings and best practices for every fix.
      - Evidence: Code snippets, file paths, and URLs to any external sources that helped.
   - Updates: The log is a living document. If a solution changes (e.g., due to a regression), you must go back and update the log entry to reflect the final, working solution.
   - Purpose: Ensure the log is always detailed enough to serve as a perfect checkpoint, allowing work to resume with full context after any interruption.


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