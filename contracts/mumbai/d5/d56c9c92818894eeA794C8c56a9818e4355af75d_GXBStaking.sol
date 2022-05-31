pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct StakingConfiguration {
    uint256 daysInPeriod;
    uint256 period;
    uint256 percentage;
    bool active;
}

struct AddressStakingInfo {
    uint256 stakingAmount;
    uint256 start;
    uint256 end;
    uint256 period;
    uint256 daysInPeriod;
    uint256 percentage;
    uint256 earned;
    uint256 lastClaimTimestamp;
    bool active;
}

contract GXBStaking is Ownable {
    using SafeERC20 for IERC20;

    // constants for timestamp calculation
    uint256 private constant HOURS_IN_DAY = 24;
    uint256 private constant MINUTES_IN_HOUR = 60;
    uint256 private constant SECONDS_IN_MINUTE = 60;
    uint256 public constant ERC20_Decimals = 18;

    // address of GBX ERC20 token
    address private immutable GBX_TOKEN;

    // staking addresses with it's configurations
    mapping(address => AddressStakingInfo) public stakeBalances;
    address[] private stakeAddresses;

    // possible staking configurations
    StakingConfiguration[] private stakingConfigurations;

    constructor(address gbxToken) {
        GBX_TOKEN = gbxToken;

        uint256 three_month_unix = 90 * HOURS_IN_DAY * MINUTES_IN_HOUR * SECONDS_IN_MINUTE; // 90 days = 3 month
        uint256 six_month_unix = 180 * HOURS_IN_DAY * MINUTES_IN_HOUR * SECONDS_IN_MINUTE; // 180 days = 6 month
        uint256 year_unix = 360 * HOURS_IN_DAY * MINUTES_IN_HOUR * SECONDS_IN_MINUTE; // 360 days = 12 month

        stakingConfigurations.push(StakingConfiguration(90, three_month_unix, 10, true)); // 3 month for 10%
        stakingConfigurations.push(StakingConfiguration(180, six_month_unix, 20, true)); // 6 month for 20%
        stakingConfigurations.push(StakingConfiguration(360, year_unix, 40, true)); // 12 month for 40%
    }

    /**
        Inserts or updates staking configuration by days period.
        If days period exists - updates percentages
        Otherwise creates new staking configuration
     */
    function updateStakingConfiguration(uint256 daysInPeriod, uint256 percentage) public onlyOwner {
        uint256 period = daysInPeriod * HOURS_IN_DAY * MINUTES_IN_HOUR * SECONDS_IN_MINUTE;

        for(uint i = 0; i < stakingConfigurations.length; i++) {
            if(stakingConfigurations[i].daysInPeriod == daysInPeriod) {
                stakingConfigurations[i].percentage = percentage;
                return;
            }
        }

        stakingConfigurations.push(StakingConfiguration(daysInPeriod, period, percentage, true));
    }

    /**
        Disables active staking configuration
     */
    function disableStakingConfiguration(uint256 stakingOption) public onlyOwner {
        require(stakingConfigurations[stakingOption].active, "GBXStaking: wrong staking option specified.");
        stakingConfigurations[stakingOption].active = false;
    }

    /**
        Stakes specified amount for sender wallet with selected staking option
        Requires:
        - unique address to stake
        - amount for staking more than zero
        - existing stakingOption

        Specified amount sents to contract address
     */
    function stake(uint256 amount, uint256 stakingOption) public {
        require(!stakeBalances[msg.sender].active, "GBXStaking: an address already participating in staking.");
        require(amount > 0, "GBXStaking: specified staking amount should be more than 0.");
        require(stakingConfigurations.length - 1 >= stakingOption, "GBXStaking: wrong staking option specified.");
        require(stakingConfigurations[stakingOption].active, "GBXStaking: staking option is not active.");

        IERC20(GBX_TOKEN).safeTransferFrom(msg.sender, address(this), amount);
        
        StakingConfiguration memory selectedStakingOption = stakingConfigurations[stakingOption];
        uint256 start = getCurrentTime();
        uint256 end = start + selectedStakingOption.period;

        stakeBalances[msg.sender] = AddressStakingInfo(amount, start, end, selectedStakingOption.period, selectedStakingOption.daysInPeriod, selectedStakingOption.percentage, 0, start, true);
        stakeAddresses.push(msg.sender);
    }

    /**
        Unstakes specified amount for sender wallet 
        Requires:
        - address that stakes anything
        - staking period ends

        Deletes wallet from stakers addresses and transfers tokens from contract address to user wallet address
     */
    function unstake() public {
        require(stakeBalances[msg.sender].active, "GBXStaking: an address not participating in staking.");
        require(getCurrentTime() >= stakeBalances[msg.sender].end, "GBXStaking: staking period for specified address not ended.");

        IERC20(GBX_TOKEN).safeTransfer(msg.sender, stakeBalances[msg.sender].stakingAmount);
        delete stakeBalances[msg.sender];
    }

    /**
        When staking period ends it's possible to restake staked amount with specified staking configuration
        Requires:
        - address that stakes anything
        - staking period ends
        - existing staking configuration

        Overrides staking configurations for specific wallet address.
        Tokens can't be unstaked if restake started.
     */
    function restake(uint256 stakingOption) public {
        require(stakeBalances[msg.sender].active, "GBXStaking: an address not participating in staking.");
        require(getCurrentTime() >= stakeBalances[msg.sender].end, "GBXStaking: staking period for specified address not ended.");
        require(stakingConfigurations.length - 1 >= stakingOption, "GBXStaking: wrong staking option specified.");
        require(stakingConfigurations[stakingOption].active, "GBXStaking: staking option is not active.");

        StakingConfiguration memory selectedStakingOption = stakingConfigurations[stakingOption];
        uint256 start = getCurrentTime();
        uint256 end = start + selectedStakingOption.period;

        stakeBalances[msg.sender].start = start;
        stakeBalances[msg.sender].end = end;
        stakeBalances[msg.sender].period = selectedStakingOption.period;
        stakeBalances[msg.sender].daysInPeriod = selectedStakingOption.daysInPeriod;
        stakeBalances[msg.sender].percentage = selectedStakingOption.percentage;
        stakeBalances[msg.sender].lastClaimTimestamp = start;
        stakeBalances[msg.sender].earned = 0;
    }

    /**
        Claims reward for sender wallet if available
        Requires:
        - address that stakes anything
        - staking period not yet ended
        - reward amount more then zero
     */
    function claimReward() public {
        require(stakeBalances[msg.sender].active, "GBXStaking: an address not participating in staking.");
        require(getCurrentTime() < stakeBalances[msg.sender].end, "GBXStaking: staking period ended.");
     
        uint256 rewardAmount = calculateReward();
        require(rewardAmount > 0, "GBXStaking: rewards are not available at the moment.");

        IERC20(GBX_TOKEN).safeTransfer(msg.sender, rewardAmount);
        stakeBalances[msg.sender].earned += rewardAmount;
        stakeBalances[msg.sender].lastClaimTimestamp = getCurrentTime();
    }

    /**
        Gets list of available staking configurations
     */
    function getStakingConfigurations() public view returns(StakingConfiguration[] memory){
        return stakingConfigurations;
    }

    /**
        Calculates available rewards for specific address
        Requires:
        - address that stakes anything
        - staking period not yet ended
     */
    function calculateReward() public view returns(uint256) {
        require(stakeBalances[msg.sender].active, "GBXStaking: an address not participating in staking.");
        require(getCurrentTime() < stakeBalances[msg.sender].end, "GBXStaking: staking period ended.");

        uint256 timeFromLastClaim = getCurrentTime() - stakeBalances[msg.sender].lastClaimTimestamp;
        uint256 daysAfterLastClaim = timeFromLastClaim / (HOURS_IN_DAY * MINUTES_IN_HOUR * SECONDS_IN_MINUTE);

        uint256 stakedPerWallet = stakeBalances[msg.sender].stakingAmount;
        uint256 stakingDays = stakeBalances[msg.sender].daysInPeriod;
        uint256 percentage = stakeBalances[msg.sender].percentage;

        return daysAfterLastClaim * getDailyEarnings(stakedPerWallet, stakingDays, percentage);
    }

    /**
        Returns amount of addresses in staking
     */
    function getStakersLength() view public returns(uint256) {
        return stakeAddresses.length;
    }

    /**
        Retuns amount of tokens in staking pool
     */
    function stakedAmount() view public returns(uint256) {
        uint256 staked = 0;

        for(uint256 i = 0; i < stakeAddresses.length; i++) {
            address currentAddress = stakeAddresses[i];
            staked += stakeBalances[currentAddress].stakingAmount;
        }

        return staked;
    }

    /**
        Estimates how much tokens can be taken as a reward for specific user wallet address
        Requires:
        - address that stakes anything
        - staking period not yet ended
     */
    function estimatedDailyEarnings(uint256 stakedPerWallet, uint256 stakingOption) view public returns(uint256) {
        StakingConfiguration memory configuration = stakingConfigurations[stakingOption];

        return getDailyEarnings(stakedPerWallet, configuration.daysInPeriod, configuration.percentage);
    }

    function getDailyEarnings(uint256 stakedPerWallet, uint256 stakingDays, uint256 percentage) pure internal returns(uint256) {
        uint256 totalReceiveForPeriod = (stakedPerWallet * percentage) / 100;
        return totalReceiveForPeriod / stakingDays;
    }

    function getCurrentTime()
        internal
        virtual
        view
        returns(uint256) {
        return block.timestamp;
    }
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