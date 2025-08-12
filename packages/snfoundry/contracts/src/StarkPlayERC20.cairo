use starknet::ContractAddress;
#[starknet::interface]
trait ITestingHelpers<TContractState> {
    fn getTotalSupply(self: @TContractState) -> u256;
    fn getAllAllowances(self: @TContractState, account: ContractAddress) -> (u256, u256);
}

// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts for Cairo ^0.20.0
pub const INITIAL_SUPPLY: u256 = 1000; // initial supply added 1000 for testing purposes

const MINTER_ROLE: felt252 = selector!("MINTER_ROLE");
const BURNER_ROLE: felt252 = selector!("BURNER_ROLE");
const PAUSER_ROLE: felt252 = selector!("PAUSER_ROLE");
const PRIZE_ASSIGNER_ROLE: felt252 = selector!("PRIZE_ASSIGNER_ROLE");

#[starknet::interface]
pub trait IMintable<TContractState> {
    fn mint(ref self: TContractState, recipient: ContractAddress, amount: u256);
    fn grant_minter_role(ref self: TContractState, minter: ContractAddress);
    fn revoke_minter_role(ref self: TContractState, minter: ContractAddress);
    fn set_minter_allowance(ref self: TContractState, minter: ContractAddress, allowance: u256);
    fn get_minter_allowance(self: @TContractState, minter: ContractAddress) -> u256;
    fn get_authorized_minters(self: @TContractState) -> Array<ContractAddress>;
}

#[starknet::interface]
pub trait IBurnable<TContractState> {
    fn burn(ref self: TContractState, amount: u256);
    fn burn_from(ref self: TContractState, account: ContractAddress, amount: u256);
    fn grant_burner_role(ref self: TContractState, burner: ContractAddress);
    fn revoke_burner_role(ref self: TContractState, burner: ContractAddress);
    fn set_burner_allowance(ref self: TContractState, burner: ContractAddress, allowance: u256);
    fn get_burner_allowance(self: @TContractState, burner: ContractAddress) -> u256;
    fn get_authorized_burners(self: @TContractState) -> Array<ContractAddress>;
}

#[starknet::interface]
pub trait IPrizeToken<TContractState> {
    fn assign_prize_tokens(ref self: TContractState, recipient: ContractAddress, amount: u256);
    fn get_prize_balance(self: @TContractState, account: ContractAddress) -> u256;
    fn grant_prize_assigner_role(ref self: TContractState, assigner: ContractAddress);
    fn revoke_prize_assigner_role(ref self: TContractState, assigner: ContractAddress);
}

#[starknet::contract]
pub mod StarkPlayERC20 {
    use openzeppelin_access::accesscontrol::{AccessControlComponent, DEFAULT_ADMIN_ROLE};
    use openzeppelin_introspection::interface::{ISRC5Dispatcher, ISRC5DispatcherTrait};
    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_security::PausableComponent;
    use openzeppelin_token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use openzeppelin_upgrades::UpgradeableComponent;
    use openzeppelin_upgrades::interface::IUpgradeable;
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePathEntry,
        StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{ClassHash, ContractAddress, get_caller_address};
    use super::{
        BURNER_ROLE, IBurnable, IMintable, IPrizeToken, ITestingHelpers, MINTER_ROLE, PAUSER_ROLE,
        PRIZE_ASSIGNER_ROLE,
    };

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    component!(path: PausableComponent, storage: pausable, event: PausableEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    #[abi(embed_v0)]
    impl PausableImpl = PausableComponent::PausableImpl<ContractState>;
    #[abi(embed_v0)]
    impl AccessControlMixinImpl =
        AccessControlComponent::AccessControlMixinImpl<ContractState>;

    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;
    impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        #[substorage(v0)]
        pausable: PausableComponent::Storage,
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        minter_allowance: Map<ContractAddress, u256>,
        burner_allowance: Map<ContractAddress, u256>,
        minters: Map<u256, ContractAddress>,
        burners: Map<u256, ContractAddress>,
        minters_count: u256,
        burners_count: u256,
        minter_index: Map<ContractAddress, u256>,
        burner_index: Map<ContractAddress, u256>,
        prize_balances: Map<ContractAddress, u256>,
        prize_assigners: Map<u256, ContractAddress>,
        prize_assigners_count: u256,
        prize_assigner_index: Map<ContractAddress, u256>,
    }

    #[derive(Drop, starknet::Event)]
    pub struct Burn {
        #[key]
        pub burner: ContractAddress,
        #[key]
        pub amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct Mint {
        #[key]
        pub recipient: ContractAddress,
        #[key]
        pub amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct MinterAllowanceSet {
        #[key]
        pub minter: ContractAddress,
        #[key]
        pub allowance: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct BurnerAllowanceSet {
        #[key]
        pub burner: ContractAddress,
        #[key]
        pub allowance: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct PrizeTokensAssigned {
        #[key]
        pub recipient: ContractAddress,
        #[key]
        pub amount: u256,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
        #[flat]
        PausableEvent: PausableComponent::Event,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        Burn: Burn,
        Mint: Mint,
        MinterAllowanceSet: MinterAllowanceSet,
        BurnerAllowanceSet: BurnerAllowanceSet,
        PrizeTokensAssigned: PrizeTokensAssigned,
    }

    #[constructor]
    fn constructor(ref self: ContractState, recipient: ContractAddress, admin: ContractAddress) {
        self.erc20.initializer("$tarkPlay", "STARKP");
        self.accesscontrol.initializer();
        self.accesscontrol._grant_role(DEFAULT_ADMIN_ROLE, admin);
        self.accesscontrol._grant_role(PAUSER_ROLE, admin);
        // Mint initial supply for testing
        self.erc20.mint(recipient, 1000);
    }

    #[abi(embed_v0)]
    impl MintableImpl of IMintable<ContractState> {
        fn mint(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            self.pausable.assert_not_paused();
            let caller = get_caller_address();
            self.accesscontrol.assert_only_role(MINTER_ROLE);
            let allowance = self.minter_allowance.entry(caller).read();
            assert(allowance >= amount, 'Insufficient minter allowance');
            self.minter_allowance.entry(caller).write(allowance - amount);
            self.erc20.mint(recipient, amount);
            self.emit(Mint { recipient, amount });
        }

        fn grant_minter_role(ref self: ContractState, minter: ContractAddress) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            //assert(is_contract(minter), 'Minter must be a contract');
            self.accesscontrol._grant_role(MINTER_ROLE, minter);
            let index = self.minters_count.read();
            self.minters.entry(index).write(minter);
            self.minter_index.entry(minter).write(index);
            self.minters_count.write(index + 1);
        }

        fn revoke_minter_role(ref self: ContractState, minter: ContractAddress) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            self.accesscontrol._revoke_role(MINTER_ROLE, minter);
            let index = self.minter_index.read(minter);
            let last_index = self.minters_count.read() - 1;
            if index != last_index {
                let last_minter = self.minters.entry(last_index).read();
                self.minters.entry(index).write(last_minter);
                self.minter_index.entry(last_minter).write(index);
            }
            self.minters.entry(last_index).write(zero_address_const());
            self.minter_index.write(minter, 0);
            self.minters_count.write(last_index);
        }

        fn set_minter_allowance(ref self: ContractState, minter: ContractAddress, allowance: u256) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            self.minter_allowance.entry(minter).write(allowance);
            self.emit(MinterAllowanceSet { minter, allowance });
        }

        fn get_minter_allowance(self: @ContractState, minter: ContractAddress) -> u256 {
            self.minter_allowance.entry(minter).read()
        }

        fn get_authorized_minters(self: @ContractState) -> Array<ContractAddress> {
            let mut minters = ArrayTrait::new();
            let count = self.minters_count.read();
            let mut i = 0;
            while i < count {
                minters.append(self.minters.entry(i).read());
                i += 1;
            }
            minters
        }
    }

    #[abi(embed_v0)]
    impl BurnableImpl of IBurnable<ContractState> {
        fn burn(ref self: ContractState, amount: u256) {
            self.pausable.assert_not_paused();
            let burner = get_caller_address();
            self.accesscontrol.assert_only_role(BURNER_ROLE);
            let allowance = self.burner_allowance.entry(burner).read();
            assert(allowance >= amount, 'Insufficient burner allowance');
            self.burner_allowance.entry(burner).write(allowance - amount);
            let prize_balance = self.prize_balances.entry(burner).read();
            if prize_balance >= amount {
                self.prize_balances.entry(burner).write(prize_balance - amount);
            } else {
                self.prize_balances.entry(burner).write(0);
            }
            self.erc20.burn(burner, amount);
            self.emit(Burn { burner, amount });
        }

        fn burn_from(ref self: ContractState, account: ContractAddress, amount: u256) {
            let caller = get_caller_address();
            self.accesscontrol.assert_only_role(BURNER_ROLE);
            let allowance = self.burner_allowance.entry(caller).read();
            assert(allowance >= amount, 'Insufficient burner allowance');
            self.burner_allowance.entry(caller).write(allowance - amount);
            let prize_balance = self.prize_balances.entry(account).read();
            if prize_balance >= amount {
                self.prize_balances.entry(account).write(prize_balance - amount);
            } else {
                self.prize_balances.entry(account).write(0);
            }
            self.erc20.burn(account, amount);
            self.emit(Burn { burner: account, amount });
        }

        fn grant_burner_role(ref self: ContractState, burner: ContractAddress) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            // assert(is_contract(burner), 'Burner must be a contract');
            self.accesscontrol._grant_role(BURNER_ROLE, burner);
            let index = self.burners_count.read();
            self.burners.entry(index).write(burner);
            self.burner_index.entry(burner).write(index);
            self.burners_count.write(index + 1);
        }

        fn revoke_burner_role(ref self: ContractState, burner: ContractAddress) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            self.accesscontrol._revoke_role(BURNER_ROLE, burner);
            let index = self.burner_index.read(burner);
            let last_index = self.burners_count.read() - 1;
            if index != last_index {
                let last_burner = self.burners.entry(last_index).read();
                self.burners.entry(index).write(last_burner);
                self.burner_index.entry(last_burner).write(index);
            }
            self.burners.entry(last_index).write(zero_address_const());
            self.burner_index.write(burner, 0);
            self.burners_count.write(last_index);
        }

        fn set_burner_allowance(ref self: ContractState, burner: ContractAddress, allowance: u256) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            self.burner_allowance.entry(burner).write(allowance);
            self.emit(BurnerAllowanceSet { burner, allowance });
        }

        fn get_burner_allowance(self: @ContractState, burner: ContractAddress) -> u256 {
            self.burner_allowance.entry(burner).read()
        }

        fn get_authorized_burners(self: @ContractState) -> Array<ContractAddress> {
            let mut burners = ArrayTrait::new();
            let count = self.burners_count.read();
            let mut i = 0;
            while i < count {
                burners.append(self.burners.read(i));
                i += 1;
            }
            burners
        }
    }

    #[abi(embed_v0)]
    impl PrizeTokenImpl of IPrizeToken<ContractState> {
        fn assign_prize_tokens(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            self.pausable.assert_not_paused();
            self.accesscontrol.assert_only_role(PRIZE_ASSIGNER_ROLE);
            let current_prize_balance = self.prize_balances.entry(recipient).read();
            self.prize_balances.entry(recipient).write(current_prize_balance + amount);
            self.erc20.mint(recipient, amount);
            self.emit(PrizeTokensAssigned { recipient, amount });
        }

        fn get_prize_balance(self: @ContractState, account: ContractAddress) -> u256 {
            self.prize_balances.entry(account).read()
        }

        fn grant_prize_assigner_role(ref self: ContractState, assigner: ContractAddress) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            assert(is_contract(assigner), 'Assigner must be a contract');
            self.accesscontrol._grant_role(PRIZE_ASSIGNER_ROLE, assigner);
            let index = self.prize_assigners_count.read();
            self.prize_assigners.entry(index).write(assigner);
            self.prize_assigner_index.entry(assigner).write(index);
            self.prize_assigners_count.write(index + 1);
        }

        fn revoke_prize_assigner_role(ref self: ContractState, assigner: ContractAddress) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            self.accesscontrol._revoke_role(PRIZE_ASSIGNER_ROLE, assigner);
            let index = self.prize_assigner_index.read(assigner);
            let last_index = self.prize_assigners_count.read() - 1;
            if index != last_index {
                let last_assigner = self.prize_assigners.entry(last_index).read();
                self.prize_assigners.entry(index).write(last_assigner);
                self.prize_assigner_index.entry(last_assigner).write(index);
            }
            self.prize_assigners.entry(last_index).write(zero_address_const());
            self.prize_assigner_index.entry(assigner).write(0);
            self.prize_assigners_count.write(last_index);
        }
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            self.upgradeable.upgrade(new_class_hash);
        }
    }


    fn is_contract(address: ContractAddress) -> bool {
        // Avoid zero address
        if address == zero_address_const() {
            return false;
        }
        // Check if the address supports the SRC5 interface
        //let src5_dispatcher = ISRC5Dispatcher { contract_address: address };
        //let src5_interface_id: felt252 =
        //    0x3f918d17e5ee77373b56385708f855659a07f75997f365cf87748628532a055; // SRC5 interface ID 
        //let supports_src5 = src5_dispatcher.supports_interface(src5_interface_id);

        true
    }

    fn zero_address_const() -> ContractAddress {
        '0x0'.try_into().unwrap()
    }
    #[abi(embed_v0)]
    impl TestingHelpers of ITestingHelpers<ContractState> {
        fn getTotalSupply(self: @ContractState) -> u256 {
            self.erc20.total_supply()
        }

        fn getAllAllowances(self: @ContractState, account: ContractAddress) -> (u256, u256) {
            let minter_allowance = self.minter_allowance.read(account);
            let burner_allowance = self.burner_allowance.read(account);
            (minter_allowance, burner_allowance)
        }
    }
}

