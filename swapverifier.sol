/**
 * @title SwapVerifier
 * @notice Verifies a SimpleSwap implementation by exercising its functions and asserting correct behavior.
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import {ISimpleSwap} from "verificador.sol";

contract SwapVerifier {

    string[] public authors;

    /// @notice Runs end-to-end checks on a deployed SimpleSwap contract.
    /// @param swapContract Address of the SimpleSwap contract to verify.
    /// @param tokenA Address of a test ERC20 token (must implement IMintableERC20).
    /// @param tokenB Address of a test ERC20 token (must implement IMintableERC20).
    /// @param amountA Initial amount of tokenA to mint and add as liquidity.
    /// @param amountB Initial amount of tokenB to mint and add as liquidity.
    /// @param amountIn Amount of tokenA to swap for tokenB.
    /// @param author Name of the author of swap contract
    function verify(
        address swapContract,
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 amountIn,
        string memory author
    ) external {

        amountA = amountA * 1 ether;
        amountB = amountB * 1 ether;
        amountIn = amountIn * 1 ether;

        require(amountA > 0 && amountB > 0, "Invalid liquidity amounts");
        require(amountIn > 0 && amountIn <= amountA, "Invalid swap amount");
        
        require(IERC20(tokenA).balanceOf(address(this)) >= amountA, "Insufficient token A supply for this contact");
        require(IERC20(tokenB).balanceOf(address(this)) >= amountB, "Insufficient token B supply for this contact");

        // Approve SimpleSwap to transfer tokens
        IERC20(tokenA).approve(swapContract, amountA);
        IERC20(tokenB).approve(swapContract, amountB);

        // Add liquidity
        (uint256 aAdded, uint256 bAdded, uint256 liquidity) = ISimpleSwap(swapContract)
            .addLiquidity(tokenA, tokenB, amountA, amountB, amountA, amountB, address(this), block.timestamp + 1);
        require(aAdded == amountA && bAdded == amountB, "addLiquidity amounts mismatch");
        require(liquidity > 0, "addLiquidity returned zero liquidity");

        // Check price = bAdded * 1e18 / aAdded
        uint256 price = ISimpleSwap(swapContract).getPrice(tokenA, tokenB);
        require(price == (bAdded * 1e18) / aAdded, "getPrice incorrect");

        // Compute expected output for swap
        uint256 expectedOut = ISimpleSwap(swapContract).getAmountOut(tokenA, tokenB, amountIn);
        // Perform swap
        IERC20(tokenA).approve(swapContract, amountIn);
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
        ISimpleSwap(swapContract).swapExactTokensForTokens(amountIn, expectedOut, path, address(this), block.timestamp + 1);
        require(IERC20(tokenB).balanceOf(address(this)) >= expectedOut, "swapExactTokensForTokens failed");

        // Remove liquidity
        (uint256 aOut, uint256 bOut) = ISimpleSwap(swapContract)
            .removeLiquidity(tokenA, tokenB, liquidity, 0, 0, address(this), block.timestamp + 1);
        require(aOut + bOut > 0, "removeLiquidity returned zero tokens");

        // Add author
        authors.push(author);
    }
function verSupplyTA(address tokenA) external view returns (uint256, uint256) {
    uint256 supply = IERC20(tokenA).totalSupply();
    uint256 supplyContract = IERC20(tokenA).balanceOf(address(this));
    return (supply, supplyContract);
}
}