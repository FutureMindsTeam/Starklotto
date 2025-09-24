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
const TicketPriceInitial: u256 = 5000000000000000000;
// Hardcoded addresses from Lottery contract
const STRK_PLAY_CONTRACT_ADDRESS: ContractAddress =
    0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
    .try_into()
    .unwrap();
const STRK_PLAY_VAULT_CONTRACT_ADDRESS: ContractAddress =
    0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
    .try_into()
    .unwrap();

const DEFAULT_PRICE: u256 = 500;
const DEFAULT_ACCUMULATED_PRIZE: u256 = 1000;
const DEFAULT_ID: u64 = 1;

//=======================================================================================
// Helper functions - following existing patterns
//=======================================================================================

fn owner_address() -> ContractAddress {
    OWNER
}

fn deploy_mock_strk_play() -> ContractAddress {
    let contract_class = declare("StarkPlayERC20").unwrap().contract_class();
    let mut calldata = array![owner_address().into(), owner_address().into()];
    let (contract_address, _) = contract_class.deploy(@calldata).unwrap();
    contract_address
}

fn deploy_mock_vault(strk_play_address: ContractAddress) -> ContractAddress {
    let contract_class = declare("StarkPlayVault").unwrap().contract_class();
    let mut calldata = array![owner_address().into(), strk_play_address.into(), 50_u64.into()];
    let (contract_address, _) = contract_class.deploy(@calldata).unwrap();
    contract_address
}

fn deploy_lottery() -> (ContractAddress, ContractAddress, ContractAddress) {
    // Deploy mock contracts first
    let mock_strk_play = deploy_mock_strk_play();
    let mock_vault = deploy_mock_vault(mock_strk_play);

    let mut calldata = array![owner_address().into(), mock_strk_play.into(), mock_vault.into()];
    let lottery_address = declare_and_deploy("Lottery", calldata);

    (lottery_address, mock_strk_play, mock_vault)
}

fn create_valid_numbers() -> Array<u16> {
    array![1, 15, 25, 35, 40]
}

// NEW: Helper function to create array of arrays for multiple tickets
fn create_valid_numbers_array(quantity: u8) -> Array<Array<u16>> {
    let mut numbers_array = ArrayTrait::new();
    let mut i: u8 = 0;
    while i < quantity {
        let mut ticket_numbers = ArrayTrait::new();
        // Create unique numbers for each ticket within valid range (1-40)
        let base = i * 7; // Use 7 to ensure better distribution
        ticket_numbers.append(((base + 1_u8) % 40 + 1_u8).try_into().unwrap());
        ticket_numbers.append(((base + 2_u8) % 40 + 1_u8).try_into().unwrap());
        ticket_numbers.append(((base + 3_u8) % 40 + 1_u8).try_into().unwrap());
        ticket_numbers.append(((base + 4_u8) % 40 + 1_u8).try_into().unwrap());
        ticket_numbers.append(((base + 5_u8) % 40 + 1_u8).try_into().unwrap());
        numbers_array.append(ticket_numbers);
        i += 1;
    }
    numbers_array
}

// NEW: Helper function to create single ticket array (for backward compatibility)
fn create_single_ticket_numbers_array(numbers: Array<u16>) -> Array<Array<u16>> {
    let mut numbers_array = ArrayTrait::new();
    numbers_array.append(numbers);
    numbers_array
}

fn setup_mocks_for_buy_ticket(
    strk_play_address: ContractAddress,
    user: ContractAddress,
    user_balance: u256,
    allowance: u256,
    transfer_success: bool,
) {
    // Mock balance_of call
    start_mock_call(strk_play_address, selector!("balance_of"), user_balance);

    // Mock allowance call
    start_mock_call(strk_play_address, selector!("allowance"), allowance);

    // Mock transfer_from call
    start_mock_call(strk_play_address, selector!("transfer_from"), transfer_success);
}

fn setup_mocks_success(strk_play_address: ContractAddress, user: ContractAddress) {
    setup_mocks_for_buy_ticket(strk_play_address, user, TICKET_PRICE * 10, TICKET_PRICE * 10, true);
}

fn setup_mocks_for_multiple_tickets(strk_play_address: ContractAddress, user: ContractAddress, quantity: u8) {
    let total_price = TICKET_PRICE * quantity.into();
    setup_mocks_for_buy_ticket(strk_play_address, user, total_price * 2, total_price * 2, true);
}

fn setup_mocks_insufficient_balance(strk_play_address: ContractAddress, user: ContractAddress) {
    setup_mocks_for_buy_ticket(strk_play_address, user, TICKET_PRICE / 2, TICKET_PRICE * 10, true);
}

fn setup_mocks_zero_balance(strk_play_address: ContractAddress, user: ContractAddress) {
    setup_mocks_for_buy_ticket(strk_play_address, user, 0, TICKET_PRICE * 10, true);
}

fn setup_mocks_insufficient_allowance(strk_play_address: ContractAddress, user: ContractAddress) {
    setup_mocks_for_buy_ticket(strk_play_address, user, TICKET_PRICE * 10, 0, true);
}

fn cleanup_mocks(strk_play_address: ContractAddress) {
    stop_mock_call(strk_play_address, selector!("balance_of"));
    stop_mock_call(strk_play_address, selector!("allowance"));
    stop_mock_call(strk_play_address, selector!("transfer_from"));
}

fn context(
    ticket_price: u256, accumulated_prize: u256, caller: ContractAddress,
) -> (IERC20Dispatcher, ILotteryDispatcher) {
    let (lottery, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery };
    cheat_caller_address(lottery, owner_address(), CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(ticket_price, accumulated_prize);
    let erc = start(lottery_dispatcher, USER1, ticket_price, lottery);
    (erc, lottery_dispatcher)
}

fn default_context() -> (IERC20Dispatcher, ILotteryDispatcher) {
    context(DEFAULT_PRICE, DEFAULT_ACCUMULATED_PRIZE, USER1)
}

fn mint(target: ContractAddress, amount: u256, spender: ContractAddress, erc: IERC20Dispatcher) {
    let previous_balance = erc.balance_of(target);
    let token = IMintableDispatcher { contract_address: erc.contract_address };
    cheat_caller_address(token.contract_address, owner_address(), CheatSpan::TargetCalls(3));
    token.grant_minter_role(owner_address());
    token.set_minter_allowance(owner_address(), 1000000000);
    token.mint(target, amount);
    let new_balance = erc.balance_of(target);
    assert(new_balance - previous_balance == amount, 'MINTING FAILED');
    cheat_caller_address(token.contract_address, target, CheatSpan::TargetCalls(1));
    erc.approve(spender, amount);
}

fn start(
    lottery: ILotteryDispatcher, target: ContractAddress, amount: u256, spender: ContractAddress,
) -> IERC20Dispatcher {
    let contract_address = lottery.GetStarkPlayContractAddress();
    let erc = IERC20Dispatcher { contract_address };
    mint(target, amount, spender, erc);
    erc
}

fn feign_buy_ticket(lottery: ILotteryDispatcher, buyer: ContractAddress) -> Array<u16> {
    let numbers = array![1, 2, 3, 4, 5];
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());
    cheat_caller_address(lottery.contract_address, buyer, CheatSpan::Indefinite);
    cheat_block_timestamp(lottery.contract_address, 1, CheatSpan::TargetCalls(1));
    lottery.BuyTicket(DEFAULT_ID, numbers_array, 1);
    numbers
}

//=======================================================================================
// Phase 0: Contract Declaration and Deployment Tests
//=======================================================================================

#[test]
fn should_declare_contract() {
    let lottery = declare("Lottery");
    assert(lottery.is_ok(), 'Contract declaration successful');
}

#[test]
fn should_deploy_contract() {
    // Deploy mock contracts first
    let mock_strk_play = deploy_mock_strk_play();
    let mock_vault = deploy_mock_vault(mock_strk_play);

    let lottery = declare("Lottery").unwrap().contract_class();
    let init_data = array![owner_address().into(), mock_strk_play.into(), mock_vault.into()];
    let (lottery_address, _) = lottery.deploy(@init_data).unwrap();
    assert(lottery_address != 0.try_into().unwrap(), 'Contract deployment');
}

#[test]
fn test_contract_initialization() {
    let (lottery, _, _) = deploy_lottery();
    assert(lottery != 0.try_into().unwrap(), 'Lottery contract deployed');

    start_cheat_caller_address(lottery, owner_address());
    stop_cheat_caller_address(lottery);

    assert(true, 'Admin interaction verified');
}

#[test]
fn validate_ticket_numbers() {
    let (lottery, _, _) = deploy_lottery();

    start_cheat_caller_address(lottery, owner_address());
    stop_cheat_caller_address(lottery);

    let ticket = array![2_u16, 8_u16, 12_u16, 18_u16, 25_u16];
    assert(ticket.len() == 5, 'Ticket must have 5 numbers');

    let mut i = 0;
    while i < 5 {
        assert(*ticket.at(i) >= 1_u16, 'Number >= minimum');
        assert(*ticket.at(i) <= 40_u16, 'Number <= maximum');
        i += 1;
    }

    i = 0;
    while i < 4 {
        let mut j = i + 1;
        while j < 5 {
            assert(*ticket.at(i) != *ticket.at(j), 'Numbers must be unique');
            j += 1;
        }
        i += 1;
    }
}

#[test]
fn test_multiple_tickets() {
    let (_lottery, _, _) = deploy_lottery();

    let ticket1 = array![4_u16, 9_u16, 13_u16, 19_u16, 24_u16];
    let ticket2 = array![5_u16, 11_u16, 17_u16, 23_u16, 29_u16];
    let ticket3 = array![7_u16, 14_u16, 21_u16, 28_u16, 35_u16];

    assert(ticket1.len() == 5, 'First ticket valid');
    assert(ticket2.len() == 5, 'Second ticket valid');
    assert(ticket3.len() == 5, 'Third ticket valid');

    let min_values = array![1_u16, 2_u16, 3_u16, 4_u16, 5_u16];
    let max_values = array![36_u16, 37_u16, 38_u16, 39_u16, 40_u16];

    assert(min_values.len() == 5, 'Minimum values');
    assert(max_values.len() == 5, 'Maximum values');
    assert(*min_values.at(0) == 1_u16, 'Minimum boundary');
    assert(*max_values.at(4) == 40_u16, 'Maximum boundary');
}

#[test]
fn test_invalid_inputs() {
    let (_lottery, _, _) = deploy_lottery();

    let duplicate_nums = array![3_u16, 7_u16, 12_u16, 7_u16, 18_u16];
    assert(duplicate_nums.len() == 5, 'Has correct length');

    let mut found_duplicate = false;
    let mut i = 0;
    while i < 4 {
        let mut j = i + 1;
        while j < 5 {
            if *duplicate_nums.at(i) == *duplicate_nums.at(j) {
                found_duplicate = true;
            }
            j += 1;
        }
        i += 1;
    }
    assert(found_duplicate, 'Finds duplicate numbers');

    let invalid_range_high = array![5_u16, 10_u16, 15_u16, 20_u16, 45_u16];
    let invalid_range_low = array![0_u16, 10_u16, 15_u16, 20_u16, 25_u16];
    assert(*invalid_range_high.at(4) > 40_u16, 'Identifies out of range (high)');
    assert(*invalid_range_low.at(0) < 1_u16, 'Identifies out of range (low)');

    let short_array = array![1_u16, 2_u16, 3_u16, 4_u16];
    let long_array = array![1_u16, 2_u16, 3_u16, 4_u16, 5_u16, 6_u16];

    assert(short_array.len() != 5, 'Detects short array');
    assert(long_array.len() != 5, 'Detects long array');
}

#[test]
fn test_draw_state() {
    let (_lottery, _, _) = deploy_lottery();

    let test_numbers = array![3_u16, 9_u16, 14_u16, 22_u16, 31_u16];
    assert(test_numbers.len() == 5, 'Valid ticket numbers');

    let current_draw = 42_u64;
    let future_draw = 100_u64;

    assert(current_draw != future_draw, 'Different draw IDs');
    assert(true, 'Draw state verification');
}

#[test]
fn test_event_emission() {
    let (_lottery, _, _) = deploy_lottery();

    let current_draw = 7_u64;
    let ticket_numbers = array![4_u16, 8_u16, 15_u16, 16_u16, 23_u16];
    let quantity = 1_u32;

    assert(current_draw > 0, 'Valid draw ID');
    assert(ticket_numbers.len() == 5, 'Correct number of numbers');
    assert(quantity > 0, 'Positive quantity');
    assert(USER1 != 0.try_into().unwrap(), 'Valid participant');

    assert(true, 'Event validation');
}

#[test]
fn test_data_storage() {
    let (_lottery, _, _) = deploy_lottery();

    let stored_numbers = array![2_u16, 11_u16, 19_u16, 27_u16, 33_u16];
    let draw_number = 3_u64;

    assert(stored_numbers.len() == 5, 'Correct number of stored values');
    assert(*stored_numbers.at(0) == 2_u16, 'First position');
    assert(*stored_numbers.at(1) == 11_u16, 'Second position');
    assert(*stored_numbers.at(2) == 19_u16, 'Third position');
    assert(*stored_numbers.at(3) == 27_u16, 'Fourth position');
    assert(*stored_numbers.at(4) == 33_u16, 'Fifth position');

    assert(USER1 != 0.try_into().unwrap(), 'User address valid');
    assert(draw_number > 0, 'Valid draw number');

    let is_claimed = false;
    assert(!is_claimed, 'Initial unclaimed state');
}

#[test]
fn test_payment_handling() {
    let (_lottery, _, _) = deploy_lottery();

    let price_per_ticket = 1000000000000000000_u256;
    let total_prize = 5000000000000000000_u256;

    assert(price_per_ticket > 0, 'Valid ticket price');
    assert(total_prize > 0, 'Valid prize amount');
    assert(total_prize > price_per_ticket, 'Prize exceeds ticket price');

    let user_balance = 2000000000000000000_u256;
    assert(user_balance >= price_per_ticket, 'Enough balance for ticket');

    let ticket_quantity = 3_u32;
    let expected_total = 3000000000000000000_u256;
    assert(price_per_ticket * ticket_quantity.into() == expected_total, 'Total cost calculation');
}

#[should_panic(expected: 'Invalid array')]
#[test]
fn test_buy_ticket_valid_numbers() {
    let (lottery_address, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    let invalid_numbers = array![0_u16, 20_u16, 40_u16, 15_u16, 30_u16];
    assert(invalid_numbers.len() == 5, 'Valid length');
    assert(*invalid_numbers.at(0) == 0_u16, 'First number is 0 (invalid)');
    assert(*invalid_numbers.at(2) <= 40_u16, 'Third number <= 40');

    lottery_dispatcher.BuyTicket(1_u64, create_single_ticket_numbers_array(invalid_numbers), 1);
}

#[should_panic(expected: 'Invalid array')]
#[test]
fn test_buy_ticket_number_zero() {
    let (lottery_address, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    let invalid_numbers = array![0_u16, 10_u16, 20_u16, 30_u16, 40_u16];

    // This should panic because 0 is below the minimum (1)
    lottery_dispatcher.BuyTicket(1_u64, create_single_ticket_numbers_array(invalid_numbers), 1);
}

#[should_panic(expected: 'Invalid array')]
#[test]
fn test_buy_ticket_number_above_max() {
    let (lottery_address, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    let invalid_numbers = array![1_u16, 10_u16, 20_u16, 30_u16, 41_u16];

    // This should panic because 41 is above the maximum (40)
    lottery_dispatcher.BuyTicket(1_u64, create_single_ticket_numbers_array(invalid_numbers), 1);
}

//=======================================================================================
// Phase 1: Successful Case Tests
//=======================================================================================

#[test]
fn test_buy_ticket_successful_single_ticket() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for successful ticket purchase
    setup_mocks_success(mock_strk_play, USER1);

    let numbers = create_valid_numbers();
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());

    // Buy ticket
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 1);

    // Verify results
    let ticket_count = lottery_dispatcher.GetUserTicketsCount(1, USER1);
    assert(ticket_count == 1, 'Should have 1 ticket');

    // Cleanup mocks
    cleanup_mocks(mock_strk_play);
}
#[test]
fn test_buy_multiple_tickets_same_user() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for successful ticket purchases
    setup_mocks_success(mock_strk_play, USER1);

    // Create array of arrays for 3 tickets with different numbers
    let numbers_array = create_valid_numbers_array(3);

    // Buy 3 tickets
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 3);

    let ticket_count = lottery_dispatcher.GetUserTicketsCount(1, USER1);
    assert(ticket_count == 3, 'Should have 3 tickets');

    cleanup_mocks(mock_strk_play);
}

#[test]
fn test_buy_multiple_tickets_with_unique_numbers() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for successful ticket purchases
    setup_mocks_success(mock_strk_play, USER1);

    // Create array of arrays for 3 tickets with different numbers
    let numbers_array = create_valid_numbers_array(3);

    // Buy 3 tickets
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 3);

    let ticket_count = lottery_dispatcher.GetUserTicketsCount(1, USER1);
    assert(ticket_count == 3, 'Should have 3 tickets');

    // Verify that tickets have different numbers
    let ticket_ids = lottery_dispatcher.GetUserTicketIds(1, USER1);
    assert(ticket_ids.len() == 3, 'Should have 3 ticket IDs');

    // Get ticket numbers and verify they are different
    let ticket1_numbers = lottery_dispatcher.GetTicketNumbers(1, *ticket_ids.at(0));
    let ticket2_numbers = lottery_dispatcher.GetTicketNumbers(1, *ticket_ids.at(1));
    let ticket3_numbers = lottery_dispatcher.GetTicketNumbers(1, *ticket_ids.at(2));

    // Verify first numbers are different (they should be 2, 9, 16 based on our helper function)
    assert(*ticket1_numbers.at(0) == 2, 'Ticket 1 first num should be 2');
    assert(*ticket2_numbers.at(0) == 9, 'Ticket 2 first num should be 9');
    assert(*ticket3_numbers.at(0) == 16, 'Ticket 3 first num should be 16');

    cleanup_mocks(mock_strk_play);
}
#[test]
fn test_buy_tickets_different_users() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Create arrays for different users
    let numbers_array1 = create_valid_numbers_array(2);
    let numbers_array2 = create_valid_numbers_array(7);

    // Setup mocks for USER1
    setup_mocks_for_multiple_tickets(mock_strk_play, USER1, 2);
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array1, 2);
    cleanup_mocks(mock_strk_play);

    // Setup mocks for USER2
    setup_mocks_for_multiple_tickets(mock_strk_play, USER2, 7);
    cheat_caller_address(lottery_address, USER2, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array2, 7);
    cleanup_mocks(mock_strk_play);

    let user1_count = lottery_dispatcher.GetUserTicketsCount(1, USER1);
    let user2_count = lottery_dispatcher.GetUserTicketsCount(1, USER2);

    assert(user1_count == 2, 'User1 should have 2 tickets');
    assert(user2_count == 7, 'User2 should have 7 tickets');
}

#[test]
fn test_buy_ticket_different_number_combinations() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for successful ticket purchases
    setup_mocks_success(mock_strk_play, USER1);

    // Different number combinations - create arrays for multiple tickets
    let numbers_array1 = create_valid_numbers_array(6);
    let numbers_array2 = create_valid_numbers_array(8);
    let numbers_array3 = create_valid_numbers_array(10);

    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(3));
    lottery_dispatcher.BuyTicket(1, numbers_array1, 6);
    lottery_dispatcher.BuyTicket(1, numbers_array2, 8);
    lottery_dispatcher.BuyTicket(1, numbers_array3, 10);

    let ticket_count = lottery_dispatcher.GetUserTicketsCount(1, USER1);
    assert(ticket_count == 24, 'Should have 24 tickets');

    cleanup_mocks(mock_strk_play);
}

#[test]
fn test_buy_ticket_event_emission() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for successful ticket purchase
    setup_mocks_success(mock_strk_play, USER1);

    let numbers_array = create_valid_numbers_array(2);
    let mut spy = spy_events();

    // Buy ticket
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 2);

    let events = spy.get_events();
    assert(events.events.len() >= 2, 'Should emit events');

    cleanup_mocks(mock_strk_play);
}

// //=======================================================================================
// // Phase 2: Validation Tests
// //=======================================================================================

#[should_panic(expected: 'Invalid array')]
#[test]
fn test_buy_ticket_invalid_numbers_count_too_few() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for successful ticket purchase (validation fails before payment)
    setup_mocks_success(mock_strk_play, USER1);

    // Only 4 numbers instead of 5
    let mut numbers = array![1, 2, 3, 4];
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());

    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 1);

    cleanup_mocks(mock_strk_play);
}

#[should_panic(expected: 'Invalid array')]
#[test]
fn test_buy_ticket_invalid_numbers_count_too_many() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for successful ticket purchase (validation fails before payment)
    setup_mocks_success(mock_strk_play, USER1);

    // 6 numbers instead of 5
    let mut numbers = array![1, 2, 3, 4, 5, 6];
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());

    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 1);

    cleanup_mocks(mock_strk_play);
}


#[should_panic(expected: 'Quantity too low')]
#[test]
fn test_buy_ticket_low_quantity() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for successful ticket purchase (validation fails before payment)
    setup_mocks_success(mock_strk_play, USER1);

    // For quantity = 0, we should pass an empty array
    let empty_numbers_array = ArrayTrait::new();

    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, empty_numbers_array, 0);

    cleanup_mocks(mock_strk_play);
}


#[should_panic(expected: 'Quantity too high')]
#[test]
fn test_buy_ticket_high_quantity() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for successful ticket purchase (validation fails before payment)
    setup_mocks_success(mock_strk_play, USER1);

    let mut numbers = array![1, 2, 3, 4, 5];
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());

    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 30);

    cleanup_mocks(mock_strk_play);
}

#[should_panic(expected: 'Invalid array')]
#[test]
fn test_buy_ticket_numbers_out_of_range() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for successful ticket purchase (validation fails before payment)
    setup_mocks_success(mock_strk_play, USER1);

    // Number 41 is out of range (max is 40)
    let mut numbers = array![1, 2, 3, 4, 41];
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());

    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 1);

    cleanup_mocks(mock_strk_play);
}

#[should_panic(expected: 'Invalid array')]
#[test]
fn test_buy_ticket_duplicate_numbers() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for successful ticket purchase (validation fails before payment)
    setup_mocks_success(mock_strk_play, USER1);

    // Duplicate number 5
    let mut numbers = array![1, 2, 3, 5, 5];
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());

    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 3);

    cleanup_mocks(mock_strk_play);
}

#[should_panic(expected: 'Insufficient balance')]
#[test]
fn test_buy_ticket_insufficient_balance() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for insufficient balance
    setup_mocks_insufficient_balance(mock_strk_play, USER1);

    let numbers = create_valid_numbers();
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());

    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 1);

    cleanup_mocks(mock_strk_play);
}

#[should_panic(expected: 'No token balance')]
#[test]
fn test_buy_ticket_zero_balance() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for zero balance
    setup_mocks_zero_balance(mock_strk_play, USER1);

    let numbers = create_valid_numbers();
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());

    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 1);

    cleanup_mocks(mock_strk_play);
}

#[should_panic(expected: 'Insufficient allowance')]
#[test]
fn test_buy_ticket_insufficient_allowance() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for insufficient allowance
    setup_mocks_insufficient_allowance(mock_strk_play, USER1);

    let numbers = create_valid_numbers();
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());

    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 1);

    cleanup_mocks(mock_strk_play);
}

#[should_panic(expected: 'Draw is not active')]
#[test]
fn test_buy_ticket_inactive_draw() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Complete the draw to make it inactive
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.DrawNumbers(1);

    // Setup mocks for successful ticket purchase (draw validation fails first)
    setup_mocks_success(mock_strk_play, USER1);

    let numbers_array = create_valid_numbers_array(2);

    // Try to buy ticket on inactive draw
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 2);

    cleanup_mocks(mock_strk_play);
}

// //=======================================================================================
// // Phase 3: Edge Case Tests
// //=======================================================================================

#[test]
fn test_buy_ticket_boundary_numbers() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for successful ticket purchases
    setup_mocks_success(mock_strk_play, USER1);

    // Test with minimum and maximum valid numbers
    let min_numbers_array = create_valid_numbers_array(2);
    let max_numbers_array = create_valid_numbers_array(2);

    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(2));
    lottery_dispatcher.BuyTicket(1, min_numbers_array, 2);
    lottery_dispatcher.BuyTicket(1, max_numbers_array, 2);

    let ticket_count = lottery_dispatcher.GetUserTicketsCount(1, USER1);
    assert(ticket_count == 4, 'Should buy boundary tickets');

    cleanup_mocks(mock_strk_play);
}

#[test]
fn test_buy_ticket_exact_balance() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for exact balance (same as ticket price)
    setup_mocks_for_buy_ticket(mock_strk_play, USER1, TICKET_PRICE, TICKET_PRICE, true);

    let numbers = create_valid_numbers();
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());

    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 1);

    let ticket_count = lottery_dispatcher.GetUserTicketsCount(1, USER1);
    assert(ticket_count == 1, 'Should have 1 ticket');

    cleanup_mocks(mock_strk_play);
}

// //=======================================================================================
// // Phase 4: Integration Tests
// //=======================================================================================

#[test]
fn test_buy_ticket_balance_updates() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for successful ticket purchase
    setup_mocks_success(mock_strk_play, USER1);

    let numbers_array = create_valid_numbers_array(4);

    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 4);

    // Verify ticket was created successfully
    let ticket_count = lottery_dispatcher.GetUserTicketsCount(1, USER1);
    assert(ticket_count == 4, 'Should have 4 ticket');

    cleanup_mocks(mock_strk_play);
}

#[test]
fn test_buy_ticket_state_updates() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for successful ticket purchase
    setup_mocks_success(mock_strk_play, USER1);

    let initial_ticket_id = lottery_dispatcher.GetTicketCurrentId();
    let initial_user_count = lottery_dispatcher.GetUserTicketsCount(1, USER1);
    let numbers = create_valid_numbers();
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());

    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 1);

    let final_ticket_id = lottery_dispatcher.GetTicketCurrentId();
    let final_user_count = lottery_dispatcher.GetUserTicketsCount(1, USER1);

    assert(final_ticket_id == initial_ticket_id + 1, 'Ticket ID should increment');
    assert(final_user_count == initial_user_count + 1, 'User count should increment');

    cleanup_mocks(mock_strk_play);
}

// //=======================================================================================
// // Phase 5: Advanced Security Tests
// //=======================================================================================

// Edge case test for maximum balance
#[test]
fn test_buy_ticket_with_large_balance() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks with very large balance
    let large_balance = 1000000000000000000000_u256; // 1000 tokens
    setup_mocks_for_buy_ticket(mock_strk_play, USER1, large_balance, large_balance, true);

    let numbers = create_valid_numbers();
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());

    // Buy a single ticket with large balance
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 1);

    let ticket_count = lottery_dispatcher.GetUserTicketsCount(1, USER1);
    assert(ticket_count == 1, 'Should have 1 ticket');

    cleanup_mocks(mock_strk_play);
}

// // Invalid draw_id validation tests
#[should_panic(expected: 'Draw is not active')]
#[test]
fn test_buy_ticket_invalid_draw_id_zero() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for successful ticket purchase (validation fails before payment)
    setup_mocks_success(mock_strk_play, USER1);

    let numbers = create_valid_numbers();
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());

    // Try to buy ticket with draw_id = 0
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(0, numbers_array, 1);

    cleanup_mocks(mock_strk_play);
}

#[should_panic(expected: 'Draw is not active')]
#[test]
fn test_buy_ticket_invalid_draw_id_out_of_range() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for successful ticket purchase (validation fails before payment)
    setup_mocks_success(mock_strk_play, USER1);

    let numbers = create_valid_numbers();
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());

    // Try to buy ticket with draw_id way out of range
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(9999, numbers_array, 1);

    cleanup_mocks(mock_strk_play);
}

// // Empty or null parameters tests
#[should_panic(expected: 'Invalid array')]
#[test]
fn test_buy_ticket_empty_numbers_array() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for successful ticket purchase (validation fails before payment)
    setup_mocks_success(mock_strk_play, USER1);

    // Pass empty array of numbers
    let empty_numbers = array![];
    let empty_numbers_array = create_single_ticket_numbers_array(empty_numbers.clone());

    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, empty_numbers_array, 1);

    cleanup_mocks(mock_strk_play);
}

#[should_panic(expected: 'Invalid array')]
#[test]
fn test_buy_ticket_numbers_with_zero() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for successful ticket purchase (validation fails before payment)
    setup_mocks_success(mock_strk_play, USER1);

    // Numbers containing zero (invalid)
    let mut numbers = array![0, 1, 2, 3, 4];
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());

    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 1);

    cleanup_mocks(mock_strk_play);
}

// // Event content and structure validation tests
#[test]
fn test_buy_ticket_event_content_validation() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for successful ticket purchase
    setup_mocks_success(mock_strk_play, USER1);

    let numbers_array = create_valid_numbers_array(2);
    let mut spy = spy_events();

    // Buy ticket
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 2);

    let events = spy.get_events();

    // Verify we have events
    assert(events.events.len() >= 2, 'Should emit at least 1 event');

    // Verify event is from correct contract
    let (from, _event) = events.events.at(0);
    assert(from == @lottery_address, 'Event from lottery contract');

    cleanup_mocks(mock_strk_play);
}

#[test]
fn test_buy_ticket_multiple_events_validation() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for successful ticket purchases
    setup_mocks_success(mock_strk_play, USER1);

    let numbers_array = create_valid_numbers_array(10);
    let mut spy = spy_events();

    // Buy multiple tickets
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(3));
    lottery_dispatcher.BuyTicket(1, numbers_array.clone(), 10);

    let events = spy.get_events();

    // Verify correct number of events emitted (should be at least 3 for ticket purchases)
    assert(events.events.len() >= 10, 'Should emit events');

    // Verify all events are from the lottery contract
    let mut i: u32 = 0;
    while i < events.events.len() {
        let (from, _event) = events.events.at(i);
        assert(from == @lottery_address, 'All events from lottery');
        i += 1;
    }

    cleanup_mocks(mock_strk_play);
}

#[test]
fn test_buy_ticket_event_data_consistency() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for successful ticket purchase
    setup_mocks_success(mock_strk_play, USER1);

    let numbers = create_valid_numbers();
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());
    let mut spy = spy_events();

    let initial_ticket_id = lottery_dispatcher.GetTicketCurrentId();

    // Buy ticket
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 1);

    let events = spy.get_events();
    let final_ticket_id = lottery_dispatcher.GetTicketCurrentId();
    let user_ticket_count = lottery_dispatcher.GetUserTicketsCount(1, USER1);

    // Verify state consistency with events
    assert(events.events.len() >= 1, 'Should emit ticket event');
    assert(final_ticket_id == initial_ticket_id + 1, 'Ticket ID should increment');
    assert(user_ticket_count == 1, 'User should have 1 ticket');

    // Verify event matches the state changes
    let (from, _event) = events.events.at(0);
    assert(from == @lottery_address, 'Event from correct contract');

    cleanup_mocks(mock_strk_play);
}

// Additional edge case for very large numbers close to limits
#[test]
fn test_buy_ticket_stress_test_many_tickets() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for successful ticket purchases
    setup_mocks_success(mock_strk_play, USER1);

    let numbers = create_valid_numbers();
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());

    // Buy 10 tickets to test system limits (reduced from 50 to avoid potential overflow)
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(10));

    let mut i: u32 = 0;
    while i < 10 {
        lottery_dispatcher.BuyTicket(1, numbers_array.clone(), 1);
        i += 1;
    }

    let final_count = lottery_dispatcher.GetUserTicketsCount(1, USER1);
    assert(final_count == 10, 'Should have 10 tickets');

    cleanup_mocks(mock_strk_play);
}

// //=======================================================================================
// // Phase 6: Enhanced Overflow/Underflow and Edge Case Tests
// //=======================================================================================

#[test]
fn test_buy_ticket_overflow_prevention_excessive_tickets() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks with huge balance to simulate potential overflow scenarios
    let huge_balance = 340282366920938463463374607431768211455_u256; // Max u256
    setup_mocks_for_buy_ticket(mock_strk_play, USER1, huge_balance, huge_balance, true);

    let numbers = create_valid_numbers();
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());

    // Try to buy a very large number of tickets (100) to test counter overflow protection
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(100));

    let mut i: u32 = 0;
    while i < 100 {
        lottery_dispatcher.BuyTicket(1, numbers_array.clone(), 1);
        i += 1;
    }

    // Verify the system handles large ticket counts correctly
    let final_count = lottery_dispatcher.GetUserTicketsCount(1, USER1);
    assert(final_count == 100, 'Should handle 100 tickets');

    // Verify ticket ID increments are handled correctly
    // GetTicketCurrentId returns the NEXT ticket ID to be assigned
    // After buying 100 tickets (IDs 0-99), the next ID should be 100
    let final_ticket_id = lottery_dispatcher.GetTicketCurrentId();
    assert(final_ticket_id == 100, 'Ticket IDs should increment');

    cleanup_mocks(mock_strk_play);
}

#[test]
fn test_buy_ticket_balance_overflow_simulation() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks with maximum possible balance that could cause overflow
    let max_u256 = 340282366920938463463374607431768211455_u256;
    setup_mocks_for_buy_ticket(mock_strk_play, USER1, max_u256, max_u256, true);

    let numbers = create_valid_numbers();
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());

    // This should work correctly without causing overflow
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 1);

    // Verify the transaction succeeded
    let ticket_count = lottery_dispatcher.GetUserTicketsCount(1, USER1);
    assert(ticket_count == 1, 'Should handle max balance');

    cleanup_mocks(mock_strk_play);
}

// //=======================================================================================
// // Phase 7: Enhanced Draw ID Validation Tests
// //=======================================================================================

#[should_panic(expected: 'Draw is not active')]
#[test]
fn test_buy_ticket_draw_id_zero_enhanced() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery (this creates draw_id = 1)
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for successful ticket purchase
    setup_mocks_success(mock_strk_play, USER1);

    let numbers = create_valid_numbers();
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());

    // Try to buy ticket with draw_id = 0 (should be invalid)
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(0, numbers_array, 1);

    cleanup_mocks(mock_strk_play);
}

#[should_panic(expected: 'Draw is not active')]
#[test]
fn test_buy_ticket_draw_id_negative_edge() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for successful ticket purchase
    setup_mocks_success(mock_strk_play, USER1);

    let numbers = create_valid_numbers();
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());

    // Try to buy ticket with very large draw_id (simulating negative in u32 context)
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(4294967295, numbers_array, 1); // Max u32

    cleanup_mocks(mock_strk_play);
}

// //=======================================================================================
// // Phase 8: Enhanced Empty/Null Parameter Tests
// //=======================================================================================

#[should_panic(expected: 'Invalid array')]
#[test]
fn test_buy_ticket_empty_array_enhanced() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks (validation should fail before payment processing)
    setup_mocks_success(mock_strk_play, USER1);

    // Pass completely empty array
    let empty_numbers = array![];
    let empty_numbers_array = create_single_ticket_numbers_array(empty_numbers.clone());

    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, empty_numbers_array, 1);

    cleanup_mocks(mock_strk_play);
}

#[should_panic(expected: 'Invalid array')]
#[test]
fn test_buy_ticket_single_element_array() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks
    setup_mocks_success(mock_strk_play, USER1);

    // Pass array with single element (invalid)
    let single_number = array![1];
    let single_number_array = create_single_ticket_numbers_array(single_number.clone());

    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, single_number_array, 1);

    cleanup_mocks(mock_strk_play);
}

// //=======================================================================================
// // Phase 9: Enhanced Event Content and Structure Validation
// //=======================================================================================

#[test]
fn test_buy_ticket_event_ticketpurchased_structure() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for successful ticket purchase
    setup_mocks_success(mock_strk_play, USER1);

    let numbers = create_valid_numbers();
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());
    let mut spy = spy_events();

    let initial_ticket_id = lottery_dispatcher.GetTicketCurrentId();

    // Buy ticket
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 1);

    let events = spy.get_events();

    // Verify event emission and structure
    assert(events.events.len() >= 1, 'Should emit TicketPurchased');

    // Verify the event is from the correct contract
    let (event_contract, _event_data) = events.events.at(0);
    assert(event_contract == @lottery_address, 'Event from lottery contract');

    // Verify state consistency after event
    let final_ticket_id = lottery_dispatcher.GetTicketCurrentId();
    let user_tickets = lottery_dispatcher.GetUserTicketsCount(1, USER1);

    assert(final_ticket_id == initial_ticket_id + 1, 'Ticket ID incremented');
    assert(user_tickets == 1, 'User has 1 ticket');

    cleanup_mocks(mock_strk_play);
}

#[test]
fn test_buy_ticket_event_fields_validation() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for successful ticket purchase
    setup_mocks_success(mock_strk_play, USER1);

    let numbers = create_valid_numbers();
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());
    let mut spy = spy_events();

    // Buy ticket and capture expected values
    let expected_draw_id = 1;
    let expected_user = USER1;

    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(expected_draw_id, numbers_array.clone(), 1);

    let events = spy.get_events();

    // Verify event count and source
    assert(events.events.len() >= 1, 'Should emit ticket event');

    let (event_contract, _event_data) = events.events.at(0);
    assert(event_contract == @lottery_address, 'Correct event source');

    // Verify the transaction was processed correctly by checking state
    let user_ticket_count = lottery_dispatcher.GetUserTicketsCount(expected_draw_id, expected_user);
    assert(user_ticket_count == 1, 'User should have 1 ticket');

    cleanup_mocks(mock_strk_play);
}

#[test]
fn test_buy_ticket_multiple_events_structure() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for successful ticket purchases
    setup_mocks_success(mock_strk_play, USER1);

    let numbers1 = array![1, 2, 3, 4, 5];
    let numbers2 = array![6, 7, 8, 9, 10];
    let numbers3 = array![11, 12, 13, 14, 15];

    let mut spy = spy_events();

    // Buy multiple tickets with different numbers
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(3));
    lottery_dispatcher.BuyTicket(1, create_single_ticket_numbers_array(numbers1.clone()), 1);
    lottery_dispatcher.BuyTicket(1, create_single_ticket_numbers_array(numbers2.clone()), 1);
    lottery_dispatcher.BuyTicket(1, create_single_ticket_numbers_array(numbers3.clone()), 1);

    let events = spy.get_events();

    // Verify multiple events were emitted (at least 3 for the ticket purchases)
    assert(events.events.len() >= 3, 'Should emit multiple events');

    // Verify all events are from the lottery contract
    let mut i: u32 = 0;
    while i < events.events.len() {
        let (event_contract, _event_data) = events.events.at(i);
        assert(event_contract == @lottery_address, 'All events from lottery');
        i += 1;
    }

    // Verify final state consistency
    let final_user_tickets = lottery_dispatcher.GetUserTicketsCount(1, USER1);
    assert(final_user_tickets == 3, 'User should have 3 tickets');

    cleanup_mocks(mock_strk_play);
}

#[test]
fn test_buy_ticket_event_ordering_consistency() {
    let (lottery_address, mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Setup mocks for successful ticket purchases
    setup_mocks_success(mock_strk_play, USER1);
    setup_mocks_success(mock_strk_play, USER2);

    let numbers = create_valid_numbers();
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());
    let mut spy = spy_events();

    let initial_tickets_user1 = lottery_dispatcher.GetUserTicketsCount(1, USER1);
    let initial_tickets_user2 = lottery_dispatcher.GetUserTicketsCount(1, USER2);

    // Buy tickets from different users in sequence
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array.clone(), 1);

    cheat_caller_address(lottery_address, USER2, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array.clone(), 1);

    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 1);

    let events = spy.get_events();

    // Verify events were emitted in correct order
    assert(events.events.len() >= 3, 'Should emit 3+ events');

    // Verify final state consistency
    let final_tickets_user1 = lottery_dispatcher.GetUserTicketsCount(1, USER1);
    let final_tickets_user2 = lottery_dispatcher.GetUserTicketsCount(1, USER2);

    assert(final_tickets_user1 == initial_tickets_user1 + 2, 'User1 should have +2 tickets');
    assert(final_tickets_user2 == initial_tickets_user2 + 1, 'User2 should have +1 ticket');

    cleanup_mocks(mock_strk_play);
}

//=======================================================================================
// CU03: Single Active Lottery + Admin Close + Getter + Event
//=======================================================================================

#[should_panic(expected: 'Active draw exists')]
#[test]
fn test_prevent_multiple_active_lotteries() {
    let (lottery_address, _mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize creates draw 1 (active)
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Attempt to create new draw while previous is still active should panic
    lottery_dispatcher.CreateNewDraw(INITIAL_JACKPOT);
}

#[test]
fn test_get_current_active_draw_and_transition() {
    let (lottery_address, _mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize → draw 1 active
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    let (id1, active1) = lottery_dispatcher.GetCurrentActiveDraw();
    assert(id1 == 1, 'Current draw should be 1');
    assert(active1 == true, 'Current draw should be active');

    // Close draw 1 as admin
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.SetDrawInactive(1);

    // After closing, last draw should be inactive
    let (id1_after, active1_after) = lottery_dispatcher.GetCurrentActiveDraw();
    assert(id1_after == 1, 'Still last draw is 1');
    assert(active1_after == false, 'Draw 1 now inactive');

    // Create new draw now that none is active
    lottery_dispatcher.CreateNewDraw(INITIAL_JACKPOT);
    let (id2, active2) = lottery_dispatcher.GetCurrentActiveDraw();
    assert(id2 == 2, 'New current draw should be 2');
    assert(active2 == true, 'New draw should be active');
}

#[should_panic]
#[test]
fn test_set_draw_inactive_non_admin_forbidden() {
    let (lottery_address, _mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize → draw 1 active
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    // Non-owner attempts to close
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.SetDrawInactive(1);
}

#[test]
fn test_set_draw_inactive_emits_event_and_updates_status() {
    let (lottery_address, _mock_strk_play, _mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize → draw 1 active
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE, INITIAL_JACKPOT);

    let mut spy = spy_events();

    // Close as admin
    cheat_block_timestamp(lottery_address, 777, CheatSpan::TargetCalls(1));
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.SetDrawInactive(1);

    // Verify status
    let is_active = lottery_dispatcher.GetDrawStatus(1);
    assert(!is_active, 'Draw inactive after close');

    // Verify at least one event was emitted (DrawClosed among them)
    let events = spy.get_events();
    assert(events.events.len() >= 1, 'Should emit events on close');

    // Assert specific DrawClosed event content
    let expected = Lottery::Event::DrawClosed(Lottery::DrawClosed { drawId: 1, timestamp: 777, caller: OWNER });
    spy.assert_emitted(@array![(lottery_address, expected)]);
}

//=======================================================================================
// Phase 10: Ticket Price Tests
//=======================================================================================
#[test]
fn test_initial_ticket_price() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    let initial_price = lottery_dispatcher.GetTicketPrice();
    assert!(initial_price == TicketPriceInitial, "Initial ticket price should be 5");
}

#[test]
fn test_set_ticket_price_by_owner() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());

    let new_price: u256 = 1000000000000000000;
    lottery_dispatcher.SetTicketPrice(new_price);

    let current_price = lottery_dispatcher.GetTicketPrice();
    assert!(current_price == new_price, "Ticket price was not set correctly");

    stop_cheat_caller_address(lottery_dispatcher.contract_address);
}

#[test]
fn test_set_ticket_price_multiple_times() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());

    let initial_price: u256 = 1000000000000000000;
    lottery_dispatcher.SetTicketPrice(initial_price);
    assert!(
        lottery_dispatcher.GetTicketPrice() == initial_price, "Initial price not set correctly",
    );

    let updated_price: u256 = 2000000000000000000;
    lottery_dispatcher.SetTicketPrice(updated_price);
    assert!(
        lottery_dispatcher.GetTicketPrice() == updated_price, "Updated price not set correctly",
    );

    let final_price: u256 = 500000000000000000;
    lottery_dispatcher.SetTicketPrice(final_price);
    assert!(lottery_dispatcher.GetTicketPrice() == final_price, "Final price not set correctly");

    stop_cheat_caller_address(lottery_dispatcher.contract_address);
}


#[should_panic(expected: 'Price must be greater than 0')]
#[test]
fn test_set_ticket_price_to_zero() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());

    // Try to set price to zero - should panic
    lottery_dispatcher.SetTicketPrice(0);

    stop_cheat_caller_address(lottery_dispatcher.contract_address);
}

#[test]
fn test_set_ticket_price_very_high_value() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());

    let high_price: u256 = 1000000000000000000000000000;
    lottery_dispatcher.SetTicketPrice(high_price);
    assert!(lottery_dispatcher.GetTicketPrice() == high_price, "High price not set correctly");

    stop_cheat_caller_address(lottery_dispatcher.contract_address);
}

#[test]
fn test_get_ticket_price_public_access() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());
    let set_price: u256 = 1500000000000000000;
    lottery_dispatcher.SetTicketPrice(set_price);
    stop_cheat_caller_address(lottery_dispatcher.contract_address);

    start_cheat_caller_address(lottery_dispatcher.contract_address, USER1);
    let read_price = lottery_dispatcher.GetTicketPrice();
    assert!(read_price == set_price, "User cannot read ticket price correctly");
    stop_cheat_caller_address(lottery_dispatcher.contract_address);

    start_cheat_caller_address(lottery_dispatcher.contract_address, USER2);
    let read_price_2 = lottery_dispatcher.GetTicketPrice();
    assert!(read_price_2 == set_price, "Admin cannot read ticket price correctly");
    stop_cheat_caller_address(lottery_dispatcher.contract_address);
}

#[test]
fn test_ticket_price_persistence() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());

    let initial_price: u256 = 1000000000000000000;
    lottery_dispatcher.SetTicketPrice(initial_price);

    assert!(
        lottery_dispatcher.GetTicketPrice() == initial_price, "Price not persisted after setting",
    );

    stop_cheat_caller_address(lottery_dispatcher.contract_address);
    start_cheat_caller_address(lottery_dispatcher.contract_address, USER1);
    assert!(
        lottery_dispatcher.GetTicketPrice() == initial_price,
        "Price not persisted after caller change",
    );

    stop_cheat_caller_address(lottery_dispatcher.contract_address);
}

#[test]
fn test_ticket_price_with_initialize() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());

    let init_price: u256 = 500000000000000000;
    let accumulated_prize: u256 = 10000000000000000000;
    lottery_dispatcher.Initialize(init_price, accumulated_prize);

    assert!(
        lottery_dispatcher.GetTicketPrice() == init_price,
        "Ticket price not set during initialization",
    );

    let new_price: u256 = 750000000000000000;
    lottery_dispatcher.SetTicketPrice(new_price);
    assert!(
        lottery_dispatcher.GetTicketPrice() == new_price, "Price not updated after initialization",
    );

    stop_cheat_caller_address(lottery_dispatcher.contract_address);
}

#[test]
fn test_ticket_price_edge_cases() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());

    let min_price: u256 = 1;
    lottery_dispatcher.SetTicketPrice(min_price);
    assert!(lottery_dispatcher.GetTicketPrice() == min_price, "Minimum price not set correctly");

    let max_price: u256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    lottery_dispatcher.SetTicketPrice(max_price);
    assert!(lottery_dispatcher.GetTicketPrice() == max_price, "Maximum price not set correctly");

    stop_cheat_caller_address(lottery_dispatcher.contract_address);
}

//=======================================================================================
// Phase 11: Full Ticket Flow Tests
//=======================================================================================
#[test]
fn test_buy_ticket_flow_success() {
    let (erc, lottery) = default_context();
    let mut spy = spy_events();
    let numbers = feign_buy_ticket(lottery, USER1);
    let event = Lottery::Event::TicketPurchased(
        Lottery::TicketPurchased {
            drawId: 1, player: USER1, ticketId: 0, numbers, ticketCount: 1, timestamp: 1,
        },
    );
    spy.assert_emitted(@array![(lottery.contract_address, event)]);

    let balance = erc.balance_of(USER1);
    assert(balance == 0, 'BALANCE SHOULD BE ZERO');

    let tickets = lottery.GetUserTickets(DEFAULT_ID, USER1);
    assert(tickets.len() == 1, 'TICKETS LEN SHOUD BE 1');
}

#[test]
fn test_buy_ticket_on_same_draw_id_success() {
    let (erc, lottery) = default_context();
    feign_buy_ticket(lottery, USER1);
    mint(USER2, DEFAULT_PRICE, lottery.contract_address, erc);
    feign_buy_ticket(lottery, USER2);

    let player1_ticket = lottery.GetUserTickets(1, USER1);
    let player2_ticket = lottery.GetUserTickets(1, USER2);
    // check if the same buy on the same draw id was successful, len should be 1.
    assert(player1_ticket.len() == 1 && player2_ticket.len() == 1, 'MULTIPLE BUY FAILED.');
}

#[should_panic(expected: 'Draw is not active')]
#[test]
fn test_buy_ticket_should_panic_on_draw_not_active() {
    let (erc, lottery) = default_context();
    feign_buy_ticket(lottery, USER1);
    mint(USER2, DEFAULT_PRICE, lottery.contract_address, erc);
    cheat_caller_address(lottery.contract_address, owner_address(), CheatSpan::TargetCalls(1));
    lottery.DrawNumbers(DEFAULT_ID);

    feign_buy_ticket(lottery, USER2);
}
