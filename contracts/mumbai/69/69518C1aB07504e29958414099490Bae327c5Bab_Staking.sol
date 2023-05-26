//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Paysenger staking contract.
 */
contract Staking is Ownable {
    using SafeERC20 for IERC20;

    /**
     * @notice Shows that the user stake some tokens to contract.
     * @param user the address of user.
     * @param amount an amount of tokens which user stakes to contract.
     */
    event Stake(address user, uint256 amount);

    /**
     * @notice Shows that the user unstake some tokens from contract.
     * @param user the address of user.
     * @param amount an amount of tokens which user unstakes from contract.
     */
    event Unstake(address user, uint256 amount);

    /**
     * @notice Shows that the user claim some reward tokens from contract.
     * @param user the address of user.
     * @param amount an amount of reward tokens which user claim from contract.
     */
    event Claim(address user, uint256 amount);

    /**
     * @notice Shows that the staking is locked and new deposits does not accepted.
     * @param sender the address of user, who lock stake.
     * @param status status for stake function.
     */
    event StakingLocked(address sender, bool status);

    /**
     * @notice Shows that stking rules changed.
     * @param epochDuration The duration of epoch.
     * @param rewardPerEpoch The amount of rewards distributed per epoch.
     * @param rewardDistibutionPeriod Period of time per which awards accrue.
     */
    event StakingRuleChanged(uint256 epochDuration, uint256 rewardPerEpoch, uint256 rewardDistibutionPeriod);

    struct Account {
        uint256 amountStake; //the number of tokens that the user has staked
        uint256 missedReward; //the number of reward tokens that the user missed
        uint256 lockedUntil; //timestamp at which staked token unlocked
    }

    struct UserInfo {
        uint256 amountStake; //the number of tokens that the user has staked
        uint256 missedReward; //the number of reward tokens that the user missed
        uint256 lockedUntil; //timestamp at which staked token unlocked
        uint256 availableReward;
    }

    struct ViewData {
        address stakeTokenAddress; //Address of stake and reward token
        address rewardTokenAddress; //Address of stake and reward token
        uint256 rewardPerEpoch; //Amount of reward distributed per epoch
        uint256 epochDuration; //Duration of epoch
        uint256 rewardDistibutionPeriod; //Period of time per which awards accrue
        uint256 lockPeriod; //Period for which tokens of user locked
        uint256 totalAmountStake; //Total amount of staked tokens
    }

    // Status of staking. Is new deposited not accepted?
    bool public stakingLocked;

    uint256 public constant precision = 1e18;

    //Current reward token per stake token
    uint256 private tokenPerStake;

    //The amount of rewards distributed per epoch
    uint256 public rewardPerEpoch;

    //The duration of epoch
    uint256 public epochDuration;

    //The period of time for which the currency is locked
    uint256 public lockPeriod;

    //Address of stake token
    address public stakeTokenAddress;

    //Address of reward token
    address public rewardTokenAddress;

    //Total amount of staked tokens
    uint256 public totalAmountStake;

    // The last timestamp in which token per stake changed
    uint256 private lastTimeTPSChanged;

    //Period of time per which awards accrue
    uint256 private rewardDistibutionPeriod;

    //This mapping contains information about users stake
    //accounts[userAddress] = Account
    mapping(address => Account) public accounts;

    constructor(
        address _stakeTokenAddress,
        address _rewardTokenAddress,
        uint256 _rewardPerEpoch,
        uint256 _epochDuration,
        uint256 _rewardDistibutionPeriod,
        uint256 _lockPeriod
    ) {
        require(_epochDuration >= _rewardDistibutionPeriod);

        rewardPerEpoch = _rewardPerEpoch;
        epochDuration = _epochDuration;
        stakeTokenAddress = _stakeTokenAddress;
        rewardTokenAddress = _rewardTokenAddress;
        rewardDistibutionPeriod = _rewardDistibutionPeriod;
        lastTimeTPSChanged = block.timestamp;
        lockPeriod = _lockPeriod;
    }

    /**
     * @notice With this function user can stake some amount of token to contract.
     * @dev Users can not unstake and claim tokens before their lock time ends
     * @param _amount is an amount of tokens which user stakes to contract.
     */
    function stake(uint256 _amount) external {
        require(!stakingLocked, "Deposit locked, can only withdraw");
        require(_amount > 0, "Not enough to deposite");
        Account storage account = accounts[msg.sender];
        IERC20(stakeTokenAddress).safeTransferFrom(msg.sender, address(this), _amount);

        totalAmountStake += _amount;

        update();

        account.lockedUntil = block.timestamp + lockPeriod;
        account.amountStake += _amount;
        account.missedReward += _amount * tokenPerStake;

        emit Stake(msg.sender, _amount);
    }

    /**
     * @notice With this function user can unstake some amount of token from contract.
     * @dev User claim rewards instantly in unstake
     * @param _amount Amount of tokens which user want to unstake.
     */
    function unstake(uint256 _amount) external {
        require(_amount > 0, "Not enough to unstake");
        Account storage account = accounts[msg.sender];
        require(account.amountStake >= _amount, "Too much to unstake");
        require(account.lockedUntil < block.timestamp, "The time to unlock has not yet come");

        update();

        IERC20(stakeTokenAddress).safeTransfer(msg.sender, _amount);
        IERC20(rewardTokenAddress).safeTransfer(msg.sender, _availableReward(msg.sender));

        account.amountStake -= _amount;

        account.missedReward = tokenPerStake * account.amountStake;

        totalAmountStake -= _amount;

        emit Unstake(msg.sender, _amount);
    }

    /**
     * @notice With this function user can claim his rewards.
     * @dev User get amount of tokens depends on time which he stake and amount of staked tokens
     */
    function claim() external {
        update();
        Account storage account = accounts[msg.sender];
        require(account.lockedUntil < block.timestamp, "The time to unlock has not yet come");

        uint256 amount = _availableReward(msg.sender);

        IERC20(rewardTokenAddress).safeTransfer(msg.sender, amount);

        account.missedReward += amount * precision;

        emit Claim(msg.sender, amount);
    }

    /**
     * @notice With this function we can lock stake function to lock new deposites
     * @param status - true - lock stake function, false - unlock stake function
     */
    function lockStake(bool status) external onlyOwner {
        stakingLocked = status;
        emit StakingLocked(msg.sender, status);
    }

    /** @notice Set parameters of staking by Owner.
     * @dev  emit `StakingRuleChфnged` event.
     * @param _rewardPerEpoch New amount reward tokens which will available in epoch.
     * @param _epochDuration New duration of epoch.
     * @param _rewardDistibutionPeriod Min amount of time for receive reward.
     */
    function setStakingRules(
        uint256 _rewardPerEpoch,
        uint256 _epochDuration,
        uint256 _rewardDistibutionPeriod
    ) external onlyOwner {
        require(_epochDuration >= _rewardDistibutionPeriod, "Incorrect parametres");
        update();

        epochDuration = _epochDuration;
        rewardPerEpoch = _rewardPerEpoch;
        rewardDistibutionPeriod = _rewardDistibutionPeriod;

        emit StakingRuleChanged(_epochDuration, _rewardPerEpoch, _rewardDistibutionPeriod);
    }

    /**
    * @notice With this function user can see information 
    about contract, including tokens addresses,
    amount of reward tokens, that will be paid to all of user in some epoch,
    duration of epoch and the minimum period of time for which the reward is received.
    * @return viewData - structure with information about contract.
    */
    function getViewData() external view returns (ViewData memory viewData) {
        viewData = (
            ViewData(
                stakeTokenAddress,
                rewardTokenAddress,
                rewardPerEpoch,
                epochDuration,
                rewardDistibutionPeriod,
                lockPeriod,
                totalAmountStake
            )
        );
    }

    /** 
    * @notice With this function user can see information 
    of user with certain address, including amount of staked tokens,
    missed rewards and timestamp in which stake unlocks.
    * @param _account is the address of some user.
    * @return account - structure with information about user.
    */
    function getAccount(address _account) external view returns (Account memory account) {
        account = (
            Account(accounts[_account].amountStake, accounts[_account].missedReward, accounts[_account].lockedUntil)
        );
    }

    /** 
    * @notice With this function user can see information 
    of user with certain address, including amount of staked tokens,
    missed rewards and how many reward tokens can be claimed.
    * @param _account is the address of some user.
    * @return userInfo - structure with information about user.
    */
    function getUserInfo(address _account) external view returns (UserInfo memory userInfo) {
        userInfo = UserInfo(
            accounts[_account].amountStake,
            accounts[_account].missedReward,
            accounts[_account].lockedUntil,
            _availableReward(_account)
        );
    }

    /**
     * @notice With this function user can see amount of tokens which address cant get after claim
     * @param _account is the address of some user.
     * @return amount - amount of tokens available for claim after unlock.
     */
    function availableReward(address _account) public view returns (uint256 amount) {
        amount = _availableReward(_account);
    }

    /**
    * @notice With this function contract can previously see how many reward tokens 
    can be claimed by user with certain address.
    * @param _account is the address of some user.
    * @return amount - An amount reward tokens that can be claimed.
    */
    function _availableReward(address _account) internal view returns (uint256 amount) {
        uint256 amountOfDurations = (block.timestamp - lastTimeTPSChanged) / rewardDistibutionPeriod;
        uint256 currentTokenPerStake = tokenPerStake +
            ((rewardPerEpoch * rewardDistibutionPeriod * precision) / (totalAmountStake * epochDuration)) *
            amountOfDurations;
        amount = (currentTokenPerStake * accounts[_account].amountStake - accounts[_account].missedReward) / precision;
    }

    /**
     * @notice This function update value of tokenPerStake.
     */
    function update() private {
        uint256 amountOfDurations = (block.timestamp - lastTimeTPSChanged) / rewardDistibutionPeriod;
        lastTimeTPSChanged += rewardDistibutionPeriod * amountOfDurations;
        if (totalAmountStake > 0)
            tokenPerStake =
                tokenPerStake +
                ((rewardPerEpoch * rewardDistibutionPeriod * precision) / (totalAmountStake * epochDuration)) *
                amountOfDurations;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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