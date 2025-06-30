use array::ArrayTrait;
use starknet::testing::set_contract_address;
use starknet::contract_address_const;
use starknet::testing::set_caller_address;
use starknet::ContractAddress;
use starknet::testing::set_block_timestamp;
use openzeppelin::utils::u256;
use openzeppelin::utils::u256_utils::u256_signed_lt;
use openzeppelin::utils::u256_utils::u256_signed_le;
use openzeppelin::utils::u256_utils::u256_signed_gt;
use openzeppelin::utils::u256_utils::u256_signed_ge;
use openzeppelin::utils::u256_utils::u256_signed_eq;
use openzeppelin_token::erc20::interface::IERC20DispatcherTrait;
use super::Lottery;
use super::ILotteryDispatcherTrait;
use super::ILotteryDispatcher;

#[test]
#[available_gas(999999999999999999)]
fn test_buy_ticket_with_sufficient_balance() {
    // Setup test accounts
    let owner = starknet::contract_address_const::<0x1234>();
    let user = starknet::contract_address_const::<0x5678>();
    
    // Deploy token contract (mocked)
    let token_address = starknet::contract_address_const::<0x9999>();
    
    // Deploy lottery contract
    let lottery = Lottery::deploy(@array![owner.into()], owner).unwrap();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery };
    
    // Initialize lottery
    let ticket_price = u256!(1000);
    let initial_prize = u256!(10000);
    lottery_dispatcher.initialize(ticket_price, initial_prize);
    
    // Set up test context
    set_caller_address(user);
    
    // Mock token balance and allowance
    let mut token = IERC20Dispatcher { contract_address: token_address };
    token.mock_balance(user, u256!(5000)); // Sufficient balance
    token.mock_approve(user, lottery, u256!(5000)); // Sufficient allowance
    
    // Buy ticket
    let numbers = array![1, 2, 3, 4, 5];
    lottery_dispatcher.buy_ticket(1, numbers);
    
    // Verify ticket was created
    let user_tickets = lottery_dispatcher.get_user_tickets(1, user);
    assert(user_tickets.len() == 1, 'Ticket was not created');
    
    // Verify balance was deducted
    let new_balance = token.balance_of(user);
    assert(u256_signed_eq(new_balance, u256!(4000)), 'Incorrect balance after purchase');
}

#[test]
#[should_panic(expected: ('Insufficient token balance for ticket purchase',))]
fn test_buy_ticket_with_insufficient_balance() {
    // Setup test accounts
    let owner = starknet::contract_address_const::<0x1234>();
    let user = starknet::contract_address_const::<0x5678>();
    
    // Deploy token contract (mocked)
    let token_address = starknet::contract_address_const::<0x9999>();
    
    // Deploy lottery contract
    let lottery = Lottery::deploy(@array![owner.into()], owner).unwrap();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery };
    
    // Initialize lottery
    let ticket_price = u256!(1000);
    let initial_prize = u256!(10000);
    lottery_dispatcher.initialize(ticket_price, initial_prize);
    
    // Set up test context
    set_caller_address(user);
    
    // Mock token balance (insufficient) and allowance
    let mut token = IERC20Dispatcher { contract_address: token_address };
    token.mock_balance(user, u256!(500)); // Insufficient balance
    token.mock_approve(user, lottery, u256!(5000)); // Sufficient allowance
    
    // This should panic with 'Insufficient token balance for ticket purchase'
    let numbers = array![1, 2, 3, 4, 5];
    lottery_dispatcher.buy_ticket(1, numbers);
}

#[test]
#[should_panic(expected: ('Insufficient token allowance',))]
fn test_buy_ticket_with_insufficient_allowance() {
    // Setup test accounts
    let owner = starknet::contract_address_const::<0x1234>();
    let user = starknet::contract_address_const::<0x5678>();
    
    // Deploy token contract (mocked)
    let token_address = starknet::contract_address_const::<0x9999>();
    
    // Deploy lottery contract
    let lottery = Lottery::deploy(@array![owner.into()], owner).unwrap();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery };
    
    // Initialize lottery
    let ticket_price = u256!(1000);
    let initial_prize = u256!(10000);
    lottery_dispatcher.initialize(ticket_price, initial_prize);
    
    // Set up test context
    set_caller_address(user);
    
    // Mock token balance and insufficient allowance
    let mut token = IERC20Dispatcher { contract_address: token_address };
    token.mock_balance(user, u256!(5000)); // Sufficient balance
    token.mock_approve(user, lottery, u256!(500)); // Insufficient allowance
    
    // This should panic with 'Insufficient token allowance'
    let numbers = array![1, 2, 3, 4, 5];
    lottery_dispatcher.buy_ticket(1, numbers);
}
