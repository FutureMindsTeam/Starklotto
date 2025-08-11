use contracts::Lottery::{ILotteryDispatcher, ILotteryDispatcherTrait};
use contracts::StarkPlayERC20::{IMintableDispatcher, IMintableDispatcherTrait};
use contracts::StarkPlayVault::{IStarkPlayVaultDispatcher, IStarkPlayVaultDispatcherTrait};
use core::array::ArrayTrait;
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, start_cheat_caller_address,
    stop_cheat_caller_address,
};
use starknet::ContractAddress;

// Helper constants
pub fn OWNER() -> ContractAddress {
    'OWNER'.try_into().unwrap()
}

pub fn USER() -> ContractAddress {
    'USER'.try_into().unwrap()
}

pub fn deploy_lottery() -> ContractAddress {
    // Deploy mock contracts first
    let mock_strk_play = deploy_mock_strk_play();
    let mock_vault = deploy_mock_vault(mock_strk_play.contract_address);

    let mut constructor_calldata = array![];
    OWNER().serialize(ref constructor_calldata);
    mock_strk_play.contract_address.serialize(ref constructor_calldata);
    mock_vault.contract_address.serialize(ref constructor_calldata);

    let lottery_class = declare("Lottery").unwrap().contract_class();
    let (lottery_addr, _) = lottery_class.deploy(@constructor_calldata).unwrap();

    lottery_addr
}

fn deploy_mock_strk_play() -> IMintableDispatcher {
    let starkplay_contract = declare("StarkPlayERC20").unwrap().contract_class();
    let starkplay_constructor_calldata = array![
        OWNER().into(), OWNER().into(),
    ]; // recipient and admin
    let (starkplay_address, _) = starkplay_contract
        .deploy(@starkplay_constructor_calldata)
        .unwrap();
    IMintableDispatcher { contract_address: starkplay_address }
}

fn deploy_mock_vault(strk_play_address: ContractAddress) -> IStarkPlayVaultDispatcher {
    let vault_contract = declare("StarkPlayVault").unwrap().contract_class();
    let vault_constructor_calldata = array![
        OWNER().into(), strk_play_address.into(), 50_u64.into(),
    ]; // owner, starkPlayToken, feePercentage
    let (vault_address, _) = vault_contract.deploy(@vault_constructor_calldata).unwrap();
    IStarkPlayVaultDispatcher { contract_address: vault_address }
}

// Helper functions to access JackpotEntry data through getter functions
fn get_jackpot_entry_draw_id(lottery_dispatcher: ILotteryDispatcher, draw_id: u64) -> u64 {
    lottery_dispatcher.GetJackpotEntryDrawId(draw_id)
}

fn get_jackpot_entry_amount(lottery_dispatcher: ILotteryDispatcher, draw_id: u64) -> u256 {
    lottery_dispatcher.GetJackpotEntryAmount(draw_id)
}

fn get_jackpot_entry_start_time(lottery_dispatcher: ILotteryDispatcher, draw_id: u64) -> u64 {
    lottery_dispatcher.GetJackpotEntryStartTime(draw_id)
}

fn get_jackpot_entry_end_time(lottery_dispatcher: ILotteryDispatcher, draw_id: u64) -> u64 {
    lottery_dispatcher.GetJackpotEntryEndTime(draw_id)
}

fn get_jackpot_entry_is_active(lottery_dispatcher: ILotteryDispatcher, draw_id: u64) -> bool {
    lottery_dispatcher.GetJackpotEntryIsActive(draw_id)
}

fn get_jackpot_entry_is_completed(lottery_dispatcher: ILotteryDispatcher, draw_id: u64) -> bool {
    lottery_dispatcher.GetJackpotEntryIsCompleted(draw_id)
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

    // Use getter functions to access the data
    assert!(get_jackpot_entry_draw_id(lottery_dispatcher, 1) == 1, "First draw should have ID 1");
    assert!(get_jackpot_entry_is_active(lottery_dispatcher, 1), "First draw should be active");
    assert!(
        !get_jackpot_entry_is_completed(lottery_dispatcher, 1),
        "First draw should not be completed",
    );
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

    // Verify each entry using getter functions
    assert!(
        get_jackpot_entry_draw_id(lottery_dispatcher, 1) == 1, "First entry should have drawId 1",
    );
    assert!(
        get_jackpot_entry_draw_id(lottery_dispatcher, 2) == 2, "Second entry should have drawId 2",
    );
    assert!(
        get_jackpot_entry_draw_id(lottery_dispatcher, 3) == 3, "Third entry should have drawId 3",
    );

    assert!(
        get_jackpot_entry_amount(lottery_dispatcher, 1) == 1000000000000000000000_u256,
        "First jackpot amount incorrect",
    );
    assert!(
        get_jackpot_entry_amount(lottery_dispatcher, 2) == 2000000000000000000000_u256,
        "Second jackpot amount incorrect",
    );
    assert!(
        get_jackpot_entry_amount(lottery_dispatcher, 3) == 3000000000000000000000_u256,
        "Third jackpot amount incorrect",
    );
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

    // Use getter functions to verify the completed draw
    assert!(get_jackpot_entry_draw_id(lottery_dispatcher, 1) == 1, "Entry should have drawId");
    assert!(
        !get_jackpot_entry_is_active(lottery_dispatcher, 1),
        "Draw should not be active after completion",
    );
    assert!(get_jackpot_entry_is_completed(lottery_dispatcher, 1), "Draw should be completed");
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

    // Verify the last entry using getter functions
    assert!(
        get_jackpot_entry_draw_id(lottery_dispatcher, 11) == 11, "Last entry should have drawId 11",
    );
    assert!(
        get_jackpot_entry_amount(lottery_dispatcher, 11) == 11000000000000000000000_u256,
        "Last jackpot amount incorrect",
    );
}
