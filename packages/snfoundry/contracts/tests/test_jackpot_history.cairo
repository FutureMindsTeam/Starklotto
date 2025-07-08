use contracts::Lottery::ILotteryDispatcher;
use contracts::Lottery::ILotteryDispatcherTrait;
use snforge_std::{declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address, stop_cheat_caller_address};
use starknet::ContractAddress;

// Helper constants
pub fn OWNER() -> ContractAddress {
    'OWNER'.try_into().unwrap()
}

pub fn USER() -> ContractAddress {
    'USER'.try_into().unwrap()
}

fn deploy_lottery() -> ContractAddress {
    let mut constructor_calldata = array![];
    OWNER().serialize(ref constructor_calldata);

    let lottery_class = declare("Lottery").unwrap().contract_class();
    let (lottery_addr, _) = lottery_class.deploy(@constructor_calldata).unwrap();

    lottery_addr
}

#[test]
fn test_get_jackpot_history_basic() {
    let lottery_addr = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, OWNER());
    // Initialize the lottery
    lottery_dispatcher.Initialize(1000000000000000000_u256, 1000000000000000000000_u256);
    stop_cheat_caller_address(lottery_dispatcher.contract_address);

    // Get jackpot history - should return 1 entry for the initial draw
    let jackpot_history = lottery_dispatcher.get_jackpot_history();
    assert!(jackpot_history.len() == 1, "Should have 1 jackpot entry");

    let first_entry = *jackpot_history.at(0);
    assert!(first_entry.drawId == 1, "First draw should have ID 1");
    assert!(first_entry.isActive, "First draw should be active");
    assert!(!first_entry.isCompleted, "First draw should not be completed");
}

#[test]
fn test_get_jackpot_history_multiple_draws() {
    let lottery_addr = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, OWNER());
    // Initialize the lottery
    lottery_dispatcher.Initialize(1000000000000000000_u256, 1000000000000000000000_u256);

    // Create additional draws
    lottery_dispatcher.CreateNewDraw(2000000000000000000000_u256);
    lottery_dispatcher.CreateNewDraw(3000000000000000000000_u256);
    stop_cheat_caller_address(lottery_dispatcher.contract_address);
    // Get jackpot history - should return 3 entries
    let jackpot_history = lottery_dispatcher.get_jackpot_history();
    assert!(jackpot_history.len() == 3, "Should have 3 jackpot entries");

    // Verify each entry
    let entry1 = *jackpot_history.at(0);
    let entry2 = *jackpot_history.at(1);
    let entry3 = *jackpot_history.at(2);

    assert!(entry1.drawId == 1, "First entry should have drawId 1");
    assert!(entry2.drawId == 2, "Second entry should have drawId 2");
    assert!(entry3.drawId == 3, "Third entry should have drawId 3");

    assert!(entry1.jackpotAmount == 1000000000000000000000_u256, "First jackpot amount incorrect");
    assert!(entry2.jackpotAmount == 2000000000000000000000_u256, "Second jackpot amount incorrect");
    assert!(entry3.jackpotAmount == 3000000000000000000000_u256, "Third jackpot amount incorrect");
}

#[test]
fn test_get_jackpot_history_completed_draw() {
    let lottery_addr = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, OWNER());
    // Initialize the lottery
    lottery_dispatcher.Initialize(1000000000000000000_u256, 1000000000000000000000_u256);

    // Complete the draw
    lottery_dispatcher.DrawNumbers(1);
    stop_cheat_caller_address(lottery_dispatcher.contract_address);
    // Get jackpot history
    let jackpot_history = lottery_dispatcher.get_jackpot_history();
    assert!(jackpot_history.len() == 1, "Should have 1 jackpot entry");

    let entry = *jackpot_history.at(0);
    assert!(entry.drawId == 1, "Entry should have drawId"); 
    assert!(!entry.isActive, "Draw should not be active after completion");
    assert!(entry.isCompleted, "Draw should be completed");
}

#[test]
fn test_get_jackpot_history_performance() {
    let lottery_addr = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, OWNER());
    // Initialize the lottery
    lottery_dispatcher.Initialize(1000000000000000000_u256, 1000000000000000000000_u256);

    // Create many draws to test performance
    let mut i = 0;
    while i != 10 {
        lottery_dispatcher.CreateNewDraw((i + 2) * 1000000000000000000000_u256);
        i = i + 1;
    }
    stop_cheat_caller_address(lottery_dispatcher.contract_address);
    // Get jackpot history - should handle multiple entries efficiently
    let jackpot_history = lottery_dispatcher.get_jackpot_history();
    assert!(jackpot_history.len() == 11, "Should have 11 jackpot entries");

    // Verify the last entry
    let last_entry = *jackpot_history.at(10);
    assert!(last_entry.drawId == 11, "Last entry should have drawId 11");
    assert!(last_entry.jackpotAmount == 11000000000000000000000_u256, "Last jackpot amount incorrect");
} 