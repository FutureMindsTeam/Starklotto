# Fee Management - Administrator Guide

## 📋 Executive Summary

The StarkLotto system uses a configurable fee mechanism for purchasing STRKP tokens. This documentation details how to manage these fees safely.

## 🔧 Fee Configuration

### System Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `feePercentageMin` | 10 (0.1%) | Minimum allowed fee |
| `feePercentageMax` | 500 (5.0%) | Maximum allowed fee |
| `feePercentage` | 50 (0.5%) | Currently configured fee |

### Fee Calculation

```
Fee in STRK = (STRK Amount × feePercentage) / 10000
STRKP Tokens = STRK Amount - Fee
```

**Examples:**
- 1 STRK with 0.5% fee = 0.005 STRK fee → 0.995 STRKP
- 10 STRK with 0.5% fee = 0.05 STRK fee → 9.95 STRKP
- 100 STRK with 0.5% fee = 0.5 STRK fee → 99.5 STRKP

## 🛡️ Security Validations

### Allowed Ranges
- ✅ **Minimum**: 10 (0.1%)
- ✅ **Maximum**: 500 (5.0%)
- ❌ **Rejected**: < 10 or > 500

### Access Control
- Only the **contract owner** can modify fees
- Any unauthorized user attempt will be rejected

## 🔄 How to Change the Fee

### Contract Function
```cairo
fn setFeePercentage(ref self: ContractState, new_fee: u64) -> bool
```

### Recommended Process

1. **Validate the new fee**:
   ```
   10 ≤ new_fee ≤ 500
   ```

2. **Execute from owner account**:
   ```cairo
   vault_dispatcher.setFeePercentage(new_fee);
   ```

3. **Verify change**:
   ```cairo
   let current_fee = vault_dispatcher.GetFeePercentage();
   ```

### Usage Examples

```cairo
// ✅ Valid changes
vault_dispatcher.setFeePercentage(10);   // 0.1%
vault_dispatcher.setFeePercentage(100);  // 1.0%
vault_dispatcher.setFeePercentage(500);  // 5.0%

// ❌ Invalid changes (cause panic)
vault_dispatcher.setFeePercentage(0);    // Too low
vault_dispatcher.setFeePercentage(600);  // Too high
```

## 📊 Monitoring and Analysis

### Important Metrics
- `accumulatedFee`: Total accumulated fees
- `totalSTRKStored`: Total STRK deposited
- `totalStarkPlayMinted`: Total STRKP created

### Events to Monitor
```cairo
FeeCollected { user, amount, accumulatedFee }
```

## ⚠️ Risk Considerations

### Very Low Fees (< 0.5%)
- **Risk**: Insufficient revenue for operations
- **Recommendation**: Maintain at least 0.3%

### Very High Fees (> 2%)
- **Risk**: User loss due to excessive costs
- **Recommendation**: Do not exceed 2% except in special cases

### Frequent Changes
- **Risk**: User confusion
- **Recommendation**: Maximum 1 change per week

## 🚨 Emergency Procedures

### In Case of Incorrect Fee
1. Identify the problem
2. Calculate correct fee
3. Execute `setFeePercentage()` immediately
4. Communicate change to users

### Emergency Rollback
```cairo
// Return to default fee
vault_dispatcher.setFeePercentage(50); // 0.5%
```

## 📞 Technical Support

For technical support contact:
- Telegram: [Starklotto Contributors](https://t.me/StarklottoContributors) 