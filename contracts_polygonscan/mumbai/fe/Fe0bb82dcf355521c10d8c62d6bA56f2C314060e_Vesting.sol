//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ISheeshaVesting.sol";
import "./interfaces/ISheeshaVault.sol";

/**
 * @title Sheesha vesting contract
 * @author Sheesha Finance
 */
contract Vesting is ISheeshaVesting, Ownable {
    using SafeERC20 for IERC20;

    enum VestingType {
        SEED,
        PRIVATE,
        STRATEGIC,
        PUBLIC,
        TEAM_ADVISORS,
        RESERVES
    }

    struct RecipientInfo {
        uint256 amount;
        VestingType vestingType;
        uint256 paidAmount;
    }

    struct VestingSchedule {
        uint256 durationInPeriods;
        uint256 cliffInPeriods;
        uint256 tokensAllocation;
        uint256 tokensInVestings;
    }

    uint256 private constant PERIOD = 30 days;
    uint256 private constant DECIMALS_MUL = 10**18;
    uint256 private constant SEED = 150_000_000 * DECIMALS_MUL;
    uint256 private constant PRIVATE = 80_000_000 * DECIMALS_MUL;
    uint256 private constant STRATEGIC = 40_000_000 * DECIMALS_MUL;
    uint256 private constant PUBLIC = 5_000_000 * DECIMALS_MUL;
    uint256 private constant TEAM_ADVISORS = 120_000_000 * DECIMALS_MUL;
    uint256 private constant RESERVES = 100_000_000 * DECIMALS_MUL;

    IERC20 public immutable mSheesha;
    ISheeshaVault public immutable sheeshaStaking;
    uint256 public immutable tgeTimestamp;

    mapping(address => RecipientInfo[]) public vestings;
    mapping(VestingType => VestingSchedule) public vestingSchedules;

    /**
     * @dev Emitted when a new recipient added to vesting
     * @param recipient Address of recipient.
     * @param amount The amount of tokens to be vested.
     */
    event RecipientAdded(address indexed recipient, uint256 amount);

    /**
     * @dev Emitted when a staked to staking contract
     * @param recipient Address of user for which deposit was made.
     * @param pool Pool's unique ID.
     * @param amount The amount of deposited tokens.
     */
    event DepositedToStaking(
        address indexed recipient,
        uint256 pool,
        uint256 amount
    );

    /**
     * @dev Emitted when withdraw of tokens was made on vesting contract.
     * @param recipient Address of user for which withdraw tokens.
     * @param amount The amount of tokens which was withdrawn.
     */
    event WithdrawFromVesting(address indexed recipient, uint256 amount);

    /**
     * @dev Emitted when withdraw of tokens was made on staking contract.
     * @param _recipient Address of user for which withdraw from staking.
     * @param _amount The amount of tokens which was withdrawn.
     */
    event WithdrawFromStaking(address indexed _recipient, uint256 _amount);

    modifier onlyStaking() {
        require(
            address(sheeshaStaking) == _msgSender(),
            "Only Staking allowed"
        );
        _;
    }

    /**
     * @dev Constructor of the contract.
     * @notice Initialize all vesting schedules.
     * @param _tgeTimestamp Token generetaion event unix timestamp.
     * @param _mSheesha Address of mSheesha token.
     * @param _sheeshaStaking Address of staking contract.
     */
    constructor(
        uint256 _tgeTimestamp,
        IERC20 _mSheesha,
        address _sheeshaStaking
    ) {
        require(
            address(_mSheesha) != address(0),
            "Wrong Sheesha token address"
        );
        require(_sheeshaStaking != address(0), "Wrong Sheesha staking address");
        tgeTimestamp = _tgeTimestamp;
        mSheesha = _mSheesha;
        sheeshaStaking = ISheeshaVault(_sheeshaStaking);
        _mSheesha.safeApprove(_sheeshaStaking, type(uint256).max);
        _initializeVestingSchedules();
    }

    /**
     * @dev Adds recipients for vesting.
     * @param _recipients Addresses of recipients.
     * @param _amount The amounts of tokens to be vested.
     * @param _vestingType Type of vesting.
     */
    function addRecipients(
        address[] calldata _recipients,
        uint256[] calldata _amount,
        VestingType _vestingType
    ) external onlyOwner {
        require(
            _recipients.length == _amount.length,
            "Parameters length mismatch"
        );

        for (uint256 i = 0; i < _recipients.length; i++) {
            _addRecipient(_recipients[i], _amount[i], _vestingType);
        }
    }

    /**
     * @dev Withdraws tokens from vesting.
     * @notice Check function caller for available withdrawable amount and
     * transfer tokens to his wallet
     */
    function withdrawFromVesting() external {
        require(block.timestamp >= tgeTimestamp, "TGE didn't start yet");
        RecipientInfo[] storage vesting = vestings[msg.sender];
        uint256 totalToPay;
        for (uint256 i = 0; i < vesting.length; i++) {
            if (!_isForStaking(vesting[i].vestingType)) {
                (, uint256 amountToPay) = _recipientAvailableAmount(
                    msg.sender,
                    i
                );
                totalToPay = totalToPay + amountToPay;
                vesting[i].paidAmount = vesting[i].paidAmount + amountToPay;
            }
        }
        require(totalToPay > 0, "Nothing to withdraw");
        mSheesha.safeTransfer(msg.sender, totalToPay);
        emit WithdrawFromVesting(msg.sender, totalToPay);
    }

    /**
     * @dev Updates user paid amount when withdraw was called on staking contract.
     * @notice Can be called only by staking contract
     */
    function withdrawFromStaking(address recipient, uint256 amount)
        external
        override
        onlyStaking
    {
        RecipientInfo[] storage vesting = vestings[recipient];
        uint256 amountLeft = amount;
        for (uint256 i = 0; i < vesting.length; i++) {
            if (!_isForStaking(vesting[i].vestingType)) continue;
            (, uint256 amountAvailable) = _recipientAvailableAmount(
                recipient,
                i
            );
            if (amountAvailable >= amountLeft) {
                vesting[i].paidAmount = vesting[i].paidAmount + amountLeft;
                amountLeft = 0;
                break;
            } else {
                vesting[i].paidAmount = vesting[i].paidAmount + amountAvailable;
                amountLeft = amountLeft - amountAvailable;
            }
        }
        require(amountLeft == 0, "Something went wrong");
        emit WithdrawFromStaking(recipient, amount);
    }

    /**
     * @dev Withdraw tokens that wasn't added to vesting.
     * @param _type Vesting type to withdraw from
     * @param recipient Address where tokens needed to be send
     */
    function withdrawLeftovers(VestingType _type, address recipient)
        external
        onlyOwner
    {
        require(recipient != address(0), "Wrong recipient address");
        VestingSchedule storage vestingSchedule = vestingSchedules[_type];
        uint256 availableToWithdraw = vestingSchedule.tokensAllocation -
            vestingSchedule.tokensInVestings;
        vestingSchedule.tokensInVestings = vestingSchedule.tokensAllocation;
        mSheesha.safeTransfer(recipient, availableToWithdraw);
    }

    /**
     * @dev Calculates available amount of tokens to withdraw for vesting types
     * which not participate in staking for FE.
     * @return _totalAmount  Recipient total amount in vesting.
     * @return _totalAmountAvailable Recipient available amount to withdraw.
     */
    function calculateAvailableAmount(address _recipient)
        external
        view
        returns (uint256 _totalAmount, uint256 _totalAmountAvailable)
    {
        RecipientInfo[] memory vesting = vestings[_recipient];
        uint256 totalAmount;
        uint256 totalAmountAvailable;
        for (uint256 i = 0; i < vesting.length; i++) {
            if (_isForStaking(vesting[i].vestingType)) continue;
            (
                uint256 _amount,
                uint256 _amountAvailable
            ) = _recipientAvailableAmount(_recipient, i);
            totalAmount = totalAmount + _amount;
            totalAmountAvailable = totalAmountAvailable + _amountAvailable;
        }
        return (totalAmount, totalAmountAvailable);
    }

    /**
     * @dev Calculates available amount of tokens to withdraw for vesting types
     * which participate in staking for FE.
     * @return _leftover Recipient amount which wasn't withdrawn.
     * @return _amountAvailable Recipient available amount to withdraw.
     */
    function calculateAvailableAmountForStaking(address _recipient)
        external
        view
        override
        returns (uint256 _leftover, uint256 _amountAvailable)
    {
        RecipientInfo[] memory vesting = vestings[_recipient];
        uint256 leftover;
        uint256 amountAvailable;
        for (uint256 i = 0; i < vesting.length; i++) {
            if (!_isForStaking(vesting[i].vestingType)) continue;
            (uint256 amount, uint256 available) = _recipientAvailableAmount(
                _recipient,
                i
            );
            uint256 notPaid = amount - vesting[i].paidAmount;
            leftover = leftover + notPaid;
            amountAvailable = amountAvailable + available;
        }
        return (leftover, amountAvailable);
    }

    /**
     * @dev Internal function initialize all vesting types with their schedule
     */
    function _initializeVestingSchedules() internal {
        _addVestingSchedule(
            VestingType.SEED,
            VestingSchedule({
                durationInPeriods: 24,
                cliffInPeriods: 2,
                tokensAllocation: SEED,
                tokensInVestings: 0
            })
        );
        _addVestingSchedule(
            VestingType.PRIVATE,
            VestingSchedule({
                durationInPeriods: 12,
                cliffInPeriods: 1,
                tokensAllocation: PRIVATE,
                tokensInVestings: 0
            })
        );
        _addVestingSchedule(
            VestingType.STRATEGIC,
            VestingSchedule({
                durationInPeriods: 6,
                cliffInPeriods: 1,
                tokensAllocation: STRATEGIC,
                tokensInVestings: 0
            })
        );
        _addVestingSchedule(
            VestingType.PUBLIC,
            VestingSchedule({
                durationInPeriods: 0,
                cliffInPeriods: 0,
                tokensAllocation: PUBLIC,
                tokensInVestings: 0
            })
        );
        _addVestingSchedule(
            VestingType.TEAM_ADVISORS,
            VestingSchedule({
                durationInPeriods: 24,
                cliffInPeriods: 3,
                tokensAllocation: TEAM_ADVISORS,
                tokensInVestings: 0
            })
        );
        _addVestingSchedule(
            VestingType.RESERVES,
            VestingSchedule({
                durationInPeriods: 24,
                cliffInPeriods: 24,
                tokensAllocation: RESERVES,
                tokensInVestings: 0
            })
        );
    }

    /**
     * @dev Internal function adds vesting schedules for vesting type
     */
    function _addVestingSchedule(
        VestingType _type,
        VestingSchedule memory _schedule
    ) internal {
        vestingSchedules[_type] = _schedule;
    }

    /**
     * @dev Internal function used to add recipient for vesting.
     * @param _recipient Address of recipient.
     * @param _amount The amount of tokens to be vested.
     * @param _vestingType Type of vesting.
     */
    function _addRecipient(
        address _recipient,
        uint256 _amount,
        VestingType _vestingType
    ) internal {
        require(_recipient != address(0), "Wrong recipient address");
        require(_amount > 0, "Amount should not be equal to zero");
        require(
            vestingSchedules[_vestingType].tokensInVestings + _amount <=
                vestingSchedules[_vestingType].tokensAllocation,
            "Amount exeeds vesting schedule allocation"
        );
        RecipientInfo[] storage vesting = vestings[_recipient];
        for (uint256 i = 0; i < vesting.length; i++) {
            require(
                vesting[i].vestingType != _vestingType,
                "Recipient with this vesting schedule already exists"
            );
        }
        vestings[_recipient].push(
            RecipientInfo({
                amount: _amount,
                vestingType: _vestingType,
                paidAmount: 0
            })
        );
        vestingSchedules[_vestingType].tokensInVestings =
            vestingSchedules[_vestingType].tokensInVestings +
            _amount;
        if (_isForStaking(_vestingType)) {
            _depositForRecipientInStaking(_recipient, _amount);
        }
        emit RecipientAdded(_recipient, _amount);
    }

    /**
     * @dev Internal function used to stake for recipient in staking contract.
     * @param _recipient Address of recipient.
     * @param _amount The amount of tokens to be staked.
     */
    function _depositForRecipientInStaking(address _recipient, uint256 _amount)
        internal
    {
        sheeshaStaking.depositFor(_recipient, 0, _amount);
        emit DepositedToStaking(_recipient, 0, _amount);
    }

    function _isForStaking(VestingType _type) internal pure returns (bool) {
        bool result = (_type != VestingType.TEAM_ADVISORS &&
            _type != VestingType.RESERVES)
            ? true
            : false;
        return result;
    }

    /**
     * @dev Internal function used to calculate available tokens for specific recipient.
     * @param _recipient Address of recipient.
     * @return _amount  Recipient total amount in vesting.
     * @return _amountAvailable Recipient available amount to withdraw.
     */
    function _recipientAvailableAmount(address _recipient, uint256 index)
        internal
        view
        returns (uint256 _amount, uint256 _amountAvailable)
    {
        RecipientInfo[] memory recipient = vestings[_recipient];
        uint256 amount = recipient[index].amount;
        if (block.timestamp <= tgeTimestamp) return (amount, 0);
        uint256 unlockedAmount;
        VestingSchedule memory vestingSchedule = vestingSchedules[
            recipient[index].vestingType
        ];
        unlockedAmount = _getVestingTypeAvailableAmount(
            vestingSchedule,
            recipient[index].amount
        );
        uint256 amountAvailable = unlockedAmount - recipient[index].paidAmount;
        return (amount, amountAvailable);
    }

    /**
     * @dev Internal function used to calculate available tokens for specific vesting schedule.
     * @param _vestingSchedule vesting schedule.
     * @param _vestingSchedule amount for which calculation should be made
     * @return Available amount for specific schedule.
     */
    function _getVestingTypeAvailableAmount(
        VestingSchedule memory _vestingSchedule,
        uint256 _amount
    ) internal view returns (uint256) {
        uint256 elapsedPeriods = _calculateElapsedPeriods();
        if (elapsedPeriods < _vestingSchedule.cliffInPeriods) {
            return 0;
        } else if (
            elapsedPeriods >=
            _vestingSchedule.cliffInPeriods + _vestingSchedule.durationInPeriods
        ) {
            return _amount;
        } else {
            uint256 periodsWithoutCliff = elapsedPeriods -
                _vestingSchedule.cliffInPeriods;
            uint256 availableAmount = (_amount * periodsWithoutCliff) /
                _vestingSchedule.durationInPeriods;
            return availableAmount;
        }
    }

    /**
     * @dev Internal function used to calculate elapsed periods from tge timestamp.
     * @return Number of periods from tge timestamp.
     */
    function _calculateElapsedPeriods() internal view returns (uint256) {
        return (block.timestamp - tgeTimestamp) / PERIOD;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ISheeshaVesting {
    /**
     * @dev Calculates available amount of tokens to withdraw for vesting types
     * which participate in staking for FE.
     * @return _leftover Recipient amount which wasn't withdrawn.
     * @return _amountAvailable Recipient available amount to withdraw.
     */
    function calculateAvailableAmountForStaking(address _recipient)
        external
        view
        returns (uint256, uint256);

    /**
     * @dev Emitted when withdraw of tokens was made on staking contract.
     * @param _recipient Address of user for which withdraw from staking.
     * @param _amount The amount of tokens which was withdrawn.
     */
    function withdrawFromStaking(address _recipient, uint256 _amount) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ISheeshaVault {
    function token() external view returns (address);

    function staked() external view returns (uint256);

    function stakedOf(address member) external view returns (uint256);

    function enterStaking(uint256 _amount) external;

    function leaveStaking(uint256 _amount) external;

    function depositFor(
        address _depositFor,
        uint256 _pid,
        uint256 _amount
    ) external;

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function pendingSheesha(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function emergencyWithdraw(uint256 _pid) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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