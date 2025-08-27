use contracts::StarkPlayVault::StarkPlayVault::{Event, FeeUpdated};
use contracts::StarkPlayVault::{
    IStarkPlayVault, IStarkPlayVaultDispatcher, IStarkPlayVaultDispatcherTrait, StarkPlayVault,
};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait, EventSpyTrait, declare, load,
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
    let initial_state_limit = load(contract_address, selector!("mintLimit"), 1);
    assert(initial_state_limit == array![MAX_MINT_AMOUNT.try_into().unwrap()], 'Wrong mint limit');

    // Set caller as owner
    start_cheat_caller_address(contract_address, owner);

    // set new mint limit
    state.setMintLimit(new_limit);

    // Verify
    let final_limit = load(contract_address, selector!("mintLimit"), 1);
    assert(final_limit == array![new_limit.try_into().unwrap()], 'Mint limit not updated');
}

#[test]
fn test_set_burn_limit_by_owner() {
    // Setup
    let mut state = init_vault();
    let owner = contract_address_const::<5>();
    let new_limit = 500_u256;
    let contract_address = test_address();

    // Check initial state
    let initial_state_limit = load(contract_address, selector!("burnLimit"), 1);
    assert(initial_state_limit == array![MAX_BURN_AMOUNT.try_into().unwrap()], 'Wrong burn limit');

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

    let updated_limit = dispatcher.get_mint_limit();
    assert(updated_limit == new_limit, 'Mint limit not updated');

    // Check event emission
    let events = spy.get_events();
    assert(events.events.len() == 1, 'Event not emitted');
    // let expected_event = StarkPlayVault::Event::MintLimitUpdated(
//     StarkPlayVault::MintLimitUpdated { new_mint_limit: new_limit },
// );
// let expected_events = array![(contract_address, expected_event)];
// spy.assert_emitted(@expected_events);
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

    let updated_limit = dispatcher.get_burn_limit();
    assert(updated_limit == new_limit, 'Burn limit not updated');

    // Check event emission
    let events = spy.get_events();
    assert(events.events.len() == 1, 'Event not emitted');
    // let expected_event = StarkPlayVault::Event::BurnLimitUpdated(
//     StarkPlayVault::BurnLimitUpdated { new_burn_limit: new_limit },
// );
// let expected_events = array![(contract_address, expected_event)];
// spy.assert_emitted(@expected_events);
}

#[should_panic(expected: 'Invalid Mint limit')]
#[test]
fn test_mint_limit_zero_value() {
    // Setup
    let vault = deploy_vault();
    let owner = contract_address_const::<5>();
    let contract_address = vault.contract_address;

    // Check initial state
    let initial_state_limit = vault.get_mint_limit();
    assert(initial_state_limit == MAX_MINT_AMOUNT, 'Wrong mint limit');

    // Set caller as owner
    start_cheat_caller_address(contract_address, owner);

    // set new mint limit to zero
    vault.setMintLimit(0);
}

#[should_panic(expected: 'Invalid Burn limit')]
#[test]
fn test_burn_limit_zero_value() {
    // Setup
    let vault = deploy_vault();
    let owner = contract_address_const::<5>();
    let contract_address = vault.contract_address;

    // Check initial state
    let initial_state_limit = vault.get_burn_limit();
    assert(initial_state_limit == MAX_BURN_AMOUNT, 'Wrong burn limit');

    // Set caller as owner
    start_cheat_caller_address(contract_address, owner);

    // set new mint limit to zero
    vault.setBurnLimit(0_u256);
}
#[test]
fn test_set_fee_by_owner() {
    // Setup
    let mut state = init_vault();
    let owner = contract_address_const::<5>();
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
fn test_set_fee_by_non_owner() {
    // Setup
    let dispatcher = deploy_vault();
    let non_owner = contract_address_const::<6>();
    let new_fee = 5000_u64;

    // Set caller as non-owner
    start_cheat_caller_address(dispatcher.contract_address, non_owner);

    // Attempt to set new fee
    dispatcher.set_fee(new_fee);
}

#[should_panic(expected: 'Fee too high')]
#[test]
fn test_set_fee_exceeds_maximum() {
    // Setup
    let dispatcher = deploy_vault();
    let owner = contract_address_const::<5>();
    let invalid_fee = 10001_u64; // Exceeds MAX_FEE_PERCENTAGE (10000)
    let contract_address = dispatcher.contract_address;

    // Set caller as owner
    start_cheat_caller_address(contract_address, owner);

    // Attempt to set fee above maximum
    dispatcher.set_fee(invalid_fee);
}

#[test]
fn test_set_fee_at_maximum_boundary() {
    // Setup
    let dispatcher = deploy_vault();
    let owner = contract_address_const::<5>();
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
fn test_set_fee_to_zero() {
    // Setup
    let dispatcher = deploy_vault();
    let owner = contract_address_const::<5>();
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
fn test_set_fee_emit_event() {
    // Setup
    let dispatcher = deploy_vault();
    let owner = contract_address_const::<5>();
    let new_fee = 2500_u64; // 25%
    let contract_address = dispatcher.contract_address;
    let mut spy = spy_events();

    // Set caller as owner
    start_cheat_caller_address(contract_address, owner);

    // Get initial fee for comparison
    let old_fee = dispatcher.GetFeePercentage();

    // Set new fee
    dispatcher.set_fee(new_fee);

    // Verify fee was updated
    let updated_fee = dispatcher.GetFeePercentage();
    assert(updated_fee == new_fee, 'Fee not updated');

    // Check event emission
    let events = spy.get_events();
    assert(events.events.len() == 1, 'Event not emitted');

    let expected_event = StarkPlayVault::Event::FeeUpdated(
        StarkPlayVault::FeeUpdated { admin: owner, old_fee, new_fee },
    );
    let expected_events = array![(contract_address, expected_event)];
    spy.assert_emitted(@expected_events);
}

#[test]
fn test_set_fee_multiple_times() {
    // Setup
    let dispatcher = deploy_vault();
    let owner = contract_address_const::<5>();
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
    assert(result3 == true, 'Thirdfee should return true');
    assert(dispatcher.GetFeePercentage() == fee3, 'Third fee not updated');
}

#[test]
fn test_fee_queries_reflect_changes() {
    // Setup
    let dispatcher = deploy_vault();
    let owner = contract_address_const::<5>();
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
