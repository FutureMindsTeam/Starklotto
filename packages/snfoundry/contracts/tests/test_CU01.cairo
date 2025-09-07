use contracts::StarkPlayVault::{IStarkPlayVaultDispatcher, IStarkPlayVaultDispatcherTrait};
use openzeppelin_access::accesscontrol::interface::{
    IAccessControlDispatcher, IAccessControlDispatcherTrait,
};
use openzeppelin_security::interface::{IPausableDispatcher, IPausableDispatcherTrait};
use openzeppelin_testing::declare_and_deploy;
use openzeppelin_token::erc20::interface::{
    IERC20Dispatcher, IERC20DispatcherTrait, IERC20MetadataDispatcher,
    IERC20MetadataDispatcherTrait,
};
use openzeppelin_utils::serde::SerializedAppend;
use snforge_std::{CheatSpan, cheat_caller_address, spy_events, ContractClassTrait, DeclareResultTrait, declare};
use starknet::{ContractAddress, contract_address_const};

// =============================================================================
// Constants and Helper Functions
// =============================================================================

// Direcciones de prueba
const OWNER: ContractAddress = 0x02dA5254690b46B9C4059C25366D1778839BE63C142d899F0306fd5c312A5918
    .try_into()
    .unwrap();

const USER: ContractAddress = 0x02dA5254690b46B9C4059C25366D1778839BE63C142d899F0306fd5c312A5918
    .try_into()
    .unwrap();

const ADMIN: ContractAddress = contract_address_const::<0x01234>();
const STRK_TOKEN_ADDRESS: ContractAddress = contract_address_const::<0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d>();

const Initial_Fee_Percentage: u64 = 50; // 50 basis points = 0.5%
const BASIS_POINTS_DENOMINATOR: u256 = 10000_u256; // 10000 basis points = 100%

//helper function
fn owner_address() -> ContractAddress {
    OWNER
}

fn user_address() -> ContractAddress {
    USER
}

fn admin_address() -> ContractAddress {
    ADMIN
}

// =============================================================================
// Deploy Functions - Unified to avoid duplications
// =============================================================================

fn deploy_contract_lottery() -> ContractAddress {
    let contract_lotery: ContractAddress =
        0x02dA5254690b46B9C4059C25366D1778839BE63C142d899F0306fd5c312A5918
        .try_into()
        .unwrap();
    contract_lotery
}

/// Deploy StarkPlayERC20 token contract
fn deploy_starkplay_erc20() -> ContractAddress {
    let contract_class = declare("StarkPlayERC20").unwrap().contract_class();
    let mut calldata = array![];
    calldata.append_serde(admin_address()); // recipient (unused)
    calldata.append_serde(admin_address()); // admin
    let (contract_address, _) = contract_class.deploy(@calldata).unwrap();
    contract_address
}

/// Deploy StarkPlayVault contract with lottery contract (legacy method)
fn deploy_starkplay_vault_with_lottery() -> ContractAddress {
    let contract_lotery = deploy_contract_lottery();
    let owner = owner_address();
    let initial_fee = 50_u64; // 50 basis points = 0.5%
    let mut calldata = array![];

    calldata.append_serde(contract_lotery);
    calldata.append_serde(owner);
    calldata.append_serde(initial_fee);

    declare_and_deploy("StarkPlayVault", calldata)
}

/// Deploy StarkPlayVault contract with StarkPlayERC20 token
fn deploy_starkplay_vault_with_token() -> ContractAddress {
    let starkplay_token = deploy_starkplay_erc20();
    let contract_class = declare("StarkPlayVault").unwrap().contract_class();
    let mut calldata = array![];
    calldata.append_serde(owner_address());
    calldata.append_serde(starkplay_token);
    calldata.append_serde(5_u64); // feePercentage
    let (contract_address, _) = contract_class.deploy(@calldata).unwrap();
    contract_address
}

// =============================================================================
// Utility Functions
// =============================================================================

fn get_fee_amount(feePercentage: u64, amount: u256) -> u256 {
    let feeAmount = (amount * feePercentage.into()) / BASIS_POINTS_DENOMINATOR;
    feeAmount
}

// =============================================================================
// StarkPlayERC20 Tests
// =============================================================================

#[test]
fn test_starkplay_erc20_initialization() {
    let token_address = deploy_starkplay_erc20();
    let erc20_metadata = IERC20MetadataDispatcher { contract_address: token_address };
    let access_control = IAccessControlDispatcher { contract_address: token_address };
    let erc20 = IERC20Dispatcher { contract_address: token_address };
    let pausable = IPausableDispatcher { contract_address: token_address };

    assert(erc20_metadata.name() == "$tarkPlay", 'Incorrect token name');
    assert(erc20_metadata.symbol() == "STARKP", 'Incorrect token symbol');
    assert(erc20_metadata.decimals() == 18, 'Incorrect decimals');
    assert(access_control.has_role(0, admin_address()), 'Admin role not set');
    // let src5 = ISRC5Dispatcher { contract_address: token_address };
    // let access_control_interface_id: felt252 =
    //     0x3f918d17e5ee77373b56385708f855659a07f75997f365cf8774862850866d;
    // assert(src5.supports_interface(access_control_interface_id), 'Interface not registered');
    assert(erc20.total_supply() == 1000, 'Initial supply should be 1000');
    assert(erc20.balance_of(admin_address()) == 1000, 'Adm should have initial supp');
    assert(!pausable.is_paused(), 'Contract should not be paused');
}

// =============================================================================
// StarkPlayVault Tests
// =============================================================================

#[test]
fn test_starkplay_vault_fee_percentage_deploy() {
    //Deploy the contract
    let vault_address = deploy_starkplay_vault_with_lottery();

    //dispatch the contract
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };

    //check fee of buy starkplay is correct
    let fee_percentage = vault_dispatcher.GetFeePercentage();

    assert(fee_percentage == Initial_Fee_Percentage, 'Fee percentage should be 0.5%');
}

#[test]
fn test_starkplay_vault_calculate_fee_buy_numbers() {
    let vault_address = deploy_starkplay_vault_with_lottery();

    //dispatch the contract
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

// =============================================================================
// Integration Tests between StarkPlayERC20 and StarkPlayVault
// =============================================================================

#[test]
fn test_starkplay_vault_with_erc20_integration() {
    // Deploy vault with ERC20 token
    let vault_address = deploy_starkplay_vault_with_token();

    // Test vault functionality
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    let fee_percentage = vault_dispatcher.GetFeePercentage();

    // Verify vault has correct fee percentage
    assert(fee_percentage == 5, 'Vault fee percentage should be 5 basis points');
}