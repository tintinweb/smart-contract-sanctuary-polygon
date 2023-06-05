// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
pragma solidity ^0.8.13;

import "./interfaces/IHypercert.sol";
import "./interfaces/IFundingPool.sol";
import "./interfaces/IERC20Decimal.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract QFPool is Ownable {
	IFundingPool public fundingPool;
	IHypercert public hypercert;
	uint256 public lastStartingId;
	uint256 public timeFrame = 2592000; // one month availability for grant to receive QF.
	uint256 private constant precision = 10 ** 4; // precision for double decimals percentage.

	mapping(address => uint256) public thisBalances;
	mapping(uint256 => mapping(address => uint256)) public allotmentsByIdToken;

	event NewBalance(uint256 _thisBalances, address _token);
	event FundsWithdrawed(uint256 _grantId, uint256 _amount, address _token, address _grantCreator);
	event NewTimeFrame(uint256 _timeFrame);

	error TransferFailed();
	error GrantNotExist();

	constructor(address _fundingPool, address _hypercert) {
		fundingPool = IFundingPool(_fundingPool);
		hypercert = IHypercert(_hypercert);
	}

	/**
	 * @notice Distribute funds to eligible grants according to number of contributors over
	 * total contributors within the eligible period.
	 * Eligible means grants ended within timeFrame.
	 */
	function distributeFunds(address _token) public {
		require(fundingPool.allowedTokens(_token) == true, "Token is not supported");
		withdrawFromFundingPool(_token);
		uint256 latestUnusedId = hypercert.latestUnusedId();
		uint256 totalParticipants = _getTotalParticipants(latestUnusedId);
		uint256 i = lastStartingId;
		uint256 totalToDistribute = thisBalances[_token];
		while (i < latestUnusedId) {
			unchecked {
				uint256 allotment = fundingPool.donatedAddressNumber(i) * precision / totalParticipants;
				uint256 amount = allotment * totalToDistribute / precision;
				allotmentsByIdToken[i][_token] += amount;
				i++;
			}
		}
		thisBalances[_token] = 0;
	}

	function withdrawFromFundingPool(address _token) public {
		if (fundingPool.quadraticFundingPoolFunds(_token) > 0) {
			thisBalances[_token] += fundingPool.qFWithdraw(_token);
			emit NewBalance(thisBalances[_token], _token);
		}
	}

	/// @notice check if grant ended and still within eligible timeframe.
	function _getTotalParticipants(uint256 latestUnusedId) internal returns (uint256 totalParticipants) {
		uint256 i = lastStartingId;
		while (i < latestUnusedId) {
			uint256 endTime = hypercert.grantEndTime(i);
			if (block.timestamp < endTime + timeFrame) break;
			unchecked {
				i++;
			}
		}
		lastStartingId = i;
		while (i < latestUnusedId) {
			totalParticipants += fundingPool.donatedAddressNumber(i);
			unchecked {
				i++;
			}
		}
	}

	/// @notice Withdraw allocated funds for grant creator.
    function withdrawFunds(uint256 _grantId, address _token) external {
        if (_grantId >= hypercert.latestUnusedId()) revert GrantNotExist();
		require(allotmentsByIdToken[_grantId][_token] > 0, "No Balance to withdraw");
		require(hypercert.grantEnded(_grantId), "Round not ended");
		if (thisBalances[_token] != 0) distributeFunds(_token);

		address grantCreator = hypercert.grantOwner(_grantId);
        uint256 amount = allotmentsByIdToken[_grantId][_token];
		allotmentsByIdToken[_grantId][_token] = 0;
        if (!IERC20Decimal(_token).transfer(grantCreator, amount)) revert TransferFailed();

        emit FundsWithdrawed(_grantId, amount, _token, grantCreator);
    }

    /// =====================================================================================================
    /// @dev Owner functions
    function setHypercertAddress(IHypercert _hypercert) external onlyOwner {
        hypercert = _hypercert;
    }

    function setFundingPoolAddress(IFundingPool _fundingPool) external onlyOwner {
        fundingPool = _fundingPool;
    }

	function setTimeFrame(uint256 _timeFrame) external onlyOwner {
		timeFrame = _timeFrame;
		emit NewTimeFrame(timeFrame);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Decimal is IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IHypercert.sol";

struct FundInfo {
	uint256 grantId;
	uint256 depositFund;
	string tokenSymbol;
}

interface IFundingPool {

    function depositFunds(
        uint256[] calldata _grantIds,
        uint256[] calldata  _depositFunds,
        uint256 _cumulativeTotal,
        address _token
    ) external;

	function withdrawFunds(uint256 _grantId, address _token) external;

	function fundInfoByAddress(address _addr) external view returns (FundInfo[] memory _fundInfo);

	function qFWithdraw(address _token) external returns (uint256 amount);

	function treasuryWithdraw(address _token) external returns (uint256 amount) ;

	function allowToken(address _token, bool _bool) external;

    function setHypercertAddress(IHypercert _hypercertAddress) external;

    function setQFAddress(address _qFAddress) external;

    function setTreasuryAddress(address _treasuryAddress) external;

    function setQFPoolShare(uint256 _percent) external;

    function setTreasuryPoolShare(uint256 _percent) external;

	function uri(uint256 tokenId) external view returns (string memory);

	function donatedAddressNumber(uint256 _id) external view returns (uint256 numbers);

	function quadraticFundingPoolFunds(address _addr) external view returns (uint256 amounts);

	function allowedTokens(address _addr) external view returns (bool _bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

struct GrantInfo {
	string grantName;
	uint256 grantEndTime;
	address grantOwner;
	string grantURI;
}

interface IHypercert {

    function createGrant(
        string calldata _grantName,
        uint256 _grantEndTime,
        string calldata _tokenURI
    ) external returns (uint256 _grantId);

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function grantOwner(uint256 _grandId) external view returns (address _creator);

    function grantEnded(uint256 _grandId) external view returns (bool _ended);

    function grantsCreatedByAddress(address _addr) external view returns (uint256[] memory _grants);

    function setPool(address _poolAddress) external;

    function setURI(uint256 _tokenId, string calldata _tokenURI) external;

	function latestUnusedId() external view returns (uint256 _id);

	function grantEndTime(uint256 _grandId) external view returns (uint256 _endTime);
}