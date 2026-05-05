#!/bin/bash
# Post-commit hook: keep code-review-graph knowledge graph current
# Runs automatically after each commit via Claude Code hooks configuration
python -m code_review_graph update
