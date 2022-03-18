/**
 *Submitted for verification at polygonscan.com on 2022-03-17
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
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

// File: CustomTokenSwapPoly.sol


pragma solidity ^0.8.10;


contract CustomTokenSwapPoly {
    IERC20 public buyerToken;
    address public buyer;
    uint256 public buyerAmt;
    address public usdtToken;
    address public usdcToken;
    address public daiToken;
    address private tysToken;
    address private tysTokenWallet;
    address private stableWallet;
    IERC20 public sellerToken;
    address public seller;
    uint256 public sellerAmt;

    constructor(
        address _usdtToken,
        address _usdcToken,
        address _daiToken,
        address _tysToken,
        address _tysTokenWallet,
        address _stableWallet
    ) {
        usdtToken = _usdtToken;
        usdcToken = _usdcToken;
        daiToken = _daiToken;
        tysToken = _tysToken;
        tysTokenWallet = _tysTokenWallet;
        stableWallet = _stableWallet;
    }

    function swap(
        address token,
        address buyerAdd,
        uint256 buyAmt,
        address sellerAdd,
        uint256 sellAmt
    ) public {
        // Reject if not usdt, usdc or dai
        require(
            token == usdtToken || token == usdcToken || token == daiToken,
            "buyerToken not allowed"
        );

        // Reject if buyer address is invalid
        require(
            buyerAdd != tysTokenWallet && buyerAdd != stableWallet,
            "buyerAdd not authorized"
        );

        // Reject if stablecoins are not going to stablecoin wallet
        require(
            sellerAdd == stableWallet,
            "Stablecoins to unauthorized wallet"
        );

        buyerToken = IERC20(token);
        buyer = buyerAdd;
        buyerAmt = buyAmt;
        sellerToken = IERC20(tysToken);
        seller = sellerAdd;
        sellerAmt = sellAmt;

        // Reject if buyer or seller address doesn't match
        require(
            msg.sender == buyer || msg.sender == tysTokenWallet,
            "Not authorized"
        );

        // Reject if buyerToken allowance is not enough
        require(
            buyerToken.allowance(buyer, address(this)) >= buyerAmt,
            "Buyer Token allowance too low"
        );

        // Reject if sellerToken allowance is not enough
        require(
            sellerToken.allowance(tysTokenWallet, address(this)) >= sellerAmt,
            "TYS Token allowance too low"
        );

        _safeTransferFrom(buyerToken, buyer, seller, buyerAmt);
        _safeTransferFrom(sellerToken, tysTokenWallet, buyer, sellerAmt);
    }

    function _safeTransferFrom(
        IERC20 token,
        address sender,
        address recipient,
        uint256 amount
    ) private {
        bool sent = token.transferFrom(sender, recipient, amount);
        require(sent, "Token transfer failed");
    }
}