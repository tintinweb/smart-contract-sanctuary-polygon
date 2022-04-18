// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

contract Wallet
{
    address public owner;

    bool pause;

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }

    constructor(
        address _owner
    )
    {
       owner = _owner;
    }
    
    function updateOwner(
        address _owner
    )external onlyOwner
    {
        owner = _owner;
    }

    function paused()
      external
      onlyOwner
    {
        pause = true;
    }

    function unpaused()
       external
       onlyOwner
    {
       pause = false;
    }

    function send(
        address _to,
        address _token,
        uint256 _amount
    ) external onlyOwner
    {
       require(!pause,"wallet is paused for now");
       require(IERC20(_token).balanceOf(address(this))>=_amount,"don't have sufficient fund to transfer");
       IERC20(_token).transfer(_to,_amount);     
    }
    
    function withdraw(
        address _token,
        uint256 _amount
    ) external onlyOwner
    {
        require(!pause,"wallet is paused for now");
        require(IERC20(_token).balanceOf(address(this))>=_amount,"don't have sufficient fund to transfer");
        IERC20(_token).transfer(msg.sender,_amount);
    }

    function deposite(
        address _token,
        uint256 _amount
    ) external onlyOwner
    {
       require(!pause,"wallet is paused for now"); 
       require(IERC20(_token).allowance(msg.sender,address(this))>=_amount,"allowance is not enough");
       IERC20(_token).transferFrom(msg.sender,address(this),_amount);
    }

    function balanceOfWallet(address _token)
       external
       view
       onlyOwner
       returns(
           uint256
    )
    {
       return IERC20(_token).balanceOf(address(this));
    }

}