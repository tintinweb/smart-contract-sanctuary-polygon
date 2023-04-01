// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "SafeERC20.sol";
import "IERC20.sol";
import "IERC721.sol";

/**
 * @title Stake2Follow
 * @author atlasxu
 * @notice A contract to encourage follow on Lens Protocol by staking
 */

contract stake2Follow {
    using SafeERC20 for IERC20;

    address public owner;
    address public walletAddress;
    address public appAddress;
    bool private stopped = false;
    IERC20 public currency;

    // contract deployed time
    uint256 genesis;
    // stake amount of each profile at each round
    uint256 public stakeValue;
    // The fee of stake, n/1000
    uint256 public gasFee;
    // The fee of reward, n/1000
    uint256 public rewardFee;
    // The maximum profiles of each round
    uint256 public maxProfiles;

    // First N profiles free of fee in each round
    uint256 public firstNFree = 0;

    // roundId => qualify info
    // qualify-bits   exclude-bits   claimed bits
    //  [0 --- 49]    [50------99]  [100------149]
    mapping(uint256 => uint256) roundToQualify;

    /// roundId => profiles
    mapping(uint256 => uint256[]) roundToProfiles;

    // profiles => roundIds
    mapping(uint256 => uint256[]) profileToRounds;

    // profileId -> address
    mapping(uint256 => address) profileToAddress;

    uint256 public constant MAXIMAL_PROFILES = 50;

    uint256 public constant ROUND_OPEN_LENGTH = 3 hours;
    uint256 public constant ROUND_FREEZE_LENGTH = 50 minutes;
    uint256 public constant ROUND_GAP_LENGTH = 10 minutes;

    // Events
    event ProfileStake(uint256 roundId, address profileAddress, uint256 stake, uint256 fees);
    event ProfileQualify(uint256 roundId, uint256 qualify);
    event ProfileExclude(uint256 roundId, uint256 exclude);
    event ProfileClaim(uint256 roundId, uint256 profileId, uint256 fund);
    event AppSet(address app, address sender);
    event WalletSet(address wallet, address sender);
    event CircuitBreak(bool stop);
    event SetGasFee(uint256 fee);
    event SetRewardFee(uint256 fee);
    event SetMaxProfiles(uint256 profiles);
    event SetStakeValue(uint256 value);
    event SetFirstNFree(uint256 n);
    event WithdrawRoundFee(uint256 roundId, uint256 fee);
    event Withdraw(uint256 balance);

    constructor(uint256 _stakeValue, uint256 _gasFee, uint256 _rewardFee, uint8 _maxProfiles, address _currency, address _appAddress, address _walletAddress) {
        currency = IERC20(_currency);

        gasFee = _gasFee;
        rewardFee = _rewardFee;
        stakeValue = _stakeValue;
        maxProfiles = _maxProfiles;

        appAddress = _appAddress;
        walletAddress = _walletAddress;

        owner = msg.sender;
        genesis = block.timestamp;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    modifier onlyApp() {
        require(msg.sender == appAddress, "Only App can call this function.");
        _;
    }

    modifier stopInEmergency() {
        require(!stopped, "Emergency stop is active, function execution is prevented.");
        _;
    }

    modifier onlyInEmergency() {
        require(stopped, "Not in Emergency, function execution is prevented.");
        _;
    }

    function isClaimable(uint256 roundId, uint256 profileIndex) internal view returns (bool) {
        return (((roundToQualify[roundId] >> profileIndex) & 1) == 1);
    }

    function isExcluded(uint256 roundId, uint256 profileIndex) internal view returns (bool) {
        return (((roundToQualify[roundId] >> (profileIndex + 50)) & 1) == 1);
    }

    function isClaimed(uint256 roundId, uint256 profileIndex) internal view returns (bool) {
        return (((roundToQualify[roundId] >> (profileIndex + 100)) & 1) == 1);
    }

    function setClaimed(uint256 roundId, uint256 profileIndex) internal {
        roundToQualify[roundId] |= (1 << (100 + profileIndex));
    }

    function setExcluded(uint256 roundId, uint256 profileIndex) internal {
        roundToQualify[roundId] |= (1 << (50 + profileIndex));
    }

    function setClaimable(uint256 roundId, uint256 profileIndex) internal {
        roundToQualify[roundId] |= (1 << profileIndex);
    }

    function isOpen(uint256 roundId) internal view returns (bool) {
        uint256 startTime = genesis + roundId * ROUND_GAP_LENGTH;
        return (block.timestamp > startTime && block.timestamp < (startTime + ROUND_OPEN_LENGTH));
    }

    function isSettle(uint256 roundId) internal view returns (bool) {
        return (block.timestamp > (genesis + roundId * ROUND_GAP_LENGTH + ROUND_OPEN_LENGTH + ROUND_FREEZE_LENGTH));
    }

    function payCurrency(address to, uint256 amount) internal {
        require(amount > 0, "Invalid amount");
        currency.safeTransfer(to, amount);
    }

    /**
     * @dev profile claim and transfer fund back
     * @param roundId round id
     * @param profileIndex The index in the profiles array, get by getRoundData
     * @param profileId profile id
     */
    function profileClaim(uint256 roundId, uint256 profileIndex, uint256 profileId) external stopInEmergency {
        // ensure round is settle
        require(isSettle(roundId), "Round is not settle");
        // out-of-bound check
        require(profileIndex < roundToProfiles[roundId].length, "index out of bound");
        require(profileId == roundToProfiles[roundId][profileIndex], "Profile invalid");
        // check address legal
        require(msg.sender == profileToAddress[profileId], "Address not match profile");
        // Check the profile has qualify to claim
        require(isClaimable(roundId, profileIndex), "Profile not qualify to claimed");
        // Check the profile is not exclude
        require(!isExcluded(roundId, profileIndex), "Profile is excluded");
        // Check the profile has not claimed
        require(!isClaimed(roundId, profileIndex), "Profile already claimed");

        // calculate reward && pay

        uint256 profileNum = roundToProfiles[roundId].length;
        uint256 qualifyNum = 0;
        for (uint256 i = 0; i < profileNum; i++) {
            if (isClaimable(roundId, i) && !isExcluded(roundId, i)) {
                qualifyNum += 1;
            }
        }

        // adition fee to divide
        uint256 reward = stakeValue * (profileNum - qualifyNum);
        uint256 fee = (reward / 1000) * rewardFee;
        uint256 claimValue = stakeValue + ((reward - fee) / qualifyNum);

        // Transfer the fund to profile
        payCurrency(profileToAddress[profileId], claimValue);
        
        // Set the flag indicating that the profile has already claimed
        setClaimed(roundId, profileIndex);

        emit ProfileClaim(roundId, profileId, claimValue);
    }

    /**
     * @dev Each participant stake the fund to the round.
     * @param roundId the round id.
     * @param profileId The ID of len profile.
     * @param profileAddress The address of the profile that staking.
     */
    function profileStake(uint256 roundId, uint256 profileId, address profileAddress) external stopInEmergency {
        // Check if the msg.sender is the profile owner
        require(msg.sender == profileAddress, "Sender is not the profile owner");
        // Check if the profile address is valid
        require(profileAddress != address(0), "Invalid profile address");
        // Check round is in open stage
        require(isOpen(roundId), "Round is not in open stage");
        // Check profile count
        require(roundToProfiles[roundId].length < maxProfiles, "Maximum profile limit reached");
        // TODO: check not staked before
        // total profiles is small, so this loop is ok
        bool alreadyIn = false;
        for (uint32 i = 0; i < roundToProfiles[roundId].length; i += 1) {
            if (roundToProfiles[roundId][i] ==  profileId) {
                alreadyIn = true;
                break;
            }
        }
        require(!alreadyIn, "profile already paticipant");

        // bind address to profile
        profileToAddress[profileId] = profileAddress;

        // free of fee ?
        if (roundToProfiles[roundId].length < firstNFree) {
            // Transfer funds to stake contract
            currency.safeTransferFrom(
                profileAddress,
                address(this),
                stakeValue
            );
            emit ProfileStake(roundId, profileAddress, stakeValue, 0);
        } else {
            // Calculate fee
            uint256 stakeFee = (stakeValue / 1000) * gasFee;

            // Transfer funds to stake contract
            currency.safeTransferFrom(
                profileAddress,
                address(this),
                stakeValue + stakeFee
            );

            // transfer fees
            if (stakeFee > 0) {
                payCurrency(walletAddress, stakeFee);
            }
            emit ProfileStake(roundId, profileAddress, stakeValue, stakeFee);
        }
        
        // add profile
        roundToProfiles[roundId].push(profileId);

        // add round
        profileToRounds[profileId].push(roundId);
    }

    /**
     * @dev qualify profile
     */
    function profileQualify(uint256 roundId, uint256 qualify) external stopInEmergency onlyApp {
        require(!isOpen(roundId), "Round is open");
        // ensure round is not settle
        require(!isSettle(roundId), "Round is settle");
        require(qualify > 0, "qualify should not be zero");
        require(roundToProfiles[roundId].length > 0, "profiles is empty");
        // set last #profiles bits
        roundToQualify[roundId] |= (((1 << roundToProfiles[roundId].length) - 1) & qualify);
        emit ProfileQualify(roundId, qualify);
    }

    /**
     * @dev exclude profiles which is illegal
     * @param roundId current round id
     * @param illegals Bit array to indicate profile qualification of claim
     */
    function profileExclude(uint256 roundId, uint256 illegals) external stopInEmergency onlyApp {
        // round not settle
        require(!isSettle(roundId), "Round is settle");
        require(illegals > 0, "qualify should not be zero");
        require(roundToProfiles[roundId].length > 0, "profiles is empty");

        roundToQualify[roundId] |= ((((1 << roundToProfiles[roundId].length) - 1) & illegals) << 50);
        emit ProfileExclude(roundId, illegals);
    }

    function getCurrentRound() public view returns (uint256 roundId, uint256 startTime) {
        uint256 crrentRoundId = (block.timestamp - genesis) / ROUND_GAP_LENGTH;
        return (crrentRoundId, genesis + crrentRoundId * ROUND_GAP_LENGTH);
    }

    function getRoundData(uint256 roundId) public view returns (uint256 qualify, uint256[] memory profiles) {
        return (roundToQualify[roundId], roundToProfiles[roundId]);
    }

    function getProfileRounds(uint256 profileId) public view returns (uint256[] memory roundIds) {
        return profileToRounds[profileId];
    }

    function setApp(address _appAddress) public onlyOwner {
        appAddress = _appAddress;
        emit AppSet(_appAddress, msg.sender);
    }

    function getApp() public view returns (address) {
        return appAddress;
    }

    function setGasFee(uint256 fee) public onlyOwner {
        require(fee < 1000, "Fee invalid");
        gasFee = fee;
        emit SetGasFee(fee);
    }

    function getGasFee() public view returns (uint256) {
        return gasFee;
    }

    function setRewardFee(uint256 fee) public onlyOwner {
        require(fee < 1000, "Fee invalid");
        rewardFee = fee;
        emit SetRewardFee(fee);
    }

    function getRewardFee() public view returns (uint256) {
        return rewardFee;
    }

    function setStakeValue(uint256 _stakeValue) public onlyOwner {
        stakeValue = _stakeValue;
        emit SetStakeValue(stakeValue);
    }

    function getStakeValue() public view returns (uint256) {
        return stakeValue;
    }

    function setMaxProfiles(uint256 profiles) public onlyOwner {
        require(profiles <= MAXIMAL_PROFILES && profiles >= firstNFree, "max profiles invalid");
        maxProfiles = profiles;
        emit SetMaxProfiles(profiles);
    }

    function getMaxProfiles() public view returns (uint256) {
        return maxProfiles;
    }

    function setFirstNFree(uint256 n) public onlyOwner {
        require(n <= maxProfiles, "invalid input");
        firstNFree = n;
        emit SetFirstNFree(n);
    }

    function getFirstNFree() public view returns (uint256) {
        return firstNFree;
    }

    function getConfig() public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        return (stakeValue, gasFee, rewardFee, maxProfiles, genesis, ROUND_OPEN_LENGTH, ROUND_FREEZE_LENGTH, ROUND_GAP_LENGTH, firstNFree);
    }

    function setWallet(address wallet) public onlyOwner {
        walletAddress = wallet;
        emit WalletSet(wallet, msg.sender);
    }

    function getWallet() public view returns (address) {
        return walletAddress;
    }

    function circuitBreaker() public onlyOwner {
        stopped = !stopped;
        emit CircuitBreak(stopped);
    }

    function withdrawRoundFee(uint256 roundId) public onlyOwner {
        // ensure round is settle
        require(isSettle(roundId), "Round is not settle");

        // calculate reward && pay
        uint256 profileNum = roundToProfiles[roundId].length;
        uint256 qualifyNum = 0;
        for (uint256 i = 0; i < profileNum; i++) {
            if (isClaimable(roundId, i) && !isExcluded(roundId, i)) {
                qualifyNum += 1;
            }
        }

        uint256 reward = stakeValue * (profileNum - qualifyNum);
        uint256 fee = (reward / 1000) * rewardFee;

        // Transfer the fund to profile
        if (fee > 0) {
            payCurrency(walletAddress, fee);
        }
        
        emit WithdrawRoundFee(roundId, fee);
    }

    function withdraw() public onlyInEmergency onlyOwner {
        uint256 balance = currency.balanceOf(address(this));
        // Check that there is enough funds to withdraw
        require(balance > 0, "The fund is empty");

        payCurrency(msg.sender, balance);
        emit Withdraw(balance);
    }

    /** @notice To be able to pay and fallback
     */
    receive() external payable {}

    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}