use contracts::Lottery::{ILotteryDispatcher, ILotteryDispatcherTrait};
use contracts::StarkPlayERC20::{IMintableDispatcher, IMintableDispatcherTrait};
use contracts::StarkPlayVault::{IStarkPlayVaultDispatcher};
use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, start_cheat_caller_address,
    stop_cheat_caller_address,
};

use starknet::{ContractAddress};
use core::array::ArrayTrait;

// Test constants
fn OWNER() -> ContractAddress {
    'OWNER'.try_into().unwrap()
}

fn USER1() -> ContractAddress {
    'USER1'.try_into().unwrap()
}

fn TICKET_PRICE() -> u256 {
    1000000000000000000_u256 // 1 STRK
}

fn INITIAL_ACCUMULATED_PRIZE() -> u256 {
    10000000000000000000_u256 // 10 STRK
}

fn INITIAL_FEE_PERCENTAGE() -> u64 {
    50_u64 // 50 basis points = 0.5%
}

fn LARGE_AMOUNT() -> u256 {
    10000000000000000000_u256 // 10 STRK
}

// Helper function to deploy StarkPlay token
fn deploy_starkplay_token() -> IMintableDispatcher {
    let contract = declare("StarkPlayERC20").unwrap().contract_class();
    let mut constructor_calldata = ArrayTrait::new();
    constructor_calldata.append(OWNER().into());
    constructor_calldata.append(OWNER().into());
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    
    let starkplay_token = IMintableDispatcher { contract_address };
    
    // Set up the StarkPlay token with initial balances for users
    start_cheat_caller_address(contract_address, OWNER());
    
    // Grant MINTER_ROLE to OWNER so we can mint tokens
    starkplay_token.grant_minter_role(OWNER());
    starkplay_token.set_minter_allowance(OWNER(), 1000000000000000000000000_u256); // Large allowance
    
    starkplay_token.mint(USER1(), LARGE_AMOUNT() * 100); // Mint plenty for testing
    stop_cheat_caller_address(contract_address);
    
    starkplay_token
}



// Helper function to deploy vault contract
fn deploy_vault_contract(starkplay_token: ContractAddress) -> IStarkPlayVaultDispatcher {
    let vault_contract = declare("StarkPlayVault").unwrap().contract_class();
    let mut vault_constructor_calldata = ArrayTrait::new();
    vault_constructor_calldata.append(OWNER().into());
    vault_constructor_calldata.append(starkplay_token.into());
    vault_constructor_calldata.append(INITIAL_FEE_PERCENTAGE().into());
    let (vault_address, _) = vault_contract.deploy(@vault_constructor_calldata).unwrap();
    IStarkPlayVaultDispatcher { contract_address: vault_address }
}

// Helper function to deploy lottery contract with dynamic addresses
fn deploy_lottery_contract(
    strk_play_address: ContractAddress,
    strk_play_vault_address: ContractAddress,
) -> ILotteryDispatcher {
    let lottery_contract = declare("Lottery").unwrap().contract_class();
    let mut lottery_constructor_calldata = ArrayTrait::new();
    lottery_constructor_calldata.append(OWNER().into());
    lottery_constructor_calldata.append(strk_play_address.into());
    lottery_constructor_calldata.append(strk_play_vault_address.into());
    let (lottery_address, _) = lottery_contract.deploy(@lottery_constructor_calldata).unwrap();
    ILotteryDispatcher { contract_address: lottery_address }
}

// Helper function to create valid lottery numbers
fn create_valid_numbers() -> Array<u16> {
    let mut numbers = ArrayTrait::new();
    numbers.append(1);
    numbers.append(5);
    numbers.append(10);
    numbers.append(15);
    numbers.append(20);
    numbers
}

#[test]
fn test_lottery_constructor_with_dynamic_addresses() {
    // Deploy StarkPlay token
    let starkplay_token = deploy_starkplay_token();
    
    // Deploy vault contract
    let vault = deploy_vault_contract(starkplay_token.contract_address);
    
    // Deploy lottery contract with dynamic addresses
    let lottery = deploy_lottery_contract(starkplay_token.contract_address, vault.contract_address);
    
    // Test that lottery was deployed successfully
    assert(lottery.contract_address != 0.try_into().unwrap(), 'Lottery should be deployed');
}

#[test]
fn test_lottery_initialization() {
    // Deploy all required contracts
    let starkplay_token = deploy_starkplay_token();
    let vault = deploy_vault_contract(starkplay_token.contract_address);
    let lottery = deploy_lottery_contract(starkplay_token.contract_address, vault.contract_address);
    
    // Initialize lottery with ticket price and accumulated prize
    start_cheat_caller_address(lottery.contract_address, OWNER());
    lottery.Initialize(TICKET_PRICE(), INITIAL_ACCUMULATED_PRIZE());
    stop_cheat_caller_address(lottery.contract_address);
    
    // Verify initialization
    let accumulated_prize = lottery.GetAccumulatedPrize();
    assert(accumulated_prize == INITIAL_ACCUMULATED_PRIZE(), 'Accumulated prize should match');
}

#[test]
fn test_buy_ticket_with_dynamic_addresses() {
    // Deploy all required contracts
    let starkplay_token = deploy_starkplay_token();
    let vault = deploy_vault_contract(starkplay_token.contract_address);
    let lottery = deploy_lottery_contract(starkplay_token.contract_address, vault.contract_address);
    
    // Initialize lottery
    start_cheat_caller_address(lottery.contract_address, OWNER());
    lottery.Initialize(TICKET_PRICE(), INITIAL_ACCUMULATED_PRIZE());
    stop_cheat_caller_address(lottery.contract_address);
    
    // Set up user with tokens and approval
    let user = USER1();
    start_cheat_caller_address(starkplay_token.contract_address, user);
    
    // Approve lottery contract to spend tokens
    let starkplay_dispatcher = IERC20Dispatcher { contract_address: starkplay_token.contract_address };
    starkplay_dispatcher.approve(lottery.contract_address, LARGE_AMOUNT());
    stop_cheat_caller_address(starkplay_token.contract_address);
    
    // Create valid numbers for ticket
    let numbers = create_valid_numbers();
    
    // Buy ticket as user
    start_cheat_caller_address(lottery.contract_address, user);
    lottery.BuyTicket(1, numbers); // Use drawId 1, not 0
    stop_cheat_caller_address(lottery.contract_address);
    
    // Verify user has tickets
    let ticket_count = lottery.GetUserTicketsCount(1, user); // Use drawId 1
    assert(ticket_count == 1, 'User should have 1 ticket');
} 

#[test]
fn test_get_starkplay_token_address() {
    let starkplay_token = deploy_starkplay_token();
    let vault = deploy_vault_contract(starkplay_token.contract_address);
    let lottery = deploy_lottery_contract(starkplay_token.contract_address, vault.contract_address);

    assert(lottery.GetStrkPlayContractAddress() == starkplay_token.contract_address, 'StarkPlay address should match');
    assert(lottery.GetStrkPlayVaultContractAddress() == vault.contract_address, 'Vault address should match');
}

