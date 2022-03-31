// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ISynthereumPoolOnChainPriceFeed.sol";
import "../interfaces/IJarvisV4Mint.sol";

/**
 * @title JarvisV4DepositBridge
 * @author DeFi Basket
 *
 * @notice Mints and redeems jTokens using Jarvis Price feed.
 *
 * @dev This contract has 2 main functions:
 *
 * 1. Mint jTokens from Jarvis
 * 2. Redeem jTokens from Jarvis
 *
 */

contract JarvisV4MintBridge is IJarvisV4Mint {
    /**
      * @notice Mints jTokens using Jarvis from USDC.
      *
      * @dev Interacts with SynthereumPoolOnChainPriceFeed to mint jTokens
      *
      * @param assetIn Address of the asset to be converted to jTokens (USDC only)
      * @param percentageIn Percentage of the balance of the asset that will be converted
      * @param assetOut Derivative address for jToken
      * @param minAmountOut Minimum amount of jTokens out (reduces slippage)
      */
    function mint(
        address synthereumAddress,
        address assetIn,
        uint256 percentageIn,
        address assetOut,
        uint256 minAmountOut
    ) external override {
        ISynthereumPoolOnChainPriceFeed jarvis = ISynthereumPoolOnChainPriceFeed(synthereumAddress);

        uint256 amount = IERC20(assetIn).balanceOf(address(this)) * percentageIn / 100000;

        // Approve 0 first as a few ERC20 tokens are requiring this pattern.
        IERC20(assetIn).approve(address(jarvis), 0);
        IERC20(assetIn).approve(address(jarvis), amount);

        uint256 feePercentage = 2000000000000000;

        ISynthereumPoolOnChainPriceFeed.MintParams memory mintParams = ISynthereumPoolOnChainPriceFeed.MintParams(
            assetOut, // Derivative to use
            minAmountOut, // Minimum amount of synthetic tokens that a user wants to mint using collateral (anti-slippage)
            amount, // Amount of collateral that a user wants to spend for minting
            feePercentage, // Maximum amount of fees in percentage that user is willing to pay
            block.timestamp + 10000, // Expiration time of the transaction
            address(this) // Address to which send synthetic tokens minted
        );

        (uint256 amountOut,) = jarvis.mint(mintParams);

        emit DEFIBASKET_JARVISV4_MINT(amount, amountOut);
    }
    /**
      * @notice Redeems USDC using Jarvis from jTokens.
      *
      * @dev Interacts with SynthereumPoolOnChainPriceFeed to redeem jTokens into USDC
      *
      * @param assetIn Address of the jToken
      * @param derivativeAddress Derivative address for jToken
      * @param percentageIn Percentage of the balance of the jToken that will be converted
      * @param assetOut Address of collateral (USDC)
      * @param minAmountOut Minimum amount of collateral out (reduces slippage)
      */
    function redeem(
        address synthereumAddress,
        address assetIn,
        address derivativeAddress,
        uint256 percentageIn,
        address assetOut,
        uint256 minAmountOut
    ) external override {
        ISynthereumPoolOnChainPriceFeed jarvis = ISynthereumPoolOnChainPriceFeed(synthereumAddress);

        uint256 amount = IERC20(assetIn).balanceOf(address(this)) * percentageIn / 100000;

        // Approve 0 first as a few ERC20 tokens are requiring this pattern.
        IERC20(assetIn).approve(address(jarvis), 0);
        IERC20(assetIn).approve(address(jarvis), amount);

        uint256 feePercentage = 2000000000000000;

        ISynthereumPoolOnChainPriceFeed.RedeemParams memory redeemParams = ISynthereumPoolOnChainPriceFeed.RedeemParams(
            derivativeAddress, // Derivative to use
            amount, // Amount of synthetic tokens that user wants to use for redeeming
            minAmountOut, // Minimium amount of collateral that user wants to redeem (anti-slippage)
            feePercentage, // Maximum amount of fees in percentage that user is willing to pay
            block.timestamp + 10000, // Expiration time of the transaction
            address(this) // Address to which send collateral tokens redeemed
        );

        (uint256 amountOut,) = jarvis.redeem(redeemParams);

        emit DEFIBASKET_JARVISV4_REDEEM(amount, amountOut);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

interface ISynthereumPoolOnChainPriceFeed{
    struct MintParams {
        // Derivative to use
        address derivative;
        // Minimum amount of synthetic tokens that a user wants to mint using collateral (anti-slippage)
        uint256 minNumTokens;
        // Amount of collateral that a user wants to spend for minting
        uint256 collateralAmount;
        // Maximum amount of fees in percentage that user is willing to pay
        uint256 feePercentage;
        // Expiration time of the transaction
        uint256 expiration;
        // Address to which send synthetic tokens minted
        address recipient;
    }

    struct RedeemParams {
        // Derivative to use
        address derivative;
        // Amount of synthetic tokens that user wants to use for redeeming
        uint256 numTokens;
        // Minimium amount of collateral that user wants to redeem (anti-slippage)
        uint256 minCollateral;
        // Maximum amount of fees in percentage that user is willing to pay
        uint256 feePercentage;
        // Expiration time of the transaction
        uint256 expiration;
        // Address to which send collateral tokens redeemed
        address recipient;
    }

    function mint(MintParams memory mintParams)
        external
    returns (uint256 syntheticTokensMinted, uint256 feePaid);

    function redeem(RedeemParams memory redeemParams)
        external
    returns (uint256 collateralRedeemed, uint256 feePaid);


}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

interface IJarvisV4Mint {
    event DEFIBASKET_JARVISV4_MINT (
        uint256 amountIn,
        uint256 amountOut
    );

    event DEFIBASKET_JARVISV4_REDEEM (
        uint256 amountIn,
        uint256 amountOut
    );

    // Note: function addLiquidity does not stakes the LP token
    function mint(
        address synthereumAddress,
        address assetIn,
        uint256 percentageIn,
        address assetOut,
        uint256 minAmountOut)
    external;

    function redeem(
        address synthereumAddress,
        address assetIn,
        address derivativeAddress,
        uint256 percentageIn,
        address assetOut,
        uint256 minAmountOut
    ) external;

}