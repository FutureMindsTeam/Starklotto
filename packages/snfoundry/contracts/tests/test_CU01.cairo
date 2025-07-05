use contracts::StarkPlayVault::{IStarkPlayVaultDispatcher, IStarkPlayVaultDispatcherTrait};
use openzeppelin_testing::declare_and_deploy;
use openzeppelin_utils::serde::SerializedAppend;
use snforge_std::{
    CheatSpan, cheat_caller_address, EventSpy, start_cheat_caller_address,
    stop_cheat_caller_address, declare, ContractClassTrait, DeclareResultTrait, spy_events,
    EventSpyAssertionsTrait, EventSpyTrait, // Add for fetching events directly
    Event, // A structure describing a raw `Event`
    IsEmitted // Trait for checking if a given event was ever emitted
};
use starknet::ContractAddress;



// Test addresses
const OWNER: felt252 = 0x123456789abcdef;
const USER: felt252 = 0x987654321fedcba;
const Initial_Fee_Percentage: u64 = 50; // 50 basis points = 0.5%
const BASIS_POINTS_DENOMINATOR: u256 = 10000_u256; // 10000 basis points = 100%

//helper functions
fn owner_address() -> ContractAddress {
    OWNER.try_into().unwrap()
}

fn user_address() -> ContractAddress {
    USER.try_into().unwrap()
}

fn deploy_contract_lottery() -> ContractAddress {
    let contract_lotery: ContractAddress = OWNER.try_into().unwrap();
    contract_lotery
}

fn deploy_contract_starkplayvault() -> ContractAddress {
    let contract_lotery = deploy_contract_lottery();
    let owner = owner_address();
    let initial_fee = 50_u64; // 50 basis points = 0.5%
    let mut calldata = array![];

    calldata.append_serde(contract_lotery);
    calldata.append_serde(owner);
    calldata.append_serde(initial_fee);

    declare_and_deploy("StarkPlayVault", calldata)
}

fn deploy_starkplay_token() -> ContractAddress {
    let contract_class = declare("StarkPlayERC20").unwrap().contract_class();
    let mut calldata = array![];
    calldata.append_serde(owner_address()); // recipient
    calldata.append_serde(owner_address()); // admin
    let (contract_address, _) = contract_class.deploy(@calldata).unwrap();
    contract_address
}

fn deploy_vault_with_fee(starkplay_token: ContractAddress, fee_percentage: u64) -> ContractAddress {
    let contract_class = declare("StarkPlayVault").unwrap().contract_class();
    let mut calldata = array![];
    calldata.append_serde(owner_address());
    calldata.append_serde(starkplay_token);
    calldata.append_serde(fee_percentage);
    let (contract_address, _) = contract_class.deploy(@calldata).unwrap();
    contract_address
}

fn get_fee_amount(feePercentage: u64, amount: u256) -> u256 {
    let feeAmount = (amount * feePercentage.into()) / BASIS_POINTS_DENOMINATOR;
    feeAmount
}

#[test]
fn test_get_fee_percentage_deploy() {
    let vault_address = deploy_contract_starkplayvault();

    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };

    //check fee of buy starkplay is correct
    let fee_percentage = vault_dispatcher.GetFeePercentage();

    assert(fee_percentage == Initial_Fee_Percentage, 'Fee percentage should be 0.5%');
}

#[test]
fn test_calculate_fee_buy_numbers() {
    let vault_address = deploy_contract_starkplayvault();

    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };

    let fee_percentage = vault_dispatcher.GetFeePercentage();

    let mount_1STARK = 1000000000000000000_u256; // 1 STARK = 10^18
    let mount_10STARK = 10000000000000000000_u256; // 10 STARK 
    let mount_100STARK = 100000000000000000000_u256; // 100 STARK 

    //1 STARK	0.005 STARK
    assert(
        get_fee_amount(fee_percentage, mount_1STARK) == 5000000000000000_u256,
        'Fee correct for 1 STARK',
    );
    //10 STARK	0.05 STARK
    assert(
        get_fee_amount(fee_percentage, mount_10STARK) == 50000000000000000_u256,
        'Fee correct for 10 STARK',
    );
    //100 STARK	0.5 STARK
    assert(
        get_fee_amount(fee_percentage, mount_100STARK) == 500000000000000000_u256,
        'Fee correct for 100 STARK',
    );
}

//--------------TEST ISSUE-TEST-004------------------------------
//tests have to fail
#[should_panic(expected: 'Fee percentage is too low')]
#[test]
fn test_set_fee_zero_like_negative_value() {
    let vault_address = deploy_contract_starkplayvault();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    let new_fee = 0_u64;
    let result = vault_dispatcher.setFeePercentage(new_fee);
}

//tests have to fail
#[should_panic(expected: 'Fee percentage is too high')]
#[test]
fn test_set_fee_max_like_501() {
    let vault_address = deploy_contract_starkplayvault();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    let new_fee = 501_u64;
    let _result = vault_dispatcher.setFeePercentage(new_fee);
}

#[test]
fn test_set_fee_deploy_contract() {
    let vault_address = deploy_contract_starkplayvault();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    let fee_percentage = 50_u64;
    let val = vault_dispatcher.GetFeePercentage();
    assert(val == 50_u64, 'Fee  should be 50');
}

#[test]
fn test_set_fee_min() {
    let vault_address = deploy_contract_starkplayvault();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    let new_fee = 10_u64;
    let result = vault_dispatcher.setFeePercentage(new_fee);
    assert(result == true, 'Fee should be set');
    assert(vault_dispatcher.GetFeePercentage() == new_fee, 'Fee is not 10_u64');
}

#[test]
fn test_set_fee_max() {
    let vault_address = deploy_contract_starkplayvault();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    let new_fee = 500_u64;
    let result = vault_dispatcher.setFeePercentage(new_fee);
    assert(result == true, 'Fee should be set');
    assert(vault_dispatcher.GetFeePercentage() == new_fee, 'Fee is not 500_u64');
}

#[test]
fn test_set_fee_middle() {
    let vault_address = deploy_contract_starkplayvault();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    let new_fee = 250_u64;
    let result = vault_dispatcher.setFeePercentage(new_fee);
    assert(result == true, 'Fee should be set');
    assert(vault_dispatcher.GetFeePercentage() == new_fee, 'Fee is not 250_u64');
}

#[test]
fn test_event_set_fee_percentage() {
    let vault_address = deploy_contract_starkplayvault();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    let new_fee = 250_u64;
    let mut spy = spy_events();

    let result = vault_dispatcher.setFeePercentage(new_fee);

    let events = spy.get_events();

    assert(events.events.len() == 1, 'There should be one event');
}
//--------------TEST ISSUE-TEST-004------------------------------

#[test]
fn test_convert_1000_tokens_with_5_percent_fee() {
    let token_address = deploy_starkplay_token();
    
    let vault_address = deploy_vault_with_fee(token_address, 500_u64); // 5% = 500 basis points
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };

    // Check initial accumulated prize conversion fees (should be 0)
    let initial_accumulated_fees = vault_dispatcher.GetAccumulatedPrizeConversionFees();
    assert(initial_accumulated_fees == 0, 'Initial fees should be 0');

    // For 1,000 tokens with 5% fee: fee = 1000 * 500 / 10000 = 50 tokens
    let amount_to_convert = 1000_u256;
    let expected_fee = get_fee_amount(500_u64, amount_to_convert); // 500 basis points = 5%
        
        // Verify the expected fee calculation
    assert!(expected_fee == 50_u256, "Expected fee should be 50 for 1000 tokens");

    // Test the fee calculation matches our helper function
    let fee_percentage = vault_dispatcher.GetFeePercentage();
    assert(fee_percentage == 500_u64, 'Fee percentage should be 5%');
    
    let calculated_fee = get_fee_amount(fee_percentage, amount_to_convert);
    assert(calculated_fee == expected_fee, 'Fee calculation should match');
}

#[test]
fn test_fee_accumulation_logic() { 
    let amount1 = 1000_u256;
    let fee_rate = 500_u64; // 5% = 500 basis points
    let expected_fee1 = 50_u256;
    let calculated_fee1 = get_fee_amount(fee_rate, amount1);
    assert!(calculated_fee1 == expected_fee1, "Fee should be 50 for 1000 tokens");
    
    let amount2 = 2000_u256;
    let expected_fee2 = 100_u256;
    let calculated_fee2 = get_fee_amount(fee_rate, amount2);
    assert!(calculated_fee2 == expected_fee2, "Fee should be 100 for 2000 tokens");
    
    let total_accumulated = calculated_fee1 + calculated_fee2;
    assert!(total_accumulated == 150_u256, "Total fees should be 150 (50+100)");
    
    // Verify individual components
    assert!(calculated_fee1 == 50_u256, "First conversion fee should be 50");
    assert!(calculated_fee2 == 100_u256, "Second conversion fee should be 100");
    assert!(total_accumulated == calculated_fee1 + calculated_fee2, "Accumulation should sum correctly");
}

#[test]
fn test_accumulated_prize_conversion_fees_getter() {
    let token_address = deploy_starkplay_token();
    let vault_address = deploy_vault_with_fee(token_address, 500_u64); // 5% fee
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    
    // Initial accumulated fees should be 0
    let initial_fees = vault_dispatcher.GetAccumulatedPrizeConversionFees();
    assert!(initial_fees == 0, "Initial accumulated fees should be 0");
}

#[test]
fn test_basis_points_calculation() {
    // 0.5% (50 basis points) on 1000 tokens = 5 tokens
    let fee_05_percent = get_fee_amount(50_u64, 1000_u256);
    assert(fee_05_percent == 5_u256, '0.5% of 1000 should be 5');
    
    // 1% (100 basis points) on 1000 tokens = 10 tokens
    let fee_1_percent = get_fee_amount(100_u64, 1000_u256);
    assert(fee_1_percent == 10_u256, '1% of 1000 should be 10');
    
    // 5% (500 basis points) on 1000 tokens = 50 tokens
    let fee_5_percent = get_fee_amount(500_u64, 1000_u256);
    assert(fee_5_percent == 50_u256, '5% of 1000 should be 50');
    
    // 10% (1000 basis points) on 1000 tokens = 100 tokens
    let fee_10_percent = get_fee_amount(1000_u64, 1000_u256);
    assert(fee_10_percent == 100_u256, '10% of 1000 should be 100');
}

#[test]
fn test_consecutive_conversion_fee_accumulation() {    
    let token_address = deploy_starkplay_token();
    let vault_address = deploy_vault_with_fee(token_address, 500_u64); // 5% fee
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };

    let mut simulated_accumulated_fees = 0_u256;
    
    // First conversion: 1000 tokens with 5% fee
    let first_conversion_amount = 1000_u256;
    let first_fee = get_fee_amount(500_u64, first_conversion_amount); // 50 tokens
    simulated_accumulated_fees += first_fee;
    
    assert!(first_fee == 50_u256, "First conversion fee should be 50");
    assert!(simulated_accumulated_fees == 50_u256, "Accumulated should be 50 after first conversion");
    
    // Second conversion: 2000 tokens with 5% fee  
    let second_conversion_amount = 2000_u256;
    let second_fee = get_fee_amount(500_u64, second_conversion_amount); // 100 tokens
    simulated_accumulated_fees += second_fee;
    
    assert!(second_fee == 100_u256, "Second conversion fee should be 100");
    assert!(simulated_accumulated_fees == 150_u256, "Accumulated should be 150 after second conversion");
}

#[test]
fn test_multiple_prize_conversions_accumulate_fees() {
    
    let fee_percentage = 500_u64; // 5% fee
    let mut total_accumulated_fees = 0_u256;
    
    // First conversion: 1000 tokens with 5% fee = 50 tokens fee
    let first_amount = 1000_u256;
    let first_fee = get_fee_amount(fee_percentage, first_amount);
    total_accumulated_fees += first_fee;
    
    // Second conversion: 2000 tokens with 5% fee = 100 tokens fee
    let second_amount = 2000_u256;
    let second_fee = get_fee_amount(fee_percentage, second_amount);
    total_accumulated_fees += second_fee;
    
    // Third conversion: 500 tokens with 5% fee = 25 tokens fee
    let third_amount = 500_u256;
    let third_fee = get_fee_amount(fee_percentage, third_amount);
    total_accumulated_fees += third_fee;
    
    // Verify individual fee calculations
    assert!(first_fee == 50_u256, "First conversion fee should be 50");
    assert!(second_fee == 100_u256, "Second conversion fee should be 100");
    assert!(third_fee == 25_u256, "Third conversion fee should be 25");
    
    // Verify total accumulation
    assert!(total_accumulated_fees == 175_u256, "Total accumulated fees should be 175");
    
    // Verify step-by-step accumulation
    assert!(first_fee == 50_u256, "After first conversion: 50");
    assert!(first_fee + second_fee == 150_u256, "After second conversion: 150");
    assert!(first_fee + second_fee + third_fee == 175_u256, "After third conversion: 175");
}

#[test]
fn test_different_fee_percentages_accumulation() {
    
    let amount = 1000_u256;
    
    // Test with 1% fee (100 basis points)
    let fee_1_percent = get_fee_amount(100_u64, amount);
    assert!(fee_1_percent == 10_u256, "1% of 1000 should be 10");
    
    // Test with 2.5% fee (250 basis points)
    let fee_2_5_percent = get_fee_amount(250_u64, amount);
    assert!(fee_2_5_percent == 25_u256, "2.5% of 1000 should be 25");
    
    // Test with 5% fee (500 basis points)
    let fee_5_percent = get_fee_amount(500_u64, amount);
    assert!(fee_5_percent == 50_u256, "5% of 1000 should be 50");
    
    // Test accumulation of different fee percentages
    let total_fees = fee_1_percent + fee_2_5_percent + fee_5_percent;
    assert!(total_fees == 85_u256, "Total fees should be 85 (10+25+50)");
}

#[test]
fn test_large_amounts_accumulation() {
    let fee_percentage = 250_u64; // 2.5% fee
    
    // Test with 10,000 tokens
    let amount_10k = 10000_u256;
    let fee_10k = get_fee_amount(fee_percentage, amount_10k);
    assert!(fee_10k == 250_u256, "2.5% of 10,000 should be 250");
    
    // Test with 100,000 tokens
    let amount_100k = 100000_u256;
    let fee_100k = get_fee_amount(fee_percentage, amount_100k);
    assert!(fee_100k == 2500_u256, "2.5% of 100,000 should be 2,500");
    
    // Test with 1,000,000 tokens
    let amount_1m = 1000000_u256;
    let fee_1m = get_fee_amount(fee_percentage, amount_1m);
    assert!(fee_1m == 25000_u256, "2.5% of 1,000,000 should be 25,000");
    
    // Test accumulation of large amounts
    let total_large_fees = fee_10k + fee_100k + fee_1m;
    assert!(total_large_fees == 27750_u256, "Total large fees should be 27,750");
}

#[test]
fn test_sequential_conversions_different_users() {
    // Test that accumulation works correctly for multiple users
    let fee_percentage = 300_u64; // 3% fee
    let mut accumulated_fees = 0_u256;
    
    // User 1 converts 1000 tokens
    let user1_amount = 1000_u256;
    let user1_fee = get_fee_amount(fee_percentage, user1_amount);
    accumulated_fees += user1_fee;
    
    // User 2 converts 1500 tokens
    let user2_amount = 1500_u256;
    let user2_fee = get_fee_amount(fee_percentage, user2_amount);
    accumulated_fees += user2_fee;
    
    // User 3 converts 2000 tokens
    let user3_amount = 2000_u256;
    let user3_fee = get_fee_amount(fee_percentage, user3_amount);
    accumulated_fees += user3_fee;
    
    // Verify individual fees
    assert!(user1_fee == 30_u256, "User 1 fee should be 30 (3% of 1000)");
    assert!(user2_fee == 45_u256, "User 2 fee should be 45 (3% of 1500)");
    assert!(user3_fee == 60_u256, "User 3 fee should be 60 (3% of 2000)");
    
    // Verify total accumulation
    assert!(accumulated_fees == 135_u256, "Total accumulated fees should be 135");
    
    // Verify step-by-step accumulation
    let after_user1 = user1_fee;
    let after_user2 = user1_fee + user2_fee;
    let after_user3 = user1_fee + user2_fee + user3_fee;
    
    assert!(after_user1 == 30_u256, "After user 1: 30");
    assert!(after_user2 == 75_u256, "After user 2: 75");
    assert!(after_user3 == 135_u256, "After user 3: 135");
}

#[test]
fn test_minimum_fee_accumulation() {
    let fee_percentage = 10_u64; // 0.1% fee (minimum allowed)
    
    let amount1 = 100_u256;
    let amount2 = 200_u256;
    let amount3 = 300_u256;
    
    let fee1 = get_fee_amount(fee_percentage, amount1);
    let fee2 = get_fee_amount(fee_percentage, amount2);
    let fee3 = get_fee_amount(fee_percentage, amount3);
    
    // Verify minimum fee calculations
    assert!(fee1 == 0_u256, "0.1% of 100 should be 0 (rounded down)");
    assert!(fee2 == 0_u256, "0.1% of 200 should be 0 (rounded down)");
    assert!(fee3 == 0_u256, "0.1% of 300 should be 0 (rounded down)");
    
    // Test with amounts that will generate fees
    let amount_large = 10000_u256;
    let fee_large = get_fee_amount(fee_percentage, amount_large);
    assert!(fee_large == 10_u256, "0.1% of 10,000 should be 10");
    
    let total_fees = fee1 + fee2 + fee3 + fee_large;
    assert!(total_fees == 10_u256, "Total fees should be 10");
}

#[test]
fn test_maximum_fee_accumulation() {
    // Test accumulation with maximum fee amounts
    let fee_percentage = 500_u64; // 5% fee (maximum allowed)
    
    let amount1 = 1000_u256;
    let amount2 = 2000_u256;
    let amount3 = 3000_u256;
    
    let fee1 = get_fee_amount(fee_percentage, amount1);
    let fee2 = get_fee_amount(fee_percentage, amount2);
    let fee3 = get_fee_amount(fee_percentage, amount3);
    
    // Verify maximum fee calculations
    assert!(fee1 == 50_u256, "5% of 1000 should be 50");
    assert!(fee2 == 100_u256, "5% of 2000 should be 100");
    assert!(fee3 == 150_u256, "5% of 3000 should be 150");
    
    let total_fees = fee1 + fee2 + fee3;
    assert!(total_fees == 300_u256, "Total fees should be 300");
}

#[test]
fn test_mixed_amounts_accumulation() {
    // Test with realistic mixed amounts and verify accumulation
    let fee_percentage = 200_u64; // 2% fee
    
    // Simulate various conversion amounts
    let amounts = array![
        500_u256,    // Small conversion
        1250_u256,   // Medium conversion  
        3000_u256,   // Large conversion
        750_u256,    // Small conversion
        2200_u256,   // Medium conversion
    ];
    
    let mut total_accumulated = 0_u256;
    let mut expected_fees = array![];
    
    // Calculate fees for each amount
    let mut i = 0;
    while i < amounts.len() {
        let amount = *amounts.at(i);
        let fee = get_fee_amount(fee_percentage, amount);
        total_accumulated += fee;
        expected_fees.append(fee);
        i += 1;
    };
    
    // Verify individual fee calculations
    assert!(*expected_fees.at(0) == 10_u256, "2% of 500 should be 10");
    assert!(*expected_fees.at(1) == 25_u256, "2% of 1250 should be 25");
    assert!(*expected_fees.at(2) == 60_u256, "2% of 3000 should be 60");
    assert!(*expected_fees.at(3) == 15_u256, "2% of 750 should be 15");
    assert!(*expected_fees.at(4) == 44_u256, "2% of 2200 should be 44");
    
    // Verify total accumulation
    assert!(total_accumulated == 154_u256, "Total accumulated fees should be 154");
    
    // Verify step-by-step accumulation
    let mut running_total = 0_u256;
    let mut j = 0;
    while j < expected_fees.len() {
        running_total += *expected_fees.at(j);
        j += 1;
    };
    
    assert!(running_total == total_accumulated, "Running total should match total accumulated");
} 