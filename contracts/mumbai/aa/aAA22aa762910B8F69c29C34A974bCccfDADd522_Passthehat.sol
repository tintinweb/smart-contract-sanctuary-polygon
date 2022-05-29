// SPDX-License-Identifier: MIT

/// @title Pass the Hat: Crowdfunding projects made easy with blockchain.
/// @author Ricardo Vieira

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Passthehat is Ownable {
  using SafeMath for uint;

  uint32 public constant MAX_FEE = 5000;
  uint32 public FEE = 3000;
  address public adminWallet;

  event TimeLimitIncreased(address _fundingAddress, uint32 _newTime);
  event NewDonate(address _from, address _to, uint _value, uint balance);
  event NewFunding(
    uint _id,
    address _owner,
    uint _goal,
    uint minAmount,
    uint32 _startsIn,
    uint32 _expiresIn,
    uint32 _createdAt,
    bool isFlexibleTimeLimit
  );

  struct CrowdfundingRegistration {
    address owner;
    uint goal;
    uint minAmount;
    uint balance;
    uint32 startsIn;
    uint32 expiresIn;
    uint32 createdAt;
    bool isActive;
    bool isFlexibleTimeLimit;
    bool isTimeLimitIncreased;
  }

  CrowdfundingRegistration[] public registry;

  mapping(address => uint) crowdFundingId;

  modifier isGoalReached() {
    uint id = crowdFundingId[msg.sender];

    CrowdfundingRegistration memory _registry = registry[id];

    require(msg.sender == _registry.owner);

    require(_registry.goal < _registry.balance, "Funding not reached.");
    _;
  }

  modifier isOwnerOfFunding() {
    uint id = crowdFundingId[msg.sender];

    CrowdfundingRegistration memory _registry = registry[id];

    require(msg.sender == _registry.owner);
    _;
  }

  function newRegistry(CrowdfundingRegistration memory _registry) private {
    require(_registry.owner != address(0));

    registry.push(_registry);

    uint id = registry.length - 1;

    crowdFundingId[msg.sender] = id;

    emit NewFunding(
      id,
      _registry.owner,
      _registry.goal,
      _registry.minAmount,
      _registry.startsIn,
      _registry.expiresIn,
      _registry.createdAt,
      _registry.isFlexibleTimeLimit
    );
  }

  function createFunding(
    uint _goal,
    uint _minAmount,
    uint32 _startsIn,
    uint32 _expiresIn,
    bool _isFlexibleTimeLimit
  ) public {
    uint32 createdAt = uint32(block.timestamp);
    uint32 max_allowed = createdAt + 60 days;

    if (_startsIn == 0) {
      newRegistry(
        CrowdfundingRegistration(
          msg.sender,
          _goal,
          _minAmount,
          0,
          createdAt,
          _expiresIn,
          createdAt,
          true,
          _isFlexibleTimeLimit,
          false
        )
      );

      return;
    }

    if ((_startsIn > createdAt && _startsIn <= max_allowed)) {
      newRegistry(
        CrowdfundingRegistration(
          msg.sender,
          _goal,
          _minAmount,
          0,
          _startsIn,
          _expiresIn,
          createdAt,
          true,
          _isFlexibleTimeLimit,
          false
        )
      );
    } else {
      revert("You must pass a start date in epoch time format with a maximum of 60 days from now");
    }
  }

  function increaseFundraisingTime(uint32 _days) public isOwnerOfFunding {
    require(_days >= 0 && _days <= 30, "The number of days need to be less than or equal to 30");

    uint32 extendedTime = _days * 24 * 60 * 60;
    uint id = crowdFundingId[msg.sender];

    CrowdfundingRegistration storage funding = registry[id];

    require(
      funding.isTimeLimitIncreased == false,
      "You cannot increase the time limit more than once"
    );

    require(funding.isFlexibleTimeLimit == false, "This Funding has a flexible time limit.");

    funding.expiresIn = (funding.expiresIn + extendedTime);

    funding.isTimeLimitIncreased = true;

    emit TimeLimitIncreased(msg.sender, funding.expiresIn + extendedTime);
  }

  function getFunding(address _fundingAddress)
    public
    view
    returns (CrowdfundingRegistration memory)
  {
    uint id = crowdFundingId[_fundingAddress];

    CrowdfundingRegistration memory funding = registry[id];

    return funding;
  }

  function donate(address _fundingAddress) public payable {
    uint id = crowdFundingId[_fundingAddress];

    CrowdfundingRegistration storage funding = registry[id];

    require(
      funding.isActive == true,
      "This funding has already reached its goal and no longer accepts donations."
    );

    require(msg.value >= 0);

    require(
      msg.value >= funding.minAmount,
      "This funding has a minimum amount allowed for donations."
    );

    funding.balance = funding.balance.add(msg.value);

    emit NewDonate(msg.sender, _fundingAddress, msg.value, funding.balance);
  }

  function withdraw() public isGoalReached {
    uint id = crowdFundingId[msg.sender];

    CrowdfundingRegistration storage funding = registry[id];

    require(msg.sender == funding.owner);

    uint withdrawalFee = funding.balance.mul(FEE / 100).div(10000);

    payable(msg.sender).transfer(funding.balance.sub(withdrawalFee));

    payable(adminWallet).transfer(withdrawalFee);

    funding.isActive = false;
  }

  function balanceOf(address _fundingAddress) public view returns (uint) {
    uint id = crowdFundingId[_fundingAddress];

    CrowdfundingRegistration storage funding = registry[id];

    if (funding.owner == _fundingAddress) {
      return funding.balance;
    } else {
      return 0;
    }
  }

  function setFee(uint16 _fee) public onlyOwner {
    require((_fee * 100) <= MAX_FEE, "Fee is greater than the maximum allowed.");

    FEE = _fee * 100;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}