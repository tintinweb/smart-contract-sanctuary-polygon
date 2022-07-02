/**
 *Submitted for verification at polygonscan.com on 2022-07-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


 library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

  /**
   * @dev remove an account's access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

contract Distributor {

    /// using Role struct from 'Roles' library
    using Roles for Roles.Role;

    /// 2 events, one for Adding, and other for Removing
    event DistributorAdded(address indexed account);
    event DistributorRemoved(address indexed account);

    /// structure '_distributors' inherited from 'Roles' library
    Roles.Role private _distributors;

    /// @notice constructer will assign the deployer as 1st distributor
    constructor ()  {
        _addDistributor(msg.sender);
    }

    // modifier that checks to see if `msg.sender` has distributor role
    modifier onlyDistributor() {
        require(isDistributor(msg.sender), 'Not A Distributor!');
        _;
    }

    /// Function to check even he has distributor role or not
    /// @param account address to be checked
    /// @return boolean for this address state in `_distributors` Role
    /// @notice uses'Roles' library's internal function `has()` to check, refer to library for more detail
    function isDistributor(address account) public view returns (bool) {
        return _distributors.has(account);
    }

    /// Function to check caller `msg.sender` if he has distributor role
    /// @return boolean for caller address state in `_distributors` Role
    function amIDistributor() public view returns (bool) {
        return _distributors.has(msg.sender);
    }

    /// Function to assign caller `msg.sender` to distributor role
    // function assignMeAsDistributor() public {
    //     _addDistributor(msg.sender);
    // }

    /// Function to renounce caller `msg.sender` from distributor role
    function renounceMeFromDistributor() public {
        _removeDistributor(msg.sender);
    }
    function addDistributor(address account) public onlyDistributor{
        _addDistributor(account);
    }

    /// Internal function to add account to this role
    /// @param account address to be Added
    /// @notice uses'Roles' library's internal function `add()`, refer to the library for more detail
    function _addDistributor(address account) internal  {
        _distributors.add(account);
        emit DistributorAdded(account);
    }

    /// Internal function to remove account from this role
    /// @param account address to be removed
    /// @notice uses'Roles' library's internal function `remove()`, refer to the library for more detail
    function _removeDistributor(address account) internal {
        _distributors.remove(account);
        emit DistributorRemoved(account);
    }
}

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
contract Profit is Distributor{
    using SafeMath for uint;

    address public treasuryWallet;
    IERC20 immutable private token;
    event profitReceived(address indexed receiver,uint profitReceived);
    constructor(address _rewardWallet,address _token ){

         treasuryWallet = address(_rewardWallet);
         token=IERC20(_token);
    }

    function  updateTreasuryWallet(address _treasuryWallet) public{
        treasuryWallet = _treasuryWallet;       
    }

    function _profitDistribute(address[] memory receiver,uint profitPercent) internal  onlyDistributor{
        uint profit=token.balanceOf(treasuryWallet);
        require(profit>0,"no profit to distribute in treadsury wallet");
        uint profitToDistribute = profit.mul(profitPercent).div(1000);
        require(token.allowance(treasuryWallet,address(this))>profitToDistribute,"treasury wallet allowance not suffiecnt");
        uint profitPerRecevier= profitToDistribute.div(receiver.length);
        for(uint i=0;i< receiver.length;i++){

            token.transferFrom(treasuryWallet,receiver[i],profitPerRecevier);
            emit profitReceived(receiver[i],profitPerRecevier);
            
       }

    }
    function profit49(address[] memory receiver) public {
        _profitDistribute(receiver,490);
    }
    function profit10(address[] memory receiver) public {
        _profitDistribute(receiver,100);
    }

    // function Profit49(address[] memory receiver) public onlyDistributor{
    //     uint profit=token.balanceOf(treasuryWallet);
    //     require(profit>0,"no profit to distribute in treadsury wallet");
    //     uint profit49= profit.mul(49).div(100);
    //     require(token.allowance(address(this),treasuryWallet)>0,"treasury wallet allowance not suffiecnt");
    //     uint profitPerRecevier= profit49.div(receiver.length);
    //     for(uint i=0;i<=receiver.length;i++){

    //         token.transferFrom(treasuryWallet,receiver[i],profitPerRecevier);
    //     }

    // }
    // function Profit10(address[] memory receiver)public  onlyDistributor{
    //     uint profit=token.balanceOf(treasuryWallet);
    //     require(profit>0,"no profit to distribute in treadsury wallet");
    //     uint profit49= profit.mul(10).div(100);
    //     require(token.allowance(address(this),treasuryWallet)>0,"treasury wallet allowance not suffiecnt");
    //     uint profitPerRecevier= profit49.div(receiver.length);
    //     for(uint i=0;i<=receiver.length;i++){

    //         token.transferFrom(treasuryWallet,receiver[i],profitPerRecevier);
    //    }

    // }
    
 
}