use contracts::Lottery::{ILotteryDispatcher, ILotteryDispatcherTrait};
use contracts::StarkPlayERC20::{
    IBurnableDispatcher, IBurnableDispatcherTrait, IMintableDispatcher, IMintableDispatcherTrait,
    IPrizeTokenDispatcher, IPrizeTokenDispatcherTrait,
};
use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    CheatSpan, ContractClassTrait, DeclareResultTrait, EventSpyTrait, cheat_caller_address, declare,
    spy_events,
};
use starknet::ContractAddress;
use crate::test_CU01::{deploy_mock_strk_token as deploy_token, owner_address as owner};
use crate::test_erc20::{ADMIN}; // deploy token here
use crate::test_jackpot_history::{OWNER, USER, deploy_lottery};
use crate::test_starkplayvault::deploy_vault;

fn mint(target: ContractAddress, amount: u256, spender: ContractAddress) -> IERC20Dispatcher {
    let token = deploy_token();
    let erc = IERC20Dispatcher { contract_address: token.contract_address };
    let previous_balance = erc.balance_of(target);
    cheat_caller_address(token.contract_address, owner(), CheatSpan::TargetCalls(1));
    token.mint(target, amount);
    let new_balance = erc.balance_of(target);
    assert(new_balance - previous_balance == amount, 'MINTING FAILED');
    cheat_caller_address(token.contract_address, target, CheatSpan::TargetCalls(1));
    erc.approve(spender, amount);
    erc
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
    let erc = mint(USER(), ticket_price, lottery);
    cheat_caller_address(lottery, USER(), CheatSpan::Indefinite);
    lottery_dispatcher.BuyTicket(draw_id, numbers);

    let balance = erc.balance_of(USER());
    assert(balance == 0, 'BALANCE SHOULD BE ZERO');
}
// the accumulated prize is stored in one creation, and on create new draw, the acumulated prize is
// changed

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


