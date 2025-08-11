use contracts::StarkPlayERC20::{
    IBurnableDispatcher, IBurnableDispatcherTrait, IMintableDispatcher, IMintableDispatcherTrait,
};
use contracts::StarkPlayVault::{IStarkPlayVaultDispatcher, IStarkPlayVaultDispatcherTrait};
use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyTrait, declare, load,
    spy_events, start_cheat_caller_address, stop_cheat_caller_address, store,
};
#[feature("deprecated-starknet-consts")]
use starknet::{ContractAddress, contract_address_const};

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
    // Deploy the mock STRK token at the exact constant address that the vault expects
    let target_address: ContractAddress =
        0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
        .try_into()
        .unwrap();

    let contract = declare("StarkPlayERC20").unwrap().contract_class();
    let constructor_calldata = array![OWNER().into(), OWNER().into()];

    // Deploy at the specific constant address that the vault expects
    let (deployed_address, _) = contract.deploy_at(@constructor_calldata, target_address).unwrap();

    // Verify it deployed at the correct address
    assert(deployed_address == target_address, 'Mock STRK address mismatch');

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

fn deploy_vault_contract() -> (IStarkPlayVaultDispatcher, IMintableDispatcher) {
    // First deploy the mock STRK token at the constant address
    let _strk_token = deploy_mock_strk_token();

    // Deploy StarkPlay token with OWNER as admin (so OWNER can grant roles)
    let starkplay_contract = declare("StarkPlayERC20").unwrap().contract_class();
    let starkplay_constructor_calldata = array![
        OWNER().into(), OWNER().into(),
    ]; // recipient and admin
    let (starkplay_address, _) = starkplay_contract
        .deploy(@starkplay_constructor_calldata)
        .unwrap();
    let starkplay_token = IMintableDispatcher { contract_address: starkplay_address };
    let starkplay_token_burn = IBurnableDispatcher { contract_address: starkplay_address };

    // Deploy vault (no longer needs STRK token address parameter)
    let vault_contract = declare("StarkPlayVault").unwrap().contract_class();
    let vault_constructor_calldata = array![
        OWNER().into(), starkplay_token.contract_address.into(), INITIAL_FEE_PERCENTAGE().into(),
    ];
    let (vault_address, _) = vault_contract.deploy(@vault_constructor_calldata).unwrap();
    let vault = IStarkPlayVaultDispatcher { contract_address: vault_address };

    // Grant MINTER_ROLE and BURNER_ROLE to the vault so it can mint and burn StarkPlay tokens
    start_cheat_caller_address(starkplay_token.contract_address, OWNER());
    starkplay_token.grant_minter_role(vault_address);
    starkplay_token_burn.grant_burner_role(vault_address);
    // Set a large allowance for the vault to mint and burn tokens
    starkplay_token
        .set_minter_allowance(vault_address, 1000000000000000000000000_u256); // 1M tokens
    starkplay_token_burn
        .set_burner_allowance(vault_address, 1000000000000000000000000_u256); // 1M tokens
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
    erc20_dispatcher.approve(vault_address, amount * 10); // Approve 10x the amount to be safe
    stop_cheat_caller_address(token.contract_address);
}

// ============================================================================================
// SEQUENTIAL CONSISTENCY TESTS
// ============================================================================================

#[test]
fn test_sequential_fee_consistency() {
    let (vault, _) = deploy_vault_contract();
    let purchase_amount = PURCHASE_AMOUNT();
    let expected_fee = (purchase_amount * INITIAL_FEE_PERCENTAGE().into()) / 10000; // basis points

    // Get the deployed STRK token for user balance setup
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    // Setup user balance using the deployed STRK token
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
    }

    // Final verification
    assert(vault.get_accumulated_fee() == expected_fee * 10, 'Final accumulated fee incorrect');
}

#[test]
fn test_fee_calculation_accuracy() {
    let (vault, _) = deploy_vault_contract();

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

    setup_user_balance(
        strk_token, USER1(), 1000000000000000000000_u256, vault.contract_address,
    ); // 1000 STRK

    let mut i = 0;
    let mut total_expected_fee = 0;

    while i != amounts.len() {
        let amount = *amounts.at(i);
        let expected_fee = (amount * INITIAL_FEE_PERCENTAGE().into()) / 10000;

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

// //============================================================================================
// // MULTIPLE USERS TESTS
// //============================================================================================

#[test]
fn test_multiple_users_fee_consistency() {
    let (vault, _) = deploy_vault_contract();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    let purchase_amount = PURCHASE_AMOUNT();
    let expected_fee = (purchase_amount * INITIAL_FEE_PERCENTAGE().into()) / 10000;

    // Setup balances for multiple users
    setup_user_balance(strk_token, USER1(), LARGE_AMOUNT(), vault.contract_address);
    setup_user_balance(strk_token, USER2(), LARGE_AMOUNT(), vault.contract_address);
    setup_user_balance(strk_token, USER3(), LARGE_AMOUNT(), vault.contract_address);

    let users = array![USER1(), USER2(), USER3()];
    let mut i = 0;
    let mut expected_accumulated_fee = 0;

    while i != users.len() {
        let user = *users.at(i);
        let initial_accumulated_fee = vault.get_accumulated_fee();

        // Each user makes a purchase
        let success = vault.buySTRKP(user, purchase_amount);

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
    let (vault, _) = deploy_vault_contract();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };
    let purchase_amount = PURCHASE_AMOUNT();
    let expected_fee = (purchase_amount * INITIAL_FEE_PERCENTAGE().into()) / 10000;

    // Setup balances
    setup_user_balance(strk_token, USER1(), LARGE_AMOUNT(), vault.contract_address);
    setup_user_balance(strk_token, USER2(), LARGE_AMOUNT(), vault.contract_address);
    setup_user_balance(strk_token, USER3(), LARGE_AMOUNT(), vault.contract_address);

    let users = array![USER1(), USER2(), USER3()];
    let mut fees_collected = ArrayTrait::new();

    // Simulate concurrent transactions by executing them in rapid succession
    let mut i = 0;
    while i != users.len() {
        let user = *users.at(i);
        let initial_fee = vault.get_accumulated_fee();

        start_cheat_caller_address(vault.contract_address, user);
        vault.buySTRKP(user, purchase_amount);
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

// //============================================================================================
// // PAUSE/UNPAUSE TESTS
// //============================================================================================

#[test]
fn test_fee_consistency_after_pause_unpause() {
    let (vault, _) = deploy_vault_contract();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };
    let purchase_amount = PURCHASE_AMOUNT();
    let expected_fee = (purchase_amount * INITIAL_FEE_PERCENTAGE().into()) / 10000;

    setup_user_balance(strk_token, USER1(), LARGE_AMOUNT(), vault.contract_address);

    // First transaction before pause
    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), purchase_amount);
    stop_cheat_caller_address(vault.contract_address);

    let fee_before_pause = vault.get_accumulated_fee();
    assert(fee_before_pause == expected_fee, 'Fee before pause incorrect');

    // Pause the contract
    start_cheat_caller_address(vault.contract_address, vault.get_owner());
    vault.pause();
    stop_cheat_caller_address(vault.contract_address);

    assert(vault.is_paused(), 'Contract should be paused');

    // Unpause the contract
    start_cheat_caller_address(vault.contract_address, vault.get_owner());
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
    assert(vault.GetFeePercentage() == INITIAL_FEE_PERCENTAGE(), 'percentage changed');
}

#[should_panic(expected: 'Contract is paused')]
#[test]
fn test_transaction_fails_when_paused() {
    let (vault, _) = deploy_vault_contract();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    setup_user_balance(strk_token, USER1(), LARGE_AMOUNT(), vault.contract_address);

    // Pause the contract
    start_cheat_caller_address(vault.contract_address, vault.get_owner());
    vault.pause();
    stop_cheat_caller_address(vault.contract_address);

    assert(vault.is_paused(), 'Contract must be paused');

    // Try to make a transaction - should fail
    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), PURCHASE_AMOUNT());
    stop_cheat_caller_address(vault.contract_address);
}


#[test]
fn test_fee_accumulation_multiple_users() {
    let (vault, _) = deploy_vault_contract();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };
    let purchase_amount = PURCHASE_AMOUNT();
    let expected_fee_per_tx = (purchase_amount * INITIAL_FEE_PERCENTAGE().into()) / 10000;

    // Setup balances
    setup_user_balance(strk_token, USER1(), LARGE_AMOUNT(), vault.contract_address);
    setup_user_balance(strk_token, USER2(), LARGE_AMOUNT(), vault.contract_address);
    setup_user_balance(strk_token, USER3(), LARGE_AMOUNT(), vault.contract_address);

    let users = array![USER1(), USER2(), USER3()];
    let transactions_per_user = 3;

    let mut total_expected_fee = 0;
    let mut user_index = 0;

    while user_index != users.len() {
        let user = *users.at(user_index);
        let mut tx_count = 0;

        while tx_count != transactions_per_user {
            start_cheat_caller_address(vault.contract_address, user);
            vault.buySTRKP(user, purchase_amount);
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

// //============================================================================================
// // ERROR HANDLING TESTS
// //============================================================================================

#[should_panic(expected: 'Amount must be greater than 0')]
#[test]
fn test_zero_amount_transaction() {
    let (vault, _) = deploy_vault_contract();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    setup_user_balance(strk_token, USER1(), LARGE_AMOUNT(), vault.contract_address);

    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), 0_u256);
    stop_cheat_caller_address(vault.contract_address);
}

// //============================================================================================
// // INTEGRATION TESTS
// //============================================================================================

#[test]
fn test_complete_flow_integration() {
    let (vault, _) = deploy_vault_contract();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };
    // Setup multiple users
    setup_user_balance(strk_token, USER1(), LARGE_AMOUNT(), vault.contract_address);
    setup_user_balance(strk_token, USER2(), LARGE_AMOUNT(), vault.contract_address);

    let expected_fee = (PURCHASE_AMOUNT() * INITIAL_FEE_PERCENTAGE().into()) / 10000;

    // Initial state
    assert(vault.get_accumulated_fee() == 0, 'Initial fee must be 0');
    assert(vault.GetFeePercentage() == INITIAL_FEE_PERCENTAGE(), 'percentage must be initial');

    // Multiple transactions
    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), PURCHASE_AMOUNT());
    stop_cheat_caller_address(vault.contract_address);

    assert(vault.get_accumulated_fee() == expected_fee, 'Fee after first transaction');

    start_cheat_caller_address(vault.contract_address, USER2());
    vault.buySTRKP(USER2(), PURCHASE_AMOUNT());
    stop_cheat_caller_address(vault.contract_address);

    assert(vault.get_accumulated_fee() == expected_fee * 2, 'Fee after second transaction');

    // Pause and unpause
    start_cheat_caller_address(vault.contract_address, vault.get_owner());
    vault.pause();
    vault.unpause();
    stop_cheat_caller_address(vault.contract_address);

    // Transaction after pause/unpause
    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), PURCHASE_AMOUNT());
    stop_cheat_caller_address(vault.contract_address);

    assert(vault.get_accumulated_fee() == expected_fee * 3, 'Fee after pause/unpause');

    // Verify fee percentage remains consistent
    assert(vault.GetFeePercentage() == INITIAL_FEE_PERCENTAGE(), 'percentage changed');
}

// ============================================================================================
// WITHDRAWAL TESTS FOR ADMINISTRATOR FEE FUNCTIONS
// ============================================================================================

#[test]
fn test_withdraw_general_fees_success() {
    let (vault, _) = deploy_vault_contract();
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };
    setup_user_balance(strk_token, USER1(), LARGE_AMOUNT(), vault.contract_address);
    let purchase_amount = PURCHASE_AMOUNT();
    let expected_fee = (purchase_amount * INITIAL_FEE_PERCENTAGE().into()) / 10000;
    // User buys STRKP, fee is accumulated
    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), purchase_amount);
    stop_cheat_caller_address(vault.contract_address);
    assert(vault.get_accumulated_fee() == expected_fee, 'Fee not accumulated');
    // Owner withdraws fee
    let owner = vault.get_owner();
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
    let (vault, starkplay) = deploy_vault_contract();
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };
    setup_user_balance(strk_token, USER1(), LARGE_AMOUNT(), vault.contract_address);
    setup_user_balance(starkplay, USER1(), LARGE_AMOUNT(), vault.contract_address);

    let purchase_amount = PURCHASE_AMOUNT();
    let expected_fee = (purchase_amount * INITIAL_FEE_PERCENTAGE().into()) / 10000;
    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), purchase_amount);
    stop_cheat_caller_address(vault.contract_address);
    // Not owner tries to withdraw
    start_cheat_caller_address(vault.contract_address, USER1());
    vault.withdrawGeneralFees(USER2(), expected_fee);
    stop_cheat_caller_address(vault.contract_address);
}

#[should_panic(expected: 'Withdraw amount exceeds fees')]
#[test]
fn test_withdraw_general_fees_exceeds_accumulated() {
    let (vault, _) = deploy_vault_contract();
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };
    setup_user_balance(strk_token, USER1(), LARGE_AMOUNT(), vault.contract_address);
    let purchase_amount = PURCHASE_AMOUNT();
    let expected_fee = (purchase_amount * INITIAL_FEE_PERCENTAGE().into()) / 10000;
    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), purchase_amount);
    stop_cheat_caller_address(vault.contract_address);
    // Owner tries to withdraw more than accumulated
    let owner = vault.get_owner();
    start_cheat_caller_address(vault.contract_address, owner);
    vault.withdrawGeneralFees(USER2(), expected_fee + 1_u256);
    stop_cheat_caller_address(vault.contract_address);
}

#[should_panic(expected: 'Amount must be > 0')]
#[test]
fn test_withdraw_general_fees_zero_amount() {
    let (vault, _) = deploy_vault_contract();
    let owner = vault.get_owner();
    start_cheat_caller_address(vault.contract_address, owner);
    vault.withdrawGeneralFees(USER2(), 0_u256);
    stop_cheat_caller_address(vault.contract_address);
}

#[should_panic(expected: 'Insufficient STRK in vault')]
#[test]
fn test_withdraw_general_fees_insufficient_vault_balance() {
    let (vault, _) = deploy_vault_contract();
    let owner = vault.get_owner();

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

// // Repeat similar tests for PrizeConversionFees

#[test]
fn test_withdraw_prize_conversion_fees_success() {
    let (vault, _starkplay_token) = deploy_vault_contract();
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    setup_user_balance(strk_token, USER1(), LARGE_AMOUNT(), vault.contract_address);
    let convert_amount = PURCHASE_AMOUNT();
    let prizeFeeAmount = (convert_amount * INITIAL_FEE_PERCENTAGE().into()) / 10000;

    // Manually increment accumulatedPrizeConversionFees to simulate conversion
    let owner = vault.get_owner();
    start_cheat_caller_address(vault.contract_address, owner);

    // Use storage manipulation to set accumulated prize conversion fees
    store(
        vault.contract_address,
        selector!("accumulatedPrizeConversionFees"),
        array![prizeFeeAmount.low.into(), prizeFeeAmount.high.into()].span(),
    );

    // Mint STRK tokens to vault so it can pay withdrawal
    start_cheat_caller_address(strk_token.contract_address, OWNER());
    strk_token.mint(vault.contract_address, LARGE_AMOUNT());
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
    let (vault, _) = deploy_vault_contract();

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
    let (vault, _) = deploy_vault_contract();
    let owner = vault.get_owner();

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
    let (vault, _) = deploy_vault_contract();
    let owner = vault.get_owner();
    start_cheat_caller_address(vault.contract_address, owner);
    vault.withdrawPrizeConversionFees(USER2(), 0_u256);
    stop_cheat_caller_address(vault.contract_address);
}

#[should_panic(expected: 'Insufficient STRK in vault')]
#[test]
fn test_withdraw_prize_conversion_fees_insufficient_vault_balance() {
    let (vault, _) = deploy_vault_contract();
    let owner = vault.get_owner();

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

#[test]
fn test_total_starkplay_minted_updates() {
    let (vault, _) = deploy_vault_contract();
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    setup_user_balance(
        strk_token, USER1(), LARGE_AMOUNT() + 200000000000000000000_u256, vault.contract_address,
    );

    assert(vault.get_total_starkplay_minted() == 0, 'Initial minted should be 0');

    let amount1 = LARGE_AMOUNT();
    let expected_minted1 = amount1 - (amount1 * INITIAL_FEE_PERCENTAGE().into()) / 10000;

    vault.buySTRKP(USER1(), amount1);
    assert(vault.get_total_starkplay_minted() == expected_minted1, 'First minting incorrect');

    let amount2 = 200000000000000000000_u256;
    let expected_minted2 = amount2 - (amount2 * INITIAL_FEE_PERCENTAGE().into()) / 10000;
    let expected_total = expected_minted1 + expected_minted2;

    vault.buySTRKP(USER1(), amount2);
    assert(vault.get_total_starkplay_minted() == expected_total, 'Total minted incorrect');
}

#[test]
fn test_total_strk_stored_updates() {
    let (vault, _) = deploy_vault_contract();
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    setup_user_balance(
        strk_token, USER1(), LARGE_AMOUNT() + 500000000000000000000_u256, vault.contract_address,
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
    let (vault, _) = deploy_vault_contract();
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    setup_user_balance(
        strk_token, USER1(), LARGE_AMOUNT() + 500000000000000000000_u256, vault.contract_address,
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
    let (vault, _) = deploy_vault_contract();
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    setup_user_balance(
        strk_token, USER1(), LARGE_AMOUNT() + 500000000000000000000_u256, vault.contract_address,
    );
    setup_user_balance(
        strk_token, USER2(), LARGE_AMOUNT() + 500000000000000000000_u256, vault.contract_address,
    );
    setup_user_balance(
        strk_token, USER3(), LARGE_AMOUNT() + 500000000000000000000_u256, vault.contract_address,
    );

    let users = array![USER1(), USER2(), USER3()];
    let purchase_amount = PURCHASE_AMOUNT();

    let mut expected_total_stored = 0;
    let mut expected_total_minted = 0;
    let mut expected_total_fee = 0;

    let mut i = 0;
    while i != users.len() {
        let user = *users.at(i);

        vault.buySTRKP(user, purchase_amount);

        expected_total_stored += purchase_amount;
        expected_total_minted += purchase_amount
            - (purchase_amount * INITIAL_FEE_PERCENTAGE().into()) / 10000;
        expected_total_fee += (purchase_amount * INITIAL_FEE_PERCENTAGE().into()) / 10000;

        assert(vault.get_total_strk_stored() == expected_total_stored, 'Global stored incorrect');
        assert(
            vault.get_total_starkplay_minted() == expected_total_minted, 'Global minted incorrect',
        );
        assert(vault.get_accumulated_fee() == expected_total_fee, 'Global fee incorrect');

        i += 1;
    }
}

// ============================================================================================
// EVENT TESTING
// ============================================================================================

// Helper function to get the expected minted amount (amount after fee deduction)
fn get_expected_minted_amount(amount_strk: u256, fee_percentage: u64) -> u256 {
    let fee = (amount_strk * fee_percentage.into()) / 10000;
    amount_strk - fee
}

// Helper function to get the expected fee amount
fn get_expected_fee_amount(amount_strk: u256, fee_percentage: u64) -> u256 {
    (amount_strk * fee_percentage.into()) / 10000
}

#[test]
fn test_starkplay_minted_event_emission() {
    let (vault, _) = deploy_vault_contract();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    let purchase_amount = 100000000000000000000_u256; // 100 STRK

    setup_user_balance(strk_token, USER1(), LARGE_AMOUNT(), vault.contract_address);

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
    let expected_fee = get_expected_fee_amount(purchase_amount, INITIAL_FEE_PERCENTAGE());
    assert(vault.get_accumulated_fee() == expected_fee, 'Fee should be correct');
}

#[test]
fn test_event_parameters_validation() {
    let (vault, _) = deploy_vault_contract();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    let purchase_amount = 1000000000000000000_u256; // 1 STRK

    setup_user_balance(strk_token, USER1(), LARGE_AMOUNT(), vault.contract_address);

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
    let (vault, _) = deploy_vault_contract();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    setup_user_balance(strk_token, USER1(), LARGE_AMOUNT(), vault.contract_address);

    let mut spy = spy_events();

    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), PURCHASE_AMOUNT());
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
    let (vault, _) = deploy_vault_contract();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    setup_user_balance(strk_token, USER1(), LARGE_AMOUNT(), vault.contract_address);

    let mut spy = spy_events();

    // Execute 3 consecutive buySTRKP transactions
    let mut i = 0;
    while i != 3 {
        start_cheat_caller_address(vault.contract_address, USER1());
        vault.buySTRKP(USER1(), PURCHASE_AMOUNT());
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
    let expected_fee_per_tx = get_expected_fee_amount(PURCHASE_AMOUNT(), INITIAL_FEE_PERCENTAGE());
    let expected_total_fee = expected_fee_per_tx * 3;
    assert(vault.get_accumulated_fee() == expected_total_fee, 'Fee should match');
}

#[test]
fn test_events_with_different_users() {
    let (vault, _) = deploy_vault_contract();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    setup_user_balance(strk_token, USER1(), LARGE_AMOUNT(), vault.contract_address);
    setup_user_balance(strk_token, USER2(), LARGE_AMOUNT(), vault.contract_address);

    let mut spy = spy_events();

    // USER1 makes a purchase
    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), PURCHASE_AMOUNT());
    stop_cheat_caller_address(vault.contract_address);

    // USER2 makes a purchase
    start_cheat_caller_address(vault.contract_address, USER2());
    vault.buySTRKP(USER2(), PURCHASE_AMOUNT());
    stop_cheat_caller_address(vault.contract_address);

    let events = spy.get_events();

    // Verify that 4 events are emitted (2 users * 2 events each)
    assert(events.events.len() >= 4, 'Should emit 4 events');

    // Verify that both users' transactions were processed
    let expected_fee_per_tx = get_expected_fee_amount(PURCHASE_AMOUNT(), INITIAL_FEE_PERCENTAGE());
    let expected_total_fee = expected_fee_per_tx * 2;
    assert(vault.get_accumulated_fee() == expected_total_fee, 'Fee should match');
}

#[test]
fn test_event_state_consistency() {
    let (vault, starkplay_token) = deploy_vault_contract();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    setup_user_balance(strk_token, USER1(), LARGE_AMOUNT(), vault.contract_address);

    let erc20_dispatcher = IERC20Dispatcher { contract_address: starkplay_token.contract_address };
    let initial_balance = erc20_dispatcher.balance_of(USER1());
    let initial_accumulated_fee = vault.get_accumulated_fee();

    let mut spy = spy_events();

    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), PURCHASE_AMOUNT());
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
    let expected_fee = get_expected_fee_amount(PURCHASE_AMOUNT(), INITIAL_FEE_PERCENTAGE());
    assert(
        final_accumulated_fee == initial_accumulated_fee + expected_fee, 'Fee should be correct',
    );
}

#[should_panic(expected: 'ERC20: insufficient allowance')]
#[test]
fn test_events_in_error_cases() {
    let (vault, _) = deploy_vault_contract();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    // Don't setup user balance - this will cause insufficient balance error

    let mut spy = spy_events();

    // Try to make a transaction that will fail
    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), PURCHASE_AMOUNT());
    stop_cheat_caller_address(vault.contract_address);
}

#[should_panic(expected: 'Amount must be greater than 0')]
#[test]
fn test_events_with_zero_amount() {
    let (vault, _) = deploy_vault_contract();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    setup_user_balance(strk_token, USER1(), LARGE_AMOUNT(), vault.contract_address);

    // Try to make a transaction with zero amount
    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), 0_u256);
    stop_cheat_caller_address(vault.contract_address);
}

#[test]
fn test_events_with_large_amounts() {
    let (vault, _) = deploy_vault_contract();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    let large_amount = 1000000000000000000000_u256; // 1000 STRK
    let expected_fee_amount = get_expected_fee_amount(large_amount, INITIAL_FEE_PERCENTAGE());

    setup_user_balance(strk_token, USER1(), large_amount * 2, vault.contract_address);

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
    let (vault, _) = deploy_vault_contract();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    setup_user_balance(strk_token, USER1(), LARGE_AMOUNT(), vault.contract_address);

    // Pause and unpause the contract
    start_cheat_caller_address(vault.contract_address, vault.get_owner());
    vault.pause();
    vault.unpause();
    stop_cheat_caller_address(vault.contract_address);

    let mut spy = spy_events();

    // Make a transaction after pause/unpause
    start_cheat_caller_address(vault.contract_address, USER1());
    vault.buySTRKP(USER1(), PURCHASE_AMOUNT());
    stop_cheat_caller_address(vault.contract_address);

    let events = spy.get_events();

    // Verify events are still emitted correctly after pause/unpause
    assert(events.events.len() >= 2, 'Should emit events after pause');

    // Verify that the transaction was successful
    let expected_fee = get_expected_fee_amount(PURCHASE_AMOUNT(), INITIAL_FEE_PERCENTAGE());
    assert(vault.get_accumulated_fee() == expected_fee, 'Fee should accumulate');
}

// ============================================================================================
// MINT LIMIT UPDATED EVENT TESTS
// ============================================================================================

#[test]
fn test_mint_limit_updated_event_emission() {
    let (vault, _) = deploy_vault_contract();

    let initial_mint_limit = vault.get_mint_limit();
    let new_mint_limit = 1000000000000000000000_u256; // 1000 tokens

    // Start event spy before transaction
    let mut spy = spy_events();

    // Execute setMintLimit transaction (as owner)
    start_cheat_caller_address(vault.contract_address, OWNER());
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
fn test_mint_limit_updated_event_parameters() {
    let (vault, _) = deploy_vault_contract();

    let new_mint_limit = 500000000000000000000_u256; // 500 tokens

    let mut spy = spy_events();

    // Execute setMintLimit transaction
    start_cheat_caller_address(vault.contract_address, OWNER());
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
    let (vault, _) = deploy_vault_contract();

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

        start_cheat_caller_address(vault.contract_address, OWNER());
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
    let (vault, _) = deploy_vault_contract();

    // Try to set mint limit to zero (should fail)
    start_cheat_caller_address(vault.contract_address, OWNER());
    vault.setMintLimit(0_u256);
    stop_cheat_caller_address(vault.contract_address);
}

#[should_panic(expected: 'Caller is not the owner')]
#[test]
fn test_mint_limit_updated_event_non_owner() {
    let (vault, _) = deploy_vault_contract();

    // Try to set mint limit as non-owner (should fail)
    start_cheat_caller_address(vault.contract_address, USER1());
    vault.setMintLimit(100000000000000000000_u256);
    stop_cheat_caller_address(vault.contract_address);
}

#[test]
fn test_mint_limit_updated_event_large_values() {
    let (vault, _) = deploy_vault_contract();

    let large_limit = 1000000000000000000000000_u256; // 1M tokens

    let mut spy = spy_events();

    // Execute setMintLimit with large value
    start_cheat_caller_address(vault.contract_address, OWNER());
    vault.setMintLimit(large_limit);
    stop_cheat_caller_address(vault.contract_address);

    let events = spy.get_events();

    // Verify that event was emitted
    assert(events.events.len() >= 1, 'Should emit event');

    // Verify that the large mint limit was set correctly
    assert(vault.get_mint_limit() == large_limit, 'Large limit should be set');
}

// Simple working event test - let's start with this one
#[test]
fn test_basic_event_emission() {
    let (vault, _) = deploy_vault_contract();

    // Get the deployed STRK token
    let strk_token = IMintableDispatcher {
        contract_address: 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            .try_into()
            .unwrap(),
    };

    setup_user_balance(strk_token, USER1(), LARGE_AMOUNT(), vault.contract_address);

    // Start event spy before transaction
    let mut spy = spy_events();

    // Execute buySTRKP transaction
    start_cheat_caller_address(vault.contract_address, USER1());
    let success = vault.buySTRKP(USER1(), PURCHASE_AMOUNT());
    stop_cheat_caller_address(vault.contract_address);

    assert(success, 'Transaction should succeed');

    // Get events and verify that events are emitted
    let events = spy.get_events();

    // Simple assertion - just check that some events were emitted
    assert(events.events.len() > 0, 'Should emit events');

    // Verify that the transaction was successful by checking state
    assert(vault.get_accumulated_fee() > 0, 'Fee should be accumulated');
}
