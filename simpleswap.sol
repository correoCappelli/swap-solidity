// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISimpleSwap} from "./verificador.sol"; // Adjust import path as needed

contract SimpleSwap is ISimpleSwap, ReentrancyGuard {
    using Math for uint256;

    address public tokenA;
    address public tokenB;
    bool public pairInitialized;

    uint256 public reserveA;
    uint256 public reserveB;
    uint256 public totalLiquidity;

    mapping(address => uint256) public liquidityOf;

    event SwapExecuted(
    address indexed sender,
    uint256 amountIn,
    uint256 amountOut
);

event LiquidityAdded(
    address indexed provider,
    address indexed tokenA,
    address indexed tokenB,
    uint256 amountA,
    uint256 amountB,
    uint256 liquidity
);

event LiquidityRemoved(
    address indexed provider,
    address indexed tokenA,
    address indexed tokenB,
    uint256 amountA,
    uint256 amountB,
    uint256 liquidity
);

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
        require(block.timestamp <= deadline, "Expired");

        if (!pairInitialized) {
            require(tokenA_ != tokenB_, "Tokens must differ");
            require(tokenA_ != address(0) && tokenB_ != address(0), "Invalid address");
            tokenA = tokenA_;
            tokenB = tokenB_;
            pairInitialized = true;
        } else {
            require(tokenA_ == tokenA && tokenB_ == tokenB, "Token pair mismatch");
        }

        uint256 _reserveA = reserveA;
        uint256 _reserveB = reserveB;

        if (totalLiquidity == 0) {
            amountA = amountADesired;
            amountB = amountBDesired;
        } else {
            uint256 amountBOptimal = (amountADesired * _reserveB) / _reserveA;
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "Insufficient B");
                amountA = amountADesired;
                amountB = amountBOptimal;
            } else {
                uint256 amountAOptimal = (amountBDesired * _reserveA) / _reserveB;
                require(amountAOptimal <= amountADesired, "Excessive A");
                require(amountAOptimal >= amountAMin, "Insufficient A");
                amountA = amountAOptimal;
                amountB = amountBDesired;
            }
        }

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        liquidity = (totalLiquidity == 0)
            ? Math.sqrt(amountA * amountB)
            : Math.min(
                (amountA * totalLiquidity) / _reserveA,
                (amountB * totalLiquidity) / _reserveB
            );

        require(liquidity > 0, "Zero liquidity");

        liquidityOf[to] += liquidity;
        totalLiquidity += liquidity;
        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(to, tokenA, tokenB, amountA, amountB, liquidity);


        return (amountA, amountB, liquidity);
    }

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
        require(block.timestamp <= deadline, "Expired");
        require(tokenA_ == tokenA && tokenB_ == tokenB, "Invalid token pair");
        require(liquidity <= liquidityOf[msg.sender], "Insufficient liquidity");

        amountA = (reserveA * liquidity) / totalLiquidity;
        amountB = (reserveB * liquidity) / totalLiquidity;

        require(amountA >= amountAMin, "Insufficient A");
        require(amountB >= amountBMin, "Insufficient B");

        liquidityOf[msg.sender] -= liquidity;
        totalLiquidity -= liquidity;
        reserveA -= amountA;
        reserveB -= amountB;

        IERC20(tokenA).transfer(to, amountA);
        IERC20(tokenB).transfer(to, amountB);

        emit LiquidityRemoved(msg.sender, tokenA, tokenB, amountA, amountB, liquidity);

        return (amountA, amountB);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override nonReentrant {
        require(block.timestamp <= deadline, "Expired");
        require(path.length == 2, "Path must have 2 tokens");
        require(path[0] == tokenA && path[1] == tokenB, "Unsupported pair");

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountIn);

        uint256 amountInWithFee = (amountIn * 997) / 1000;
        uint256 amountOut = (amountInWithFee * reserveB) / (reserveA + amountInWithFee);

        require(amountOut >= amountOutMin, "Slippage too high");

        reserveA += amountIn;
        reserveB -= amountOut;

        IERC20(tokenB).transfer(to, amountOut);

        emit SwapExecuted(msg.sender, amountIn, amountOut);
    }

    function getPrice(address tokenA_, address tokenB_)
        external
        view
        override
        returns (uint256 price)
    {
        require(tokenA_ == tokenA && tokenB_ == tokenB, "Pair mismatch");
        require(reserveA > 0 && reserveB > 0, "No liquidity");
        price = (reserveB * 1e18) / reserveA;
    }

    function getAmountOut(address tokenIn, address tokenOut, uint256 amountIn)
        external
        view
        override
        returns (uint256 amountOut)
    {
        require(amountIn > 0, "Zero input");
        require(tokenIn == tokenA && tokenOut == tokenB, "Invalid token pair");
        require(reserveA > 0 && reserveB > 0, "No liquidity");

        uint256 amountInWithFee = (amountIn * 997) / 1000;
        amountOut = (amountInWithFee * reserveB) / (reserveA + amountInWithFee);
    }
}