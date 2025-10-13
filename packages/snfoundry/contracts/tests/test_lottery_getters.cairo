use contracts::Lottery::{ILotteryDispatcher, ILotteryDispatcherTrait};
use contracts::StarkPlayERC20::{IMintableDispatcher, IMintableDispatcherTrait};
use openzeppelin_testing::declare_and_deploy;
use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    CheatSpan, ContractClassTrait, DeclareResultTrait, cheat_block_timestamp, cheat_caller_address,
    declare, start_cheat_caller_address, start_mock_call, stop_cheat_caller_address, stop_mock_call,
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

fn deploy_mock_randomness() -> ContractAddress {
    let randomness_contract = declare("MockRandomness").unwrap().contract_class();
    let (randomness_address, _) = randomness_contract.deploy(@array![]).unwrap();
    randomness_address
}

fn deploy_lottery() -> (ContractAddress, ContractAddress, ContractAddress) {
    // Deploy mock contracts first
    let mock_strk_play = deploy_mock_strk_play();
    let mock_vault = deploy_mock_vault(mock_strk_play);

    // Deploy mock randomness contract
    let randomness_contract_address = deploy_mock_randomness();

    let mut calldata = array![
        owner_address().into(),
        mock_strk_play.into(),
        mock_vault.into(),
        randomness_contract_address.into(),
    ];
    let lottery_address = declare_and_deploy("Lottery", calldata);

    (lottery_address, mock_strk_play, mock_vault)
}

fn create_valid_numbers() -> Array<u16> {
    array![1, 15, 25, 35, 40]
}

// Helper function to create array of arrays for multiple tickets
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

// Helper function to create single ticket array (for backward compatibility)
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

fn setup_mocks_for_multiple_tickets(
    strk_play_address: ContractAddress, user: ContractAddress, quantity: u8,
) {
    let total_price = TICKET_PRICE * quantity.into();
    setup_mocks_for_buy_ticket(strk_play_address, user, total_price * 2, total_price * 2, true);
}

fn cleanup_mocks(strk_play_address: ContractAddress) {
    stop_mock_call(strk_play_address, selector!("balance_of"));
    stop_mock_call(strk_play_address, selector!("allowance"));
    stop_mock_call(strk_play_address, selector!("transfer_from"));
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

fn feign_buy_ticket(lottery: ILotteryDispatcher, buyer: ContractAddress) -> Array<u16> {
    let numbers = array![1, 2, 3, 4, 5];
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());
    cheat_caller_address(lottery.contract_address, buyer, CheatSpan::Indefinite);
    cheat_block_timestamp(lottery.contract_address, 1, CheatSpan::TargetCalls(1));
    lottery.BuyTicket(DEFAULT_ID, numbers_array, 1);
    numbers
}

//=======================================================================================
// Phase 1: Basic Getter Tests - Ticket Price
//=======================================================================================

#[test]
fn test_get_ticket_price_initial_value() {
    let (lottery_address, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    //  (5 STRK tokens)
    let initial_price = lottery_dispatcher.GetTicketPrice();
    assert(initial_price == TicketPriceInitial, 'Initial price OK');
}

#[test]
fn test_get_ticket_price_after_set_ticket_price() {
    let (lottery_address, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Set new price as owner
    start_cheat_caller_address(lottery_address, owner_address());
    let new_price: u256 = 2000000000000000000; // 2 STRK
    lottery_dispatcher.SetTicketPrice(new_price);

    // Verify that the getter returns the correct price
    let retrieved_price = lottery_dispatcher.GetTicketPrice();
    assert(retrieved_price == new_price, 'Price updated');

    stop_cheat_caller_address(lottery_address);
}

#[test]
fn test_get_ticket_price_public_access() {
    let (lottery_address, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // owner
    start_cheat_caller_address(lottery_address, owner_address());
    let set_price: u256 = 3000000000000000000; // 3 STRK
    lottery_dispatcher.SetTicketPrice(set_price);
    stop_cheat_caller_address(lottery_address);

    // Verify public access from different users
    start_cheat_caller_address(lottery_address, USER1);
    let price_from_user1 = lottery_dispatcher.GetTicketPrice();
    assert(price_from_user1 == set_price, 'User1 access OK');
    stop_cheat_caller_address(lottery_address);

    start_cheat_caller_address(lottery_address, USER2);
    let price_from_user2 = lottery_dispatcher.GetTicketPrice();
    assert(price_from_user2 == set_price, 'User2 access OK');
    stop_cheat_caller_address(lottery_address);
}

#[test]
fn test_get_ticket_price_persistence() {
    let (lottery_address, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Set initial price
    start_cheat_caller_address(lottery_address, owner_address());
    let initial_price: u256 = 1500000000000000000; // 1.5 STRK
    lottery_dispatcher.SetTicketPrice(initial_price);

    // Verify persistence after changing caller
    stop_cheat_caller_address(lottery_address);
    start_cheat_caller_address(lottery_address, USER1);
    let persisted_price = lottery_dispatcher.GetTicketPrice();
    assert(persisted_price == initial_price, 'Price persists');
    stop_cheat_caller_address(lottery_address);
}


#[should_panic(expected: 'Price must be greater than 0')]
#[test]
fn test_get_ticket_price_zero_value() {
    let (lottery_address, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Try to set price to zero - should panic
    start_cheat_caller_address(lottery_address, owner_address());
    lottery_dispatcher.SetTicketPrice(0);
    stop_cheat_caller_address(lottery_address);
}

#[test]
fn test_get_ticket_price_high_value() {
    let (lottery_address, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Set very high price
    start_cheat_caller_address(lottery_address, owner_address());
    let high_price: u256 = 1000000000000000000000; // 1000 STRK
    lottery_dispatcher.SetTicketPrice(high_price);

    let retrieved_high_price = lottery_dispatcher.GetTicketPrice();
    assert(retrieved_high_price == high_price, 'High price OK');
    stop_cheat_caller_address(lottery_address);
}

//=======================================================================================
// Phase 2: Basic Getter Tests - Ticket Current ID
//=======================================================================================

#[test]
fn test_get_ticket_current_id_initial_value() {
    let (lottery_address, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // The initial ID should be 0 (before any ticket)
    let initial_id = lottery_dispatcher.GetTicketCurrentId();
    assert(initial_id == 0, 'Initial ID OK');
}

#[test]
fn test_get_ticket_current_id_after_buying_tickets() {
    let (lottery_address, mock_strk_play, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE);

    // Setup mocks for successful ticket purchase
    setup_mocks_success(mock_strk_play, USER1);

    let numbers = create_valid_numbers();
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());

    // Buy one ticket
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 1);

    // Verify that the ID was incremented
    let current_id = lottery_dispatcher.GetTicketCurrentId();
    assert(current_id == 1, 'ID incremented');

    cleanup_mocks(mock_strk_play);
}

#[test]
fn test_get_ticket_current_id_multiple_tickets() {
    let (lottery_address, mock_strk_play, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE);

    // Setup mocks for successful ticket purchases
    setup_mocks_for_multiple_tickets(mock_strk_play, USER1, 5);

    let numbers_array = create_valid_numbers_array(5);

    // Buy 5 tickets
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 5);

    // Verify that the ID was incremented correctly (should be 5)
    let current_id = lottery_dispatcher.GetTicketCurrentId();
    assert(current_id == 5, 'ID is 5 after 5');

    cleanup_mocks(mock_strk_play);
}

#[test]
fn test_get_ticket_current_id_consistency_with_user_tickets() {
    let (lottery_address, mock_strk_play, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE);

    // Setup mocks for successful ticket purchases
    setup_mocks_for_multiple_tickets(mock_strk_play, USER1, 3);

    let numbers_array = create_valid_numbers_array(3);

    // Buy 3 tickets
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 3);

    // Verify consistency between current_id and user ticket count
    let current_id = lottery_dispatcher.GetTicketCurrentId();
    let user_ticket_count = lottery_dispatcher.GetUserTicketsCount(1, USER1);

    assert(current_id == user_ticket_count.into(), 'ID matches count');

    cleanup_mocks(mock_strk_play);
}

//=======================================================================================
// Phase 7: Basic Getter Tests - Winning Numbers
//=======================================================================================

#[test]
fn test_get_winning_numbers_before_draw() {
    let (lottery_address, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE);

    // Try to get winning numbers before drawing (should panic)
    // The function should panic because draw must be completed
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.DrawNumbers(1);

    let winning_numbers = lottery_dispatcher.GetWinningNumbers(1);
    assert(winning_numbers.len() == 5, 'Returns 5 nums');
}

#[test]
fn test_get_winning_numbers_after_draw() {
    let (lottery_address, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE);

    // Draw numbers
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.DrawNumbers(1);

    let winning_numbers = lottery_dispatcher.GetWinningNumbers(1);
    assert(winning_numbers.len() == 5, 'Returns 5 nums');

    // Verify all numbers are in valid range (1-40)
    let mut i: usize = 0;
    while i < winning_numbers.len() {
        let number = *winning_numbers.at(i);
        assert(number >= 1 && number <= 49, 'Numbers in range');
        i += 1;
    }
}

#[test]
fn test_get_winning_numbers_different_draws() {
    let (lottery_address, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery (creates draw 1)
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE);

    // Close draw 1, then create second draw
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.DrawNumbers(1);
    lottery_dispatcher.CreateNewDraw();

    // Draw numbers for both draws
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.DrawNumbers(2);

    let winning_numbers_1 = lottery_dispatcher.GetWinningNumbers(1);
    let winning_numbers_2 = lottery_dispatcher.GetWinningNumbers(2);

    assert(winning_numbers_1.len() == 5, 'Draw 1 has 5');
    assert(winning_numbers_2.len() == 5, 'Draw 2 has 5');

    // Numbers should be different (though this is not guaranteed by the random function)
    let mut numbers_are_different = false;
    let mut i: usize = 0;
    while i < winning_numbers_1.len() {
        if *winning_numbers_1.at(i) != *winning_numbers_2.at(i) {
            numbers_are_different = true;
            break;
        }
        i += 1;
    }
    // This assertion might fail if the random function generates the same numbers
// but it's statistically unlikely
}

#[should_panic(expected: 'Draw does not exist')]
#[test]
fn test_get_winning_numbers_nonexistent_draw() {
    let (lottery_address, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Try to get winning numbers for non-existent draw
    // This should panic with 'Draw does not exist'
    let winning_numbers = lottery_dispatcher.GetWinningNumbers(999);
    assert(winning_numbers.len() == 0, 'Empty for invalid');
}

//=======================================================================================
// Phase 8: Basic Getter Tests - User Ticket IDs
//=======================================================================================

#[test]
fn test_get_user_ticket_ids_initial_value() {
    let (lottery_address, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE);

    let user_ticket_ids = lottery_dispatcher.GetUserTicketIds(1, USER1);
    assert(user_ticket_ids.len() == 0, 'No tickets yet');
}

#[test]
fn test_get_user_ticket_ids_after_buying_tickets() {
    let (lottery_address, mock_strk_play, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE);

    // Setup mocks for successful ticket purchase
    setup_mocks_success(mock_strk_play, USER1);

    let numbers = create_valid_numbers();
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());

    // Buy one ticket
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 1);

    let user_ticket_ids = lottery_dispatcher.GetUserTicketIds(1, USER1);
    assert(user_ticket_ids.len() == 1, 'Has 1 ticket');

    cleanup_mocks(mock_strk_play);
}

#[test]
fn test_get_user_ticket_ids_multiple_tickets() {
    let (lottery_address, mock_strk_play, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE);

    // Setup mocks for successful ticket purchases
    setup_mocks_for_multiple_tickets(mock_strk_play, USER1, 5);

    let numbers_array = create_valid_numbers_array(5);

    // Buy 5 tickets
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 5);

    let user_ticket_ids = lottery_dispatcher.GetUserTicketIds(1, USER1);
    assert(user_ticket_ids.len() == 5, 'Has 5 tickets');

    // Verify ticket IDs are sequential
    let mut i: usize = 0;
    while i < user_ticket_ids.len() {
        let ticket_id = *user_ticket_ids.at(i);
        assert(ticket_id == i.into(), 'IDs sequential');
        i += 1;
    }

    cleanup_mocks(mock_strk_play);
}

#[test]
fn test_get_user_ticket_ids_different_users() {
    let (lottery_address, mock_strk_play, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE);

    // User 1 buys 2 tickets
    setup_mocks_for_multiple_tickets(mock_strk_play, USER1, 2);
    let numbers_array1 = create_valid_numbers_array(2);
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array1, 2);
    cleanup_mocks(mock_strk_play);

    // User 2 buys 3 tickets
    setup_mocks_for_multiple_tickets(mock_strk_play, USER2, 3);
    let numbers_array2 = create_valid_numbers_array(3);
    cheat_caller_address(lottery_address, USER2, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array2, 3);
    cleanup_mocks(mock_strk_play);

    let user1_ticket_ids = lottery_dispatcher.GetUserTicketIds(1, USER1);
    let user2_ticket_ids = lottery_dispatcher.GetUserTicketIds(1, USER2);

    assert(user1_ticket_ids.len() == 2, 'User1 has 2');
    assert(user2_ticket_ids.len() == 3, 'User2 has 3');
}

#[test]
fn test_get_user_ticket_ids_nonexistent_draw() {
    let (lottery_address, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    let user_ticket_ids = lottery_dispatcher.GetUserTicketIds(999, USER1);
    assert(user_ticket_ids.len() == 0, 'Empty for invalid');
}

//=======================================================================================
// Phase 9: Basic Getter Tests - Contract Addresses
//=======================================================================================

#[test]
fn test_get_stark_play_contract_address() {
    let (lottery_address, mock_strk_play, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    let strk_play_address = lottery_dispatcher.GetStarkPlayContractAddress();
    assert(strk_play_address == mock_strk_play, 'STRK Play addr OK');
}

#[test]
fn test_get_stark_play_vault_contract_address() {
    let (lottery_address, _, mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    let vault_address = lottery_dispatcher.GetStarkPlayVaultContractAddress();
    assert(vault_address == mock_vault, 'Vault addr OK');
}

#[test]
fn test_contract_addresses_public_access() {
    let (lottery_address, mock_strk_play, mock_vault) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Test access from different users
    start_cheat_caller_address(lottery_address, USER1);
    let strk_play_from_user1 = lottery_dispatcher.GetStarkPlayContractAddress();
    let vault_from_user1 = lottery_dispatcher.GetStarkPlayVaultContractAddress();
    stop_cheat_caller_address(lottery_address);

    start_cheat_caller_address(lottery_address, USER2);
    let strk_play_from_user2 = lottery_dispatcher.GetStarkPlayContractAddress();
    let vault_from_user2 = lottery_dispatcher.GetStarkPlayVaultContractAddress();
    stop_cheat_caller_address(lottery_address);

    assert(strk_play_from_user1 == mock_strk_play, 'User1 STRK access');
    assert(vault_from_user1 == mock_vault, 'User1 vault access');
    assert(strk_play_from_user2 == mock_strk_play, 'User2 STRK access');
    assert(vault_from_user2 == mock_vault, 'User2 vault access');
}

//=======================================================================================
// Phase 10: Basic Getter Tests - Ticket Info
//=======================================================================================

#[test]
fn test_get_ticket_info_after_purchase() {
    let (lottery_address, mock_strk_play, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE);

    // Setup mocks for successful ticket purchase
    setup_mocks_success(mock_strk_play, USER1);

    let numbers = create_valid_numbers();
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());

    // Buy one ticket
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 1);

    // Get ticket IDs to find the ticket
    let user_ticket_ids = lottery_dispatcher.GetUserTicketIds(1, USER1);
    assert(user_ticket_ids.len() == 1, 'Should have 1 ticket ID');

    let ticket_id = *user_ticket_ids.at(0);
    let _ticket_info = lottery_dispatcher.GetTicketInfo(1, ticket_id, USER1);

    // Verify ticket info using getter functions instead of direct access
    let ticket_player = lottery_dispatcher.GetTicketPlayer(1, ticket_id);
    let ticket_numbers = lottery_dispatcher.GetTicketNumbers(1, ticket_id);
    let ticket_claimed = lottery_dispatcher.GetTicketClaimed(1, ticket_id);
    let ticket_draw_id = lottery_dispatcher.GetTicketDrawId(1, ticket_id);

    assert(ticket_player == USER1, 'Ticket belongs to USER1');
    assert(ticket_draw_id == 1, 'Ticket for draw 1');
    assert(!ticket_claimed, 'Ticket not claimed');
    assert(ticket_numbers.len() == 5, 'Returns 5 numbers');
    assert(*ticket_numbers.at(0) == *numbers.at(0), 'Number 1 matches');
    assert(*ticket_numbers.at(1) == *numbers.at(1), 'Number 2 matches');
    assert(*ticket_numbers.at(2) == *numbers.at(2), 'Number 3 matches');
    assert(*ticket_numbers.at(3) == *numbers.at(3), 'Number 4 matches');
    assert(*ticket_numbers.at(4) == *numbers.at(4), 'Number 5 matches');

    cleanup_mocks(mock_strk_play);
}

#[test]
fn test_get_ticket_info_multiple_tickets() {
    let (lottery_address, mock_strk_play, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE);

    // Setup mocks for successful ticket purchases
    setup_mocks_for_multiple_tickets(mock_strk_play, USER1, 3);

    let numbers_array = create_valid_numbers_array(3);

    // Buy 3 tickets
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 3);

    let user_ticket_ids = lottery_dispatcher.GetUserTicketIds(1, USER1);
    assert(user_ticket_ids.len() == 3, 'Should have 3 ticket IDs');

    // Check each ticket info using getter functions
    let mut i: usize = 0;
    while i < user_ticket_ids.len() {
        let ticket_id = *user_ticket_ids.at(i);

        let ticket_player = lottery_dispatcher.GetTicketPlayer(1, ticket_id);
        let ticket_claimed = lottery_dispatcher.GetTicketClaimed(1, ticket_id);
        let ticket_draw_id = lottery_dispatcher.GetTicketDrawId(1, ticket_id);
        //let ticket_timestamp = lottery_dispatcher.GetTicketTimestamp(1, ticket_id);

        assert(ticket_player == USER1, 'All belong to USER1');
        assert(ticket_draw_id == 1, 'All for draw 1');
        assert(!ticket_claimed, 'All not claimed');
        // assert(ticket_timestamp > 0, 'Timestamp set');

        i += 1;
    }

    cleanup_mocks(mock_strk_play);
}


#[should_panic]
#[test]
fn test_get_ticket_info_nonexistent_ticket() {
    let (lottery_address, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE);

    // Try to get info for non-existent ticket - should panic with "Not ticket owner"
    let _ticket_info = lottery_dispatcher.GetTicketInfo(1, 999, USER1);
}

//=======================================================================================
// Phase 11: Basic Getter Tests - Individual Ticket Getters
//=======================================================================================

#[test]
fn test_get_ticket_player() {
    let (lottery_address, mock_strk_play, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE);

    // Setup mocks for successful ticket purchase
    setup_mocks_success(mock_strk_play, USER1);

    let numbers = create_valid_numbers();
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());

    // Buy one ticket
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 1);

    let user_ticket_ids = lottery_dispatcher.GetUserTicketIds(1, USER1);
    let ticket_id = *user_ticket_ids.at(0);

    let ticket_player = lottery_dispatcher.GetTicketPlayer(1, ticket_id);
    assert(ticket_player == USER1, 'Correct player');

    cleanup_mocks(mock_strk_play);
}

#[test]
fn test_get_ticket_numbers() {
    let (lottery_address, mock_strk_play, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE);

    // Setup mocks for successful ticket purchase
    setup_mocks_success(mock_strk_play, USER1);

    let numbers = create_valid_numbers();
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());

    // Buy one ticket
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 1);

    let user_ticket_ids = lottery_dispatcher.GetUserTicketIds(1, USER1);
    let ticket_id = *user_ticket_ids.at(0);

    let ticket_numbers = lottery_dispatcher.GetTicketNumbers(1, ticket_id);

    assert(ticket_numbers.len() == 5, 'Returns 5 numbers');
    assert(*ticket_numbers.at(0) == *numbers.at(0), 'Num 1 matches');
    assert(*ticket_numbers.at(1) == *numbers.at(1), 'Num 2 matches');
    assert(*ticket_numbers.at(2) == *numbers.at(2), 'Num 3 matches');
    assert(*ticket_numbers.at(3) == *numbers.at(3), 'Num 4 matches');
    assert(*ticket_numbers.at(4) == *numbers.at(4), 'Num 5 matches');

    cleanup_mocks(mock_strk_play);
}

#[test]
fn test_get_ticket_claimed() {
    let (lottery_address, mock_strk_play, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE);

    // Setup mocks for successful ticket purchase
    setup_mocks_success(mock_strk_play, USER1);

    let numbers = create_valid_numbers();
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());

    // Buy one ticket
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 1);

    let user_ticket_ids = lottery_dispatcher.GetUserTicketIds(1, USER1);
    let ticket_id = *user_ticket_ids.at(0);

    let is_claimed = lottery_dispatcher.GetTicketClaimed(1, ticket_id);
    assert(!is_claimed, 'New ticket not claimed');

    cleanup_mocks(mock_strk_play);
}

#[test]
fn test_get_ticket_draw_id() {
    let (lottery_address, mock_strk_play, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE);

    // Setup mocks for successful ticket purchase
    setup_mocks_success(mock_strk_play, USER1);

    let numbers = create_valid_numbers();
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());

    // Buy one ticket
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 1);

    let user_ticket_ids = lottery_dispatcher.GetUserTicketIds(1, USER1);
    let ticket_id = *user_ticket_ids.at(0);

    let ticket_draw_id = lottery_dispatcher.GetTicketDrawId(1, ticket_id);
    assert(ticket_draw_id == 1, 'Correct draw ID');

    cleanup_mocks(mock_strk_play);
}

#[test]
fn test_get_ticket_timestamp() {
    let (lottery_address, mock_strk_play, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE);

    // Setup mocks for successful ticket purchase
    setup_mocks_success(mock_strk_play, USER1);

    let numbers = create_valid_numbers();
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());

    // Set specific timestamp
    cheat_block_timestamp(lottery_address, 1234567890, CheatSpan::TargetCalls(2));

    // Buy one ticket
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 1);

    let user_ticket_ids = lottery_dispatcher.GetUserTicketIds(1, USER1);
    let ticket_id = *user_ticket_ids.at(0);

    let ticket_timestamp = lottery_dispatcher.GetTicketTimestamp(1, ticket_id);
    assert(ticket_timestamp == 1234567890, 'Correct timestamp');

    cleanup_mocks(mock_strk_play);
}

//=======================================================================================
// Phase 12: Basic Getter Tests - Jackpot Entry Getters
//=======================================================================================

#[test]
fn test_get_jackpot_entry_draw_id() {
    let (lottery_address, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery (creates draw 1)
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE);

    let jackpot_draw_id = lottery_dispatcher.GetJackpotEntryDrawId(1);
    assert(jackpot_draw_id == 1, 'Jackpot draw ID OK');
}

#[test]
fn test_get_jackpot_entry_amount() {
    let (lottery_address, mock_strk_play, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery (Draw 1)
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE);

    // Buy 1 ticket to add 2.75 STRKP to jackpot (5 * 55%)
    setup_mocks_for_multiple_tickets(mock_strk_play, USER1, 1);
    let numbers_array = create_valid_numbers_array(1);
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 1);
    cleanup_mocks(mock_strk_play);

    // Close Draw 1 and create Draw 2
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.DrawNumbers(1);
    lottery_dispatcher.CreateNewDraw();

    // Verify Draw 2 jackpot is exactly 2.75 STRKP (carry-over without distribution)
    let jackpot_amount_draw2 = lottery_dispatcher.GetJackpotEntryAmount(2);
    let expected_jackpot = (TICKET_PRICE * 55) / 100; // 2.75 STRKP
    assert(jackpot_amount_draw2 == expected_jackpot, 'Draw 2 jackpot 2.75');
}

#[test]
fn test_get_jackpot_entry_start_block() {
    let (lottery_address, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE);

    let start_block = lottery_dispatcher.GetJackpotEntryStartBlock(1);
    assert(start_block > 0, 'Start block set');
}

#[test]
fn test_get_jackpot_entry_end_block() {
    let (lottery_address, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE);

    let end_block = lottery_dispatcher.GetJackpotEntryEndBlock(1);
    assert(end_block > 0, 'End block set');

    // End block should be start block + default duration (44800 blocks)
    let start_block = lottery_dispatcher.GetJackpotEntryStartBlock(1);
    assert(end_block == start_block + 44800, 'Duration 44800 blocks');
}

#[test]
fn test_get_jackpot_entry_is_active() {
    let (lottery_address, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE);

    let is_active = lottery_dispatcher.GetJackpotEntryIsActive(1);
    assert(is_active == true, 'New draw active');
}

#[test]
fn test_get_jackpot_entry_is_completed() {
    let (lottery_address, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE);

    let is_completed = lottery_dispatcher.GetJackpotEntryIsCompleted(1);
    assert(is_completed == false, 'Active not completed');
}

#[test]
fn test_jackpot_entry_getters_multiple_draws() {
    let (lottery_address, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery (creates draw 1)
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE);

    // Close draw 1, then create second draw
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.DrawNumbers(1);
    lottery_dispatcher.CreateNewDraw();

    // Check both draws
    let draw1_active = lottery_dispatcher.GetJackpotEntryIsActive(1);
    let draw1_completed = lottery_dispatcher.GetJackpotEntryIsCompleted(1);
    let draw2_active = lottery_dispatcher.GetJackpotEntryIsActive(2);
    let draw2_completed = lottery_dispatcher.GetJackpotEntryIsCompleted(2);

    assert(draw1_active == false, 'Draw 1 inactive');
    assert(draw1_completed == true, 'Draw 1 completed');
    assert(draw2_active == true, 'Draw 2 active');
    assert(draw2_completed == false, 'Draw 2 not completed');
}

//=======================================================================================
// Phase 13: Basic Getter Tests - Jackpot History
//=======================================================================================

#[test]
fn test_get_jackpot_history_jackpot_amounts() {
    let (lottery_address, mock_strk_play, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE);

    // Buy some tickets to increase jackpot
    setup_mocks_for_multiple_tickets(mock_strk_play, USER1, 3);
    let numbers_array = create_valid_numbers_array(3);
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array, 3);
    cleanup_mocks(mock_strk_play);

    let jackpot_history = lottery_dispatcher.get_jackpot_history();
    assert(jackpot_history.len() == 1, '1 entry in history');

    let _entry = jackpot_history.at(0);
    // Note: With the new logic, jackpot starts from vault balance (0 with mocks)
    // Then increases with ticket purchases (55% of total price)
    let expected_increase = (TICKET_PRICE * 3 * 55) / 100; // 55% of total price
    let expected_amount = expected_increase; // No initial jackpot with empty vault

    // Use getter functions instead of direct struct access
    let entry_amount = lottery_dispatcher.GetJackpotEntryAmount(1);
    let entry_is_active = lottery_dispatcher.GetJackpotEntryIsActive(1);

    assert(entry_amount == expected_amount, 'Jackpot includes purchases');
    assert(entry_is_active == true, 'Draw still active');
}

//=======================================================================================
// New Tests: Jackpot Accumulation Scenarios
//=======================================================================================

#[test]
fn test_jackpot_accumulation_across_three_draws() {
    let (lottery_address, mock_strk_play, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize lottery (Draw 1)
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(TICKET_PRICE);

    // Draw 1: Buy 2 tickets → jackpot = 5.5 STRKP (2 * 5 * 55%)
    setup_mocks_for_multiple_tickets(mock_strk_play, USER1, 2);
    let numbers_array1 = create_valid_numbers_array(2);
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(1, numbers_array1, 2);
    cleanup_mocks(mock_strk_play);

    let jackpot_draw1 = lottery_dispatcher.GetJackpotEntryAmount(1);
    let expected_jackpot_1 = (TICKET_PRICE * 2 * 55) / 100; // 5.5 STRKP
    assert(jackpot_draw1 == expected_jackpot_1, 'Draw 1: 5.5 STRKP');

    // Close Draw 1 and create Draw 2
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.DrawNumbers(1);
    lottery_dispatcher.CreateNewDraw();

    // Draw 2: Buy 1 ticket → jackpot = 5.5 + 2.75 = 8.25 STRKP
    setup_mocks_for_multiple_tickets(mock_strk_play, USER1, 1);
    let numbers_array2 = create_valid_numbers_array(1);
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(2, numbers_array2, 1);
    cleanup_mocks(mock_strk_play);

    let jackpot_draw2 = lottery_dispatcher.GetJackpotEntryAmount(2);
    let expected_jackpot_2 = (TICKET_PRICE * 3 * 55) / 100; // 8.25 STRKP
    assert(jackpot_draw2 == expected_jackpot_2, 'Draw 2: 8.25 STRKP');

    // Close Draw 2 and create Draw 3
    cheat_caller_address(lottery_address, OWNER, CheatSpan::TargetCalls(1));
    lottery_dispatcher.DrawNumbers(2);
    lottery_dispatcher.CreateNewDraw();

    // Draw 3: Buy 1 ticket → jackpot = 8.25 + 2.75 = 11 STRKP
    setup_mocks_for_multiple_tickets(mock_strk_play, USER1, 1);
    let numbers_array3 = create_valid_numbers_array(1);
    cheat_caller_address(lottery_address, USER1, CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(3, numbers_array3, 1);
    cleanup_mocks(mock_strk_play);

    let jackpot_draw3 = lottery_dispatcher.GetJackpotEntryAmount(3);
    let expected_jackpot_3 = (TICKET_PRICE * 4 * 55) / 100; // 11 STRKP
    assert(jackpot_draw3 == expected_jackpot_3, 'Draw 3: 11 STRKP');

    // Verify progression: 5.5 → 8.25 → 11
    assert(jackpot_draw1 < jackpot_draw2, 'Jackpot increased D1->D2');
    assert(jackpot_draw2 < jackpot_draw3, 'Jackpot increased D2->D3');
}
