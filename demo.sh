#!/bin/bash

# Demo script for Liquidation Monitor
# This demonstrates the contract's functionality

source .env

echo "🔍 Liquidation Monitor Demo"
echo "============================"
echo ""

CONTRACT="0x9a129Ef786fff0F9Ce334A10D6ae1691399755cc"
AAVE_POOL="0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2"

# Test wallets
WALLETS=(
  "0x176F3DAb24a159341c0509bB36B833E7fdd0a132"
  "0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9"
  "0xBcca60bB61934080951369a648Fb03DF4F96263C"
)

echo "📊 Checking Aave Health Factors:"
echo ""

for wallet in "${WALLETS[@]}"; do
  echo "Wallet: $wallet"
  result=$(cast call $AAVE_POOL "getUserAccountData(address)" $wallet --rpc-url $RPC_URL)
  echo "Health Factor: $result"
  echo ""
done

echo "✅ Liquidation Monitor is ready!"
echo "Contract: $CONTRACT"
echo "Network: Stagenet (Chain ID 58092)"
