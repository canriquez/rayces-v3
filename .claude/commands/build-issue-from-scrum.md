# Build GitHub Issue from SCRUM Ticket

## Command: build-issue-from-scrum {{$ARGUMENTS}}

Create a comprehensive GitHub issue for SCRUM-{{$ARGUMENTS}} by fetching the Jira ticket details and formatting them according to the project's established GitHub issue template.

## Process

1. **Fetch SCRUM Ticket Details**
   - Use `mcp__atlassian__jira_get_issue` to get SCRUM-{{$ARGUMENTS}} details
   - Extract all fields including description, acceptance criteria, dependencies, and labels
   - Note the parent epic and sprint information

2. **Analyze Existing GitHub Issues**
   - Review the format of existing GitHub issues (e.g., issues #10-#15)
   - Identify the standard structure and sections used
   - Note the labeling conventions and assignee patterns

3. **Create GitHub Issue Content**
   
   ### Standard Issue Structure:
   ```markdown
   ## 🎯 Epic: [Epic Name] ([Epic Key])
   **Sprint**: [Sprint Name and Dates]  
   **Story Points**: [Points]  
   **Assignee**: [Assignee Name]  
   **Priority**: [Priority Level]  
   **Status**: [Current Status]  
   **Jira Link**: https://canriquez.atlassian.net/browse/SCRUM-{{$ARGUMENTS}}

   ## 📋 Story Description
   [Full description from Jira, including context and gaps]

   ## 🏗️ MyHub Foundation Context
   [How this builds on existing MyHub foundation]
   [What exists vs what needs to be built]

   ## 🔧 Technical Requirements
   [Detailed technical implementation requirements]
   [Code examples and configuration samples]

   ## 🎯 Acceptance Criteria
   [All acceptance criteria from Jira, formatted as checkboxes]

   ## 📁 Files to Create/Modify
   [File structure showing what needs to be created/modified]

   ## 🚀 Implementation Guide
   [Step-by-step implementation instructions]

   ## 🧪 Testing Strategy
   [Unit tests, integration tests, and validation approach]

   ## 📚 Documentation Updates
   [What documentation needs to be created/updated]

   ## 🔐 Security Considerations
   [Any security-related implementation details]

   ## 🎨 Development Velocity Benefits
   [How this enables future development]

   ## 📋 Definition of Done
   [Clear checklist of completion criteria]

   **Dependencies**:
   - **Requires**: [Prerequisites]
   - **Enables**: [What this unblocks]
   - **Prepares for**: [Future work]

   **Success Metrics**:
   [Measurable outcomes]
   ```

4. **Create the GitHub Issue**
   - Use `mcp__github__create_issue` with:
     - Title: `[SCRUM-{{$ARGUMENTS}}] [Issue Summary from Jira]`
     - Body: Formatted content following the template
     - Labels: Convert Jira labels to GitHub labels
     - Assignee: Map from Jira assignee

5. **Post-Creation Tasks**
   - Verify issue was created successfully
   - Report the issue URL back to the user
   - Update CHANGELOG.md if needed

## Implementation Steps

```bash
# 1. Fetch Jira ticket
mcp__atlassian__jira_get_issue(
  issue_key="SCRUM-{{$ARGUMENTS}}",
  fields="*all"
)

# 2. Extract key information
- Summary, Description, Acceptance Criteria
- Epic parent, Sprint, Story Points
- Priority, Status, Assignee
- Labels, Dependencies

# 3. Format for GitHub
- Convert Jira markdown to GitHub markdown
- Add emoji indicators for sections
- Format code blocks appropriately
- Create checkbox lists from acceptance criteria

# 4. Create GitHub issue
mcp__github__create_issue(
  owner="canriquez",
  repo="rayces-v3",
  title="[SCRUM-{{$ARGUMENTS}}] {summary}",
  body="{formatted_content}",
  labels=[mapped_labels],
  assignees=[assignee_username]
)
```

## Quality Checklist
- [ ] All Jira content accurately transferred
- [ ] GitHub markdown properly formatted
- [ ] Code examples syntax highlighted
- [ ] Acceptance criteria as checkboxes
- [ ] Dependencies clearly stated
- [ ] Implementation guide actionable
- [ ] Testing strategy comprehensive
- [ ] Labels correctly mapped
- [ ] Assignee properly set

## Error Handling
- If SCRUM-{{$ARGUMENTS}} not found in Jira, report error
- If GitHub issue creation fails, report error with details
- If label mapping fails, create issue without labels and note in response

## Output
- GitHub issue URL (e.g., https://github.com/canriquez/rayces-v3/issues/XX)
- Confirmation message with issue number
- Any warnings about unmapped labels or missing information

Remember: The goal is to create self-contained GitHub issues that developers can work from without needing to reference Jira.