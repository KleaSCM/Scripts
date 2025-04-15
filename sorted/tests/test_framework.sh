#!/bin/bash
# @interactive
# Script: test_framework.sh
# Description: Test framework for validating scripts
# Author: KleaSCM
# Version: 1.0.0
# Last Modified: $(date +%Y-%m-%d)
# Dependencies: bash >= 4.0

# Source common functions
source "$(dirname "$0")/../lib/common.sh" || {
    echo "Error: Failed to load common functions"
    exit 1
}

# Test configuration
TEST_DIR="$(dirname "$0")"
TEST_LOG="$TEST_DIR/test.log"
TEST_RESULTS="$TEST_DIR/results.txt"

# Initialize test logging
init_test_logging() {
    mkdir -p "$(dirname "$TEST_LOG")"
    exec 3>&1 4>&2
    exec 1> >(tee -a "$TEST_LOG")
    exec 2>&1
}

# Test functions
test_script_exists() {
    local script="$1"
    if [[ -f "$script" ]]; then
        log "PASS: Script exists: $script"
        return 0
    else
        error "FAIL: Script not found: $script"
        return 1
    fi
}

test_script_executable() {
    local script="$1"
    if [[ -x "$script" ]]; then
        log "PASS: Script is executable: $script"
        return 0
    else
        error "FAIL: Script is not executable: $script"
        return 1
    fi
}

test_script_header() {
    local script="$1"
    local required_fields=("Description" "Author" "Version" "Last Modified" "Dependencies")
    local missing_fields=()
    
    for field in "${required_fields[@]}"; do
        if ! grep -q "^# $field:" "$script"; then
            missing_fields+=("$field")
        fi
    done
    
    if [[ ${#missing_fields[@]} -eq 0 ]]; then
        log "PASS: Script header contains all required fields: $script"
        return 0
    else
        error "FAIL: Script header missing fields: ${missing_fields[*]} in $script"
        return 1
    fi
}

test_script_syntax() {
    local script="$1"
    if bash -n "$script"; then
        log "PASS: Script syntax is valid: $script"
        return 0
    else
        error "FAIL: Script syntax error in: $script"
        return 1
    fi
}

test_script_dependencies() {
    local script="$1"
    local dependencies
    
    # Extract dependencies from script header
    dependencies=$(grep "^# Dependencies:" "$script" | sed 's/^# Dependencies: //')
    
    if [[ -n "$dependencies" ]]; then
        local deps=($dependencies)
        for dep in "${deps[@]}"; do
            if ! command -v "$dep" &> /dev/null; then
                error "FAIL: Missing dependency: $dep for script: $script"
                return 1
            fi
        done
    fi
    
    log "PASS: All dependencies available for: $script"
    return 0
}

# Run all tests for a script
run_tests() {
    local script="$1"
    local test_results=()
    local overall_result=0
    
    log "Running tests for: $script"
    
    # Run individual tests
    test_script_exists "$script" || test_results+=("exists")
    test_script_executable "$script" || test_results+=("executable")
    test_script_header "$script" || test_results+=("header")
    test_script_syntax "$script" || test_results+=("syntax")
    test_script_dependencies "$script" || test_results+=("dependencies")
    
    # Check overall result
    if [[ ${#test_results[@]} -eq 0 ]]; then
        log "PASS: All tests passed for: $script"
        return 0
    else
        error "FAIL: Tests failed for: $script (${test_results[*]})"
        return 1
    fi
}

# Main function
main() {
    local scripts_dir="$1"
    local overall_result=0
    
    [[ -z "$scripts_dir" ]] && {
        error "Usage: $0 <scripts_directory>"
        exit 1
    }
    
    init_test_logging
    log "Starting test suite"
    
    # Find all scripts
    while IFS= read -r script; do
        run_tests "$script" || overall_result=1
    done < <(find "$scripts_dir" -type f -name "*.sh")
    
    log "Test suite completed"
    exit $overall_result
}

# Run main function
main "$@" 