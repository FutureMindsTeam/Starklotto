use starknet::ContractAddress;

#[starknet::interface]
pub trait IStarkPlayVault<TContractState> {
    //=======================================================================================
    //get functions
    fn GetFeePercentage(self: @TContractState) -> u64;
    fn GetFeePercentagePrizesConverted(self: @TContractState) -> u64;
    fn GetAccumulatedPrizeConversionFees(self: @TContractState) -> u256;
    fn get_mint_limit(self: @TContractState) -> u256;
    fn get_burn_limit(self: @TContractState) -> u256;
    fn get_accumulated_fee(self: @TContractState) -> u256;
    fn get_owner(self: @TContractState) -> ContractAddress;
    fn get_total_starkplay_minted(self: @TContractState) -> u256;
    fn get_total_strk_stored(self: @TContractState) -> u256;
    fn get_total_starkplay_burned(self: @TContractState) -> u256;

    //=======================================================================================
    //set functions
    fn set_fee(ref self: TContractState, new_fee: u64) -> bool;
    fn setMintLimit(ref self: TContractState, new_limit: u256);
    fn setBurnLimit(ref self: TContractState, new_limit: u256);
    fn setFeePercentage(ref self: TContractState, new_fee: u64) -> bool;
    fn setFeePercentagePrizesConverted(ref self: TContractState, new_fee: u64) -> bool;
    fn convert_to_strk(ref self: TContractState, amount: u256);
    //=======================================================================================
    //mint functions
    fn mint_strk_play(self: @TContractState, user: ContractAddress, amount: u256) -> bool;
    fn buySTRKP(ref self: TContractState, user: ContractAddress, amountSTRK: u256) -> bool;
    fn pause(ref self: TContractState) -> bool;
    fn unpause(ref self: TContractState) -> bool;
    fn is_paused(self: @TContractState) -> bool;
    fn withdrawGeneralFees(
        ref self: TContractState, recipient: ContractAddress, amount: u256,
    ) -> bool;
    fn withdrawPrizeConversionFees(
        ref self: TContractState, recipient: ContractAddress, amount: u256,
    ) -> bool;
    //test functions
    fn update_total_strk_stored(ref self: TContractState, amount: u256);
}


#[starknet::contract]
pub mod StarkPlayVault {
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //imports
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePathEntry,
        StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{
        ContractAddress, contract_address_const, get_caller_address, get_contract_address,
    };
    use crate::StarkPlayERC20::{
        IBurnableDispatcher, IBurnableDispatcherTrait, IMintable, IMintableDispatcher,
        IMintableDispatcherTrait, IPrizeTokenDispatcher, IPrizeTokenDispatcherTrait,
    };
    use super::IStarkPlayVault;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //Constants Dev
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    pub const FELT_STRK_CONTRACT: felt252 =
        0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d;
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //constants
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    const TOKEN_STRK_ADDRESS: felt252 =
        0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d;
    const Initial_Fee_Percentage: u64 = 50_u64; // 50 basis points = 0.5%
    const BASIS_POINTS_DENOMINATOR: u256 = 10000_u256; // 10000 basis points = 100%
    const DECIMALS_FACTOR: u256 = 1_000_000_000_000_000_000; // 10^18
    const MAX_MINT_AMOUNT: u256 = 1_000_000 * 1_000_000_000_000_000_000; // 1 millón de tokens
    const MAX_BURN_AMOUNT: u256 = 1_000_000 * 1_000_000_000_000_000_000; // 1 millón de tokens
    const MAX_FEE_PERCENTAGE: u64 = 10000; // 100%

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //storage
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    #[storage]
    struct Storage {
        strkToken: felt252,
        totalSTRKStored: u256,
        totalStarkPlayMinted: u256,
        totalStarkPlayBurned: u256,
        starkPlayToken: ContractAddress,
        //fee percentage for the vault to mint STRKP
        feePercentage: u64,
        feePercentagePrizesConverted: u64,
        //this don't change after the constructor
        feePercentageMin: u64, //min fee percentage for the vault to mint STRKP (0.1% = 10 basis points)
        feePercentageMax: u64, //max fee percentage for the vault to mint STRKP (5% = 500 basis points)
        feePercentagePrizesConvertedMin: u64, //min fee percentage for the vault to convert prizes to STRKP (0.1% = 10 basis points)
        feePercentagePrizesConvertedMax: u64, //max fee percentage for the vault to convert prizes to STRKP (5% = 500 basis points)
        //------------------------------------------------
        //owner of the vault
        owner: ContractAddress,
        paused: bool,
        mintLimit: u256,
        burnLimit: u256,
        reentrant_locked: bool,
        accumulatedFee: u256,
        accumulatedPrizeConversionFees: u256,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //constructor
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    #[constructor]
    pub fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        starkPlayToken: ContractAddress,
        feePercentage: u64,
    ) {
        self.strkToken.write(TOKEN_STRK_ADDRESS);
        self.starkPlayToken.write(starkPlayToken);
        self.owner.write(starknet::get_caller_address());
        self.ownable.initializer(owner);
        self.mintLimit.write(MAX_MINT_AMOUNT);
        self.burnLimit.write(MAX_BURN_AMOUNT);
        self.paused.write(false);
        self.reentrant_locked.write(false);
        self.accumulatedPrizeConversionFees.write(0);
        self.totalSTRKStored.write(0); // Initialize totalSTRKStored to 0
        self.totalStarkPlayMinted.write(0); // Initialize totalStarkPlayMinted to 0
        self.totalStarkPlayBurned.write(0); // Initialize totalStarkPlayBurned to 0
        self.accumulatedFee.write(0); // Initialize accumulatedFee to 0
        //set fee percentage
        self.feePercentage.write(feePercentage);
        self.feePercentageMin.write(10); //0.1%
        self.feePercentageMax.write(500); //5%
        self.feePercentagePrizesConverted.write(300); //3%
        self.feePercentagePrizesConvertedMin.write(10); //0.1%
        self.feePercentagePrizesConvertedMax.write(500); //5%
    }

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //events
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    #[derive(Drop, starknet::Event)]
    struct STRKDeposited {
        #[key]
        user: ContractAddress,
        #[key]
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct STRKWithdrawn {
        #[key]
        user: ContractAddress,
        #[key]
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct StarkPlayMinted {
        #[key]
        user: ContractAddress,
        #[key]
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct StarkPlayBurned {
        #[key]
        user: ContractAddress,
        #[key]
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Paused {
        #[key]
        admin: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct Unpaused {
        #[key]
        admin: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct FeeCollected {
        #[key]
        user: ContractAddress,
        #[key]
        amount: u256,
        accumulatedFee: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct StarkPlayBurnedByOwner {
        #[key]
        owner: ContractAddress,
        #[key]
        user: ContractAddress,
        #[key]
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct ConvertedToSTRK {
        #[key]
        user: ContractAddress,
        #[key]
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct MintLimitUpdated {
        new_mint_limit: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct BurnLimitUpdated {
        new_burn_limit: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct SetFeePercentage {
        #[key]
        owner: ContractAddress,
        old_fee: u64,
        new_fee: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct SetFeePercentagePrizesConverted {
        #[key]
        owner: ContractAddress,
        old_fee: u64,
        new_fee: u64,
    }
    #[derive(Drop, starknet::Event)]
    pub struct FeeUpdated {
        #[key]
        pub admin: ContractAddress,
        pub old_fee: u64,
        pub new_fee: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct GeneralFeesWithdrawn {
        #[key]
        recipient: ContractAddress,
        #[key]
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct PrizeConversionFeesWithdrawn {
        #[key]
        recipient: ContractAddress,
        #[key]
        amount: u256,
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
        ConvertedToSTRK: ConvertedToSTRK,
        MintLimitUpdated: MintLimitUpdated,
        BurnLimitUpdated: BurnLimitUpdated,
        SetFeePercentage: SetFeePercentage,
        SetFeePercentagePrizesConverted: SetFeePercentagePrizesConverted,
        FeeUpdated: FeeUpdated,
        GeneralFeesWithdrawn: GeneralFeesWithdrawn,
        PrizeConversionFeesWithdrawn: PrizeConversionFeesWithdrawn,
    }


    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //modifiers
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    fn _assert_not_paused(self: @ContractState) {
        assert(!self.paused.read(), 'Contract is paused');
    }

    fn assert_only_owner(self: @ContractState) {
        assert(get_caller_address() == self.owner.read(), 'Caller is not the owner');
    }

    // Helper function for zero address validation
    fn zero_address_const() -> ContractAddress {
        contract_address_const::<0x0>()
    }

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //public functions
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    fn pause(ref self: ContractState) -> bool {
        assert_only_owner(@self);
        assert(!self.paused.read(), 'Contract already paused');
        self.paused.write(true);
        self.emit(Paused { admin: get_caller_address() });
        true
    }

    fn unpause(ref self: ContractState) -> bool {
        assert_only_owner(@self);
        assert(self.paused.read(), 'Contract not paused');
        self.paused.write(false);
        self.emit(Unpaused { admin: get_caller_address() });
        true
    }


    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //private functions
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    fn _check_user_balance(self: @ContractState, user: ContractAddress, amountSTRK: u256) -> bool {
        let strk_contract_address = contract_address_const::<TOKEN_STRK_ADDRESS>();
        let strk_dispatcher = IERC20Dispatcher { contract_address: strk_contract_address };
        let balance = strk_dispatcher.balance_of(user);

        // set mount with fee
        let fee = (amountSTRK * self.feePercentage.read().into()) / BASIS_POINTS_DENOMINATOR.into();
        let total_amount_with_fee = amountSTRK + fee;

        //if balance is greater than total_amount_with_fee return true
        balance >= total_amount_with_fee
    }
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    fn _amount_to_mint(self: @ContractState, amountSTRK: u256) -> u256 {
        let fee = (amountSTRK * self.feePercentage.read().into()) / BASIS_POINTS_DENOMINATOR.into();
        let total_amount_with_fee = amountSTRK - fee;
        total_amount_with_fee
    }
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    fn _transfer_strk(self: @ContractState, user: ContractAddress, amountSTRK: u256) -> bool {
        let strk_contract_address = contract_address_const::<TOKEN_STRK_ADDRESS>();
        let strk_dispatcher = IERC20Dispatcher { contract_address: strk_contract_address };
        strk_dispatcher.transfer_from(user, get_contract_address(), amountSTRK);
        true
    }

    //TODO: delete fn public
    //#[external(v0)]
    fn _mint_strk_play(self: @ContractState, user: ContractAddress, amount: u256) -> bool {
        let starkPlayContractAddress = self.starkPlayToken.read();
        let mintDispatcher = IMintableDispatcher { contract_address: starkPlayContractAddress };
        mintDispatcher.mint(user, amount);
        true
    }


    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //public functions
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    fn buySTRKP(ref self: ContractState, user: ContractAddress, amountSTRK: u256) -> bool {
        //verify reentrancy and set reentrancy lock
        assert(!self.reentrant_locked.read(), 'ReentrancyGuard: reentrant call');
        self.reentrant_locked.write(true);

        let mut success = false;

        assert(amountSTRK > 0, 'Amount must be greater than 0');
        let has_balance = _check_user_balance(@self, user, amountSTRK);
        assert(has_balance, 'Insufficient STRK balance');

        _assert_not_paused(@self);
        assert(amountSTRK <= self.mintLimit.read(), 'Exceeds mint limit');

        // tranfer strk from user to contract
        let transfer_result = _transfer_strk(@self, user, amountSTRK);
        assert(transfer_result, 'Error al transferir el STRK');

        //recollect fee
        let fee = (amountSTRK * self.feePercentage.read().into()) / BASIS_POINTS_DENOMINATOR.into();
        self.accumulatedFee.write(self.accumulatedFee.read() + fee);
        self.emit(FeeCollected { user, amount: fee, accumulatedFee: self.accumulatedFee.read() });

        //update totalSTRKStored
        self.totalSTRKStored.write(self.totalSTRKStored.read() + amountSTRK);

        //mint strk play to user
        let amount_to_mint = _amount_to_mint(@self, amountSTRK);
        _mint_strk_play(@self, user, amount_to_mint);

        //update totalStarkPlayMinted
        self.totalStarkPlayMinted.write(self.totalStarkPlayMinted.read() + amount_to_mint);

        self.emit(StarkPlayMinted { user, amount: amount_to_mint });

        success = true;

        //unlock reentrancy always at the end
        self.reentrant_locked.write(false);

        return success;
    }

    fn convert_to_strk(ref self: ContractState, amount: u256) {
        // Reentrancy protection
        assert(!self.reentrant_locked.read(), 'ReentrancyGuard: reentrant call');
        self.reentrant_locked.write(true);

        // Check that the contract is not paused
        _assert_not_paused(@self);
        let user = get_caller_address();
        
        // Validate amount is greater than 0
        assert(amount > 0, 'Amount must be greater than 0');
        
        // Zero address validation
        assert(user != zero_address_const(), 'Zero address not allowed');
        
        // Validate burnLimit
        assert(amount <= self.burnLimit.read(), 'Exceeds burn limit per tx');
        
        let starkPlayContractAddress = self.starkPlayToken.read();
        let prizeDispatcher = IPrizeTokenDispatcher { contract_address: starkPlayContractAddress };
        let prize_balance = prizeDispatcher.get_prize_balance(user);
        assert(prize_balance >= amount, 'Insufficient prize tokens');

        // Calculate conversion fee using the correct fee percentage 
        let prizeFeeAmount = (amount * self.feePercentagePrizesConverted.read().into()) / BASIS_POINTS_DENOMINATOR;
        let netAmount = amount - prizeFeeAmount;

        // Verify contract has sufficient STRK balance before transfer
        let strk_contract_address = contract_address_const::<TOKEN_STRK_ADDRESS>();
        let strk_dispatcher = IERC20Dispatcher { contract_address: strk_contract_address };
        let contract_balance = strk_dispatcher.balance_of(get_contract_address());
        assert(contract_balance >= netAmount, 'Insufficient STRK in vault');
       
        // Burn the full amount of prize tokens from user
        let mut burnDispatcher = IBurnableDispatcher { contract_address: starkPlayContractAddress };
        burnDispatcher.burn_from(user, amount);
        self.totalStarkPlayBurned.write(self.totalStarkPlayBurned.read() + amount);
        self.emit(StarkPlayBurned { user, amount });

        // Update accumulated prize conversion fees
        self
            .accumulatedPrizeConversionFees
            .write(self.accumulatedPrizeConversionFees.read() + prizeFeeAmount);

        // Emit FeeCollected event
        self
            .emit(
                FeeCollected {
                    user,
                    amount: prizeFeeAmount,
                    accumulatedFee: self.accumulatedPrizeConversionFees.read(),
                },
            );

        // Transfer the net amount (after deducting fee) to user
        strk_dispatcher.transfer(user, netAmount);
        self.totalSTRKStored.write(self.totalSTRKStored.read() - netAmount);
        self.emit(ConvertedToSTRK { user, amount: netAmount });

        //Release reentrancy lock
        self.reentrant_locked.write(false);
    }

    #[abi(embed_v0)]
    impl StarkPlayVaultImpl of IStarkPlayVault<ContractState> {
        fn GetFeePercentage(self: @ContractState) -> u64 {
            self.feePercentage.read()
        }

        fn GetFeePercentagePrizesConverted(self: @ContractState) -> u64 {
            self.feePercentagePrizesConverted.read()
        }

        fn GetAccumulatedPrizeConversionFees(self: @ContractState) -> u256 {
            self.accumulatedPrizeConversionFees.read()
        }

        fn convert_to_strk(ref self: ContractState, amount: u256) {
            convert_to_strk(ref self, amount)
        }

        // Function to update totalSTRKStored (for testing purposes)
        fn update_total_strk_stored(ref self: ContractState, amount: u256) {
            self.ownable.assert_only_owner();
            self.totalSTRKStored.write(amount);
        }

        fn setMintLimit(ref self: ContractState, new_limit: u256) {
            self.ownable.assert_only_owner();

            assert(new_limit > 0, 'Invalid Mint limit');
            self.mintLimit.write(new_limit);

            self.emit(MintLimitUpdated { new_mint_limit: new_limit });
        }

        fn setBurnLimit(ref self: ContractState, new_limit: u256) {
            self.ownable.assert_only_owner();
            assert(new_limit > 0, 'Invalid Burn limit');
            self.burnLimit.write(new_limit);

            self.emit(BurnLimitUpdated { new_burn_limit: new_limit });
        }

        fn setFeePercentage(ref self: ContractState, new_fee: u64) -> bool {
            assert_only_owner(@self);
            assert(new_fee >= self.feePercentageMin.read(), 'Fee percentage is too low');
            assert(new_fee <= self.feePercentageMax.read(), 'Fee percentage is too high');
            let old_fee = self.feePercentage.read();
            self.feePercentage.write(new_fee);
            self.emit(SetFeePercentage { owner: get_caller_address(), old_fee, new_fee });
            true
        }

        fn setFeePercentagePrizesConverted(ref self: ContractState, new_fee: u64) -> bool {
            assert_only_owner(@self);
            assert(
                new_fee >= self.feePercentagePrizesConvertedMin.read(), 'Fee percentage is too low',
            );
            assert(
                new_fee <= self.feePercentagePrizesConvertedMax.read(),
                'Fee percentage is too high',
            );
            let old_fee = self.feePercentagePrizesConverted.read();
            self.feePercentagePrizesConverted.write(new_fee);
            self
                .emit(
                    SetFeePercentagePrizesConverted {
                        owner: get_caller_address(), old_fee, new_fee,
                    },
                );
            true
        }
        fn get_mint_limit(self: @ContractState) -> u256 {
            self.mintLimit.read()
        }

        fn get_burn_limit(self: @ContractState) -> u256 {
            self.burnLimit.read()
        }

        fn get_accumulated_fee(self: @ContractState) -> u256 {
            self.accumulatedFee.read()
        }

        fn get_owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }

        fn is_paused(self: @ContractState) -> bool {
            self.paused.read()
        }

        fn buySTRKP(ref self: ContractState, user: ContractAddress, amountSTRK: u256) -> bool {
            buySTRKP(ref self, user, amountSTRK)
        }

        fn pause(ref self: ContractState) -> bool {
            pause(ref self)
        }

        fn unpause(ref self: ContractState) -> bool {
            unpause(ref self)
        }

        //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        fn mint_strk_play(self: @ContractState, user: ContractAddress, amount: u256) -> bool {
            _mint_strk_play(self, user, amount)
        }
        //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        fn set_fee(ref self: ContractState, new_fee: u64) -> bool {
            self.ownable.assert_only_owner();
            assert(new_fee <= MAX_FEE_PERCENTAGE, 'Fee too high');

            let old_fee = self.feePercentage.read();
            self.feePercentage.write(new_fee);

            self.emit(FeeUpdated { admin: get_caller_address(), old_fee, new_fee });
            true
        }
        fn withdrawGeneralFees(
            ref self: ContractState, recipient: ContractAddress, amount: u256,
        ) -> bool {
            // Only owner can withdraw
            assert_only_owner(@self);
            let current_fees = self.accumulatedFee.read();
            assert(amount > 0, 'Amount must be > 0');
            assert(amount <= current_fees, 'Withdraw amount exceeds fees');
            let strk_contract_address = contract_address_const::<TOKEN_STRK_ADDRESS>();

            let strk_dispatcher = IERC20Dispatcher { contract_address: strk_contract_address };
            let contract_balance = strk_dispatcher.balance_of(get_contract_address());
            assert(contract_balance >= amount, 'Insufficient STRK in vault');
            strk_dispatcher.transfer(recipient, amount);
            self.accumulatedFee.write(current_fees - amount);
            self.emit(GeneralFeesWithdrawn { recipient, amount });
            true
        }

        fn withdrawPrizeConversionFees(
            ref self: ContractState, recipient: ContractAddress, amount: u256,
        ) -> bool {
            // Only owner can withdraw
            assert_only_owner(@self);
            let current_fees = self.accumulatedPrizeConversionFees.read();
            assert(amount > 0, 'Amount must be > 0');
            assert(amount <= current_fees, 'Withdraw amount exceeds fees');
            let strk_contract_address = contract_address_const::<TOKEN_STRK_ADDRESS>();
            let strk_dispatcher = IERC20Dispatcher { contract_address: strk_contract_address };
            let contract_balance = strk_dispatcher.balance_of(get_contract_address());
            assert(contract_balance >= amount, 'Insufficient STRK in vault');
            strk_dispatcher.transfer(recipient, amount);
            self.accumulatedPrizeConversionFees.write(current_fees - amount);
            self.emit(PrizeConversionFeesWithdrawn { recipient, amount });
            true
        }

        //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        fn get_total_starkplay_minted(self: @ContractState) -> u256 {
            self.totalStarkPlayMinted.read()
        }

        fn get_total_strk_stored(self: @ContractState) -> u256 {
            self.totalSTRKStored.read()
        }

        fn get_total_starkplay_burned(self: @ContractState) -> u256 {
            self.totalStarkPlayBurned.read()
        }
        //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    }
}
