/**
 *Submitted for verification at polygonscan.com on 2022-02-21
*/

// File: @0xcert/ethereum-utils-contracts/src/contracts/permission/ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @dev The contract has an owner address, and provides basic authorization control which
 * simplifies the implementation of user permissions. This contract is based on the source code at:
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
 */
contract Ownable
{

  /**
   * @dev Error constants.
   */
  string constant NOT_OWNER = "018001";
  string constant ZERO_ADDRESS_NOT_ALLOWED = "018002";

  /**
   * @dev Address of the owner.
   */
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  constructor()
  {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner()
  {
    require(msg.sender == owner, NOT_OWNER);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(
    address _newOwner
  )
    public
    virtual
    onlyOwner
  {
    require(_newOwner != address(0), ZERO_ADDRESS_NOT_ALLOWED);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}

// File: openzeppelin-solidity/contracts/utils/math/SafeMath.sol



pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/ArianeeStore/ArianeeCreditHistory.sol


pragma solidity 0.8.0;


contract ArianeeCreditHistory is
Ownable
{
  using SafeMath for uint256;

  /**
   * @dev Mapping from address to array of creditHistory by type of credit.
   */
  mapping(address => mapping(uint256=>CreditBuy[])) internal creditHistory;

  /**
   * @dev Mapping from address to creditHistory index by type of the credit.
   */
  mapping(address => mapping(uint256=>uint256)) internal historyIndex;

  /**
   * @dev Mapping from address to totalCredit by type of the credit.
   */
  mapping(address => mapping(uint256=>uint256)) internal totalCredits;

  /**
   * @dev Address of the actual store address.
   */
  address public arianeeStoreAddress;

  struct CreditBuy{
      uint256 price;
      uint256 quantity;
  }

  /**
   * @dev This emits when a new address is set.
   */
  event SetAddress(string _addressType, address _newAddress);

  modifier onlyStore(){
      require(msg.sender == arianeeStoreAddress, 'not called by store');
      _;
  }

  /**
   * @dev public function that change the store contract address.
   * @notice Can only be called by the contract owner.
   */
  function setArianeeStoreAddress(address _newArianeeStoreAdress) onlyOwner() external {
      arianeeStoreAddress = _newArianeeStoreAdress;
      emit SetAddress("arianeeStore", _newArianeeStoreAdress);
  }

  /**
   * @dev public funciton that add a credit history when credit are bought.
   * @notice can only be called by the store.
   * @param _spender address of the buyer
   * @param _price current price of the credit.
   * @param _quantity of credit buyed.
   * @param _type of credit buyed.
   */
  function addCreditHistory(address _spender, uint256 _price, uint256 _quantity, uint256 _type) external onlyStore() {

      CreditBuy memory _creditBuy = CreditBuy({
          price: _price,
          quantity: _quantity
          });

      creditHistory[_spender][_type].push(_creditBuy);
      totalCredits[_spender][_type] = SafeMath.add(totalCredits[_spender][_type], _quantity);
  }

  /**
   * @dev Public function that consume a given quantity of credit and return the price of the oldest non spent credit.
   * @notice Can only be called by the store.
   * @param _spender address of the buyer.
   * @param _type type of credit.
   * @return price of the credit.
   */
  function consumeCredits(address _spender, uint256 _type, uint256 _quantity) external onlyStore() returns (uint256) {
      require(totalCredits[_spender][_type]>0, "No credit of that type");
      uint256 _index = historyIndex[_spender][_type];
      require(creditHistory[_spender][_type][_index].quantity >= _quantity);

      uint256 price = creditHistory[_spender][_type][_index].price;
      creditHistory[_spender][_type][_index].quantity = SafeMath.sub(creditHistory[_spender][_type][_index].quantity, _quantity);
      totalCredits[_spender][_type] = SafeMath.sub(totalCredits[_spender][_type], 1);

      if(creditHistory[_spender][_type][_index].quantity == 0){
          historyIndex[_spender][_type] = SafeMath.add(historyIndex[_spender][_type], 1);
      }

      return price;
  }

  /**
   * @notice Give a specific credit history for a given spender, and type.
   * @param _spender for which we want the credit history.
   * @param _type of the credit for which we want the history.
   * @param _index of the credit for which we want the history.
   * @return _price credit price for this purchase.
   * * @return _quantity credit quantity for this purchase.
   */
  function userCreditHistory(address _spender, uint256 _type, uint256 _index) external view returns (uint256 _price, uint256 _quantity) {
      _price = creditHistory[_spender][_type][_index].price;
      _quantity = creditHistory[_spender][_type][_index].quantity;
  }

  /**
   * @notice Get the actual index for a spender and a credit type.
   * @param _spender for which we want the credit history.
   * @param _type of the credit for which we want the history.
   * @return _historyIndex Current index.
   */
  function userIndex(address _spender, uint256 _type) external view returns(uint256 _historyIndex){
      _historyIndex = historyIndex[_spender][_type];
  }

  /**
   * @notice Give the total balance of credit for a spender.
   * @param _spender for which we want the credit history.
   * @param _type of the credit for which we want the history.
   * @return _totalCredits Balance of the spender.
   */
  function balanceOf(address _spender, uint256 _type) external view returns(uint256 _totalCredits){
      _totalCredits = totalCredits[_spender][_type];
  }

}