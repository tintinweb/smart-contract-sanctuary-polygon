/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


contract RewardContract {
    IERC20 public USDC; 
    IERC20 public DAI ; //=  IERC20 ( 0x73e2278B2D5f32AaFBC00C1Bd85055Ab0CB1450A); 
    uint256 constant public REWARD_MULTIPLIER = 5 ;
    uint constant MIN_TRANSFER_AMOUNT = 20;  
    address public admin;
  //  uint public left;
    uint public deposit;
    bool public isFirstTransaction;
    mapping(address => uint) public userPayments;
 //  mapping(address => uint256) public _balances;

   
  constructor (address _admin, IERC20 _USDC , IERC20 _DAI )  {
         admin = _admin ;
          USDC = _USDC;  
          DAI = _DAI;  
          isFirstTransaction = true;
    }
    function updateUsdc(IERC20 _USDC ) public{
        require(msg.sender == admin, "u are not the admin " );
        USDC = _USDC;
    }
    function updateDAI(IERC20 _DAI ) public{
        require(msg.sender == admin, "u are not the admin " );
        DAI = _DAI;
    }
   
    function transfering( uint value ) external  returns (uint, address) {
        require ( ( userPayments [msg.sender] < 250 ), "USDC EXCEEDING THE LIMIT");
         if (isFirstTransaction) {
            require(value > 20, "At first, you have to deposit more than 20 USDC");
            isFirstTransaction = false;
            }
        uint256 transfer_amount = value * REWARD_MULTIPLIER;
        userPayments[msg.sender] += value;
        require(USDC.transferFrom(msg.sender, address(this), value), "USDT transfer failed");
        require(DAI.transfer(address(msg.sender), transfer_amount), "DAI transfer failed");
        return (transfer_amount, address(this));
    }
      function redeamrewards( )public {
          require(msg.sender == admin, "onle admin can call this function ");
          uint256 balance =  USDC.balanceOf (address(this));
          USDC.transfer(admin,balance); 

      }
     
   }