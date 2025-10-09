#[starknet::interface]
pub trait IMockRandomness<TContractState> {
    fn devnet_generate(ref self: TContractState, seed: u64) -> u64;
    fn get_generation_numbers(self: @TContractState, id: u64) -> Array<u8>;
    fn get_generation_status(self: @TContractState, id: u64) -> u8;
}

#[starknet::contract]
pub mod MockRandomness {
    use starknet::storage::{Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        current_id: u64,
        generation_status: Map<u64, u8>,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.current_id.write(1);
    }

    #[abi(embed_v0)]
    impl MockRandomnessImpl of super::IMockRandomness<ContractState> {
        /// Simulates random number generation for devnet
        /// Returns the generation ID
        fn devnet_generate(ref self: ContractState, seed: u64) -> u64 {
            let generation_id = self.current_id.read();
            // Mark as completed (status = 2)
            self.generation_status.entry(generation_id).write(2_u8);
            self.current_id.write(generation_id + 1);
            generation_id
        }

        /// Returns 5 random numbers in the range 1-40
        fn get_generation_numbers(self: @ContractState, id: u64) -> Array<u8> {
            // Return mock numbers for testing (1-40)
            let mut numbers = ArrayTrait::new();
            numbers.append(5_u8);
            numbers.append(12_u8);
            numbers.append(23_u8);
            numbers.append(31_u8);
            numbers.append(38_u8);
            numbers
        }

        /// Returns the generation status
        /// For testing, always returns 2 (completed) if not explicitly marked
        /// 0 = not started, 1 = in progress, 2 = completed
        fn get_generation_status(self: @ContractState, id: u64) -> u8 {
            let status = self.generation_status.entry(id).read();
            // If status is 0 (not initialized), return 2 (completed) to simplify tests
            if status == 0_u8 {
                2_u8
            } else {
                status
            }
        }
    }
}

