// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/IEscrowCapable.sol";

contract XFUNEscrow is Ownable {
  using SafeMath for uint256;

  IEscrowCapable public token;

  modifier accessAllowed() {
    require(granted[msg.sender] > 0, "Not allowed");
    _;
  }

  mapping(uint256 => mapping(address => uint256))
    public escrowedBalancesOfService;
  mapping(address => uint256) public granted;
  mapping(uint256 => uint256) public escrowedOfService;

  constructor(address _tokenAddress) {
    require(_tokenAddress != address(0), "_tokenAddress can't be zero address");
    token = IEscrowCapable(_tokenAddress);
  }

  event AccessGranted(address _addr, uint256 _id);
  event AccessRemoved(address _addr, uint256 _id);
  event TokenEscrowDeposit(address _who, address _fromAddress, uint256 _amount);
  event TokenEscrowWithdraw(
    address _who,
    address _toAddress,
    uint256 _amount,
    uint256 _fee
  );
  event EscrowMoved(address _who, address _fromAddress, uint256 _amount);

  function allowAccess(address _addr, uint256 _id) external onlyOwner {
    require(_addr != address(0), "_addr can't be zero address");
    granted[_addr] = _id;
    emit AccessGranted(_addr, _id);
  }

  function removeAccess(address _addr) external onlyOwner {
    uint256 previousId = granted[_addr];
    granted[_addr] = 0;
    emit AccessRemoved(_addr, previousId);
  }

  function deposit(address _addr, uint256 _amount) external accessAllowed {
    require(
      token.escrowFrom(_addr, _amount) == true,
      "Transfer to the escrow account failed"
    );
    escrowedBalancesOfService[granted[msg.sender]][
      _addr
    ] = escrowedBalancesOfService[granted[msg.sender]][_addr].add(_amount);
    escrowedOfService[granted[msg.sender]] = escrowedOfService[
      granted[msg.sender]
    ].add(_amount);
    emit TokenEscrowDeposit(msg.sender, _addr, _amount);
  }

  function moveEscrowShadow(
    address _from,
    address _to,
    uint256 _amount
  ) external accessAllowed {
    require(_from != address(0), "_from can't be zero address");
    require(_to != address(0), "_to can't be zero address");
    escrowedBalancesOfService[granted[msg.sender]][
      _from
    ] = escrowedBalancesOfService[granted[msg.sender]][_from].sub(_amount);
    escrowedBalancesOfService[granted[msg.sender]][
      _to
    ] = escrowedBalancesOfService[granted[msg.sender]][_to].add(_amount);
    emit EscrowMoved(_to, _from, _amount);
  }

  function withdraw(
    address _to,
    uint256 _amount,
    uint256 _fee
  ) external accessAllowed {
    require(
      escrowedBalancesOfService[granted[msg.sender]][_to] >= _amount &&
        token.escrowReturn(_to, _amount.sub(_fee), _fee) == true,
      "Return from the escrow account failed"
    );
    escrowedOfService[granted[msg.sender]] = escrowedOfService[
      granted[msg.sender]
    ].sub(_amount);
    escrowedBalancesOfService[granted[msg.sender]][
      _to
    ] = escrowedBalancesOfService[granted[msg.sender]][_to].sub(_amount);
    emit TokenEscrowWithdraw(address(this), _to, _amount, _fee);
  }

  function escrowedBalanceOf(uint256 _id, address _address)
    external
    view
    returns (uint256)
  {
    return escrowedBalancesOfService[_id][_address];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @dev a token contract implementing this interface can interact with the XFUN Escrow contract
 */
interface IEscrowCapable {
  /**
   * @notice Lets owner add the escrow address
   * @param _escrow address of escrow
   */
  function allowEscrow(address _escrow) external;

  /**
   * @notice Lets owner remove the escrow address
   * @param _escrow address of escrow
   */
  function removeEscrow(address _escrow) external;

  /**
   * @notice Lets user enable the escrow address
   * @param _escrow address of escrow
   */
  function enableEscrow(address _escrow) external;

  /**
   * @notice Lets user disable the escrow address
   * @param _escrow address of escrow
   */
  function disableEscrow(address _escrow) external;

  /**
   * @notice the calling escrow contract transfers tokens from the user account into an escrow account
   * @param _from Sender address for Escrow
   * @param _value Amount to store in Escrow
   */
  function escrowFrom(address _from, uint256 _value) external returns (bool);

  /**
   * @notice The calling escrow contract returns tokens back to the user
   * @param _to Receiver address to get the value from Escrow
   * @param _value Return Amount
   * @param _fee Escrow Fee Amount
   */
  function escrowReturn(
    address _to,
    uint256 _value,
    uint256 _fee
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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