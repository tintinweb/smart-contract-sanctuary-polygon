/**
 *Submitted for verification at polygonscan.com on 2022-07-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    /**
     * @dev Emitted when `value` _tokens are moved from one account (`from`) to
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
     * @dev Returns the amount of _tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of _tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` _tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of _tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's _tokens.
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
     * @dev Moves `amount` _tokens from `from` to `to` using the
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

contract Vault
{
    address owner;

    modifier onlyOwner()
    {
        require(owner==msg.sender,"not owner");
        _;
    }

    constructor(address _owner)
    {
        owner = _owner;
    }

    function sendToken(address _senderAddress, address _tokenAddress, uint256 _amount)
      external
      onlyOwner
    {
        require(IERC20(_tokenAddress).balanceOf(address(this))>=_amount,"don't have sufficient fund to transfer");
        IERC20(_tokenAddress).transfer(_senderAddress,_amount);
    }

    function withdrawToken(uint256 _amount,address _token) 
      external
      onlyOwner
    {
        require(IERC20(_token).balanceOf(address(this))>=_amount,"don't have sufficient fund to transfer");
        IERC20(_token).transfer(msg.sender,_amount);
    }
    
    function balanceOfToken(address _tokenAddress)
      external
      view
      returns (uint256)
    {
       return IERC20(_tokenAddress).balanceOf(address(this));
    }

}