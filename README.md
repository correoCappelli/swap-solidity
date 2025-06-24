# SimpleSwap Solidity

Prof Sebastian Perez ETH-KIPU Talento Tech Turno AM 2025 CABA ,Argentina

A lightweight decentralized exchange built in Solidity using a constant product market maker model. This project provides a complete implementation of a swap engine, including liquidity provisioning, price quoting, and token swaps. Verification is conducted via an externally deployed `SwapVerifier` contract maintained by the evaluators.

## 📦 Repository

[correoCappelli/swap-solidity](https://github.com/correoCappelli/swap-solidity.git)

---

## 🧠 Overview

`SimpleSwap` is a minimal AMM that supports:
- Pair-agnostic ERC-20 token swaps
- Liquidity provision with slippage protection
- LP token accounting and redemption
- Constant product price curves
- Reentrancy-safe external functions

The `SwapVerifier` contract is deployed and managed externally. It performs an end-to-end validation of the `SimpleSwap` deployment by interacting with it via minting tokens, adding liquidity, initiating swaps, and verifying outcomes.

---

## 🔧 Contracts

### 🏗️ `SimpleSwap.sol`

Implements the decentralized exchange logic:

#### 📥 `addLiquidity(...)`

Adds a token pair to the pool, ensuring:
- Correct slippage enforcement
- Deadline validation
- Reserve updates and LP token minting

#### 💧 `removeLiquidity(...)`

Burns LP tokens and returns token reserves based on the user's liquidity share.

#### 🔁 `swapExactTokensForTokens(...)`

Swaps an exact `amountIn` of one token for the maximum possible output of another, using:

amountOut = (amountIn * reserveOut) / (reserveIn + amountIn)


Includes output validation (`amountOutMin`), deadline checks, and emits a `Swap` event.

#### 📊 `getPrice(...)` and `getAmountOut(...)`

- `getAmountOut`: Computes expected output for a swap using pool reserves.
- `getPrice`: Returns price of `tokenA` in `tokenB` terms, scaled by 1e18.

#### 🔐 Reentrancy Protection

All external operations are wrapped in OpenZeppelin-style `nonReentrant` modifiers to prevent recursive call exploits.

---

## ✅ SwapVerifier Integration

The `SwapVerifier` contract is deployed by evaluators and **must not be redeployed**. Its `verify(...)` function will:
1. Validate core functionality by interacting with your deployed `SimpleSwap`
2. Mint and approve test tokens
3. Call `addLiquidity(...)` on your contract
4. Verify correct swap output via `swapExactTokensForTokens(...)`
5. Remove liquidity and assert final state
6. Log success using the `author` string you provide

### ✅ What You Must Do

- Ensure your `SimpleSwap` contract is deployed on Sepolia and adheres to the expected interface
- Deploy mock ERC-20 tokens that implement the `IMintableERC20` interface
- Mint Tokens to the address of the evaluator contract
- Pass your contract and token addresses (plus metadata) to the evaluators, who will call the `verify` function

---

## 🧪 Local Testing (Optional)

If you wish to simulate verifier behavior in Remix or locally:

1. **Deploy mock `IMintableERC20` test tokens**
2. **Deploy your own `SimpleSwap` instance**
3. **Mimic Verifier actions**:
   - Mint tokens to yourself
   - Approve them to `SimpleSwap`
   - Call `addLiquidity`, then `swapExactTokensForTokens`, then `removeLiquidity`

This helps debug logic before the evaluator-run test occurs.

---

## 📁 Project Structure

- `SimpleSwap.sol`: Core AMM contract
- `SwapVerifier.sol`: External test logic (already deployed by evaluators)
- Interfaces and libraries: `SafeERC20`, `ReentrancyGuard`, `IMintableERC20`

---

## 🛡️ Design Notes

- Token pair sorting ensures consistent storage paths
- LP token accounting is internal (not ERC-20 based)
- The pool uses 112-bit reserves for gas and precision balance
- No fees are applied—ideal for academic testing

---

## 📄 License

MIT

---

