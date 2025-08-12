use contracts::StarkPlayERC20::{IMintableDispatcher, IMintableDispatcherTrait};
use contracts::StarkPlayVault::{IStarkPlayVaultDispatcher, IStarkPlayVaultDispatcherTrait};
use openzeppelin_testing::declare_and_deploy;
use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use openzeppelin_utils::serde::SerializedAppend;
use snforge_std::{EventSpyTrait, spy_events, start_cheat_caller_address, stop_cheat_caller_address};
use starknet::{ContractAddress, contract_address_const};


const MAX_MINT_AMOUNT: u256 = 1_000_000 * 1_000_000_000_000_000_000;
const INITIAL_FEE_PERCENTAGE: u64 = 50;

fn owner_address() -> ContractAddress {
    contract_address_const::<'owner'>()
}

fn user_address() -> ContractAddress {
    contract_address_const::<'user'>()
}

fn deploy_starkplay_token() -> ContractAddress {
    let recipient = owner_address();
    let admin = owner_address();
    let mut calldata = array![];

    calldata.append_serde(recipient);
    calldata.append_serde(admin);

    declare_and_deploy("StarkPlayERC20", calldata)
}

fn deploy_starkplay_vault(starkplay_token: ContractAddress) -> ContractAddress {
    let owner = owner_address();
    let initial_fee = INITIAL_FEE_PERCENTAGE;
    let mut calldata = array![];

    calldata.append_serde(owner);
    calldata.append_serde(starkplay_token);
    calldata.append_serde(initial_fee);

    declare_and_deploy("StarkPlayVault", calldata)
}

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


#[test]
fn test_contract_deployment() {
    let (vault, starkplay_token) = setup_contracts();

    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault };

    let fee_percentage = vault_dispatcher.GetFeePercentage();
    assert(fee_percentage == INITIAL_FEE_PERCENTAGE, 'Fee percentage incorrect');
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


#[should_panic(expected: ('Insufficient minter allowance',))]
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
    let result = vault_dispatcher.setFeePercentage(new_fee);

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
    vault_dispatcher.setFeePercentage(low_fee);
}


#[should_panic(expected: 'Fee percentage is too high')]
#[test]
fn test_fee_percentage_too_high() {
    let (vault, _starkplay_token) = setup_contracts();

    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault };

    let high_fee = 600_u64;
    vault_dispatcher.setFeePercentage(high_fee);
}
