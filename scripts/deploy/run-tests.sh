#!/bin/bash

# Test Execution Script for OnboardingV2
# This script runs Apex tests and validates coverage
#
# Usage:
#   ./scripts/deploy/run-tests.sh [org-alias] [test-classes]
#
# Examples:
#   ./scripts/deploy/run-tests.sh myorg
#   ./scripts/deploy/run-tests.sh myorg OnboardingRulesServiceTest,OnboardingStatusEvaluatorTest

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get org alias from argument or use default
ORG_ALIAS=${1:-myorg}
TEST_CLASSES=${2:-""}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}OnboardingV2 Test Execution${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if Salesforce CLI is installed
if ! command -v sf &> /dev/null; then
    echo -e "${RED}Error: Salesforce CLI (sf) is not installed${NC}"
    exit 1
fi

# Check if org is authenticated
echo -e "${YELLOW}Checking org authentication...${NC}"
if ! sf org display --target-org "$ORG_ALIAS" &> /dev/null; then
    echo -e "${RED}Error: Org '$ORG_ALIAS' is not authenticated${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Org authenticated${NC}"
echo ""

# Run tests
echo -e "${YELLOW}Running Apex tests...${NC}"

if [ -z "$TEST_CLASSES" ]; then
    # Run all tests
    echo "Running all tests in org..."
    TEST_RESULT=$(sf apex run test --target-org "$ORG_ALIAS" --result-format human --code-coverage --wait 10)
else
    # Run specific test classes
    echo "Running test classes: $TEST_CLASSES"
    TEST_RESULT=$(sf apex run test --class-names "$TEST_CLASSES" --target-org "$ORG_ALIAS" --result-format human --code-coverage --wait 10)
fi

# Check test results
if echo "$TEST_RESULT" | grep -q "Test Execution: PASSED"; then
    echo -e "${GREEN}✓ All tests passed${NC}"
    
    # Extract coverage information
    COVERAGE=$(echo "$TEST_RESULT" | grep -oP 'Code Coverage: \K[0-9]+%' || echo "N/A")
    echo "  Code Coverage: $COVERAGE"
    
    # Check if coverage meets minimum (75%)
    COVERAGE_NUM=$(echo "$COVERAGE" | grep -oP '[0-9]+' || echo "0")
    if [ "$COVERAGE_NUM" -ge 75 ]; then
        echo -e "${GREEN}  ✓ Coverage meets minimum requirement (75%)${NC}"
    else
        echo -e "${YELLOW}  ⚠ Warning: Coverage below 75%${NC}"
    fi
else
    echo -e "${RED}✗ Some tests failed${NC}"
    echo "$TEST_RESULT"
    exit 1
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Test Execution Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Save test results to file
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULT_FILE="test-results/test-run-$TIMESTAMP.txt"
mkdir -p test-results
echo "$TEST_RESULT" > "$RESULT_FILE"
echo "Test results saved to: $RESULT_FILE"
echo ""

