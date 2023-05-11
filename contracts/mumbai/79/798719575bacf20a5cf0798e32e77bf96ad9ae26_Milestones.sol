// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.17;

import { Pausable } from "../utils/Pausable.sol";
import { Ownable } from "../utils/Ownable.sol";

import { Stream } from "./../lib/Stream.sol";
import { IMilestones } from "./interfaces/IMilestones.sol";

/// @title Manager
/// @author Matthew Harrison
/// @notice A milestone based stream contract
contract Milestones is IMilestones, Stream {
    /// @notice The milestone payments array
    uint256[] internal msPayments;
    /// @notice The milestone dates array
    uint64[] internal msDates;
    /// @notice The current milestone incrementer
    uint48 internal currentMilestone;
    /// @notice The tip for the bot
    uint96 internal tip;

    constructor() initializer {}

    /// @notice Initialize the contract
    /// @param _owner The owner address of the contract
    /// @param _msPayments The payments for each milestone
    /// @param _msDates The dates for each milestone
    /// @param _tip The tip of the stream, paid to the bot
    /// @param _recipient The recipient address of the stream
    /// @param _token The token used for stream payments
    function initialize(
        address _owner,
        uint256[] calldata _msPayments,
        uint64[] calldata _msDates,
        uint96 _tip,
        address _recipient,
        address _token,
        address _botDAO
    ) external initializer {
        msPayments = _msPayments;
        msDates = _msDates;
        tip = _tip;
        recipient = _recipient;
        token = _token;
        botDAO = _botDAO;

        /// Grant initial ownership to a founder
        __Ownable_init(_owner);

        /// Pause the contract until the first auction
        __Pausable_init(false);
    }

    /// @notice Distribute payouts with tip calculation
    function release() external whenNotPaused returns (uint256) {
        uint256 _amount = _nextPayment();
        if (_amount == 0) return 0;

        uint256 amount = _amount - tip;
        _distribute(recipient, amount);
        _distribute(botDAO, tip);

        currentMilestone++;

        emit FundsDisbursed(address(this), _amount, "Milestones");

        return _amount;
    }

    /// @notice Release funds of a single stream with no tip payout
    /// @return The amount disbursed
    function claim() external whenNotPaused returns (uint256) {
        uint256 _amount = _nextPayment();
        if (_amount == 0) return 0;

        _distribute(recipient, _amount);

        currentMilestone++;

        emit FundsDisbursed(address(this), _amount, "Milestones");

        return _amount;
    }

    /// @notice Retrieve the current balance of a stream
    /// @return The balance of the stream
    function nextPayment() external view returns (uint256) {
        return _nextPayment();
    }

    /// @notice Get the current meta information about the stream
    /// @return currentMilestone The current milestone index
    /// @return currentPayment The current milestone payment
    /// @return currentDate The current milestone date
    /// @return tip The tip of the stream
    /// @return recipient The recipient address of the stream
    function getCurrentMilestone() external view returns (uint48, uint256, uint64, uint96, address) {
        if (msDates.length <= currentMilestone) {
            return (currentMilestone, 0, 0, tip, recipient);
        } else {
            return (currentMilestone, msPayments[currentMilestone], msDates[currentMilestone], tip, recipient);
        }
    }

    /// @notice Get the milestone payment and date via an index
    /// @param index The index of the milestone
    /// @return payment The milestone payment
    /// @return date The milestone date
    function getMilestone(uint88 index) external view returns (uint256, uint64) {
        return (msPayments[index], msDates[index]);
    }

    /// @notice Get the length of the milestones array
    /// @return milestonesAmount The length of the milestones array
    function getMilestoneLength() external view returns (uint256, uint256) {
        return (msPayments.length, msDates.length);
    }

    /// @notice Gets the next payment amount
    /// @return nextPaymentAmount The next payment amount
    function _nextPayment() internal view returns (uint256) {
        if (msDates.length <= currentMilestone) revert STREAM_FINISHED();
        if (block.timestamp < msDates[currentMilestone]) {
            return 0;
        }
        return msPayments[currentMilestone];
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.17;

import { IPausable } from "./interfaces/IPausable.sol";
import { Initializable } from "./Initializable.sol";

/// @notice Modified from OpenZeppelin Contracts v4.7.3 (security/PausableUpgradeable.sol)
/// - Uses custom errors declared in IPausable
/// @notice repo github.com/ourzora/nouns-protocol
abstract contract Pausable is IPausable, Initializable {
    /// @dev If the contract is paused
    bool internal _paused;

    /// @dev Ensures the contract is paused
    modifier whenPaused() {
        if (!_paused) revert UNPAUSED();
        _;
    }

    /// @dev Ensures the contract isn't paused
    modifier whenNotPaused() {
        if (_paused) revert PAUSED();
        _;
    }

    /// @dev Sets whether the initial state
    /// @param _initPause If the contract should pause upon initialization
    function __Pausable_init(bool _initPause) internal onlyInitializing {
        _paused = _initPause;
    }

    /// @notice If the contract is paused
    function paused() external view returns (bool) {
        return _paused;
    }

    /// @dev Pauses the contract
    function _pause() internal virtual whenNotPaused {
        _paused = true;

        emit Paused(msg.sender);
    }

    /// @dev Unpauses the contract
    function _unpause() internal virtual whenPaused {
        _paused = false;

        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { IOwnable } from "./interfaces/IOwnable.sol";
import { Initializable } from "../utils/Initializable.sol";

// @title Ownable
// @author Rohan Kulkarni
// @notice Modified from OpenZeppelin Contracts v4.8.1 (access/OwnableUpgradeable.sol)
// @notice repo github.com/ourzora/nouns-protocol
abstract contract Ownable is IOwnable, Initializable {
    /// @dev The address of the owner
    address internal _owner;
    /// @dev The address of the pending owner
    address internal _pendingOwner;

    /// @dev Ensures the caller is the owner
    modifier onlyOwner() {
        if (msg.sender != _owner) revert ONLY_OWNER();
        _;
    }

    /// @dev Ensures the caller is the pending owner
    modifier onlyPendingOwner() {
        if (msg.sender != _pendingOwner) revert ONLY_PENDING_OWNER();
        _;
    }

    /// @dev Initializes contract ownership
    /// @param _initialOwner The initial owner address
    function __Ownable_init(address _initialOwner) internal onlyInitializing {
        _owner = _initialOwner;

        emit OwnerUpdated(address(0), _initialOwner);
    }

    /// @notice The address of the owner
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /// @notice The address of the pending owner
    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    /// @notice Forces an ownership transfer from the last owner
    /// @param _newOwner The new owner address
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /// @notice Forces an ownership transfer from any sender
    /// @param _newOwner New owner to transfer contract to
    /// @dev Ensure is called only from trusted internal code, no access control checks.
    function _transferOwnership(address _newOwner) internal {
        emit OwnerUpdated(_owner, _newOwner);

        _owner = _newOwner;

        if (_pendingOwner != address(0)) delete _pendingOwner;
    }

    /// @notice Initiates a two-step ownership transfer
    /// @param _newOwner The new owner address
    function safeTransferOwnership(address _newOwner) public onlyOwner {
        _pendingOwner = _newOwner;

        emit OwnerPending(_owner, _newOwner);
    }

    /// @notice Accepts an ownership transfer
    function acceptOwnership() public onlyPendingOwner {
        emit OwnerUpdated(_owner, msg.sender);

        _owner = _pendingOwner;

        delete _pendingOwner;
    }

    /// @notice Cancels a pending ownership transfer
    function cancelOwnershipTransfer() public onlyOwner {
        emit OwnerCanceled(_owner, _pendingOwner);

        delete _pendingOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.17;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Pausable } from "../utils/Pausable.sol";
import { Ownable } from "../utils/Ownable.sol";

import { IStream } from "./interfaces/IStream.sol";
import { VersionedContract } from "../VersionedContract.sol";

/// @title Stream
/// @author Matthew Harrison
/// @notice The base contract for all streams
abstract contract Stream is IStream, VersionedContract, Pausable, Ownable {
    using SafeERC20 for address;

    /// @notice The token used for stream payments
    address public token;
    /// @notice The address of the botDAO
    address public botDAO;
    /// @notice The recipient address
    address public recipient;

    /// @notice Withdraw funds from smart contract, only the owner can do this.
    function withdraw() external onlyOwner {
        uint256 bal;
        if (token == address(0)) {
            bal = address(this).balance;
            (bool success, ) = address(owner()).call{ value: bal }("");
            if (!success) {
                revert TRANSFER_FAILED();
            }
        } else {
            bal = IERC20(token).balanceOf(address(this));
            SafeERC20.safeTransfer(IERC20(token), owner(), bal);
        }

        emit Withdraw(address(this), bal);
    }

    /// @notice Pause the whole contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Pause the whole contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Get the balance of the contract
    /// @return The balance of the contract
    function balance() external view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }

    /// @notice Change the recipient address
    /// @param newRecipient The new recipient address
    function changeRecipient(address newRecipient) external {
        if (msg.sender == recipient) {
            recipient = newRecipient;
            emit RecipientChanged(msg.sender, newRecipient);
        } else {
            revert ONLY_RECIPIENT();
        }
    }

    /// @notice Distribute payout
    /// @param _to Account receieve transfer
    /// @param _amount Amount to transfer
    function _distribute(address _to, uint256 _amount) internal {
        if (token != address(0)) {
            /// ERC20 transfer
            SafeERC20.safeTransfer(IERC20(token), _to, _amount);
        } else {
            (bool success, ) = address(_to).call{ value: _amount }("");
            if (!success) {
                revert TRANSFER_FAILED();
            }
        }
    }

    receive() external payable {
        if (token != address(0)) {
            revert NO_ETHER();
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.17;

import { IStream } from "../../lib/interfaces/IStream.sol";

/// @title IMilestones
/// @author Matthew Harrison
/// @notice An interface for the Milestones stream contract
interface IMilestones is IStream {
    /// @notice Initialize the contract
    /// @param _owner The owner address of the contract
    /// @param _msPayments The payments for each milestone
    /// @param _msDates The dates for each milestone
    /// @param _tip The tip of the stream, paid to the bot
    /// @param _recipient The recipient address of the stream
    /// @param _token The token used for stream payments
    function initialize(
        address _owner,
        uint256[] calldata _msPayments,
        uint64[] calldata _msDates,
        uint96 _tip,
        address _recipient,
        address _token,
        address _botDAO
    ) external;

    /// @notice Get the current meta information about the stream
    /// @return The current milestone index
    /// @return The current milestone payment
    /// @return The current milestone date
    /// @return The tip of the stream
    /// @return The recipient address of the stream
    function getCurrentMilestone() external view returns (uint48, uint256, uint64, uint96, address);

    /// @notice Get the milestone payment and date via an index
    /// @param index The index of the milestone
    /// @return The milestone payment
    /// @return The milestone date
    function getMilestone(uint88 index) external view returns (uint256, uint64);

    /// @notice Get the length of the milestones array
    /// @return The length of the milestones array
    function getMilestoneLength() external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// @title IPausable
// @author Rohan Kulkarni
// @notice The external Pausable events, errors, and functions
// @custom:mod repo github.com/ourzora/nouns-protocol
interface IPausable {
    /// @notice Emitted when the contract is paused
    /// @param user The address that paused the contract
    event Paused(address user);

    /// @notice Emitted when the contract is unpaused
    /// @param user The address that unpaused the contract
    event Unpaused(address user);

    /// @dev Reverts if called when the contract is paused
    error PAUSED();

    /// @dev Reverts if called when the contract is unpaused
    error UNPAUSED();

    /// @notice If the contract is paused
    function paused() external view returns (bool);

    /// @notice Pauses the contract
    function pause() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { IInitializable } from "./interfaces/IInitializable.sol";
import { Address } from "../utils/Address.sol";

// @title Initializable
// @author Rohan Kulkarni
// @notice Modified from OpenZeppelin Contracts v4.7.3 (proxy/utils/Initializable.sol)
// - Uses custom errors declared in IInitializable
// @notice repo github.com/ourzora/nouns-protocol
abstract contract Initializable is IInitializable {
    /// @dev Indicates the contract has been initialized
    uint8 internal _initialized;

    /// @dev Indicates the contract is being initialized
    bool internal _initializing;

    /// @dev Ensures an initialization function is only called within an `initializer` or `reinitializer` function
    modifier onlyInitializing() {
        if (!_initializing) revert NOT_INITIALIZING();
        _;
    }

    /// @dev Enables initializing upgradeable contracts
    modifier initializer() {
        bool isTopLevelCall = !_initializing;

        if ((!isTopLevelCall || _initialized != 0) && (Address.isContract(address(this)) || _initialized != 1)) revert ALREADY_INITIALIZED();

        _initialized = 1;

        if (isTopLevelCall) {
            _initializing = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;

            emit Initialized(1);
        }
    }

    /// @dev Enables initializer versioning
    /// @param _version The version to set
    modifier reinitializer(uint8 _version) {
        if (_initializing || _initialized >= _version) revert ALREADY_INITIALIZED();

        _initialized = _version;

        _initializing = true;

        _;

        _initializing = false;

        emit Initialized(_version);
    }

    /// @dev Prevents future initialization
    function _disableInitializers() internal virtual {
        if (_initializing) revert INITIALIZING();

        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;

            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// @title IOwnable
// @author Rohan Kulkarni
// @notice The external Ownable events, errors, and functions
// @notice repo github.com/ourzora/nouns-protocol
interface IOwnable {
    /// @notice Emitted when ownership has been updated
    /// @param prevOwner The previous owner address
    /// @param newOwner The new owner address
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);

    /// @notice Emitted when an ownership transfer is pending
    /// @param owner The current owner address
    /// @param pendingOwner The pending new owner address
    event OwnerPending(address indexed owner, address indexed pendingOwner);

    /// @notice Emitted when a pending ownership transfer has been canceled
    /// @param owner The current owner address
    /// @param canceledOwner The canceled owner address
    event OwnerCanceled(address indexed owner, address indexed canceledOwner);

    /// @dev Reverts if an unauthorized user calls an owner function
    error ONLY_OWNER();

    /// @dev Reverts if an unauthorized user calls a pending owner function
    error ONLY_PENDING_OWNER();

    /// @notice The address of the owner
    function owner() external view returns (address);

    /// @notice The address of the pending owner
    function pendingOwner() external view returns (address);

    /// @notice Forces an ownership transfer
    /// @param newOwner The new owner address
    function transferOwnership(address newOwner) external;

    /// @notice Initiates a two-step ownership transfer
    /// @param newOwner The new owner address
    function safeTransferOwnership(address newOwner) external;

    /// @notice Accepts an ownership transfer
    function acceptOwnership() external;

    /// @notice Cancels a pending ownership transfer
    function cancelOwnershipTransfer() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.17;

import { IPausable } from "../../utils/interfaces/IPausable.sol";

/// @title IStream
/// @author Matthew Harrison
/// @notice An interface for the Stream contract
interface IStream is IPausable {
    /// @notice The address of the token for payments
    function token() external view returns (address);

    /// @notice The address of the of the botDAO
    function botDAO() external view returns (address);

    /// @notice Emits event when funds are disbursed
    /// @param streamId contract address of the stream
    /// @param amount amount of funds disbursed
    /// @param streamType type of stream
    event FundsDisbursed(address streamId, uint256 amount, string streamType);

    /// @notice Emits event when funds are disbursed
    /// @param streamId contract address of the stream
    /// @param amount amount of funds withdrawn
    event Withdraw(address streamId, uint256 amount);

    /// @notice Emits event when recipient is changed
    /// @param oldRecipient old recipient address
    /// @param newRecipient new recipient address
    event RecipientChanged(address oldRecipient, address newRecipient);

    /// @dev Thrown if the start date is greater than the end date
    error INCORRECT_DATE_RANGE();

    /// @dev Thrown if if the stream has not started
    error STREAM_HASNT_STARTED();

    /// @dev Thrown if the stream has made its final payment
    error STREAM_FINISHED();

    /// @dev Thrown if msg.sender is not the recipient
    error ONLY_RECIPIENT();

    /// @dev Thrown if the transfer failed.
    error TRANSFER_FAILED();

    /// @dev Thrown if the stream is an ERC20 stream and reverts if ETH was sent.
    error NO_ETHER();

    /// @notice Retrieve the current balance of a stream
    function balance() external returns (uint256);

    /// @notice Retrieve the next payment of a stream
    function nextPayment() external returns (uint256);

    /// @notice Release of streams
    /// @return amount of funds released
    function release() external returns (uint256);

    /// @notice Release funds of a single stream with no tip payout
    function claim() external returns (uint256);

    /// @notice Withdraw funds from smart contract, only the owner can do this.
    function withdraw() external;

    /// // @notice Unpause stream
    function unpause() external;

    /// @notice Change the recipient address
    /// @param newRecipient The new recipient address
    function changeRecipient(address newRecipient) external;
}

/// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.17;

/// @notice Versioned Contract Interface
/// @notice repo github.com/ourzora/nouns-protocol
abstract contract VersionedContract {
    function contractVersion() external pure returns (string memory) {
        return "1.0.0";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// @title IInitializable
// @author Rohan Kulkarni
// @notice The external Initializable events and errors
// @notice repo github.com/ourzora/nouns-protocol
interface IInitializable {
    /// @notice Emitted when the contract has been initialized or reinitialized
    event Initialized(uint256 version);

    /// @dev Reverts if incorrectly initialized with address(0)
    error ADDRESS_ZERO();

    /// @dev Reverts if disabling initializers during initialization
    error INITIALIZING();

    /// @dev Reverts if calling an initialization function outside of initialization
    error NOT_INITIALIZING();

    /// @dev Reverts if reinitializing incorrectly
    error ALREADY_INITIALIZED();
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// @title EIP712
// @author Rohan Kulkarni
// @notice Modified from OpenZeppelin Contracts v4.8.1 (utils/Address.sol)
// - Uses custom errors `INVALID_TARGET()` & `DELEGATE_CALL_FAILED()`
// - Adds util converting address to bytes32
// @notice repo github.com/ourzora/nouns-protocol
library Address {
    /// @dev Reverts if the target of a delegatecall is not a contract
    error INVALID_TARGET();

    /// @dev Reverts if a delegatecall has failed
    error DELEGATE_CALL_FAILED();

    /// @dev Utility to convert an address to bytes32
    function toBytes32(address _account) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_account)) << 96);
    }

    /// @dev If an address is a contract
    function isContract(address _account) internal view returns (bool rv) {
        assembly {
            rv := gt(extcodesize(_account), 0)
        }
    }

    /// @dev Performs a delegatecall on an address
    function functionDelegateCall(address _target, bytes memory _data) internal returns (bytes memory) {
        if (!isContract(_target)) revert INVALID_TARGET();

        (bool success, bytes memory returndata) = _target.delegatecall(_data);

        return verifyCallResult(success, returndata);
    }

    /// @dev Verifies a delegatecall was successful
    function verifyCallResult(bool _success, bytes memory _returndata) internal pure returns (bytes memory) {
        if (_success) {
            return _returndata;
        } else {
            if (_returndata.length > 0) {
                assembly {
                    let returndata_size := mload(_returndata)

                    revert(add(32, _returndata), returndata_size)
                }
            } else {
                revert DELEGATE_CALL_FAILED();
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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