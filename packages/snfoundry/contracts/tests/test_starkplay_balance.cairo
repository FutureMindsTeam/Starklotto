use contracts::StarkPlayERC20::{IMintableDispatcher, IMintableDispatcherTrait};
use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    CheatSpan, ContractClassTrait, DeclareResultTrait, declare, start_cheat_caller_address,
    stop_cheat_caller_address,
};
use starknet::ContractAddress;


// Helper constants
pub fn OWNER() -> ContractAddress {
    'OWNER'.try_into().unwrap()
}

pub fn USER() -> ContractAddress {
    'USER'.try_into().unwrap()
}

pub fn USER2() -> ContractAddress {
    'USER2'.try_into().unwrap()
}

pub fn FEE_PERCENT() -> u256 {
    5_u256
}


// Helper: Calculate expected minted amount after fee (5%)
fn expected_minted(strk_amount: u256, fee_percent: u256) -> u256 {
    let fee = (strk_amount * fee_percent) / 100_u256;
    strk_amount - fee
}

fn deploy_erc20() -> ContractAddress {
    let mut constructor_calldata = array![];

    let erc20_class = declare("StarkPlayERC20").unwrap().contract_class();

    // Constructor expects: (recipient: ContractAddress, admin: ContractAddress)
    OWNER().serialize(ref constructor_calldata); // recipient
    OWNER().serialize(ref constructor_calldata); // admin

    // Deploy ERC20
    let (erc20_addr, _) = erc20_class.deploy(@constructor_calldata).unwrap();

    erc20_addr
}

fn deploy_vault() -> (ContractAddress, ContractAddress) {
    let mut constructor_calldata = array![];

    let erc20_addr = deploy_erc20();

    let vault_class = declare("StarkPlayVault").unwrap().contract_class();

    // Constructor expects: (owner: ContractAddress, starkPlayToken: ContractAddress, feePercentage:
    // u64)
    OWNER().serialize(ref constructor_calldata); // owner
    erc20_addr.serialize(ref constructor_calldata); // starkPlayToken
    let fee_percent: u64 = 5;
    fee_percent.serialize(ref constructor_calldata); // feePercentage (convert u256 to u64)

    let (vault_addr, _) = vault_class.deploy(@constructor_calldata).unwrap();

    (vault_addr, erc20_addr)
}


#[test]
fn test_basic_balance_increment() {
    let (vault_addr, erc20_addr) = deploy_vault();

    // Grant minter role and allowance to vault
    // Need to impersonate the OWNER to call admin functions
    start_cheat_caller_address(erc20_addr, OWNER());
    let erc20_disp = IMintableDispatcher { contract_address: erc20_addr };

    erc20_disp.grant_minter_role(vault_addr);
    erc20_disp.set_minter_allowance(vault_addr, 1000_000_000_000_000_000_000_000_u256);
    stop_cheat_caller_address(erc20_addr);

    // Initial balance
    let token_disp = IERC20Dispatcher {
        contract_address: erc20_addr,
    }; // Use IERC20Dispatcher for standard ERC20 methods like balance_of <a href="https://docs.openzeppelin.com/../contracts-cairo/1.0.0/api/erc20#erc20" target="_blank" rel="noopener noreferrer" className="bg-light-secondary dark:bg-dark-secondary px-1 rounded ml-1 no-underline text-xs text-black/70 dark:text-white/70 relative hover:underline">8</a>
    let initial = token_disp.balance_of(USER());
    assert(initial == 0, 'Initial balance should be 0');

    // Mint via vault (simulate buySTRKP)
    let amount = 100_000_000_000_000_000_000_u256; // 100 STRK
    let minted = expected_minted(amount, FEE_PERCENT());
    // Simulate: vault calls mint on ERC20 to user with calculated amount
    // This test directly calls mint on the ERC20 dispatcher for simplicity,
    // assuming the vault would perform a similar call internally.

    start_cheat_caller_address(erc20_addr, vault_addr);
    erc20_disp.mint(USER(), minted);
    stop_cheat_caller_address(erc20_addr);

    let after = token_disp.balance_of(USER());
    assert!(after == minted, "Final balance should match minted");
}

#[test]
fn test_multiple_cumulative_purchases() {
    let (vault_addr, erc20_addr) = deploy_vault();

    start_cheat_caller_address(erc20_addr, OWNER());
    // Grant minter role and allowance to vault
    let erc20_disp = IMintableDispatcher { contract_address: erc20_addr };
    erc20_disp.grant_minter_role(vault_addr);
    erc20_disp.set_minter_allowance(vault_addr, 1000_000_000_000_000_000_000_000_u256);
    stop_cheat_caller_address(erc20_addr);

    let token_disp = IERC20Dispatcher { contract_address: erc20_addr };
    let mut total = 0_u256;
    let amounts = array![
        100_000_000_000_000_000_000_u256,
        200_000_000_000_000_000_000_u256,
        50_000_000_000_000_000_000_u256,
    ];
    let mut i = 0;
    loop {
        if i >= amounts.len() {
            break;
        }
        let amt = *amounts.at(i);
        let minted = expected_minted(amt, FEE_PERCENT());
        start_cheat_caller_address(erc20_addr, vault_addr);
        erc20_disp.mint(USER(), minted); // Simulate minting to user
        total += minted;
        let bal = token_disp.balance_of(USER());
        assert(bal == total, 'Cumulative balance should match');
        i += 1;
        stop_cheat_caller_address(erc20_addr);
    }
}

#[test]
fn test_decimal_precision() {
    let (vault_addr, erc20_addr) = deploy_vault();

    start_cheat_caller_address(erc20_addr, OWNER());
    // Grant minter role and allowance to vault
    let erc20_disp = IMintableDispatcher { contract_address: erc20_addr };
    erc20_disp.grant_minter_role(vault_addr);
    erc20_disp.set_minter_allowance(vault_addr, 1000_000_000_000_000_000_000_u256);
    stop_cheat_caller_address(erc20_addr);

    let token_disp = IERC20Dispatcher { contract_address: erc20_addr };
    let amount = 1_000_000_000_000_000_000_u256; // 1 STRK
    let minted = expected_minted(amount, FEE_PERCENT());
    start_cheat_caller_address(erc20_addr, vault_addr);
    erc20_disp.mint(USER(), minted); // Simulate minting to user
    stop_cheat_caller_address(erc20_addr);
    let bal = token_disp.balance_of(USER());
    assert!(
        bal == 950_000_000_000_000_000_u256, "Should receive exactly 0.95 $tarkPlay",
    ); // Adjusted expected value

    let small = 1_000_000_000_000_000_u256; // 0.001 STRK
    let small_minted = expected_minted(small, FEE_PERCENT());
    start_cheat_caller_address(erc20_addr, vault_addr);
    erc20_disp.mint(USER(), small_minted); // Simulate minting to user
    stop_cheat_caller_address(erc20_addr);
    let bal2 = token_disp.balance_of(USER());
    // Previous balance (0.95) + new minted (0.00095) = 0.95095
    assert!(
        bal2 == 950_950_000_000_000_000_u256, "Should accumulate with precision",
    ); // Adjusted expected value
}

#[test]
fn test_data_integrity_multiple_users() {
    let (vault_addr, erc20_addr) = deploy_vault();

    start_cheat_caller_address(erc20_addr, OWNER());
    // Grant minter role and allowance to vault
    let erc20_disp = IMintableDispatcher { contract_address: erc20_addr };
    erc20_disp.grant_minter_role(vault_addr);
    erc20_disp.set_minter_allowance(vault_addr, 1000_000_000_000_000_000_000_000_u256);
    stop_cheat_caller_address(erc20_addr);

    start_cheat_caller_address(erc20_addr, vault_addr);
    let token_disp = IERC20Dispatcher { contract_address: erc20_addr };
    let amt1 = 100_000_000_000_000_000_000_u256;
    let amt2 = 50_000_000_000_000_000_000_u256;

    // Mint to different users
    erc20_disp.mint(USER(), expected_minted(amt1, FEE_PERCENT())); // Simulate minting to user1
    erc20_disp.mint(USER2(), expected_minted(amt2, FEE_PERCENT())); // Simulate minting to user2
    stop_cheat_caller_address(erc20_addr);

    // Check individual balances
    let bal1 = token_disp.balance_of(USER());
    let bal2 = token_disp.balance_of(USER2());

    // Expected minted for amt1: 100 * 0.95 = 95
    assert(bal1 == 95_000_000_000_000_000_000_u256, 'User1 should have 95');

    // Expected minted for amt2: 50 * 0.95 = 47.5
    assert(bal2 == 47_500_000_000_000_000_000_u256, 'User2 should have 47.5');
}
