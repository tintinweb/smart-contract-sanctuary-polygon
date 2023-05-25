/**
 *Submitted for verification at polygonscan.com on 2023-05-25
*/

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
    function transferFrom(
        address sender,
        address recipient,
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

/**
 * @dev Implementation of Transfering
 */
contract privateSale {

    // public address of admin of the contract
    address payable admin;

    // Number of RN Token per matic
    uint256 public conversionRate; 

    // RN Token address
    address public rnTokenAddress;

    constructor(address _rnTokenAddress) {
        admin = payable(msg.sender);
        conversionRate = 2;
        rnTokenAddress = _rnTokenAddress;
    }

    function setConversionRate(uint256 _conversionRate) public adminRestricted {
        conversionRate = _conversionRate;
    }

    function buy() public payable {
        require (msg.value > 50*(10**18));
        uint256 amountOfRnTokens = (msg.value/conversionRate)*1000;
        IERC20(rnTokenAddress).transfer(msg.sender, amountOfRnTokens);
    }

    function withdrawRnTokens(uint256 _amount) public adminRestricted {
        IERC20(rnTokenAddress).transfer(admin, _amount);
    }

    function getBalance() public view returns (uint) {
        return IERC20(rnTokenAddress).balanceOf(address(this));
    }

    function withdrawMaticToken() public adminRestricted {
        admin.transfer(address(this).balance);
    }

    /**
    * @dev modifier only for admin purpose
    *
    */
    modifier adminRestricted() {
        require(msg.sender == admin, "This function is restricted to the contract's admin");
        _;
    }
}