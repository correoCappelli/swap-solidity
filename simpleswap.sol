// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "verificador.sol";

contract SimpleSwap is ISimpleSwap {

    using Math for uint256;

    address public tokenA;
    address public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;
    uint256 public totalLiquidity;

    mapping(address => uint256) public liquidityOf;

    modifier onlyTokens(address tA, address tB) {
        require(tA == tokenA && tB == tokenB, "Unsupported token pair");
        _;
    }

    function addLiquidity(
        address tA,
        address tB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 ,
        uint256 ,
        address to,
        uint256 deadline
    )
        external
        override
        returns (uint256 amountA, uint256 amountB, uint256 liquidity)
    {
        


        require(block.timestamp <= deadline, "Expired");

        if (tokenA == address(0) && tokenB == address(0)) {
            tokenA = tA;
            tokenB = tB;
        }

        require(tA == tokenA && tB == tokenB, "Invalid tokens");

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountADesired);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountBDesired);

        amountA = amountADesired;
        amountB = amountBDesired;

        liquidity = (totalLiquidity == 0)
            ? Math.sqrt(amountA * amountB)
            : Math.min(
                (amountA * totalLiquidity) / reserveA,
                (amountB * totalLiquidity) / reserveB
            );

        require(liquidity > 0, "Zero liquidity");

        liquidityOf[to] += liquidity;
        totalLiquidity += liquidity;

        reserveA += amountA;
        reserveB += amountB;
    }

    function removeLiquidity(
        address tA,
        address tB,
        uint256 liquidity,
        uint256,
        uint256,
        address to,
        uint256 deadline
    )
        external
        override
        onlyTokens(tA, tB)
        returns (uint256 amountA, uint256 amountB)
    {
        require(block.timestamp <= deadline, "Expired");
        require(liquidity <= liquidityOf[msg.sender], "Insufficient LP");

        amountA = (reserveA * liquidity) / totalLiquidity;
        amountB = (reserveB * liquidity) / totalLiquidity;

        reserveA -= amountA;
        reserveB -= amountB;
        totalLiquidity -= liquidity;
        liquidityOf[msg.sender] -= liquidity;

        IERC20(tokenA).transfer(to, amountA);
        IERC20(tokenB).transfer(to, amountB);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override {

        

        require(block.timestamp <= deadline, "Expired");
        require(path.length == 2, "Invalid path");

        address tokenIn = path[0];
        address tokenOut = path[1];
        require(tokenIn == tokenA && tokenOut == tokenB, "Unsupported pair");

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        uint256 amountInWithFee = amountIn * 997 / 1000;
        uint256 amountOut = (amountInWithFee * reserveB) / (reserveA + amountInWithFee);
        require(amountOut >= amountOutMin, "Slippage too high");

        reserveA += amountIn;
        reserveB -= amountOut;

        IERC20(tokenOut).transfer(to, amountOut);
    }

    function getPrice(address tA, address tB)
        external
        view
        override
        onlyTokens(tA, tB)
        returns (uint256)
    {
        require(reserveA > 0 && reserveB > 0, "No liquidity");
        return (reserveB * 1e18) / reserveA;
    }

    function getAmountOut(address tIn, address tOut, uint256 amountIn)
        external
        view
        override
        onlyTokens(tIn, tOut)
        returns (uint256)
    {
        uint256 amountInWithFee = amountIn * 997 / 1000;
        return (amountInWithFee * reserveB) / (reserveA + amountInWithFee);
    }
}
