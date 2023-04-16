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

// SPDX-License-Identifier: UNLINCENSED

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract vestingCafe  {

  address public owner;
  address public owner2;
  uint256 public time_locked = 2629743; //  Month
  uint256 public lockedMonths = 24;
  address public addressCafe;
  IERC20 contractCafe;
  uint256 public maxOwnerWithdraw = 3300000 * 10 ** 18;
  uint256 public maxOwnerWithdrawPerMonth = maxOwnerWithdraw / lockedMonths;

  mapping(address => uint256) public _balanceWithdrawOwner;
  mapping(address => uint256) public _blockTimeWithdrawOwner;

  modifier onlyOwner() {
    require(msg.sender == owner || msg.sender == owner2, "Ownable: caller is not the owner" );
    _;
  }

  constructor() {
    owner = 0x70c9AEE0B3EF9c10E0b330367F0906dFe76950fC; 
    owner2 = 0xca8Ab405984cAc189bbEB05F453fE9A956E499C2;
    _balanceWithdrawOwner[owner] = 0;
    _balanceWithdrawOwner[owner2] = 0;
    _blockTimeWithdrawOwner[owner] = block.timestamp + time_locked;
    _blockTimeWithdrawOwner[owner2] = block.timestamp + time_locked;
  }

  function withdraw() public onlyOwner{
    uint256 _amount = 137500 * 10 ** 18;
    require(_amount + _balanceWithdrawOwner[msg.sender] <= maxOwnerWithdraw,"You've gotten all you can out of this contract");
    require(block.timestamp >= _blockTimeWithdrawOwner[msg.sender],"Wait 30 days for a new withdrawal");

    uint256 balance = _balanceWithdrawOwner[msg.sender];
    _balanceWithdrawOwner[msg.sender] = balance + _amount;
    _blockTimeWithdrawOwner[msg.sender] = block.timestamp + time_locked;

    (bool sent) = contractCafe.transfer(msg.sender, _amount);
    require(sent, "Failed to transfer token to Owner");
  }

  function setAddressCafe(address _addressCafe) public onlyOwner {
    addressCafe = _addressCafe;
    contractCafe = IERC20(addressCafe);
  }

}