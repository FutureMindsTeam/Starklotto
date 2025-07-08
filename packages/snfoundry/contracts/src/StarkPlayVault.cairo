//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// INTERFACE
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#[starknet::interface]
pub trait IStarkPlayVault<TContractState> {
    // Main functionality
    fn buy_strkp(ref self: TContractState, amount_strk: u256) -> bool;

    // Admin functions
    fn pause(ref self: TContractState) -> bool;
    fn unpause(ref self: TContractState) -> bool;
    fn set_fee(ref self: TContractState, new_fee: u64) -> bool;

    // View functions
    fn get_vault_balance(self: @TContractState) -> u256;
    fn get_total_strk_stored(self: @TContractState) -> u256;
    fn get_total_starkplay_minted(self: @TContractState) -> u256;
    fn get_total_starkplay_burned(self: @TContractState) -> u256;
    fn get_fee_percentage(self: @TContractState) -> u64;
    fn get_accumulated_fee(self: @TContractState) -> u256;
    fn is_paused(self: @TContractState) -> bool;
    fn get_mint_limit(self: @TContractState) -> u256;
    fn get_burn_limit(self: @TContractState) -> u256;
    //      fn get_starkplay_token(self: @TContractState) -> ContractAddress;
}


#[starknet::contract]
pub mod StarkPlayVault {
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // IMPORTS
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    use contracts::StarkPlayERC20::{
        IBurnable, IMintable, IMintableDispatcher, IMintableDispatcherTrait,
    };
    use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::contract_address_const;
    use starknet::{ContractAddress, get_caller_address, get_contract_address};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // CONSTANTS
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    const TOKEN_STRK_ADDRESS: felt252 =
        0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d;
    const INITIAL_FEE_PERCENTAGE: u64 = 5;
    const DECIMALS_FACTOR: u256 = 1_000_000_000_000_000_000; // 10^18
    const MAX_MINT_AMOUNT: u256 = 1_000_000 * 1_000_000_000_000_000_000; // 1 million tokens
    const MAX_BURN_AMOUNT: u256 = 1_000_000 * 1_000_000_000_000_000_000; // 1 million tokens
    const MAX_FEE_PERCENTAGE: u64 = 10000; // 100%

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // STORAGE
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    #[storage]
    struct Storage {
        strk_token: felt252,
        total_strk_stored: u256,
        total_starkplay_minted: u256,
        total_starkplay_burned: u256,
        starkplay_token: ContractAddress,
        fee_percentage: u64,
        owner: ContractAddress,
        paused: bool,
        mint_limit: u256,
        burn_limit: u256,
        reentrant_locked: bool,
        accumulated_fee: u256,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // EVENTS
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    #[derive(Drop, starknet::Event)]
    pub struct STRKDeposited {
        #[key]
        user: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct STRKWithdrawn {
        #[key]
        user: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct StarkPlayMinted {
        #[key]
        user: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct StarkPlayBurned {
        #[key]
        user: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct Paused {
        #[key]
        admin: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct Unpaused {
        #[key]
        admin: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct FeeCollected {
        #[key]
        user: ContractAddress,
        amount: u256,
        accumulated_fee: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct StarkPlayBurnedByOwner {
        #[key]
        owner: ContractAddress,
        user: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct FeeUpdated {
        #[key]
        pub admin: ContractAddress,
        pub old_fee: u64,
        pub new_fee: u64,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        STRKDeposited: STRKDeposited,
        STRKWithdrawn: STRKWithdrawn,
        StarkPlayMinted: StarkPlayMinted,
        StarkPlayBurned: StarkPlayBurned,
        Paused: Paused,
        Unpaused: Unpaused,
        StarkPlayBurnedByOwner: StarkPlayBurnedByOwner,
        FeeCollected: FeeCollected,
        FeeUpdated: FeeUpdated,
    }

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // CONSTRUCTOR
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    #[constructor]
    pub fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        starkplay_token: ContractAddress,
        fee_percentage: u64,
    ) {
        assert(fee_percentage <= MAX_FEE_PERCENTAGE, 'Fee percentage too high');

        self.strk_token.write(TOKEN_STRK_ADDRESS);
        self.starkplay_token.write(starkplay_token);
        self.fee_percentage.write(fee_percentage);
        self.owner.write(owner);
        self.ownable.initializer(owner);
        self.mint_limit.write(MAX_MINT_AMOUNT);
        self.burn_limit.write(MAX_BURN_AMOUNT);
        self.paused.write(false);
        self.reentrant_locked.write(false);
        self.accumulated_fee.write(0);
        self.total_strk_stored.write(0);
        self.total_starkplay_minted.write(0);
        self.total_starkplay_burned.write(0);
    }

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // PUBLIC IMPLEMENTATION
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    #[abi(embed_v0)]
    impl StarkPlayVaultImpl of super::IStarkPlayVault<ContractState> {
        fn buy_strkp(ref self: ContractState, amount_strk: u256) -> bool {
            // Verify reentrancy and set reentrancy lock
            assert(!self.reentrant_locked.read(), 'ReentrancyGuard: reentrant call');
            self.reentrant_locked.write(true);

            let caller = get_caller_address();
            let mut success = false;

            assert(amount_strk > 0, 'Amount must be greater than 0');
            self._assert_not_paused();
            assert(amount_strk <= self.mint_limit.read(), 'Exceeds mint limit');

            let has_balance = self._check_user_balance(caller, amount_strk);
            assert(has_balance, 'Insufficient STRK balance');

            // Transfer STRK from user to contract
            let transfer_result = self._transfer_strk(caller, amount_strk);
            assert(transfer_result, 'Error transferring STRK');

            // Collect fee
            let fee = (amount_strk * self.fee_percentage.read().into()) / 100;
            self.accumulated_fee.write(self.accumulated_fee.read() + fee);
            self
                .emit(
                    FeeCollected {
                        user: caller, amount: fee, accumulated_fee: self.accumulated_fee.read(),
                    },
                );

            // Update total STRK stored
            self.total_strk_stored.write(self.total_strk_stored.read() + amount_strk);

            // Mint StarkPlay tokens to user
            let amount_to_mint = self._amount_to_mint(amount_strk);
            self._mint_strkp(caller, amount_to_mint);

            // Update total StarkPlay minted
            self.total_starkplay_minted.write(self.total_starkplay_minted.read() + amount_to_mint);

            self.emit(StarkPlayMinted { user: caller, amount: amount_to_mint });

            success = true;

            // Unlock reentrancy always at the end
            self.reentrant_locked.write(false);

            success
        }

        fn pause(ref self: ContractState) -> bool {
            self._assert_only_owner();
            assert(!self.paused.read(), 'Contract already paused');
            self.paused.write(true);
            self.emit(Paused { admin: get_caller_address() });
            true
        }

        fn unpause(ref self: ContractState) -> bool {
            self._assert_only_owner();
            assert(self.paused.read(), 'Contract not paused');
            self.paused.write(false);
            self.emit(Unpaused { admin: get_caller_address() });
            true
        }

        fn set_fee(ref self: ContractState, new_fee: u64) -> bool {
            self._assert_only_owner();
            assert(new_fee <= MAX_FEE_PERCENTAGE, 'Fee too high');

            let old_fee = self.fee_percentage.read();
            self.fee_percentage.write(new_fee);

            self.emit(FeeUpdated { admin: get_caller_address(), old_fee, new_fee });
            true
        }

        // View functions
        fn get_vault_balance(self: @ContractState) -> u256 {
            let strk_contract_address = contract_address_const::<TOKEN_STRK_ADDRESS>();
            let strk_dispatcher = IERC20Dispatcher { contract_address: strk_contract_address };
            strk_dispatcher.balance_of(get_contract_address())
        }

        fn get_total_strk_stored(self: @ContractState) -> u256 {
            self.total_strk_stored.read()
        }

        fn get_total_starkplay_minted(self: @ContractState) -> u256 {
            self.total_starkplay_minted.read()
        }

        fn get_total_starkplay_burned(self: @ContractState) -> u256 {
            self.total_starkplay_burned.read()
        }

        fn get_fee_percentage(self: @ContractState) -> u64 {
            self.fee_percentage.read()
        }

        fn get_accumulated_fee(self: @ContractState) -> u256 {
            self.accumulated_fee.read()
        }

        fn is_paused(self: @ContractState) -> bool {
            self.paused.read()
        }

        fn get_mint_limit(self: @ContractState) -> u256 {
            self.mint_limit.read()
        }

        fn get_burn_limit(self: @ContractState) -> u256 {
            self.burn_limit.read()
        }
        // fn get_starkplay_token(self: @ContractState) -> ContractAddress {
    //     self.starkplay_token.read()
    // }
    }

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // PRIVATE IMPLEMENTATION
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    #[generate_trait]
    pub impl InternalImpl of InternalTrait {
        fn _assert_not_paused(self: @ContractState) {
            assert(!self.paused.read(), 'Contract is paused');
        }

        fn _assert_only_owner(self: @ContractState) {
            assert(get_caller_address() == self.owner.read(), 'Caller is not the owner');
        }

        fn _check_user_balance(
            self: @ContractState, user: ContractAddress, amount_strk: u256,
        ) -> bool {
            let strk_contract_address = contract_address_const::<TOKEN_STRK_ADDRESS>();
            let strk_dispatcher = IERC20Dispatcher { contract_address: strk_contract_address };
            let balance = strk_dispatcher.balance_of(user);

            // Set amount with fee
            let fee = (amount_strk * self.fee_percentage.read().into()) / 100;
            let total_amount_with_fee = amount_strk + fee;

            // If balance is greater than total_amount_with_fee return true
            balance >= total_amount_with_fee
        }

        fn _amount_to_mint(self: @ContractState, amount_strk: u256) -> u256 {
            let fee = (amount_strk * self.fee_percentage.read().into()) / 100;
            amount_strk - fee
        }

        fn _transfer_strk(self: @ContractState, user: ContractAddress, amount_strk: u256) -> bool {
            let strk_contract_address = contract_address_const::<TOKEN_STRK_ADDRESS>();
            let strk_dispatcher = IERC20Dispatcher { contract_address: strk_contract_address };
            strk_dispatcher.transfer_from(user, get_contract_address(), amount_strk);
            true
        }

        fn _mint_strkp(self: @ContractState, user: ContractAddress, amount: u256) -> bool {
            let starkplay_contract_address = self.starkplay_token.read();
            let mint_dispatcher = IMintableDispatcher {
                contract_address: starkplay_contract_address,
            };
            mint_dispatcher.mint(user, amount);
            true
        }
    }
    // TODO: Implement these functions when needed

    // fn deposit_strk(ref self: ContractState, user: ContractAddress, amount: u256) -> bool {
//     // Deposit STRK to vault
//     // Emit event STRKDeposited
//     // Return true
//     // In case of error depositing STRK, return false
// }

    // fn withdraw_strk(ref self: ContractState, user: ContractAddress, amount: u256) -> bool {
//     // Withdraw STRK from vault
//     // Emit event STRKWithdrawn
//     // Return true
//     // In case of error withdrawing STRK, return false
// }

}
// #[starknet::contract]
// mod StarkPlayVault {
//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//     //imports
//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//     use crate::StarkPlayERC20::{
//         IBurnable, IMintable, IMintableDispatcher, IMintableDispatcherTrait,
//     };
//     use openzeppelin_access::ownable::OwnableComponent;
//     use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
//     use starknet::contract_address_const;
//     use starknet::{ContractAddress, get_caller_address, get_contract_address};

//     component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

//     #[abi(embed_v0)]
//     impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
//     impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//     //constants
//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//     const TOKEN_STRK_ADDRESS: felt252 =
//         0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d;
//     const Initial_Fee_Percentage: u64 = 5;
//     const DECIMALS_FACTOR: u256 = 1_000_000_000_000_000_000; // 10^18
//     const MAX_MINT_AMOUNT: u256 = 1_000_000 * 1_000_000_000_000_000_000; // 1 millón de tokens
//     const MAX_BURN_AMOUNT: u256 = 1_000_000 * 1_000_000_000_000_000_000; // 1 millón de tokens

//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//     //storage
//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//     #[storage]
//     struct Storage {
//         strkToken: felt252,
//         totalSTRKStored: u256,
//         totalStarkPlayMinted: u256,
//         totalStarkPlayBurned: u256,
//         starkPlayToken: ContractAddress,
//         feePercentage: u64,
//         owner: ContractAddress,
//         paused: bool,
//         mintLimit: u256,
//         burnLimit: u256,
//         reentrant_locked: bool,
//         accumulatedFee: u256,
//         #[substorage(v0)]
//         ownable: OwnableComponent::Storage,
//     }

//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//     //constructor
//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//     #[constructor]
//     fn constructor(
//         ref self: ContractState,
//         owner: ContractAddress,
//         starkPlayToken: ContractAddress,
//         feePercentage: u64,
//     ) {
//         self.strkToken.write(TOKEN_STRK_ADDRESS);
//         self.starkPlayToken.write(starkPlayToken);
//         self.feePercentage.write(feePercentage);
//         self.owner.write(starknet::get_caller_address());
//         self.ownable.initializer(owner);
//         self.mintLimit.write(MAX_MINT_AMOUNT);
//         self.burnLimit.write(MAX_BURN_AMOUNT);
//         self.paused.write(false);
//         self.reentrant_locked.write(false);
//     }

//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//     //events
//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//     #[derive(Drop, starknet::Event)]
//     struct STRKDeposited {
//         #[key]
//         user: ContractAddress,
//         #[key]
//         amount: u256,
//     }

//     #[derive(Drop, starknet::Event)]
//     struct STRKWithdrawn {
//         #[key]
//         user: ContractAddress,
//         #[key]
//         amount: u256,
//     }

//     #[derive(Drop, starknet::Event)]
//     struct StarkPlayMinted {
//         #[key]
//         user: ContractAddress,
//         #[key]
//         amount: u256,
//     }

//     #[derive(Drop, starknet::Event)]
//     struct StarkPlayBurned {
//         #[key]
//         user: ContractAddress,
//         #[key]
//         amount: u256,
//     }

//     #[derive(Drop, starknet::Event)]
//     struct Paused {
//         #[key]
//         admin: ContractAddress,
//     }

//     #[derive(Drop, starknet::Event)]
//     struct Unpaused {
//         #[key]
//         admin: ContractAddress,
//     }

//     #[derive(Drop, starknet::Event)]
//     struct FeeCollected {
//         #[key]
//         user: ContractAddress,
//         #[key]
//         amount: u256,
//         accumulatedFee: u256,
//     }

//     #[derive(Drop, starknet::Event)]
//     struct StarkPlayBurnedByOwner {
//         #[key]
//         owner: ContractAddress,
//         #[key]
//         user: ContractAddress,
//         #[key]
//         amount: u256,
//     }

//     #[event]
//     #[derive(Drop, starknet::Event)]
//     enum Event {
//         #[flat]
//         OwnableEvent: OwnableComponent::Event,
//         STRKDeposited: STRKDeposited,
//         STRKWithdrawn: STRKWithdrawn,
//         StarkPlayMinted: StarkPlayMinted,
//         StarkPlayBurned: StarkPlayBurned,
//         Paused: Paused,
//         Unpaused: Unpaused,
//         StarkPlayBurnedByOwner: StarkPlayBurnedByOwner,
//         FeeCollected: FeeCollected,
//     }

//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//     //modifiers
//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//     fn _assert_not_paused(self: @ContractState) {
//         assert(!self.paused.read(), 'Contract is paused');
//     }

//     fn assert_only_owner(self: @ContractState) {
//         assert(get_caller_address() == self.owner.read(), 'Caller is not the owner');
//     }

//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//     //public functions
//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//     fn pause(ref self: ContractState) -> bool {
//         assert_only_owner(@self);
//         assert(!self.paused.read(), 'Contract already paused');
//         self.paused.write(true);
//         self.emit(Paused { admin: get_caller_address() });
//         true
//     }

//     fn unpause(ref self: ContractState) -> bool {
//         assert_only_owner(@self);
//         assert(self.paused.read(), 'Contract not paused');
//         self.paused.write(false);
//         self.emit(Unpaused { admin: get_caller_address() });
//         true
//     }

//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//     //private functions
//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//     fn _check_user_balance(self: @ContractState, user: ContractAddress, amountSTRK: u256) -> bool
//     {
//         let strk_contract_address = contract_address_const::<TOKEN_STRK_ADDRESS>();
//         let strk_dispatcher = IERC20Dispatcher { contract_address: strk_contract_address };
//         let balance = strk_dispatcher.balance_of(user);

//         // set mount with fee
//         let fee = (amountSTRK * self.feePercentage.read().into()) / 100;
//         let total_amount_with_fee = amountSTRK + fee;

//         //if balance is greater than total_amount_with_fee return true
//         balance >= total_amount_with_fee
//     }
//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//     fn _amount_to_mint(self: @ContractState, amountSTRK: u256) -> u256 {
//         let fee = (amountSTRK * self.feePercentage.read().into()) / 100;
//         let total_amount_with_fee = amountSTRK - fee;
//         total_amount_with_fee
//     }
//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//     fn _transfer_strk(self: @ContractState, user: ContractAddress, amountSTRK: u256) -> bool {
//         let strk_contract_address = contract_address_const::<TOKEN_STRK_ADDRESS>();
//         let strk_dispatcher = IERC20Dispatcher { contract_address: strk_contract_address };
//         strk_dispatcher.transfer_from(user, get_contract_address(), amountSTRK);
//         true
//     }

//     //TODO: delete fn public
//     //#[external(v0)]
//     fn mint_strk_play(self: @ContractState, user: ContractAddress, amount: u256) -> bool {
//         let starkPlayContractAddress = self.starkPlayToken.read();
//         let mintDispatcher = IMintableDispatcher { contract_address: starkPlayContractAddress };
//         mintDispatcher.mint(user, amount);
//         true
//     }

//     fn _mint_strk_play(self: @ContractState, user: ContractAddress, amount: u256) -> bool {
//         mint_strk_play(self, user, amount)
//     }

//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//     //public functions
//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//     fn buySTRKP(ref self: ContractState, user: ContractAddress, amountSTRK: u256) -> bool {
//         //verify reentrancy and set reentrancy lock
//         assert(!self.reentrant_locked.read(), 'ReentrancyGuard: reentrant call');
//         self.reentrant_locked.write(true);

//         let mut success = false;

//         assert(amountSTRK > 0, 'Amount must be greater than 0');
//         let has_balance = _check_user_balance(@self, user, amountSTRK);
//         assert(has_balance, 'Insufficient STRK balance');

//         _assert_not_paused(@self);
//         assert(amountSTRK <= self.mintLimit.read(), 'Exceeds mint limit');

//         // tranfer strk from user to contract
//         let transfer_result = _transfer_strk(@self, user, amountSTRK);
//         assert(transfer_result, 'Error al transferir el STRK');

//         //recollect fee
//         let fee = (amountSTRK * self.feePercentage.read().into()) / 100;
//         self.accumulatedFee.write(self.accumulatedFee.read() + fee);
//         self.emit(FeeCollected { user, amount: fee, accumulatedFee: self.accumulatedFee.read()
//         });

//         //update totalSTRKStored
//         self.totalSTRKStored.write(self.totalSTRKStored.read() + amountSTRK);

//         //mint strk play to user
//         let amount_to_mint = _amount_to_mint(@self, amountSTRK);
//         _mint_strk_play(@self, user, amount_to_mint);

//         //update totalStarkPlayMinted
//         self.totalStarkPlayMinted.write(self.totalStarkPlayMinted.read() + amount_to_mint);

//         self.emit(StarkPlayMinted { user, amount: amount_to_mint });

//         success = true;

//         //unlock reentrancy always at the end
//         self.reentrant_locked.write(false);

//         return success;
//     }
//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// //private functions
// //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//     //fn depositSTRK(ref self: ContractState, user: ContractAddress, amount: u256) -> bool {
// //deposit strk to vault
// //emit event STRKDeposited
// //return true

//     //in case of error al depositar el STRK
// //return false
// //}

//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//     //fn withdrawSTRK(address, u64): bool{

//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//     //fn setFee(ref self: ContractState, new_fee: u64) -> bool {
// //    self.assert_only_owner();
// //   assert(new_fee <= 10000, 'Fee too high'); // Máximo 100%
// //   self.feePercentage.write(new_fee);
// //    true
// //}

//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//     //fn setFee(u64): bool{

//     //}

//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//     //fn  getVaultBalance(): u64{

//     //}

//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//     //fn  getTotalSTRKStored(): u64{

//     //}

//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//     //fn  getTotalStarkPlayMinted(): u64{

//     //}

//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//     //fn  getTotalStarkPlayBurned(): u64{

//     //}

//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//     //fn  getFeePercentage(): u64{

//     //}

//     //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// }

