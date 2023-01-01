// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IERC20.sol";


// Contract to batch transfer ERC20 tokens
// msg.sender must allow this contract to spend the tokens by calling approve() on the ERC20 token contract
contract BatchTransfer {
    constructor () {}


    modifier erc20TokensAvailable(uint256[] memory amounts, address erc20Token) {
        uint256 totalAmount = 0;
        for (uint i = 0; i<amounts.length; i++) {
            totalAmount += amounts[i];
        }
        IERC20 _currency = IERC20(erc20Token);
        require(_currency.balanceOf(msg.sender) >= totalAmount, "Balance Not Enough");
        require(_currency.allowance(msg.sender, address(this))>=totalAmount, "Not Allowed to spend");
        _;
    }

    function groupTransfer(address[] memory addrs, uint256[] memory amounts, address erc20Token) public erc20TokensAvailable(amounts, erc20Token) 
    returns(bool) {
        IERC20 _currency = IERC20(erc20Token);
        for (uint i = 0; i<amounts.length; i++) {
            bool _success = _currency.transferFrom(msg.sender, addrs[i], amounts[i]);
            require(_success, "Couldn't transfer to addr");
        }
        return true;
    }

}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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