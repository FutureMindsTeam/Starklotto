# Implementation Checklist - Issue #456

## 🚀 Quick Start Checklist

### ✅ Pre-Implementation
- [ ] Read the full PRD document
- [ ] Ensure you're on the `dev` branch
- [ ] Pull latest changes: `git pull origin dev`
- [ ] Create feature branch: `git checkout -b feature/issue-456-missing-basic-tests`

### ✅ Environment Setup
- [ ] Verify Scarb is installed: `scarb --version`
- [ ] Verify snforge is installed: `snforge --version`
- [ ] Build project: `scarb build`
- [ ] Run existing tests: `snforge test` (should all pass)

### ✅ Test Implementation Order

#### Phase 1: Basic Getter Tests (Easiest)
- [ ] `GetTicketPrice` tests
- [ ] `GetAccumulatedPrize` tests  
- [ ] `GetTicketCurrentId` tests

#### Phase 2: Complex Function Tests
- [ ] `GetFixedPrize` tests (all match scenarios)
- [ ] `GetDrawStatus` tests (lifecycle testing)

#### Phase 3: Ownership Tests (Most Complex)
- [ ] `SetTicketPrice` ownership validation
- [ ] `SetTicketPrice` success cases
- [ ] `SetTicketPrice` edge cases

### ✅ Test File Structure
```cairo
// packages/snfoundry/contracts/tests/test_basic_functions.cairo

use contracts::Lottery::{ILotteryDispatcher, ILotteryDispatcherTrait, Lottery};
use contracts::StarkPlayERC20::{IMintableDispatcher, IMintableDispatcherTrait};
use openzeppelin_testing::declare_and_deploy;
use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    CheatSpan, ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait, EventSpyTrait,
    cheat_block_timestamp, cheat_caller_address, declare, spy_events, start_cheat_caller_address,
    start_mock_call, stop_cheat_caller_address, stop_mock_call,
};
use starknet::ContractAddress;

// Copy constants from test_CU03.cairo
const OWNER: ContractAddress = 0x02dA5254690b46B9C4059C25366D1778839BE63C142d899F0306fd5c312A5918
    .try_into()
    .unwrap();

const USER1: ContractAddress = 0x03dA5254690b46B9C4059C25366D1778839BE63C142d899F0306fd5c312A5919
    .try_into()
    .unwrap();

// Copy helper functions from test_CU03.cairo
fn owner_address() -> ContractAddress {
    OWNER
}

fn deploy_lottery() -> (ContractAddress, IMintableDispatcher, ILotteryDispatcher) {
    // Copy implementation from test_CU03.cairo
}

// Your test implementations here...
```

### ✅ Key Test Patterns to Follow

#### 1. Ownership Test Pattern
```cairo
#[test]
fn test_set_ticket_price_only_owner_can_change() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    // Test owner can change price
    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());
    lottery_dispatcher.SetTicketPrice(1000000000000000000);
    assert!(lottery_dispatcher.GetTicketPrice() == 1000000000000000000, "Owner should be able to set price");
    stop_cheat_caller_address(lottery_dispatcher.contract_address);

    // Test non-owner cannot change price
    start_cheat_caller_address(lottery_dispatcher.contract_address, USER1);
    // This should fail - implement proper error handling
    stop_cheat_caller_address(lottery_dispatcher.contract_address);
}
```

#### 2. Getter Test Pattern
```cairo
#[test]
fn test_get_ticket_price_default_value() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    let initial_price = lottery_dispatcher.GetTicketPrice();
    assert!(initial_price == 0, "Initial ticket price should be 0");
}
```

#### 3. Edge Case Test Pattern
```cairo
#[test]
fn test_get_fixed_prize_all_scenarios() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    // Test all match scenarios
    assert!(lottery_dispatcher.GetFixedPrize(0) == 0, "0 matches should return 0");
    assert!(lottery_dispatcher.GetFixedPrize(1) == 0, "1 match should return 0");
    // ... continue for all scenarios
}
```

### ✅ Validation Steps
- [ ] Run new tests: `snforge test --match-contract test_basic_functions`
- [ ] Run all tests: `snforge test`
- [ ] Check compilation: `scarb build`
- [ ] Verify no regressions in existing functionality

### ✅ Documentation Updates
- [ ] Update `test_inventory.md` with new test functions
- [ ] Add comments to all test functions
- [ ] Document any special test patterns or assumptions

### ✅ Pull Request Preparation
- [ ] Commit with descriptive message
- [ ] Push to remote branch
- [ ] Create PR targeting `dev` branch
- [ ] Add issue reference: "Closes #456"
- [ ] Add test coverage summary in PR description

### ✅ Final Checklist
- [ ] All tests pass consistently
- [ ] Code follows project standards
- [ ] Documentation is complete
- [ ] PR is ready for review
- [ ] Issue #456 is properly referenced

## 🎯 Success Criteria
- **20+ new test cases** implemented
- **80%+ test coverage** for basic functions
- **Zero test failures** in CI/CD
- **Clean code review** with no major issues
- **Issue #456 closed** successfully

## 📞 Need Help?
- Check existing test patterns in `test_CU03.cairo`
- Review the full PRD document for detailed requirements
- Follow the KISS principle - keep tests simple and focused
- Verify results with console outputs as needed
