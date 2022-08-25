// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IPool {
    function supply(address asset, uint amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint amount, address to) external;
}

contract Adapter {

    IERC20 constant usdc = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    IERC20 constant aUsdc = IERC20(0x625E7708f30cA75bfd92586e17077590C60eb4cD);
    IPool constant pool = IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);
    address constant deSwapSender = 0x663DC15D3C1aC63ff12E45Ab68FeA3F0a883C251;

    constructor() {
        usdc.approve(address(pool), type(uint).max);
        aUsdc.approve(address(pool), type(uint).max);
        usdc.approve(deSwapSender, type(uint).max);
    }

    function stake() external {
        pool.supply(
            address(usdc),
            usdc.balanceOf(address(this)),
            address(this),
            0
        );
    }

    function withdraw() external {
        pool.withdraw(
            address(usdc), 
            aUsdc.balanceOf(address(this)),
            address(this)
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}