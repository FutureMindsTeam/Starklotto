use core::serde::Serde;
use starknet::ContractAddress;
use starknet::storage::Map;

/// Enum representing the status of a lottery ticket
#[derive(Drop, Copy, Serde, starknet::Store)]
#[allow(starknet::store_no_default_variant)]
enum LottoStatus {
    Active,
    Completed,
    Claimed,
}

/// Structure that stores the details of an NFT ticket
#[derive(Drop, Copy, Serde, starknet::Store)]
struct TicketDetails {
    owner: ContractAddress,
    lotto_id: u64,
    ticket_id: u256,
    chosen_numbers: (u16, u16, u16, u16, u16),
    is_winner: bool,
    prize_amount: u256,
    timestamp: u64,
    lotto_status: LottoStatus,
}

//=======================================================================================
// Interface of the LottoTicketNFT contract
//=======================================================================================
#[starknet::interface]
trait ILottoTicketNFT<TContractState> {
    // Query functions
    fn name(self: @TContractState) -> ByteArray;
    fn symbol(self: @TContractState) -> ByteArray;
    fn token_uri(self: @TContractState, token_id: u256) -> ByteArray;
    fn get_ticket_metadata(self: @TContractState, token_id: u256) -> TicketDetails;
    fn exists(self: @TContractState, token_id: u256) -> bool;
    fn owner_of(self: @TContractState, token_id: u256) -> ContractAddress;

    // Lottery management functions
    fn mint_ticket(
        ref self: TContractState,
        to: ContractAddress,
        lotto_id: u64,
        num1: u16,
        num2: u16,
        num3: u16,
        num4: u16,
        num5: u16,
    ) -> u256;

    fn update_ticket_status(
        ref self: TContractState,
        token_id: u256,
        is_winner: bool,
        prize_amount: u256,
        lotto_status: LottoStatus,
    );

    // Admin functions
    fn set_lottery_contract(ref self: TContractState, lottery_contract: ContractAddress);
    fn set_base_uri(ref self: TContractState, base_uri: ByteArray);
}

/// Implementation of the LottoTicketNFT contract
#[starknet::contract]
mod LottoTicketNFT {
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_token::erc721::interface::{IERC721, IERC721Metadata};
    use openzeppelin_token::erc721::{ERC721Component, ERC721HooksEmptyImpl};
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePathEntry,
        StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{
        ContractAddress, contract_address_const, get_block_timestamp, get_caller_address,
    };
    use super::{ILottoTicketNFT, LottoStatus, TicketDetails};

    /// OpenZeppelin Components
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[storage]
    struct Storage {
        // Component storage
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        // Custom storage
        ticket_details: Map<u256, TicketDetails>,
        lottery_contract: ContractAddress,
        ticket_counter: u256,
        base_uri: ByteArray,
    }

    /// Events
    #[derive(Drop, starknet::Event)]
    struct TicketMinted {
        #[key]
        token_id: u256,
        #[key]
        owner: ContractAddress,
        lotto_id: u64,
        numbers: (u16, u16, u16, u16, u16),
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct TicketStatusUpdated {
        #[key]
        token_id: u256,
        is_winner: bool,
        prize_amount: u256,
        lotto_status: LottoStatus,
    }

    #[derive(Drop, starknet::Event)]
    struct TransferBlocked {
        #[key]
        token_id: u256,
        #[key]
        from: ContractAddress,
        to: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        TicketMinted: TicketMinted,
        TicketStatusUpdated: TicketStatusUpdated,
        TransferBlocked: TransferBlocked,
    }

    // Component implementations
    // Don't embed ERC721Impl to avoid duplicate entry points
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // Use the empty hooks implementation with a modification to block transfers
    impl ERC721Hooks = ERC721HooksEmptyImpl<ContractState>;

    // Override the before_token_transfer hook to block transfers
    #[generate_trait]
    impl BlockTransfersHooksImpl of BlockTransfersHooksTrait {
        fn before_token_transfer(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256,
        ) -> bool {
            // Allow minting (from zero address)
            if from == contract_address_const::<0>() {
                return true;
            }

            // Block transfers by emitting event and failing
            self.emit(TransferBlocked { token_id, from, to });
            assert(false, 'Tickets are non-transferable');
            false
        }
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        name: ByteArray,
        symbol: ByteArray,
        base_uri: ByteArray,
    ) {
        // Initialize components
        // Clone base_uri since we need to use it twice
        let base_uri_clone = base_uri.clone();
        self.erc721.initializer(name, symbol, base_uri_clone);
        self.ownable.initializer(owner);

        // Initialize values
        self.ticket_counter.write(1); // Start from 1
        self.base_uri.write(base_uri);
    }

    //=======================================================================================
    // Interface implementation
    //=======================================================================================
    #[abi(embed_v0)]
    impl LottoTicketNFTImpl of ILottoTicketNFT<ContractState> {
        fn name(self: @ContractState) -> ByteArray {
            // Access the name from the ERC721 component
            self.erc721.name()
        }

        fn symbol(self: @ContractState) -> ByteArray {
            // Access the symbol from the ERC721 component
            self.erc721.symbol()
        }

        fn token_uri(self: @ContractState, token_id: u256) -> ByteArray {
            // Ensure the token exists
            assert(self.erc721.exists(token_id), 'Token does not exist');

            // Return the base URI (token URI customization would be done at the frontend level)
            self.base_uri.read()
        }

        fn get_ticket_metadata(self: @ContractState, token_id: u256) -> TicketDetails {
            // Ensure the token exists
            assert(self.erc721.exists(token_id), 'Token does not exist');

            // Return the ticket details
            self.ticket_details.read(token_id)
        }

        fn exists(self: @ContractState, token_id: u256) -> bool {
            self.erc721.exists(token_id)
        }

        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            self.erc721.owner_of(token_id)
        }

        fn mint_ticket(
            ref self: ContractState,
            to: ContractAddress,
            lotto_id: u64,
            num1: u16,
            num2: u16,
            num3: u16,
            num4: u16,
            num5: u16,
        ) -> u256 {
            // Only lottery contract or owner can mint tickets
            let caller = get_caller_address();
            assert(
                caller == self.lottery_contract.read() || caller == self.ownable.owner(),
                'Only lottery can mint',
            );

            // Generate a unique token ID
            let token_id = self.ticket_counter.read();
            self.ticket_counter.write(token_id + 1);

            // Store the chosen numbers as a tuple
            let numbers = (num1, num2, num3, num4, num5);

            // Create ticket metadata
            let current_time = get_block_timestamp();
            let ticket_details = TicketDetails {
                owner: to,
                lotto_id: lotto_id,
                ticket_id: token_id,
                chosen_numbers: numbers,
                is_winner: false,
                prize_amount: 0,
                timestamp: current_time,
                lotto_status: LottoStatus::Active,
            };

            // Store ticket metadata
            self.ticket_details.write(token_id, ticket_details);

            // Mint the token using the ERC721 component's mint method
            self.erc721.mint(to, token_id);

            // Emit event
            self
                .emit(
                    TicketMinted {
                        token_id, owner: to, lotto_id, numbers, timestamp: current_time,
                    },
                );

            token_id
        }

        fn update_ticket_status(
            ref self: ContractState,
            token_id: u256,
            is_winner: bool,
            prize_amount: u256,
            lotto_status: LottoStatus,
        ) {
            // Only lottery contract or owner can update ticket status
            let caller = get_caller_address();
            assert(
                caller == self.lottery_contract.read() || caller == self.ownable.owner(),
                'Only lottery can update',
            );

            // Ensure the token exists
            assert(self.erc721.exists(token_id), 'Token does not exist');

            // Get current ticket details
            let ticket_details = self.ticket_details.read(token_id);

            // Create a new structure with updated values
            let updated_details = TicketDetails {
                owner: ticket_details.owner,
                lotto_id: ticket_details.lotto_id,
                ticket_id: ticket_details.ticket_id,
                chosen_numbers: ticket_details.chosen_numbers,
                is_winner: is_winner,
                prize_amount: prize_amount,
                timestamp: ticket_details.timestamp,
                lotto_status: lotto_status,
            };

            // Save updated details
            self.ticket_details.write(token_id, updated_details);

            // Emit event
            self.emit(TicketStatusUpdated { token_id, is_winner, prize_amount, lotto_status });
        }

        fn set_lottery_contract(ref self: ContractState, lottery_contract: ContractAddress) {
            // Only the owner can set the lottery contract
            self.ownable.assert_only_owner();
            self.lottery_contract.write(lottery_contract);
        }

        fn set_base_uri(ref self: ContractState, base_uri: ByteArray) {
            // Only the owner can set the base URI
            self.ownable.assert_only_owner();
            self.base_uri.write(base_uri);
        }
    }
}
