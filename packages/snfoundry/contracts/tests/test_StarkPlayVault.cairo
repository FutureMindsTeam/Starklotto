use contracts::StarkPlayVault::{IStarkPlayVaultDispatcher, IStarkPlayVaultDispatcherTrait};
use openzeppelin_testing::declare_and_deploy;
use openzeppelin_utils::serde::SerializedAppend;
use snforge_std::{
    CheatSpan, cheat_caller_address, declare, ContractClassTrait, DeclareResultTrait,
    set_balance
};
use starknet::syscalls::call_contract_syscall;
use starknet::{ContractAddress, contract_address_const, SyscallResultTrait};
use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

#[derive(Drop)]
enum Token {
    STRK,
    ETH
}

impl TokenImpl of TokenTrait for Token {
    fn contract_address(self: Token) -> ContractAddress {
        match self {
            Token::STRK => contract_address_const::<0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d>(),
            Token::ETH => contract_address_const::<0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7>()
        }
    }
}

fn OWNER() -> ContractAddress {
    contract_address_const::<0x01234>()
}
fn USER() -> ContractAddress {
    contract_address_const::<0x0567>()
}

fn ADMIN() -> ContractAddress {
    contract_address_const::<0x01234>()
}

const Initial_Fee_Percentage: u64 = 50; // 50 basis points = 0.5%
const BASIS_POINTS_DENOMINATOR: u256 = 10000_u256; // 10000 basis points = 100%

fn deploy_token() -> ContractAddress {
    let contract_class = declare("StarkPlayERC20").unwrap().contract_class();
    let mut calldata = array![];
    calldata.append_serde(ADMIN()); // recipient (unused)
    calldata.append_serde(ADMIN()); // admin
    let (contract_address, _) = contract_class.deploy(@calldata).unwrap();
    contract_address
}

fn deploy_contract_starkplayvault() -> ContractAddress {
    let owner = OWNER();
    let token_address = deploy_token();
    let initial_fee = 50_u64; // 50 basis points = 0.5%
    let mut calldata = array![];

    calldata.append_serde(owner);
    calldata.append_serde(token_address);
    calldata.append_serde(initial_fee);

    declare_and_deploy("StarkPlayVault", calldata)
}

fn get_fee_amount(feePercentage: u64, amount: u256) -> u256 {
    let feeAmount = (amount * feePercentage.into()) / BASIS_POINTS_DENOMINATOR;
    feeAmount
}

// #[test]
// fn test_initialization() {
//     let token_address = deploy_token();
//     let erc20_metadata = IERC20MetadataDispatcher { contract_address: token_address };
//     let access_control = IAccessControlDispatcher { contract_address: token_address };
//     let erc20 = IERC20Dispatcher { contract_address: token_address };
//     let pausable = IPausableDispatcher { contract_address: token_address };

//     assert(erc20_metadata.name() == "$tarkPlay", 'Incorrect token name');
//     assert(erc20_metadata.symbol() == "STARKP", 'Incorrect token symbol');
//     assert(erc20_metadata.decimals() == 18, 'Incorrect decimals');
//     assert(access_control.has_role(0, ADMIN()), 'Admin role not set');
//     assert(erc20.total_supply() == 1000, 'Initial supply should be 1000');
//     assert(erc20.balance_of(ADMIN()) == 1000, 'Adm should have initial supp');
//     assert(!pausable.is_paused(), 'Contract should not be paused');
// }

// #[test]
// fn test_get_fee_percentage_deploy() {
//     //Deploy the contract
//     let vault_address = deploy_contract_starkplayvault();

//     //dispatch the contract
//     let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };

//     //check fee of buy starkplay is correct
//     let fee_percentage = vault_dispatcher.GetFeePercentage();

//     assert(fee_percentage == Initial_Fee_Percentage, 'Fee percentage should be 0.5%');
// }


// #[test]
// fn test_calculate_fee_buy_numbers() {
//     let vault_address = deploy_contract_starkplayvault();

//     //dispatch the contract
//     let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };

//     let fee_percentage = vault_dispatcher.GetFeePercentage();

//     let mount_1STARK = 1000000000000000000_u256; // 1 STARK = 10^18
//     let mount_10STARK = 10000000000000000000_u256; // 10 STARK 
//     let mount_100STARK = 100000000000000000000_u256; // 100 STARK 

//     //1 STARK	0.005 STARK
//     assert(
//         get_fee_amount(fee_percentage, mount_1STARK) == 5000000000000000_u256,
//         'Fee correct for 1 STARK',
//     );
//     //10 STARK	0.05 STARK
//     assert(
//         get_fee_amount(fee_percentage, mount_10STARK) == 50000000000000000_u256,
//         'Fee correct for 10 STARK',
//     );
//     //100 STARK	0.5 STARK
//     assert(
//         get_fee_amount(fee_percentage, mount_100STARK) == 500000000000000000_u256,
//         'Fee correct for 100 STARK',
//     );
// }

// //--------------TEST ISSUE-TEST-004------------------------------
// //tests have to fail
// #[test]
// fn test_set_fee_zero_like_negative_value() {
//     let vault_address = deploy_contract_starkplayvault();
//     let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
//     let new_fee = 0_u64;
//     let result = vault_dispatcher.setFeePercentage(new_fee);
// }

// //tests have to fail
// #[test]
// fn test_set_fee_max_like_501() {
//     let vault_address = deploy_contract_starkplayvault();
//     let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
//     let new_fee = 501_u64;
//     let result = vault_dispatcher.setFeePercentage(new_fee);
// }

// #[test]
// fn test_set_fee_deploy_contract() {
//     let vault_address = deploy_contract_starkplayvault();
//     let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
//     let fee_percentage = 50_u64;
//     let val = vault_dispatcher.GetFeePercentage();
//     assert(val == 50_u64, 'Fee  should be 50');
// }

// #[test]
// fn test_set_fee_min() {
//     let vault_address = deploy_contract_starkplayvault();
//     let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
//     let new_fee = 10_u64;
//     let result = vault_dispatcher.setFeePercentage(new_fee);
//     assert(result == true, 'Fee should be set');
//     assert(vault_dispatcher.GetFeePercentage() == new_fee, 'Fee is not 10_u64');
// }

// #[test]
// fn test_set_fee_max() {
//     let vault_address = deploy_contract_starkplayvault();
//     let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
//     let new_fee = 500_u64;
//     let result = vault_dispatcher.setFeePercentage(new_fee);
//     assert(result == true, 'Fee should be set');
//     assert(vault_dispatcher.GetFeePercentage() == new_fee, 'Fee is not 500_u64');
// }

// #[test]
// fn test_set_fee_middle() {
//     let vault_address = deploy_contract_starkplayvault();
//     let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
//     let new_fee = 250_u64;
//     let result = vault_dispatcher.setFeePercentage(new_fee);
//     assert(result == true, 'Fee should be set');
//     assert(vault_dispatcher.GetFeePercentage() == new_fee, 'Fee is not 250_u64');
// }

// #[test]
// fn test_event_set_fee_percentage() {
//     let vault_address = deploy_contract_starkplayvault();
//     let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
//     let new_fee = 250_u64;
//     let mut spy = spy_events();

//     let result = vault_dispatcher.setFeePercentage(new_fee);

//     let events = spy.get_events();

//     assert(events.events.len() == 1, 'There should be one event');
// }

#[test]
fn test_withdraw_general_fees_success() {
    let token_address = deploy_token();
    let vault_address = deploy_contract_starkplayvault();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    let erc20_dispatcher = IERC20Dispatcher { contract_address: token_address };
    let user = USER();
    
    // Set STRK balance for user using the cheatcode
    set_balance(user, 1000_u256, Token::STRK);
    
    // Verify the balance was set correctly
    let balance = call_contract_syscall(
        Token::STRK.contract_address().into(),
        selector!("balance_of"),
        array![user.into()].span(),
    ).unwrap_syscall();
    assert(balance == array![1000, 0].span(), 'Invalid balance');
    
    // User approves vault to spend STRK
    cheat_caller_address(token_address, user, CheatSpan::TargetCalls(1));
    erc20_dispatcher.approve(vault_address, 1000_u256);
    
    // User buys STRKP, which accumulates fees in the vault
    cheat_caller_address(vault_address, user, CheatSpan::TargetCalls(1));
    vault_dispatcher.buySTRKP(user, 1000_u256);
    
    // Now, as owner, withdraw general fees
    cheat_caller_address(vault_address, OWNER(), CheatSpan::TargetCalls(1));
    let recipient = OWNER();
    let withdraw_amount: u256 = 50_u256; // Should be <= accumulatedFee
    let result = vault_dispatcher.withdrawGeneralFees(recipient, withdraw_amount);
    assert(result, 'Withdraw failed');
}

// // #[test]
// // fn test_withdraw_general_fees_unauthorized() {
// //     let token_address = deploy_token();
// //     let vault_address = deploy_vault(token_address);
// //     let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
// //     // Simulate STRK in vault and accumulatedFee
// //     let deposit_amount: u256 = 1000;
// //     let erc20_dispatcher = IERC20Dispatcher { contract_address: token_address };
// //     cheat_caller_address(token_address, OWNER(), CheatSpan::TargetCalls(1));
// //     erc20_dispatcher.mint(vault_address, deposit_amount);
// //     // Try to withdraw as non-owner
// //     cheat_caller_address(vault_address, USER(), CheatSpan::TargetCalls(1));
// //     let recipient = USER();
// //     let withdraw_amount: u256 = 100;
// //     let result = vault_dispatcher.withdrawGeneralFees(recipient, withdraw_amount);
// //     // Should fail, depending on contract logic (expect revert or false)
// //     // assert(!result, 'Non-owner should not be able to withdraw general fees');
// // }

// // #[test]
// // fn test_withdraw_general_fees_exceeds_accumulated() {
// //     let token_address = deploy_token();
// //     let vault_address = deploy_vault(token_address);
// //     let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
// //     let erc20_dispatcher = IERC20Dispatcher { contract_address: token_address };
// //     cheat_caller_address(token_address, OWNER(), CheatSpan::TargetCalls(1));
// //     erc20_dispatcher.mint(vault_address, 100u256);
// //     // Try to withdraw more than accumulated
// //     cheat_caller_address(vault_address, OWNER(), CheatSpan::TargetCalls(1));
// //     let recipient = USER();
// //     let withdraw_amount: u256 = 1000;
// //     let result = vault_dispatcher.withdrawGeneralFees(recipient, withdraw_amount);
// //     // Should fail, depending on contract logic (expect revert or false)
// //     // assert(!result, 'Should not withdraw more than accumulated general fees');
// // }

// // #[test]
// // fn test_withdraw_prize_conversion_fees_success() {
// //     let token_address = deploy_token();
// //     let vault_address = deploy_vault(token_address);
// //     let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
// //     let erc20_dispatcher = IERC20Dispatcher { contract_address: token_address };
// //     cheat_caller_address(token_address, OWNER(), CheatSpan::TargetCalls(1));
// //     erc20_dispatcher.mint(vault_address, 1000u256);
// //     // Simulate fee accumulation (direct storage or via function)
// //     cheat_caller_address(vault_address, OWNER(), CheatSpan::TargetCalls(1));
// //     let recipient = USER();
// //     let withdraw_amount: u256 = 100;
// //     let result = vault_dispatcher.withdrawPrizeConversionFees(recipient, withdraw_amount);
// //     assert(result, 'Owner should be able to withdraw prize conversion fees');
// // }

// // #[test]
// // fn test_withdraw_prize_conversion_fees_unauthorized() {
// //     let token_address = deploy_token();
// //     let vault_address = deploy_vault(token_address);
// //     let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
// //     let erc20_dispatcher = IERC20Dispatcher { contract_address: token_address };
// //     cheat_caller_address(token_address, OWNER(), CheatSpan::TargetCalls(1));
// //     erc20_dispatcher.mint(vault_address, 1000u256);
// //     cheat_caller_address(vault_address, USER(), CheatSpan::TargetCalls(1));
// //     let recipient = USER();
// //     let withdraw_amount: u256 = 100;
// //     let result = vault_dispatcher.withdrawPrizeConversionFees(recipient, withdraw_amount);
// //     // Should fail, depending on contract logic (expect revert or false)
// //     // assert(!result, 'Non-owner should not be able to withdraw prize conversion fees');
// // }

// // #[test]
// // fn test_withdraw_prize_conversion_fees_exceeds_accumulated() {
// //     let token_address = deploy_token();
// //     let vault_address = deploy_vault(token_address);
// //     let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
// //     let erc20_dispatcher = IERC20Dispatcher { contract_address: token_address };
// //     cheat_caller_address(token_address, OWNER(), CheatSpan::TargetCalls(1));
// //     erc20_dispatcher.mint(vault_address, 100u256);
// //     cheat_caller_address(vault_address, OWNER(), CheatSpan::TargetCalls(1));
// //     let recipient = USER();
// //     let withdraw_amount: u256 = 1000;
// //     let result = vault_dispatcher.withdrawPrizeConversionFees(recipient, withdraw_amount);
// //     // Should fail, depending on contract logic (expect revert or false)
// //     // assert(!result, 'Should not withdraw more than accumulated prize conversion fees');
// // }
