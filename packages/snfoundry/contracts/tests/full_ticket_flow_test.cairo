use contracts::Lottery::{ILotteryDispatcher, ILotteryDispatcherTrait, Lottery};
use contracts::StarkPlayERC20::{IMintableDispatcher, IMintableDispatcherTrait};
use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    CheatSpan, EventSpyAssertionsTrait, cheat_block_timestamp, cheat_caller_address, spy_events,
    test_address,
};
use starknet::ContractAddress;
use crate::test_jackpot_history::{OWNER, USER, deploy_lottery};

const DEFAULT_PRICE: u256 = 500;
const DEFAULT_ACCUMULATED_PRIZE: u256 = 1000;
const DEFAULT_ID: u64 = 1;

fn start(lottery: ILotteryDispatcher, target: ContractAddress, amount: u256, spender: ContractAddress) -> IERC20Dispatcher {
    // fn GetStarkPlayContractAddress(self: @TContractState) -> ContractAddress;
    let contract_address = lottery.GetStarkPlayContractAddress();
    let erc = IERC20Dispatcher { contract_address };
    mint(target, amount, spender, erc);
    erc
}

fn mint(target: ContractAddress, amount: u256, spender: ContractAddress, erc: IERC20Dispatcher) {
    let previous_balance = erc.balance_of(target);
    let token = IMintableDispatcher { contract_address: erc.contract_address };
    cheat_caller_address(token.contract_address, OWNER(), CheatSpan::TargetCalls(3));
    token.grant_minter_role(OWNER());
    token.set_minter_allowance(OWNER(), 1000000000);
    token.mint(target, amount);
    let new_balance = erc.balance_of(target);
    assert(new_balance - previous_balance == amount, 'MINTING FAILED');
    cheat_caller_address(token.contract_address, target, CheatSpan::TargetCalls(1));
    erc.approve(spender, amount);
}

fn context(
    ticket_price: u256, accumulated_prize: u256, caller: ContractAddress,
) -> (IERC20Dispatcher, ILotteryDispatcher) {
    let lottery = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery };
    cheat_caller_address(lottery, OWNER(), CheatSpan::TargetCalls(1));
    lottery_dispatcher.Initialize(ticket_price, accumulated_prize);
    let erc = start(lottery_dispatcher, USER(), ticket_price, lottery);
    (erc, lottery_dispatcher)
}

fn default_context() -> (IERC20Dispatcher, ILotteryDispatcher) {
    context(DEFAULT_PRICE, DEFAULT_ACCUMULATED_PRIZE, USER())
}

fn feign_buy_ticket(lottery: ILotteryDispatcher, buyer: ContractAddress) -> Array<u16> {
    let numbers = array![1, 2, 3, 4, 5];
    cheat_caller_address(lottery.contract_address, buyer, CheatSpan::Indefinite);
    cheat_block_timestamp(lottery.contract_address, 1, CheatSpan::TargetCalls(1));
    lottery.BuyTicket(DEFAULT_ID, numbers.clone(), 1);
    numbers
}

#[test]
fn test_buy_ticket_flow_success() {
    let (erc, lottery) = default_context();
    let mut spy = spy_events();
    let numbers = feign_buy_ticket(lottery, USER());
    let event = Lottery::Event::TicketPurchased(
        Lottery::TicketPurchased {
            drawId: 1, player: USER(), ticketId: 0, numbers, ticketCount: 1, timestamp: 1,
        },
    );
    spy.assert_emitted(@array![(lottery.contract_address, event)]);

    let balance = erc.balance_of(USER());
    assert(balance == 0, 'BALANCE SHOULD BE ZERO');

    let tickets = lottery.GetUserTickets(DEFAULT_ID, USER());
    assert(tickets.len() == 1, 'TICKETS LEN SHOUD BE 1');
}

#[test]
fn test_buy_ticket_on_same_draw_id_success() {
    let (erc, lottery) = default_context();
    let some_player = test_address();
    feign_buy_ticket(lottery, USER());
    mint(some_player, DEFAULT_PRICE, lottery.contract_address, erc);
    feign_buy_ticket(lottery, some_player);
    
    let player1_ticket = lottery.GetUserTickets(1, USER());
    let player2_ticket = lottery.GetUserTickets(1, some_player);
    // check if the same buy on the same draw id was successful, len should be 1.
    assert(player1_ticket.len() == 1 && player2_ticket.len() == 1, 'MULTIPLE BUY FAILED.');
}

#[test]
#[should_panic(expected: 'Draw is not active')]
fn test_buy_ticket_should_panic_on_draw_not_active() {
    let (erc, lottery) = default_context();
    let some_player = test_address();
    feign_buy_ticket(lottery, USER());
    mint(some_player, DEFAULT_PRICE, lottery.contract_address, erc);
    cheat_caller_address(lottery.contract_address, OWNER(), CheatSpan::TargetCalls(1));
    lottery.DrawNumbers(DEFAULT_ID);

    feign_buy_ticket(lottery, some_player);
}
