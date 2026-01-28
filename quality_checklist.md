
# Inhaus Brain - Quality Assurance Checklist v0.9.1
## Target: ≥ 0.88 Quality Score across 40 Test Cases

### 1. Text & Persuasion (Threshold: 0.88)
- [ ] **Grammar & Syntax**: Zero typos, proper punctuation.
- [ ] **Tone Alignment**: Matches "Brian" persona (Chief of Staff, professional, slightly witty/British if configured, else neutral/corporate).
- [ ] **Cultural Safety**: No Forbidden Terms (Guayaquil vs Quito regionalisms, classist terms like "pelucon").
- [ ] **Brand Alignment**: No references to Competitor Brand X.
- [ ] **Formatting**: Markdown headers, bullets, and bold text used effectively.
- [ ] **Orchestration**: Correct agent delegated (e.g., Creative for visuals, Research for data).

### 2. Image Generation (Threshold: 0.90)
- [ ] **Resolution**: Minimum 1024x1024.
- [ ] **Relevance**: Clearly reflects the user prompt (aligned objects/colors).
- [ ] **Artifacts**: No obvious distortion (extra fingers, blurred text).
- [ ] **Style**: Matches requested style (photorealistic, vector, etc.).
- [ ] **Latency**: Generated within acceptable timeframe (<15s for preview).

### 3. Video Generation (Threshold: 0.85)
- [ ] **Coherence**: Objects stay consistent across frames.
- [ ] **Motion**: Smooth movement, no "teleporting".
- [ ] **Duration**: Minimum 3 seconds.
- [ ] **Format**: Playable MP4/H.264.

### 4. Generative UI (Threshold: 0.92)
- [ ] **Validity**: Valid Dart/Flutter code.
- [ ] **Completeness**: No "TODO" implementations for core logic.
- [ ] **Accessibility**: Contrast ratios usually acceptable (basic check).
- [ ] **Responsive**: Handles basic layout constraints.

### 5. Multi-Turn Context (Threshold: 1.0 - Critical)
- [ ] **Retention**: Remembers user preferences stated 5 turns ago.
- [ ] **Correction**: Successfully adapts to "Make it bolder" without forgetting the subject.
- [ ] **Handoff**: Memories preserved when switching from Research -> Creative Agent.

### Automated Test Criteria (CI/CD)
1. Run `flutter test test/long_context_test.dart` -> MUST PASS
2. Run `flutter test test/orchestrator_service_test.dart` -> MUST PASS
3. Run `flutter test test/tool_calling_test.dart` -> MUST PASS
