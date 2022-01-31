/**
 *Submitted for verification at polygonscan.com on 2021-10-17
*/

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol



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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: contracts/MokaTokenSale.sol


pragma solidity ^0.8.7;




contract MokaTokenSale is Ownable {
  using SafeMath for uint256;

  IERC20 mokaTokenContract;
  uint256 public userCount;
  string[] public acceptedStablecoins;
  mapping(address => uint256) public addressUserMapping;
  mapping(string => address) public stablecoinContracts;
  mapping(string => uint8) public stablecoinDecimals;

  /* Price Bands For User Sign Up */
  struct PriceBand {
    uint32 userCount;
    uint16 mokaToken;
    uint8 price;
  }

  PriceBand[8] public tokenDistribution;

  event userJoined(uint256 userNumber, address userAddress);

  constructor(address tokenAddr) {
    userCount = 0;
    mokaTokenContract = IERC20(tokenAddr);

    tokenDistribution[0] = PriceBand(0, 1000, 0);
    tokenDistribution[1] = PriceBand(101, 750, 0);
    tokenDistribution[2] = PriceBand(1001, 500, 10);
    tokenDistribution[3] = PriceBand(10001, 250, 15);
    tokenDistribution[4] = PriceBand(100001, 120, 20);
    tokenDistribution[5] = PriceBand(1000001, 60, 25);
    tokenDistribution[6] = PriceBand(10000001, 30, 30);
    tokenDistribution[7] = PriceBand(100000001, 0, 0);
  }

  function buy(uint256 _amount, string memory _coindId) public {
    require(addressUserMapping[msg.sender] == 0, "Address Already Active");
    uint16 tokensToTransfer;
    uint8 price;

    if (userCount >= tokenDistribution[7].userCount) {
      tokensToTransfer = tokenDistribution[7].mokaToken;
      price = tokenDistribution[7].price;
    } else if (userCount >= tokenDistribution[6].userCount) {
      tokensToTransfer = tokenDistribution[6].mokaToken;
      price = tokenDistribution[6].price;
    } else if (userCount >= tokenDistribution[5].userCount) {
      tokensToTransfer = tokenDistribution[5].mokaToken;
      price = tokenDistribution[5].price;
    } else if (userCount >= tokenDistribution[4].userCount) {
      tokensToTransfer = tokenDistribution[4].mokaToken;
      price = tokenDistribution[4].price;
    } else if (userCount >= tokenDistribution[3].userCount) {
      tokensToTransfer = tokenDistribution[3].mokaToken;
      price = tokenDistribution[3].price;
    } else if (userCount >= tokenDistribution[2].userCount) {
      tokensToTransfer = tokenDistribution[2].mokaToken;
      price = tokenDistribution[2].price;
    } else if (userCount >= tokenDistribution[1].userCount) {
      tokensToTransfer = tokenDistribution[1].mokaToken;
      price = tokenDistribution[1].price;
    } else {
      tokensToTransfer = tokenDistribution[0].mokaToken;
      price = tokenDistribution[0].price;
    }

    if (price > 0) {
      require(_amount >= price, "Token Amount Incorrect");
      require(stablecoinContracts[_coindId] != address(0), "Stablecoin Address Invalid");
      bool successPayment = IERC20(stablecoinContracts[_coindId]).transferFrom(msg.sender, owner(), _amount * uint256(10 ** stablecoinDecimals[_coindId]));
      require(successPayment, "Payment Transfer Failed");
    }

    bool success = mokaTokenContract.transfer(msg.sender, tokensToTransfer * uint256(10 ** 18));
    require(success, "Moka Token Transfer Failed");
    addressUserMapping[msg.sender] = userCount + 1;
    userCount = userCount + 1;
    emit userJoined(userCount, msg.sender);
  }

  function setAllowedStableCoins(string[] memory _coins, address[] memory _contracts, uint8[] memory _decimals) public onlyOwner {
    require(_coins.length == _contracts.length, "Array Lengths Incorrect");

    //clear current stablecoin list
    for (uint i = 0; i < acceptedStablecoins.length; i++) {
      delete stablecoinContracts[acceptedStablecoins[i]];
      delete stablecoinDecimals[acceptedStablecoins[i]];
    }

    //set new stablecoin list
    for (uint i = 0; i < _coins.length; i++) {
      stablecoinContracts[_coins[i]] = _contracts[i];
      stablecoinDecimals[_coins[i]] = _decimals[i];
    }

    acceptedStablecoins = _coins;
  }

  function getAcceptedStablecoins() public view returns (string[] memory) {
    return acceptedStablecoins;
  }

  function getCurrentPriceBand() public view returns (uint16 tokens, uint8 price) {
    if (userCount >= tokenDistribution[7].userCount) {
      tokens = tokenDistribution[7].mokaToken;
      price = tokenDistribution[7].price;
    } else if (userCount >= tokenDistribution[6].userCount) {
      tokens = tokenDistribution[6].mokaToken;
      price = tokenDistribution[6].price;
    } else if (userCount >= tokenDistribution[5].userCount) {
      tokens = tokenDistribution[5].mokaToken;
      price = tokenDistribution[5].price;
    } else if (userCount >= tokenDistribution[4].userCount) {
      tokens = tokenDistribution[4].mokaToken;
      price = tokenDistribution[4].price;
    } else if (userCount >= tokenDistribution[3].userCount) {
      tokens = tokenDistribution[3].mokaToken;
      price = tokenDistribution[3].price;
    } else if (userCount >= tokenDistribution[2].userCount) {
      tokens = tokenDistribution[2].mokaToken;
      price = tokenDistribution[2].price;
    } else if (userCount >= tokenDistribution[1].userCount) {
      tokens = tokenDistribution[1].mokaToken;
      price = tokenDistribution[1].price;
    } else {
      tokens = tokenDistribution[0].mokaToken;
      price = tokenDistribution[0].price;
    } 
  }
}