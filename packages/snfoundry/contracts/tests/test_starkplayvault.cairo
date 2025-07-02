use contracts::StarkPlayVault::StarkPlayVault::{
    BurnLimitUpdated, Event, MintLimitUpdated, StarkPlayVaultImpl,
};
use contracts::StarkPlayVault::{
    IStarkPlayVault, IStarkPlayVaultDispatcher, IStarkPlayVaultDispatcherTrait, StarkPlayVault,
};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait, EventSpyTrait, declare,
    spy_events, start_cheat_caller_address, stop_cheat_caller_address, test_address,
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
        contract_address_const::<5>(), // owner
        contract_address_const::<'token'>(), // starkplay_token
        10000 // fee percentage
    );
    state
}

// Helper function to deploy the contract and return dispatcher and address
fn deploy_vault() -> IStarkPlayVaultDispatcher {
    let contract = declare("StarkPlayVault").unwrap().contract_class();
    let owner = contract_address_const::<5>(); // 
    let token = contract_address_const::<'token'>(); //
    let fee_percentage: u128 = 10000;

    let mut constructor_calldata = array![];
    owner.serialize(ref constructor_calldata);
    token.serialize(ref constructor_calldata);
    fee_percentage.serialize(ref constructor_calldata);

    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    let dispatcher = IStarkPlayVaultDispatcher { contract_address };
    dispatcher
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
}

#[should_panic(expected: 'Caller is not the owner')]
#[test]
fn test_set_mint_limit_by_non_owner() {
    // Setup
    let dispatcher = deploy_vault();
    let non_owner = contract_address_const::<6>();
    let new_limit = 1000_u256;

    // Set caller as non-owner
    start_cheat_caller_address(dispatcher.contract_address, non_owner);

    // Attempt to set new mint limit
    dispatcher.setMintLimit(new_limit);
}

#[should_panic(expected: 'Caller is not the owner')]
#[test]
fn test_set_burn_limit_by_non_owner() {
    // Setup
    let dispatcher = deploy_vault();
    let non_owner = contract_address_const::<6>();
    let new_limit = 500_u256;
    let contract_address = dispatcher.contract_address;

    // Set caller as non-owner
    start_cheat_caller_address(contract_address, non_owner);

    // Attempt to set new burn limit
    dispatcher.setBurnLimit(new_limit);
}

#[test]
fn test_set_mint_limit_emit_event() {
    // Setup
    let dispatcher = deploy_vault();
    let owner = contract_address_const::<5>();
    let new_limit = 1000_u256;
    let contract_address = dispatcher.contract_address;
    let mut spy = spy_events();

    // Set caller as owner
    start_cheat_caller_address(contract_address, owner);
    // set new mint limit
    dispatcher.setMintLimit(new_limit);

    // Check event emission
    let events = spy.get_events();
    assert(events.events.len() == 1, 'Event not emitted');
    let expected_event = Event::MintLimitUpdated(MintLimitUpdated { new_mint_limit: new_limit });
    let expected_events = array![(contract_address, expected_event)];
    spy.assert_emitted(@expected_events);
}

#[test]
fn test_set_burn_limit_emit_event() {
    // Setup
    let dispatcher = deploy_vault();
    let owner = contract_address_const::<5>();
    let new_limit = 500_u256;
    let contract_address = dispatcher.contract_address;
    let mut spy = spy_events();

    // Set caller as owner
    start_cheat_caller_address(contract_address, owner);

    // set new burn limit
    dispatcher.setBurnLimit(new_limit);

    // Check event emission
    let events = spy.get_events();
    assert(events.events.len() == 1, 'Event not emitted');
    let expected_event = Event::BurnLimitUpdated(BurnLimitUpdated { new_burn_limit: new_limit });
    let expected_events = array![(contract_address, expected_event)];
    spy.assert_emitted(@expected_events);
}

#[should_panic(expected: 'Invalid Mint limit')]
#[test]
fn test_mint_limit_zero_value() {
    // Setup
    let mut state = init_vault();
    let owner = contract_address_const::<5>();
    let contract_address = test_address();

    // Check initial state
    let initial_state_limit = state.mintLimit.read();
    assert(initial_state_limit == MAX_MINT_AMOUNT, 'Wrong mint limit');

    // Set caller as owner
    start_cheat_caller_address(contract_address, owner);

    // set new mint limit to zero
    state.setMintLimit(0_u256);
}

#[should_panic(expected: 'Invalid Burn limit')]
#[test]
fn test_burn_limit_zero_value() {
    // Setup
    let mut state = init_vault();
    let owner = contract_address_const::<5>();
    let contract_address = test_address();

    // Check initial state
    let initial_state_limit = state.mintLimit.read();
    assert(initial_state_limit == MAX_MINT_AMOUNT, 'Wrong mint limit');

    // Set caller as owner
    start_cheat_caller_address(contract_address, owner);

    // set new mint limit to zero
    state.setBurnLimit(0_u256);
}
