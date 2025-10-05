# FileMaker Scripts for ABA Data Collection

This document outlines the FileMaker scripts that need to be created to support the ABA data collection Flutter app.

## Required Scripts

### 1. EvaluateAssignmentMastery

**Purpose**: Evaluates if a program assignment has met mastery criteria based on recent session data.

**Parameters**:
- `assignmentId` (Text): The ID of the program assignment to evaluate

**Script Logic**:
1. Find the program assignment record using the provided ID
2. Parse the `Mastery_Criteria` field (JSON) to get evaluation criteria
3. Find all recent `SessionData` records for this assignment
4. Calculate metrics based on the assignment's `Datacollection_type`:
   - `percentCorrect`/`percentIndependent`: Calculate overall percentage from all recent sessions
   - `rate`: Calculate overall rate per minute from all recent sessions
   - `duration`: Calculate total duration from all recent sessions
   - `taskAnalysis`: Calculate overall task completion percentage
   - `timeSampling`: Calculate overall on-task percentage
   - `ratingScale`: Calculate average rating
5. Check if criteria are met:
   - `metric`: The metric to evaluate (percent, rate_per_min, duration_seconds, etc.)
   - `direction`: "at_least" or "at_most"
   - `threshold`: The target value
   - `consecutiveSessions`: Number of consecutive sessions that must meet criteria
   - `minTrialsPerSession`: Minimum trials required per session
   - `minDistinctDays`: Minimum number of different days required
6. If mastery criteria are met:
   - Set `Status` to "mastered"
   - Set `masteredAt_ts` to current timestamp
   - Optionally set `Intervention_phase` to "maintenance"
7. Return JSON result with mastery status

**Sample Criteria JSON**:
```json
{
  "metric": "percent",
  "direction": "at_least",
  "threshold": 80,
  "consecutiveSessions": 2,
  "minTrialsPerSession": 10,
  "minDistinctDays": 2
}
```

### 2. CloseVisitFinalize

**Purpose**: Finalizes a visit by calculating billable time and units, and optionally runs behavior rollups.

**Parameters**:
- `visitId` (Text): The ID of the visit to finalize

**Script Logic**:
1. Find the visit record using the provided ID
2. Validate that `start_ts` exists and `end_ts` is not null
3. Calculate `billableMinutes_n`:
   - `billableMinutes_n = Round((end_ts - start_ts) * 24 * 60)`
4. Calculate `billableUnits_n`:
   - `billableUnits_n = Ceiling(billableMinutes_n / 15)`
5. Update the visit record with calculated values
6. Optionally call `UpdateVisitBehaviorRollups` script
7. Return JSON result with calculated values:
   ```json
   {
     "ok": true,
     "billableMinutes": 45,
     "billableUnits": 3
   }
   ```

### 3. UpdateVisitBehaviorRollups (Optional)

**Purpose**: Creates summary statistics for behavior logs within a visit.

**Parameters**:
- `visitId` (Text): The ID of the visit to process

**Script Logic**:
1. Find all behavior logs for the specified visit
2. Group by behavior ID
3. Calculate summary statistics:
   - Total count of events
   - Total duration
   - Average rate per minute
   - Most common antecedent/consequence patterns
4. Store results in a rollup table or visit record
5. Return summary data

## FileMaker Layout Requirements

### 1. api_patients
- `id` (Text, Primary Key)
- `namefull` (Text)
- `namefirst` (Text)
- `namelast` (Text)

### 2. api_appointments
- `id` (Text, Primary Key)
- `clientId` (Text, Foreign Key to api_patients)
- `staffId` (Text)
- `Procedure` (Text) - Service Code
- `start_ts` (Timestamp)
- `end_ts` (Timestamp)
- `statusInput` (Text) - scheduled|in_progress|complete|canceled
- `notes` (Text)
- `units_total` (Number)

### 3. api_program_assignments
- `id` (Text, Primary Key)
- `clientId` (Text, Foreign Key to api_patients)
- `ltgId` (Text, Foreign Key to Long-Term Goals)
- `SubMilestone_name` (Text) - Program name
- `Datacollection_type` (Text) - percentCorrect, rate, taskAnalysis, etc.
- `Mastery_Criteria` (Text) - JSON string with mastery rules
- `config_json` (Text) - JSON string with widget configuration
- `Status` (Text) - active|mastered|on_hold
- `Intervention_phase` (Text) - baseline|intervention|maintenance|generalization
- `masteredAt_ts` (Timestamp)
- `programTemplateId` (Text, Optional)

### 4. api_sessiondata
- `id` (Text, Primary Key)
- `AppointmentID` (Text, Foreign Key to api_appointments)
- `clientId` (Text, Foreign Key to api_patients)
- `assignmentId` (Text, Foreign Key to api_program_assignments)
- `startedAt_ts` (Timestamp)
- `updatedAt_ts` (Timestamp)
- `payload_json` (Text) - JSON string with collected data
- `notes` (Text, Optional)
- `staffId` (Text, Optional)

### 5. api_behavior_defs
- `id` (Text, Primary Key)
- `orgId` (Text, Optional)
- `clientId` (Text, Optional)
- `name` (Text)
- `code` (Text)
- `defaultLogType` (Text)
- `severityScale_json` (Text) - JSON string with severity scale

### 6. api_behavior_logs
- `id` (Text, Primary Key)
- `visitId` (Text, Foreign Key to api_appointments)
- `clientId` (Text, Foreign Key to api_patients)
- `behaviorId` (Text, Foreign Key to api_behavior_defs)
- `assignmentId` (Text, Optional, Foreign Key to api_program_assignments)
- `start_ts` (Timestamp, Optional)
- `end_ts` (Timestamp, Optional)
- `duration_sec_n` (Number, Optional)
- `count_n` (Number, Optional)
- `rate_per_min_n` (Number, Optional)
- `antecedent_t` (Text, Optional)
- `behavior_desc_t` (Text, Optional)
- `consequence_t` (Text, Optional)
- `setting_t` (Text, Optional)
- `perceivedFunction_t` (Text, Optional)
- `severity_n` (Number, Optional)
- `injury_yn` (Boolean, Optional)
- `restraint_used_yn` (Boolean, Optional)
- `notes_t` (Text, Optional)
- `collector` (Text, Optional)
- `createdAt_ts` (Timestamp)
- `updatedAt_ts` (Timestamp)

## Implementation Notes

1. **Authentication**: Ensure all layouts require proper authentication tokens
2. **Error Handling**: Scripts should return meaningful error messages in JSON format
3. **Data Validation**: Validate all input parameters before processing
4. **Performance**: Consider indexing frequently queried fields
5. **Logging**: Log script execution for debugging purposes
6. **Backup**: Ensure data is backed up before making status changes

## Testing Checklist

- [ ] Scripts can be called via Data API
- [ ] Mastery evaluation works with different data types
- [ ] Billable time calculation is accurate
- [ ] Error handling works for invalid inputs
- [ ] JSON parsing and generation works correctly
- [ ] Scripts handle edge cases (no data, invalid criteria, etc.)
