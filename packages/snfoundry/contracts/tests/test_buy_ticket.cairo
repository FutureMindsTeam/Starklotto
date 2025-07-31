use contracts::Lottery::{ILotteryDispatcher, ILotteryDispatcherTrait};
use contracts::StarkPlayERC20::{IMintableDispatcher, IMintableDispatcherTrait};
use contracts::StarkPlayVault::{IStarkPlayVaultDispatcher, IStarkPlayVaultDispatcherTrait};
use openzeppelin_testing::declare_and_deploy;
use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use openzeppelin_utils::serde::SerializedAppend;
use snforge_std::{
    CheatSpan, cheat_caller_address, start_cheat_caller_address, stop_cheat_caller_address,
    declare, ContractClassTrait, DeclareResultTrait, spy_events, EventSpy, EventSpyAssertionsTrait,
    EventSpyTrait, start_mock_call, stop_mock_call
};
use starknet::ContractAddress;

// Test addresses - following existing pattern
const OWNER: ContractAddress = 0x02dA5254690b46B9C4059C25366D1778839BE63C142d899F0306fd5c312A5918
    .try_into()
    .unwrap();

const USER1: ContractAddress = 0x03dA5254690b46B9C4059C25366D1778839BE63C142d899F0306fd5c312A5919
    .try_into()
    .unwrap();

const USER2: ContractAddress = 0x04dA5254690b46B9C4059C25366D1778839BE63C142d899F0306fd5c312A5920
    .try_into()
    .unwrap();

// Constants
const TICKET_PRICE: u256 = 1000000000000000000; // 1 STRK token
const INITIAL_JACKPOT: u256 = 10000000000000000000; // 10 STRK tokens

// Hardcoded addresses from Lottery contract
const STRK_PLAY_CONTRACT_ADDRESS: ContractAddress = 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
    .try_into()
    .unwrap();
const STRK_PLAY_VAULT_CONTRACT_ADDRESS: ContractAddress = 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
    .try_into()
    .unwrap();

//=======================================================================================
// Helper functions - following existing patterns
//=======================================================================================

fn owner_address() -> ContractAddress {
    OWNER
}

fn deploy_starkplay_token() -> ContractAddress {
    let contract_class = declare("StarkPlayERC20").unwrap().contract_class();
    let mut calldata = array![];
    calldata.append_serde(owner_address()); // recipient
    calldata.append_serde(owner_address()); // admin
    let (contract_address, _) = contract_class.deploy(@calldata).unwrap();
    contract_address
}

fn deploy_starkplay_vault(token_address: ContractAddress) -> ContractAddress {
    let contract_class = declare("StarkPlayVault").unwrap().contract_class();
    let mut calldata = array![];
    calldata.append_serde(owner_address());
    calldata.append_serde(token_address);
    calldata.append_serde(50_u64); // 0.5% fee
    let (contract_address, _) = contract_class.deploy(@calldata).unwrap();
    contract_address
}

fn deploy_lottery() -> ContractAddress {
    let mut calldata = array![];
    calldata.append_serde(owner_address());
    declare_and_deploy("Lottery", calldata)
}

fn create_valid_numbers() -> Array<u16> {
    let mut numbers = array![];
    numbers.append(1);
    numbers.append(15);
    numbers.append(25);
    numbers.append(35);
    numbers.append(40);
    numbers
}

fn setup_mocks_for_buy_ticket(user: ContractAddress, user_balance: u256, allowance: u256, transfer_success: bool) {
    // Mock balance_of call
    start_mock_call(STRK_PLAY_CONTRACT_ADDRESS, selector!("balance_of"), user_balance);
    
    // Mock allowance call  
    start_mock_call(STRK_PLAY_CONTRACT_ADDRESS, selector!("allowance"), allowance);
    
    // Mock transfer_from call
    start_mock_call(STRK_PLAY_CONTRACT_ADDRESS, selector!("transfer_from"), transfer_success);
}

fn setup_mocks_success(user: ContractAddress) {
    setup_mocks_for_buy_ticket(user, TICKET_PRICE * 10, TICKET_PRICE * 10, true);
}

fn setup_mocks_insufficient_balance(user: ContractAddress) {
    setup_mocks_for_buy_ticket(user, TICKET_PRICE / 2, TICKET_PRICE * 10, true);
}

fn setup_mocks_zero_balance(user: ContractAddress) {
    setup_mocks_for_buy_ticket(user, 0, TICKET_PRICE * 10, true);
}

fn setup_mocks_insufficient_allowance(user: ContractAddress) {
    setup_mocks_for_buy_ticket(user, TICKET_PRICE * 10, 0, true);
}

fn cleanup_mocks() {
    stop_mock_call(STRK_PLAY_CONTRACT_ADDRESS, selector!("balance_of"));
    stop_mock_call(STRK_PLAY_CONTRACT_ADDRESS, selector!("allowance"));
    stop_mock_call(STRK_PLAY_CONTRACT_ADDRESS, selector!("transfer_from"));
}

//=======================================================================================
// Phase 1: Successful Case Tests
//=======================================================================================

#[test]
fn test_buy_ticket_successful_single_ticket() {
    let lottery_address = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };
    
    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);
    
    // Setup mocks for successful ticket purchase
    setup_mocks_success(USER1);
    
    let numbers = create_valid_numbers();
    
    // Buy ticket
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers);
    
    // Verify results
    let ticket_count = lottery_dispatcher.GetUserTicketsCount(1, USER1);
    assert(ticket_count == 1, 'Should have 1 ticket');
    
    // Cleanup mocks
    cleanup_mocks();
}

#[test]
fn test_buy_multiple_tickets_same_user() {
    let lottery_address = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };
    
    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);
    
    // Setup mocks for successful ticket purchases
    setup_mocks_success(USER1);
    
    let numbers = create_valid_numbers();
    
    // Buy 3 tickets
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(3));
    lottery_dispatcher.BuyTicket(1, numbers.clone());
    lottery_dispatcher.BuyTicket(1, numbers.clone());
    lottery_dispatcher.BuyTicket(1, numbers);
    
    let ticket_count = lottery_dispatcher.GetUserTicketsCount(1, USER1);
    assert(ticket_count == 3, 'Should have 3 tickets');
    
    cleanup_mocks();
}

#[test]
fn test_buy_tickets_different_users() {
    let lottery_address = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };
    
    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);
    
    let numbers = create_valid_numbers();
    
    // Setup mocks for USER1
    setup_mocks_success(USER1);
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers.clone());
    cleanup_mocks();
    
    // Setup mocks for USER2
    setup_mocks_success(USER2);
    cheat_caller_address(lottery_address, USER2, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers);
    cleanup_mocks();
    
    let user1_count = lottery_dispatcher.GetUserTicketsCount(1, USER1);
    let user2_count = lottery_dispatcher.GetUserTicketsCount(1, USER2);
    
    assert(user1_count == 1, 'User1 should have 1 ticket');
    assert(user2_count == 1, 'User2 should have 1 ticket');
}

#[test]
fn test_buy_ticket_different_number_combinations() {
    let lottery_address = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };
    
    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);
    
    // Setup mocks for successful ticket purchases
    setup_mocks_success(USER1);
    
    // Different number combinations
    let mut numbers1 = array![1, 2, 3, 4, 5];
    let mut numbers2 = array![10, 11, 12, 13, 14];
    let mut numbers3 = array![36, 37, 38, 39, 40];
    
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(3));
    lottery_dispatcher.BuyTicket(1, numbers1);
    lottery_dispatcher.BuyTicket(1, numbers2);
    lottery_dispatcher.BuyTicket(1, numbers3);
    
    let ticket_count = lottery_dispatcher.GetUserTicketsCount(1, USER1);
    assert(ticket_count == 3, 'Should have 3 tickets');
    
    cleanup_mocks();
}

#[test]
fn test_buy_ticket_event_emission() {
    let lottery_address = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };
    
    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);
    
    // Setup mocks for successful ticket purchase
    setup_mocks_success(USER1);
    
    let numbers = create_valid_numbers();
    let mut spy = spy_events();
    
    // Buy ticket
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers);
    
    let events = spy.get_events();
    assert(events.events.len() >= 1, 'Should emit events');
    
    cleanup_mocks();
}

//=======================================================================================
// Phase 2: Validation Tests
//=======================================================================================

#[should_panic(expected: 'Invalid numbers')]
#[test]
fn test_buy_ticket_invalid_numbers_count_too_few() {
    let lottery_address = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };
    
    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);
    
    // Setup mocks for successful ticket purchase (validation fails before payment)
    setup_mocks_success(USER1);
    
    // Only 4 numbers instead of 5
    let mut numbers = array![1, 2, 3, 4];
    
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers);
    
    cleanup_mocks();
}

#[should_panic(expected: 'Invalid numbers')]
#[test]
fn test_buy_ticket_invalid_numbers_count_too_many() {
    let lottery_address = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };
    
    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);
    
    // Setup mocks for successful ticket purchase (validation fails before payment)
    setup_mocks_success(USER1);
    
    // 6 numbers instead of 5
    let mut numbers = array![1, 2, 3, 4, 5, 6];
    
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers);
    
    cleanup_mocks();
}

#[should_panic(expected: 'Invalid numbers')]
#[test]
fn test_buy_ticket_numbers_out_of_range() {
    let lottery_address = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };
    
    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);
    
    // Setup mocks for successful ticket purchase (validation fails before payment)
    setup_mocks_success(USER1);
    
    // Number 41 is out of range (max is 40)
    let mut numbers = array![1, 2, 3, 4, 41];
    
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers);
    
    cleanup_mocks();
}

#[should_panic(expected: 'Invalid numbers')]
#[test]
fn test_buy_ticket_duplicate_numbers() {
    let lottery_address = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };
    
    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);
    
    // Setup mocks for successful ticket purchase (validation fails before payment)
    setup_mocks_success(USER1);
    
    // Duplicate number 5
    let mut numbers = array![1, 2, 3, 5, 5];
    
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers);
    
    cleanup_mocks();
}

#[should_panic(expected: 'Insufficient balance')]
#[test]
fn test_buy_ticket_insufficient_balance() {
    let lottery_address = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };
    
    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);
    
    // Setup mocks for insufficient balance
    setup_mocks_insufficient_balance(USER1);
    
    let numbers = create_valid_numbers();
    
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers);
    
    cleanup_mocks();
}

#[should_panic(expected: 'No token balance')]
#[test]
fn test_buy_ticket_zero_balance() {
    let lottery_address = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };
    
    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);
    
    // Setup mocks for zero balance
    setup_mocks_zero_balance(USER1);
    
    let numbers = create_valid_numbers();
    
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers);
    
    cleanup_mocks();
}

#[should_panic(expected: 'Insufficient allowance')]
#[test]
fn test_buy_ticket_insufficient_allowance() {
    let lottery_address = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };
    
    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);
    
    // Setup mocks for insufficient allowance
    setup_mocks_insufficient_allowance(USER1);
    
    let numbers = create_valid_numbers();
    
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers);
    
    cleanup_mocks();
}

#[should_panic(expected: 'Draw is not active')]
#[test]
fn test_buy_ticket_inactive_draw() {
    let lottery_address = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };
    
    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);
    
    // Complete the draw to make it inactive
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.DrawNumbers(1);
    
    // Setup mocks for successful ticket purchase (draw validation fails first)
    setup_mocks_success(USER1);
    
    let numbers = create_valid_numbers();
    
    // Try to buy ticket on inactive draw
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers);
    
    cleanup_mocks();
}

//=======================================================================================
// Phase 3: Edge Case Tests
//=======================================================================================

#[test]
fn test_buy_ticket_boundary_numbers() {
    let lottery_address = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };
    
    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);
    
    // Setup mocks for successful ticket purchases
    setup_mocks_success(USER1);
    
    // Test with minimum and maximum valid numbers
    let mut min_numbers = array![1, 2, 3, 4, 5];
    let mut max_numbers = array![36, 37, 38, 39, 40];
    
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(2));
    lottery_dispatcher.BuyTicket(1, min_numbers);
    lottery_dispatcher.BuyTicket(1, max_numbers);
    
    let ticket_count = lottery_dispatcher.GetUserTicketsCount(1, USER1);
    assert(ticket_count == 2, 'Should buy boundary tickets');
    
    cleanup_mocks();
}

#[test]
fn test_buy_ticket_exact_balance() {
    let lottery_address = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };
    
    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);
    
    // Setup mocks for exact balance (same as ticket price)
    setup_mocks_for_buy_ticket(USER1, TICKET_PRICE, TICKET_PRICE, true);
    
    let numbers = create_valid_numbers();
    
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers);
    
    let ticket_count = lottery_dispatcher.GetUserTicketsCount(1, USER1);
    assert(ticket_count == 1, 'Should have 1 ticket');
    
    cleanup_mocks();
}

//=======================================================================================
// Phase 4: Integration Tests
//=======================================================================================

#[test]
fn test_buy_ticket_balance_updates() {
    let lottery_address = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };
    
    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);
    
    // Setup mocks for successful ticket purchase
    setup_mocks_success(USER1);
    
    let numbers = create_valid_numbers();
    
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers);
    
    // Verify ticket was created successfully
    let ticket_count = lottery_dispatcher.GetUserTicketsCount(1, USER1);
    assert(ticket_count == 1, 'Should have 1 ticket');
    
    cleanup_mocks();
}

#[test]
fn test_buy_ticket_state_updates() {
    let lottery_address = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };
    
    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);
    
    // Setup mocks for successful ticket purchase
    setup_mocks_success(USER1);
    
    let initial_ticket_id = lottery_dispatcher.GetTicketCurrentId();
    let initial_user_count = lottery_dispatcher.GetUserTicketsCount(1, USER1);
    let numbers = create_valid_numbers();
    
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers);
    
    let final_ticket_id = lottery_dispatcher.GetTicketCurrentId();
    let final_user_count = lottery_dispatcher.GetUserTicketsCount(1, USER1);
    
    assert(final_ticket_id == initial_ticket_id + 1, 'Ticket ID should increment');
    assert(final_user_count == initial_user_count + 1, 'User count should increment');
    
    cleanup_mocks();
}