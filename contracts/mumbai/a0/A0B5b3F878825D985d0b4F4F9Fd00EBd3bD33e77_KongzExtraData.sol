pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "IERC20.sol";
import "SafeMath.sol";
import "Ownable.sol";

/*
 *     ,_,
 *    (',')
 *    {/"\}
 *    -"-"-
 */

contract KongzExtraData is Ownable {
	using SafeMath for uint256;

	mapping(address => bool) public approvedContracts;
	mapping(address => mapping(bytes32 => bool)) public approvecContractToStat;
	mapping(address => mapping(bytes32 => bool)) public approvecContractToItem;
	mapping(bytes32 => bool) internal enabledStats;
	mapping(bytes32 => bool) internal enabledItems;
	mapping(uint256 => mapping(bytes32 => uint256)) public stats;
	mapping(address => mapping(bytes32 => uint256)) public items;

	event StatIncreased(bytes32 indexed stat, uint256 indexed tokenId, uint256 amount);
	event StatDecreased(bytes32 indexed stat, uint256 indexed tokenId, uint256 amount);

	event ItemIncreased(bytes32 indexed item, address indexed user, uint256 amount);
	event ItemDecreased(bytes32 indexed item, address indexed user, uint256 amount);

	function updateStatContracts(address[] calldata _contracts, string[] calldata _statIds, bool[] calldata _vals) external onlyOwner {
		require(_contracts.length == _vals.length, "!len");

		for (uint256 i = 0 ; i < _contracts.length; i++) {
			approvecContractToStat[_contracts[i]][keccak256(abi.encodePacked(_statIds[i]))] = _vals[i];
		}
	}

	function updateItemContracts(address[] calldata _contracts, string[] calldata _itemIds, bool[] calldata _vals) external onlyOwner {
		require(_contracts.length == _vals.length, "!len");

		for (uint256 i = 0 ; i < _contracts.length; i++) {
			approvecContractToItem[_contracts[i]][keccak256(abi.encodePacked(_itemIds[i]))] = _vals[i];
		}
	}

	function adminUpdateStats(string[] calldata _stats, bool[] calldata _vals) external onlyOwner {
		require(_stats.length == _vals.length, "!len");

		for (uint256 i = 0 ; i < _stats.length; i++) {
			enabledStats[keccak256(abi.encodePacked(_stats[i]))] = _vals[i];
		}
	}

	function adminUpdateItems(string[] calldata _items, bool[] calldata _vals) external onlyOwner {
		require(_items.length == _vals.length, "!len");

		for (uint256 i = 0 ; i < _items.length; i++) {
			enabledItems[keccak256(abi.encodePacked(_items[i]))] = _vals[i];
		}
	}

	function incStats(string calldata _stat, uint256 _id, uint256 _amount) external {
		bytes32 statId = keccak256(abi.encodePacked(_stat));
		require(approvecContractToStat[msg.sender][statId] || msg.sender == owner(), "!stat");
		require(enabledStats[statId]);
		stats[_id][statId] = stats[_id][statId].add(_amount);
		emit StatIncreased(statId, _id, _amount);
	}

	function decStats(string calldata _stat, uint256 _id, uint256 _amount) external {
		bytes32 statId = keccak256(abi.encodePacked(_stat));
		require(approvecContractToStat[msg.sender][statId] || msg.sender == owner(), "!stat");
		require(enabledStats[statId]);
		stats[_id][statId] = stats[_id][statId].sub(_amount);
		emit StatDecreased(statId, _id, _amount);
	}

	function incStats(bytes32 _statId, uint256 _id, uint256 _amount) external {
		require(approvecContractToStat[msg.sender][_statId] || msg.sender == owner(), "!stat");
		require(enabledStats[_statId]);
		stats[_id][_statId] = stats[_id][_statId].add(_amount);
		emit StatIncreased(_statId, _id, _amount);
	}

	function decStats(bytes32 _statId, uint256 _id, uint256 _amount) external {
		require(approvecContractToStat[msg.sender][_statId] || msg.sender == owner(), "!stat");
		require(enabledStats[_statId]);
		stats[_id][_statId] = stats[_id][_statId].sub(_amount);
		emit StatDecreased(_statId, _id, _amount);
	}

	function incItem(string calldata _item, address _user, uint256 _amount) external {
		bytes32 itemId = keccak256(abi.encodePacked(_item));
		require(approvecContractToItem[msg.sender][itemId] || msg.sender == owner(), "!item");
		require(enabledItems[itemId]);
		items[_user][itemId] = items[_user][itemId].add(_amount);
		emit ItemIncreased(itemId, _user, _amount);
	}

	function decItem(string calldata _item, address _user, uint256 _amount) external {
		bytes32 itemId = keccak256(abi.encodePacked(_item));
		require(approvecContractToItem[msg.sender][itemId] || msg.sender == owner(), "!item");
		require(enabledItems[itemId]);
		items[_user][itemId] = items[_user][itemId].sub(_amount);
		emit ItemDecreased(itemId, _user, _amount);
	}

	function incItem(bytes32 _itemId, address _user, uint256 _amount) external {
		require(approvecContractToItem[msg.sender][_itemId] || msg.sender == owner(), "!item");
		require(enabledItems[_itemId]);
		items[_user][_itemId] = items[_user][_itemId].add(_amount);
		emit ItemIncreased(_itemId, _user, _amount);
	}

	function decItem(bytes32 _itemId, address _user, uint256 _amount) external {
		require(approvecContractToItem[msg.sender][_itemId] || msg.sender == owner(), "!item");
		require(enabledItems[_itemId]);
		items[_user][_itemId] = items[_user][_itemId].sub(_amount);
		emit ItemDecreased(_itemId, _user, _amount);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
     *
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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "Context.sol";
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
contract Ownable is Context {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}