// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IVesting.sol";

contract Vesting is IVesting, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public token;
    uint256 public start;
    uint256 public claimablePercentIndex;
    uint256 public accumulatedClaimablePercent;
    string public vestingName;

    mapping(address => uint256) public tokenAmounts;
    mapping(address => uint256) public releasedAmount;

    uint256 private constant BP = 1e18;
    UnlockEvent[] private _unlockEvents;
    uint256 private _totalUnlockedPercent;
    address[] private _beneficiaries;
    uint256 private _assigned;
    uint256 private _released;

    /**
     * @param _token The token address.
     * @param _start The TGE timestamp.
     * @param _vestingName The Vesting Schedule name. For instance: Private Round
     */
    constructor(
        IERC20 _token,
        uint256 _start,
        string memory _vestingName
    ) {
        token = _token;
        start = _start;
        vestingName = _vestingName;
    }

    /**
     * @dev Adds the Vesting Schedule Configuration
     * @param percent The Unlock Percent.
     * @param unlockTime The Unlock Time.
     */
    function addUnlockEvents(
        uint256[] memory percent,
        uint256[] memory unlockTime
    ) external override onlyOwner {
        require(
            percent.length == unlockTime.length && percent.length > 0,
            "Invalid params"
        );
        if (_unlockEvents.length == 0) {
            require(start == unlockTime[0], "Unlock time must start from TGE");
        } else {
            require(
                _unlockEvents[_unlockEvents.length - 1].unlockTime <
                    unlockTime[0],
                "Unlock time has to be in order"
            );
        }
        uint256 totalUnlockedPercent = _totalUnlockedPercent;
        for (uint256 i = 0; i < percent.length; i++) {
            if (i > 0) {
                require(
                    unlockTime[i] > unlockTime[i - 1],
                    "Unlock time has to be in order"
                );
            }

            totalUnlockedPercent += percent[i];
            require(totalUnlockedPercent <= 100, "Invalid percent values");

            _addUnlockEvent(percent[i], unlockTime[i]);
        }
        _totalUnlockedPercent = totalUnlockedPercent;
    }

    function _addUnlockEvent(uint256 percent, uint256 unlockTime) private {
        _unlockEvents.push(
            UnlockEvent({percent: percent, unlockTime: unlockTime})
        );
    }

    /**
     * @dev Fetches the Vesting Schedule Configuration
     * @return The Vesting Schedule Configuration
     */
    function getUnlockEvents()
        external
        view
        override
        returns (UnlockEvent[] memory)
    {
        return _unlockEvents;
    }

    /**
     * @dev Adds Beneficiaries addresses and amounts
     */
    function addBeneficiaries(
        address[] memory beneficiaries,
        uint256[] memory amounts
    ) external override onlyOwner {
        require(beneficiaries.length == amounts.length, "Invalid params");

        uint256 newAssigned = 0;
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            _addBeneficiary(beneficiaries[i], amounts[i]);
            newAssigned += amounts[i];
        }

        uint256 balance = token.balanceOf(address(this));
        require(
            balance >= _assigned - _released + newAssigned,
            "Not enough token to cover"
        );
        _assigned += newAssigned;
    }

    function _addBeneficiary(address beneficiary, uint256 tokenAmount) private {
        require(
            beneficiary != address(0),
            "The beneficiary's address cannot be 0"
        );
        require(tokenAmount > 0, "Amount has to be greater than 0");

        if (tokenAmounts[beneficiary] == 0) {
            _beneficiaries.push(beneficiary);
        }

        tokenAmounts[beneficiary] = tokenAmounts[beneficiary] + tokenAmount;
    }

    /**
     * @dev Gets All Beneficiaries Addresses
     * @return All Beneficiaries Addresses
     */
    function getBeneficiaries()
        external
        view
        override
        returns (address[] memory)
    {
        return _beneficiaries;
    }

    /**
     * @dev Claims All available User Tokens
     */
    function claimTokens() external override {
        require(tokenAmounts[msg.sender] > 0, "No tokens to claim");
        require(
            releasedAmount[msg.sender] < tokenAmounts[msg.sender],
            "User already released all available tokens"
        );

        (
            uint256 percent,
            uint256 _accumulatedClaimablePercent,
            uint256 _claimablePercentIndex
        ) = _claimablePercent();
        accumulatedClaimablePercent = _accumulatedClaimablePercent;
        claimablePercentIndex = _claimablePercentIndex;
        uint256 unreleased = _claimableAmount(msg.sender, percent);

        if (unreleased > 0) {
            _released += unreleased;
            token.safeTransfer(msg.sender, unreleased);
            releasedAmount[msg.sender] += unreleased;
            emit Released(msg.sender, unreleased);
        }
    }

    /**
     * withdraw ERC20 tokens in case of accidentally transfer - owner only
     */
    function withdrawAllERC20(IERC20 erc20Token) external override onlyOwner {
        uint256 balance = erc20Token.balanceOf(address(this));

        // only allow withdraw unassigned $CLASH
        if (erc20Token == token) {
            uint256 unreleased = _assigned - _released;
            require(balance > unreleased, "No available tokens");
            erc20Token.transfer(owner(), balance - unreleased);
            return;
        }

        require(balance > 0, "Balance must be greater than 0");
        erc20Token.transfer(owner(), balance);
    }

    /**
     * @dev Calculates the total Claimable Percent according to how many days have passed
     * @notice This function doesn't modify the contract state and it's just called for display purposes
     * @return The total Claimable Percent, accumulated Claimable Percent, claimable Percent Index
     */
    function _claimablePercent()
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 _accumulatedClaimablePercent = accumulatedClaimablePercent;
        uint256 _claimablePercentIndex = claimablePercentIndex;

        // cannot claim before TGE
        if (block.timestamp < start)
            return (0, _accumulatedClaimablePercent, _claimablePercentIndex);

        uint256 claimablePercentForCurentPeriod;

        for (
            uint256 i = _claimablePercentIndex;
            i < _unlockEvents.length;
            i++
        ) {
            //unlockEvents[i].percent = 4 for 4%
            uint256 lockedPeriodPercent = _unlockEvents[i].percent * BP;

            if (block.timestamp > _unlockEvents[i].unlockTime) {
                _accumulatedClaimablePercent += lockedPeriodPercent;
            } else {
                // "i" will always be greater than 0 since unlockEvents[0].unlockTime = start
                uint256 totalDaysForCurrentPeriod = (_unlockEvents[i]
                    .unlockTime - _unlockEvents[i - 1].unlockTime) / 1 days;
                uint256 daysPassedForCurrentPeriod = (block.timestamp -
                    _unlockEvents[i - 1].unlockTime) / 1 days;

                claimablePercentForCurentPeriod +=
                    (lockedPeriodPercent * daysPassedForCurrentPeriod) /
                    totalDaysForCurrentPeriod;

                _claimablePercentIndex = i;
                break;
            }
        }

        uint256 resultPercent = _accumulatedClaimablePercent +
            claimablePercentForCurentPeriod;

        if (resultPercent > 100 * BP) resultPercent = 100 * BP;

        // if 4% then it'll return 4 * BP
        return (
            resultPercent,
            _accumulatedClaimablePercent,
            _claimablePercentIndex
        );
    }

    /**
     * @dev Calculates the total Claimable Percent according to how many days have passed
     * @notice This function doesn't modify the contract state and it's just called for display purposes
     * @return The total Claimable Percent
     */
    function claimablePercent() public view override returns (uint256) {
        (uint256 percent, , ) = _claimablePercent();
        return percent;
    }

    /**
     * @dev Calculates the total Claimable Tokens according to how many days have passed
     * @return The total Claimable Tokens
     */
    function claimableAmount(address beneficiary)
        public
        view
        override
        returns (uint256)
    {
        return _claimableAmount(beneficiary, claimablePercent());
    }

    function _claimableAmount(address beneficiary, uint256 percent)
        private
        view
        returns (uint256)
    {
        return
            (tokenAmounts[beneficiary] * percent) /
            (100 * BP) -
            releasedAmount[beneficiary];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: Unlicense

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
pragma solidity ^0.8.0;

interface IVesting {
    struct UnlockEvent {
        uint256 percent;
        uint256 unlockTime;
    }

    event Released(address beneficiary, uint256 amount);

    function addUnlockEvents(
        uint256[] memory _amount,
        uint256[] memory _unlockTime
    ) external;

    function getUnlockEvents() external view returns (UnlockEvent[] memory);

    function addBeneficiaries(
        address[] memory _beneficiaries,
        uint256[] memory _tokenAmounts
    ) external;

    function getBeneficiaries() external view returns (address[] memory);

    function claimTokens() external;

    function claimablePercent() external view returns (uint256);

    function claimableAmount(address _beneficiary)
        external
        view
        returns (uint256);

    function withdrawAllERC20(IERC20 erc20Token) external;
}

// SPDX-License-Identifier: MIT
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