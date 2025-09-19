use starknet::ContractAddress;
use snforge_std::{declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address, stop_cheat_caller_address, spy_events, EventSpyAssertionsTrait};
use contracts::Lottery::{ILotteryDispatcher, ILotteryDispatcherTrait};
use contracts::Lottery::Lottery::{Event as LotteryEvents, EmergencyReentrancyGuardReset};

// Helper function to deploy the lottery contract
fn deploy_lottery_contract() -> (ILotteryDispatcher, ContractAddress) {
    let contract = declare("Lottery").unwrap().contract_class();
    
    let owner: ContractAddress = 'owner'.try_into().unwrap();
    let strkp_contract: ContractAddress = 'strkp_contract'.try_into().unwrap();
    let vault_contract: ContractAddress = 'vault_contract'.try_into().unwrap();
    
    let mut constructor_args = array![];
    constructor_args.append(owner.into());
    constructor_args.append(strkp_contract.into());
    constructor_args.append(vault_contract.into());
    
    let (contract_address, _) = contract.deploy(@constructor_args).unwrap();
    let dispatcher = ILotteryDispatcher { contract_address };
    
    (dispatcher, contract_address)
}

#[test]
fn test_emergency_reset_reentrancy_guard_only_owner() {
    // Deploy lottery contract
    let (lottery_dispatcher, lottery_address) = deploy_lottery_contract();
    
    // Setup event spy
    let mut spy = spy_events();
    
    // Test with owner address
    let owner: ContractAddress = 'owner'.try_into().unwrap();
    start_cheat_caller_address(lottery_address, owner);
    
    // This should succeed - owner can execute emergency reset
    lottery_dispatcher.EmergencyResetReentrancyGuard();
    
    // Verify event emission
    let expected_event = LotteryEvents::EmergencyReentrancyGuardReset(
        EmergencyReentrancyGuardReset {
            caller: owner,
            timestamp: 0, // We're not cheating timestamp so it will be 0
        }
    );
    let expected_events = array![(lottery_address, expected_event)];
    spy.assert_emitted(@expected_events);
    
    stop_cheat_caller_address(lottery_address);
}

#[should_panic(expected: 'Caller is not the owner')]
#[test]
fn test_emergency_reset_reentrancy_guard_non_owner_should_fail() {
    // Deploy lottery contract
    let (lottery_dispatcher, lottery_address) = deploy_lottery_contract();
    
    // Test with non-owner address
    let non_owner: ContractAddress = 'non_owner'.try_into().unwrap();
    start_cheat_caller_address(lottery_address, non_owner);
    
    // This should panic - non-owner cannot execute emergency reset
    lottery_dispatcher.EmergencyResetReentrancyGuard();
    
    stop_cheat_caller_address(lottery_address);
}


#[should_panic(expected: 'Caller is not the owner')]
#[test]
fn test_emergency_reset_non_owner_user1_should_fail() {
    // Deploy lottery contract
    let (lottery_dispatcher, lottery_address) = deploy_lottery_contract();
    
    // Test with non-owner address
    let non_owner: ContractAddress = 'user1'.try_into().unwrap();
    start_cheat_caller_address(lottery_address, non_owner);
    
    // This should panic - non-owner cannot execute emergency reset
    lottery_dispatcher.EmergencyResetReentrancyGuard();
    
    stop_cheat_caller_address(lottery_address);
}


#[should_panic(expected: 'Caller is not the owner')]
#[test]
fn test_emergency_reset_non_owner_user2_should_fail() {
    // Deploy lottery contract
    let (lottery_dispatcher, lottery_address) = deploy_lottery_contract();
    
    // Test with different non-owner address
    let non_owner: ContractAddress = 'user2'.try_into().unwrap();
    start_cheat_caller_address(lottery_address, non_owner);
    
    // This should panic - non-owner cannot execute emergency reset
    lottery_dispatcher.EmergencyResetReentrancyGuard();
    
    stop_cheat_caller_address(lottery_address);
}