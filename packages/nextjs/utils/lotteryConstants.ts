// Lottery number range constants
export const LOTTERY_MIN_NUMBER = 1;
export const LOTTERY_MAX_NUMBER = 40;
export const LOTTERY_REQUIRED_NUMBERS = 5;

// Validation messages
export const LOTTERY_VALIDATION_MESSAGES = {
  INVALID_RANGE: `Numbers must be between ${LOTTERY_MIN_NUMBER} and ${LOTTERY_MAX_NUMBER}`,
  INVALID_COUNT: `Must select exactly ${LOTTERY_REQUIRED_NUMBERS} numbers`,
  DUPLICATE_NUMBERS: "Numbers must be unique",
} as const;
