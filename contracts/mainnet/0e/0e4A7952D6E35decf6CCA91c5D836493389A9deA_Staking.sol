/**
 *Submitted for verification at polygonscan.com on 2022-06-15
*/

// File: StakingStructs.sol

pragma solidity ^0.8.0;

library StakingStructs {

	struct Reward {
	    address tokenAddress;
	    uint256 amount;
	}

	struct RandomBonus {
	    address tokenAddress;
	    uint256 min;
		uint256 max;
	}

	struct StakeInfo {
		bool active; 			// user in Staking or not
		uint256 cellId; 		// cellID of last staking
		uint256 endTimestamp;	// when staking ends
		uint256 bonusChance;	//percent
		Reward[] rewards;		// rewards to pay
		RandomBonus[] bonuses;
		string regionName;
		string monsterName;
		string monsterImageUrl;
	}

	struct CellInfo {
		bool active;
		uint256 stakeDuration;
		uint256 stakePrice;
		uint256 bonusChance;	//percent
		Reward[] rewards;
		RandomBonus[] bonuses;
		string regionName;
		string monsterName;
		string monsterImageUrl;
	}

}
// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: Cells.sol

pragma solidity ^0.8.0;




contract Cells is Ownable {

	using Counters for Counters.Counter;
	Counters.Counter private _cellIds;

	mapping (uint256 => StakingStructs.CellInfo) internal cellInfo;
	uint256 public activeCellsCount;


	function getMaxCellId() public view returns(uint256){
		return _cellIds.current();
	}


	function getCellInfo(uint256 _cellId) public view returns(StakingStructs.CellInfo memory){
		return cellInfo[_cellId];
	}


	function saveCellPrice(uint256 _cellId, uint256 _stakePrice) external onlyOwner() {
		require(_cellId>0, 'CellId should be > 0');
		require(_cellId<=getMaxCellId(), 'CellId should <= maxId');
		cellInfo[_cellId].stakePrice = _stakePrice;
	}


	function saveCellBonusChance(uint256 _cellId, uint256 _bonusChance) external onlyOwner() {
		require(_cellId>0, 'CellId should be > 0');
		require(_cellId<=getMaxCellId(), 'CellId should <= maxId');
		require(_bonusChance<=100, 'Bonus chance should be <= 100%');
		cellInfo[_cellId].bonusChance = _bonusChance;
	}


	function saveCellDuration(uint256 _cellId, uint256 _duration) external onlyOwner() {
		require(_cellId>0, 'CellId should be > 0');
		require(_cellId<=getMaxCellId(), 'CellId should <= maxId');
		cellInfo[_cellId].stakeDuration = _duration;
	}


	function saveCellRewards(uint256 _cellId, StakingStructs.Reward[] memory _rewards) external onlyOwner() {
		delete cellInfo[_cellId].rewards;
		uint256 rewardsLength = _rewards.length;
		StakingStructs.Reward memory oneReward;
		for (uint256 rewardIndex=0; rewardIndex<rewardsLength; rewardIndex++){
			oneReward.tokenAddress = _rewards[rewardIndex].tokenAddress;
			oneReward.amount = _rewards[rewardIndex].amount;
			cellInfo[_cellId].rewards.push(oneReward);
		}
	}


	function saveCellRandomBonuses(uint256 _cellId, StakingStructs.RandomBonus[] memory _bonuses) external onlyOwner() {
		delete cellInfo[_cellId].bonuses;
		StakingStructs.RandomBonus memory oneBonus;
		for (uint256 bonusIndex=0; bonusIndex<_bonuses.length; bonusIndex++){
			oneBonus.tokenAddress = _bonuses[bonusIndex].tokenAddress;
			oneBonus.min = _bonuses[bonusIndex].min;
			oneBonus.max = _bonuses[bonusIndex].max;
			cellInfo[_cellId].bonuses.push(oneBonus);
		}
	}


	function saveMonsterImageUrl(uint256 _cellId, string memory _monsterImageUrl) external onlyOwner() {
		require(_cellId>0, 'CellId should be > 0');
		require(_cellId<=getMaxCellId(), 'CellId should <= maxId');
		cellInfo[_cellId].monsterImageUrl = _monsterImageUrl;
	}


	function saveMonsterName(uint256 _cellId, string memory _monsterName) external onlyOwner() {
		require(_cellId>0, 'CellId should be > 0');
		require(_cellId<=getMaxCellId(), 'CellId should <= maxId');
		cellInfo[_cellId].monsterName = _monsterName;
	}


	function saveRegionName(uint256 _cellId, string memory _regionName) external onlyOwner() {
		require(_cellId>0, 'CellId should be > 0');
		require(_cellId<=getMaxCellId(), 'CellId should <= maxId');
		cellInfo[_cellId].regionName = _regionName;
	}


	function addCell(uint256 _duration, uint256 _stakePrice, uint256 _bonusChance, StakingStructs.Reward[] memory _rewards, StakingStructs.RandomBonus[] memory _bonuses, string memory _regionName, string memory _monsterName, string memory _monsterImageUrl) external onlyOwner() {
		_cellIds.increment();
		uint256 id = _cellIds.current();
		cellInfo[id].active = true;
		cellInfo[id].stakeDuration = _duration;
		cellInfo[id].stakePrice = _stakePrice;
		cellInfo[id].bonusChance = _bonusChance;
		cellInfo[id].regionName = _regionName;
		cellInfo[id].monsterName = _monsterName;
		cellInfo[id].monsterImageUrl = _monsterImageUrl;

		StakingStructs.Reward memory oneReward;
		for (uint256 rewardIndex=0; rewardIndex<_rewards.length; rewardIndex++){
			oneReward.tokenAddress = _rewards[rewardIndex].tokenAddress;
			oneReward.amount = _rewards[rewardIndex].amount;
			cellInfo[id].rewards.push(oneReward);
		}

		StakingStructs.RandomBonus memory oneBonus;
		for (uint256 bonusIndex=0; bonusIndex<_bonuses.length; bonusIndex++){
			oneBonus.tokenAddress = _bonuses[bonusIndex].tokenAddress;
			oneBonus.min = _bonuses[bonusIndex].min;
			oneBonus.max = _bonuses[bonusIndex].max;
			cellInfo[id].bonuses.push(oneBonus);
		}
		activeCellsCount++;
	}


	function enableCell(uint256 _cellId) external onlyOwner() {
		require(!cellInfo[_cellId].active, 'already active');
		cellInfo[_cellId].active = true;
		activeCellsCount++;
	}


	function disableCell(uint256 _cellId) external onlyOwner() {
		require(cellInfo[_cellId].active, 'already disabled');
		cellInfo[_cellId].active = false;
		activeCellsCount--;
	}
}
// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: Staking.sol

pragma solidity 0.8.11;








contract Staking is Ownable, Cells, Pausable, ReentrancyGuard {
	using SafeERC20 for IERC20;

	mapping(address => StakingStructs.StakeInfo) public stakeInfo;
	address[] private usersList;
	mapping(address => bool) internal usersExist;
	address public stakeTokenAdminAddress;	// owner of resource's contracts
	IERC20 public stakeToken;
	uint256 public activeStakesCount;
	mapping(address=>uint256) public statRewards;

	event Stake(address indexed user, uint256 cellId, uint256 returnTimestamp);
	event Reward(address indexed user, address indexed tokenAddress, uint256 tokenAmount);

	constructor (address _stakeTokenAddress, address _stakeTokenAdminAddress){
		stakeToken = IERC20(_stakeTokenAddress);
		stakeTokenAdminAddress = _stakeTokenAdminAddress;
	}

	function myStakeInfo() public view returns(StakingStructs.StakeInfo memory){
		return stakeInfo[msg.sender];
	}

	function pause() external onlyOwner() {
		_pause();
	}

	function unpause() external onlyOwner() {
		_unpause();
	}

	function stake(uint256 _cellId) external whenNotPaused nonReentrant {
		StakingStructs.CellInfo memory cellInfo = getCellInfo(_cellId);
		require(stakeInfo[msg.sender].active == false, 'You are already in staking');
		require(cellInfo.active == true, 'You cannot stake to disabled cell');
		stakeInfo[msg.sender].active = true;
		stakeInfo[msg.sender].cellId = _cellId;
		stakeInfo[msg.sender].bonusChance = cellInfo.bonusChance;
		stakeInfo[msg.sender].endTimestamp = block.timestamp + cellInfo.stakeDuration;
		stakeInfo[msg.sender].regionName = cellInfo.regionName;
		stakeInfo[msg.sender].monsterName = cellInfo.monsterName;
		stakeInfo[msg.sender].monsterImageUrl = cellInfo.monsterImageUrl;

		delete stakeInfo[msg.sender].rewards;
		StakingStructs.Reward memory oneReward;
		for (uint256 rewardInd=0; rewardInd<cellInfo.rewards.length; rewardInd++){
			oneReward.tokenAddress = cellInfo.rewards[rewardInd].tokenAddress;
			oneReward.amount = cellInfo.rewards[rewardInd].amount;
			stakeInfo[msg.sender].rewards.push(oneReward);
		}

		delete stakeInfo[msg.sender].bonuses;
		StakingStructs.RandomBonus memory oneBonus;
		for (uint256 bonusInd=0; bonusInd<cellInfo.bonuses.length; bonusInd++){
			oneBonus.tokenAddress = cellInfo.bonuses[bonusInd].tokenAddress;
			oneBonus.min = cellInfo.bonuses[bonusInd].min;
			oneBonus.max = cellInfo.bonuses[bonusInd].max;
			stakeInfo[msg.sender].bonuses.push(oneBonus);
		}

		if (!usersExist[msg.sender]){
			usersList.push(msg.sender);
		}
		usersExist[msg.sender] = true;
		activeStakesCount++;
		stakeToken.safeTransferFrom(msg.sender, stakeTokenAdminAddress, cellInfo.stakePrice);
		emit Stake(msg.sender, _cellId, stakeInfo[msg.sender].endTimestamp);
	}

	function withdraw() external whenNotPaused nonReentrant {
		require(stakeInfo[msg.sender].active == true, 'You haven`t staked anything');
		require(stakeInfo[msg.sender].endTimestamp < block.timestamp, 'Staking time not ended');
		stakeInfo[msg.sender].active = false;

		for (uint256 rewardInd=0; rewardInd<stakeInfo[msg.sender].rewards.length; rewardInd++){
			address rewardAddress = stakeInfo[msg.sender].rewards[rewardInd].tokenAddress;
			uint256 rewardAmount = stakeInfo[msg.sender].rewards[rewardInd].amount;
			IERC20 rewardInstance = IERC20(rewardAddress);
			rewardInstance.safeTransferFrom(stakeTokenAdminAddress, msg.sender, rewardAmount);
			statRewards[rewardAddress] += rewardAmount;
			emit Reward(msg.sender, rewardAddress, rewardAmount);
		}

		bool hasBonus = checkFortune(stakeInfo[msg.sender].bonusChance);

		for (uint256 bonusInd=0; bonusInd<stakeInfo[msg.sender].bonuses.length; bonusInd++){
			uint256 minAmount = stakeInfo[msg.sender].bonuses[bonusInd].min;
			uint256 maxAmount = stakeInfo[msg.sender].bonuses[bonusInd].max;
			uint256 bonusAmount = random(minAmount, maxAmount);
			stakeInfo[msg.sender].bonuses[bonusInd].max = bonusAmount;
			if (hasBonus){
				address bonusAddress = stakeInfo[msg.sender].bonuses[bonusInd].tokenAddress;
				IERC20 bonusInstance = IERC20(bonusAddress);
				bonusInstance.safeTransferFrom(stakeTokenAdminAddress, msg.sender, bonusAmount);
				statRewards[bonusAddress] += bonusAmount;
				emit Reward(msg.sender, bonusAddress, bonusAmount);
			}
		}

		activeStakesCount--;
	}

	function editStakeToken(address _newStakeTokenAddress) external onlyOwner() {
		stakeToken = IERC20(_newStakeTokenAddress);
	}

	function editStakeTokenAdmin(address _newStakeTokenAdminAddress) external onlyOwner() {
		stakeTokenAdminAddress =_newStakeTokenAdminAddress;
	}

	function random(uint256 _min, uint256 _max)	public view	returns(uint256) {
		uint256 diff = _max - _min;
		uint256 seed = uint256(keccak256(abi.encodePacked(
			block.timestamp + block.difficulty +
			((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
			block.gaslimit +
			((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
			block.number
		))) % diff;
		return seed + _min;
	}

	function checkFortune(uint256 chancePercent) public view returns(bool){
		uint256 num = random(0,100);
		if (num <= chancePercent){
			return true;
		}
		return false;
	}

	function getUsers() external view returns (address[] memory){
		return usersList;
	}

	function getTime() external view returns (uint256) {
		return block.timestamp;
	}

}