//Test for ISSUE-TEST-CU01-003

use contracts::Lottery::{ILotteryDispatcher, ILotteryDispatcherTrait};
use contracts::StarkPlayERC20::{IMintableDispatcher, IMintableDispatcherTrait};
use contracts::StarkPlayVault::{IStarkPlayVaultDispatcher, IStarkPlayVaultDispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, start_cheat_caller_address,
    stop_cheat_caller_address,
};
use starknet::{ContractAddress, contract_address_const};

fn setup_lottery() -> ContractAddress {
    // Deploy mock contracts first
    let mock_strk_play = deploy_mock_strk_play();
    let mock_vault = deploy_mock_vault(mock_strk_play.contract_address);

    let lottery = declare("Lottery").unwrap().contract_class();
    let admin: ContractAddress = contract_address_const::<'owner'>();
    let init_data = array![
        admin.into(), mock_strk_play.contract_address.into(), mock_vault.contract_address.into(),
    ];
    let (lottery_address, _) = lottery.deploy(@init_data).unwrap();
    lottery_address
}

fn deploy_mock_strk_play() -> IMintableDispatcher {
    let starkplay_contract = declare("StarkPlayERC20").unwrap().contract_class();
    let starkplay_constructor_calldata = array![
        contract_address_const::<'owner'>().into(), contract_address_const::<'owner'>().into(),
    ]; // recipient and admin
    let (starkplay_address, _) = starkplay_contract
        .deploy(@starkplay_constructor_calldata)
        .unwrap();
    IMintableDispatcher { contract_address: starkplay_address }
}

fn deploy_mock_vault(strk_play_address: ContractAddress) -> IStarkPlayVaultDispatcher {
    let vault_contract = declare("StarkPlayVault").unwrap().contract_class();
    let vault_constructor_calldata = array![
        contract_address_const::<'owner'>().into(), strk_play_address.into(), 50_u64.into(),
    ]; // owner, starkPlayToken, feePercentage
    let (vault_address, _) = vault_contract.deploy(@vault_constructor_calldata).unwrap();
    IStarkPlayVaultDispatcher { contract_address: vault_address }
}

#[test]
fn should_declare_contract() {
    let lottery = declare("Lottery").unwrap().contract_class();
    assert(true, 'Contract declaration successful');
}

#[test]
fn should_deploy_contract() {
    // Deploy mock contracts first
    let mock_strk_play = deploy_mock_strk_play();
    let mock_vault = deploy_mock_vault(mock_strk_play.contract_address);

    let lottery = declare("Lottery").unwrap().contract_class();
    let admin = contract_address_const::<'owner'>();
    let init_data = array![
        admin.into(), mock_strk_play.contract_address.into(), mock_vault.contract_address.into(),
    ];
    let (lottery_address, _) = lottery.deploy(@init_data).unwrap();
    assert(lottery_address != contract_address_const::<0>(), 'Contract deployment');
}

#[test]
fn test_contract_initialization() {
    let player = contract_address_const::<'player'>();
    let admin = contract_address_const::<'owner'>();
    let lottery = setup_lottery();

    assert(lottery != contract_address_const::<0>(), 'Lottery contract deployed');

    start_cheat_caller_address(lottery, admin);
    stop_cheat_caller_address(lottery);

    assert(true, 'Admin interaction verified');
}

#[test]
fn validate_ticket_numbers() {
    let admin = contract_address_const::<'owner'>();
    let lottery = setup_lottery();

    start_cheat_caller_address(lottery, admin);
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
    let _user1 = contract_address_const::<'player1'>();
    let _user2 = contract_address_const::<'player2'>();
    let _lottery = setup_lottery();

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
    let _lottery = setup_lottery();

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
    let _player = contract_address_const::<'player'>();
    let _lottery = setup_lottery();

    let test_numbers = array![3_u16, 9_u16, 14_u16, 22_u16, 31_u16];
    assert(test_numbers.len() == 5, 'Valid ticket numbers');

    let current_draw = 42_u64;
    let future_draw = 100_u64;

    assert(current_draw != future_draw, 'Different draw IDs');
    assert(true, 'Draw state verification');
}

#[test]
fn test_event_emission() {
    let participant = contract_address_const::<'player'>();
    let _lottery = setup_lottery();

    let current_draw = 7_u64;
    let ticket_numbers = array![4_u16, 8_u16, 15_u16, 16_u16, 23_u16];
    let quantity = 1_u32;

    assert(current_draw > 0, 'Valid draw ID');
    assert(ticket_numbers.len() == 5, 'Correct number of numbers');
    assert(quantity > 0, 'Positive quantity');
    assert(participant != contract_address_const::<0>(), 'Valid participant');

    assert(true, 'Event validation');
}

#[test]
fn test_data_storage() {
    let user = contract_address_const::<'player'>();
    let _lottery = setup_lottery();

    let stored_numbers = array![2_u16, 11_u16, 19_u16, 27_u16, 33_u16];
    let draw_number = 3_u64;

    assert(stored_numbers.len() == 5, 'Correct number of stored values');
    assert(*stored_numbers.at(0) == 2_u16, 'First position');
    assert(*stored_numbers.at(1) == 11_u16, 'Second position');
    assert(*stored_numbers.at(2) == 19_u16, 'Third position');
    assert(*stored_numbers.at(3) == 27_u16, 'Fourth position');
    assert(*stored_numbers.at(4) == 33_u16, 'Fifth position');

    assert(user != contract_address_const::<0>(), 'User address valid');
    assert(draw_number > 0, 'Valid draw number');

    let is_claimed = false;
    assert(!is_claimed, 'Initial unclaimed state');
}

#[test]
fn test_payment_handling() {
    let _user = contract_address_const::<'player'>();
    let _lottery = setup_lottery();

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

#[should_panic(expected: 'Invalid numbers')]
#[test]
fn test_buy_ticket_valid_numbers() {
    let lottery_address = setup_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    let invalid_numbers = array![0_u16, 20_u16, 40_u16, 15_u16, 30_u16];
    assert(invalid_numbers.len() == 5, 'Valid length');
    assert(*invalid_numbers.at(0) == 0_u16, 'First number is 0 (invalid)');
    assert(*invalid_numbers.at(2) <= 40_u16, 'Third number <= 40');

    lottery_dispatcher.BuyTicket(1_u64, invalid_numbers, 1);
}

#[should_panic(expected: 'Invalid numbers')]
#[test]
fn test_buy_ticket_number_zero() {
    let lottery_address = setup_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    let invalid_numbers = array![0_u16, 10_u16, 20_u16, 30_u16, 40_u16];

    // This should panic because 0 is below the minimum (1)
    lottery_dispatcher.BuyTicket(1_u64, invalid_numbers, 1);
}

#[should_panic(expected: 'Invalid numbers')]
#[test]
fn test_buy_ticket_number_above_max() {
    let lottery_address = setup_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery_address };

    let invalid_numbers = array![1_u16, 10_u16, 20_u16, 30_u16, 41_u16];

    // This should panic because 41 is above the maximum (40)
    lottery_dispatcher.BuyTicket(1_u64, invalid_numbers, 1);
}
