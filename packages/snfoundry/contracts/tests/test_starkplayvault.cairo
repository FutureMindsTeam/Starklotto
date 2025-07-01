use contracts::StarkPlayVault::StarkPlayVault::Event::{BurnLimitUpdated, MintLimitUpdated};
use contracts::StarkPlayVault::StarkPlayVault::{Event, StarkPlayVaultImpl};
use contracts::StarkPlayVault::{
    IStarkPlayVault, IStarkPlayVaultDispatcher, IStarkPlayVaultDispatcherTrait, StarkPlayVault,
};
use snforge_std::{
    EventSpyAssertionsTrait, EventSpyTrait, spy_events, start_cheat_caller_address,
    stop_cheat_caller_address, test_address,
};
use starknet::storage::StorableStoragePointerReadAccess;
use starknet::{ContractAddress, contract_address_const};

// setting up the contract state
fn CONTRACT_STATE() -> StarkPlayVault::ContractState {
    StarkPlayVault::contract_state_for_testing()
}

fn init_vault() -> StarkPlayVault::ContractState {
    let mut state = StarkPlayVault::contract_state_for_testing();
    StarkPlayVault::constructor(
        ref state,
        contract_address_const::<'owner'>(), // owner
        contract_address_const::<'token'>(), // starkplay_token
        10000 // fee percentage
    );
    state
}

const MAX_MINT_AMOUNT: u256 = 1_000_000 * 1_000_000_000_000_000_000; // 1 millón de tokens
const MAX_BURN_AMOUNT: u256 = 1_000_000 * 1_000_000_000_000_000_000; // 1 millón de tokens


#[test]
fn test_set_mint_limit_by_owner() {
    // Setup
    let mut state = init_vault();
    let owner = contract_address_const::<5>();
    let new_limit = 1000_u256;
    let contract_address = test_address();

    // Check initial state
    let initial_state_limit = state.mintLimit.read();
    assert(initial_state_limit == MAX_MINT_AMOUNT, 'Wrong mint limit');

    // Set caller as owner
    start_cheat_caller_address(contract_address, owner);

    let mut spy = spy_events();

    // set new mint limit
    state.setMintLimit(new_limit);

    // Verify
    let final_limit = state.mintLimit.read();
    assert(final_limit == new_limit, 'Mint limit not updated');

    // Check event emission
    let events = spy.get_events();
    assert(events.events.len() == 1, 'Event not emitted');
    // let expected_event = Event::MintLimitUpdated(MintLimitUpdated {
//     new_mint_limit: new_limit,
// });
// let expected_events = array![(contract_address, expected_event)];
// spy.assert_emitted(@expected_events);
}

#[test]
fn test_set_burn_limit_by_owner() {
    // Setup
    let mut state = init_vault();
    let owner = contract_address_const::<5>();
    let new_limit = 500_u256;
    let contract_address = test_address();

    // Check initial state
    let initial_state_limit = state.burnLimit.read();
    assert(initial_state_limit == MAX_BURN_AMOUNT, 'Wrong burn limit');

    // Set caller as owner
    start_cheat_caller_address(contract_address, owner);

    let mut spy = spy_events();

    // set new burn limit
    state.setBurnLimit(new_limit);

    // Verify
    let final_limit = state.burnLimit.read();
    assert(final_limit == new_limit, 'Burn limit not updated');

    // Check event emission
    let events = spy.get_events();
    assert(events.events.len() == 1, 'Event not emitted');
    // let expected_event = Event::BurnLimitUpdated(BurnLimitUpdated {
//     new_burn_limit: new_limit,
// });
// let expected_events = array![(contract_address, expected_event)];
// spy.assert_emitted(@expected_events);
}

#[test]
fn test_set_mint_limit_by_non_owner() {
    // Setup
    let mut state = init_vault();
    let non_owner = contract_address_const::<6>();
    let new_limit = 1000_u256;
    let contract_address = test_address();

    // Check initial state
    let initial_state_limit = state.mintLimit.read();
    assert(initial_state_limit == MAX_MINT_AMOUNT, 'Wrong mint limit');

    // Set caller as non-owner
    start_cheat_caller_address(contract_address, non_owner);

    // Attempt to set new mint limit
    state.setMintLimit(new_limit);
}

#[test]
fn test_set_burn_limit_by_non_owner() {
    // Setup
    let mut state = init_vault();
    let non_owner = contract_address_const::<6>();
    let new_limit = 500_u256;
    let contract_address = test_address();

    // Check initial state
    let initial_state_limit = state.burnLimit.read();
    assert(initial_state_limit == MAX_BURN_AMOUNT, 'Wrong burn limit');

    // Set caller as non-owner
    start_cheat_caller_address(contract_address, non_owner);

    // Attempt to set new burn limit
    state.setBurnLimit(new_limit);
}

