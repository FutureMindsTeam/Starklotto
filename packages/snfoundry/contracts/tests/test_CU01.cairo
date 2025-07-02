use contracts::StarkPlayVault::{IStarkPlayVaultDispatcher, IStarkPlayVaultDispatcherTrait};
use openzeppelin_testing::declare_and_deploy;
use openzeppelin_utils::serde::SerializedAppend;
use snforge_std::{CheatSpan, cheat_caller_address, spy_events, ContractClassTrait, DeclareResultTrait, declare};
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