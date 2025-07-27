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

#[test]
fn test_buy_ticket_flow_success() {
    let lottery = deploy_lottery();
    let lottery_dispatcher = ILotteryDispatcher { contract_address: lottery };
    cheat_caller_address(USER(), lottery, CheatSpan::TargetCalls(1));
    // fn Initialize(ref self: TContractState, ticketPrice: u256, accumulatedPrize: u256);
    let ticket_price = 500;
    let accumulated_price = 1000;
    lottery_dispatcher.Initialize(ticket_price, accumulated_price);

    let draw_id = 1;
    
}
