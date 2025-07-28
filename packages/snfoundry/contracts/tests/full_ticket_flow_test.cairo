use contracts::Lottery::{ILotteryDispatcher, ILotteryDispatcherTrait};
use openzeppelin_token::erc20::interface::{
    IERC20Dispatcher, IERC20DispatcherTrait, IERC20MetadataDispatcher,
    IERC20MetadataDispatcherTrait,
};
use snforge_std::{
    CheatSpan, ContractClassTrait, DeclareResultTrait, EventSpyTrait, declare, spy_events,
    cheat_caller_address,
};
use starknet::ContractAddress;
use crate::test_jackpot_history::{OWNER, USER, deploy_lottery};
use crate::test_erc20::{ADMIN, deploy_token};

fn mint(target: ContractAddress, amount: u256) {
    let contract_address = deploy_token();
    let dispatcher = IERC20Dispatcher { contract_address };
    let previous_balance = dispatcher.balance_of(target);
    cheat_caller_address(contract_address, ADMIN(), CheatSpan::Indefinite);
    dispatcher.transfer(target, amount);
    let new_balance = dispatcher.balance_of(target);
    assert(new_balance - previous_balance == amount, 'MINTING FAILED');
}

#[test]
fn test_buy_ticket_flow_success() {
    let lottery = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery };
    cheat_caller_address(lottery, OWNER(), CheatSpan::TargetCalls(1));
    // fn Initialize(ref self: TContractState, ticketPrice: u256, accumulatedPrize: u256);
    let ticket_price = 500;
    let accumulated_prize = 1000;
    lottery_dispatcher.Initialize(ticket_price, accumulated_prize);

    let draw_id = 1;
    let numbers = array![1, 2, 3, 4, 5];
    mint(USER(), ticket_price);
    cheat_caller_address(lottery, USER(), CheatSpan::TargetCalls(1));
    lottery_dispatcher.BuyTicket(draw_id, numbers);
}

// the accumulated prize is stored in one creation, and on create new draw, the acumulated prize is changed

// loop {
//     if i >= numbers.len() {
//         break;
//     }

//     let number = *numbers.at(i);

//     // Verify range (0-99)
//     if number > MaxNumber {
//         valid = false;
//         break;
//     }

//     // Verify duplicates
//     if usedNumbers.get(number.into()) == true {
//         valid = false;
//         break;
//     }

//     usedNumbers.insert(number.into(), true);
//     i += 1;
// }
