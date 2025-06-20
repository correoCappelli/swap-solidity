# 🌀 SimpleSwap AMM – Token Pair Swap Contract

This repository implements a basic Automated Market Maker (AMM) smart contract, `SimpleSwap`, that allows users to:

- Provide liquidity between two ERC-20 tokens
- Swap tokens using a constant product formula (x * y = k)
- Withdraw liquidity proportionally

---

## 📦 Contracts Overview

### 1️⃣ `ISimpleSwap.sol`

Defines the standard interface for swap functionality. Includes methods for:

- Adding/removing liquidity
- Swapping tokens
- Reading prices
- Estimating output amounts

### 2️⃣ `SimpleSwap.sol`

A concrete implementation of `ISimpleSwap`. Supports:

- A single token pair initialized during the first call to `addLiquidity()`
- Liquidity pool mechanics with accurate reserve tracking
- Token swapping with slippage protection and a 0.3% fee

### 3️⃣ `SwapVerifier.sol`

A testing scaffold that uses the `ISimpleSwap` interface to validate swap behavior end-to-end. This contract:

- Automatically approves tokens to the swap contract
- Adds and removes liquidity
- Swaps tokens
- Verifies balance changes and price formulas

---

## 🚀 How to Test the Repository Using `SwapVerifier`

The `SwapVerifier` contract multiplies all token inputs (`amountA`, `amountB`, `amountIn`) by `1 ether` to simplify testing with human-readable amounts (e.g., `20`, `30`, `5`).

### ✅ Step-by-Step Instructions

1. **Deploy `TokenA.sol` and `TokenB.sol`**  
   - Each ERC-20 token is deployed with an initial supply of 80 tokens (in ether units).
   - These are standard mock ERC-20 tokens for testing.

2. **Deploy `SimpleSwap.sol`**  
   - This contract will initialize the token pair on first liquidity provision.

3. **Deploy `SwapVerifier.sol`**  
   - This contract imports `ISimpleSwap` and interacts with `SimpleSwap`.
   - Ensure it correctly imports the interface file.

4. **Mint Tokens to `SwapVerifier`**  
   - Call `mint()` on both tokens to give `SwapVerifier` enough balance.  
   - Amounts are specified in full tokens (e.g., `20`, `30`).

5. **Call `verify()` on `SwapVerifier`**  
   This function will:
   - Scale all values to wei using `amountA * 1 ether`, etc.
   - Approve both tokens for the `SimpleSwap` contract
   - Call `addLiquidity()`
   - Check expected price and swap output using `getPrice()` and `getAmountOut()`
   - Execute a token swap
   - Withdraw liquidity and validate amounts

   Example call:
   ```solidity
   verify(
     address swapContract,
     address tokenA,
     address tokenB,
     uint256 amountA,     // e.g., 20
     uint256 amountB,     // e.g., 30
     uint256 amountIn,    // e.g., 5
     string memory author // your name or identifier
   );


6. This is a NatSpec version of the Contract SimpleSwap.sol in english

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISimpleSwap} from "./verificador.sol";

/// @title SimpleSwap Automated Market Maker (AMM)
/// @author 
/// @notice Allows token swapping, liquidity provisioning, and removal for a fixed ERC-20 token pair
/// @dev Implements constant-product AMM logic with 0.3% fee. Pair is fixed after the first addLiquidity call.
contract SimpleSwap is ISimpleSwap, ReentrancyGuard {
    using Math for uint256;

    /// @notice ERC-20 token address for token A
    address public tokenA;

    /// @notice ERC-20 token address for token B
    address public tokenB;

    /// @notice Flag indicating if tokenA and tokenB have been initialized
    bool public pairInitialized;

    /// @notice Current reserve of tokenA in the pool
    uint256 public reserveA;

    /// @notice Current reserve of tokenB in the pool
    uint256 public reserveB;

    /// @notice Total liquidity tokens issued to providers
    uint256 public totalLiquidity;

    /// @notice Mapping of user address to their liquidity share
    mapping(address => uint256) public liquidityOf;

    /// @inheritdoc ISimpleSwap
    /// @notice Adds tokenA and tokenB liquidity to the pool
    /// @dev Sets the token pair on first call and locks it. Calculates optimal token amounts using the pool ratio.
    /// @param tokenA_ Address of token A
    /// @param tokenB_ Address of token B
    /// @param amountADesired Amount of tokenA user wants to add
    /// @param amountBDesired Amount of tokenB user wants to add
    /// @param amountAMin Minimum amount of tokenA to accept (slippage protection)
    /// @param amountBMin Minimum amount of tokenB to accept (slippage protection)
    /// @param to Address to receive the liquidity share
    /// @param deadline Unix timestamp after which the transaction is invalid
    /// @return amountA Final amount of tokenA added
    /// @return amountB Final amount of tokenB added
    /// @return liquidity Amount of liquidity tokens minted
    function addLiquidity(
        address tokenA_,
        address tokenB_,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        override
        nonReentrant
        returns (uint256 amountA, uint256 amountB, uint256 liquidity)
    {
        // ...
    }

    /// @inheritdoc ISimpleSwap
    /// @notice Burns liquidity and returns corresponding amounts of tokenA and tokenB to the user
    /// @dev Tokens must match the stored pair. No slippage protection if reserves are volatile.
    /// @param tokenA_ Address of token A
    /// @param tokenB_ Address of token B
    /// @param liquidity Amount of liquidity to remove
    /// @param amountAMin Minimum acceptable tokenA to receive
    /// @param amountBMin Minimum acceptable tokenB to receive
    /// @param to Address receiving the underlying assets
    /// @param deadline Unix timestamp after which transaction is invalid
    /// @return amountA Amount of tokenA sent to `to`
    /// @return amountB Amount of tokenB sent to `to`
    function removeLiquidity(
        address tokenA_,
        address tokenB_,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        override
        nonReentrant
        returns (uint256 amountA, uint256 amountB)
    {
        // ...
    }

    /// @inheritdoc ISimpleSwap
    /// @notice Swaps an exact amount of tokenA for tokenB following the x*y=k formula
    /// @dev Assumes tokenA is always the input and tokenB is the output. Reserves are updated post-swap.
    /// @param amountIn Amount of input tokenA to swap
    /// @param amountOutMin Minimum tokenB acceptable to receive
    /// @param path Array of token addresses [tokenA, tokenB]
    /// @param to Address receiving the output tokens
    /// @param deadline Unix timestamp after which the transaction is invalid
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override nonReentrant {
        // ...
    }

    /// @inheritdoc ISimpleSwap
    /// @notice Returns the current price of tokenA in terms of tokenB
    /// @param tokenA_ Must match internal tokenA
    /// @param tokenB_ Must match internal tokenB
    /// @return price Price of 1 tokenA denominated in tokenB, scaled by 1e18
    function getPrice(address tokenA_, address tokenB_)
        external
        view
        override
        returns (uint256 price)
    {
        // ...
    }

    /// @inheritdoc ISimpleSwap
    /// @notice Computes how much tokenOut is received for a given amountIn of tokenIn
    /// @dev Assumes a 0.3% swap fee, and constant product formula
    /// @param tokenIn Token being sent into the pool
    /// @param tokenOut Token to receive
    /// @param amountIn Input amount of tokenIn
    /// @return amountOut Output amount of tokenOut after fee and pricing
    function getAmountOut(address tokenIn, address tokenOut, uint256 amountIn)
        external
        view
        override
        returns (uint256 amountOut)
    {
        // ...
    }
}
```solidity
