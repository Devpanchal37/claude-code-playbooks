# FR Generation Workflow Pattern
> Standardized process for converting requirements to FR documentation

## When This Pattern Applies
- User describes new feature requirements
- User explains user journeys and flows
- User asks to "document this requirement"
- User says "new feature/flow/requirement"

## Automatic Workflow Steps

### 1. **Requirement Intake (5-10 Questions)**
```
Critical Questions to Ask:
- What are all the UI states? (loading, error, empty, success)
- What business rules apply? (validation, constraints, scope)
- What existing components can be reused?
- Are there security concerns? (user data, payments, access)
- What are the edge cases? (network failure, concurrent access)
- Which APIs are needed? (CRUD operations, integrations)
- What Figma designs are required?
```

### 2. **Analysis & Validation (Silent Quality Gates)**
```
API Security Checklist:
✅ No user_id direct access without validation
✅ Request-based profile access patterns
✅ Pagination for all list endpoints
✅ Transaction IDs for payment operations
✅ Rate limiting specifications

Performance Checklist:
✅ 20 items per page default, 50 max
✅ Response size optimization
✅ Caching strategy defined
✅ Background operation handling

Integration Checklist:
✅ Existing component reuse identified
✅ API pattern consistency maintained
✅ GetX/Clean Architecture compliance
✅ Error handling pattern consistency
```

### 3. **Documentation Generation (3 Files)**
```
File 1: {Module}_Flow_Requirements.md
- Complete user journey mapping
- Edge case and error scenario analysis
- Business rules and validation requirements
- UI state management specifications

File 2: {Module}_API_Requirements.md
- Security-validated API specifications
- Pagination and performance optimizations
- Error handling and retry patterns
- Integration with existing systems

File 3: {Module}_Implementation_Tasks.md
- Phase-by-phase implementation breakdown
- Figma design requirements list
- Component reuse analysis
- Dependencies and integration points
```

### 4. **File Organization & Pipeline Update**
```
Copy Pattern:
docs/memory/{files} → docs/FR/{module}/{files}

Pipeline Update:
Add new module section to docs/FR/_pipeline_status.md
Mark as ⏳ PENDING with implementation notes
Include security fixes and optimization notes
```

### 5. **Deliverables Summary**
```
Standard Output Format:
✅ Flow documentation with critical edge cases
✅ API specifications (security-validated, paginated)
✅ Implementation task breakdown (phase-by-phase)
✅ Figma design requirements list
✅ Updated pipeline status
✅ Integration analysis summary
```

## Quality Assurance Patterns

### **Common Security Fixes Applied:**
- Validate resource ownership — never expose user data by raw `user_id` alone
- Add authorization checks before returning sensitive resources
- Include transaction audit trails for financial and state-changing operations
- Specify rate limiting requirements

### **Common Performance Optimizations:**
- Add pagination to all list endpoints
- Include response size optimization
- Specify caching strategies
- Plan background operation handling

### **Common Integration Points:**
- Reuse existing UserModel/UserEntity structures
- Integrate with existing shared APIs and services
- Follow the project's `{{STATE_MANAGEMENT}}` state holder patterns
- Maintain `{{ARCHITECTURE}}` layer separation

## Success Metrics

**Complete FR Package Includes:**
- ✅ 3 properly formatted FR files
- ✅ Updated pipeline status
- ✅ Security issues addressed
- ✅ Performance optimizations applied
- ✅ Clear Figma requirements list
- ✅ Implementation-ready task breakdown

**Implementation Ready Means:**
- Developer can start domain layer immediately
- All API contracts are clear and secure
- UI requirements are specified with design needs
- Integration points are identified and planned
- Error handling scenarios are documented