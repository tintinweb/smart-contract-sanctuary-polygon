/**
 *Submitted for verification at polygonscan.com on 2023-06-12
*/

// SPDX-License-Identifier: GPL-3.0

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: sale.sol


pragma solidity ^0.8.0;


contract TokenSale {
    IERC20 public token;
    address public owner;
    uint public price;
    uint public tokensSold;
    bool public saleEnded;

    mapping(address => uint) public tokenClaims;

    event Sold(address buyer, uint amount);
    event SaleEnded();

    constructor(IERC20 _token, uint _price) {
        token = _token;
        owner = msg.sender;
        price = _price;
        saleEnded = false;
    }

    receive() external payable {
        buyTokens();
    }

    function buyTokens() public payable {
        require(!saleEnded, "The sale has ended");

        uint tokenAmount = msg.value / price;
        require(tokenAmount > 0, "Insufficient payment");

        tokensSold += tokenAmount;
        emit Sold(msg.sender, tokenAmount);

        // Store the token amount to be claimed by the buyer
        tokenClaims[msg.sender] += tokenAmount*1e18;

        // Check token balance and end the sale if it reaches zero
        if (token.balanceOf(address(this)) == 0) {
            saleEnded = true;
            emit SaleEnded();
        }
    }

    function claimTokens() public {
        require(tokenClaims[msg.sender] > 0, "No tokens to claim");

        uint claimAmount = tokenClaims[msg.sender];
        tokenClaims[msg.sender] = 0;

        // Transfer the claimed tokens to the buyer
        require(token.transfer(msg.sender, claimAmount), "Token transfer failed");
    }

    function withdrawFunds() public {
        require(msg.sender == owner, "Only the owner can withdraw funds");
        uint balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(msg.sender).transfer(balance);
    }

    function getContractTokenBalance() public view returns (uint) {
        return token.balanceOf(address(this));
    }
}