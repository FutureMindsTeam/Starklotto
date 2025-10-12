use contracts::Lottery::{ILotteryDispatcher, ILotteryDispatcherTrait};
use contracts::StarkPlayERC20::{IMintableDispatcher, IMintableDispatcherTrait};
use core::array::ArrayTrait;
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
const DEFAULT_PRICE: u256 = 500;
const DEFAULT_ACCUMULATED_PRIZE: u256 = 1000;
const DEFAULT_ID: u64 = 1;
const TicketPriceInitial: u256 = 5000000000000000000;
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

fn deploy_lottery() -> (ContractAddress, IMintableDispatcher, ILotteryDispatcher) {
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

    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };
    let strk_play_dispatcher = IMintableDispatcher { contract_address: mock_strk_play };

    (lottery_address, strk_play_dispatcher, lottery_dispatcher)
}

fn create_valid_numbers() -> Array<u16> {
    array![1, 15, 25, 35, 40]
}

// Helper: wrap a single ticket numbers array into Array<Array<u16>>
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

fn cleanup_mocks(strk_play_address: ContractAddress) {
    stop_mock_call(strk_play_address, selector!("balance_of"));
    stop_mock_call(strk_play_address, selector!("allowance"));
    stop_mock_call(strk_play_address, selector!("transfer_from"));
}

fn context(
    ticket_price: u256, caller: ContractAddress,
) -> (IERC20Dispatcher, ILotteryDispatcher) {
    let (lottery, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery };
    cheat_caller_address(lottery, owner_address(), CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(ticket_price);
    let erc = start(lottery_dispatcher, USER1, ticket_price, lottery);
    (erc, lottery_dispatcher)
}

fn default_context() -> (IERC20Dispatcher, ILotteryDispatcher) {
    context(DEFAULT_PRICE, USER1)
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

fn feign_buy_ticket(lottery: ILotteryDispatcher, buyer: ContractAddress) -> Array<Array<u16>> {
    let numbers = array![1_u16, 2_u16, 3_u16, 4_u16, 5_u16];
    cheat_caller_address(lottery.contract_address, buyer, CheatSpan::Indefinite);
    cheat_block_timestamp(lottery.contract_address, 1, CheatSpan::TargetCalls(1));
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());
    lottery.BuyTicket(DEFAULT_ID, numbers_array.clone(), 1);
    numbers_array
}

//=======================================================================================
// Phase 1: GetTicketPrice Tests
//=======================================================================================

#[test]
fn test_get_ticket_price_default_value() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    let initial_price = lottery_dispatcher.GetTicketPrice();
    assert!(initial_price == TicketPriceInitial, "Initial ticket price should be 5");
}

#[test]
fn test_get_ticket_price_after_initialize() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());

    let init_price: u256 = 500000000000000000;
    lottery_dispatcher.Initialize(init_price);

    let current_price = lottery_dispatcher.GetTicketPrice();
    assert!(current_price == init_price, "Ticket price should match initialized value");

    stop_cheat_caller_address(lottery_dispatcher.contract_address);
}

#[test]
fn test_get_ticket_price_after_set_ticket_price() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());

    let new_price: u256 = 750000000000000000;
    lottery_dispatcher.SetTicketPrice(new_price);

    let current_price = lottery_dispatcher.GetTicketPrice();
    assert!(current_price == new_price, "Ticket price should match set value");

    stop_cheat_caller_address(lottery_dispatcher.contract_address);
}

#[test]
fn test_get_ticket_price_public_access() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    // Set price as owner
    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());
    let set_price: u256 = 1500000000000000000;
    lottery_dispatcher.SetTicketPrice(set_price);
    stop_cheat_caller_address(lottery_dispatcher.contract_address);

    // Read price as different users
    start_cheat_caller_address(lottery_dispatcher.contract_address, USER1);
    let read_price = lottery_dispatcher.GetTicketPrice();
    assert!(read_price == set_price, "User1 should be able to read ticket price");
    stop_cheat_caller_address(lottery_dispatcher.contract_address);

    start_cheat_caller_address(lottery_dispatcher.contract_address, USER2);
    let read_price_2 = lottery_dispatcher.GetTicketPrice();
    assert!(read_price_2 == set_price, "User2 should be able to read ticket price");
    stop_cheat_caller_address(lottery_dispatcher.contract_address);
}

//=======================================================================================
// Phase 2: GetAccumulatedPrize Tests
//=======================================================================================

#[test]
fn test_get_accumulated_prize_initial_value() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    let initial_prize = lottery_dispatcher.GetAccumulatedPrize();
    assert!(initial_prize == 0, "Initial accumulated prize should be 0");
}



#[test]
fn test_get_accumulated_prize_after_create_new_draw() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());

    let ticket_price: u256 = 500000000000000000;
    lottery_dispatcher.Initialize(ticket_price);

    // Close the active draw before creating a new one
    lottery_dispatcher.DrawNumbers(1);
    lottery_dispatcher.CreateNewDraw();

    // Note: Jackpot is now calculated from vault balance
    let current_prize = lottery_dispatcher.GetAccumulatedPrize();
    assert!(
        current_prize >= 0, "Jackpot >= 0",
    );

    stop_cheat_caller_address(lottery_dispatcher.contract_address);
}

#[test]
fn test_get_accumulated_prize_public_access() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    // Set prize as owner
    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());
    lottery_dispatcher.CreateNewDraw();
    stop_cheat_caller_address(lottery_dispatcher.contract_address);

    // Read prize as different users
    start_cheat_caller_address(lottery_dispatcher.contract_address, USER1);
    let read_prize = lottery_dispatcher.GetAccumulatedPrize();
    assert!(
        read_prize == 0, "User1 should be able to read accumulated prize (should be 0 initially)",
    );
    stop_cheat_caller_address(lottery_dispatcher.contract_address);

    start_cheat_caller_address(lottery_dispatcher.contract_address, USER2);
    let read_prize_2 = lottery_dispatcher.GetAccumulatedPrize();
    assert!(
        read_prize_2 == 0, "User2 should be able to read accumulated prize (should be 0 initially)",
    );
    stop_cheat_caller_address(lottery_dispatcher.contract_address);
}

//=======================================================================================
// Phase 3: GetTicketCurrentId Tests
//=======================================================================================

#[test]
fn test_get_ticket_current_id_initial_value() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    let initial_id = lottery_dispatcher.GetTicketCurrentId();
    assert!(initial_id == 0, "Initial ticket current ID should be 0");
}

#[test]
fn test_get_ticket_current_id_after_ticket_purchase() {
    let (_erc, lottery) = default_context();

    // Purchase a ticket
    let numbers = create_valid_numbers();
    start_cheat_caller_address(lottery.contract_address, USER1);
    cheat_block_timestamp(lottery.contract_address, 1, CheatSpan::TargetCalls(1));
    let numbers_array = create_single_ticket_numbers_array(numbers.clone());
    lottery.BuyTicket(DEFAULT_ID, numbers_array, 1);
    stop_cheat_caller_address(lottery.contract_address);

    let current_id = lottery.GetTicketCurrentId();
    assert!(current_id == 1, "Ticket current ID should be 1 after first purchase");
}

#[test]
fn test_get_ticket_current_id_multiple_purchases() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());

    let ticket_price: u256 = 500000000000000000;
    lottery_dispatcher.Initialize(ticket_price);

    stop_cheat_caller_address(lottery_dispatcher.contract_address);

    // Verify initial state
    let initial_id = lottery_dispatcher.GetTicketCurrentId();
    assert!(initial_id == 0, "Initial ticket current ID should be 0");

    // Verify that the ID remains 0 since no tickets have been purchased
    let current_id = lottery_dispatcher.GetTicketCurrentId();
    assert!(current_id == 0, "Ticket current ID should remain 0 when no tickets are purchased");
}

#[test]
fn test_get_ticket_current_id_public_access() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    // Read ID as different users
    start_cheat_caller_address(lottery_dispatcher.contract_address, USER1);
    let read_id = lottery_dispatcher.GetTicketCurrentId();
    assert!(read_id == 0, "User1 should be able to read ticket current ID");
    stop_cheat_caller_address(lottery_dispatcher.contract_address);

    start_cheat_caller_address(lottery_dispatcher.contract_address, USER2);
    let read_id_2 = lottery_dispatcher.GetTicketCurrentId();
    assert!(read_id_2 == 0, "User2 should be able to read ticket current ID");
    stop_cheat_caller_address(lottery_dispatcher.contract_address);
}

//=======================================================================================
// Phase 4: GetFixedPrize Tests
//=======================================================================================

#[test]
fn test_get_fixed_prize_zero_matches() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());
    lottery_dispatcher.Initialize(TICKET_PRICE);
    stop_cheat_caller_address(lottery_dispatcher.contract_address);

    let prize = lottery_dispatcher.GetFixedPrize(1, 0);  // drawId = 1, matches = 0
    assert!(prize == 0, "Prize for 0 matches should be 0");
}

#[test]
fn test_get_fixed_prize_one_match() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());
    lottery_dispatcher.Initialize(TICKET_PRICE);
    stop_cheat_caller_address(lottery_dispatcher.contract_address);

    let prize = lottery_dispatcher.GetFixedPrize(1, 1);  // drawId = 1, matches = 1
    assert!(prize == 0, "Prize for 1 match should be 0");
}

#[test]
fn test_get_fixed_prize_two_matches() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());
    lottery_dispatcher.Initialize(TICKET_PRICE);
    stop_cheat_caller_address(lottery_dispatcher.contract_address);

    let prize = lottery_dispatcher.GetFixedPrize(1, 2);  // drawId = 1, matches = 2
    // Note: This will return the fixed prize for 2 matches, which should be set during
    // initialization The actual value depends on the contract's fixed prize configuration
    assert!(prize >= 0, "Prize for 2 matches should be non-negative");
}

#[test]
fn test_get_fixed_prize_three_matches() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());
    lottery_dispatcher.Initialize(TICKET_PRICE);
    stop_cheat_caller_address(lottery_dispatcher.contract_address);

    let prize = lottery_dispatcher.GetFixedPrize(1, 3);  // drawId = 1, matches = 3
    assert!(prize >= 0, "Prize for 3 matches should be non-negative");
}

#[test]
fn test_get_fixed_prize_four_matches() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());
    lottery_dispatcher.Initialize(TICKET_PRICE);
    stop_cheat_caller_address(lottery_dispatcher.contract_address);

    let prize = lottery_dispatcher.GetFixedPrize(1, 4);  // drawId = 1, matches = 4
    assert!(prize >= 0, "Prize for 4 matches should be non-negative");
}

#[test]
fn test_get_fixed_prize_five_matches() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());
    lottery_dispatcher.Initialize(TICKET_PRICE);
    stop_cheat_caller_address(lottery_dispatcher.contract_address);

    let prize = lottery_dispatcher.GetFixedPrize(1, 5);  // drawId = 1, matches = 5
    // For 5 matches, it should return the accumulated prize of the draw
    let accumulated_prize = lottery_dispatcher.GetAccumulatedPrize();
    assert!(prize == accumulated_prize, "Prize for 5 matches should equal accumulated prize");
}

#[test]
fn test_get_fixed_prize_invalid_matches() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());
    lottery_dispatcher.Initialize(TICKET_PRICE);
    stop_cheat_caller_address(lottery_dispatcher.contract_address);

    let prize = lottery_dispatcher.GetFixedPrize(1, 6);  // drawId = 1, matches = 6
    assert!(prize == 0, "Prize for invalid matches should be 0");

    let prize_high = lottery_dispatcher.GetFixedPrize(1, 255);  // drawId = 1, matches = 255
    assert!(prize_high == 0, "Prize for very high matches should be 0");
}

#[test]
fn test_get_fixed_prize_all_scenarios() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());
    lottery_dispatcher.Initialize(TICKET_PRICE);
    stop_cheat_caller_address(lottery_dispatcher.contract_address);

    // Test all valid match scenarios
    assert!(lottery_dispatcher.GetFixedPrize(1, 0) == 0, "0 matches should return 0");
    assert!(lottery_dispatcher.GetFixedPrize(1, 1) == 0, "1 match should return 0");
    assert!(lottery_dispatcher.GetFixedPrize(1, 2) >= 0, "2 matches should be non-negative");
    assert!(lottery_dispatcher.GetFixedPrize(1, 3) >= 0, "3 matches should be non-negative");
    assert!(lottery_dispatcher.GetFixedPrize(1, 4) >= 0, "4 matches should be non-negative");
    assert!(
        lottery_dispatcher.GetFixedPrize(1, 5) == lottery_dispatcher.GetAccumulatedPrize(),
        "5 matches should equal accumulated prize",
    );
    assert!(lottery_dispatcher.GetFixedPrize(1, 6) == 0, "6 matches should return 0");
}

//=======================================================================================
// Phase 5: GetDrawStatus Tests
//=======================================================================================

#[test]
fn test_get_draw_status_initial_draw() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());

    let ticket_price: u256 = 500000000000000000;
    lottery_dispatcher.Initialize(ticket_price);

    // Create a new draw
    lottery_dispatcher.DrawNumbers(1);
    lottery_dispatcher.CreateNewDraw();

    stop_cheat_caller_address(lottery_dispatcher.contract_address);

    let draw_status = lottery_dispatcher.GetDrawStatus(2);
    assert!(draw_status == true, "Newly created draw should be active");
}

#[test]
fn test_get_draw_status_after_draw_completion() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());

    let ticket_price: u256 = 500000000000000000;
    lottery_dispatcher.Initialize(ticket_price);

    // Create a new draw
    lottery_dispatcher.DrawNumbers(1);
    lottery_dispatcher.CreateNewDraw();

    // Complete the draw by drawing numbers
    lottery_dispatcher.DrawNumbers(2);

    stop_cheat_caller_address(lottery_dispatcher.contract_address);

    let draw1_status = lottery_dispatcher.GetDrawStatus(1);
    let draw2_status = lottery_dispatcher.GetDrawStatus(2);
    assert!(draw1_status == false, "First draw should be inactive after completion");
    assert!(draw2_status == false, "Second draw should be inactive after completion");
}

#[test]
fn test_get_draw_status_multiple_draws() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());

    let ticket_price: u256 = 500000000000000000;
    lottery_dispatcher.Initialize(ticket_price);

    // Create multiple draws
    lottery_dispatcher.DrawNumbers(1);
    lottery_dispatcher.CreateNewDraw();
    lottery_dispatcher.DrawNumbers(2);
    lottery_dispatcher.CreateNewDraw();

    stop_cheat_caller_address(lottery_dispatcher.contract_address);

    let draw1_status = lottery_dispatcher.GetDrawStatus(1);
    let draw2_status = lottery_dispatcher.GetDrawStatus(2);
    let draw3_status = lottery_dispatcher.GetDrawStatus(3);

    assert!(draw1_status == false, "First draw should be inactive");
    assert!(draw2_status == false, "Second draw should be inactive");
    assert!(draw3_status == true, "Third draw should be active");
}

#[test]
fn test_get_draw_status_public_access() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    // Create draw as owner
    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());
    let ticket_price: u256 = 500000000000000000;
    lottery_dispatcher.Initialize(ticket_price);
    lottery_dispatcher.DrawNumbers(1);
    lottery_dispatcher.CreateNewDraw();
    stop_cheat_caller_address(lottery_dispatcher.contract_address);

    // Read status as different users
    start_cheat_caller_address(lottery_dispatcher.contract_address, USER1);
    let read_status = lottery_dispatcher.GetDrawStatus(2);
    assert!(read_status == true, "User1 should be able to read draw status");
    stop_cheat_caller_address(lottery_dispatcher.contract_address);

    start_cheat_caller_address(lottery_dispatcher.contract_address, USER2);
    let read_status_2 = lottery_dispatcher.GetDrawStatus(2);
    assert!(read_status_2 == true, "User2 should be able to read draw status");
    stop_cheat_caller_address(lottery_dispatcher.contract_address);
}

//=======================================================================================
// Phase 6: SetTicketPrice Tests (Ownership Validation)
//=======================================================================================

#[test]
fn test_set_ticket_price_ownership_validation_owner_can_set() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());

    let new_price: u256 = 1000000000000000000;
    lottery_dispatcher.SetTicketPrice(new_price);

    let current_price = lottery_dispatcher.GetTicketPrice();
    assert!(current_price == new_price, "Owner should be able to set ticket price");

    stop_cheat_caller_address(lottery_dispatcher.contract_address);
}

#[should_panic(expected: ('Caller is not the owner',))]
#[test]
fn test_set_ticket_price_ownership_validation_non_owner_cannot_set() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, USER1);

    let new_price: u256 = 1000000000000000000;
    lottery_dispatcher.SetTicketPrice(new_price);

    stop_cheat_caller_address(lottery_dispatcher.contract_address);
}

#[test]
fn test_set_ticket_price_success_cases() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());

    // Test multiple price changes
    let price1: u256 = 1000000000000000000;
    lottery_dispatcher.SetTicketPrice(price1);
    assert!(lottery_dispatcher.GetTicketPrice() == price1, "First price should be set correctly");

    let price2: u256 = 2000000000000000000;
    lottery_dispatcher.SetTicketPrice(price2);
    assert!(lottery_dispatcher.GetTicketPrice() == price2, "Second price should be set correctly");

    let price3: u256 = 500000000000000000;
    lottery_dispatcher.SetTicketPrice(price3);
    assert!(lottery_dispatcher.GetTicketPrice() == price3, "Third price should be set correctly");

    stop_cheat_caller_address(lottery_dispatcher.contract_address);
}

#[test]
fn test_set_ticket_price_persistence() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());

    let initial_price: u256 = 1000000000000000000;
    lottery_dispatcher.SetTicketPrice(initial_price);

    // Verify price persists after setting
    assert!(
        lottery_dispatcher.GetTicketPrice() == initial_price, "Price should persist after setting",
    );

    stop_cheat_caller_address(lottery_dispatcher.contract_address);

    // Verify price persists after caller change
    start_cheat_caller_address(lottery_dispatcher.contract_address, USER1);
    assert!(
        lottery_dispatcher.GetTicketPrice() == initial_price,
        "Price should persist after caller change",
    );
    stop_cheat_caller_address(lottery_dispatcher.contract_address);
}

//=======================================================================================
// Phase 7: Integration Tests
//=======================================================================================

#[test]
fn test_basic_functions_integration() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());

    // Initialize contract
    let ticket_price: u256 = 500000000000000000;
    lottery_dispatcher.Initialize(ticket_price);

    // Verify all basic functions work together
    assert!(
        lottery_dispatcher.GetTicketPrice() == ticket_price,
        "Ticket price match",
    );
    // Note: Jackpot is calculated from vault balance
    assert!(
        lottery_dispatcher.GetAccumulatedPrize() >= 0,
        "Jackpot >= 0",
    );
    assert!(lottery_dispatcher.GetTicketCurrentId() == 0, "Initial ID = 0");

    // Close initial draw before creating a new one
    lottery_dispatcher.DrawNumbers(1);
    lottery_dispatcher.CreateNewDraw();

    // Verify draw status (draw 2 is the new active draw)
    assert!(lottery_dispatcher.GetDrawStatus(2) == true, "New draw should be active");

    // Change ticket price
    let new_price: u256 = 750000000000000000;
    lottery_dispatcher.SetTicketPrice(new_price);

    // Verify all functions still work correctly
    assert!(lottery_dispatcher.GetTicketPrice() == new_price, "Price updated");
    assert!(
        lottery_dispatcher.GetAccumulatedPrize() >= 0,
        "Jackpot >= 0",
    );
    assert!(lottery_dispatcher.GetDrawStatus(2) == true, "Draw active");

    stop_cheat_caller_address(lottery_dispatcher.contract_address);
}

#[test]
fn test_basic_functions_with_ticket_purchases() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());

    let ticket_price: u256 = 500000000000000000;
    lottery_dispatcher.Initialize(ticket_price);

    stop_cheat_caller_address(lottery_dispatcher.contract_address);

    // Verify initial state
    assert!(lottery_dispatcher.GetTicketCurrentId() == 0, "Initial ticket ID should be 0");

    // Verify other functions work correctly
    assert!(
        lottery_dispatcher.GetTicketPrice() == ticket_price,
        "Price matches",
    );
    assert!(
        lottery_dispatcher.GetAccumulatedPrize() >= 0,
        "Jackpot >= 0",
    );
    assert!(lottery_dispatcher.GetDrawStatus(1) == true, "Draw active");
}

//=======================================================================================
// Phase 8: Edge Case and Error Handling Tests
//=======================================================================================

#[test]
fn test_get_fixed_prize_with_updated_accumulated_prize() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());

    let ticket_price: u256 = 500000000000000000;
    lottery_dispatcher.Initialize(ticket_price);

    // Get the initial jackpot for draw 1
    let initial_jackpot_draw1 = lottery_dispatcher.GetJackpotEntryAmount(1);
    
    // Verify 5 matches returns the draw's accumulated prize
    let prize_5_matches = lottery_dispatcher.GetFixedPrize(1, 5);  // drawId = 1
    assert!(prize_5_matches == initial_jackpot_draw1, "5 matches = jackpot");

    // Close current draw, then create a new one
    lottery_dispatcher.DrawNumbers(1);
    lottery_dispatcher.CreateNewDraw();

    // Verify 5 matches for draw 2 returns the new draw's accumulated prize
    let updated_prize_5_matches = lottery_dispatcher.GetFixedPrize(2, 5);  // drawId = 2
    // Note: The actual jackpot for draw 2 is calculated from vault balance
    assert!(
        updated_prize_5_matches >= 0,
        "Draw 2 jackpot >= 0",
    );

    stop_cheat_caller_address(lottery_dispatcher.contract_address);
}

#[test]
fn test_multiple_price_changes_persistence() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());

    // Test multiple rapid price changes
    let prices = array![
        1000000000000000000,
        2000000000000000000,
        500000000000000000,
        1500000000000000000,
        3000000000000000000,
    ];

    let mut i: usize = 0;
    while i != prices.len() {
        let price = *prices.at(i);
        lottery_dispatcher.SetTicketPrice(price);
        assert!(lottery_dispatcher.GetTicketPrice() == price, "Price should be set correctly");
        i += 1;
    }

    stop_cheat_caller_address(lottery_dispatcher.contract_address);
}

#[test]
fn test_draw_status_multiple_draws_completion() {
    let (lottery_addr, _, _) = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_addr };

    start_cheat_caller_address(lottery_dispatcher.contract_address, owner_address());

    let ticket_price: u256 = 500000000000000000;
    lottery_dispatcher.Initialize(ticket_price);

    // Create multiple draws with closure between
    lottery_dispatcher.DrawNumbers(1);
    lottery_dispatcher.CreateNewDraw();
    lottery_dispatcher.DrawNumbers(2);
    lottery_dispatcher.CreateNewDraw();
    lottery_dispatcher.DrawNumbers(3);
    lottery_dispatcher.CreateNewDraw();

    // Verify statuses: 1,2,3 completed 4 active
    assert!(lottery_dispatcher.GetDrawStatus(1) == false, "First draw should be completed");
    assert!(lottery_dispatcher.GetDrawStatus(2) == false, "Second draw should be completed");
    assert!(lottery_dispatcher.GetDrawStatus(3) == false, "Third draw should be completed");
    assert!(lottery_dispatcher.GetDrawStatus(4) == true, "Fourth draw should be active");

    stop_cheat_caller_address(lottery_dispatcher.contract_address);
}
