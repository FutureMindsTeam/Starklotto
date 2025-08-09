# Test Functions Inventory

## Test Functions Ordered Alphabetically

### test_1_1_conversion_consistency
Tests the consistency of 1:1 conversion operations across multiple transactions.

### test_accumulated_prize_conversion_fees_getter
Tests the retrieval of accumulated prize conversion fees.

### test_basic_balance_increment
Tests basic balance increment functionality for user accounts.

### test_basic_event_emission
Tests basic event emission functionality in the contract.

### test_basis_points_calculation
Tests the calculation of basis points for fee calculations.

### test_buy_multiple_tickets_same_user
Tests buying multiple tickets by the same user in a single transaction.

### test_buy_ticket_balance_overflow_simulation
Tests balance overflow simulation during ticket purchase operations.

### test_buy_ticket_balance_updates
Tests balance updates after successful ticket purchases.

### test_buy_ticket_boundary_numbers
Tests ticket purchase with boundary number values (minimum and maximum valid numbers).

### test_buy_ticket_draw_id_negative_edge
Tests ticket purchase with negative edge draw ID values.

### test_buy_ticket_draw_id_zero_enhanced
Tests ticket purchase with zero draw ID (enhanced validation).

### test_buy_ticket_duplicate_numbers
Tests ticket purchase with duplicate numbers in the selection.

### test_buy_ticket_empty_array_enhanced
Tests ticket purchase with empty array (enhanced validation).

### test_buy_ticket_empty_numbers_array
Tests ticket purchase with empty numbers array.

### test_buy_ticket_event_content_validation
Tests validation of event content during ticket purchase.

### test_buy_ticket_event_data_consistency
Tests consistency of event data with state changes during ticket purchase.

### test_buy_ticket_event_emission
Tests event emission during ticket purchase operations.

### test_buy_ticket_event_fields_validation
Tests validation of event fields during ticket purchase.

### test_buy_ticket_event_ordering_consistency
Tests consistency of event ordering during multiple ticket purchases.

### test_buy_ticket_event_ticketpurchased_structure
Tests the structure of TicketPurchased events during ticket purchase.

### test_buy_ticket_exact_balance
Tests ticket purchase with exact balance amount.

### test_buy_ticket_insufficient_allowance
Tests ticket purchase with insufficient token allowance.

### test_buy_ticket_insufficient_balance
Tests ticket purchase with insufficient token balance.

### test_buy_ticket_inactive_draw
Tests ticket purchase on an inactive draw.

### test_buy_ticket_invalid_draw_id_out_of_range
Tests ticket purchase with out-of-range draw ID.

### test_buy_ticket_invalid_draw_id_zero
Tests ticket purchase with zero draw ID.

### test_buy_ticket_invalid_numbers_count_too_few
Tests ticket purchase with too few numbers in the selection.

### test_buy_ticket_invalid_numbers_count_too_many
Tests ticket purchase with too many numbers in the selection.

### test_buy_ticket_multiple_events_structure
Tests structure of multiple events during ticket purchases.

### test_buy_ticket_multiple_events_validation
Tests validation of multiple events during ticket purchases.

### test_buy_ticket_numbers_out_of_range
Tests ticket purchase with numbers outside the valid range.

### test_buy_ticket_numbers_with_zero
Tests ticket purchase with zero values in the number selection.

### test_buy_ticket_overflow_prevention_excessive_tickets
Tests overflow prevention when buying excessive number of tickets.

### test_buy_ticket_single_element_array
Tests ticket purchase with single element array.

### test_buy_ticket_state_updates
Tests state updates after successful ticket purchase.

### test_buy_ticket_stress_test_many_tickets
Tests stress scenarios with many tickets purchased.

### test_buy_ticket_successful_single_ticket
Tests successful purchase of a single ticket.

### test_buy_ticket_with_large_balance
Tests ticket purchase with very large balance amounts.

### test_buy_tickets_different_users
Tests ticket purchases by different users.

### test_buy_ticket_different_number_combinations
Tests ticket purchase with different number combinations.

### test_buy_ticket_zero_balance
Tests ticket purchase with zero token balance.

### test_burn_limit_zero_value
Tests setting burn limit to zero value.

### test_calculate_fee_buy_numbers
Tests fee calculation when buying numbers.

### test_complete_flow_integration
Tests complete integration flow of the system.

### test_concurrent_transactions_simulation
Tests simulation of concurrent transactions.

### test_consecutive_conversion_fee_accumulation
Tests consecutive accumulation of conversion fees.

### test_contract_deployment
Tests contract deployment functionality.

### test_contract_initialization
Tests contract initialization process.

### test_convert_1000_tokens_with_5_percent_fee
Tests conversion of 1000 tokens with 5% fee.

### test_convert_to_strk_burn_limit_validation
Tests converting prize tokens to STRK within the configured burn limit (validation succeeds).

### test_convert_to_strk_correct_fee_percentage
Tests that the conversion fee is correctly calculated at 3% (300 bps) with 18 decimals.

### test_convert_to_strk_events_emission
Tests that conversion emits the expected events (StarkPlayBurned, FeeCollected, ConvertedToSTRK).

### test_convert_to_strk_exceeds_burn_limit
Tests that converting an amount exceeding the burn limit results in a panic.

### test_convert_to_strk_fee_accumulation
Tests fee accumulation across two consecutive conversions (fees are summed correctly).

### test_convert_to_strk_insufficient_balance
Tests that conversion panics when the user lacks sufficient prize tokens.

### test_convert_to_strk_zero_amount
Tests that conversion panics when the amount to convert is zero.

### test_conversion_1_1_basic
Tests basic 1:1 conversion functionality.

### test_conversion_1_1_different_amounts
Tests 1:1 conversion with different amounts.

### test_conversion_1_1_precision
Tests precision in 1:1 conversion operations.

### test_counter_consistency
Tests consistency of counter operations.

### test_counters_multiple_users
Tests counter operations with multiple users.

### test_data_integrity_multiple_users
Tests data integrity across multiple users.

### test_data_storage
Tests data storage functionality.

### test_decimal_precision
Tests decimal precision in calculations.

### test_decimal_precision_edge_cases
Tests edge cases in decimal precision calculations.

### test_different_fee_percentages_accumulation
Tests accumulation with different fee percentages.

### test_draw_state
Tests draw state management.

### test_event_emission
Tests event emission functionality.

### test_event_emission_order
Tests the order of event emissions.

### test_event_parameters_validation
Tests validation of event parameters.

### test_event_set_fee_percentage
Tests event emission when setting fee percentage.

### test_events_after_pause_unpause
Tests events after pause and unpause operations.

### test_events_in_error_cases
Tests events in error scenarios.

### test_events_with_different_users
Tests events with different users.

### test_events_with_large_amounts
Tests events with large amounts.

### test_events_with_zero_amount
Tests events with zero amounts.

### test_event_state_consistency
Tests consistency between events and state.

### test_fee_accumulation_logic
Tests the logic of fee accumulation.

### test_fee_accumulation_multiple_users
Tests fee accumulation with multiple users.

### test_fee_calculation_accuracy
Tests accuracy of fee calculations.

### test_fee_calculation_overflow_prevention
Tests overflow prevention in fee calculations.

### test_fee_calculation_overflow_prevention_exceeds_limit
Tests overflow prevention when exceeding limits in fee calculations.

### test_fee_calculation_underflow_prevention
Tests underflow prevention in fee calculations.

### test_fee_consistency_after_pause_unpause
Tests fee consistency after pause and unpause operations.

### test_fee_percentage_management
Tests management of fee percentages.

### test_fee_percentage_too_high
Tests fee percentage when set too high.

### test_fee_percentage_too_low
Tests fee percentage when set too low.

### test_fee_queries_reflect_changes
Tests that fee queries reflect changes correctly.

### test_get_fee_percentage_deploy
Tests getting fee percentage during deployment.

### test_get_fee_percentage_prizes_in_constructor
Tests getting fee percentage for prizes in constructor.

### test_get_jackpot_history_basic
Tests basic jackpot history retrieval.

### test_get_jackpot_history_completed_draw
Tests jackpot history retrieval for completed draws.

### test_get_jackpot_history_multiple_draws
Tests jackpot history retrieval for multiple draws.

### test_get_jackpot_history_performance
Tests performance of jackpot history retrieval.

### test_imintable_dispatcher_integration
Tests integration with IMintable dispatcher.

### test_initialization
Tests contract initialization.

### test_invalid_inputs
Tests handling of invalid inputs.

### test_large_amounts_accumulation
Tests accumulation of large amounts.

### test_maximum_fee_accumulation
Tests maximum fee accumulation scenarios.

### test_minimum_fee_accumulation
Tests minimum fee accumulation scenarios.

### test_mint_limit_updated_event_emission
Tests event emission when mint limit is updated.

### test_mint_limit_updated_event_large_values
Tests mint limit updated events with large values.

### test_mint_limit_updated_event_non_owner
Tests mint limit updated events by non-owner.

### test_mint_limit_updated_event_parameters
Tests parameters of mint limit updated events.

### test_mint_limit_updated_event_zero_limit
Tests mint limit updated events with zero limit.

### test_mint_limit_zero_value
Tests setting mint limit to zero value.

### test_minting_event_emission
Tests event emission during minting operations.

### test_minting_limits
Tests minting limits functionality.

### test_minting_limits_exceeded
Tests scenarios when minting limits are exceeded.

### test_mixed_amounts_accumulation
Tests accumulation of mixed amounts.

### test_multiple_cumulative_purchases
Tests multiple cumulative purchase operations.

### test_multiple_events_successive_transactions
Tests multiple events in successive transactions.

### test_multiple_mint_limit_updates
Tests multiple mint limit updates.

### test_multiple_minting_operations
Tests multiple minting operations.

### test_multiple_prize_conversions_accumulate_fees
Tests fee accumulation in multiple prize conversions.

### test_multiple_tickets
Tests multiple ticket operations.

### test_multiple_users_fee_consistency
Tests fee consistency with multiple users.

### test_payment_handling
Tests payment handling functionality.

### test_sequential_conversions_different_users
Tests sequential conversions with different users.

### test_sequential_fee_consistency
Tests sequential fee consistency.

### test_set_burn_limit_by_non_owner
Tests setting burn limit by non-owner (should fail).

### test_set_burn_limit_by_owner
Tests setting burn limit by owner.

### test_set_burn_limit_emit_event
Tests event emission when setting burn limit.

### test_set_fee_at_maximum_boundary
Tests setting fee at maximum boundary.

### test_set_fee_by_non_owner
Tests setting fee by non-owner (should fail).

### test_set_fee_by_owner
Tests setting fee by owner.

### test_set_fee_deploy_contract
Tests setting fee during contract deployment.

### test_set_fee_emit_event
Tests event emission when setting fee.

### test_set_fee_exceeds_maximum
Tests setting fee that exceeds maximum allowed.

### test_set_fee_max
Tests setting maximum fee.

### test_set_fee_max_like_501
Tests setting fee maximum like 501.

### test_set_fee_middle
Tests setting fee to middle value.

### test_set_fee_min
Tests setting minimum fee.

### test_set_fee_multiple_times
Tests setting fee multiple times.

### test_set_fee_percentage_prizes_converted
Tests setting fee percentage for prizes converted.

### test_set_fee_percentage_prizes_converted_invalid_fee
Tests setting invalid fee percentage for prizes converted.

### test_set_fee_to_zero
Tests setting fee to zero.

### test_set_fee_zero_like_negative_value
Tests setting fee zero like negative value.

### test_set_greetings
Tests setting greetings functionality.

### test_set_mint_limit_by_non_owner
Tests setting mint limit by non-owner (should fail).

### test_set_mint_limit_by_owner
Tests setting mint limit by owner.

### test_set_mint_limit_emit_event
Tests event emission when setting mint limit.

### test_starkplay_minted_event_emission
Tests event emission for StarkPlay minted operations.

### test_stress_test_many_tickets
Tests stress scenarios with many tickets.

### test_total_starkplay_minted_updates
Tests updates to total StarkPlay minted counter.

### test_total_strk_stored_updates
Tests updates to total STRK stored counter.

### test_transaction_fails_when_paused
Tests that transactions fail when contract is paused.

### test_transfer
Tests transfer functionality.

### test_unauthorized_minting
Tests unauthorized minting attempts.

### test_user_balance_after_conversion
Tests user balance after conversion operations.

### test_withdraw_general_fees_exceeds_accumulated
Tests withdrawal of general fees that exceeds accumulated amount.

### test_withdraw_general_fees_insufficient_vault_balance
Tests withdrawal of general fees with insufficient vault balance.

### test_withdraw_general_fees_not_owner
Tests withdrawal of general fees by non-owner.

### test_withdraw_general_fees_success
Tests successful withdrawal of general fees.

### test_withdraw_general_fees_zero_amount
Tests withdrawal of general fees with zero amount.

### test_withdraw_prize_conversion_fees_exceeds_accumulated
Tests withdrawal of prize conversion fees that exceeds accumulated amount.

### test_withdraw_prize_conversion_fees_insufficient_vault_balance
Tests withdrawal of prize conversion fees with insufficient vault balance.

### test_withdraw_prize_conversion_fees_not_owner
Tests withdrawal of prize conversion fees by non-owner.

### test_withdraw_prize_conversion_fees_success
Tests successful withdrawal of prize conversion fees.

### test_withdraw_prize_conversion_fees_zero_amount
Tests withdrawal of prize conversion fees with zero amount.

### test_zero_amount_minting
Tests minting with zero amount.

### test_zero_amount_transaction
Tests transactions with zero amount.

---

**Total test functions: 159**

---

## Function Groups with the Same Purpose

### **Group 1: Fee setting and management**
- `test_set_fee_by_owner`
- `test_set_fee_by_non_owner`
- `test_set_fee_deploy_contract`
- `test_set_fee_max`
- `test_set_fee_min`
- `test_set_fee_middle`
- `test_set_fee_to_zero`
- `test_set_fee_max_like_501`
- `test_set_fee_zero_like_negative_value`
- `test_set_fee_at_maximum_boundary`
- `test_set_fee_exceeds_maximum`
- `test_set_fee_multiple_times`
- `test_set_fee_emit_event`
- `test_event_set_fee_percentage`
- `test_fee_percentage_management`
- `test_fee_percentage_too_low`
- `test_fee_percentage_too_high`
- `test_set_fee_percentage_prizes_converted`
- `test_set_fee_percentage_prizes_converted_invalid_fee`
- `test_get_fee_percentage_deploy`
- `test_get_fee_percentage_prizes_in_constructor`

### **Group 2: Minting limits**
- `test_set_mint_limit_by_owner`
- `test_set_mint_limit_by_non_owner`
- `test_set_mint_limit_emit_event`
- `test_mint_limit_zero_value`
- `test_mint_limit_updated_event_emission`
- `test_mint_limit_updated_event_parameters`
- `test_multiple_mint_limit_updates`
- `test_mint_limit_updated_event_zero_limit`
- `test_mint_limit_updated_event_non_owner`
- `test_mint_limit_updated_event_large_values`

### **Group 3: Burning limits**
- `test_set_burn_limit_by_owner`
- `test_set_burn_limit_by_non_owner`
- `test_set_burn_limit_emit_event`
- `test_burn_limit_zero_value`

### **Group 4: General fees withdrawal**
- `test_withdraw_general_fees_success`
- `test_withdraw_general_fees_not_owner`
- `test_withdraw_general_fees_exceeds_accumulated`
- `test_withdraw_general_fees_zero_amount`
- `test_withdraw_general_fees_insufficient_vault_balance`

### **Group 5: Prize conversion fees withdrawal**
- `test_withdraw_prize_conversion_fees_success`
- `test_withdraw_prize_conversion_fees_not_owner`
- `test_withdraw_prize_conversion_fees_exceeds_accumulated`
- `test_withdraw_prize_conversion_fees_zero_amount`
- `test_withdraw_prize_conversion_fees_insufficient_vault_balance`

### **Group 6: Fee accumulation and calculation**
- `test_fee_accumulation_logic`
- `test_fee_accumulation_multiple_users`
- `test_consecutive_conversion_fee_accumulation`
- `test_multiple_prize_conversions_accumulate_fees`
- `test_different_fee_percentages_accumulation`
- `test_large_amounts_accumulation`
- `test_minimum_fee_accumulation`
- `test_maximum_fee_accumulation`
- `test_mixed_amounts_accumulation`
- `test_sequential_conversions_different_users`
- `test_calculate_fee_buy_numbers`
- `test_fee_calculation_accuracy`
- `test_fee_calculation_overflow_prevention`
- `test_fee_calculation_overflow_prevention_exceeds_limit`
- `test_fee_calculation_underflow_prevention`
- `test_decimal_precision_edge_cases`
- `test_basis_points_calculation`

### **Group 7: Jackpot history**
- `test_get_jackpot_history_basic`
- `test_get_jackpot_history_multiple_draws`
- `test_get_jackpot_history_completed_draw`
- `test_get_jackpot_history_performance`

### **Group 8: Minting operations**
- `test_minting_limits`
- `test_minting_limits_exceeded`
- `test_multiple_minting_operations`
- `test_unauthorized_minting`
- `test_zero_amount_minting`
- `test_minting_event_emission`

### **Group 9: Fee consistency**
- `test_sequential_fee_consistency`
- `test_multiple_users_fee_consistency`
- `test_fee_consistency_after_pause_unpause`
- `test_fee_queries_reflect_changes`

### **Group 10: Ticket purchase operations**
- `test_buy_ticket_successful_single_ticket`
- `test_buy_multiple_tickets_same_user`
- `test_buy_tickets_different_users`
- `test_buy_ticket_different_number_combinations`
- `test_buy_ticket_event_emission`
- `test_buy_ticket_invalid_numbers_count_too_few`
- `test_buy_ticket_invalid_numbers_count_too_many`
- `test_buy_ticket_numbers_out_of_range`
- `test_buy_ticket_duplicate_numbers`
- `test_buy_ticket_insufficient_balance`
- `test_buy_ticket_zero_balance`
- `test_buy_ticket_insufficient_allowance`
- `test_buy_ticket_inactive_draw`
- `test_buy_ticket_boundary_numbers`
- `test_buy_ticket_exact_balance`
- `test_buy_ticket_balance_updates`
- `test_buy_ticket_state_updates`
- `test_buy_ticket_with_large_balance`
- `test_buy_ticket_invalid_draw_id_zero`
- `test_buy_ticket_invalid_draw_id_out_of_range`
- `test_buy_ticket_empty_numbers_array`
- `test_buy_ticket_numbers_with_zero`
- `test_buy_ticket_event_content_validation`
- `test_buy_ticket_multiple_events_validation`
- `test_buy_ticket_event_data_consistency`
- `test_buy_ticket_stress_test_many_tickets`
- `test_buy_ticket_overflow_prevention_excessive_tickets`
- `test_buy_ticket_balance_overflow_simulation`
- `test_buy_ticket_draw_id_zero_enhanced`
- `test_buy_ticket_draw_id_negative_edge`
- `test_buy_ticket_empty_array_enhanced`
- `test_buy_ticket_single_element_array`
- `test_buy_ticket_event_ticketpurchased_structure`
- `test_buy_ticket_event_fields_validation`
- `test_buy_ticket_multiple_events_structure`
- `test_buy_ticket_event_ordering_consistency`

### **Group 11: Event emission and validation**
- `test_basic_event_emission`
- `test_event_emission`
- `test_event_emission_order`
- `test_event_parameters_validation`
- `test_events_after_pause_unpause`
- `test_events_in_error_cases`
- `test_events_with_different_users`
- `test_events_with_large_amounts`
- `test_events_with_zero_amount`
- `test_event_state_consistency`
- `test_multiple_events_successive_transactions`
- `test_starkplay_minted_event_emission`

### **Group 12: Contract initialization and deployment**
- `test_contract_deployment`
- `test_contract_initialization`
- `test_initialization`
- `test_imintable_dispatcher_integration`

### **Group 13: Data storage and integrity**
- `test_data_storage`
- `test_data_integrity_multiple_users`
- `test_counter_consistency`
- `test_counters_multiple_users`
- `test_total_starkplay_minted_updates`
- `test_total_strk_stored_updates`

### **Group 14: Conversion operations**
- `test_conversion_1_1_basic`
- `test_conversion_1_1_different_amounts`
- `test_conversion_1_1_precision`
- `test_1_1_conversion_consistency`
- `test_convert_1000_tokens_with_5_percent_fee`
- `test_user_balance_after_conversion`

### **Group 15: Balance and precision operations**
- `test_basic_balance_increment`
- `test_multiple_cumulative_purchases`
- `test_decimal_precision`

### **Group 16: Pause and transaction control**
- `test_transaction_fails_when_paused`
- `test_zero_amount_transaction`

### **Group 17: Input validation**
- `test_invalid_inputs`
- `test_multiple_tickets`
- `test_draw_state`
- `test_payment_handling`

### **Group 18: Basic operations**
- `test_set_greetings`
- `test_transfer`
- `test_accumulated_prize_conversion_fees_getter`

### **Group 19: Integration and flow testing**
- `test_complete_flow_integration`
- `test_concurrent_transactions_simulation`
- `test_sequential_fee_consistency`
- `test_fee_calculation_accuracy`
- `test_multiple_users_fee_consistency`
- `test_fee_accumulation_multiple_users`
- `test_zero_amount_minting` 

### **Group 20: CU02 – Prize conversion (convert_to_strk)**
- `test_convert_to_strk_burn_limit_validation` — Converts within burn limit (should succeed and update counters correctly).
- `test_convert_to_strk_exceeds_burn_limit` — Exceeding burn limit should panic with the expected message.
- `test_convert_to_strk_zero_amount` — Zero amount should panic with the expected message.
- `test_convert_to_strk_insufficient_balance` — Insufficient prize tokens should panic.
- `test_convert_to_strk_correct_fee_percentage` — Verifies fee is 3% (300 bps) using 18 decimals.
- `test_convert_to_strk_fee_accumulation` — Two consecutive conversions accumulate fees correctly.
- `test_convert_to_strk_events_emission` — Emits StarkPlayBurned, FeeCollected, and ConvertedToSTRK events.