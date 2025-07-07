use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address,
};
#[feature("deprecated-starknet-consts")]
use starknet::{ContractAddress, contract_address_const};
use contracts::StarkPlayVault::{IStarkPlayVaultDispatcher, IStarkPlayVaultDispatcherTrait};
use contracts::StarkPlayERC20::{IMintableDispatcher, IMintableDispatcherTrait};
use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

// Test constants
fn OWNER() -> ContractAddress {
    contract_address_const::<0x123>()
}

fn USER1() -> ContractAddress {
    contract_address_const::<0x456>()
}

fn USER2() -> ContractAddress {
    contract_address_const::<0x789>()
}

fn USER3() -> ContractAddress {
    contract_address_const::<0xABC>()
}


fn INITIAL_FEE_PERCENTAGE() -> u64 {
    50_u64 // 50 basis points = 0.5%
}

fn PURCHASE_AMOUNT() -> u256 {
    1000000000000000000_u256 // 1 STRK
}

fn LARGE_AMOUNT() -> u256 {
    10000000000000000000_u256 // 10 STRK
}

fn deploy_mock_strk_token() -> IMintableDispatcher {
    // Deploy a real STRK token (using StarkPlayERC20 as template)
    let contract = declare("StarkPlayERC20").unwrap().contract_class();
    let constructor_calldata = array![OWNER().into(), OWNER().into()];
    let (deployed_address, _) = contract.deploy(@constructor_calldata).unwrap();

    // Set up the STRK token with initial balances for users
    let strk_token = IMintableDispatcher { contract_address: deployed_address };
    start_cheat_caller_address(deployed_address, OWNER());

    // Grant MINTER_ROLE to OWNER so we can mint tokens
    strk_token.grant_minter_role(OWNER());
    strk_token.set_minter_allowance(OWNER(), 1000000000000000000000000_u256); // Large allowance

    strk_token.mint(USER1(), LARGE_AMOUNT() * 100); // Mint plenty for testing
    strk_token.mint(USER2(), LARGE_AMOUNT() * 100);
    strk_token.mint(USER3(), LARGE_AMOUNT() * 100);
    stop_cheat_caller_address(deployed_address);

    strk_token
}

fn deploy_starkplay_token() -> IMintableDispatcher {
    // Deploy the StarkPlay token that the vault will mint to users
    let contract = declare("StarkPlayERC20").unwrap().contract_class();
    let constructor_calldata = array![OWNER().into(), OWNER().into()];
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    IMintableDispatcher { contract_address }
}

fn deploy_vault_contract(
    strk_token: IMintableDispatcher,
) -> (IStarkPlayVaultDispatcher, IMintableDispatcher) {
    // First deploy the vault to get its address
    let vault_contract = declare("StarkPlayVault").unwrap().contract_class();

    // Deploy StarkPlay token with OWNER as admin (so OWNER can grant roles)
    let starkplay_contract = declare("StarkPlayERC20").unwrap().contract_class();
    let starkplay_constructor_calldata = array![
        OWNER().into(), OWNER().into(),
    ]; // recipient and admin
    let (starkplay_address, _) = starkplay_contract
        .deploy(@starkplay_constructor_calldata)
        .unwrap();
    let starkplay_token = IMintableDispatcher { contract_address: starkplay_address };

    // Deploy vault with the StarkPlay token address
    let vault_constructor_calldata = array![
        OWNER().into(),
        starkplay_token.contract_address.into(),
        strk_token.contract_address.into(),
        INITIAL_FEE_PERCENTAGE().into(),
    ];
    let (vault_address, _) = vault_contract.deploy(@vault_constructor_calldata).unwrap();
    let vault = IStarkPlayVaultDispatcher { contract_address: vault_address };

    // Grant MINTER_ROLE to the vault so it can mint StarkPlay tokens
    start_cheat_caller_address(starkplay_token.contract_address, OWNER());
    starkplay_token.grant_minter_role(vault_address);
    // Set a large allowance for the vault to mint tokens
    starkplay_token
        .set_minter_allowance(vault_address, 1000000000000000000000000_u256); // 1M tokens
    stop_cheat_caller_address(starkplay_token.contract_address);

    (vault, starkplay_token)
}

fn setup_user_balance(
    token: IMintableDispatcher, user: ContractAddress, amount: u256, vault_address: ContractAddress,
) {
    // Mint STRK tokens to user so they can pay
    start_cheat_caller_address(token.contract_address, OWNER());

    // Ensure OWNER has MINTER_ROLE and allowance (should already be set, but just in case)
    token.grant_minter_role(OWNER());
    token.set_minter_allowance(OWNER(), 1000000000000000000000000_u256);

    token.mint(user, amount);
    stop_cheat_caller_address(token.contract_address);

    // Set up allowance so vault can transfer STRK tokens from user
    let erc20_dispatcher = IERC20Dispatcher { contract_address: token.contract_address };
    start_cheat_caller_address(token.contract_address, user);
    erc20_dispatcher.approve(vault_address, amount);
    stop_cheat_caller_address(token.contract_address);
}

// ============================================================================================
// SEQUENTIAL CONSISTENCY TESTS
// ============================================================================================

#[test]
fn test_sequential_fee_consistency() {
    // Deploy real STRK token that users will pay with
    let strk_token = deploy_mock_strk_token();

    let (vault, _) = deploy_vault_contract(strk_token);
    let purchase_amount = PURCHASE_AMOUNT();
    let expected_fee = (purchase_amount * INITIAL_FEE_PERCENTAGE().into()) / 10000; // basis points

    // Setup user balance using the real STRK token (what users pay with)
    setup_user_balance(strk_token, USER1(), LARGE_AMOUNT(), vault.contract_address);

    // Execute 10 consecutive transactions
    let mut i = 0;
    let mut expected_accumulated_fee = 0;

    while i != 10_u64 {
        let initial_accumulated_fee = vault.get_accumulated_fee();

        // Execute transaction - don't cheat caller address, let vault be the caller to mint
        let success = vault.buySTRKP(USER1(), purchase_amount);

        assert(success, 'Transaction should succeed');

        // Verify fee consistency
        let new_accumulated_fee = vault.get_accumulated_fee();
        let actual_fee = new_accumulated_fee - initial_accumulated_fee;

        assert(actual_fee == expected_fee, 'Fee should be consistent');

        expected_accumulated_fee += expected_fee;
        assert(new_accumulated_fee == expected_accumulated_fee, 'Accumulated fee incorrect');

        i += 1;
    };

    // Final verification
    assert(vault.get_accumulated_fee() == expected_fee * 10, 'Final accumulated fee incorrect');
}
// #[test]
// fn test_fee_calculation_accuracy() {
//     let (vault, starkplay_token) = deploy_vault_contract();

//     // Test different amounts
//     let amounts = array![
//         1000000000000000000_u256, // 1 STRK
//         5000000000000000000_u256, // 5 STRK
//         10000000000000000000_u256, // 10 STRK
//         100000000000000000000_u256 // 100 STRK
//     ];

//     setup_user_balance(starkplay_token, USER1(), 1000000000000000000000_u256); // 1000 STRK

//     let mut i = 0;
//     let mut total_expected_fee = 0;

//     while i < amounts.len() {
//         let amount = *amounts.at(i);
//         let expected_fee = (amount * INITIAL_FEE_PERCENTAGE().into()) / 100;

//         let initial_accumulated_fee = vault.get_accumulated_fee();

//         start_cheat_caller_address(vault.contract_address, USER1());
//         vault.buySTRKP(USER1(), amount);
//         stop_cheat_caller_address(vault.contract_address);

//         let actual_fee = vault.get_accumulated_fee() - initial_accumulated_fee;
//         assert(actual_fee == expected_fee, 'Fee calculation incorrect');

//         total_expected_fee += expected_fee;
//         i += 1;
//     };

//     assert(vault.get_accumulated_fee() == total_expected_fee, 'fee accumulation incorrect');
// }

// // ============================================================================================
// // MULTIPLE USERS TESTS
// // ============================================================================================

// #[test]
// fn test_multiple_users_fee_consistency() {
//     let (vault, starkplay_token) = deploy_vault_contract();
//     let purchase_amount = PURCHASE_AMOUNT();
//     let expected_fee = (purchase_amount * INITIAL_FEE_PERCENTAGE().into()) / 100;

//     // Setup balances for multiple users
//     setup_user_balance(starkplay_token, USER1(), LARGE_AMOUNT());
//     setup_user_balance(starkplay_token, USER2(), LARGE_AMOUNT());
//     setup_user_balance(starkplay_token, USER3(), LARGE_AMOUNT());

//     let users = array![USER1(), USER2(), USER3()];
//     let mut i = 0;
//     let mut expected_accumulated_fee = 0;

//     while i < users.len() {
//         let user = *users.at(i);
//         let initial_accumulated_fee = vault.get_accumulated_fee();

//         // Each user makes a purchase
//         start_cheat_caller_address(vault.contract_address, user);
//         let success = vault.buySTRKP(user, purchase_amount);
//         stop_cheat_caller_address(vault.contract_address);

//         assert(success, 'Transaction should succeed');

//         // Verify fee is consistent for each user
//         let actual_fee = vault.get_accumulated_fee() - initial_accumulated_fee;
//         assert(actual_fee == expected_fee, 'Fee should be same for all');

//         expected_accumulated_fee += expected_fee;
//         assert(
//             vault.get_accumulated_fee() == expected_accumulated_fee, 'Accumulated fee incorrect',
//         );

//         i += 1;
//     }
// }

// #[test]
// fn test_concurrent_transactions_simulation() {
//     let (vault, starkplay_token) = deploy_vault_contract();
//     let purchase_amount = PURCHASE_AMOUNT();
//     let expected_fee = (purchase_amount * INITIAL_FEE_PERCENTAGE().into()) / 100;

//     // Setup balances
//     setup_user_balance(starkplay_token, USER1(), LARGE_AMOUNT());
//     setup_user_balance(starkplay_token, USER2(), LARGE_AMOUNT());
//     setup_user_balance(starkplay_token, USER3(), LARGE_AMOUNT());

//     let users = array![USER1(), USER2(), USER3()];
//     let mut fees_collected = ArrayTrait::new();

//     // Simulate concurrent transactions by executing them in rapid succession
//     let mut i = 0;
//     while i < users.len() {
//         let user = *users.at(i);
//         let initial_fee = vault.get_accumulated_fee();

//         start_cheat_caller_address(vault.contract_address, user);
//         vault.buySTRKP(user, purchase_amount);
//         stop_cheat_caller_address(vault.contract_address);

//         let fee_collected = vault.get_accumulated_fee() - initial_fee;
//         fees_collected.append(fee_collected);

//         i += 1;
//     };

//     // Verify all fees are identical
//     let first_fee = *fees_collected.at(0);
//     let mut j = 1;
//     while j < fees_collected.len() {
//         assert(*fees_collected.at(j) == first_fee, 'Fees should be identical');
//         j += 1;
//     };

//     assert(first_fee == expected_fee, 'Fee amount should be correct');
// }

// // ============================================================================================
// // PAUSE/UNPAUSE TESTS
// // ============================================================================================

// #[test]
// fn test_fee_consistency_after_pause_unpause() {
//     let (vault, starkplay_token) = deploy_vault_contract();
//     let purchase_amount = PURCHASE_AMOUNT();
//     let expected_fee = (purchase_amount * INITIAL_FEE_PERCENTAGE().into()) / 100;

//     setup_user_balance(starkplay_token, USER1(), LARGE_AMOUNT());

//     // First transaction before pause
//     start_cheat_caller_address(vault.contract_address, USER1());
//     vault.buySTRKP(USER1(), purchase_amount);
//     stop_cheat_caller_address(vault.contract_address);

//     let fee_before_pause = vault.get_accumulated_fee();
//     assert(fee_before_pause == expected_fee, 'Fee before pause incorrect');

//     // Pause the contract
//     start_cheat_caller_address(vault.contract_address, OWNER());
//     vault.pause();
//     stop_cheat_caller_address(vault.contract_address);

//     assert(vault.is_paused(), 'Contract should be paused');

//     // Unpause the contract
//     start_cheat_caller_address(vault.contract_address, OWNER());
//     vault.unpause();
//     stop_cheat_caller_address(vault.contract_address);

//     assert(!vault.is_paused(), 'Contract should be unpaused');

//     // Transaction after unpause
//     start_cheat_caller_address(vault.contract_address, USER1());
//     vault.buySTRKP(USER1(), purchase_amount);
//     stop_cheat_caller_address(vault.contract_address);

//     let fee_after_unpause = vault.get_accumulated_fee();
//     assert(fee_after_unpause == expected_fee * 2, 'Fee after unpause incorrect');

//     // Verify fee percentage remains the same
//     assert(vault.get_fee_percentage() == INITIAL_FEE_PERCENTAGE(), 'percentage remain
//     unchanged');
// }

// #[test]
// fn test_transaction_fails_when_paused() {
//     let (vault, starkplay_token) = deploy_vault_contract();

//     setup_user_balance(starkplay_token, USER1(), LARGE_AMOUNT());

//     // Pause the contract
//     start_cheat_caller_address(vault.contract_address, OWNER());
//     vault.pause();
//     stop_cheat_caller_address(vault.contract_address);

//     // Try to make a transaction - should fail
//     start_cheat_caller_address(vault.contract_address, USER1());

//     // Test that the contract is paused by checking the paused state
//     assert(vault.is_paused(), 'Contract should be paused');
//     // Note: Cannot test actual panic without causing compilation error
// // The function would panic with 'Contract is paused' if called
// }

// // ============================================================================================
// // FEE ACCUMULATION TESTS
// // ============================================================================================

// #[test]
// fn test_fee_accumulation_with_different_amounts() {
//     let (vault, starkplay_token) = deploy_vault_contract();

//     setup_user_balance(starkplay_token, USER1(), 1000000000000000000000_u256); // 1000 STRK

//     let amounts = array![
//         1000000000000000000_u256, // 1 STRK
//         2000000000000000000_u256, // 2 STRK
//         5000000000000000000_u256, // 5 STRK
//         10000000000000000000_u256 // 10 STRK
//     ];

//     let mut total_expected_fee = 0;
//     let mut i = 0;

//     while i < amounts.len() {
//         let amount = *amounts.at(i);
//         let expected_fee = (amount * INITIAL_FEE_PERCENTAGE().into()) / 100;

//         start_cheat_caller_address(vault.contract_address, USER1());
//         vault.buySTRKP(USER1(), amount);
//         stop_cheat_caller_address(vault.contract_address);

//         total_expected_fee += expected_fee;
//         assert(vault.get_accumulated_fee() == total_expected_fee, 'Accumulated fee incorrect');

//         i += 1;
//     };

//     // Verify final accumulation
//     let final_fee = vault.get_accumulated_fee();
//     assert(final_fee == total_expected_fee, 'Final accumulated fee incorrect');
// }

// #[test]
// fn test_fee_accumulation_multiple_users() {
//     let (vault, starkplay_token) = deploy_vault_contract();
//     let purchase_amount = PURCHASE_AMOUNT();
//     let expected_fee_per_tx = (purchase_amount * INITIAL_FEE_PERCENTAGE().into()) / 100;

//     // Setup balances
//     setup_user_balance(starkplay_token, USER1(), LARGE_AMOUNT());
//     setup_user_balance(starkplay_token, USER2(), LARGE_AMOUNT());
//     setup_user_balance(starkplay_token, USER3(), LARGE_AMOUNT());

//     let users = array![USER1(), USER2(), USER3()];
//     let transactions_per_user = 3;

//     let mut total_expected_fee = 0;
//     let mut user_index = 0;

//     while user_index < users.len() {
//         let user = *users.at(user_index);
//         let mut tx_count = 0;

//         while tx_count < transactions_per_user {
//             start_cheat_caller_address(vault.contract_address, user);
//             vault.buySTRKP(user, purchase_amount);
//             stop_cheat_caller_address(vault.contract_address);

//             total_expected_fee += expected_fee_per_tx;
//             assert(vault.get_accumulated_fee() == total_expected_fee, 'Fee accumulation
//             incorrect');

//             tx_count += 1;
//         };

//         user_index += 1;
//     };

//     // Verify total fees collected
//     let total_transactions = users.len() * transactions_per_user;
//     let expected_total_fee = expected_fee_per_tx * total_transactions.into();
//     assert(vault.get_accumulated_fee() == expected_total_fee, 'fee accumulation incorrect');
// }

// // ============================================================================================
// // ERROR HANDLING TESTS
// // ============================================================================================

// #[test]
// fn test_zero_amount_transaction() {
//     let (vault, starkplay_token) = deploy_vault_contract();

//     setup_user_balance(starkplay_token, USER1(), LARGE_AMOUNT());

//     start_cheat_caller_address(vault.contract_address, USER1());

//     // Test the validation logic without triggering panic
//     // In a real scenario, this would panic with 'Amount must be greater than 0'
//     let zero_amount = 0_u256;
//     assert(zero_amount == 0, 'Zero amount detected correctly');
//     // Note: Actual call would cause panic - vault.buySTRKP(USER1(), 0);
// }

// #[test]
// fn test_insufficient_balance() {
//     let (vault, starkplay_token) = deploy_vault_contract();

//     // Don't setup balance - user has 0 balance
//     start_cheat_caller_address(vault.contract_address, USER1());

//     // Test that user has no balance (would cause 'Insufficient STRK balance' panic)
//     // In practice, we can't call vault.buySTRKP without causing compilation errors
//     // This test verifies the setup where user has insufficient balance
//     let purchase_amount = PURCHASE_AMOUNT();
//     assert(purchase_amount > 0, 'Purchase amount is valid');
//     // Note: Actual call would panic - vault.buySTRKP(USER1(), PURCHASE_AMOUNT());
// }

// #[test]
// fn test_fee_consistency_after_failed_transaction() {
//     let (vault, starkplay_token) = deploy_vault_contract();

//     setup_user_balance(starkplay_token, USER1(), LARGE_AMOUNT());

//     // Successful transaction
//     start_cheat_caller_address(vault.contract_address, USER1());
//     vault.buySTRKP(USER1(), PURCHASE_AMOUNT());
//     stop_cheat_caller_address(vault.contract_address);

//     let fee_after_success = vault.get_accumulated_fee();

//     // Try failed transaction (insufficient balance for USER2)
//     // This should be wrapped in a try-catch in a real scenario

//     // Another successful transaction
//     start_cheat_caller_address(vault.contract_address, USER1());
//     vault.buySTRKP(USER1(), PURCHASE_AMOUNT());
//     stop_cheat_caller_address(vault.contract_address);

//     let expected_fee = (PURCHASE_AMOUNT() * INITIAL_FEE_PERCENTAGE().into()) / 100;
//     assert(
//         vault.get_accumulated_fee() == fee_after_success + expected_fee, 'Fee should be
//         consistent',
//     );
// }

// // ============================================================================================
// // REENTRANCY PROTECTION TESTS
// // ============================================================================================

// #[test]
// fn test_reentrancy_protection() {
//     let (vault, starkplay_token) = deploy_vault_contract();

//     // Test successful transaction (reentrancy guard allows normal flow)
//     start_cheat_caller_address(vault.contract_address, USER1());
//     let success = vault.buySTRKP(USER1(), PURCHASE_AMOUNT());
//     stop_cheat_caller_address(vault.contract_address);

//     assert(success, 'Normal tx should succeed');
//     // Note: Testing actual reentrancy would require a malicious contract
// // that calls back into buySTRKP during execution, which would trigger
// // 'ReentrancyGuard: reentrant call' panic. This is difficult to test
// // without a contract that implements a callback mechanism.
// }

// // ============================================================================================
// // INTEGRATION TESTS
// // ============================================================================================

// #[test]
// fn test_complete_flow_integration() {
//     let (vault, starkplay_token) = deploy_vault_contract();

//     // Setup multiple users
//     setup_user_balance(starkplay_token, USER1(), LARGE_AMOUNT());
//     setup_user_balance(starkplay_token, USER2(), LARGE_AMOUNT());

//     let expected_fee = (PURCHASE_AMOUNT() * INITIAL_FEE_PERCENTAGE().into()) / 100;

//     // Initial state
//     assert(vault.get_accumulated_fee() == 0, 'Initial fee should be 0');
//     assert(vault.get_fee_percentage() == INITIAL_FEE_PERCENTAGE(), 'percentage should be
//     initial');

//     // Multiple transactions
//     start_cheat_caller_address(vault.contract_address, USER1());
//     vault.buySTRKP(USER1(), PURCHASE_AMOUNT());
//     stop_cheat_caller_address(vault.contract_address);

//     assert(vault.get_accumulated_fee() == expected_fee, 'Fee after first transaction');

//     start_cheat_caller_address(vault.contract_address, USER2());
//     vault.buySTRKP(USER2(), PURCHASE_AMOUNT());
//     stop_cheat_caller_address(vault.contract_address);

//     assert(vault.get_accumulated_fee() == expected_fee * 2, 'Fee after second transaction');

//     // Pause and unpause
//     start_cheat_caller_address(vault.contract_address, OWNER());
//     vault.pause();
//     vault.unpause();
//     stop_cheat_caller_address(vault.contract_address);

//     // Transaction after pause/unpause
//     start_cheat_caller_address(vault.contract_address, USER1());
//     vault.buySTRKP(USER1(), PURCHASE_AMOUNT());
//     stop_cheat_caller_address(vault.contract_address);

//     assert(vault.get_accumulated_fee() == expected_fee * 3, 'Fee after pause/unpause');

//     // Verify fee percentage remains consistent
//     assert(vault.get_fee_percentage() == INITIAL_FEE_PERCENTAGE(), 'percentage remain
//     unchanged');
// }


