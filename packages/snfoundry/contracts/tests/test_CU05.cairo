use contracts::Lottery::{ILotteryDispatcher, ILotteryDispatcherTrait};
use contracts::StarkPlayERC20::{
    IBurnableDispatcher, IBurnableDispatcherTrait, IMintableDispatcher, IMintableDispatcherTrait,
};
use contracts::StarkPlayVault::{IStarkPlayVaultDispatcher};
use openzeppelin_access::ownable::interface::{IOwnableDispatcher, IOwnableDispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, start_cheat_caller_address,
    stop_cheat_caller_address,
};
use starknet::ContractAddress;

// Standard duration constant from Lottery contract
const STANDARD_DRAW_DURATION_BLOCKS: u64 = 44800;

// Helper functions from test_CU01.cairo
fn owner_address() -> ContractAddress {
    0x123.try_into().unwrap()
}

fn deploy_mock_randomness() -> ContractAddress {
    let randomness_contract = declare("MockRandomness").unwrap().contract_class();
    let (randomness_address, _) = randomness_contract.deploy(@array![]).unwrap();
    randomness_address
}

fn deploy_contract_lottery() -> ContractAddress {
    // Deploy mock contracts first
    let (vault, starkplay_token) = deploy_vault_contract();
    
    // Deploy mock randomness contract
    let randomness_contract_address = deploy_mock_randomness();

    // Deploy Lottery with the mock contracts
    let lottery_contract = declare("Lottery").unwrap().contract_class();
    
    let lottery_constructor_calldata = array![
        owner_address().into(),
        starkplay_token.contract_address.into(),
        vault.contract_address.into(),
        randomness_contract_address.into(),
    ];
    let (lottery_address, _) = lottery_contract.deploy(@lottery_constructor_calldata).unwrap();
    lottery_address
}

fn deploy_vault_contract() -> (IStarkPlayVaultDispatcher, IMintableDispatcher) {
    let initial_fee = 50_u64;
    let _strk_token = deploy_mock_strk_token();

    let starkplay_contract = declare("StarkPlayERC20").unwrap().contract_class();
    let starkplay_constructor_calldata = array![
        owner_address().into(), owner_address().into(),
    ];
    let (starkplay_address, _) = starkplay_contract
        .deploy(@starkplay_constructor_calldata)
        .unwrap();
    let starkplay_token = IMintableDispatcher { contract_address: starkplay_address };
    let starkplay_token_burn = IBurnableDispatcher { contract_address: starkplay_address };

    let vault_contract = declare("StarkPlayVault").unwrap().contract_class();
    let vault_constructor_calldata = array![
        owner_address().into(), starkplay_token.contract_address.into(), initial_fee.into(),
    ];
    let (vault_address, _) = vault_contract.deploy(@vault_constructor_calldata).unwrap();
    let vault = IStarkPlayVaultDispatcher { contract_address: vault_address };

    start_cheat_caller_address(starkplay_token.contract_address, owner_address());
    starkplay_token.grant_minter_role(vault_address);
    starkplay_token_burn.grant_burner_role(vault_address);
    starkplay_token
        .set_minter_allowance(vault_address, 1000000000000000000000000000_u256);
    starkplay_token_burn
        .set_burner_allowance(vault_address, 1000000000000000000000000000_u256);
    stop_cheat_caller_address(starkplay_token.contract_address);

    (vault, starkplay_token)
}

fn deploy_mock_strk_token() -> IMintableDispatcher {
    let target_address: ContractAddress =
        0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
        .try_into()
        .unwrap();

    let contract = declare("StarkPlayERC20").unwrap().contract_class();
    let constructor_calldata = array![owner_address().into(), owner_address().into()];

    let (deployed_address, _) = contract.deploy_at(@constructor_calldata, target_address).unwrap();

    assert(deployed_address == target_address, 'Mock STRk address mismatch');

    let strk_token = IMintableDispatcher { contract_address: deployed_address };
    start_cheat_caller_address(deployed_address, owner_address());

    strk_token.grant_minter_role(owner_address());
    strk_token
        .set_minter_allowance(
            owner_address(), 1000000000000000000000000000_u256,
        );

    strk_token.mint(USER(), 1000000000000000000000000000_u256);

    stop_cheat_caller_address(deployed_address);

    strk_token
}

fn USER() -> ContractAddress {
    0x456.try_into().unwrap()
}

// ============================================================================================
// TESTS FOR ISSUE-CU03-111: Configurable Lottery Duration
// ============================================================================================

#[test]
fn test_create_new_draw_with_custom_duration() {
    // Deploy lottery contract
    let lottery_address = deploy_contract_lottery();
    let lottery = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize the lottery (this creates draw ID 1)
    let owner = IOwnableDispatcher { contract_address: lottery_address };
    start_cheat_caller_address(lottery_address, owner.owner());
    lottery.Initialize(5000000000000000000_u256, 1000000000000000000_u256);
    stop_cheat_caller_address(lottery_address);

    // Get the initial draw ID created by Initialize
    let initial_draw_id = lottery.GetCurrentDrawId();
    assert(initial_draw_id == 1, 'Initial draw ID should be 1');

    // Mark the initial draw as inactive so we can create a new one
    start_cheat_caller_address(lottery_address, owner.owner());
    lottery.SetDrawInactive(initial_draw_id);
    stop_cheat_caller_address(lottery_address);

    // Test creating a draw with custom duration (100 blocks)
    let custom_duration: u64 = 100;
    let accumulated_prize = 2000000000000000000_u256; // 2 STARKP

    start_cheat_caller_address(lottery_address, owner.owner());
    lottery.CreateNewDrawWithDuration(accumulated_prize, custom_duration);
    stop_cheat_caller_address(lottery_address);

    // Verify the new draw was created with correct duration (should be draw ID 2)
    let current_draw_id = lottery.GetCurrentDrawId();
    assert(current_draw_id == 2, 'New draw ID should be 2');

    // Get draw info using the getter functions
    let jackpot_amount = lottery.GetJackpotEntryAmount(current_draw_id);
    let start_block = lottery.GetJackpotEntryStartBlock(current_draw_id);
    let end_block = lottery.GetJackpotEntryEndBlock(current_draw_id);

    assert(jackpot_amount == accumulated_prize, 'Accumulated prize incorrect');
    assert(end_block == start_block + custom_duration, 'End block calculation incorrect');
}

#[test]
fn test_create_new_draw_default_duration() {
    // Deploy lottery contract
    let lottery_address = deploy_contract_lottery();
    let lottery = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize the lottery
    let owner = IOwnableDispatcher { contract_address: lottery_address };
    start_cheat_caller_address(lottery_address, owner.owner());
    lottery.Initialize(5000000000000000000_u256, 1000000000000000000_u256);
    stop_cheat_caller_address(lottery_address);

    // Get the initial draw ID created by Initialize
    let initial_draw_id = lottery.GetCurrentDrawId();
    assert(initial_draw_id == 1, 'Initial draw ID should be 1');

    // Mark the initial draw as inactive so we can test CreateNewDraw
    start_cheat_caller_address(lottery_address, owner.owner());
    lottery.SetDrawInactive(initial_draw_id);
    stop_cheat_caller_address(lottery_address);

    // Test creating a draw with default duration using CreateNewDraw
    let accumulated_prize = 2000000000000000000_u256;

    start_cheat_caller_address(lottery_address, owner.owner());
    lottery.CreateNewDraw(accumulated_prize);
    stop_cheat_caller_address(lottery_address);

    // Verify the draw was created with standard duration
    let current_draw_id = lottery.GetCurrentDrawId();
    let start_block = lottery.GetJackpotEntryStartBlock(current_draw_id);
    let end_block = lottery.GetJackpotEntryEndBlock(current_draw_id);

    assert(end_block == start_block + STANDARD_DRAW_DURATION_BLOCKS, 'Should use standard duration');
}

#[test]
fn test_create_new_draw_with_short_duration() {
    // Deploy lottery contract
    let lottery_address = deploy_contract_lottery();
    let lottery = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize the lottery (this creates draw ID 1)
    let owner = IOwnableDispatcher { contract_address: lottery_address };
    start_cheat_caller_address(lottery_address, owner.owner());
    lottery.Initialize(5000000000000000000_u256, 1000000000000000000_u256);
    stop_cheat_caller_address(lottery_address);

    // Get the initial draw ID created by Initialize
    let initial_draw_id = lottery.GetCurrentDrawId();
    assert(initial_draw_id == 1, 'Initial draw ID should be 1');

    // Mark the initial draw as inactive so we can create a new one
    start_cheat_caller_address(lottery_address, owner.owner());
    lottery.SetDrawInactive(initial_draw_id);
    stop_cheat_caller_address(lottery_address);

    // Test creating a draw with very short duration for testing (10 blocks)
    let short_duration: u64 = 10;
    let accumulated_prize = 1500000000000000000_u256;

    start_cheat_caller_address(lottery_address, owner.owner());
    lottery.CreateNewDrawWithDuration(accumulated_prize, short_duration);
    stop_cheat_caller_address(lottery_address);

    // Verify the draw was created with short duration (should be draw ID 2)
    let current_draw_id = lottery.GetCurrentDrawId();
    assert(current_draw_id == 2, 'New draw ID should be 2');

    let start_block = lottery.GetJackpotEntryStartBlock(current_draw_id);
    let end_block = lottery.GetJackpotEntryEndBlock(current_draw_id);

    assert(end_block == start_block + short_duration, 'Should use short duration');
    assert(end_block == start_block + 10, 'End block should be start + 10');
}

#[test]
fn test_backward_compatibility_create_new_draw() {
    // Deploy lottery contract
    let lottery_address = deploy_contract_lottery();
    let lottery = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize the lottery (this creates draw ID 1)
    let owner = IOwnableDispatcher { contract_address: lottery_address };
    start_cheat_caller_address(lottery_address, owner.owner());
    lottery.Initialize(5000000000000000000_u256, 1000000000000000000_u256);
    stop_cheat_caller_address(lottery_address);

    // Get the initial draw ID created by Initialize
    let initial_draw_id = lottery.GetCurrentDrawId();
    assert(initial_draw_id == 1, 'Initial draw ID should be 1');

    // Mark the initial draw as inactive so we can test CreateNewDraw
    start_cheat_caller_address(lottery_address, owner.owner());
    lottery.SetDrawInactive(initial_draw_id);
    stop_cheat_caller_address(lottery_address);

    // Test that the old CreateNewDraw function still works (should create draw ID 2)
    let accumulated_prize = 2000000000000000000_u256;

    start_cheat_caller_address(lottery_address, owner.owner());
    lottery.CreateNewDraw(accumulated_prize);
    stop_cheat_caller_address(lottery_address);

    // Verify it uses the standard duration (should be draw ID 2)
    let current_draw_id = lottery.GetCurrentDrawId();
    assert(current_draw_id == 2, 'New draw ID should be 2');

    let start_block = lottery.GetJackpotEntryStartBlock(current_draw_id);
    let end_block = lottery.GetJackpotEntryEndBlock(current_draw_id);

    assert(end_block == start_block + STANDARD_DRAW_DURATION_BLOCKS, 'Should use standard duration');
}

#[should_panic(expected: 'Duration must be > 0')]
#[test]
fn test_create_new_draw_with_zero_duration() {
    // Deploy lottery contract
    let lottery_address = deploy_contract_lottery();
    let lottery = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize the lottery (this creates draw ID 1)
    let owner = IOwnableDispatcher { contract_address: lottery_address };
    start_cheat_caller_address(lottery_address, owner.owner());
    lottery.Initialize(5000000000000000000_u256, 1000000000000000000_u256);
    stop_cheat_caller_address(lottery_address);

    // Get the initial draw ID created by Initialize
    let initial_draw_id = lottery.GetCurrentDrawId();
    assert(initial_draw_id == 1, 'Initial draw ID should be 1');

    // Mark the initial draw as inactive so we can test zero duration
    start_cheat_caller_address(lottery_address, owner.owner());
    lottery.SetDrawInactive(initial_draw_id);
    stop_cheat_caller_address(lottery_address);

    // Try to create a draw with zero duration (should panic with 'Duration must be > 0')
    start_cheat_caller_address(lottery_address, owner.owner());
    lottery.CreateNewDrawWithDuration(1000000000000000000_u256, 0_u64);
    stop_cheat_caller_address(lottery_address);
}

// ============================================================================================
// INTEGRATION TEST: Complete Randomness Flow
// ============================================================================================

#[test]
fn test_complete_randomness_flow() {
    // Deploy lottery contract
    let lottery_address = deploy_contract_lottery();
    let lottery = ILotteryDispatcher { contract_address: lottery_address };

    // Initialize the lottery (creates draw ID 1)
    let owner = IOwnableDispatcher { contract_address: lottery_address };
    start_cheat_caller_address(lottery_address, owner.owner());
    lottery.Initialize(5000000000000000000_u256, 1000000000000000000_u256);
    stop_cheat_caller_address(lottery_address);

    // Verify draw was created
    let draw_id = lottery.GetCurrentDrawId();
    assert(draw_id == 1, 'Draw ID should be 1');
    
    // STEP 1: REQUEST - Request random number generation
    // Owner requests randomness with seed
    start_cheat_caller_address(lottery_address, owner.owner());
    let generation_id = lottery.RequestRandomGeneration(draw_id, 12345_u64);
    stop_cheat_caller_address(lottery_address);
    
    // Verify generation ID is correct (should start at 1)
    assert(generation_id == 1, 'Generation ID should be 1');
    
    // STEP 2: VERIFY - Check randomness status (MockRandomness always returns completed)
    // In production, you would wait for VRF to complete here
    // With MockRandomness, status is automatically 2 (completed)
    
    // STEP 3: CONSUME - Draw numbers using the random generation
    start_cheat_caller_address(lottery_address, owner.owner());
    lottery.DrawNumbers(draw_id);
    stop_cheat_caller_address(lottery_address);
    
    // VERIFY RESULTS:
    // 1. Draw should be completed (inactive)
    let is_active = lottery.IsDrawActive(draw_id);
    assert(!is_active, 'Draw should be inactive');
    
    // 2. Winning numbers should be set
    let winning_numbers = lottery.GetWinningNumbers(draw_id);
    assert(winning_numbers.len() == 5, 'Should have 5 numbers');
    
    // 3. All winning numbers should be in valid range (1-40)
    let mut i: usize = 0;
    while i < winning_numbers.len() {
        let number = *winning_numbers.at(i);
        assert(number >= 1 && number <= 40, 'Number out of range');
        i += 1;
    };
    
    // 4. Verify the numbers match MockRandomness expected values
    // MockRandomness returns: [5, 12, 23, 31, 38]
    assert(*winning_numbers.at(0) == 5, 'Number 1 should be 5');
    assert(*winning_numbers.at(1) == 12, 'Number 2 should be 12');
    assert(*winning_numbers.at(2) == 23, 'Number 3 should be 23');
    assert(*winning_numbers.at(3) == 31, 'Number 4 should be 31');
    assert(*winning_numbers.at(4) == 38, 'Number 5 should be 38');
}
