#[starknet::contract]
mod StarkPlayVault {
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

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;


    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //constants
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    const TOKEN_STRK_ADDRESS: felt252 =
        0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d;
    const Initial_Fee_Percentage: u64 = 5;
    const DECIMALS_FACTOR: u256 = 1_000_000_000_000_000_000; // 10^18
    const MAX_MINT_AMOUNT: u256 = 1_000_000 * 1_000_000_000_000_000_000; // 1 millón de tokens
    const MAX_BURN_AMOUNT: u256 = 1_000_000 * 1_000_000_000_000_000_000; // 1 millón de tokens


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
        feePercentage: u64,
        owner: ContractAddress,
        paused: bool,
        mintLimit: u256,
        burnLimit: u256,
        reentrant_locked: bool,
        accumulatedFee: u256,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //constructor
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        starkPlayToken: ContractAddress,
        feePercentage: u64,
    ) {
        self.strkToken.write(TOKEN_STRK_ADDRESS);
        self.starkPlayToken.write(starkPlayToken);
        self.feePercentage.write(feePercentage);
        self.owner.write(starknet::get_caller_address());
        self.ownable.initializer(owner);
        self.mintLimit.write(MAX_MINT_AMOUNT);
        self.burnLimit.write(MAX_BURN_AMOUNT);
        self.paused.write(false);
        self.reentrant_locked.write(false);
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

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
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
        let fee = (amountSTRK * self.feePercentage.read().into()) / 100;
        let total_amount_with_fee = amountSTRK + fee;

        //if balance is greater than total_amount_with_fee return true
        balance >= total_amount_with_fee
    }
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    fn _amount_to_mint(self: @ContractState, amountSTRK: u256) -> u256 {
        let fee = (amountSTRK * self.feePercentage.read().into()) / 100;
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
    fn mint_strk_play(self: @ContractState, user: ContractAddress, amount: u256) -> bool {
        let starkPlayContractAddress = self.starkPlayToken.read();
        let mintDispatcher = IMintableDispatcher { contract_address: starkPlayContractAddress };
        mintDispatcher.mint(user, amount);
        true
    }

    fn _mint_strk_play(self: @ContractState, user: ContractAddress, amount: u256) -> bool {
        mint_strk_play(self, user, amount)
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
        let fee = (amountSTRK * self.feePercentage.read().into()) / 100;
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
        _assert_not_paused(@self);
        let user = get_caller_address();
        let starkPlayContractAddress = self.starkPlayToken.read();
        let prizeDispatcher = IPrizeTokenDispatcher { contract_address: starkPlayContractAddress };
        let prize_balance = prizeDispatcher.get_prize_balance(user);
        assert(prize_balance >= amount, 'Insufficient prize tokens');
        let mut burnDispatcher = IBurnableDispatcher { contract_address: starkPlayContractAddress };
        burnDispatcher.burn_from(user, amount);
        self.totalStarkPlayBurned.write(self.totalStarkPlayBurned.read() + amount);
        self.emit(StarkPlayBurned { user, amount });
        let strk_contract_address = contract_address_const::<TOKEN_STRK_ADDRESS>();
        let strk_dispatcher = IERC20Dispatcher { contract_address: strk_contract_address };
        strk_dispatcher.transfer(user, amount);
        self.totalSTRKStored.write(self.totalSTRKStored.read() - amount);
        self.emit(ConvertedToSTRK { user, amount });
    }
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//private functions
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    //fn depositSTRK(ref self: ContractState, user: ContractAddress, amount: u256) -> bool {
//deposit strk to vault
//emit event STRKDeposited
//return true

    //in case of error al depositar el STRK
//return false
//}

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    //fn withdrawSTRK(address, u64): bool{

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    //fn setFee(ref self: ContractState, new_fee: u64) -> bool {
//    self.assert_only_owner();
//   assert(new_fee <= 10000, 'Fee too high'); // Máximo 100%
//   self.feePercentage.write(new_fee);
//    true
//}

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    //fn setFee(u64): bool{

    //}

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    //fn  getVaultBalance(): u64{

    //}

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    //fn  getTotalSTRKStored(): u64{

    //}

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    //fn  getTotalStarkPlayMinted(): u64{

    //}

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    //fn  getTotalStarkPlayBurned(): u64{

    //}

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    //fn  getFeePercentage(): u64{

    //}

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

}
