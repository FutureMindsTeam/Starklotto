use starknet::ContractAddress;

// Interface for the deployed Randomness contract
#[starknet::interface]
pub trait IRandomnessLottery<TContractState> {
    fn devnet_generate(ref self: TContractState, seed: u64) -> u64;
    fn get_generation_numbers(self: @TContractState, id: u64) -> Array<u8>;
    fn get_generation_status(self: @TContractState, id: u64) -> u8;
}


//=======================================================================================
//structs
//=======================================================================================
#[derive(Drop, Copy, Serde, starknet::Store)]
//serde for serialization and deserialization
struct Ticket {
    player: ContractAddress,
    number1: u16,
    number2: u16,
    number3: u16,
    number4: u16,
    number5: u16,
    claimed: bool,
    drawId: u64,
    timestamp: u64,
    prize_amount: u256,
    prize_assigned: bool,
}

#[derive(Drop, Copy, Serde, starknet::Store)]
//serde for serialization and deserialization
struct Draw {
    drawId: u64,
    accumulatedPrize: u256,
    winningNumber1: u16,
    winningNumber2: u16,
    winningNumber3: u16,
    winningNumber4: u16,
    winningNumber5: u16,
    //map of ticketId to ticket
    isActive: bool,
    //start time of the draw,timestamp unix (legacy, retained for compatibility) (legacy, retained
    //for compatibility)
    startTime: u64,
    //end time of the draw,timestamp unix (legacy, retained for compatibility) (legacy, retained for
    //compatibility)
    endTime: u64,
    //start block of the draw (primary scheduling reference)
    startBlock: u64,
    //end block of the draw (primary scheduling reference)
    endBlock: u64,
    //prize distribution completed flag (CU-05)
    distribution_done: bool,
}

#[derive(Drop, Copy, Serde, starknet::Store)]
//serde for serialization and deserialization
struct JackpotEntry {
    drawId: u64,
    jackpotAmount: u256,
    startTime: u64,
    endTime: u64,
    startBlock: u64,
    endBlock: u64,
    isActive: bool,
    isCompleted: bool,
}

//=======================================================================================
//interface
//=======================================================================================
#[starknet::interface]
pub trait ILottery<TContractState> {
    //=======================================================================================
    //set functions
    fn Initialize(ref self: TContractState, ticketPrice: u256);
    fn BuyTicket(
        ref self: TContractState, drawId: u64, numbers_array: Array<Array<u16>>, quantity: u8,
    );
    fn DrawNumbers(ref self: TContractState, drawId: u64);
    fn ClaimPrize(ref self: TContractState, drawId: u64, ticketId: felt252);
    fn CheckMatches(
        self: @TContractState,
        drawId: u64,
        number1: u16,
        number2: u16,
        number3: u16,
        number4: u16,
        number5: u16,
    ) -> u8;
    fn CreateNewDraw(ref self: TContractState);
    fn CreateNewDrawWithDuration(ref self: TContractState, duration_blocks: u64);
    fn GetCurrentActiveDraw(self: @TContractState) -> (u64, bool);
    fn SetDrawInactive(ref self: TContractState, drawId: u64);
    fn SetTicketPrice(ref self: TContractState, price: u256);
    fn EmergencyResetReentrancyGuard(ref self: TContractState);
    fn RequestRandomGeneration(ref self: TContractState, drawId: u64, seed: u64) -> u64;
    fn DistributePrizes(ref self: TContractState, drawId: u64);
    fn AddExternalFunds(ref self: TContractState, amount: u256);
    //=======================================================================================
    //get functions
    fn GetTicketPrice(self: @TContractState) -> u256;
    fn GetVaultBalance(self: @TContractState) -> u256;
    fn GetAccumulatedPrize(self: @TContractState) -> u256;
    fn GetFixedPrize(self: @TContractState, drawId: u64, matches: u8) -> u256;
    fn GetDrawStatus(self: @TContractState, drawId: u64) -> bool;
    fn GetBlocksRemaining(self: @TContractState, drawId: u64) -> u64;
    fn IsDrawActive(self: @TContractState, drawId: u64) -> bool;
    fn GetUserTicketIds(
        self: @TContractState, drawId: u64, player: ContractAddress,
    ) -> Array<felt252>;
    fn GetUserTickets(
        ref self: TContractState, drawId: u64, player: ContractAddress,
    ) -> Array<Ticket>;
    fn GetUserTicketsCount(self: @TContractState, drawId: u64, player: ContractAddress) -> u32;
    fn GetTicketInfo(
        self: @TContractState, drawId: u64, ticketId: felt252, player: ContractAddress,
    ) -> Ticket;
    fn GetTicketCurrentId(self: @TContractState) -> u64;
    fn GetWinningNumbers(self: @TContractState, drawId: u64) -> Array<u16>;
    fn get_jackpot_history(self: @TContractState) -> Array<JackpotEntry>;

    // Getter functions for private structures
    fn GetTicketPlayer(self: @TContractState, drawId: u64, ticketId: felt252) -> ContractAddress;
    fn GetTicketNumbers(self: @TContractState, drawId: u64, ticketId: felt252) -> Array<u16>;
    fn GetTicketClaimed(self: @TContractState, drawId: u64, ticketId: felt252) -> bool;
    fn GetTicketDrawId(self: @TContractState, drawId: u64, ticketId: felt252) -> u64;
    fn GetTicketTimestamp(self: @TContractState, drawId: u64, ticketId: felt252) -> u64;

    fn GetJackpotEntryDrawId(self: @TContractState, drawId: u64) -> u64;
    fn GetJackpotEntryAmount(self: @TContractState, drawId: u64) -> u256;
    fn GetJackpotEntryStartTime(self: @TContractState, drawId: u64) -> u64;
    fn GetJackpotEntryEndTime(self: @TContractState, drawId: u64) -> u64;
    fn GetJackpotEntryStartBlock(self: @TContractState, drawId: u64) -> u64;
    fn GetJackpotEntryEndBlock(self: @TContractState, drawId: u64) -> u64;
    fn GetJackpotEntryIsActive(self: @TContractState, drawId: u64) -> bool;
    fn GetJackpotEntryIsCompleted(self: @TContractState, drawId: u64) -> bool;

    // Dynamic address getters
    fn GetStarkPlayContractAddress(self: @TContractState) -> ContractAddress;
    fn GetStarkPlayVaultContractAddress(self: @TContractState) -> ContractAddress;

    // Get current draw ID
    fn GetCurrentDrawId(self: @TContractState) -> u64;

    // Get randomness contract address
    fn GetRandomnessContractAddress(self: @TContractState) -> ContractAddress;
    //=======================================================================================
}

//=======================================================================================
//contract
//=======================================================================================
#[starknet::contract]
pub mod Lottery {
    use core::array::{Array, ArrayTrait};
    use core::dict::{Felt252Dict, Felt252DictTrait};
    use core::traits::TryInto;
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_security::reentrancyguard::ReentrancyGuardComponent;
    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{
        ContractAddress, get_block_number, get_block_timestamp, get_caller_address,
        get_contract_address,
    };
    use super::{
        Draw, ILottery, IRandomnessLotteryDispatcher, IRandomnessLotteryDispatcherTrait,
        JackpotEntry, Ticket,
    };

    // ownable component by openzeppelin
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    //=======================================================================================
    //constants
    //=======================================================================================
    const MinNumber: u16 = 1; // min number
    const MaxNumber: u16 = 40; // max number
    const RequiredNumbers: usize = 5; // amount of numbers per ticket
    // Initial ticket price: 5 STARKP (18 decimals)
    const TicketPriceInitial: u256 = 5000000000000000000;
    // Standard estimated duration of a draw (≈ 1 week) expressed in blocks
    const STANDARD_DRAW_DURATION_BLOCKS: u64 = 44800;

    // Constants for jackpot calculation
    const JACKPOT_PERCENTAGE: u256 = 55; // 55% of purchase amount goes to jackpot
    const PERCENTAGE_DENOMINATOR: u256 = 100; // For percentage calculations

    // reentrancy guard component by openzeppelin
    component!(
        path: ReentrancyGuardComponent, storage: reentrancy_guard, event: ReentrancyGuardEvent,
    );


    //ownable component by openzeppelin
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // reentrancy guard component by openzeppelin
    impl ReentrancyGuardInternalImpl = ReentrancyGuardComponent::InternalImpl<ContractState>;

    // Dynamic contract addresses - will be set in constructor
    // These constants are kept for backward compatibility but should not be used
    const STRK_PLAY_CONTRACT_ADDRESS: felt252 =
        0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d;

    const STRK_PLAY_VAULT_CONTRACT_ADDRESS: felt252 =
        0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d;

    //=======================================================================================
    //events
    //=======================================================================================

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        ReentrancyGuardEvent: ReentrancyGuardComponent::Event,
        TicketPurchased: TicketPurchased,
        BulkTicketPurchase: BulkTicketPurchase,
        DrawCompleted: DrawCompleted,
        PrizeClaimed: PrizeClaimed,
        UserTicketsInfo: UserTicketsInfo,
        JackpotIncreased: JackpotIncreased,
        InvalidDrawIdAttempted: InvalidDrawIdAttempted,
        DrawValidationFailed: DrawValidationFailed,
        EmergencyReentrancyGuardReset: EmergencyReentrancyGuardReset,
        DrawClosed: DrawClosed,
        JackpotCalculated: JackpotCalculated,
        PrizeAssigned: PrizeAssigned,
        PrizesDistributed: PrizesDistributed,
        ExternalFundsAdded: ExternalFundsAdded,
    }

    #[derive(Drop, starknet::Event)]
    pub struct TicketPurchased {
        #[key]
        pub drawId: u64,
        #[key]
        pub player: ContractAddress,
        pub ticketId: felt252,
        pub numbers: Array<u16>,
        pub ticketCount: u32,
        pub timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct BulkTicketPurchase {
        #[key]
        pub drawId: u64,
        #[key]
        pub player: ContractAddress,
        pub quantity: u8,
        pub totalPrice: u256,
        pub timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct DrawCompleted {
        drawId: u64,
        winningNumbers: Array<u16>,
        accumulatedPrize: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct PrizeClaimed {
        #[key]
        drawId: u64,
        #[key]
        player: ContractAddress,
        ticketId: felt252,
        prizeAmount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct UserTicketsInfo {
        #[key]
        player: ContractAddress,
        drawId: u64,
        tickets: Array<Ticket>,
    }

    #[derive(Drop, starknet::Event)]
    struct JackpotIncreased {
        #[key]
        drawId: u64,
        previousAmount: u256,
        newAmount: u256,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct InvalidDrawIdAttempted {
        caller: ContractAddress,
        attempted_draw_id: u64,
        current_draw_id: u64,
        function_name: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct DrawValidationFailed {
        draw_id: u64,
        reason: felt252,
        caller: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct EmergencyReentrancyGuardReset {
        pub caller: ContractAddress,
        pub timestamp: u64,
    }


    #[derive(Drop, starknet::Event)]
    pub struct DrawClosed {
        #[key]
        pub drawId: u64,
        pub timestamp: u64,
        pub caller: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct JackpotCalculated {
        #[key]
        pub draw_id: u64,
        pub vault_balance: u256,
        pub prizes_distributed: u256,
        pub calculated_jackpot: u256,
        pub timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct PrizeAssigned {
        #[key]
        pub drawId: u64,
        #[key]
        pub ticketId: felt252,
        pub level: u8,
        pub amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct PrizesDistributed {
        #[key]
        pub drawId: u64,
        pub winners_total: u32,
        pub total_distributed: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ExternalFundsAdded {
        #[key]
        pub contributor: ContractAddress,
        #[key]
        pub drawId: u64,
        pub amount: u256,
        pub new_jackpot: u256,
        pub timestamp: u64,
    }

    //=======================================================================================
    //storage
    //=======================================================================================
    #[storage]
    struct Storage {
        ticketPrice: u256,
        currentDrawId: u64,
        currentTicketId: u64,
        fixedPrize4Matches: u256,
        fixedPrize3Matches: u256,
        fixedPrize2Matches: u256,
        accumulatedPrize: u256,
        userTickets: Map<(ContractAddress, u64), felt252>,
        userTicketCount: Map<(ContractAddress, u64), u32>, // (user, drawId) -> user ticket count
        // (user, drawId, index)-> ticketId
        userTicketIds: Map<(ContractAddress, u64, u32), felt252>,
        draws: Map<u64, Draw>,
        tickets: Map<(u64, felt252), Ticket>,
        // (drawId, index) -> ticketId for iterating all tickets in a draw
        drawTicketIds: Map<(u64, u32), felt252>,
        // drawId -> total ticket count for that draw
        drawTicketCount: Map<u64, u32>,
        // Total prizes distributed per draw (for jackpot calculation)
        totalPrizesDistributed: Map<u64, u256>,
        // Dynamic contract addresses
        strkPlayContractAddress: ContractAddress,
        strkPlayVaultContractAddress: ContractAddress,
        // Address of the deployed Randomness contract
        randomnessContractAddress: ContractAddress,
        // Randomness generation ID counter (starts at 1)
        currentRandomnessId: u64,
        // ownable component by openzeppelin
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        // reentrancy guard component by openzeppelin
        #[substorage(v0)]
        reentrancy_guard: ReentrancyGuardComponent::Storage,
    }
    //=======================================================================================
    //constructor
    //=======================================================================================

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        strkPlayContractAddress: ContractAddress,
        strkPlayVaultContractAddress: ContractAddress,
        randomnessContractAddress: ContractAddress,
    ) {
        // Validate that addresses are not zero address
        assert(strkPlayContractAddress != 0.try_into().unwrap(), 'Invalid STRKP contract');
        assert(strkPlayVaultContractAddress != 0.try_into().unwrap(), 'Invalid Vault contract');
        assert(randomnessContractAddress != 0.try_into().unwrap(), 'Invalid Randomness contract');

        self.ownable.initializer(owner);
        self.fixedPrize4Matches.write(4000000000000000000);
        self.fixedPrize3Matches.write(3000000000000000000);
        self.fixedPrize2Matches.write(2000000000000000000);
        self.currentDrawId.write(0);
        self.currentTicketId.write(0);
        self.currentRandomnessId.write(1); // Initialize at 1

        // Store dynamic contract addresses
        self.strkPlayContractAddress.write(strkPlayContractAddress);
        self.strkPlayVaultContractAddress.write(strkPlayVaultContractAddress);
        self.randomnessContractAddress.write(randomnessContractAddress);
        self.ticketPrice.write(TicketPriceInitial);
    }
    //=======================================================================================
    //impl
    //=======================================================================================

    #[abi(embed_v0)]
    impl LotteryImpl of ILottery<ContractState> {
        //OK
        fn Initialize(ref self: ContractState, ticketPrice: u256) {
            self.ownable.assert_only_owner();
            self.ticketPrice.write(ticketPrice);
            // CreateNewDraw will calculate the jackpot automatically from vault balance
            self.CreateNewDraw();
        }

        //=======================================================================================
        //OK
        fn BuyTicket(
            ref self: ContractState, drawId: u64, numbers_array: Array<Array<u16>>, quantity: u8,
        ) {
            // Reentrancy guard using OpenZeppelin component
            self.reentrancy_guard.start();

            // Validate quantity limits first (1-10 tickets)
            assert(quantity >= 1, 'Quantity too low');
            assert(quantity <= 10, 'Quantity too high');

            // Input validation for numbers array
            assert(self.ValidateNumbersArray(@numbers_array, quantity), 'Invalid array');

            // Validate that draw exists
            self.AssertDrawExists(drawId, 'BuyTicket');

            // Validate that draw is active
            let draw = self.draws.entry(drawId).read();
            assert(draw.isActive, 'Draw is not active');

            let current_timestamp = get_block_timestamp();

            // Process the payment
            let token_dispatcher = IERC20Dispatcher {
                contract_address: self.strkPlayContractAddress.read(),
            };

            // --- CORRECTED: Calculate total price for all tickets ---
            let ticket_price = self.ticketPrice.read();
            let total_price = ticket_price * quantity.into();
            let user = get_caller_address();
            let vault_address: ContractAddress = self.strkPlayVaultContractAddress.read();

            // Validate user has sufficient token balance for total price
            let user_balance = token_dispatcher.balance_of(user);
            assert(user_balance > 0, 'No token balance');
            assert(user_balance >= total_price, 'Insufficient balance');

            // Validate user has approved lottery contract for total price
            let allowance = token_dispatcher.allowance(user, get_contract_address());
            assert(allowance >= total_price, 'Insufficient allowance');

            // Execute token transfer for total price
            let transfer_success = token_dispatcher.transfer_from(user, vault_address, total_price);
            assert(transfer_success, 'Transfer failed');

            // --- End corrected payment logic ---

            // Calculate 55% of total price to add to jackpot
            let jackpot_contribution = (total_price * JACKPOT_PERCENTAGE) / PERCENTAGE_DENOMINATOR;

            // Update the specific draw's accumulated prize
            // Note: We only update the draw's jackpot, not the global accumulatedPrize
            // The global accumulatedPrize is recalculated from vault balance when creating new draws
            let mut current_draw = self.draws.entry(drawId).read();
            let previous_draw_jackpot = current_draw.accumulatedPrize;
            current_draw.accumulatedPrize = current_draw.accumulatedPrize + jackpot_contribution;
            self.draws.entry(drawId).write(current_draw);

            // Emit event for jackpot increase
            self
                .emit(
                    JackpotIncreased {
                        drawId,
                        previousAmount: previous_draw_jackpot,
                        newAmount: previous_draw_jackpot + jackpot_contribution,
                        timestamp: current_timestamp,
                    },
                );

            // Emit bulk purchase event for auditing
            self
                .emit(
                    BulkTicketPurchase {
                        drawId,
                        player: user,
                        quantity,
                        totalPrice: total_price,
                        timestamp: current_timestamp,
                    },
                );

            let caller = get_caller_address();
            let mut count = self.userTicketCount.entry((caller, drawId)).read();

            // Generate multiple tickets with unique numbers
            let mut i: u8 = 0;
            while i != quantity {
                // TODO: Mint the NFT here, for now it is simulated
                let minted = true;
                assert(minted, 'NFT minting failed');

                // Get numbers for this specific ticket
                let ticket_numbers = numbers_array.at(i.into());
                let n1 = *ticket_numbers.at(0);
                let n2 = *ticket_numbers.at(1);
                let n3 = *ticket_numbers.at(2);
                let n4 = *ticket_numbers.at(3);
                let n5 = *ticket_numbers.at(4);

                let ticketNew = Ticket {
                    player: caller,
                    number1: n1,
                    number2: n2,
                    number3: n3,
                    number4: n4,
                    number5: n5,
                    claimed: false,
                    drawId: drawId,
                    timestamp: current_timestamp,
                    prize_amount: 0,
                    prize_assigned: false,
                };

                let ticketId = GenerateTicketId(ref self);
                self.tickets.entry((drawId, ticketId)).write(ticketNew);

                // Increment counter and save ticketId
                count += 1;
                self.userTicketCount.entry((caller, drawId)).write(count);
                self.userTicketIds.entry((caller, drawId, count)).write(ticketId);

                // Also track all tickets globally for the draw
                let mut draw_ticket_count = self.drawTicketCount.entry(drawId).read();
                draw_ticket_count += 1;
                self.drawTicketCount.entry(drawId).write(draw_ticket_count);
                self.drawTicketIds.entry((drawId, draw_ticket_count)).write(ticketId);

                // Emit event for each generated ticket with its specific numbers
                let mut event_numbers = ArrayTrait::new();
                event_numbers.append(n1);
                event_numbers.append(n2);
                event_numbers.append(n3);
                event_numbers.append(n4);
                event_numbers.append(n5);

                self
                    .emit(
                        TicketPurchased {
                            drawId,
                            player: caller,
                            ticketId,
                            numbers: event_numbers,
                            ticketCount: count,
                            timestamp: current_timestamp,
                        },
                    );

                i += 1;
            }

            // Release reentrancy guard
            self.reentrancy_guard.end();
        }
        //=======================================================================================
        fn GetUserTicketsCount(self: @ContractState, drawId: u64, player: ContractAddress) -> u32 {
            self.userTicketCount.entry((player, drawId)).read()
        }

        //=======================================================================================
        fn DrawNumbers(ref self: ContractState, drawId: u64) {
            self.ownable.assert_only_owner();
            let mut draw = self.draws.entry(drawId).read();
            assert(draw.isActive, 'Draw is not active');

            // Get current randomness ID
            let current_randomness_id = self.currentRandomnessId.read();

            // Create dispatcher for the deployed Randomness contract
            let randomness_dispatcher = IRandomnessLotteryDispatcher {
                contract_address: self.randomnessContractAddress.read(),
            };

            // Validate that generation is completed (status = 2)
            let status = randomness_dispatcher.get_generation_status(current_randomness_id);
            assert(status == 2_u8, 'Random generation not ready');

            // Get random numbers (Array<u8> in range 1-40)
            let random_numbers_u8 = randomness_dispatcher
                .get_generation_numbers(current_randomness_id);
            assert(random_numbers_u8.len() == 5, 'Invalid random numbers count');

            // Convert from u8 to u16 (already in range 1-40)
            let winningNumbers = self.MapRandomNumbersToLotteryRange(@random_numbers_u8);

            // Assign winning numbers to the draw
            draw.winningNumber1 = *winningNumbers.at(0);
            draw.winningNumber2 = *winningNumbers.at(1);
            draw.winningNumber3 = *winningNumbers.at(2);
            draw.winningNumber4 = *winningNumbers.at(3);
            draw.winningNumber5 = *winningNumbers.at(4);
            draw.isActive = false;
            self.draws.entry(drawId).write(draw);

            self
                .emit(
                    DrawCompleted {
                        drawId, winningNumbers, accumulatedPrize: draw.accumulatedPrize,
                    },
                );

            // Increment randomness ID for next generation
            self.currentRandomnessId.write(current_randomness_id + 1);
        }
        //=======================================================================================
        fn ClaimPrize(ref self: ContractState, drawId: u64, ticketId: felt252) {
            // Validate that draw exists
            self.AssertDrawExists(drawId, 'ClaimPrize');

            let draw = self.draws.entry(drawId).read();
            let ticket = self.tickets.entry((drawId, ticketId)).read();
            assert(!ticket.claimed, 'Prize already claimed');
            assert(!draw.isActive, 'Draw still active');

            let matches = self
                .CheckMatches(
                    drawId,
                    ticket.number1,
                    ticket.number2,
                    ticket.number3,
                    ticket.number4,
                    ticket.number5,
                );
            let prize = self.GetFixedPrize(drawId, matches);

            let mut ticket = ticket;
            ticket.claimed = true;
            self.tickets.entry((drawId, ticketId)).write(ticket);

            if prize > 0 {
                //TODO: We need to process the payment of the prize

                self
                    .emit(
                        PrizeClaimed {
                            drawId, player: ticket.player, ticketId, prizeAmount: prize,
                        },
                    );
            } else {
                self.emit(PrizeClaimed { drawId, player: ticket.player, ticketId, prizeAmount: 0 });
            }
        }

        //=======================================================================================
        //OK
        fn CheckMatches(
            self: @ContractState,
            drawId: u64,
            number1: u16,
            number2: u16,
            number3: u16,
            number4: u16,
            number5: u16,
        ) -> u8 {
            // Get the draw
            let draw = self.draws.entry(drawId).read();
            assert(!draw.isActive, 'Draw must be completed');

            // Get the winning numbers
            let winningNumber1 = draw.winningNumber1;
            let winningNumber2 = draw.winningNumber2;
            let winningNumber3 = draw.winningNumber3;
            let winningNumber4 = draw.winningNumber4;
            let winningNumber5 = draw.winningNumber5;

            // Match counter
            let mut matches: u8 = 0;

            // For each ticket number
            if number1 == winningNumber1 {
                matches += 1;
            }
            if number2 == winningNumber2 {
                matches += 1;
            }
            if number3 == winningNumber3 {
                matches += 1;
            }
            if number4 == winningNumber4 {
                matches += 1;
            }
            if number5 == winningNumber5 {
                matches += 1;
            }

            matches
        }

        //=======================================================================================
        //OK
        fn GetAccumulatedPrize(self: @ContractState) -> u256 {
            // Return the jackpot of the current active draw
            let current_draw_id = self.currentDrawId.read();
            if current_draw_id == 0 {
                return 0;
            }
            let current_draw = self.draws.entry(current_draw_id).read();
            current_draw.accumulatedPrize
        }

        //=======================================================================================
        //OK
        fn GetFixedPrize(self: @ContractState, drawId: u64, matches: u8) -> u256 {
            match matches {
                0 => 0,
                1 => 0,
                2 => self.fixedPrize2Matches.read(),
                3 => self.fixedPrize3Matches.read(),
                4 => self.fixedPrize4Matches.read(),
                5 => {
                    // For jackpot (5 matches), return the accumulated prize of the specific draw
                    let draw = self.draws.entry(drawId).read();
                    draw.accumulatedPrize
                },
                _ => 0,
            }
        }

        //=======================================================================================
        fn CreateNewDraw(ref self: ContractState) {
            // Call the new function with default duration
            self.CreateNewDrawWithDuration(STANDARD_DRAW_DURATION_BLOCKS);
        }

        //=======================================================================================
        fn CreateNewDrawWithDuration(ref self: ContractState, duration_blocks: u64) {
            // Validate that duration is not zero
            assert(duration_blocks > 0, 'Duration must be > 0');
            // Only one active draw allowed at a time
            let current_id = self.currentDrawId.read();
            if current_id > 0 {
                let last_draw = self.draws.entry(current_id).read();
                assert(!last_draw.isActive, 'Active draw exists');
            }

            // Calculate jackpot automatically from vault balance
            // The jackpot for the new draw is calculated as:
            // remaining_funds = vault_balance - prizes_distributed_in_previous_draw
            // This ensures the remaining funds after prize distribution carry over to the next draw
            let vault_balance = self.GetVaultBalance();
            
            // Get prizes distributed in the previous draw (if exists)
            // This value is set by DistributePrizes function when prizes are assigned to winners
            let prizes_distributed = if current_id > 0 {
                self.totalPrizesDistributed.entry(current_id).read()
            } else {
                0
            };

            // Calculate the jackpot: remaining funds after previous prize distribution
            // Formula: vault_balance - prizes_distributed = funds_available_for_new_draw
            // Note: calculated_jackpot can be 0 if vault is empty; it will grow as tickets are purchased
            assert(vault_balance >= prizes_distributed, 'Insufficient vault balance');
            let calculated_jackpot = vault_balance - prizes_distributed;

            let drawId = self.currentDrawId.read() + 1;
            let current_timestamp = get_block_timestamp();
            let current_block = get_block_number();
            let end_block = current_block + duration_blocks;
            
            let newDraw = Draw {
                drawId,
                accumulatedPrize: calculated_jackpot,
                winningNumber1: 0,
                winningNumber2: 0,
                winningNumber3: 0,
                winningNumber4: 0,
                winningNumber5: 0,
                isActive: true,
                startTime: current_timestamp,
                endTime: 0,
                startBlock: current_block,
                endBlock: end_block,
                distribution_done: false,
            };
            self.draws.entry(drawId).write(newDraw);
            self.currentDrawId.write(drawId);
            
            // Update global accumulated prize
            self.accumulatedPrize.write(calculated_jackpot);

            // Emit event with transparent jackpot calculation
            self
                .emit(
                    JackpotCalculated {
                        draw_id: drawId,
                        vault_balance: vault_balance,
                        prizes_distributed: prizes_distributed,
                        calculated_jackpot: calculated_jackpot,
                        timestamp: current_timestamp,
                    },
                );
        }

        // Returns last draw id and whether it is active
        fn GetCurrentActiveDraw(self: @ContractState) -> (u64, bool) {
            let id = self.currentDrawId.read();
            if id == 0 {
                return (0, false);
            }
            let d = self.draws.entry(id).read();
            (id, d.isActive)
        }

        // Admin: mark a draw inactive and emit event
        fn SetDrawInactive(ref self: ContractState, drawId: u64) {
            self.ownable.assert_only_owner();
            // Validate that draw exists
            self.AssertDrawExists(drawId, 'SetDrawInactive');
            let mut draw = self.draws.entry(drawId).read();
            assert(draw.isActive, 'Draw already inactive');
            draw.isActive = false;
            draw.endTime = get_block_timestamp();
            self.draws.entry(drawId).write(draw);
            self
                .emit(
                    DrawClosed {
                        drawId, timestamp: get_block_timestamp(), caller: get_caller_address(),
                    },
                );
        }

        //OK
        fn GetDrawStatus(self: @ContractState, drawId: u64) -> bool {
            if !self.DrawExists(drawId) {
                return false;
            }
            self.draws.entry(drawId).read().isActive
        }


        fn GetBlocksRemaining(self: @ContractState, drawId: u64) -> u64 {
            if !self.DrawExists(drawId) {
                return 0;
            }
            let current_block = get_block_number();
            self.ComputeBlocksRemaining(drawId, current_block)
        }

        fn IsDrawActive(self: @ContractState, drawId: u64) -> bool {
            if !self.DrawExists(drawId) {
                return false;
            }
            let current_block = get_block_number();
            self.EvaluateDrawActive(drawId, current_block)
        }

        //=======================================================================================
        fn GetUserTicketIds(
            self: @ContractState, drawId: u64, player: ContractAddress,
        ) -> Array<felt252> {
            let mut userTicket_ids = ArrayTrait::new();
            let count = self.userTicketCount.entry((player, drawId)).read();

            let mut i: u32 = 1;
            while i != (count + 1) {
                let ticketId = self.userTicketIds.entry((player, drawId, i)).read();
                userTicket_ids.append(ticketId);
                i += 1;
            }

            userTicket_ids
        }

        //=======================================================================================
        fn GetUserTickets(
            ref self: ContractState, drawId: u64, player: ContractAddress,
        ) -> Array<Ticket> {
            // Validate that draw exists
            self.AssertDrawExists(drawId, 'GetUserTickets');

            let ticket_ids = self.GetUserTicketIds(drawId, player);
            let mut user_tickets_data = ArrayTrait::new();
            let mut i: usize = 0;
            while i != ticket_ids.len() {
                let ticket_id = *ticket_ids.at(i);
                let ticket_info = self.tickets.entry((drawId, ticket_id)).read();
                assert(ticket_info.player == player, 'Ticket not owned by player');
                user_tickets_data.append(ticket_info);
                i += 1;
            }

            self.emit(UserTicketsInfo { player, drawId, tickets: user_tickets_data.clone() });
            user_tickets_data
        }

        //=======================================================================================
        fn GetTicketInfo(
            self: @ContractState, drawId: u64, ticketId: felt252, player: ContractAddress,
        ) -> Ticket {
            let ticket = self.tickets.entry((drawId, ticketId)).read();
            // Verify that the ticket belongs to the caller
            assert(ticket.player == player, 'Not ticket owner');
            ticket
        }

        //=======================================================================================
        fn GetTicketCurrentId(self: @ContractState) -> u64 {
            self.currentTicketId.read()
        }

        //=======================================================================================
        fn GetWinningNumbers(self: @ContractState, drawId: u64) -> Array<u16> {
            // Validate that draw exists
            assert(self.DrawExists(drawId), 'Draw does not exist');

            let draw = self.draws.entry(drawId).read();
            assert(!draw.isActive, 'Draw must be completed');

            let mut numbers = ArrayTrait::new();
            numbers.append(draw.winningNumber1);
            numbers.append(draw.winningNumber2);
            numbers.append(draw.winningNumber3);
            numbers.append(draw.winningNumber4);
            numbers.append(draw.winningNumber5);
            numbers
        }

        // Set the ticket price (admin only)
        fn SetTicketPrice(ref self: ContractState, price: u256) {
            self.ownable.assert_only_owner();
            assert(price > 0, 'Price must be greater than 0');
            self.ticketPrice.write(price);
        }

        // Emergency function to reset reentrancy guard (owner only)
        fn EmergencyResetReentrancyGuard(ref self: ContractState) {
            self.ownable.assert_only_owner();

            // Force reset the reentrancy guard to false
            // This is a critical emergency function that should only be used
            // if the guard gets permanently locked due to a failed transaction
            self.reentrancy_guard.end();

            // Emit event for audit trail
            self
                .emit(
                    EmergencyReentrancyGuardReset {
                        caller: get_caller_address(), timestamp: get_block_timestamp(),
                    },
                );
        }

        // Get the ticket price (public view)
        fn GetTicketPrice(self: @ContractState) -> u256 {
            self.ticketPrice.read()
        }

        // Get the current balance of the vault
        fn GetVaultBalance(self: @ContractState) -> u256 {
            let vault_address = self.strkPlayVaultContractAddress.read();
            let token_dispatcher = IERC20Dispatcher {
                contract_address: self.strkPlayContractAddress.read(),
            };
            token_dispatcher.balance_of(vault_address)
        }

        //=======================================================================================
        /// Returns the complete history of all jackpot draws
        ///
        /// This function iterates through all draws from drawId 1 to currentDrawId
        /// and returns an array of JackpotEntry structs containing:
        /// - drawId: Unique identifier for the draw
        /// - jackpotAmount: The accumulated prize amount for this draw
        /// - startTime: When the draw started (legacy unix timestamp)
        /// - endTime: When the draw ended (legacy unix timestamp)
        /// - startBlock: Block where the draw started (primary reference)
        /// - endBlock: Block where the draw ends (primary reference)
        /// - isActive: Whether the draw is currently active (true) or completed (false)
        /// - isCompleted: Whether the draw has been completed (true) or is still active (false)
        ///   Note: isCompleted is the logical inverse of isActive for clarity
        fn get_jackpot_history(self: @ContractState) -> Array<JackpotEntry> {
            let mut jackpotHistory = ArrayTrait::new();
            let currentDrawId = self.currentDrawId.read();

            // Iterate through all draws from 1 to currentDrawId
            let mut drawId: u64 = 1;
            while drawId != (currentDrawId + 1) {
                let draw = self.draws.entry(drawId).read();
                let jackpotEntry = JackpotEntry {
                    drawId: draw.drawId,
                    jackpotAmount: draw.accumulatedPrize,
                    startTime: draw.startTime,
                    endTime: draw.endTime,
                    startBlock: draw.startBlock,
                    endBlock: draw.endBlock,
                    isActive: draw.isActive,
                    // isCompleted is the logical inverse of isActive for explicit clarity
                    // When isActive is true, the draw is ongoing (not completed)
                    // When isActive is false, the draw has been completed
                    isCompleted: !draw.isActive,
                };

                jackpotHistory.append(jackpotEntry);
                drawId += 1;
            }

            jackpotHistory
        }

        //=======================================================================================
        // Getter functions for Ticket structure
        //=======================================================================================
        fn GetTicketPlayer(
            self: @ContractState, drawId: u64, ticketId: felt252,
        ) -> ContractAddress {
            let ticket = self.tickets.entry((drawId, ticketId)).read();
            ticket.player
        }

        fn GetTicketNumbers(self: @ContractState, drawId: u64, ticketId: felt252) -> Array<u16> {
            let ticket = self.tickets.entry((drawId, ticketId)).read();
            let mut numbers = ArrayTrait::new();
            numbers.append(ticket.number1);
            numbers.append(ticket.number2);
            numbers.append(ticket.number3);
            numbers.append(ticket.number4);
            numbers.append(ticket.number5);
            numbers
        }

        fn GetTicketClaimed(self: @ContractState, drawId: u64, ticketId: felt252) -> bool {
            let ticket = self.tickets.entry((drawId, ticketId)).read();
            ticket.claimed
        }

        fn GetTicketDrawId(self: @ContractState, drawId: u64, ticketId: felt252) -> u64 {
            let ticket = self.tickets.entry((drawId, ticketId)).read();
            ticket.drawId
        }

        fn GetTicketTimestamp(self: @ContractState, drawId: u64, ticketId: felt252) -> u64 {
            let ticket = self.tickets.entry((drawId, ticketId)).read();
            ticket.timestamp
        }

        //=======================================================================================
        // Getter functions for JackpotEntry structure
        //=======================================================================================
        fn GetJackpotEntryDrawId(self: @ContractState, drawId: u64) -> u64 {
            let draw = self.draws.entry(drawId).read();
            draw.drawId
        }

        fn GetJackpotEntryAmount(self: @ContractState, drawId: u64) -> u256 {
            let draw = self.draws.entry(drawId).read();
            draw.accumulatedPrize
        }

        fn GetJackpotEntryStartTime(self: @ContractState, drawId: u64) -> u64 {
            let draw = self.draws.entry(drawId).read();
            draw.startTime
        }

        fn GetJackpotEntryEndTime(self: @ContractState, drawId: u64) -> u64 {
            let draw = self.draws.entry(drawId).read();
            draw.endTime
        }


        fn GetJackpotEntryStartBlock(self: @ContractState, drawId: u64) -> u64 {
            let draw = self.draws.entry(drawId).read();
            draw.startBlock
        }

        fn GetJackpotEntryEndBlock(self: @ContractState, drawId: u64) -> u64 {
            let draw = self.draws.entry(drawId).read();
            draw.endBlock
        }

        fn GetJackpotEntryIsActive(self: @ContractState, drawId: u64) -> bool {
            let draw = self.draws.entry(drawId).read();
            draw.isActive
        }

        fn GetJackpotEntryIsCompleted(self: @ContractState, drawId: u64) -> bool {
            let draw = self.draws.entry(drawId).read();
            !draw.isActive
        }

        //=======================================================================================
        // Dynamic address getters
        //=======================================================================================
        fn GetStarkPlayContractAddress(self: @ContractState) -> ContractAddress {
            self.strkPlayContractAddress.read()
        }

        fn GetStarkPlayVaultContractAddress(self: @ContractState) -> ContractAddress {
            self.strkPlayVaultContractAddress.read()
        }


        fn GetCurrentDrawId(self: @ContractState) -> u64 {
            self.currentDrawId.read()
        }

        fn GetRandomnessContractAddress(self: @ContractState) -> ContractAddress {
            self.randomnessContractAddress.read()
        }

        /// Requests random number generation for a draw
        /// Must be called by the owner before executing DrawNumbers
        fn RequestRandomGeneration(ref self: ContractState, drawId: u64, seed: u64) -> u64 {
            self.ownable.assert_only_owner();

            // Validate that the draw exists and is active
            self.AssertDrawExists(drawId, 'RequestRandomGeneration');
            let draw = self.draws.entry(drawId).read();
            assert(draw.isActive, 'Draw is not active');

            // Create dispatcher for the deployed Randomness contract
            let mut randomness_dispatcher = IRandomnessLotteryDispatcher {
                contract_address: self.randomnessContractAddress.read(),
            };

            // Request generation (devnet mode) - generates numbers in range 1-40
            let generation_id = randomness_dispatcher.devnet_generate(seed);

            generation_id
        }

        /// Distributes prizes to all winning tickets based on match levels
        /// CU-05: Global prize distribution
        fn DistributePrizes(ref self: ContractState, drawId: u64) {
            // Only owner can distribute prizes
            self.ownable.assert_only_owner();

            // 1. Validate that draw exists (don't check if active, we need it finalized)
            assert(self.DrawExists(drawId), 'Draw does not exist');

            let mut draw = self.draws.entry(drawId).read();

            // 2. Validate that draw is finalized (not active, numbers already drawn)
            assert(!draw.isActive, 'LOTTERY_NOT_FINALIZED');

            // 3. Validate that winning numbers have been drawn (at least one number set)
            assert(
                draw.winningNumber1 > 0
                    || draw.winningNumber2 > 0
                    || draw.winningNumber3 > 0
                    || draw.winningNumber4 > 0
                    || draw.winningNumber5 > 0,
                'Winning numbers not drawn',
            );

            // 4. Validate that distribution hasn't been done already
            assert(!draw.distribution_done, 'ALREADY_DISTRIBUTED');

            // 5. Get total pool and winning numbers
            let total_pool = draw.accumulatedPrize;
            let winning_numbers = array![
                draw.winningNumber1,
                draw.winningNumber2,
                draw.winningNumber3,
                draw.winningNumber4,
                draw.winningNumber5,
            ];

            // 6. Get all tickets for this draw
            let total_tickets = self.drawTicketCount.entry(drawId).read();
            assert(total_tickets > 0, 'NO_TICKETS');

            // 7. Count winners by level using arrays (1-5 matches)
            let mut level1_winners: Array<felt252> = ArrayTrait::new();
            let mut level2_winners: Array<felt252> = ArrayTrait::new();
            let mut level3_winners: Array<felt252> = ArrayTrait::new();
            let mut level4_winners: Array<felt252> = ArrayTrait::new();
            let mut level5_winners: Array<felt252> = ArrayTrait::new(); // Jackpot (5 matches)

            // Iterate through all tickets and count matches
            let mut ticket_index: u32 = 1;
            while ticket_index <= total_tickets {
                let ticket_id = self.drawTicketIds.entry((drawId, ticket_index)).read();
                let ticket = self.tickets.entry((drawId, ticket_id)).read();

                // Count matches for this ticket
                let matches = self.CountTicketMatches(@ticket, @winning_numbers.span());

                // Group by level
                if matches == 1 {
                    level1_winners.append(ticket_id);
                } else if matches == 2 {
                    level2_winners.append(ticket_id);
                } else if matches == 3 {
                    level3_winners.append(ticket_id);
                } else if matches == 4 {
                    level4_winners.append(ticket_id);
                } else if matches == 5 {
                    level5_winners.append(ticket_id); // Jackpot winner!
                }

                ticket_index += 1;
            }

            // 8. Define prize percentages for each level
            // Level 1: 1%, Level 2: 4%, Level 3: 10%, Level 4: 15%, Level 5: 70%
            let percentages = array![1_u256, 4_u256, 10_u256, 15_u256, 70_u256];

            let mut total_winners: u32 = 0;
            let mut total_distributed: u256 = 0;

            // 9. Distribute prizes for level 1 (1 match)
            if level1_winners.len() > 0 {
                let (winners, distributed) = self
                    .DistributePrizesForLevel(
                        drawId, @level1_winners, total_pool, *percentages.at(0), 1,
                    );
                total_winners += winners;
                total_distributed += distributed;
            }

            // 10. Distribute prizes for level 2 (2 matches)
            if level2_winners.len() > 0 {
                let (winners, distributed) = self
                    .DistributePrizesForLevel(
                        drawId, @level2_winners, total_pool, *percentages.at(1), 2,
                    );
                total_winners += winners;
                total_distributed += distributed;
            }

            // 11. Distribute prizes for level 3 (3 matches)
            if level3_winners.len() > 0 {
                let (winners, distributed) = self
                    .DistributePrizesForLevel(
                        drawId, @level3_winners, total_pool, *percentages.at(2), 3,
                    );
                total_winners += winners;
                total_distributed += distributed;
            }

            // 12. Distribute prizes for level 4 (4 matches)
            if level4_winners.len() > 0 {
                let (winners, distributed) = self
                    .DistributePrizesForLevel(
                        drawId, @level4_winners, total_pool, *percentages.at(3), 4,
                    );
                total_winners += winners;
                total_distributed += distributed;
            }

            // 13. Distribute jackpot for level 5 (5 matches = 70% of pool)
            if level5_winners.len() > 0 {
                let (winners, distributed) = self
                    .DistributePrizesForLevel(
                        drawId, @level5_winners, total_pool, *percentages.at(4), 5,
                    );
                total_winners += winners;
                total_distributed += distributed;
            }

            // 14. Store total prizes distributed for jackpot calculation
            self.totalPrizesDistributed.entry(drawId).write(total_distributed);

            // 15. Mark distribution as done
            draw.distribution_done = true;
            self.draws.entry(drawId).write(draw);

            // 16. Emit final event
            self
                .emit(
                    Event::PrizesDistributed(
                        PrizesDistributed {
                            drawId, winners_total: total_winners, total_distributed,
                        },
                    ),
                );
        }

        /// Adds external funds (donations or investments) to the lottery jackpot
        /// Only the owner (administrator) can call this function
        /// 
        /// # Arguments
        /// * `amount` - The amount of tokens to add to the jackpot
        /// 
        /// # Requirements
        /// * Caller must be the contract owner
        /// * Caller must have approved the lottery contract to transfer tokens
        /// * Amount must be greater than 0
        /// * There must be an active draw to add funds to
        fn AddExternalFunds(ref self: ContractState, amount: u256) {
            // 1. Only owner can add external funds
            self.ownable.assert_only_owner();

            // 2. Validate amount
            assert(amount > 0, 'Amount must be greater than 0');

            // 3. Get current draw ID
            let current_draw_id = self.currentDrawId.read();
            assert(current_draw_id > 0, 'No draw exists');

            // 4. Get the current draw and verify it's active
            let mut current_draw = self.draws.entry(current_draw_id).read();
            assert(current_draw.isActive, 'Draw is not active');

            // 5. Get addresses and create token dispatcher
            let contributor = get_caller_address();
            let vault_address = self.strkPlayVaultContractAddress.read();
            let token_dispatcher = IERC20Dispatcher {
                contract_address: self.strkPlayContractAddress.read(),
            };

            // 6. Validate contributor has sufficient balance
            let contributor_balance = token_dispatcher.balance_of(contributor);
            assert(contributor_balance >= amount, 'Insufficient balance');

            // 7. Validate contributor has approved the contract
            let allowance = token_dispatcher.allowance(contributor, get_contract_address());
            assert(allowance >= amount, 'Insufficient allowance');

            // 8. Transfer tokens from contributor to vault
            let transfer_success = token_dispatcher
                .transfer_from(contributor, vault_address, amount);
            assert(transfer_success, 'Transfer failed');

            // 9. Update current draw's jackpot only
            // Note: We don't update global accumulatedPrize here
            // It will be recalculated from vault balance when creating new draws
            let _previous_draw_jackpot = current_draw.accumulatedPrize;
            current_draw.accumulatedPrize = current_draw.accumulatedPrize + amount;
            self.draws.entry(current_draw_id).write(current_draw);

            // 10. Emit event for transparency
            self
                .emit(
                    Event::ExternalFundsAdded(
                        ExternalFundsAdded {
                            contributor,
                            drawId: current_draw_id,
                            amount,
                            new_jackpot: current_draw.accumulatedPrize,
                            timestamp: get_block_timestamp(),
                        },
                    ),
                );
        }
    }


    //=======================================================================================
    //internal functions
    //=======================================================================================
    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        //OK
        fn ValidateNumbers(self: @ContractState, numbers: @Array<u16>) -> bool {
            // Verify correct amount of numbers
            if numbers.len() != RequiredNumbers {
                return false;
            }

            // Verify that there are no duplicates and numbers are in range
            let mut usedNumbers: Felt252Dict<bool> = Default::default();
            let mut i: usize = 0;
            let mut valid = true;

            while i != numbers.len() {
                let number = *numbers.at(i);

                // Verify range (1-40)
                if number < MinNumber || number > MaxNumber {
                    valid = false;
                    break;
                }

                // Verify duplicates
                if usedNumbers.get(number.into()) {
                    valid = false;
                    break;
                }

                usedNumbers.insert(number.into(), true);
                i += 1;
            }

            valid
        }

        // NEW: Validate array of number arrays for multiple tickets
        fn ValidateNumbersArray(
            self: @ContractState, numbers_array: @Array<Array<u16>>, quantity: u8,
        ) -> bool {
            // If quantity is 0, the array should also be empty
            if quantity == 0 {
                return numbers_array.len() == 0;
            }

            // Verify that the array length matches the quantity
            if numbers_array.len() != quantity.into() {
                return false;
            }

            // Verify each array of numbers
            let mut i: usize = 0;
            let mut valid = true;

            while i != numbers_array.len() {
                let numbers = numbers_array.at(i);

                // Validate each individual array of numbers
                if !self.ValidateNumbers(numbers) {
                    valid = false;
                    break;
                }

                i += 1;
            }

            valid
        }

        fn DrawExists(self: @ContractState, drawId: u64) -> bool {
            drawId > 0 && drawId <= self.currentDrawId.read()
        }

        fn ValidateDrawExists(
            ref self: ContractState, drawId: u64, function_name: felt252,
        ) -> bool {
            if !self.DrawExists(drawId) {
                self
                    .emit(
                        InvalidDrawIdAttempted {
                            caller: get_caller_address(),
                            attempted_draw_id: drawId,
                            current_draw_id: self.currentDrawId.read(),
                            function_name,
                        },
                    );
                return false;
            }

            let draw = self.draws.entry(drawId).read();
            if !(draw.drawId == drawId && draw.isActive) {
                self
                    .emit(
                        DrawValidationFailed {
                            draw_id: drawId,
                            reason: 'Draw is not active',
                            caller: get_caller_address(),
                        },
                    );
                return false;
            }

            true
        }

        fn AssertDrawExists(ref self: ContractState, drawId: u64, function_name: felt252) {
            assert(self.ValidateDrawExists(drawId, function_name), 'Draw is not active');
        }

        fn ComputeBlocksRemaining(self: @ContractState, drawId: u64, current_block: u64) -> u64 {
            let draw = self.draws.entry(drawId).read();
            if draw.endBlock == 0 {
                if draw.endTime == 0 {
                    return 0;
                }
                let current_time = get_block_timestamp();
                if current_time >= draw.endTime {
                    return 0;
                }
                let remaining = draw.endTime - current_time;
                return remaining;
            }
            if current_block >= draw.endBlock {
                return 0;
            }
            draw.endBlock - current_block
        }

        fn EvaluateDrawActive(self: @ContractState, drawId: u64, current_block: u64) -> bool {
            let draw = self.draws.entry(drawId).read();
            if !draw.isActive {
                return false;
            }
            if draw.startBlock == 0 || draw.endBlock == 0 {
                if draw.endTime == 0 {
                    return false;
                }
                let current_time = get_block_timestamp();
                return current_time >= draw.startTime && current_time < draw.endTime;
            }
            current_block >= draw.startBlock && current_block < draw.endBlock
        }

        /// Converts random numbers from range [1-40] from u8 to u16 for Lottery
        /// Numbers are already in the correct range [1-40]
        fn MapRandomNumbersToLotteryRange(
            self: @ContractState, random_numbers: @Array<u8>,
        ) -> Array<u16> {
            let mut lottery_numbers = ArrayTrait::new();
            let mut i: usize = 0;

            while i < random_numbers.len() {
                let random_u8 = *random_numbers.at(i);
                // Convert directly from u8 to u16 (already in range 1-40)
                let mapped_number: u16 = random_u8.into();

                lottery_numbers.append(mapped_number);
                i += 1;
            }

            lottery_numbers
        }

        /// Counts how many numbers in a ticket match the winning numbers
        /// CU-05: Helper function for prize distribution
        fn CountTicketMatches(
            self: @ContractState, ticket: @Ticket, winning_numbers: @Span<u16>,
        ) -> u8 {
            let mut matches: u8 = 0;

            // Compare each ticket number with winning numbers
            if *ticket.number1 == *winning_numbers.at(0) {
                matches += 1;
            }
            if *ticket.number2 == *winning_numbers.at(1) {
                matches += 1;
            }
            if *ticket.number3 == *winning_numbers.at(2) {
                matches += 1;
            }
            if *ticket.number4 == *winning_numbers.at(3) {
                matches += 1;
            }
            if *ticket.number5 == *winning_numbers.at(4) {
                matches += 1;
            }

            matches
        }

        /// Distributes prizes for a specific match level
        /// Returns (number_of_winners, total_distributed)
        /// CU-05: Helper function for prize distribution
        fn DistributePrizesForLevel(
            ref self: ContractState,
            drawId: u64,
            winner_tickets: @Array<felt252>,
            total_pool: u256,
            percentage: u256,
            level: u8,
        ) -> (u32, u256) {
            let winner_count: u256 = winner_tickets.len().into();

            if winner_count == 0 {
                return (0, 0);
            }

            // Calculate pool for this level
            let pool_for_level = (total_pool * percentage) / 100;

            // Calculate prize per ticket
            let prize_per_ticket = pool_for_level / winner_count;

            let mut total_distributed: u256 = 0;

            // Distribute to each winner
            let mut i: usize = 0;
            while i < winner_tickets.len() {
                let ticket_id = *winner_tickets.at(i);

                // Read ticket
                let mut ticket = self.tickets.entry((drawId, ticket_id)).read();

                // Assign prize
                ticket.prize_amount = prize_per_ticket;
                ticket.prize_assigned = true;

                // Write back
                self.tickets.entry((drawId, ticket_id)).write(ticket);

                // Emit event for this ticket
                self
                    .emit(
                        Event::PrizeAssigned(
                            PrizeAssigned {
                                drawId, ticketId: ticket_id, level, amount: prize_per_ticket,
                            },
                        ),
                    );

                total_distributed += prize_per_ticket;
                i += 1;
            }

            (winner_tickets.len(), total_distributed)
        }
    }

    //=======================================================================================

    //OK
    fn GenerateTicketId(ref self: ContractState) -> felt252 {
        let ticketId = self.currentTicketId.read();
        self.currentTicketId.write(ticketId + 1);
        ticketId.into()
    }

    //OK
    fn GenerateRandomNumbers() -> Array<u16> {
        //     TODO: We need to use VRF de Pragma Oracle to generate random numbers
        let mut numbers = ArrayTrait::new();
        let blockTimestamp = get_block_timestamp();

        let mut count = 0;
        let mut usedNumbers: Felt252Dict<bool> = Default::default();

        while count != 5 {
            let number = (blockTimestamp + count) % (MaxNumber.into() - MinNumber.into() + 1)
                + MinNumber.into();
            let number_u16: u16 = number.try_into().unwrap();

            if !usedNumbers.get(number.into()) {
                numbers.append(number_u16);
                usedNumbers.insert(number.into(), true);
                count += 1;
            }
        }

        numbers
    }
}
