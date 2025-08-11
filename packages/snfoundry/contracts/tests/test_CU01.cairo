use contracts::StarkPlayERC20::{
    IBurnableDispatcher, IBurnableDispatcherTrait, IMintableDispatcher, IMintableDispatcherTrait,
    IPrizeTokenDispatcher, IPrizeTokenDispatcherTrait,
};
use contracts::StarkPlayVault::StarkPlayVault::FELT_STRK_CONTRACT;
use contracts::StarkPlayVault::{IStarkPlayVaultDispatcher, IStarkPlayVaultDispatcherTrait};
use openzeppelin_testing::declare_and_deploy;
use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use openzeppelin_utils::serde::SerializedAppend;
use snforge_std::{
    CheatSpan, cheat_caller_address, EventSpy, start_cheat_caller_address,
    stop_cheat_caller_address, declare, ContractClassTrait, DeclareResultTrait, spy_events,
    EventSpyAssertionsTrait, EventSpyTrait, // Add for fetching events directly
    Event, // A structure describing a raw `Event`
    IsEmitted // Trait for checking if a given event was ever emitted
};
use starknet::ContractAddress;
use starknet::contract_address::contract_address_const;

const STRK_TOKEN_CONTRACT_ADDRESS: ContractAddress = FELT_STRK_CONTRACT.try_into().unwrap();
// Direcciones de prueba
const OWNER: ContractAddress = 0x02dA5254690b46B9C4059C25366D1778839BE63C142d899F0306fd5c312A5918
    .try_into()
    .unwrap();

const USER: ContractAddress = 0x02dA5254690b46B9C4059C25366D1778839BE63C142d899F0306fd5c312A5918
    .try_into()
    .unwrap();

const Initial_Fee_Percentage: u64 = 50; // 50 basis points = 0.5%
const BASIS_POINTS_DENOMINATOR: u256 = 10000_u256; // 10000 basis points = 100%

//helper function
fn owner_address_Sepolia() -> ContractAddress {
    OWNER
}
fn user_address_Sepolia() -> ContractAddress {
    USER
}
fn owner_address() -> ContractAddress {
    contract_address_const::<0x123>()
}

fn user_address() -> ContractAddress {
    contract_address_const::<0x456>()
}


fn USER1() -> ContractAddress {
    contract_address_const::<0x456>()
}


fn LARGE_AMOUNT() -> u256 {
    1000000000000000000000000_u256 // 1 million tokens (within mint limit)
}

fn MAX_MINT_LIMIT() -> u256 {
    // Definir el límite máximo exacto del contrato
    1000000000000000000000000_u256 // 1 million tokens (MAX_MINT_AMOUNT)
}

fn EXCEEDS_MINT_LIMIT() -> u256 {
    // Cantidad que excede el límite para provocar panic
    2000000000000000000000000_u256 // 2 million tokens (exceeds limit)
}

fn deploy_contract_lottery() -> ContractAddress {
    // Deploy mock contracts first
    let (vault, starkplay_token) = deploy_vault_contract();

    // Deploy Lottery with the mock contracts
    let lottery_contract = declare("Lottery").unwrap().contract_class();
    let lottery_constructor_calldata = array![
        owner_address().into(),
        starkplay_token.contract_address.into(),
        vault.contract_address.into(),
    ];
    let (lottery_address, _) = lottery_contract.deploy(@lottery_constructor_calldata).unwrap();
    lottery_address
}

fn deploy_mock_strk_token() -> IMintableDispatcher {
    // Deploy the mock STRK token at the exact constant address that the vault expects
    let target_address: ContractAddress =
        0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
        .try_into()
        .unwrap();

    let contract = declare("StarkPlayERC20").unwrap().contract_class();
    let constructor_calldata = array![owner_address().into(), owner_address().into()];

    // Deploy at the specific constant address that the vault expects
    let (deployed_address, _) = contract.deploy_at(@constructor_calldata, target_address).unwrap();

    // Verify it deployed at the correct address
    assert(deployed_address == target_address, 'Mock STRk address mismatch');

    // Set up the STRK token with initial balances for users
    let strk_token = IMintableDispatcher { contract_address: deployed_address };
    start_cheat_caller_address(deployed_address, owner_address());

    // Grant MINTER_ROLE to OWNER so we can mint tokens
    strk_token.grant_minter_role(owner_address());
    strk_token
        .set_minter_allowance(owner_address(), EXCEEDS_MINT_LIMIT().into() * 10); // Large allowance

    strk_token.mint(USER1(), EXCEEDS_MINT_LIMIT().into() * 3); // Mint plenty for testing

    stop_cheat_caller_address(deployed_address);

    strk_token
}

fn deploy_vault_contract() -> (IStarkPlayVaultDispatcher, IMintableDispatcher) {
    let initial_fee = 50_u64; // 50 basis points = 0.5%
    // First deploy the mock STRK token at the constant address
    let _strk_token = deploy_mock_strk_token();

    // Deploy StarkPlay token with OWNER as admin (so OWNER can grant roles)
    let starkplay_contract = declare("StarkPlayERC20").unwrap().contract_class();
    let starkplay_constructor_calldata = array![
        owner_address().into(), owner_address().into(),
    ]; // recipient and admin
    let (starkplay_address, _) = starkplay_contract
        .deploy(@starkplay_constructor_calldata)
        .unwrap();
    let starkplay_token = IMintableDispatcher { contract_address: starkplay_address };
    let starkplay_token_burn = IBurnableDispatcher { contract_address: starkplay_address };

    // Deploy vault (no longer needs STRK token address parameter)
    let vault_contract = declare("StarkPlayVault").unwrap().contract_class();
    let vault_constructor_calldata = array![
        owner_address().into(), starkplay_token.contract_address.into(), initial_fee.into(),
    ];
    let (vault_address, _) = vault_contract.deploy(@vault_constructor_calldata).unwrap();
    let vault = IStarkPlayVaultDispatcher { contract_address: vault_address };

    // Grant MINTER_ROLE and BURNER_ROLE to the vault so it can mint and burn StarkPlay tokens
    start_cheat_caller_address(starkplay_token.contract_address, owner_address());
    starkplay_token.grant_minter_role(vault_address);
    starkplay_token_burn.grant_burner_role(vault_address);
    // Set a large allowance for the vault to mint and burn tokens
    starkplay_token
        .set_minter_allowance(vault_address, EXCEEDS_MINT_LIMIT().into() * 10); // 1M tokens
    starkplay_token_burn
        .set_burner_allowance(vault_address, EXCEEDS_MINT_LIMIT().into() * 10); // 1M tokens
    stop_cheat_caller_address(starkplay_token.contract_address);

    (vault, starkplay_token)
}

fn deploy_vault_contract_with_fee(
    initial_fee: u64,
) -> (IStarkPlayVaultDispatcher, IMintableDispatcher) {
    //let initial_fee = 50_u64; // 50 basis points = 0.5%
    // First deploy the mock STRK token at the constant address
    let _strk_token = deploy_mock_strk_token();

    // Deploy StarkPlay token with OWNER as admin (so OWNER can grant roles)
    let starkplay_contract = declare("StarkPlayERC20").unwrap().contract_class();
    let starkplay_constructor_calldata = array![
        owner_address().into(), owner_address().into(),
    ]; // recipient and admin
    let (starkplay_address, _) = starkplay_contract
        .deploy(@starkplay_constructor_calldata)
        .unwrap();
    let starkplay_token = IMintableDispatcher { contract_address: starkplay_address };
    let starkplay_token_burn = IBurnableDispatcher { contract_address: starkplay_address };

    // Deploy vault (no longer needs STRK token address parameter)
    let vault_contract = declare("StarkPlayVault").unwrap().contract_class();
    let vault_constructor_calldata = array![
        owner_address().into(), starkplay_token.contract_address.into(), initial_fee.into(),
    ];
    let (vault_address, _) = vault_contract.deploy(@vault_constructor_calldata).unwrap();
    let vault = IStarkPlayVaultDispatcher { contract_address: vault_address };

    // Grant MINTER_ROLE and BURNER_ROLE to the vault so it can mint and burn StarkPlay tokens
    start_cheat_caller_address(starkplay_token.contract_address, owner_address());
    starkplay_token.grant_minter_role(vault_address);
    starkplay_token_burn.grant_burner_role(vault_address);
    // Set a large allowance for the vault to mint and burn tokens
    starkplay_token
        .set_minter_allowance(vault_address, EXCEEDS_MINT_LIMIT().into() * 10); // 1M tokens
    starkplay_token_burn
        .set_burner_allowance(vault_address, EXCEEDS_MINT_LIMIT().into() * 10); // 1M tokens
    stop_cheat_caller_address(starkplay_token.contract_address);

    (vault, starkplay_token)
}

//this function is used to deploy the vault with the lottery contract
//someone deleted the lottery contract from the vault constructor
fn deploy_contract_starkplayvault_with_Lottery() -> ContractAddress {
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


fn setup_user_balance(
    token: IMintableDispatcher, user: ContractAddress, amount: u256, vault_address: ContractAddress,
) {
    // Mint STRK tokens to user so they can pay
    // Set caller as owner (who has DEFAULT_ADMIN_ROLE and MINTER_ROLE)
    start_cheat_caller_address(token.contract_address, owner_address());

    // Ensure OWNER has MINTER_ROLE and allowance (should already be set, but just in case)
    token.grant_minter_role(owner_address());
    token.set_minter_allowance(owner_address(), EXCEEDS_MINT_LIMIT().into() * 10);

    // Mint tokens to user (still as owner)
    token.mint(user, amount);
    stop_cheat_caller_address(token.contract_address);

    // Set up allowance so vault can transfer STRK tokens from user
    let erc20_dispatcher = IERC20Dispatcher { contract_address: token.contract_address };
    start_cheat_caller_address(token.contract_address, user);
    erc20_dispatcher.approve(vault_address, amount);
    stop_cheat_caller_address(token.contract_address);
}


#[test]
fn test_get_fee_percentage_deploy() {
    let vault_address = deploy_contract_starkplayvault_with_Lottery();

    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };

    //check fee of buy starkplay is correct
    let fee_percentage = vault_dispatcher.GetFeePercentage();

    assert(fee_percentage == Initial_Fee_Percentage, 'Fee percentage should be 0.5%');
}

#[test]
fn test_calculate_fee_buy_numbers() {
    let vault_address = deploy_contract_starkplayvault_with_Lottery();

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
    let vault_address = deploy_contract_starkplayvault_with_Lottery();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    let new_fee = 0_u64;
    let _ = vault_dispatcher.setFeePercentage(new_fee);
}

//tests have to fail
#[should_panic(expected: 'Fee percentage is too high')]
#[test]
fn test_set_fee_max_like_501() {
    let vault_address = deploy_contract_starkplayvault_with_Lottery();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    let new_fee = 501_u64;
    let _result = vault_dispatcher.setFeePercentage(new_fee);
}

#[test]
fn test_set_fee_deploy_contract() {
    let vault_address = deploy_contract_starkplayvault_with_Lottery();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    let _ = 50_u64;
    let val = vault_dispatcher.GetFeePercentage();
    assert(val == 50_u64, 'Fee  should be 50');
}

#[test]
fn test_set_fee_min() {
    let vault_address = deploy_contract_starkplayvault_with_Lottery();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    let new_fee = 10_u64;
    let result = vault_dispatcher.setFeePercentage(new_fee);
    assert(result, 'Fee should be set');
    assert(vault_dispatcher.GetFeePercentage() == new_fee, 'Fee is not 10_u64');
}

#[test]
fn test_set_fee_max() {
    let vault_address = deploy_contract_starkplayvault_with_Lottery();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    let new_fee = 500_u64;
    let result = vault_dispatcher.setFeePercentage(new_fee);
    assert(result, 'Fee should be set');
    assert(vault_dispatcher.GetFeePercentage() == new_fee, 'Fee is not 500_u64');
}

#[test]
fn test_set_fee_middle() {
    let vault_address = deploy_contract_starkplayvault_with_Lottery();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    let new_fee = 250_u64;
    let result = vault_dispatcher.setFeePercentage(new_fee);
    assert(result, 'Fee should be set');
    assert(vault_dispatcher.GetFeePercentage() == new_fee, 'Fee is not 250_u64');
}

#[test]
fn test_event_set_fee_percentage() {
    let vault_address = deploy_contract_starkplayvault_with_Lottery();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    let new_fee = 250_u64;
    let mut spy = spy_events();

    let _ = vault_dispatcher.setFeePercentage(new_fee);

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
    assert!(
        total_accumulated == calculated_fee1 + calculated_fee2, "Accumulation should sum correctly",
    );
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
    let _ = IStarkPlayVaultDispatcher { contract_address: vault_address };

    let mut simulated_accumulated_fees = 0_u256;

    // First conversion: 1000 tokens with 5% fee
    let first_conversion_amount = 1000_u256;
    let first_fee = get_fee_amount(500_u64, first_conversion_amount); // 50 tokens
    simulated_accumulated_fees += first_fee;

    assert!(first_fee == 50_u256, "First conversion fee should be 50");
    assert!(
        simulated_accumulated_fees == 50_u256, "Accumulated should be 50 after first conversion",
    );

    // Second conversion: 2000 tokens with 5% fee
    let second_conversion_amount = 2000_u256;
    let second_fee = get_fee_amount(500_u64, second_conversion_amount); // 100 tokens
    simulated_accumulated_fees += second_fee;

    assert!(second_fee == 100_u256, "Second conversion fee should be 100");
    assert!(
        simulated_accumulated_fees == 150_u256, "Accumulated should be 150 after second conversion",
    );
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
        500_u256, // Small conversion
        1250_u256, // Medium conversion  
        3000_u256, // Large conversion
        750_u256, // Small conversion
        2200_u256 // Medium conversion
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
    }

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
    }

    assert!(running_total == total_accumulated, "Running total should match total accumulated");
}


//--------------TEST ISSUE-VAULT-HACK14-001------------------------------

//test set fee percentage prizes converted
#[test]
fn test_set_fee_percentage_prizes_converted() {
    let token_address = deploy_starkplay_token();
    let vault_address = deploy_vault_with_fee(token_address, 500_u64);
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };

    //test set fee percentage prizes converted
    let new_fee = 500_u64;
    let result = vault_dispatcher.setFeePercentagePrizesConverted(new_fee);
    assert!(result, "Set fee should return true");

    //test get fee percentage prizes converted
    let fee_percentage = vault_dispatcher.GetFeePercentagePrizesConverted();
    assert!(fee_percentage == new_fee, "Fee percentage  should be 5%");
}
#[should_panic(expected: 'Fee percentage is too high')]
#[test]
fn test_set_fee_percentage_prizes_converted_invalid_fee() {
    let token_address = deploy_starkplay_token();
    let vault_address = deploy_vault_with_fee(token_address, 500_u64);
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    //test set fee percentage prizes converted with invalid fee
    let new_fee = 501_u64;
    let result = vault_dispatcher.setFeePercentagePrizesConverted(new_fee);
    assert!(!result, "Set fee should return false");
}
#[test]
fn test_get_fee_percentage_prizes_in_constructor() {
    let token_address = deploy_starkplay_token();
    let vault_address = deploy_vault_with_fee(token_address, 500_u64);
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    //test get fee percentage prizes in constructor
    let fee_percentage = vault_dispatcher.GetFeePercentagePrizesConverted();
    assert!(fee_percentage == 300_u64, "Fee percentage should be 3%");
}


//Test for ISSUE-TEST-CU01-003

// ============================================================================================
// CRITICAL SECURITY TESTS - OVERFLOW/UNDERFLOW PREVENTION
// ============================================================================================

#[test]
//#[fork("SEPOLIA_LATEST")]
fn test_fee_calculation_overflow_prevention() {
    // Set up STRK balance for the user to test with large amounts
    let user_address = USER1();

    // Deploy vault
    let (vault, _) = deploy_vault_contract();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault.contract_address };

    // Set up amounts for testing overflow prevention (within mint limit)
    let large_amount = LARGE_AMOUNT(); // 1 million tokens
    let very_large_amount = MAX_MINT_LIMIT(); // Exact limit - 1 million tokens

    //---------------------------------------
    // let erc20_dispatcher = IERC20Dispatcher { contract_address: STRK_TOKEN_CONTRACT_ADDRESS };
    //let amount_to_transfer: u256 = very_large_amount;
    //cheat_caller_address(STRK_TOKEN_CONTRACT_ADDRESS, user_address, CheatSpan::TargetCalls(1));
    //erc20_dispatcher.approve(vault_address, amount_to_transfer);
    //let approved_amount = erc20_dispatcher.allowance(user_address, vault_address);
    //assert(approved_amount == amount_to_transfer, 'Not the right amount approved');
    //---------------------------------------

    // Get the deployed STRK token for user balance setup
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    // Setup user balance using the deployed STRK token
    setup_user_balance(strk_token, user_address, MAX_MINT_LIMIT() * 3, vault.contract_address);

    // Get initial state
    let initial_fee_percentage = vault_dispatcher.GetFeePercentage();
    let initial_accumulated_fee = vault_dispatcher.get_accumulated_fee();

    // Verify initial state
    assert(initial_fee_percentage > 0, 'fee percentage zero');
    assert(initial_accumulated_fee == 0, 'initial fee not zero');

    // Test buySTRKP with large amounts to ensure no overflow
    let result1 = vault_dispatcher.buySTRKP(user_address, large_amount);

    // Verify first transaction completed successfully
    assert(result1, 'first tx failed');

    // Check that fees were calculated correctly for large amounts
    let fee_percentage = vault_dispatcher.GetFeePercentage();
    let expected_fee = large_amount * fee_percentage.into() / 10000_u256;
    let actual_accumulated_fee = vault_dispatcher.get_accumulated_fee();

    // Verify fee calculation didn't overflow
    assert(actual_accumulated_fee > 0, 'fee not accumulated');
    assert(actual_accumulated_fee == expected_fee, 'fee calc wrong');

    // Test with even larger amount
    let result2 = vault_dispatcher.buySTRKP(user_address, large_amount.into());

    // Verify second transaction completed successfully
    assert(result2, 'second tx failed');

    // Verify final state after both transactions
    let final_accumulated_fee = vault_dispatcher.get_accumulated_fee();
    let expected_total_fee = expected_fee
        + (very_large_amount * fee_percentage.into() / 10000_u256);

    // Verify total accumulated fees are correct
    assert(final_accumulated_fee == expected_total_fee, 'total fee wrong');
    assert(final_accumulated_fee > actual_accumulated_fee, 'fee not increased');

    // Verify the contract is still functional after large operations
    let final_fee_percentage = vault_dispatcher.GetFeePercentage();
    assert(final_fee_percentage == initial_fee_percentage, 'fee percentage changed');
}


#[should_panic(expected: 'Exceeds mint limit')]
#[test]
fn test_fee_calculation_overflow_prevention_exceeds_limit() {
    let (vault, _) = deploy_vault_contract();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault.contract_address };

    // Set up STRK balance for the user to test with large amounts
    let user_address = USER1();

    // Get the deployed STRK token for user balance setup
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    // Setup user balance using the deployed STRK token
    setup_user_balance(strk_token, user_address, MAX_MINT_LIMIT() * 3, vault.contract_address);

    // Test buySTRKP with amount that exceeds mint limit
    // This should trigger a panic with "Exceeds mint limit"
    let _result = vault_dispatcher.buySTRKP(user_address, EXCEEDS_MINT_LIMIT());

    // This line should never be reached due to panic
    assert(false, 'Should have panicked');
}

#[test]
fn test_fee_calculation_underflow_prevention() {
    // Set up STRK balance for the user to test with large amounts
    let user_address = USER1();

    // Deploy vault
    let (vault, _) = deploy_vault_contract_with_fee(10_u64);
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault.contract_address };

    // Get the deployed STRK token for user balance setup
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    // Setup user balance using the deployed STRK token
    setup_user_balance(strk_token, user_address, MAX_MINT_LIMIT() * 3, vault.contract_address);

    // Get initial state
    let initial_fee_percentage = vault_dispatcher.GetFeePercentage();
    let initial_accumulated_fee = vault_dispatcher.get_accumulated_fee();

    // Verify initial state
    assert(initial_fee_percentage > 0, 'fee percentage zero');
    assert(initial_accumulated_fee == 0, 'initial fee not zero');

    // Test with very small amounts to prevent underflow
    let fee_percentage = 10_u64; // 0.1% fee (minimum allowed)

    // Test with 1 wei (smallest possible amount)
    let one_wei = 1_u256;
    let fee_for_one_wei = get_fee_amount(fee_percentage, one_wei);

    // With 0.1% fee on 1 wei: 1 * 10 / 10000 = 0 (rounded down)
    assert(fee_for_one_wei == 0_u256, 'should be 0 with 0.1% fee');

    // Test with 10 wei
    let ten_wei = 10_u256;
    let fee_for_ten_wei = get_fee_amount(fee_percentage, ten_wei);

    // With 0.1% fee on 10 wei: 10 * 10 / 10000 = 0 (rounded down)
    assert(fee_for_ten_wei == 0_u256, 'should be 0 with 0.1% fee');

    // Test with 100 wei
    let hundred_wei = 100_u256;
    let fee_for_hundred_wei = get_fee_amount(fee_percentage, hundred_wei);

    // With 0.1% fee on 100 wei: 100 * 10 / 10000 = 0 (rounded down)
    assert(fee_for_hundred_wei == 0_u256, 'should be 0 with 0.1% fee');

    // Test with 1000 wei (should generate a fee)
    let thousand_wei = 1000_u256;
    let fee_for_thousand_wei = get_fee_amount(fee_percentage, thousand_wei);

    // With 0.1% fee on 1000 wei: 1000 * 10 / 10000 = 1
    assert(fee_for_thousand_wei == 1_u256, 'should be 1 with 0.1% fee');

    // Verify that division doesn't cause underflow
    let minimum_amount_for_fee = 1000_u256;
    let fee_for_minimum = get_fee_amount(fee_percentage, minimum_amount_for_fee);
    assert(fee_for_minimum > 0, 'should generate a fee');

    // Test buySTRKP with small amounts to ensure no underflow
    let result1 = vault_dispatcher.buySTRKP(user_address, thousand_wei);

    // Verify first transaction completed successfully
    assert(result1, 'first tx failed');

    // Check that fees were calculated correctly for small amounts
    let actual_accumulated_fee = vault_dispatcher.get_accumulated_fee();

    // Verify fee calculation didn't underflow
    assert(actual_accumulated_fee > 0, 'fee not accumulated');
    assert(actual_accumulated_fee == fee_for_thousand_wei, 'fee calc wrong');

    // Test with another small amount
    let result2 = vault_dispatcher.buySTRKP(user_address, thousand_wei);

    // Verify second transaction completed successfully
    assert(result2, 'second tx failed');

    // Verify final state after both transactions
    let final_accumulated_fee = vault_dispatcher.get_accumulated_fee();
    let expected_total_fee = fee_for_thousand_wei + fee_for_thousand_wei;

    // Verify total accumulated fees are correct
    assert(final_accumulated_fee == expected_total_fee, 'total fee wrong');
    assert(final_accumulated_fee > actual_accumulated_fee, 'fee not increased');

    // Verify the contract is still functional after small operations
    let final_fee_percentage = vault_dispatcher.GetFeePercentage();
    assert(final_fee_percentage == initial_fee_percentage, 'fee percentage changed');
}


#[test]
fn test_decimal_precision_edge_cases() {
    // Set up STRK balance for the user to test with large amounts
    let user_address = USER1();

    // Deploy vault
    let (vault, _) = deploy_vault_contract();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault.contract_address };

    // Get the deployed STRK token for user balance setup
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    // Setup user balance using the deployed STRK token
    setup_user_balance(strk_token, user_address, MAX_MINT_LIMIT() * 3, vault.contract_address);

    // Get initial state
    let initial_fee_percentage = vault_dispatcher.GetFeePercentage();
    let initial_accumulated_fee = vault_dispatcher.get_accumulated_fee();

    // Verify initial state
    assert(initial_fee_percentage > 0, 'fee percentage zero');
    assert(initial_accumulated_fee == 0, 'initial fee not zero');

    // Test decimal precision with edge cases that could cause precision loss
    let fee_percentage = 50_u64; // 0.5% fee

    // Test with amount that results in 0.5 wei fee (edge case)
    // To get 0.5 wei fee: amount * 50 / 10000 = 0.5
    // This means: amount = 0.5 * 10000 / 50 = 100 wei
    let amount_for_half_wei = 100_u256;
    let fee_for_half_wei = get_fee_amount(fee_percentage, amount_for_half_wei);

    // Should round down to 0 wei
    assert(fee_for_half_wei == 0_u256, 'should round down for 0.5');

    // Test with amount that results in 1.5 wei fee
    // To get 1.5 wei fee: amount * 50 / 10000 = 1.5
    // This means: amount = 1.5 * 10000 / 50 = 300 wei
    let amount_for_one_and_half_wei = 300_u256;
    let fee_for_one_and_half_wei = get_fee_amount(fee_percentage, amount_for_one_and_half_wei);

    // Should round down to 1 wei
    assert(fee_for_one_and_half_wei == 1_u256, 'should round down for 1.5');

    // Test with amount that results in exactly 1 wei fee
    // To get exactly 1 wei fee: amount * 50 / 10000 = 1
    // This means: amount = 1 * 10000 / 50 = 200 wei
    let amount_for_exact_one_wei = 200_u256;
    let fee_for_exact_one_wei = get_fee_amount(fee_percentage, amount_for_exact_one_wei);

    // Should be exactly 1 wei
    assert(fee_for_exact_one_wei == 1_u256, 'should be exactly 1n');

    // Test with very small amounts that should result in zero fee
    let very_small_amounts = array![
        1_u256, // 1 wei
        10_u256, // 10 wei
        50_u256, // 50 wei
        99_u256 // 99 wei
    ];

    let mut i = 0;
    while i < very_small_amounts.len() {
        let amount = *very_small_amounts.at(i);
        let fee = get_fee_amount(fee_percentage, amount);
        assert(fee == 0_u256, 'should be zero fee');
        i += 1;
    }

    // Test with amounts that should result in non-zero fees
    let amounts_with_fees = array![
        200_u256, // Should give 1 wei fee
        400_u256, // Should give 2 wei fee
        600_u256, // Should give 3 wei fee
        1000_u256 // Should give 5 wei fee
    ];

    let expected_fees = array![
        1_u256, // For 200 wei
        2_u256, // For 400 wei
        3_u256, // For 600 wei
        5_u256 // For 1000 wei
    ];

    let mut j = 0;
    while j < amounts_with_fees.len() {
        let amount = *amounts_with_fees.at(j);
        let expected_fee = *expected_fees.at(j);
        let calculated_fee = get_fee_amount(fee_percentage, amount);
        assert(calculated_fee == expected_fee, 'should be precise');
        j += 1;
    }

    // Test buySTRKP with edge case amounts to ensure precision is maintained
    let result1 = vault_dispatcher.buySTRKP(user_address, amount_for_exact_one_wei);

    // Verify first transaction completed successfully
    assert(result1, 'first tx failed');

    // Check that fees were calculated correctly for edge case amounts
    let actual_accumulated_fee = vault_dispatcher.get_accumulated_fee();

    // Verify fee calculation maintained precision
    assert(actual_accumulated_fee > 0, 'fee not accumulated');
    assert(actual_accumulated_fee == fee_for_exact_one_wei, 'fee calc wrong');

    // Test with another edge case amount
    let result2 = vault_dispatcher.buySTRKP(user_address, amount_for_one_and_half_wei);

    // Verify second transaction completed successfully
    assert(result2, 'second tx failed');

    // Verify final state after both transactions
    let final_accumulated_fee = vault_dispatcher.get_accumulated_fee();
    let expected_total_fee = fee_for_exact_one_wei + fee_for_one_and_half_wei;

    // Verify total accumulated fees are correct
    assert(final_accumulated_fee == expected_total_fee, 'total fee wrong');
    assert(final_accumulated_fee > actual_accumulated_fee, 'fee not increased');

    // Verify the contract is still functional after edge case operations
    let final_fee_percentage = vault_dispatcher.GetFeePercentage();
    assert(final_fee_percentage == initial_fee_percentage, 'fee percentage changed');
}


// ============================================================================================
// ISSUE-TEST-007: TESTS CONVERTION 1:1 buySTRKP
// ============================================================================================

#[test]
fn test_conversion_1_1_basic() {
    // Test básico de conversión 1:1 después del fee
    let (vault, starkplay_token) = deploy_vault_contract();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault.contract_address };

    // Get the deployed STRK token for user balance setup
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    let user_address = USER1();
    let amount_strk = 1000000000000000000_u256; // 1 STRK (10^18 wei)

    // Setup user balance
    setup_user_balance(strk_token, user_address, LARGE_AMOUNT(), vault.contract_address);

    // Get initial $tarkPlay balance
    let erc20_dispatcher = IERC20Dispatcher { contract_address: starkplay_token.contract_address };
    let initial_starkplay_balance = erc20_dispatcher.balance_of(user_address);

    // Execute buySTRKP
    start_cheat_caller_address(vault.contract_address, user_address);
    let success = vault_dispatcher.buySTRKP(user_address, amount_strk);
    stop_cheat_caller_address(vault.contract_address);

    assert(success, 'buySTRKP should succeed');

    // Get final $tarkPlay balance
    let final_starkplay_balance = erc20_dispatcher.balance_of(user_address);
    let starkplay_minted = final_starkplay_balance - initial_starkplay_balance;

    // Calculate expected amount: 1 STRK - 0.5% fee = 0.995 STRK
    let fee_percentage = vault_dispatcher.GetFeePercentage();
    let expected_fee = (amount_strk * fee_percentage.into()) / 10000_u256;
    let expected_starkplay = amount_strk - expected_fee;

    // Verify conversion is 1:1 after fee deduction
    assert(starkplay_minted == expected_starkplay, 'Conver should be 1:1 after fee');
    assert(starkplay_minted == 995000000000000000_u256, 'Should receive 0.995 $tarkPlay');

    // Verify fee calculation
    assert(expected_fee == 5000000000000000_u256, 'Fee should be 0.005 STRK');
}

#[test]
fn test_conversion_1_1_different_amounts() {
    // Test con diferentes montos para verificar conversión 1:1
    let (vault, starkplay_token) = deploy_vault_contract();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault.contract_address };

    // Get the deployed STRK token for user balance setup
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    let user_address = USER1();
    let erc20_dispatcher = IERC20Dispatcher { contract_address: starkplay_token.contract_address };

    // Setup user balance
    setup_user_balance(strk_token, user_address, LARGE_AMOUNT(), vault.contract_address);

    // Test different amounts
    let test_amounts = array![
        1000000000000000000_u256, // 1 STRK
        10000000000000000000_u256, // 10 STRK
        100000000000000000000_u256 // 100 STRK
    ];

    let expected_results = array![
        995000000000000000_u256, // 0.995 $tarkPlay
        9950000000000000000_u256, // 9.95 $tarkPlay
        99500000000000000000_u256 // 99.5 $tarkPlay
    ];

    let mut i = 0;
    while i < test_amounts.len() {
        let amount_strk = *test_amounts.at(i);
        let expected_starkplay = *expected_results.at(i);

        // Get initial balance
        let initial_starkplay_balance = erc20_dispatcher.balance_of(user_address);

        // Execute buySTRKP
        start_cheat_caller_address(vault.contract_address, user_address);
        let success = vault_dispatcher.buySTRKP(user_address, amount_strk);
        stop_cheat_caller_address(vault.contract_address);

        assert(success, 'buySTRKP should succeed');

        // Get final balance and calculate minted amount
        let final_starkplay_balance = erc20_dispatcher.balance_of(user_address);
        let starkplay_minted = final_starkplay_balance - initial_starkplay_balance;

        // Verify conversion is 1:1 after fee deduction
        assert(starkplay_minted == expected_starkplay, 'Conver should be 1:1 after fee');

        i += 1;
    }
}


#[test]
fn test_conversion_1_1_precision() {
    // Test de precisión decimal en la conversión 1:1
    let (vault, starkplay_token) = deploy_vault_contract();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault.contract_address };

    // Get the deployed STRK token for user balance setup
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    let user_address = USER1();
    let erc20_dispatcher = IERC20Dispatcher { contract_address: starkplay_token.contract_address };

    // Setup user balance
    setup_user_balance(strk_token, user_address, LARGE_AMOUNT(), vault.contract_address);

    // Test edge cases with precision
    let precision_test_amounts = array![
        200_u256, // Should give exactly 1 wei fee (200 * 50 / 10000 = 1)
        300_u256, // Should give 1.5 wei fee, rounds down to 1
        400_u256, // Should give 2 wei fee
        1000_u256 // Should give 5 wei fee
    ];

    let expected_fees = array![
        1_u256, // 200 * 50 / 10000 = 1
        1_u256, // 300 * 50 / 10000 = 1.5, rounds down to 1
        2_u256, // 400 * 50 / 10000 = 2
        5_u256 // 1000 * 50 / 10000 = 5
    ];

    let mut i = 0;
    while i < precision_test_amounts.len() {
        let amount_strk = *precision_test_amounts.at(i);
        let expected_fee = *expected_fees.at(i);
        let expected_starkplay = amount_strk - expected_fee;

        // Get initial balance
        let initial_starkplay_balance = erc20_dispatcher.balance_of(user_address);

        // Execute buySTRKP
        start_cheat_caller_address(vault.contract_address, user_address);
        let success = vault_dispatcher.buySTRKP(user_address, amount_strk);
        stop_cheat_caller_address(vault.contract_address);

        assert(success, 'buySTRKP should succeed');

        // Get final balance and calculate minted amount
        let final_starkplay_balance = erc20_dispatcher.balance_of(user_address);
        let starkplay_minted = final_starkplay_balance - initial_starkplay_balance;

        // Verify precision is maintained
        assert(starkplay_minted == expected_starkplay, 'Precision should be maintained');

        i += 1;
    }
}


#[test]
fn test_user_balance_after_conversion() {
    // Verificar balance de $tarkPlay después de buySTRKP()
    let (vault, starkplay_token) = deploy_vault_contract();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault.contract_address };

    // Get the deployed STRK token for user balance setup
    let strk_token_address = 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
        .try_into()
        .unwrap();

    let strk_token = IMintableDispatcher { contract_address: strk_token_address };

    let strk_erc20_dispatcher = IERC20Dispatcher { contract_address: strk_token_address };

    let user_address = USER1();
    let erc20_dispatcher = IERC20Dispatcher { contract_address: starkplay_token.contract_address };

    // Setup user balance
    setup_user_balance(strk_token, user_address, LARGE_AMOUNT(), vault.contract_address);

    // Get initial balances
    let initial_strk_balance = strk_erc20_dispatcher.balance_of(user_address);
    let initial_starkplay_balance = erc20_dispatcher.balance_of(user_address);

    let amount_strk = 1000000000000000000_u256; // 1 STRK

    // Execute buySTRKP
    start_cheat_caller_address(vault.contract_address, user_address);
    let _ = vault_dispatcher.buySTRKP(user_address, amount_strk);
    stop_cheat_caller_address(vault.contract_address);

    let newBalance = strk_erc20_dispatcher.balance_of(user_address);
    assert(newBalance != initial_strk_balance, 'newBalance not changed');

    // Get final balances
    let final_strk_balance = strk_erc20_dispatcher.balance_of(user_address);
    let final_starkplay_balance = erc20_dispatcher.balance_of(user_address);

    // Calculate actual changes
    let strk_spent = initial_strk_balance - final_strk_balance;
    let starkplay_received = final_starkplay_balance - initial_starkplay_balance;

    // Verify STRK was spent correctly
    assert(strk_spent == amount_strk, 'STRK should be spent correctly');

    // Verify $tarkPlay was received correctly (1:1 conversion minus fee)
    let fee_percentage = vault_dispatcher.GetFeePercentage();
    let expected_fee = (amount_strk * fee_percentage.into()) / 10000_u256;
    let expected_starkplay = amount_strk - expected_fee;

    assert(starkplay_received == expected_starkplay, '$tarkPlay should be received');
    assert(starkplay_received == 995000000000000000_u256, 'Should receive 0.995 $tarkPlay');

    // Verify totalStarkPlayMinted was updated correctly
    let total_starkplay_minted = vault_dispatcher.get_total_starkplay_minted();
    assert(total_starkplay_minted == expected_starkplay, 'total Minted should be updated');
    assert(total_starkplay_minted == 995000000000000000_u256, 'total Minted should be 0.995');
}


fn test_1_1_conversion_consistency() {
    // Test de consistencia de conversión 1:1 en múltiples transacciones
    let (vault, starkplay_token) = deploy_vault_contract();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault.contract_address };

    // Get the deployed STRK token for user balance setup
    let strk_token_address = 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
        .try_into()
        .unwrap();

    let strk_token = IMintableDispatcher { contract_address: strk_token_address };

    let _ = IERC20Dispatcher { contract_address: strk_token_address };

    let user_address = USER1();
    let erc20_dispatcher = IERC20Dispatcher { contract_address: starkplay_token.contract_address };

    // Setup user balance
    setup_user_balance(strk_token, user_address, LARGE_AMOUNT(), vault.contract_address);

    let amount_strk = 1000000000000000000_u256; // 1 STRK
    let fee_percentage = vault_dispatcher.GetFeePercentage();
    let expected_fee = (amount_strk * fee_percentage.into()) / 10000_u256;
    let expected_starkplay_per_tx = amount_strk - expected_fee;

    // Execute multiple transactions
    let num_transactions = 5_u32;
    let mut total_starkplay_minted = 0_u256;

    let mut i = 0_u32;
    while i < num_transactions {
        // Get initial balance
        let initial_starkplay_balance = erc20_dispatcher.balance_of(user_address);

        // Execute buySTRKP
        start_cheat_caller_address(vault.contract_address, user_address);
        let success = vault_dispatcher.buySTRKP(user_address, amount_strk);
        stop_cheat_caller_address(vault.contract_address);

        assert(success, 'buySTRKP should succeed');

        // Get final balance and calculate minted amount
        let final_starkplay_balance = erc20_dispatcher.balance_of(user_address);
        let starkplay_minted = final_starkplay_balance - initial_starkplay_balance;

        // Verify each transaction maintains 1:1 conversion
        assert(starkplay_minted == expected_starkplay_per_tx, 'Each tran should maintain 1:1');

        total_starkplay_minted += starkplay_minted;

        i += 1;
    }

    // Verify total minted is consistent
    let expected_total_starkplay = expected_starkplay_per_tx * num_transactions.into();
    assert(total_starkplay_minted == expected_total_starkplay, 'Tot mint should be consistent');
    assert(total_starkplay_minted == 4975000000000000000_u256, 'Tot mint should be 4.975');

    let total_starkplay_minted2 = vault_dispatcher.get_total_starkplay_minted();
    assert(total_starkplay_minted2 == expected_total_starkplay, 'Tot mint should be consistent');
    assert(total_starkplay_minted2 == 4975000000000000000_u256, 'Tot mint should be 4.975');
}

// ============================================================================================
// ISSUE-BC-AUTH-002: Tests for mint and burn authorization in StarkPlayERC20
// ============================================================================================

fn deploy_starkplay_erc20_for_auth_tests() -> (IMintableDispatcher, IBurnableDispatcher) {
    let starkplay_contract = declare("StarkPlayERC20").unwrap().contract_class();
    let starkplay_constructor_calldata = array![
        owner_address().into(), owner_address().into(),
    ]; // recipient and admin
    let (starkplay_address, _) = starkplay_contract
        .deploy(@starkplay_constructor_calldata)
        .unwrap();

    let mintable_dispatcher = IMintableDispatcher { contract_address: starkplay_address };
    let burnable_dispatcher = IBurnableDispatcher { contract_address: starkplay_address };

    (mintable_dispatcher, burnable_dispatcher)
}

// ============================================================================================
// 1. ROLE MANAGEMENT TESTS
// ============================================================================================

#[test]
fn test_owner_can_grant_minter_role() {
    let (token, _) = deploy_starkplay_erc20_for_auth_tests();

    start_cheat_caller_address(token.contract_address, owner_address());

    // Grant MINTER_ROLE to a contract address
    token.grant_minter_role(user_address());

    // Verify the role was granted by checking if the address is in authorized minters
    let authorized_minters = token.get_authorized_minters();
    assert(authorized_minters.len() == 1, 'Should have 1 minter');
    assert(*authorized_minters.at(0) == user_address(), 'User should be minter');

    stop_cheat_caller_address(token.contract_address);
}

#[test]
fn test_owner_can_grant_burner_role() {
    let (_, token) = deploy_starkplay_erc20_for_auth_tests();

    start_cheat_caller_address(token.contract_address, owner_address());

    // Grant BURNER_ROLE to a contract address
    token.grant_burner_role(user_address());

    // Verify the role was granted by checking if the address is in authorized burners
    let authorized_burners = token.get_authorized_burners();
    assert(authorized_burners.len() == 1, 'Should have 1 burner');
    assert(*authorized_burners.at(0) == user_address(), 'User should be burner');

    stop_cheat_caller_address(token.contract_address);
}

#[test]
fn test_owner_can_revoke_minter_role() {
    let (token, _) = deploy_starkplay_erc20_for_auth_tests();

    start_cheat_caller_address(token.contract_address, owner_address());

    // First grant the role
    token.grant_minter_role(user_address());
    let authorized_minters = token.get_authorized_minters();
    assert(authorized_minters.len() == 1, 'Should have 1 minter');

    // Then revoke the role
    token.revoke_minter_role(user_address());
    let authorized_minters_after = token.get_authorized_minters();
    assert(authorized_minters_after.len() == 0, 'Should have 0 minters');

    stop_cheat_caller_address(token.contract_address);
}

#[test]
fn test_owner_can_revoke_burner_role() {
    let (_, token) = deploy_starkplay_erc20_for_auth_tests();

    start_cheat_caller_address(token.contract_address, owner_address());

    // First grant the role
    token.grant_burner_role(user_address());
    let authorized_burners = token.get_authorized_burners();
    assert(authorized_burners.len() == 1, 'Should have 1 burner');

    // Then revoke the role
    token.revoke_burner_role(user_address());
    let authorized_burners_after = token.get_authorized_burners();
    assert(authorized_burners_after.len() == 0, 'Should have 0 burners');

    stop_cheat_caller_address(token.contract_address);
}

#[should_panic(expected: 'Caller is missing role')]
#[test]
fn test_only_owner_can_grant_minter_role() {
    let (token, _) = deploy_starkplay_erc20_for_auth_tests();

    // Try to grant role as non-owner (should fail)
    start_cheat_caller_address(token.contract_address, user_address());
    token.grant_minter_role(USER1());
    stop_cheat_caller_address(token.contract_address);
}

#[should_panic(expected: 'Caller is missing role')]
#[test]
fn test_only_owner_can_grant_burner_role() {
    let (_, token) = deploy_starkplay_erc20_for_auth_tests();

    // Try to grant role as non-owner (should fail)
    start_cheat_caller_address(token.contract_address, user_address());
    token.grant_burner_role(USER1());
    stop_cheat_caller_address(token.contract_address);
}

#[should_panic(expected: 'Caller is missing role')]
#[test]
fn test_only_owner_can_revoke_minter_role() {
    let (token, _) = deploy_starkplay_erc20_for_auth_tests();

    // First grant role as owner
    start_cheat_caller_address(token.contract_address, owner_address());
    token.grant_minter_role(user_address());
    stop_cheat_caller_address(token.contract_address);

    // Try to revoke role as non-owner (should fail)
    start_cheat_caller_address(token.contract_address, user_address());
    token.revoke_minter_role(user_address());
    stop_cheat_caller_address(token.contract_address);
}

#[should_panic(expected: 'Caller is missing role')]
#[test]
fn test_only_owner_can_revoke_burner_role() {
    let (_, token) = deploy_starkplay_erc20_for_auth_tests();

    // First grant role as owner
    start_cheat_caller_address(token.contract_address, owner_address());
    token.grant_burner_role(user_address());
    stop_cheat_caller_address(token.contract_address);

    // Try to revoke role as non-owner (should fail)
    start_cheat_caller_address(token.contract_address, user_address());
    token.revoke_burner_role(user_address());
    stop_cheat_caller_address(token.contract_address);
}

// ============================================================================================
// 2. AUTHORIZED CONTRACT OPERATION TESTS
// ============================================================================================

#[test]
fn test_authorized_contract_can_mint() {
    let (token, _) = deploy_starkplay_erc20_for_auth_tests();
    let erc20_dispatcher = IERC20Dispatcher { contract_address: token.contract_address };

    // Setup: Owner grants MINTER_ROLE and sets allowance
    start_cheat_caller_address(token.contract_address, owner_address());
    token.grant_minter_role(user_address());
    token.set_minter_allowance(user_address(), LARGE_AMOUNT());
    stop_cheat_caller_address(token.contract_address);

    // Get initial balance
    let initial_balance = erc20_dispatcher.balance_of(USER1());

    // Authorized contract mints tokens
    start_cheat_caller_address(token.contract_address, user_address());
    token.mint(USER1(), 1000_u256);
    stop_cheat_caller_address(token.contract_address);

    // Verify mint was successful
    let final_balance = erc20_dispatcher.balance_of(USER1());
    assert(final_balance == initial_balance + 1000_u256, 'Mint should succeed');
}

#[test]
fn test_authorized_contract_can_burn() {
    let (mint_token, burn_token) = deploy_starkplay_erc20_for_auth_tests();
    let erc20_dispatcher = IERC20Dispatcher { contract_address: mint_token.contract_address };

    // Setup: Owner grants roles and sets allowances
    start_cheat_caller_address(mint_token.contract_address, owner_address());
    mint_token.grant_minter_role(owner_address());
    mint_token.set_minter_allowance(owner_address(), LARGE_AMOUNT());
    burn_token.grant_burner_role(user_address());
    burn_token.set_burner_allowance(user_address(), LARGE_AMOUNT());

    // Mint some tokens first
    mint_token.mint(user_address(), 2000_u256);
    stop_cheat_caller_address(mint_token.contract_address);

    // Get initial balance
    let initial_balance = erc20_dispatcher.balance_of(user_address());
    assert(initial_balance >= 2000_u256, 'Should have tokens to burn');

    // Authorized contract burns tokens
    start_cheat_caller_address(burn_token.contract_address, user_address());
    burn_token.burn(1000_u256);
    stop_cheat_caller_address(burn_token.contract_address);

    // Verify burn was successful
    let final_balance = erc20_dispatcher.balance_of(user_address());
    assert(final_balance == initial_balance - 1000_u256, 'Burn should succeed');
}

#[should_panic(expected: 'Caller is missing role')]
#[test]
fn test_unauthorized_contract_cannot_mint() {
    let (token, _) = deploy_starkplay_erc20_for_auth_tests();

    // Try to mint without MINTER_ROLE (should fail)
    start_cheat_caller_address(token.contract_address, user_address());
    token.mint(USER1(), 1000_u256);
    stop_cheat_caller_address(token.contract_address);
}

#[should_panic(expected: 'Caller is missing role')]
#[test]
fn test_unauthorized_contract_cannot_burn() {
    let (_, token) = deploy_starkplay_erc20_for_auth_tests();

    // Try to burn without BURNER_ROLE (should fail)
    start_cheat_caller_address(token.contract_address, user_address());
    token.burn(1000_u256);
    stop_cheat_caller_address(token.contract_address);
}

#[should_panic(expected: 'Caller is missing role')]
#[test]
fn test_minter_cannot_burn_without_burner_role() {
    let (mint_token, burn_token) = deploy_starkplay_erc20_for_auth_tests();

    // Setup: Grant only MINTER_ROLE to user_address
    start_cheat_caller_address(mint_token.contract_address, owner_address());
    mint_token.grant_minter_role(user_address());
    mint_token.set_minter_allowance(user_address(), LARGE_AMOUNT());
    stop_cheat_caller_address(mint_token.contract_address);

    // Try to burn without BURNER_ROLE (should fail)
    start_cheat_caller_address(burn_token.contract_address, user_address());
    burn_token.burn(1000_u256);
    stop_cheat_caller_address(burn_token.contract_address);
}

// ============================================================================================
// 3. SECURITY TESTS - MINT/BURN LIMITS AND ALLOWANCES
// ============================================================================================

#[should_panic(expected: 'Insufficient minter allowance')]
#[test]
fn test_mint_limit_enforcement() {
    let (token, _) = deploy_starkplay_erc20_for_auth_tests();

    // Setup: Grant role but set low allowance
    start_cheat_caller_address(token.contract_address, owner_address());
    token.grant_minter_role(user_address());
    token.set_minter_allowance(user_address(), 500_u256); // Low allowance
    stop_cheat_caller_address(token.contract_address);

    // Try to mint more than allowance (should fail)
    start_cheat_caller_address(token.contract_address, user_address());
    token.mint(USER1(), 1000_u256); // Exceeds allowance
    stop_cheat_caller_address(token.contract_address);
}

#[should_panic(expected: 'Insufficient burner allowance')]
#[test]
fn test_burn_limit_enforcement() {
    let (mint_token, burn_token) = deploy_starkplay_erc20_for_auth_tests();

    // Setup: Grant roles and mint tokens first
    start_cheat_caller_address(mint_token.contract_address, owner_address());
    mint_token.grant_minter_role(owner_address());
    mint_token.set_minter_allowance(owner_address(), LARGE_AMOUNT());
    burn_token.grant_burner_role(user_address());
    burn_token.set_burner_allowance(user_address(), 500_u256); // Low allowance
    mint_token.mint(user_address(), 2000_u256);
    stop_cheat_caller_address(mint_token.contract_address);

    // Try to burn more than allowance (should fail)
    start_cheat_caller_address(burn_token.contract_address, user_address());
    burn_token.burn(1000_u256); // Exceeds allowance
    stop_cheat_caller_address(burn_token.contract_address);
}

#[test]
fn test_allowance_decreases_after_mint() {
    let (token, _) = deploy_starkplay_erc20_for_auth_tests();

    // Setup: Grant role and set allowance
    start_cheat_caller_address(token.contract_address, owner_address());
    token.grant_minter_role(user_address());
    token.set_minter_allowance(user_address(), 1000_u256);
    stop_cheat_caller_address(token.contract_address);

    // Check initial allowance
    let initial_allowance = token.get_minter_allowance(user_address());
    assert(initial_allowance == 1000_u256, 'Initial allowance incorrect');

    // Mint tokens
    start_cheat_caller_address(token.contract_address, user_address());
    token.mint(USER1(), 300_u256);
    stop_cheat_caller_address(token.contract_address);

    // Check allowance decreased
    let final_allowance = token.get_minter_allowance(user_address());
    assert(final_allowance == 700_u256, 'Allowance should decrease');
}

#[test]
fn test_allowance_decreases_after_burn() {
    let (mint_token, burn_token) = deploy_starkplay_erc20_for_auth_tests();

    // Setup: Grant roles and mint tokens first
    start_cheat_caller_address(mint_token.contract_address, owner_address());
    mint_token.grant_minter_role(owner_address());
    mint_token.set_minter_allowance(owner_address(), LARGE_AMOUNT());
    burn_token.grant_burner_role(user_address());
    burn_token.set_burner_allowance(user_address(), 1000_u256);
    mint_token.mint(user_address(), 2000_u256);
    stop_cheat_caller_address(mint_token.contract_address);

    // Check initial burn allowance
    let initial_allowance = burn_token.get_burner_allowance(user_address());
    assert(initial_allowance == 1000_u256, 'Initial allowance incorrect');

    // Burn tokens
    start_cheat_caller_address(burn_token.contract_address, user_address());
    burn_token.burn(300_u256);
    stop_cheat_caller_address(burn_token.contract_address);

    // Check allowance decreased
    let final_allowance = burn_token.get_burner_allowance(user_address());
    assert(final_allowance == 700_u256, 'Allowance should decrease');
}

// ============================================================================================
// 4. INTEGRATION TESTS WITH STARKPLAYVAULT
// ============================================================================================

#[test]
fn test_vault_integration_with_mint_role() {
    // Deploy vault which should automatically get MINTER_ROLE
    let (vault, starkplay_token) = deploy_vault_contract();

    // Verify vault has MINTER_ROLE
    let authorized_minters = starkplay_token.get_authorized_minters();
    let mut vault_is_minter = false;
    let mut i = 0;
    while i != authorized_minters.len() {
        if *authorized_minters.at(i) == vault.contract_address {
            vault_is_minter = true;
            break;
        }
        i += 1;
    }
    assert(vault_is_minter, 'Vault should have MINTER_ROLE');

    // Verify vault has sufficient allowance
    let minter_allowance = starkplay_token.get_minter_allowance(vault.contract_address);
    assert(minter_allowance > 0, 'Vault should have allowance');
}

#[test]
fn test_vault_integration_with_burn_role() {
    // Deploy vault which should automatically get BURNER_ROLE
    let (vault, starkplay_token_mint) = deploy_vault_contract();
    let starkplay_token_burn = IBurnableDispatcher {
        contract_address: starkplay_token_mint.contract_address,
    };

    // Verify vault has BURNER_ROLE
    let authorized_burners = starkplay_token_burn.get_authorized_burners();
    let mut vault_is_burner = false;
    let mut i = 0;
    while i != authorized_burners.len() {
        if *authorized_burners.at(i) == vault.contract_address {
            vault_is_burner = true;
            break;
        }
        i += 1;
    }
    assert(vault_is_burner, 'Vault should have BURNER_ROLE');

    // Verify vault has sufficient burn allowance
    let burner_allowance = starkplay_token_burn.get_burner_allowance(vault.contract_address);
    assert(burner_allowance > 0, 'Vault has burn allowance');
}

#[test]
fn test_multiple_authorized_contracts() {
    let (token_mint, token_burn) = deploy_starkplay_erc20_for_auth_tests();

    // Setup: Grant roles to multiple contracts
    start_cheat_caller_address(token_mint.contract_address, owner_address());
    token_mint.grant_minter_role(user_address());
    token_mint.grant_minter_role(USER1());
    token_mint.set_minter_allowance(user_address(), LARGE_AMOUNT());
    token_mint.set_minter_allowance(USER1(), LARGE_AMOUNT());

    token_burn.grant_burner_role(user_address());
    token_burn.grant_burner_role(USER1());
    token_burn.set_burner_allowance(user_address(), LARGE_AMOUNT());
    token_burn.set_burner_allowance(USER1(), LARGE_AMOUNT());
    stop_cheat_caller_address(token_mint.contract_address);

    // Verify both contracts are authorized
    let authorized_minters = token_mint.get_authorized_minters();
    assert(authorized_minters.len() == 2, 'Should have 2 minters');

    let authorized_burners = token_burn.get_authorized_burners();
    assert(authorized_burners.len() == 2, 'Should have 2 burners');

    // Both should be able to mint
    start_cheat_caller_address(token_mint.contract_address, user_address());
    token_mint.mint(owner_address(), 1000_u256);
    stop_cheat_caller_address(token_mint.contract_address);

    start_cheat_caller_address(token_mint.contract_address, USER1());
    token_mint.mint(owner_address(), 1000_u256);
    stop_cheat_caller_address(token_mint.contract_address);
}
