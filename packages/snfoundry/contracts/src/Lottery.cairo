use starknet::ContractAddress;

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
    //start time of the draw,timestamp unix (legacy, retained for compatibility) (legacy, retained for compatibility)
    startTime: u64,
    //end time of the draw,timestamp unix (legacy, retained for compatibility) (legacy, retained for compatibility)
    endTime: u64,
    //start block of the draw (primary scheduling reference)
    startBlock: u64,
    //end block of the draw (primary scheduling reference)
    endBlock: u64
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
    fn Initialize(ref self: TContractState, ticketPrice: u256, accumulatedPrize: u256);
    fn BuyTicket(ref self: TContractState, drawId: u64, numbers_array: Array<Array<u16>>, quantity: u8);
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
    fn CreateNewDraw(ref self: TContractState, accumulatedPrize: u256);
    fn GetCurrentActiveDraw(self: @TContractState) -> (u64, bool);
    fn SetDrawInactive(ref self: TContractState, drawId: u64);
    fn SetTicketPrice(ref self: TContractState, price: u256);
    fn EmergencyResetReentrancyGuard(ref self: TContractState);
    //=======================================================================================
    //get functions
    fn GetTicketPrice(self: @TContractState) -> u256;
    fn GetAccumulatedPrize(self: @TContractState) -> u256;
    fn GetFixedPrize(self: @TContractState, matches: u8) -> u256;
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
        ContractAddress, get_block_timestamp, get_caller_address,
        get_contract_address, get_block_number
    };
    use super::{Draw, ILottery, JackpotEntry, Ticket};

    // ownable component by openzeppelin
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

     //=======================================================================================
    //constants
    //=======================================================================================
    const MinNumber: u16 = 1; // min number
    const MaxNumber: u16 = 40; // max number
    const RequiredNumbers: usize = 5; // amount of numbers per ticket
    // Precio inicial de ticket: 5 STARKP (18 decimales)
    const TicketPriceInitial: u256 = 5000000000000000000;
    // Duración estándar estimada de un sorteo (≈ 1 semana) expresada en bloques
    const STANDARD_DRAW_DURATION_BLOCKS: u64 = 44800;

    // Constantes para el cálculo del jackpot
    const JACKPOT_PERCENTAGE: u256 = 55; // 55% del monto de compra va al jackpot
    const PERCENTAGE_DENOMINATOR: u256 = 100; // Para calcular porcentajes
    
    // reentrancy guard component by openzeppelin
    component!(path: ReentrancyGuardComponent, storage: reentrancy_guard, event: ReentrancyGuardEvent);


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
        userTicketCount: Map<
            (ContractAddress, u64), u32,
        >, // (usuario, drawId) -> usert ticket count
        // (usuario, drawId, índice)-> ticketId
        userTicketIds: Map<(ContractAddress, u64, u32), felt252>,
        draws: Map<u64, Draw>,
        tickets: Map<(u64, felt252), Ticket>,
        // Dynamic contract addresses
        strkPlayContractAddress: ContractAddress,
        strkPlayVaultContractAddress: ContractAddress,
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
        strkPlayVaultContractAddress: ContractAddress
    ) {
        // Validate that addresses are not zero address
        assert(strkPlayContractAddress != 0.try_into().unwrap(), 'Invalid STRKP contract');
        assert(
            strkPlayVaultContractAddress != 0.try_into().unwrap(), 'Invalid Vault contract'
        );

        self.ownable.initializer(owner);
        self.fixedPrize4Matches.write(4000000000000000000);
        self.fixedPrize3Matches.write(3000000000000000000);
        self.fixedPrize2Matches.write(2000000000000000000);
        self.currentDrawId.write(0);
        self.currentTicketId.write(0);

        // Store dynamic contract addresses
        self.strkPlayContractAddress.write(strkPlayContractAddress);
        self.strkPlayVaultContractAddress.write(strkPlayVaultContractAddress);
        self.ticketPrice.write(TicketPriceInitial);
    }
    //=======================================================================================
    //impl
    //=======================================================================================

    #[abi(embed_v0)]
    impl LotteryImpl of ILottery<ContractState> {
        //OK
        fn Initialize(ref self: ContractState, ticketPrice: u256, accumulatedPrize: u256) {
            self.ownable.assert_only_owner();
            self.ticketPrice.write(ticketPrice);
            self.accumulatedPrize.write(accumulatedPrize);
            self.CreateNewDraw(accumulatedPrize);
        }

        //=======================================================================================
        //OK
        fn BuyTicket(ref self: ContractState, drawId: u64, numbers_array: Array<Array<u16>>, quantity: u8) {
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

            // --- CORREGIDO: Calculate total price for all tickets ---
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
            let transfer_success = token_dispatcher
                .transfer_from(user, vault_address, total_price);
            assert(transfer_success, 'Transfer failed');


            // --- End corrected payment logic ---

            // Calculate 55% of total price to add to jackpot
            let jackpot_contribution = (total_price * JACKPOT_PERCENTAGE) / PERCENTAGE_DENOMINATOR;

            // Update global accumulated prize
            let current_accumulated_prize = self.accumulatedPrize.read();
            self.accumulatedPrize.write(current_accumulated_prize + jackpot_contribution);

            // Update the specific draw's accumulated prize
            let mut current_draw = self.draws.entry(drawId).read();
            current_draw.accumulatedPrize = current_draw.accumulatedPrize + jackpot_contribution;
            self.draws.entry(drawId).write(current_draw);

            // Emit event for jackpot increase
            self.emit(
                JackpotIncreased {
                    drawId,
                    previousAmount: current_accumulated_prize,
                    newAmount: current_accumulated_prize + jackpot_contribution,
                    timestamp: current_timestamp,
                },
            );

            

            // Emit bulk purchase event for auditing
            self.emit(
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
                };

                let ticketId = GenerateTicketId(ref self);
                self.tickets.entry((drawId, ticketId)).write(ticketNew);

                // Increment counter and save ticketId
                count += 1;
                self.userTicketCount.entry((caller, drawId)).write(count);
                self.userTicketIds.entry((caller, drawId, count)).write(ticketId);

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
        //OK
        fn DrawNumbers(ref self: ContractState, drawId: u64) {
            self.ownable.assert_only_owner();
            let mut draw = self.draws.entry(drawId).read();
            assert(draw.isActive, 'Draw is not active');

            let winningNumbers = GenerateRandomNumbers();
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
                        drawId, winningNumbers, accumulatedPrize: self.accumulatedPrize.read(),
                    },
                );
        }
        //=======================================================================================
        //OK
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
            let prize = self.GetFixedPrize(matches);

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
            // Obtener el sorteo
            let draw = self.draws.entry(drawId).read();
            assert(!draw.isActive, 'Draw must be completed');

            // Obtener los números ganadores
            let winningNumber1 = draw.winningNumber1;
            let winningNumber2 = draw.winningNumber2;
            let winningNumber3 = draw.winningNumber3;
            let winningNumber4 = draw.winningNumber4;
            let winningNumber5 = draw.winningNumber5;

            // Contador de coincidencias
            let mut matches: u8 = 0;

            // Para cada número del ticket
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
            self.accumulatedPrize.read()
        }

        //=======================================================================================
        //OK
        fn GetFixedPrize(self: @ContractState, matches: u8) -> u256 {
            match matches {
                0 => 0,
                1 => 0,
                2 => self.fixedPrize2Matches.read(),
                3 => self.fixedPrize3Matches.read(),
                4 => self.fixedPrize4Matches.read(),
                5 => self.accumulatedPrize.read(),
                _ => 0,
            }
        }

        //=======================================================================================
        //OK
        fn CreateNewDraw(ref self: ContractState, accumulatedPrize: u256) {
            // Validate that the accumulated prize is not negative
            assert(accumulatedPrize >= 0, 'Invalid accumulated prize');
            // Only one active draw allowed at a time
            let current_id = self.currentDrawId.read();
            if current_id > 0 {
                let last_draw = self.draws.entry(current_id).read();
                assert(!last_draw.isActive, 'Active draw exists');
            }

            let drawId = self.currentDrawId.read() + 1;
            let previousAmount = self.accumulatedPrize.read();
            let current_timestamp = get_block_timestamp();
            let current_block = get_block_number();
            let end_block = current_block + STANDARD_DRAW_DURATION_BLOCKS;
            let newDraw = Draw {
                drawId,
                accumulatedPrize: accumulatedPrize,
                winningNumber1: 0,
                winningNumber2: 0,
                winningNumber3: 0,
                winningNumber4: 0,
                winningNumber5: 0,
                // tickets: Map::new(),
                isActive: true,
                startTime: current_timestamp,
                endTime: 0,
                startBlock: current_block,
                endBlock: end_block
            };
            self.draws.entry(drawId).write(newDraw);
            self.currentDrawId.write(drawId);

            self
                .emit(
                    JackpotIncreased {
                        drawId,
                        previousAmount,
                        newAmount: accumulatedPrize,
                        timestamp: current_timestamp
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
            self.emit(DrawClosed { drawId, timestamp: get_block_timestamp(), caller: get_caller_address() });
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
            // Verificar que el ticket pertenece al caller
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
            self.emit(
                EmergencyReentrancyGuardReset {
                    caller: get_caller_address(),
                    timestamp: get_block_timestamp(),
                }
            );
        }

        // Get the ticket price (public view)
        fn GetTicketPrice(self: @ContractState) -> u256 {
            self.ticketPrice.read()
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
        fn ValidateNumbersArray(self: @ContractState, numbers_array: @Array<Array<u16>>, quantity: u8) -> bool {
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

        fn ValidateDrawExists(ref self: ContractState, drawId: u64, function_name: felt252) -> bool {
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
                self.emit( DrawValidationFailed {
                    draw_id: drawId,
                    reason: 'Draw is not active',
                    caller: get_caller_address(),
                });
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
