use contracts::StarkPlayVault::{IStarkPlayVaultDispatcher, IStarkPlayVaultDispatcherTrait};
use openzeppelin_testing::declare_and_deploy;
use openzeppelin_utils::serde::SerializedAppend;
use snforge_std::{
    CheatSpan, cheat_caller_address, EventSpy, start_cheat_caller_address,
    stop_cheat_caller_address, declare, ContractClassTrait, DeclareResultTrait, spy_events,
    EventSpyAssertionsTrait, EventSpyTrait, // Add for fetching events directly
    Event, // A structure describing a raw `Event`
    IsEmitted // Trait for checking if a given event was ever emitted
};
use starknet::ContractAddress;


// Direcciones de prueba
const OWNER: ContractAddress = 0x02dA5254690b46B9C4059C25366D1778839BE63C142d899F0306fd5c312A5918
    .try_into()
    .unwrap();

const USER: ContractAddress = 0x02dA5254690b46B9C4059C25366D1778839BE63C142d899F0306fd5c312A5918
    .try_into()
    .unwrap();

const Initial_Fee_Percentage: u64 = 50; // 50 basis points = 0.5%
const BASIS_POINTS_DENOMINATOR: u256 = 10000_u256; // 10000 basis points = 100%

//helper function
fn owner_address() -> ContractAddress {
    OWNER
}

fn user_address() -> ContractAddress {
    USER
}

fn deploy_contract_lottery() -> ContractAddress {
    let contract_lotery: ContractAddress =
        0x02dA5254690b46B9C4059C25366D1778839BE63C142d899F0306fd5c312A5918
        .try_into()
        .unwrap();
    contract_lotery
}

fn deploy_contract_starkplayvault() -> ContractAddress {
    let contract_lotery = deploy_contract_lottery();
    let owner = owner_address();
    let initial_fee = 50_u64; // 50 basis points = 0.5%
    let mut calldata = array![];

    calldata.append_serde(contract_lotery);
    calldata.append_serde(owner);
    calldata.append_serde(initial_fee);

    declare_and_deploy("StarkPlayVault", calldata)
}

#[test]
fn test_get_fee_percentage_deploy() {
    //Deploy the contract
    let vault_address = deploy_contract_starkplayvault();

    //dispatch the contract
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };

    //check fee of buy starkplay is correct
    let fee_percentage = vault_dispatcher.GetFeePercentage();

    assert(fee_percentage == Initial_Fee_Percentage, 'Fee percentage should be 0.5%');
}

fn get_fee_amount(feePercentage: u64, amount: u256) -> u256 {
    let feeAmount = (amount * feePercentage.into()) / BASIS_POINTS_DENOMINATOR;
    feeAmount
}

#[test]
fn test_calculate_fee_buy_numbers() {
    let vault_address = deploy_contract_starkplayvault();

    //dispatch the contract
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };

    let fee_percentage = vault_dispatcher.GetFeePercentage();

    let mount_1STARK = 1000000000000000000_u256; // 1 STARK = 10^18
    let mount_10STARK = 10000000000000000000_u256; // 10 STARK 
    let mount_100STARK = 100000000000000000000_u256; // 100 STARK 

    //1 STARK	0.005 STARK
    assert(
        get_fee_amount(fee_percentage, mount_1STARK) == 5000000000000000_u256,
        'Fee correct for 1 STARK',
    );
    //10 STARK	0.05 STARK
    assert(
        get_fee_amount(fee_percentage, mount_10STARK) == 50000000000000000_u256,
        'Fee correct for 10 STARK',
    );
    //100 STARK	0.5 STARK
    assert(
        get_fee_amount(fee_percentage, mount_100STARK) == 500000000000000000_u256,
        'Fee correct for 100 STARK',
    );
}

//--------------TEST ISSUE-TEST-004------------------------------
//tests have to fail
//#[test]
fn test_set_fee_zero_like_negative_value() {
    let vault_address = deploy_contract_starkplayvault();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    let new_fee = 0_u64;
    let result = vault_dispatcher.setFeePercentage(new_fee);
}

//tests have to fail
#[test]
fn test_set_fee_max_like_501() {
    let vault_address = deploy_contract_starkplayvault();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    let new_fee = 501_u64;
    let result = vault_dispatcher.setFeePercentage(new_fee);
}

#[test]
fn test_set_fee_deploy_contract() {
    let vault_address = deploy_contract_starkplayvault();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    let fee_percentage = 50_u64;
    let val = vault_dispatcher.GetFeePercentage();
    assert(val == 50_u64, 'Fee  should be 50');
}

#[test]
fn test_set_fee_min() {
    let vault_address = deploy_contract_starkplayvault();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    let new_fee = 10_u64;
    let result = vault_dispatcher.setFeePercentage(new_fee);
    assert(result == true, 'Fee should be set');
    assert(vault_dispatcher.GetFeePercentage() == new_fee, 'Fee is not 10_u64');
}

#[test]
fn test_set_fee_max() {
    let vault_address = deploy_contract_starkplayvault();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    let new_fee = 500_u64;
    let result = vault_dispatcher.setFeePercentage(new_fee);
    assert(result == true, 'Fee should be set');
    assert(vault_dispatcher.GetFeePercentage() == new_fee, 'Fee is not 500_u64');
}

#[test]
fn test_set_fee_middle() {
    let vault_address = deploy_contract_starkplayvault();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    let new_fee = 250_u64;
    let result = vault_dispatcher.setFeePercentage(new_fee);
    assert(result == true, 'Fee should be set');
    assert(vault_dispatcher.GetFeePercentage() == new_fee, 'Fee is not 250_u64');
}

#[test]
fn test_event_set_fee_percentage() {
    let vault_address = deploy_contract_starkplayvault();
    let vault_dispatcher = IStarkPlayVaultDispatcher { contract_address: vault_address };
    let new_fee = 250_u64;
    let mut spy = spy_events();

    let result = vault_dispatcher.setFeePercentage(new_fee);

    let events = spy.get_events();

    assert(events.events.len() == 1, 'There should be one event');
}
//--------------TEST ISSUE-TEST-004------------------------------


