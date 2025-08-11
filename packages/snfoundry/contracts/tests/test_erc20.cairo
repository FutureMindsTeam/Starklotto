use openzeppelin_access::accesscontrol::interface::{
    IAccessControlDispatcher, IAccessControlDispatcherTrait,
};
use openzeppelin_security::interface::{IPausableDispatcher, IPausableDispatcherTrait};
use openzeppelin_token::erc20::interface::{
    IERC20Dispatcher, IERC20DispatcherTrait, IERC20MetadataDispatcher,
    IERC20MetadataDispatcherTrait,
};
use openzeppelin_utils::serde::SerializedAppend;
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
#[feature("deprecated-starknet-consts")]
use starknet::{ContractAddress, contract_address_const};

pub fn ADMIN() -> ContractAddress {
    contract_address_const::<0x01234>()
}
fn OWNER() -> ContractAddress {
    contract_address_const::<0x01234>()
}
fn USER() -> ContractAddress {
    contract_address_const::<0x0567>()
}
fn STRK_TOKEN_ADDRESS() -> ContractAddress {
    contract_address_const::<0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d>()
}


pub fn deploy_token() -> ContractAddress {
    let contract_class = declare("StarkPlayERC20").unwrap().contract_class();
    let mut calldata = array![];
    calldata.append_serde(ADMIN()); // recipient (unused)
    calldata.append_serde(ADMIN()); // admin
    let (contract_address, _) = contract_class.deploy(@calldata).unwrap();
    contract_address
}


fn deploy_vault(starkplay_token: ContractAddress) -> ContractAddress {
    let contract_class = declare("StarkPlayVault").unwrap().contract_class();
    let mut calldata = array![];
    calldata.append_serde(OWNER());
    calldata.append_serde(starkplay_token);
    calldata.append_serde(5_u64); // feePercentage
    let (contract_address, _) = contract_class.deploy(@calldata).unwrap();
    contract_address
}

#[test]
fn test_initialization() {
    let token_address = deploy_token();
    let erc20_metadata = IERC20MetadataDispatcher { contract_address: token_address };
    let access_control = IAccessControlDispatcher { contract_address: token_address };
    let erc20 = IERC20Dispatcher { contract_address: token_address };
    let pausable = IPausableDispatcher { contract_address: token_address };

    assert(erc20_metadata.name() == "$tarkPlay", 'Incorrect token name');
    assert(erc20_metadata.symbol() == "STARKP", 'Incorrect token symbol');
    assert(erc20_metadata.decimals() == 18, 'Incorrect decimals');
    assert(access_control.has_role(0, ADMIN()), 'Admin role not set');
    // let src5 = ISRC5Dispatcher { contract_address: token_address };
    // let access_control_interface_id: felt252 =
    //     0x3f918d17e5ee77373b56385708f855659a07f75997f365cf8774862850866d;
    // assert(src5.supports_interface(access_control_interface_id), 'Interface not registered');
    assert(erc20.total_supply() == 1000, 'Initial supply should be 1000');
    assert(erc20.balance_of(ADMIN()) == 1000, 'Adm should have initial supp');
    assert(!pausable.is_paused(), 'Contract should not be paused');
}
