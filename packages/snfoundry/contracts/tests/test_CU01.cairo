use contracts::StarkPlayERC20::{
    IBurnableDispatcher, IBurnableDispatcherTrait, IMintableDispatcher, IMintableDispatcherTrait,
};
use contracts::StarkPlayVault::StarkPlayVault::FELT_STRK_CONTRACT;
use contracts::StarkPlayVault::{
    IStarkPlayVault, IStarkPlayVaultDispatcher, IStarkPlayVaultDispatcherTrait, StarkPlayVault,
};
use openzeppelin_access::ownable::interface::{IOwnableDispatcher, IOwnableDispatcherTrait};
use openzeppelin_testing::declare_and_deploy;
use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use openzeppelin_utils::serde::SerializedAppend;
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyTrait, declare, load, spy_events,
    start_cheat_caller_address, stop_cheat_caller_address, store, test_address,
};
#[feature("deprecated-starknet-consts")]
use starknet::{ContractAddress, contract_address_const};

const STRK_TOKEN_CONTRACT_ADDRESS: ContractAddress = FELT_STRK_CONTRACT.try_into().unwrap();
// Test addresses
const OWNER: ContractAddress = 0x02dA5254690b46B9C4059C25366D1778839BE63C142d899F0306fd5c312A5918
    .try_into()
    .unwrap();

const USER: ContractAddress = 0x02dA5254690b46B9C4059C25366D1778839BE63C142d899F0306fd5c312A5918
    .try_into()
    .unwrap();

const Initial_Fee_Percentage: u64 = 50; // 50 basis points = 0.5%
const BASIS_POINTS_DENOMINATOR: u256 = 10000_u256; // 10000 basis points = 100%

// Specific function for test_starkplay_vault.cairo tests (equivalent to OWNER() from original file)
fn VAULT_OWNER() -> ContractAddress {
    contract_address_const::<0x123>()
}

//helper function
fn owner_address_Sepolia() -> ContractAddress {
    OWNER
}
fn user_address_Sepolia() -> ContractAddress {
    USER
}
fn owner_address() -> ContractAddress {
    0x123.try_into().unwrap()
}

fn user_address() -> ContractAddress {
    0x456.try_into().unwrap()
}


fn USER1() -> ContractAddress {
    0x456.try_into().unwrap()
}

fn USER2() -> ContractAddress {
    contract_address_const::<0x789>()
}

fn USER3() -> ContractAddress {
    contract_address_const::<0xABC>()
}


fn LARGE_AMOUNT() -> u256 {
    1000000000000000000000000_u256 // 1 million tokens (within mint limit)
}

fn MAX_MINT_LIMIT() -> u256 {
    // Define the exact maximum limit of the contract
    1000000000000000000000000_u256 // 1 million tokens (MAX_MINT_AMOUNT)
}

fn EXCEEDS_MINT_LIMIT() -> u256 {
    // Amount that exceeds the limit to trigger panic
    2000000000000000000000000_u256 // 2 million tokens (exceeds limit)
}

// Constants from test_mint_strk_play.cairo
const MAX_MINT_AMOUNT: u256 = 1_000_000 * 1_000_000_000_000_000_000;

// Constants from test_starkplay_balance.cairo
const BALANCE_FEE_PERCENT: u256 = 5_u256;

// Constants from test_starkplay_vault.cairo
const VAULT_LARGE_AMOUNT: u256 = 10000000000000000000_u256; // 10 STRK (same value as in original)
const VAULT_PURCHASE_AMOUNT: u256 =
    1000000000000000000_u256; // 1 STRK (same value as PURCHASE_AMOUNT in original)

// Constants from test_starkplayvault.cairo
const VAULT_MAX_MINT_AMOUNT: u256 = 1_000_000 * 1_000_000_000_000_000_000; // 1 million tokens
const VAULT_MAX_BURN_AMOUNT: u256 = 1_000_000 * 1_000_000_000_000_000_000; // 1 million tokens

// Addresses equivalent to those used in test_starkplay_balance.cairo
fn BALANCE_OWNER() -> ContractAddress {
    'OWNER'.try_into().unwrap()
}

fn BALANCE_USER() -> ContractAddress {
    'USER'.try_into().unwrap()
}

fn BALANCE_USER2() -> ContractAddress {
    'USER2'.try_into().unwrap()
}

// Helper functions from test_mint_strk_play.cairo
fn setup_contracts() -> (ContractAddress, ContractAddress) {
    let starkplay_token = deploy_starkplay_token();
    let vault = deploy_starkplay_vault(starkplay_token);
    (vault, starkplay_token)
}

fn setup_minting_permissions(vault: ContractAddress, starkplay_token: ContractAddress) {
    let token_dispatcher = IMintableDispatcher { contract_address: starkplay_token };
    start_cheat_caller_address(starkplay_token, owner_address());
    token_dispatcher.grant_minter_role(vault);
    stop_cheat_caller_address(starkplay_token);

    start_cheat_caller_address(starkplay_token, owner_address());
    token_dispatcher.set_minter_allowance(vault, MAX_MINT_AMOUNT);
    stop_cheat_caller_address(starkplay_token);
}


fn deploy_starkplay_vault(starkplay_token: ContractAddress) -> ContractAddress {
    let owner = owner_address();
    let initial_fee = Initial_Fee_Percentage;
    let mut calldata = array![];

    calldata.append_serde(owner);
    calldata.append_serde(starkplay_token);
    calldata.append_serde(initial_fee);

    declare_and_deploy("StarkPlayVault", calldata)
}

// Helper functions from test_starkplay_balance.cairo
fn expected_minted_balance(strk_amount: u256, fee_percent: u256) -> u256 {
    let fee = (strk_amount * fee_percent) / 100_u256;
    strk_amount - fee
}

fn deploy_erc20_balance() -> ContractAddress {
    let mut constructor_calldata = array![];

    let erc20_class = declare("StarkPlayERC20").unwrap().contract_class();

    // Constructor expects: (recipient: ContractAddress, admin: ContractAddress)
    BALANCE_OWNER().serialize(ref constructor_calldata); // recipient
    BALANCE_OWNER().serialize(ref constructor_calldata); // admin

    // Deploy ERC20
    let (erc20_addr, _) = erc20_class.deploy(@constructor_calldata).unwrap();

    erc20_addr
}

fn deploy_vault_balance() -> (ContractAddress, ContractAddress) {
    let mut constructor_calldata = array![];

    let erc20_addr = deploy_erc20_balance();

    let vault_class = declare("StarkPlayVault").unwrap().contract_class();

    // Constructor expects: (owner: ContractAddress, starkPlayToken: ContractAddress, feePercentage:
    // u64)
    BALANCE_OWNER().serialize(ref constructor_calldata); // owner
    erc20_addr.serialize(ref constructor_calldata); // starkPlayToken
    let fee_percent: u64 = 5;
    fee_percent.serialize(ref constructor_calldata); // feePercentage (convert u256 to u64)

    let (vault_addr, _) = vault_class.deploy(@constructor_calldata).unwrap();

    (vault_addr, erc20_addr)
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

fn get_expected_fee_amount(amount_strk: u256, fee_percentage: u64) -> u256 {
    (amount_strk * fee_percentage.into()) / 10000
}

// Helper functions from test_starkplayvault.cairo
fn deploy_vault_basic() -> IStarkPlayVaultDispatcher {
    let contract = declare("StarkPlayVault").unwrap().contract_class();
    let owner: ContractAddress = VAULT_OWNER();
    let token: ContractAddress = 'token'.try_into().unwrap();
    let fee_percentage: u128 = 10000;

    let mut constructor_calldata = array![];
    owner.serialize(ref constructor_calldata);
    token.serialize(ref constructor_calldata);
    fee_percentage.serialize(ref constructor_calldata);

    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    let dispatcher = IStarkPlayVaultDispatcher { contract_address };
    dispatcher
}

fn init_vault_basic() -> StarkPlayVault::ContractState {
    let mut state = StarkPlayVault::contract_state_for_testing();
    StarkPlayVault::constructor(
        ref state,
        VAULT_OWNER(), // owner
        'token'.try_into().unwrap(), // starkplay_token
        10000 // fee percentage
    );
    state
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

    let ownable = IOwnableDispatcher { contract_address: vault_address };
    start_cheat_caller_address(vault_address, ownable.owner());
    let _ = vault_dispatcher.setFeePercentage(new_fee);
    stop_cheat_caller_address(vault_address);
}

//tests have to fail
#[should_panic(expected: 'Fee percentage is too high')]
#[test]
fn test_set_fee_max_like_501() {
    let vault_address = deploy_contract_starkplayvault_with_Lottery();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    let new_fee = 501_u64;

    let ownable = IOwnableDispatcher { contract_address: vault_address };
    start_cheat_caller_address(vault_address, ownable.owner());
    let _result = vault_dispatcher.setFeePercentage(new_fee);
    stop_cheat_caller_address(vault_address);
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

    let ownable = IOwnableDispatcher { contract_address: vault_address };
    start_cheat_caller_address(vault_address, ownable.owner());
    let result = vault_dispatcher.setFeePercentage(new_fee);
    stop_cheat_caller_address(vault_address);

    assert(result, 'Fee should be set');
    assert(vault_dispatcher.GetFeePercentage() == new_fee, 'Fee is not 10_u64');
}

#[test]
fn test_set_fee_max() {
    let vault_address = deploy_contract_starkplayvault_with_Lottery();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    let new_fee = 500_u64;

    let ownable = IOwnableDispatcher { contract_address: vault_address };
    start_cheat_caller_address(vault_address, ownable.owner());
    let result = vault_dispatcher.setFeePercentage(new_fee);
    stop_cheat_caller_address(vault_address);

    assert(result, 'Fee should be set');
    assert(vault_dispatcher.GetFeePercentage() == new_fee, 'Fee is not 500_u64');
}

#[test]
fn test_set_fee_middle() {
    let vault_address = deploy_contract_starkplayvault_with_Lottery();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    let new_fee = 250_u64;

    let ownable = IOwnableDispatcher { contract_address: vault_address };
    start_cheat_caller_address(vault_address, ownable.owner());
    let result = vault_dispatcher.setFeePercentage(new_fee);
    stop_cheat_caller_address(vault_address);

    assert(result, 'Fee should be set');
    assert(vault_dispatcher.GetFeePercentage() == new_fee, 'Fee is not 250_u64');
}

#[test]
fn test_event_set_fee_percentage() {
    let vault_address = deploy_contract_starkplayvault_with_Lottery();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    let new_fee = 250_u64;
    let mut spy = spy_events();

    let ownable = IOwnableDispatcher { contract_address: vault_address };
    start_cheat_caller_address(vault_address, ownable.owner());
    let _ = vault_dispatcher.setFeePercentage(new_fee);
    stop_cheat_caller_address(vault_address);

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

    let ownable = IOwnableDispatcher { contract_address: vault_address };
    start_cheat_caller_address(vault_address, ownable.owner());
    let result = vault_dispatcher.setFeePercentagePrizesConverted(new_fee);
    stop_cheat_caller_address(vault_address);

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

    let ownable = IOwnableDispatcher { contract_address: vault_address };
    start_cheat_caller_address(vault_address, ownable.owner());
    let result = vault_dispatcher.setFeePercentagePrizesConverted(new_fee);
    stop_cheat_caller_address(vault_address);

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
    // Basic 1:1 conversion test after fee
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
    // Test with different amounts to verify 1:1 conversion
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
    // Test decimal precision in 1:1 conversion
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
    // Verify $tarkPlay balance after buySTRKP()
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
    // Test 1:1 conversion consistency in multiple transactions
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

// ============================================================================================
// INTEGRATED TESTS FROM test_mint_strk_play.cairo
// ============================================================================================

#[test]
fn test_contract_deployment() {
    let (vault, _starkplay_token) = setup_contracts();

    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault };

    let fee_percentage = vault_dispatcher.GetFeePercentage();
    assert(fee_percentage == Initial_Fee_Percentage, 'Fee percentage incorrect');
}


#[test]
fn test_imintable_dispatcher_integration() {
    let (vault, starkplay_token) = setup_contracts();
    setup_minting_permissions(vault, starkplay_token);
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault };
    let token_dispatcher = IMintableDispatcher { contract_address: starkplay_token };

    let authorized_minters = token_dispatcher.get_authorized_minters();
    assert(authorized_minters.len() > 0, 'Should have authorized minters');

    let vault_allowance = token_dispatcher.get_minter_allowance(vault);
    assert(vault_allowance > 0, 'Vault should have allowance');

    let mint_amount = 500_u256;
    start_cheat_caller_address(starkplay_token, vault);
    vault_dispatcher.mint_strk_play(user_address(), mint_amount);
    stop_cheat_caller_address(starkplay_token);

    let erc20_dispatcher = IERC20Dispatcher { contract_address: starkplay_token };
    let total_supply = erc20_dispatcher.total_supply();
    assert(total_supply >= mint_amount, 'Total supply incorrect');
}


#[test]
fn test_minting_limits() {
    let (vault, starkplay_token) = setup_contracts();
    setup_minting_permissions(vault, starkplay_token);

    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault };

    start_cheat_caller_address(starkplay_token, vault);
    vault_dispatcher.mint_strk_play(user_address(), MAX_MINT_AMOUNT);
    stop_cheat_caller_address(starkplay_token);

    let erc20_dispatcher = IERC20Dispatcher { contract_address: starkplay_token };
    let total_supply = erc20_dispatcher.total_supply();
    assert(total_supply >= MAX_MINT_AMOUNT, 'Total supply incorrect');
}


#[should_panic(expected: 'Insufficient minter allowance')]
#[test]
fn test_minting_limits_exceeded() {
    let (vault, starkplay_token) = setup_contracts();
    setup_minting_permissions(vault, starkplay_token);

    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault };

    let excessive_amount = MAX_MINT_AMOUNT + 1_u256;

    start_cheat_caller_address(starkplay_token, vault);
    vault_dispatcher.mint_strk_play(user_address(), excessive_amount);
    stop_cheat_caller_address(starkplay_token);
}

#[should_panic(expected: 'Caller is missing role')]
#[test]
fn test_unauthorized_minting() {
    let (vault, starkplay_token) = setup_contracts();
    setup_minting_permissions(vault, starkplay_token);

    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault };

    start_cheat_caller_address(starkplay_token, user_address());
    vault_dispatcher.mint_strk_play(user_address(), 1000_u256);
    stop_cheat_caller_address(starkplay_token);
}

#[test]
fn test_multiple_minting_operations() {
    let (vault, starkplay_token) = setup_contracts();
    setup_minting_permissions(vault, starkplay_token);

    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault };

    let erc20_dispatcher = IERC20Dispatcher { contract_address: starkplay_token };
    let initial_supply = erc20_dispatcher.total_supply();
    let mut total_minted = 0_u256;

    let mint_amounts = array![100_u256, 200_u256, 300_u256, 400_u256, 500_u256];

    for mint_amount in mint_amounts {
        start_cheat_caller_address(starkplay_token, vault);
        vault_dispatcher.mint_strk_play(user_address(), mint_amount);
        stop_cheat_caller_address(starkplay_token);

        total_minted += mint_amount;
    }

    let final_supply = erc20_dispatcher.total_supply();
    assert(final_supply >= initial_supply + total_minted, 'Total supply incorrect');
}

#[test]
fn test_zero_amount_minting() {
    let (vault, starkplay_token) = setup_contracts();
    setup_minting_permissions(vault, starkplay_token);

    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault };

    let erc20_dispatcher = IERC20Dispatcher { contract_address: starkplay_token };
    let initial_supply = erc20_dispatcher.total_supply();

    start_cheat_caller_address(starkplay_token, vault);
    vault_dispatcher.mint_strk_play(user_address(), 0_u256);
    stop_cheat_caller_address(starkplay_token);

    let final_supply = erc20_dispatcher.total_supply();
    assert(final_supply == initial_supply, 'Supply should remain unchanged');
}


#[test]
fn test_minting_event_emission() {
    let (vault, starkplay_token) = setup_contracts();
    setup_minting_permissions(vault, starkplay_token);

    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault };

    let mut spy = spy_events();

    let mint_amount = 1000_u256;
    start_cheat_caller_address(starkplay_token, vault);
    vault_dispatcher.mint_strk_play(user_address(), mint_amount);
    stop_cheat_caller_address(starkplay_token);

    let events = spy.get_events();
    assert(events.events.len() > 0, 'Should emit events');
}

#[test]
fn test_fee_percentage_management() {
    let (vault, _starkplay_token) = setup_contracts();

    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault };

    let new_fee = 100_u64;

    let ownable = IOwnableDispatcher { contract_address: vault };
    start_cheat_caller_address(vault, ownable.owner());
    let result = vault_dispatcher.setFeePercentage(new_fee);
    stop_cheat_caller_address(vault);

    assert(result == true, 'Fee percentage not set');

    let updated_fee = vault_dispatcher.GetFeePercentage();
    assert(updated_fee == new_fee, 'Fee percentage not updated');
}


#[should_panic(expected: 'Fee percentage is too low')]
#[test]
fn test_fee_percentage_too_low() {
    let (vault, _starkplay_token) = setup_contracts();

    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault };

    let low_fee = 5_u64;

    let ownable = IOwnableDispatcher { contract_address: vault };
    start_cheat_caller_address(vault, ownable.owner());
    vault_dispatcher.setFeePercentage(low_fee);
    stop_cheat_caller_address(vault);
}


#[should_panic(expected: 'Fee percentage is too high')]
#[test]
fn test_fee_percentage_too_high() {
    let (vault, _starkplay_token) = setup_contracts();

    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault };

    let high_fee = 600_u64;

    let ownable = IOwnableDispatcher { contract_address: vault };
    start_cheat_caller_address(vault, ownable.owner());
    vault_dispatcher.setFeePercentage(high_fee);
    stop_cheat_caller_address(vault);
}

// ============================================================================================
// INTEGRATED TESTS FROM test_starkplay_balance.cairo
// ============================================================================================

#[test]
fn test_basic_balance_increment() {
    let (vault_addr, erc20_addr) = deploy_vault_balance();

    // Grant minter role and allowance to vault
    // Need to impersonate the OWNER to call admin functions
    start_cheat_caller_address(erc20_addr, BALANCE_OWNER());
    let erc20_disp = IMintableDispatcher { contract_address: erc20_addr };

    erc20_disp.grant_minter_role(vault_addr);
    erc20_disp.set_minter_allowance(vault_addr, 1000_000_000_000_000_000_000_000_u256);
    stop_cheat_caller_address(erc20_addr);

    // Initial balance
    let token_disp = IERC20Dispatcher { contract_address: erc20_addr };
    let initial = token_disp.balance_of(BALANCE_USER());
    assert(initial == 0, 'Initial balance should be 0');

    // Mint via vault (simulate buySTRKP)
    let amount = 100_000_000_000_000_000_000_u256; // 100 STRK
    let minted = expected_minted_balance(amount, BALANCE_FEE_PERCENT);
    // Simulate: vault calls mint on ERC20 to user with calculated amount
    // This test directly calls mint on the ERC20 dispatcher for simplicity,
    // assuming the vault would perform a similar call internally.

    start_cheat_caller_address(erc20_addr, vault_addr);
    erc20_disp.mint(BALANCE_USER(), minted);
    stop_cheat_caller_address(erc20_addr);

    let after = token_disp.balance_of(BALANCE_USER());
    assert!(after == minted, "Final balance should match minted");
}

#[test]
fn test_multiple_cumulative_purchases() {
    let (vault_addr, erc20_addr) = deploy_vault_balance();

    start_cheat_caller_address(erc20_addr, BALANCE_OWNER());
    // Grant minter role and allowance to vault
    let erc20_disp = IMintableDispatcher { contract_address: erc20_addr };
    erc20_disp.grant_minter_role(vault_addr);
    erc20_disp.set_minter_allowance(vault_addr, 1000_000_000_000_000_000_000_000_u256);
    stop_cheat_caller_address(erc20_addr);

    let token_disp = IERC20Dispatcher { contract_address: erc20_addr };
    let mut total = 0_u256;
    let amounts = array![
        100_000_000_000_000_000_000_u256,
        200_000_000_000_000_000_000_u256,
        50_000_000_000_000_000_000_u256,
    ];
    let mut i = 0;
    loop {
        if i >= amounts.len() {
            break;
        }
        let amt = *amounts.at(i);
        let minted = expected_minted_balance(amt, BALANCE_FEE_PERCENT);
        start_cheat_caller_address(erc20_addr, vault_addr);
        erc20_disp.mint(BALANCE_USER(), minted); // Simulate minting to user
        total += minted;
        let bal = token_disp.balance_of(BALANCE_USER());
        assert(bal == total, 'Cumulative balance should match');
        i += 1;
        stop_cheat_caller_address(erc20_addr);
    }
}

#[test]
fn test_decimal_precision() {
    let (vault_addr, erc20_addr) = deploy_vault_balance();

    start_cheat_caller_address(erc20_addr, BALANCE_OWNER());
    // Grant minter role and allowance to vault
    let erc20_disp = IMintableDispatcher { contract_address: erc20_addr };
    erc20_disp.grant_minter_role(vault_addr);
    erc20_disp.set_minter_allowance(vault_addr, 1000_000_000_000_000_000_000_u256);
    stop_cheat_caller_address(erc20_addr);

    let token_disp = IERC20Dispatcher { contract_address: erc20_addr };
    let amount = 1_000_000_000_000_000_000_u256; // 1 STRK
    let minted = expected_minted_balance(amount, BALANCE_FEE_PERCENT);
    start_cheat_caller_address(erc20_addr, vault_addr);
    erc20_disp.mint(BALANCE_USER(), minted); // Simulate minting to user
    stop_cheat_caller_address(erc20_addr);
    let bal = token_disp.balance_of(BALANCE_USER());
    assert!(
        bal == 950_000_000_000_000_000_u256, "Should receive exactly 0.95 $tarkPlay",
    ); // Adjusted expected value

    let small = 1_000_000_000_000_000_u256; // 0.001 STRK
    let small_minted = expected_minted_balance(small, BALANCE_FEE_PERCENT);
    start_cheat_caller_address(erc20_addr, vault_addr);
    erc20_disp.mint(BALANCE_USER(), small_minted); // Simulate minting to user
    stop_cheat_caller_address(erc20_addr);
    let bal2 = token_disp.balance_of(BALANCE_USER());
    // Previous balance (0.95) + new minted (0.00095) = 0.95095
    assert!(
        bal2 == 950_950_000_000_000_000_u256, "Should accumulate with precision",
    ); // Adjusted expected value
}

#[test]
fn test_data_integrity_multiple_users() {
    let (vault_addr, erc20_addr) = deploy_vault_balance();

    start_cheat_caller_address(erc20_addr, BALANCE_OWNER());
    // Grant minter role and allowance to vault
    let erc20_disp = IMintableDispatcher { contract_address: erc20_addr };
    erc20_disp.grant_minter_role(vault_addr);
    erc20_disp.set_minter_allowance(vault_addr, 1000_000_000_000_000_000_000_000_u256);
    stop_cheat_caller_address(erc20_addr);

    start_cheat_caller_address(erc20_addr, vault_addr);
    let token_disp = IERC20Dispatcher { contract_address: erc20_addr };
    let amt1 = 100_000_000_000_000_000_000_u256;
    let amt2 = 50_000_000_000_000_000_000_u256;

    // Mint to different users
    erc20_disp
        .mint(
            BALANCE_USER(), expected_minted_balance(amt1, BALANCE_FEE_PERCENT),
        ); // Simulate minting to user1
    erc20_disp
        .mint(
            BALANCE_USER2(), expected_minted_balance(amt2, BALANCE_FEE_PERCENT),
        ); // Simulate minting to user2
    stop_cheat_caller_address(erc20_addr);

    // Check individual balances
    let bal1 = token_disp.balance_of(BALANCE_USER());
    let bal2 = token_disp.balance_of(BALANCE_USER2());

    // Expected minted for amt1: 100 * 0.95 = 95
    assert(bal1 == 95_000_000_000_000_000_000_u256, 'User1 should have 95');

    // Expected minted for amt2: 50 * 0.95 = 47.5
    assert(bal2 == 47_500_000_000_000_000_000_u256, 'User2 should have 47.5');
}

// Helper functions from test_starkplay_vault.cairo
fn get_expected_minted_amount(amount_strk: u256, fee_percentage: u64) -> u256 {
    let fee = (amount_strk * fee_percentage.into()) / 10000;
    amount_strk - fee
}

fn deploy_starkplay_token_vault() -> IMintableDispatcher {
    // Deploy the StarkPlay token that the vault will mint to users
    let contract = declare("StarkPlayERC20").unwrap().contract_class();
    let constructor_calldata = array![owner_address().into(), owner_address().into()];
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    IMintableDispatcher { contract_address }
}

fn deploy_vault_contract_vault() -> (IStarkPlayVaultDispatcher, IMintableDispatcher) {
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
        owner_address().into(),
        starkplay_token.contract_address.into(),
        Initial_Fee_Percentage.into(),
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

fn setup_user_balance_vault(
    token: IMintableDispatcher, user: ContractAddress, amount: u256, vault_address: ContractAddress,
) {
    // Mint STRK tokens to user so they can pay
    start_cheat_caller_address(token.contract_address, owner_address());

    // Ensure OWNER has MINTER_ROLE and allowance (should already be set, but just in case)
    token.grant_minter_role(owner_address());
    token.set_minter_allowance(owner_address(), EXCEEDS_MINT_LIMIT().into() * 10);

    token.mint(user, amount);
    stop_cheat_caller_address(token.contract_address);

    // Set up allowance so vault can transfer STRK tokens from user
    let erc20_dispatcher = IERC20Dispatcher { contract_address: token.contract_address };
    start_cheat_caller_address(token.contract_address, user);
    erc20_dispatcher.approve(vault_address, amount * 10); // Approve 10x the amount to be safe
    stop_cheat_caller_address(token.contract_address);
}

// ============================================================================================
// INTEGRATED TESTS FROM test_starkplay_vault.cairo
// ============================================================================================

#[test]
fn test_sequential_fee_consistency() {
    let (vault, _) = deploy_vault_contract_vault();
    let purchase_amount = VAULT_PURCHASE_AMOUNT; // 1 STRK
    let expected_fee = get_fee_amount(Initial_Fee_Percentage, purchase_amount);

    // Get the deployed STRK token for user balance setup
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    // Setup user balance using the deployed STRK token
    setup_user_balance_vault(strk_token, USER1(), LARGE_AMOUNT(), vault.contract_address);

    // Execute 10 consecutive transactions
    let mut i = 0;
    let mut expected_accumulated_fee = 0;

    while i != 10_u64 {
        let initial_accumulated_fee = vault.get_accumulated_fee();

        // Execute transaction - don't cheat caller address, let vault be the caller to mint
        let success = vault.buySTRKP(USER1(), VAULT_PURCHASE_AMOUNT);

        assert(success, 'Transaction should succeed');

        // Verify fee consistency
        let new_accumulated_fee = vault.get_accumulated_fee();
        let actual_fee = new_accumulated_fee - initial_accumulated_fee;

        assert(actual_fee == expected_fee, 'Fee should be consistent');

        expected_accumulated_fee += expected_fee;
        assert(new_accumulated_fee == expected_accumulated_fee, 'Accumulated fee incorrect');

        i += 1;
    }

    // Final verification
    assert(vault.get_accumulated_fee() == expected_fee * 10, 'Final accumulated fee incorrect');
}

#[test]
fn test_fee_calculation_accuracy() {
    let (vault, _) = deploy_vault_contract_vault();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    // Test different amounts
    let amounts = array![
        1000000000000000000_u256, // 1 STRK
        5000000000000000000_u256, // 5 STRK
        10000000000000000000_u256, // 10 STRK
        100000000000000000000_u256 // 100 STRK
    ];

    setup_user_balance_vault(
        strk_token, USER1(), 1000000000000000000000_u256, vault.contract_address,
    ); // 1000 STRK

    let mut i = 0;
    let mut total_expected_fee = 0;

    while i != amounts.len() {
        let amount = *amounts.at(i);
        let expected_fee = get_fee_amount(Initial_Fee_Percentage, amount);

        let initial_accumulated_fee = vault.get_accumulated_fee();

        let success = vault.buySTRKP(USER1(), amount);
        assert(success, 'Transaction should succeed');

        let actual_fee = vault.get_accumulated_fee() - initial_accumulated_fee;
        assert(actual_fee == expected_fee, 'Fee calculation incorrect');

        total_expected_fee += expected_fee;
        i += 1;
    }

    assert(vault.get_accumulated_fee() == total_expected_fee, 'fee accumulation incorrect');
}

#[test]
fn test_multiple_users_fee_consistency() {
    let (vault, _) = deploy_vault_contract_vault();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };
    let purchase_amount = VAULT_PURCHASE_AMOUNT; // 1 STRK
    let expected_fee = get_fee_amount(Initial_Fee_Percentage, purchase_amount);

    // Setup balances for multiple users
    setup_user_balance_vault(strk_token, USER1(), VAULT_LARGE_AMOUNT, vault.contract_address);
    setup_user_balance_vault(strk_token, USER2(), VAULT_LARGE_AMOUNT, vault.contract_address);
    setup_user_balance_vault(strk_token, USER3(), VAULT_LARGE_AMOUNT, vault.contract_address);

    let users = array![USER1(), USER2(), USER3()];
    let mut i = 0;
    let mut expected_accumulated_fee = 0;

    while i != users.len() {
        let user = *users.at(i);
        let initial_accumulated_fee = vault.get_accumulated_fee();

        // Each user makes a purchase
        let success = vault.buySTRKP(user, VAULT_PURCHASE_AMOUNT);

        assert(success, 'Transaction should succeed');

        // Verify fee is consistent for each user
        let actual_fee = vault.get_accumulated_fee() - initial_accumulated_fee;
        assert(actual_fee == expected_fee, 'Fee should be same for all');

        expected_accumulated_fee += expected_fee;
        assert(
            vault.get_accumulated_fee() == expected_accumulated_fee, 'Accumulated fee incorrect',
        );

        i += 1;
    }
}

#[test]
fn test_concurrent_transactions_simulation() {
    let (vault, _) = deploy_vault_contract_vault();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };
    let purchase_amount = VAULT_PURCHASE_AMOUNT; // 1 STRK
    let expected_fee = get_fee_amount(Initial_Fee_Percentage, purchase_amount);

    // Setup balances
    setup_user_balance_vault(strk_token, USER1(), VAULT_LARGE_AMOUNT, vault.contract_address);
    setup_user_balance_vault(strk_token, USER2(), VAULT_LARGE_AMOUNT, vault.contract_address);
    setup_user_balance_vault(strk_token, USER3(), VAULT_LARGE_AMOUNT, vault.contract_address);

    let users = array![USER1(), USER2(), USER3()];
    let mut fees_collected = ArrayTrait::new();

    // Simulate concurrent transactions by executing them in rapid succession
    let mut i = 0;
    while i != users.len() {
        let user = *users.at(i);
        let initial_fee = vault.get_accumulated_fee();

        start_cheat_caller_address(vault.contract_address, user);
        vault.buySTRKP(user, VAULT_PURCHASE_AMOUNT);
        stop_cheat_caller_address(vault.contract_address);

        let fee_collected = vault.get_accumulated_fee() - initial_fee;
        fees_collected.append(fee_collected);

        i += 1;
    }

    // Verify all fees are identical
    let first_fee = *fees_collected.at(0);
    let mut j = 1;
    while j != fees_collected.len() {
        assert(*fees_collected.at(j) == first_fee, 'Fees should be identical');
        j += 1;
    }

    assert(first_fee == expected_fee, 'Fee must be consistent');
}

#[test]
fn test_fee_consistency_after_pause_unpause() {
    let (vault, _) = deploy_vault_contract_vault();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };
    let purchase_amount = VAULT_PURCHASE_AMOUNT; // 1 STRK
    let expected_fee = get_fee_amount(Initial_Fee_Percentage, purchase_amount);

    setup_user_balance_vault(strk_token, USER1(), VAULT_LARGE_AMOUNT, vault.contract_address);

    // First transaction before pause
    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), purchase_amount);
    stop_cheat_caller_address(vault.contract_address);

    let fee_before_pause = vault.get_accumulated_fee();
    assert(fee_before_pause == expected_fee, 'Fee before pause incorrect');

    // Pause the contract
    let ownable = IOwnableDispatcher { contract_address: vault.contract_address };
    start_cheat_caller_address(vault.contract_address, ownable.owner());
    vault.pause();
    stop_cheat_caller_address(vault.contract_address);

    assert(vault.is_paused(), 'Contract should be paused');

    // Unpause the contract
    start_cheat_caller_address(vault.contract_address, ownable.owner());
    vault.unpause();
    stop_cheat_caller_address(vault.contract_address);

    assert(!vault.is_paused(), 'Contract must be unpaused');

    let fee_after_unpause = vault.get_accumulated_fee();
    assert(fee_after_unpause == expected_fee, 'Fee after unpause incorrect');

    // Transaction after unpause
    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), purchase_amount);
    stop_cheat_caller_address(vault.contract_address);

    let fee_after_unpause = vault.get_accumulated_fee();
    assert(fee_after_unpause == expected_fee * 2, 'Fee must be consistent');

    // Verify fee percentage remains the same
    assert(vault.GetFeePercentage() == Initial_Fee_Percentage, 'percentage changed');
}

#[should_panic(expected: 'Contract is paused')]
#[test]
fn test_transaction_fails_when_paused() {
    let (vault, _) = deploy_vault_contract_vault();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    setup_user_balance_vault(strk_token, USER1(), VAULT_LARGE_AMOUNT, vault.contract_address);

    // Pause the contract
    let ownable = IOwnableDispatcher { contract_address: vault.contract_address };
    start_cheat_caller_address(vault.contract_address, ownable.owner());
    vault.pause();
    stop_cheat_caller_address(vault.contract_address);

    assert(vault.is_paused(), 'Contract must be paused');

    // Try to make a transaction - should fail
    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), LARGE_AMOUNT());
    stop_cheat_caller_address(vault.contract_address);
}

#[test]
fn test_fee_accumulation_multiple_users() {
    let (vault, _) = deploy_vault_contract_vault();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };
    let purchase_amount = VAULT_PURCHASE_AMOUNT; // 1 STRK
    let expected_fee_per_tx = get_fee_amount(Initial_Fee_Percentage, purchase_amount);

    // Setup balances
    setup_user_balance_vault(strk_token, USER1(), VAULT_LARGE_AMOUNT, vault.contract_address);
    setup_user_balance_vault(strk_token, USER2(), VAULT_LARGE_AMOUNT, vault.contract_address);
    setup_user_balance_vault(strk_token, USER3(), VAULT_LARGE_AMOUNT, vault.contract_address);

    let users = array![USER1(), USER2(), USER3()];
    let transactions_per_user = 3;

    let mut total_expected_fee = 0;
    let mut user_index = 0;

    while user_index != users.len() {
        let user = *users.at(user_index);
        let mut tx_count = 0;

        while tx_count != transactions_per_user {
            start_cheat_caller_address(vault.contract_address, user);
            vault.buySTRKP(user, VAULT_PURCHASE_AMOUNT);
            stop_cheat_caller_address(vault.contract_address);

            total_expected_fee += expected_fee_per_tx;
            assert(vault.get_accumulated_fee() == total_expected_fee, 'Fee must be consistent');

            tx_count += 1;
        }

        user_index += 1;
    }

    // Verify total fees collected
    let total_transactions = users.len() * transactions_per_user;
    let expected_total_fee = expected_fee_per_tx * total_transactions.into();
    assert(vault.get_accumulated_fee() == expected_total_fee, 'fee accumulation incorrect');
}

#[should_panic(expected: 'Amount must be greater than 0')]
#[test]
fn test_zero_amount_transaction() {
    let (vault, _) = deploy_vault_contract_vault();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    setup_user_balance_vault(strk_token, USER1(), VAULT_LARGE_AMOUNT, vault.contract_address);

    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), 0_u256);
    stop_cheat_caller_address(vault.contract_address);
}

#[test]
fn test_complete_flow_integration() {
    let (vault, _) = deploy_vault_contract_vault();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };
    // Setup multiple users
    setup_user_balance_vault(strk_token, USER1(), VAULT_LARGE_AMOUNT, vault.contract_address);
    setup_user_balance_vault(strk_token, USER2(), VAULT_LARGE_AMOUNT, vault.contract_address);

    let expected_fee = get_fee_amount(Initial_Fee_Percentage, VAULT_PURCHASE_AMOUNT);

    // Initial state
    assert(vault.get_accumulated_fee() == 0, 'Initial fee must be 0');
    assert(vault.GetFeePercentage() == Initial_Fee_Percentage, 'percentage must be initial');

    // Multiple transactions
    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), VAULT_PURCHASE_AMOUNT);
    stop_cheat_caller_address(vault.contract_address);

    assert(vault.get_accumulated_fee() == expected_fee, 'Fee after first transaction');

    start_cheat_caller_address(vault.contract_address, USER2());
    vault.buySTRKP(USER2(), VAULT_PURCHASE_AMOUNT);
    stop_cheat_caller_address(vault.contract_address);

    assert(vault.get_accumulated_fee() == expected_fee * 2, 'Fee after second transaction');

    // Pause and unpause
    let ownable = IOwnableDispatcher { contract_address: vault.contract_address };
    start_cheat_caller_address(vault.contract_address, ownable.owner());
    vault.pause();
    vault.unpause();
    stop_cheat_caller_address(vault.contract_address);

    // Transaction after pause/unpause
    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), VAULT_PURCHASE_AMOUNT);
    stop_cheat_caller_address(vault.contract_address);

    assert(vault.get_accumulated_fee() == expected_fee * 3, 'Fee after pause/unpause');

    // Verify fee percentage remains consistent
    assert(vault.GetFeePercentage() == Initial_Fee_Percentage, 'percentage changed');
}

// ============================================================================================
// WITHDRAWAL TESTS
// ============================================================================================

#[test]
fn test_withdraw_general_fees_success() {
    let (vault, _) = deploy_vault_contract_vault();
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };
    setup_user_balance_vault(strk_token, USER1(), VAULT_LARGE_AMOUNT, vault.contract_address);

    let expected_fee = get_fee_amount(Initial_Fee_Percentage, VAULT_PURCHASE_AMOUNT);
    // User buys STRKP, fee is accumulated
    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), VAULT_PURCHASE_AMOUNT);
    stop_cheat_caller_address(vault.contract_address);
    assert(vault.get_accumulated_fee() == expected_fee, 'Fee not accumulated');
    // Owner withdraws fee
    let ownable = IOwnableDispatcher { contract_address: vault.contract_address };
    let owner = ownable.owner();
    let recipient = USER2();
    let erc20 = IERC20Dispatcher { contract_address: strk_token.contract_address };
    let initial_recipient_balance = erc20.balance_of(recipient);

    start_cheat_caller_address(vault.contract_address, owner);
    let success = vault.withdrawGeneralFees(recipient, expected_fee);
    stop_cheat_caller_address(vault.contract_address);
    assert(success, 'Withdraw should succeed');
    assert(vault.get_accumulated_fee() == 0, 'Fee not decremented');
    let new_recipient_balance = erc20.balance_of(recipient);
    assert(
        new_recipient_balance - initial_recipient_balance == expected_fee, 'STRK not transferred',
    );
}

#[should_panic(expected: 'Caller is not the owner')]
#[test]
fn test_withdraw_general_fees_not_owner() {
    let (vault, starkplay) = deploy_vault_contract_vault();
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };
    setup_user_balance_vault(strk_token, USER1(), VAULT_LARGE_AMOUNT, vault.contract_address);
    setup_user_balance_vault(starkplay, USER1(), VAULT_LARGE_AMOUNT, vault.contract_address);

    let expected_fee = get_fee_amount(Initial_Fee_Percentage, VAULT_PURCHASE_AMOUNT);
    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), VAULT_PURCHASE_AMOUNT);
    stop_cheat_caller_address(vault.contract_address);
    // Not owner tries to withdraw
    start_cheat_caller_address(vault.contract_address, USER1());
    vault.withdrawGeneralFees(USER2(), expected_fee);
    stop_cheat_caller_address(vault.contract_address);
}

#[should_panic(expected: 'Withdraw amount exceeds fees')]
#[test]
fn test_withdraw_general_fees_exceeds_accumulated() {
    let (vault, _) = deploy_vault_contract_vault();
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };
    setup_user_balance_vault(strk_token, USER1(), VAULT_LARGE_AMOUNT, vault.contract_address);

    let expected_fee = get_fee_amount(Initial_Fee_Percentage, VAULT_PURCHASE_AMOUNT);
    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), VAULT_PURCHASE_AMOUNT);
    stop_cheat_caller_address(vault.contract_address);
    // Owner tries to withdraw more than accumulated
    let ownable = IOwnableDispatcher { contract_address: vault.contract_address };
    let owner = ownable.owner();
    start_cheat_caller_address(vault.contract_address, owner);
    vault.withdrawGeneralFees(USER2(), expected_fee + 1_u256);
    stop_cheat_caller_address(vault.contract_address);
}

#[should_panic(expected: 'Amount must be > 0')]
#[test]
fn test_withdraw_general_fees_zero_amount() {
    let (vault, _) = deploy_vault_contract_vault();
    let ownable = IOwnableDispatcher { contract_address: vault.contract_address };
    let owner = ownable.owner();
    start_cheat_caller_address(vault.contract_address, owner);
    vault.withdrawGeneralFees(USER2(), 0_u256);
    stop_cheat_caller_address(vault.contract_address);
}

#[should_panic(expected: 'Insufficient STRK in vault')]
#[test]
fn test_withdraw_general_fees_insufficient_vault_balance() {
    let (vault, _) = deploy_vault_contract_vault();
    let ownable = IOwnableDispatcher { contract_address: vault.contract_address };
    let owner = ownable.owner();

    // Manually increment accumulatedFee without STRK in vault

    start_cheat_caller_address(vault.contract_address, owner);

    // load existing value from storage
    let loaded = load(
        vault.contract_address, // an existing contract which owns the storage
        selector!("accumulatedFee"), // field marking the start of the memory chunk being read from
        1 // length of the memory chunk (seen as an array of felts) to read
    );

    assert_eq!(loaded, array![0_felt252], "Initial accumulatedFee should be 0");

    // Simulate fee accumulation without STRK

    store(
        vault.contract_address, // storage owner
        selector!("accumulatedFee"), // field marking the start of the memory chunk being written to
        array![5000].span() // array of felts to write
    );

    // load again and check if it changed
    let loaded = load(vault.contract_address, selector!("accumulatedFee"), 1);

    assert_eq!(loaded, array![5000]);

    vault.withdrawGeneralFees(USER2(), 100_u256);

    stop_cheat_caller_address(vault.contract_address);
}

#[test]
fn test_withdraw_prize_conversion_fees_success() {
    let (vault, _starkplay_token) = deploy_vault_contract_vault();
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    setup_user_balance_vault(strk_token, USER1(), VAULT_LARGE_AMOUNT, vault.contract_address);
    let convert_amount = VAULT_LARGE_AMOUNT;
    let prizeFeeAmount = get_fee_amount(Initial_Fee_Percentage, convert_amount);

    // Manually increment accumulatedPrizeConversionFees to simulate conversion
    let ownable = IOwnableDispatcher { contract_address: vault.contract_address };
    let owner = ownable.owner();
    start_cheat_caller_address(vault.contract_address, owner);

    // Use storage manipulation to set accumulated prize conversion fees
    store(
        vault.contract_address,
        selector!("accumulatedPrizeConversionFees"),
        array![prizeFeeAmount.low.into(), prizeFeeAmount.high.into()].span(),
    );

    // Mint STRK tokens to vault so it can pay withdrawal
    start_cheat_caller_address(strk_token.contract_address, owner_address());
    strk_token.mint(vault.contract_address, VAULT_LARGE_AMOUNT);
    stop_cheat_caller_address(strk_token.contract_address);

    // Verify fee was set
    assert(vault.GetAccumulatedPrizeConversionFees() == prizeFeeAmount, 'Fee not set');

    // Test withdrawal
    let recipient = USER2();
    let erc20 = IERC20Dispatcher { contract_address: strk_token.contract_address };
    let initial_recipient_balance = erc20.balance_of(recipient);

    start_cheat_caller_address(vault.contract_address, owner);
    let success = vault.withdrawPrizeConversionFees(recipient, prizeFeeAmount);
    stop_cheat_caller_address(vault.contract_address);

    assert(success, 'Withdraw should succeed');
    assert(vault.GetAccumulatedPrizeConversionFees() == 0, 'Prize fee not decremented');
    let new_recipient_balance = erc20.balance_of(recipient);
    assert(
        new_recipient_balance - initial_recipient_balance == prizeFeeAmount, 'STRK not transferred',
    );
}

#[should_panic(expected: 'Caller is not the owner')]
#[test]
fn test_withdraw_prize_conversion_fees_not_owner() {
    let (vault, _) = deploy_vault_contract_vault();

    // Use storage manipulation to set accumulated prize conversion fees
    let fee_amount = 100_u256;
    store(
        vault.contract_address,
        selector!("accumulatedPrizeConversionFees"),
        array![fee_amount.low.into(), fee_amount.high.into()].span(),
    );

    // Not owner tries to withdraw
    start_cheat_caller_address(vault.contract_address, USER1());
    vault.withdrawPrizeConversionFees(USER2(), fee_amount);
    stop_cheat_caller_address(vault.contract_address);
}

#[should_panic(expected: 'Withdraw amount exceeds fees')]
#[test]
fn test_withdraw_prize_conversion_fees_exceeds_accumulated() {
    let (vault, _) = deploy_vault_contract_vault();
    let ownable = IOwnableDispatcher { contract_address: vault.contract_address };
    let owner = ownable.owner();

    // Use storage manipulation to set accumulated prize conversion fees
    let fee_amount = 50_u256;
    store(
        vault.contract_address,
        selector!("accumulatedPrizeConversionFees"),
        array![fee_amount.low.into(), fee_amount.high.into()].span(),
    );

    start_cheat_caller_address(vault.contract_address, owner);
    vault.withdrawPrizeConversionFees(USER2(), 51_u256);
    stop_cheat_caller_address(vault.contract_address);
}

#[should_panic(expected: 'Amount must be > 0')]
#[test]
fn test_withdraw_prize_conversion_fees_zero_amount() {
    let (vault, _) = deploy_vault_contract_vault();
    let ownable = IOwnableDispatcher { contract_address: vault.contract_address };
    let owner = ownable.owner();
    start_cheat_caller_address(vault.contract_address, owner);
    vault.withdrawPrizeConversionFees(USER2(), 0_u256);
    stop_cheat_caller_address(vault.contract_address);
}

#[should_panic(expected: 'Insufficient STRK in vault')]
#[test]
fn test_withdraw_prize_conversion_fees_insufficient_vault_balance() {
    let (vault, _) = deploy_vault_contract_vault();
    let ownable = IOwnableDispatcher { contract_address: vault.contract_address };
    let owner = ownable.owner();

    // Use storage manipulation to set accumulated prize conversion fees
    let fee_amount = 100_u256;
    store(
        vault.contract_address,
        selector!("accumulatedPrizeConversionFees"),
        array![fee_amount.low.into(), fee_amount.high.into()].span(),
    );

    start_cheat_caller_address(vault.contract_address, owner);
    // No STRK in vault - this should fail
    vault.withdrawPrizeConversionFees(USER2(), fee_amount);
    stop_cheat_caller_address(vault.contract_address);
}

// ============================================================================================
// COUNTER CONSISTENCY TESTS
// ============================================================================================

#[test]
fn test_total_starkplay_minted_updates() {
    let (vault, _) = deploy_vault_contract_vault();
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    setup_user_balance_vault(
        strk_token,
        USER1(),
        VAULT_LARGE_AMOUNT + 200000000000000000000_u256,
        vault.contract_address,
    );

    assert(vault.get_total_starkplay_minted() == 0, 'Initial minted should be 0');

    let amount1 = VAULT_LARGE_AMOUNT;
    let expected_minted1 = amount1 - get_fee_amount(Initial_Fee_Percentage, amount1);

    vault.buySTRKP(USER1(), amount1);
    assert(vault.get_total_starkplay_minted() == expected_minted1, 'First minting incorrect');

    let amount2 = 200000000000000000000_u256;
    let expected_minted2 = amount2 - get_fee_amount(Initial_Fee_Percentage, amount2);
    let expected_total = expected_minted1 + expected_minted2;

    vault.buySTRKP(USER1(), amount2);
    assert(vault.get_total_starkplay_minted() == expected_total, 'Total minted incorrect');
}

#[test]
fn test_total_strk_stored_updates() {
    let (vault, _) = deploy_vault_contract_vault();
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    setup_user_balance_vault(
        strk_token,
        USER1(),
        VAULT_LARGE_AMOUNT + 500000000000000000000_u256,
        vault.contract_address,
    );

    assert(vault.get_total_strk_stored() == 0, 'Initial stored should be 0');

    let amount1 = 100000000000000000000_u256;
    vault.buySTRKP(USER1(), amount1);
    assert(vault.get_total_strk_stored() == amount1, 'First storage incorrect');

    let amount2 = 200000000000000000000_u256;
    let expected_total = amount1 + amount2;

    vault.buySTRKP(USER1(), amount2);
    assert(vault.get_total_strk_stored() == expected_total, 'Total stored incorrect');
}

#[test]
fn test_counter_consistency() {
    let (vault, _) = deploy_vault_contract_vault();
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    setup_user_balance_vault(
        strk_token,
        USER1(),
        VAULT_LARGE_AMOUNT + 500000000000000000000_u256,
        vault.contract_address,
    );

    let amounts = array![
        100000000000000000000_u256, 250000000000000000000_u256, 75000000000000000000_u256,
    ];

    let mut i = 0;
    while i != amounts.len() {
        let amount = *amounts.at(i);
        vault.buySTRKP(USER1(), amount);

        let total_stored = vault.get_total_strk_stored();
        let total_minted = vault.get_total_starkplay_minted();
        let accumulated_fee = vault.get_accumulated_fee();

        assert(total_stored == total_minted + accumulated_fee, 'Counter consistency failed');
        i += 1;
    }
}

#[test]
fn test_counters_multiple_users() {
    let (vault, _) = deploy_vault_contract_vault();
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    setup_user_balance_vault(
        strk_token,
        USER1(),
        VAULT_LARGE_AMOUNT + 500000000000000000000_u256,
        vault.contract_address,
    );
    setup_user_balance_vault(
        strk_token,
        USER2(),
        VAULT_LARGE_AMOUNT + 500000000000000000000_u256,
        vault.contract_address,
    );
    setup_user_balance_vault(
        strk_token,
        USER3(),
        VAULT_LARGE_AMOUNT + 500000000000000000000_u256,
        vault.contract_address,
    );

    let users = array![USER1(), USER2(), USER3()];

    let mut expected_total_stored = 0;
    let mut expected_total_minted = 0;
    let mut expected_total_fee = 0;

    let mut i = 0;
    while i != users.len() {
        let user = *users.at(i);

        vault.buySTRKP(user, VAULT_PURCHASE_AMOUNT);

        expected_total_stored += VAULT_PURCHASE_AMOUNT;
        expected_total_minted += VAULT_PURCHASE_AMOUNT
            - get_fee_amount(Initial_Fee_Percentage, VAULT_PURCHASE_AMOUNT);
        expected_total_fee += get_fee_amount(Initial_Fee_Percentage, VAULT_PURCHASE_AMOUNT);

        assert(vault.get_total_strk_stored() == expected_total_stored, 'Global stored incorrect');
        assert(
            vault.get_total_starkplay_minted() == expected_total_minted, 'Global minted incorrect',
        );
        assert(vault.get_accumulated_fee() == expected_total_fee, 'Global fee incorrect');

        i += 1;
    }
}

// ============================================================================================
// MISSING EVENT TESTS FROM test_starkplay_vault.cairo
// ============================================================================================

#[test]
fn test_starkplay_minted_event_emission() {
    let (vault, _) = deploy_vault_contract_vault();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    let purchase_amount = 100000000000000000000_u256; // 100 STRK

    setup_user_balance_vault(strk_token, USER1(), VAULT_LARGE_AMOUNT, vault.contract_address);

    // Start event spy before transaction
    let mut spy = spy_events();

    // Execute buySTRKP transaction
    start_cheat_caller_address(vault.contract_address, USER1());
    let success = vault.buySTRKP(USER1(), purchase_amount);
    stop_cheat_caller_address(vault.contract_address);

    assert(success, 'Transaction should succeed');

    // Get events and verify that events are emitted
    let events = spy.get_events();
    assert(events.events.len() >= 2, 'Should emit at least 2 events');

    // Verify that the transaction was successful by checking state
    let expected_fee = get_expected_fee_amount(purchase_amount, Initial_Fee_Percentage);
    assert(vault.get_accumulated_fee() == expected_fee, 'Fee should be correct');
}

#[test]
fn test_event_parameters_validation() {
    let (vault, _) = deploy_vault_contract_vault();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    let purchase_amount = VAULT_PURCHASE_AMOUNT; // 1 STRK

    setup_user_balance_vault(strk_token, USER1(), VAULT_LARGE_AMOUNT, vault.contract_address);

    let mut spy = spy_events();

    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), purchase_amount);
    stop_cheat_caller_address(vault.contract_address);

    let events = spy.get_events();

    // Verify that events are emitted
    assert(events.events.len() >= 5, 'Should emit at least 5 events');

    // Validate FeeCollected event at index 2
    let (_, first_event) = events.events.at(2);

    // Verify FeeCollected event has the expected structure
    // The event should have keys for user and amount, and data for accumulatedFee
    assert(first_event.keys.len() >= 2, 'FeeCollected keys');
    assert(first_event.data.len() >= 1, 'FeeCollected data');

    // Validate StarkPlayMinted event at index 5
    let (_, second_event) = events.events.at(5);

    // Verify StarkPlayMinted event has the expected structure
    // The event should have keys for user and amount
    assert(second_event.keys.len() >= 2, 'StarkPlayMinted keys');

    // Verify that the transaction was successful and state changed
    assert(vault.get_accumulated_fee() > 0, 'Fee should be accumulated');
}

#[test]
fn test_event_emission_order() {
    let (vault, _) = deploy_vault_contract_vault();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    setup_user_balance_vault(strk_token, USER1(), VAULT_LARGE_AMOUNT, vault.contract_address);

    let mut spy = spy_events();

    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), VAULT_PURCHASE_AMOUNT);
    stop_cheat_caller_address(vault.contract_address);

    let events = spy.get_events();

    // Verify that events are emitted in the correct order
    // The buySTRKP function should emit events in this order:
    // 1. ERC20 Transfer events (from user to vault)
    // 2. FeeCollected event (index 2)
    // 3. StarkPlayMinted event (index 5)
    assert(events.events.len() >= 5, 'Should emit 5 events');

    // Verify FeeCollected event comes before StarkPlayMinted
    let (_, fee_collected_event) = events.events.at(2);
    let (_, starkplay_minted_event) = events.events.at(5);

    // Verify events have the expected structure for their types
    // FeeCollected should have keys for user and amount, and data for accumulatedFee
    assert(fee_collected_event.keys.len() >= 2, 'FeeCollected keys');
    assert(fee_collected_event.data.len() >= 1, 'FeeCollected data');

    // StarkPlayMinted should have keys for user and amount
    assert(starkplay_minted_event.keys.len() >= 2, 'StarkPlayMinted keys');

    // Verify that the transaction was successful
    assert(vault.get_accumulated_fee() > 0, 'Fee should be accumulated');
}

#[test]
fn test_multiple_events_successive_transactions() {
    let (vault, _) = deploy_vault_contract_vault();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    setup_user_balance_vault(strk_token, USER1(), VAULT_LARGE_AMOUNT, vault.contract_address);

    let mut spy = spy_events();

    // Execute 3 consecutive buySTRKP transactions
    let mut i = 0;
    while i != 3 {
        start_cheat_caller_address(vault.contract_address, USER1());
        vault.buySTRKP(USER1(), VAULT_PURCHASE_AMOUNT);
        stop_cheat_caller_address(vault.contract_address);
        i += 1;
    }

    let events = spy.get_events();

    // Each buySTRKP transaction emits 5 events:
    // 1. ERC20 Transfer (from user to vault)
    // 2. ERC20 Transfer (from vault to user - if any)
    // 3. FeeCollected event
    // 4. ERC20 Mint event (for StarkPlay token)
    // 5. StarkPlayMinted event
    // Total: 3 transactions * 5 events = 15 events minimum
    assert(events.events.len() >= 15, 'Should emit at least 15 events');

    // Verify that the accumulated fee matches expectations
    let expected_fee_per_tx = get_expected_fee_amount(
        VAULT_PURCHASE_AMOUNT, Initial_Fee_Percentage,
    );
    let expected_total_fee = expected_fee_per_tx * 3;
    assert(vault.get_accumulated_fee() == expected_total_fee, 'Fee should match');
}

#[test]
fn test_events_with_different_users() {
    let (vault, _) = deploy_vault_contract_vault();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    setup_user_balance_vault(strk_token, USER1(), VAULT_LARGE_AMOUNT, vault.contract_address);
    setup_user_balance_vault(strk_token, USER2(), VAULT_LARGE_AMOUNT, vault.contract_address);

    let mut spy = spy_events();

    // USER1 makes a purchase
    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), VAULT_PURCHASE_AMOUNT);
    stop_cheat_caller_address(vault.contract_address);

    // USER2 makes a purchase
    start_cheat_caller_address(vault.contract_address, USER2());
    vault.buySTRKP(USER2(), VAULT_PURCHASE_AMOUNT);
    stop_cheat_caller_address(vault.contract_address);

    let events = spy.get_events();

    // Verify that 4 events are emitted (2 users * 2 events each)
    assert(events.events.len() >= 4, 'Should emit 4 events');

    // Verify that both users' transactions were processed
    let expected_fee_per_tx = get_expected_fee_amount(
        VAULT_PURCHASE_AMOUNT, Initial_Fee_Percentage,
    );
    let expected_total_fee = expected_fee_per_tx * 2;
    assert(vault.get_accumulated_fee() == expected_total_fee, 'Fee should match');
}

#[test]
fn test_event_state_consistency() {
    let (vault, starkplay_token) = deploy_vault_contract_vault();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    setup_user_balance_vault(strk_token, USER1(), VAULT_LARGE_AMOUNT, vault.contract_address);

    let erc20_dispatcher = IERC20Dispatcher { contract_address: starkplay_token.contract_address };
    let initial_balance = erc20_dispatcher.balance_of(USER1());
    let initial_accumulated_fee = vault.get_accumulated_fee();

    let mut spy = spy_events();

    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), VAULT_PURCHASE_AMOUNT);
    stop_cheat_caller_address(vault.contract_address);

    let events = spy.get_events();

    // Verify that events were emitted
    assert(events.events.len() >= 2, 'Should emit events');

    // Verify state consistency
    let final_balance = erc20_dispatcher.balance_of(USER1());
    let final_accumulated_fee = vault.get_accumulated_fee();

    // Verify that balance increased
    assert(final_balance > initial_balance, 'Balance should increase');

    // Verify that fee was accumulated
    assert(final_accumulated_fee > initial_accumulated_fee, 'Fee should accumulate');

    // Verify that the fee calculation is correct
    let expected_fee = get_expected_fee_amount(VAULT_PURCHASE_AMOUNT, Initial_Fee_Percentage);
    assert(
        final_accumulated_fee == initial_accumulated_fee + expected_fee, 'Fee should be correct',
    );
}

#[should_panic(expected: 'ERC20: insufficient allowance')]
#[test]
fn test_events_in_error_cases() {
    let (vault, _) = deploy_vault_contract_vault();

    // Get the deployed STRK token
    let _strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    // Don't setup user balance - this will cause insufficient balance error

    let mut _spy = spy_events();

    // Try to make a transaction that will fail
    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), VAULT_PURCHASE_AMOUNT);
    stop_cheat_caller_address(vault.contract_address);
}

#[should_panic(expected: 'Amount must be greater than 0')]
#[test]
fn test_events_with_zero_amount() {
    let (vault, _) = deploy_vault_contract_vault();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    setup_user_balance_vault(strk_token, USER1(), VAULT_LARGE_AMOUNT, vault.contract_address);

    let mut _spy = spy_events();

    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), 0);
    stop_cheat_caller_address(vault.contract_address);
}

#[test]
fn test_events_with_large_amounts() {
    let (vault, _) = deploy_vault_contract_vault();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    let large_amount = 1000000000000000000000_u256; // 1000 STRK
    let expected_fee_amount = get_expected_fee_amount(large_amount, Initial_Fee_Percentage);

    setup_user_balance_vault(strk_token, USER1(), large_amount * 2, vault.contract_address);

    let mut spy = spy_events();

    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), large_amount);
    stop_cheat_caller_address(vault.contract_address);

    let events = spy.get_events();

    // Verify events with large amounts
    assert(events.events.len() >= 2, 'Should emit events');

    // Verify that the fee calculation is correct for large amounts
    assert(vault.get_accumulated_fee() == expected_fee_amount, 'Fee should be correct');
}

#[test]
fn test_events_after_pause_unpause() {
    let (vault, _) = deploy_vault_contract_vault();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    setup_user_balance_vault(strk_token, USER1(), VAULT_LARGE_AMOUNT, vault.contract_address);

    // Pause and unpause the contract
    let ownable = IOwnableDispatcher { contract_address: vault.contract_address };
    start_cheat_caller_address(vault.contract_address, ownable.owner());
    vault.pause();
    vault.unpause();
    stop_cheat_caller_address(vault.contract_address);

    let mut spy = spy_events();

    // Make a transaction after pause/unpause
    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), VAULT_PURCHASE_AMOUNT);
    stop_cheat_caller_address(vault.contract_address);

    let events = spy.get_events();

    // Verify events are still emitted correctly after pause/unpause
    assert(events.events.len() >= 2, 'Should emit events after pause');

    // Verify that the transaction was successful
    let expected_fee = get_expected_fee_amount(VAULT_PURCHASE_AMOUNT, Initial_Fee_Percentage);
    assert(vault.get_accumulated_fee() == expected_fee, 'Fee should accumulate');
}

#[test]
fn test_mint_limit_updated_event_emission() {
    let (vault, _) = deploy_vault_contract_vault();

    let initial_mint_limit = vault.get_mint_limit();
    let new_mint_limit = 1000000000000000000000_u256; // 1000 tokens

    // Start event spy before transaction
    let mut spy = spy_events();

    // Execute setMintLimit transaction (as owner)
    start_cheat_caller_address(vault.contract_address, VAULT_OWNER());
    vault.setMintLimit(new_mint_limit);
    stop_cheat_caller_address(vault.contract_address);

    // Get events and verify that MintLimitUpdated event is emitted
    let events = spy.get_events();
    assert(events.events.len() >= 1, 'Should emit event');

    // Verify that the mint limit was actually updated
    assert(vault.get_mint_limit() == new_mint_limit, 'Mint limit should be updated');
    assert(vault.get_mint_limit() != initial_mint_limit, 'Mint limit should change');
}

#[test]
fn test_basic_event_emission() {
    let (vault, _) = deploy_vault_contract_vault();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    setup_user_balance_vault(strk_token, USER1(), VAULT_LARGE_AMOUNT, vault.contract_address);

    // Start event spy before transaction
    let mut spy = spy_events();

    // Execute buySTRKP transaction
    start_cheat_caller_address(vault.contract_address, USER1());
    let success = vault.buySTRKP(USER1(), VAULT_PURCHASE_AMOUNT);
    stop_cheat_caller_address(vault.contract_address);

    assert(success, 'Transaction should succeed');

    // Get events and verify that events are emitted
    let events = spy.get_events();

    // Simple assertion - just check that some events were emitted
    assert(events.events.len() > 0, 'Should emit events');

    // Verify that the transaction was successful by checking state
    assert(vault.get_accumulated_fee() > 0, 'Fee should be accumulated');
}

#[test]
fn test_mint_limit_updated_event_parameters() {
    let (vault, _) = deploy_vault_contract_vault();

    let new_mint_limit = 500000000000000000000_u256; // 500 tokens

    let mut spy = spy_events();

    // Execute setMintLimit transaction
    start_cheat_caller_address(vault.contract_address, VAULT_OWNER());
    vault.setMintLimit(new_mint_limit);
    stop_cheat_caller_address(vault.contract_address);

    let events = spy.get_events();

    // Verify that event was emitted
    assert(events.events.len() >= 1, 'Should emit event');

    // Verify that the mint limit was updated correctly
    assert(vault.get_mint_limit() == new_mint_limit, 'Mint limit should match');
}

#[test]
fn test_multiple_mint_limit_updates() {
    let (vault, _) = deploy_vault_contract_vault();

    let limits = array![
        100000000000000000000_u256, // 100 tokens
        200000000000000000000_u256, // 200 tokens
        300000000000000000000_u256 // 300 tokens
    ];

    let mut spy = spy_events();

    // Execute multiple setMintLimit transactions
    let mut i = 0;
    while i != limits.len() {
        let new_limit = *limits.at(i);

        start_cheat_caller_address(vault.contract_address, VAULT_OWNER());
        vault.setMintLimit(new_limit);
        stop_cheat_caller_address(vault.contract_address);

        // Verify each update
        assert(vault.get_mint_limit() == new_limit, 'Mint limit should update');

        i += 1;
    }

    let events = spy.get_events();

    // Verify that events were emitted for each update
    assert(events.events.len() >= limits.len(), 'Should emit events');

    // Verify final mint limit
    let final_limit = *limits.at(limits.len() - 1);
    assert(vault.get_mint_limit() == final_limit, 'Final limit should be correct');
}

#[should_panic(expected: 'Invalid Mint limit')]
#[test]
fn test_mint_limit_updated_event_zero_limit() {
    let (vault, _) = deploy_vault_contract_vault();

    // Try to set mint limit to zero (should fail)
    start_cheat_caller_address(vault.contract_address, VAULT_OWNER());
    vault.setMintLimit(0_u256);
    stop_cheat_caller_address(vault.contract_address);
}

#[should_panic(expected: 'Caller is not the owner')]
#[test]
fn test_mint_limit_updated_event_non_owner() {
    let (vault, _) = deploy_vault_contract_vault();

    // Try to set mint limit as non-owner (should fail)
    start_cheat_caller_address(vault.contract_address, USER1());
    vault.setMintLimit(100000000000000000000_u256);
    stop_cheat_caller_address(vault.contract_address);
}

#[test]
fn test_mint_limit_updated_event_large_values() {
    let (vault, _) = deploy_vault_contract_vault();

    let large_limit = 1000000000000000000000000_u256; // 1M tokens

    let mut spy = spy_events();

    // Execute setMintLimit with large value
    start_cheat_caller_address(vault.contract_address, VAULT_OWNER());
    vault.setMintLimit(large_limit);
    stop_cheat_caller_address(vault.contract_address);

    let events = spy.get_events();

    // Verify that event was emitted
    assert(events.events.len() >= 1, 'Should emit event');

    // Verify that the large mint limit was set correctly
    assert(vault.get_mint_limit() == large_limit, 'Large limit should be set');
}

// ============================================================================================
// INTEGRATED TESTS FROM test_starkplayvault.cairo
// ============================================================================================

#[test]
fn test_set_mint_limit_by_owner_vault() {
    // Setup
    let mut state = init_vault_basic();
    let owner = VAULT_OWNER();
    let new_limit = 1000_u256;
    let contract_address = test_address();

    // Check initial state
    let initial_state_limit = load(contract_address, selector!("mintLimit"), 1);
    assert(
        initial_state_limit == array![VAULT_MAX_MINT_AMOUNT.try_into().unwrap()],
        'Wrong mint limit',
    );

    // Set caller as owner
    start_cheat_caller_address(contract_address, owner);

    // set new mint limit
    state.setMintLimit(new_limit);

    // Verify
    let final_limit = load(contract_address, selector!("mintLimit"), 1);
    assert(final_limit == array![new_limit.try_into().unwrap()], 'Mint limit not updated');
}

#[test]
fn test_set_burn_limit_by_owner_vault() {
    // Setup
    let mut state = init_vault_basic();
    let owner = VAULT_OWNER();
    let new_limit = 500_u256;
    let contract_address = test_address();

    // Check initial state
    let initial_state_limit = load(contract_address, selector!("burnLimit"), 1);
    assert(
        initial_state_limit == array![VAULT_MAX_BURN_AMOUNT.try_into().unwrap()],
        'Wrong burn limit',
    );

    // Set caller as owner
    start_cheat_caller_address(contract_address, owner);

    // set new burn limit
    state.setBurnLimit(new_limit);

    // Verify
    let final_limit = load(contract_address, selector!("burnLimit"), 1);
    assert(final_limit == array![new_limit.try_into().unwrap()], 'Burn limit not updated');
}

#[should_panic(expected: 'Caller is not the owner')]
#[test]
fn test_set_mint_limit_by_non_owner_vault() {
    // Setup
    let dispatcher = deploy_vault_basic();
    let non_owner = USER1();
    let new_limit = 1000_u256;

    // Set caller as non-owner
    start_cheat_caller_address(dispatcher.contract_address, non_owner);

    // Attempt to set new mint limit
    dispatcher.setMintLimit(new_limit);
}

#[should_panic(expected: 'Caller is not the owner')]
#[test]
fn test_set_burn_limit_by_non_owner_vault() {
    // Setup
    let dispatcher = deploy_vault_basic();
    let non_owner = USER1();
    let new_limit = 500_u256;
    let contract_address = dispatcher.contract_address;

    // Set caller as non-owner
    start_cheat_caller_address(contract_address, non_owner);

    // Attempt to set new burn limit
    dispatcher.setBurnLimit(new_limit);
}

#[test]
fn test_set_mint_limit_emit_event_vault() {
    // Setup
    let dispatcher = deploy_vault_basic();
    let owner = VAULT_OWNER();
    let new_limit = 1000_u256;
    let contract_address = dispatcher.contract_address;
    let mut spy = spy_events();

    // Set caller as owner
    start_cheat_caller_address(contract_address, owner);
    // set new mint limit
    dispatcher.setMintLimit(new_limit);

    let updated_limit = dispatcher.get_mint_limit();
    assert(updated_limit == new_limit, 'Mint limit not updated');

    // Check event emission
    let events = spy.get_events();
    assert(events.events.len() == 1, 'Event not emitted');
}

#[test]
fn test_set_burn_limit_emit_event_vault() {
    // Setup
    let dispatcher = deploy_vault_basic();
    let owner = VAULT_OWNER();
    let new_limit = 500_u256;
    let contract_address = dispatcher.contract_address;
    let mut spy = spy_events();

    // Set caller as owner
    start_cheat_caller_address(contract_address, owner);

    // set new burn limit
    dispatcher.setBurnLimit(new_limit);

    let updated_limit = dispatcher.get_burn_limit();
    assert(updated_limit == new_limit, 'Burn limit not updated');

    // Check event emission
    let events = spy.get_events();
    assert(events.events.len() == 1, 'Event not emitted');
}

#[should_panic(expected: 'Invalid Mint limit')]
#[test]
fn test_mint_limit_zero_value_vault() {
    // Setup
    let vault = deploy_vault_basic();
    let owner = VAULT_OWNER();
    let contract_address = vault.contract_address;

    // Check initial state
    let initial_state_limit = vault.get_mint_limit();
    assert(initial_state_limit == VAULT_MAX_MINT_AMOUNT, 'Wrong mint limit');

    // Set caller as owner
    start_cheat_caller_address(contract_address, owner);

    // set new mint limit to zero
    vault.setMintLimit(0);
}

#[should_panic(expected: 'Invalid Burn limit')]
#[test]
fn test_burn_limit_zero_value_vault() {
    // Setup
    let vault = deploy_vault_basic();
    let owner = VAULT_OWNER();
    let contract_address = vault.contract_address;

    // Check initial state
    let initial_state_limit = vault.get_burn_limit();
    assert(initial_state_limit == VAULT_MAX_BURN_AMOUNT, 'Wrong burn limit');

    // Set caller as owner
    start_cheat_caller_address(contract_address, owner);

    // set new burn limit to zero
    vault.setBurnLimit(0_u256);
}

#[test]
fn test_set_fee_by_owner_vault() {
    // Setup
    let mut state = init_vault_basic();
    let owner = VAULT_OWNER();
    let new_fee = 5000_u64; // 50% (5000 basis points)
    let contract_address = test_address();

    // Check initial state - constructor sets fee to 10000 (100%)
    let initial_fee = state.GetFeePercentage();
    assert(initial_fee == 10000_u64, 'Wrong initial fee');

    // Set caller as owner
    start_cheat_caller_address(contract_address, owner);

    // Set new fee
    let result = state.set_fee(new_fee);
    assert(result == true, 'set_fee should return true');

    // Verify fee was updated
    let final_fee = state.GetFeePercentage();
    assert(final_fee == new_fee, 'Fee not updated');
}

#[should_panic(expected: 'Caller is not the owner')]
#[test]
fn test_set_fee_by_non_owner_vault() {
    // Setup
    let dispatcher = deploy_vault_basic();
    let non_owner = USER1();
    let new_fee = 5000_u64;

    // Set caller as non-owner
    start_cheat_caller_address(dispatcher.contract_address, non_owner);

    // Attempt to set new fee
    dispatcher.set_fee(new_fee);
}

#[should_panic(expected: 'Fee too high')]
#[test]
fn test_set_fee_exceeds_maximum_vault() {
    // Setup
    let dispatcher = deploy_vault_basic();
    let owner = VAULT_OWNER();
    let invalid_fee = 10001_u64; // Exceeds MAX_FEE_PERCENTAGE (10000)
    let contract_address = dispatcher.contract_address;

    // Set caller as owner
    start_cheat_caller_address(contract_address, owner);

    // Attempt to set fee above maximum
    dispatcher.set_fee(invalid_fee);
}

#[test]
fn test_set_fee_at_maximum_boundary_vault() {
    // Setup
    let dispatcher = deploy_vault_basic();
    let owner = VAULT_OWNER();
    let max_fee = 10000_u64; // MAX_FEE_PERCENTAGE
    let contract_address = dispatcher.contract_address;

    // Set caller as owner
    start_cheat_caller_address(contract_address, owner);

    // Set fee at maximum boundary
    let result = dispatcher.set_fee(max_fee);
    assert(result == true, 'set_fee should return true');

    // Verify fee was updated
    let final_fee = dispatcher.GetFeePercentage();
    assert(final_fee == max_fee, 'Fee not updated to max');
}

#[test]
fn test_set_fee_to_zero_vault() {
    // Setup
    let dispatcher = deploy_vault_basic();
    let owner = VAULT_OWNER();
    let zero_fee = 0_u64;
    let contract_address = dispatcher.contract_address;

    // Set caller as owner
    start_cheat_caller_address(contract_address, owner);

    // Set fee to zero
    let result = dispatcher.set_fee(zero_fee);
    assert(result == true, 'set_fee should return true');

    // Verify fee was updated
    let final_fee = dispatcher.GetFeePercentage();
    assert(final_fee == zero_fee, 'Fee not updated to zero');
}

#[test]
fn test_set_fee_emit_event_vault() {
    // Setup
    let dispatcher = deploy_vault_basic();
    let owner = VAULT_OWNER();
    let new_fee = 2500_u64; // 25%
    let contract_address = dispatcher.contract_address;
    let mut spy = spy_events();

    // Set caller as owner
    start_cheat_caller_address(contract_address, owner);

    // Get initial fee for comparison
    let _old_fee = dispatcher.GetFeePercentage();

    // Set new fee
    dispatcher.set_fee(new_fee);

    // Verify fee was updated
    let updated_fee = dispatcher.GetFeePercentage();
    assert(updated_fee == new_fee, 'Fee not updated');

    // Check event emission
    let events = spy.get_events();
    assert(events.events.len() == 1, 'Event not emitted');
}

#[test]
fn test_set_fee_multiple_times_vault() {
    // Setup
    let dispatcher = deploy_vault_basic();
    let owner = VAULT_OWNER();
    let contract_address = dispatcher.contract_address;

    // Set caller as owner
    start_cheat_caller_address(contract_address, owner);

    // Set fee multiple times
    let fee1 = 1000_u64; // 10%
    let fee2 = 5000_u64; // 50%
    let fee3 = 100_u64; // 1%

    // First update
    let result1 = dispatcher.set_fee(fee1);
    assert(result1 == true, 'First fee should return true');
    assert(dispatcher.GetFeePercentage() == fee1, 'First fee not updated');

    // Second update
    let result2 = dispatcher.set_fee(fee2);
    assert(result2 == true, 'Second fee should return true');
    assert(dispatcher.GetFeePercentage() == fee2, 'Second fee not updated');

    // Third update
    let result3 = dispatcher.set_fee(fee3);
    assert(result3 == true, 'Third fee should return true');
    assert(dispatcher.GetFeePercentage() == fee3, 'Third fee not updated');
}

#[test]
fn test_fee_queries_reflect_changes_vault() {
    // Setup
    let dispatcher = deploy_vault_basic();
    let owner = VAULT_OWNER();
    let contract_address = dispatcher.contract_address;

    // Set caller as owner
    start_cheat_caller_address(contract_address, owner);

    // Test multiple fee changes and verify queries
    let fee_sequence = array![100_u64, 250_u64, 500_u64, 0_u64, 1000_u64]; // 1%, 2.5%, 5%, 0%, 10%

    let mut i = 0;
    while i < fee_sequence.len() {
        let new_fee = *fee_sequence.at(i);

        // Set new fee
        let result = dispatcher.set_fee(new_fee);
        assert(result == true, 'set_fee should return true');

        // Query and verify immediately
        let queried_fee = dispatcher.GetFeePercentage();
        assert(queried_fee == new_fee, 'Immediate query should match');

        // Query again after some operations (to ensure persistence)
        let queried_fee_again = dispatcher.GetFeePercentage();
        assert(queried_fee_again == new_fee, 'Persistent query should match');

        i += 1;
    }

    stop_cheat_caller_address(contract_address);
}
