use contracts::StarkPlayVault::StarkPlayVault::{Event, FeeUpdated};

use contracts::StarkPlayVault::{IStarkPlayVaultDispatcher, IStarkPlayVaultDispatcherTrait};
use contracts::StarkPlayVault::{IStarkPlayVaultSafeDispatcher, IStarkPlayVaultSafeDispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait, declare, spy_events,
    start_cheat_caller_address, stop_cheat_caller_address,
};
use starknet::ContractAddress;
use starknet::contract_address_const;

// Mock addresses for testing
fn get_owner_address() -> ContractAddress {
    contract_address_const::<'owner'>()
}

fn get_non_owner_address() -> ContractAddress {
    contract_address_const::<'non_owner'>()
}

fn get_starkplay_token_address() -> ContractAddress {
    contract_address_const::<'starkplay_token'>()
}

fn deploy_vault_contract(
    owner: ContractAddress, starkplay_token: ContractAddress, fee_percentage: u64,
) -> ContractAddress {
    let contract = declare("StarkPlayVault").unwrap().contract_class();
    let mut constructor_args = ArrayTrait::new();
    constructor_args.append(owner.into());
    constructor_args.append(starkplay_token.into());
    constructor_args.append(fee_percentage.into());

    let (contract_address, _) = contract.deploy(@constructor_args).unwrap();
    contract_address
}

#[test]
fn test_set_fee_success() {
    let owner = get_owner_address();
    let starkplay_token = get_starkplay_token_address();
    let initial_fee = 5_u64; // 5%
    let new_fee = 10_u64; // 10%

    // Deploy contract with initial fee
    let contract_address = deploy_vault_contract(owner, starkplay_token, initial_fee);
    let dispatcher = IStarkPlayVaultDispatcher { contract_address };

    // Verify initial fee
    let current_fee = dispatcher.get_fee_percentage();
    assert(current_fee == initial_fee, 'Initial fee incorrect');

    let mut spy = spy_events();

    // Set caller as owner to have permission
    start_cheat_caller_address(contract_address, owner);

    // Call set_fee with new fee
    let result = dispatcher.set_fee(new_fee);
    assert(result == true, 'set_fee should return true');

    // Stop cheat caller
    stop_cheat_caller_address(contract_address);

    // Verify fee was updated
    let updated_fee = dispatcher.get_fee_percentage();
    assert(updated_fee == new_fee, 'Fee not updated correctly');

    // Verify event emission
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    Event::FeeUpdated(
                        FeeUpdated { admin: owner, old_fee: initial_fee, new_fee: new_fee },
                    ),
                ),
            ],
        );
}

#[test]
#[feature("safe_dispatcher")]
fn test_set_fee_unauthorized_caller() {
    let owner = get_owner_address();
    let non_owner = get_non_owner_address();
    let starkplay_token = get_starkplay_token_address();
    let initial_fee = 5_u64; // 5%
    let new_fee = 8_u64; // 8%

    // Deploy contract
    let contract_address = deploy_vault_contract(owner, starkplay_token, initial_fee);
    let safe_dispatcher = IStarkPlayVaultSafeDispatcher { contract_address };

    // Verify initial fee
    let current_fee = safe_dispatcher.get_fee_percentage().unwrap();
    assert(current_fee == initial_fee, 'Initial fee incorrect');

    // Set caller as non-owner (unauthorized)
    start_cheat_caller_address(contract_address, non_owner);

    // Attempt to set fee with unauthorized caller - should fail
    match safe_dispatcher.set_fee(new_fee) {
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        Result::Err(panic_data) => {
            assert(*panic_data.at(0) == 'Caller is not the owner', *panic_data.at(0));
        },
    };

    // Stop cheating caller address
    stop_cheat_caller_address(contract_address);

    // Verify fee was not changed
    let unchanged_fee = safe_dispatcher.get_fee_percentage().unwrap();
    assert(unchanged_fee == initial_fee, 'Fee should not have changed');
}

#[test]
fn test_only_admin_can_modify_fee() {
    let owner = get_owner_address();
    let random_user = contract_address_const::<'random_user'>();
    let starkplay_token = get_starkplay_token_address();
    let initial_fee = 5_u64;

    let contract_address = deploy_vault_contract(owner, starkplay_token, initial_fee);
    let dispatcher = IStarkPlayVaultDispatcher { contract_address };
    let safe_dispatcher = IStarkPlayVaultSafeDispatcher { contract_address };

    start_cheat_caller_address(contract_address, owner);
    let result = dispatcher.set_fee(8_u64);
    assert(result == true, 'Owner should be able to set fee');
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, random_user);
    match safe_dispatcher.set_fee(10_u64) {
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        Result::Err(panic_data) => {
            assert(*panic_data.at(0) == 'Caller is not the owner', *panic_data.at(0));
        },
    };
    stop_cheat_caller_address(contract_address);

    // Verify fee remains 8% (set by owner)
    let final_fee = dispatcher.get_fee_percentage();
    assert(final_fee == 8_u64, 'Fee should be 8%');
}

#[test]
fn test_fee_modification_different_values() {
    let owner = get_owner_address();
    let starkplay_token = get_starkplay_token_address();
    let initial_fee = 5_u64;

    let contract_address = deploy_vault_contract(owner, starkplay_token, initial_fee);
    let dispatcher = IStarkPlayVaultDispatcher { contract_address };

    start_cheat_caller_address(contract_address, owner);

    // Test different fee values
    let test_fees = array![1_u64, 10_u64, 100_u64, 200_u64]; // 0.01%, 0.1%, 1%, 2%

    let mut i = 0;
    while i < test_fees.len() {
        let fee = *test_fees.at(i);
        let result = dispatcher.set_fee(fee);
        assert(result == true, 'Fee setting should succeed');

        let current_fee = dispatcher.get_fee_percentage();
        assert(current_fee == fee, 'Fee should match set value');

        i += 1;
    };

    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_fee_queries_reflect_changes() {
    let owner = get_owner_address();
    let starkplay_token = get_starkplay_token_address();
    let initial_fee = 5_u64;

    let contract_address = deploy_vault_contract(owner, starkplay_token, initial_fee);
    let dispatcher = IStarkPlayVaultDispatcher { contract_address };

    start_cheat_caller_address(contract_address, owner);

    // Test multiple fee changes and verify queries
    let fee_sequence = array![100_u64, 250_u64, 500_u64, 0_u64, 1000_u64]; // 1%, 2.5%, 5%, 0%, 10%

    let mut i = 0;
    while i < fee_sequence.len() {
        let new_fee = *fee_sequence.at(i);

        // Set new fee
        dispatcher.set_fee(new_fee);

        // Query and verify immediately
        let queried_fee = dispatcher.get_fee_percentage();
        assert(queried_fee == new_fee, 'Immediate query should match');

        // Query again after some operations (to ensure persistence)
        let queried_fee_again = dispatcher.get_fee_percentage();
        assert(queried_fee_again == new_fee, 'Persistent query should match');

        i += 1;
    };

    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_event_emission_on_fee_change() {
    let owner = get_owner_address();
    let starkplay_token = get_starkplay_token_address();
    let initial_fee = 5_u64;

    let contract_address = deploy_vault_contract(owner, starkplay_token, initial_fee);
    let dispatcher = IStarkPlayVaultDispatcher { contract_address };

    let mut spy = spy_events();

    start_cheat_caller_address(contract_address, owner);

    // Test multiple fee changes and verify events
    let fee_changes = array![
        (5_u64, 100_u64), // 5% > 1%
        (100_u64, 250_u64), // 1% > 2.5%
        (250_u64, 0_u64), // 2.5% > 0%
        (0_u64, 1000_u64) // 0% > 10%
    ];

    let mut i = 0;
    while i < fee_changes.len() {
        let (old_fee, new_fee) = *fee_changes.at(i);

        dispatcher.set_fee(new_fee);

        // Verify event emission
        spy
            .assert_emitted(
                @array![
                    (
                        contract_address,
                        Event::FeeUpdated(
                            FeeUpdated { admin: owner, old_fee: old_fee, new_fee: new_fee },
                        ),
                    ),
                ],
            );

        i += 1;
    };

    stop_cheat_caller_address(contract_address);
}

#[test]
#[feature("safe_dispatcher")]
fn test_unauthorized_user_rejection() {
    let owner = get_owner_address();
    let starkplay_token = get_starkplay_token_address();
    let initial_fee = 5_u64;

    let contract_address = deploy_vault_contract(owner, starkplay_token, initial_fee);
    let safe_dispatcher = IStarkPlayVaultSafeDispatcher { contract_address };

    // Test multiple unauthorized users
    let unauthorized_users = array![
        contract_address_const::<'user1'>(),
        contract_address_const::<'user2'>(),
        contract_address_const::<'attacker'>(),
        contract_address_const::<'random'>(),
    ];

    let mut i = 0;
    while i < unauthorized_users.len() {
        let unauthorized_user = *unauthorized_users.at(i);

        start_cheat_caller_address(contract_address, unauthorized_user);

        match safe_dispatcher.set_fee(100_u64) {
            Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
            Result::Err(panic_data) => {
                assert(*panic_data.at(0) == 'Caller is not the owner', *panic_data.at(0));
            },
        };

        stop_cheat_caller_address(contract_address);

        // Verify fee hasn't changed
        let current_fee = safe_dispatcher.get_fee_percentage().unwrap();
        assert(current_fee == initial_fee, 'Fee should remain unchanged');

        i += 1;
    };
}


#[test]
#[feature("safe_dispatcher")]
fn test_set_fee_exceeds_maximum() {
    let owner = get_owner_address();
    let starkplay_token = get_starkplay_token_address();
    let initial_fee = 5_u64;
    let invalid_fee = 10001_u64;

    // Deploy contract
    let contract_address = deploy_vault_contract(owner, starkplay_token, initial_fee);
    let safe_dispatcher = IStarkPlayVaultSafeDispatcher { contract_address };

    // Set caller as owner to have permission
    start_cheat_caller_address(contract_address, owner);

    // Attempt to set fee above maximum - should fail
    match safe_dispatcher.set_fee(invalid_fee) {
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        Result::Err(panic_data) => {
            assert(*panic_data.at(0) == 'Fee too high', *panic_data.at(0));
        },
    };

    // Stop cheat caller
    stop_cheat_caller_address(contract_address);

    // Verify fee was not changed
    let unchanged_fee = safe_dispatcher.get_fee_percentage().unwrap();
    assert(unchanged_fee == initial_fee, 'Fee should not have changed');
}
