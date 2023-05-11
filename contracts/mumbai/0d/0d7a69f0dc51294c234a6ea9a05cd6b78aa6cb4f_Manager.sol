// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.17;

import { IVersionedContract } from "../utils/interfaces/IVersionedContract.sol";
import { VersionedContract } from "../VersionedContract.sol";
import { Ownable } from "../utils/Ownable.sol";
import { UUPS } from "../proxy/UUPS.sol";

import { Clones } from "../utils/Clones.sol";
import { IManager } from "./interfaces/IManager.sol";
import { IIntervals } from "../intervals/interfaces/IIntervals.sol";
import { IMilestones } from "../milestones/interfaces/IMilestones.sol";
import { IStream } from "../lib/interfaces/IStream.sol";

/// @title Manager
/// @author Matthew Harrison
/// @notice A contract to manage the creation of stream contracts
contract Manager is IManager, VersionedContract, UUPS, Ownable {
    /// @notice The milestones implementation address
    address public immutable msImpl;
    /// @notice The intervals implementation address
    address public immutable intvImpl;
    /// @notice The address of the botDAO
    address public immutable botDAO;
    /// @notice storage gap for future variables
    uint256[49] private __gap;

    constructor(address _msImpl, address _intvImpl, address _botDAO) initializer {
        msImpl = _msImpl;
        intvImpl = _intvImpl;
        botDAO = _botDAO;
    }

    /// @notice Initializes ownership of the manager contract
    /// @param _owner The owner address to set (will be transferred to the Builder DAO once its deployed)
    function initialize(address _owner) external initializer {
        /// Ensure an owner is specified
        if (_owner == address(0)) revert ADDRESS_ZERO();

        /// Set the contract owner
        __Ownable_init(_owner);
    }

    /// @notice Get the address for an interval stream
    /// @param   _owner      Contract owner
    /// @param   _startDate  Start date of the stream
    /// @param   _endDate    End date of the stream
    /// @param   _interval   Interval to issue payouts
    /// @param   _token      ERC20 token address
    /// @param   _recipient  Receiver of payouts
    function getIntvStreamAddress(
        address _owner,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _interval,
        address _token,
        address _recipient
    ) external view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(_owner, _startDate, _endDate, _interval, _token, _recipient));
        return Clones.predictDeterministicAddress(intvImpl, salt);
    }

    /// @notice Creates a stream
    /// @param _owner The owner of the stream
    /// @param _startDate Start date for stream
    /// @param _endDate End date for stream
    /// @param _interval The frequency at which the funds are being released
    /// @param _owed How much is owed to the stream recipient
    /// @param _tip Chosen percentage allocated to bots who disburse funds
    /// @param _recipient Account which receives disbursed funds
    /// @param _token Token address
    /// @return address The address of the stream
    function createIntvStream(
        address _owner,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _interval,
        uint256 _owed,
        uint256 _tip,
        address _recipient,
        address _token
    ) external returns (address) {
        IIntervals _stream = IIntervals(
            Clones.cloneDeterministic(intvImpl, keccak256(abi.encodePacked(_owner, _startDate, _endDate, _interval, _token, _recipient)))
        );
        _stream.initialize(_owner, uint64(_startDate), uint64(_endDate), uint32(_interval), uint96(_tip), _owed, _recipient, _token, botDAO);
        emit StreamCreated(address(_stream), "Intervals");

        return address(_stream);
    }

    /// @notice Get the address for a milestone stream
    /// @param   _msDates    Dates of milestones
    /// @param   _recipient   Receiver of payouts
    /// @param   _token      ERC20 token address
    /// @return  address     Deterministic address of the stream
    function getMSSStreamAddress(address _owner, uint64[] calldata _msDates, address _recipient, address _token) external view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(_owner, _msDates, _token, _recipient));
        return Clones.predictDeterministicAddress(msImpl, salt);
    }

    /// @notice Get the address for an interval stream
    /// @param   _owner      Sender address
    /// @param   _msPayments Milestones payments array
    /// @param   _msDates    Milestones date array
    /// @param   _tip        Chosen percentage allocated to bots who disburse funds
    /// @param   _recipient  Receiver of payouts
    /// @param   _token      ERC20 token address
    /// @return  address     Address of the stream
    function createMSStream(
        address _owner,
        uint256[] calldata _msPayments,
        uint64[] calldata _msDates,
        uint96 _tip,
        address _recipient,
        address _token
    ) external returns (address) {
        IMilestones _stream = IMilestones(Clones.cloneDeterministic(msImpl, keccak256(abi.encodePacked(_owner, _msDates, _token, _recipient))));
        _stream.initialize(_owner, _msPayments, _msDates, _tip, _recipient, _token, botDAO);

        emit StreamCreated(address(_stream), "Milestones");

        return address(_stream);
    }

    /// @notice A batch interface to release funds across multiple streams
    /// @param streams List of DAOStreams to call
    function batchRelease(address[] calldata streams) external {
        for (uint256 index = 0; index < streams.length; index++) {
            IStream(streams[index]).release();
        }
    }

    /// @notice Safely get the contract version of a target contract.
    /// @dev Assume `target` is a contract
    /// @return Contract version if found, empty string if not.
    function _safeGetVersion(address target) internal pure returns (string memory) {
        try IVersionedContract(target).contractVersion() returns (string memory version) {
            return version;
        } catch {
            return "";
        }
    }

    /// @notice Get current version of contract
    /// @param streamImpl Address of DAO version lookup
    function getStreamVersion(address streamImpl) external pure returns (string memory) {
        return _safeGetVersion(streamImpl);
    }

    /// @notice Ensures the caller is authorized to upgrade the contract
    /// @dev This function is called in `upgradeTo` & `upgradeToAndCall`
    /// @param _newImpl The new implementation address
    function _authorizeUpgrade(address _newImpl) internal override onlyOwner {}
}

/// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.17;

/// @title IVersionedContract
/// @notice repo github.com/ourzora/nouns-protocol
interface IVersionedContract {
    function contractVersion() external pure returns (string memory);
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { IUUPS } from "./interfaces/IUUPS.sol";
import { ERC1967Upgrade } from "./ERC1967Upgrade.sol";

/// @title UUPS
/// @author Rohan Kulkarni
/// @notice Modified from OpenZeppelin Contracts v4.7.3 (proxy/utils/UUPSUpgradeable.sol)
/// - Uses custom errors declared in IUUPS
/// - Inherits a modern, minimal ERC1967Upgrade
/// @notice repo github.com/ourzora/nouns-protocol
abstract contract UUPS is IUUPS, ERC1967Upgrade {
    /// @dev The address of the implementation
    address private immutable __self = address(this);

    /// @dev Ensures that execution is via proxy delegatecall with the correct implementation
    modifier onlyProxy() {
        if (address(this) == __self) revert ONLY_DELEGATECALL();
        if (_getImplementation() != __self) revert ONLY_PROXY();
        _;
    }

    /// @dev Ensures that execution is via direct call
    modifier notDelegated() {
        if (address(this) != __self) revert ONLY_CALL();
        _;
    }

    /// @dev Hook to authorize an implementation upgrade
    /// @param _newImpl The new implementation address
    function _authorizeUpgrade(address _newImpl) internal virtual;

    /// @notice Upgrades to an implementation
    /// @param _newImpl The new implementation address
    function upgradeTo(address _newImpl) external onlyProxy {
        _authorizeUpgrade(_newImpl);
        _upgradeToAndCallUUPS(_newImpl, "", false);
    }

    /// @notice Upgrades to an implementation with an additional function call
    /// @param _newImpl The new implementation address
    /// @param _data The encoded function call
    function upgradeToAndCall(address _newImpl, bytes memory _data) external payable onlyProxy {
        _authorizeUpgrade(_newImpl);
        _upgradeToAndCallUUPS(_newImpl, _data, true);
    }

    /// @notice The storage slot of the implementation address
    function proxiableUUID() external view notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/// @notice create opcode failed
error CreateError();
/// @notice create2 opcode failed
error Create2Error();

library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`
     * except when someone calls `receive()` and then it emits an event matching
     * `SplitWallet.ReceiveETH(indexed address, amount)`
     * Inspired by OZ & 0age's minimal clone implementations based on eip 1167 found at
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/proxy/Clones.sol
     * and https://medium.com/coinmonks/the-more-minimal-proxy-5756ae08ee48
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     *
     * init: 0x3d605d80600a3d3981f3
     * 3d   returndatasize  0
     * 605d push1 0x5d      0x5d 0
     * 80   dup1            0x5d 0x5d 0
     * 600a push1 0x0a      0x0a 0x5d 0x5d 0
     * 3d   returndatasize  0 0x0a 0x5d 0x5d 0
     * 39   codecopy        0x5d 0                      destOffset offset length     memory[destOffset:destOffset+length] = address(this).code[offset:offset+length]       copy executing contracts bytecode
     * 81   dup2            0 0x5d 0
     * f3   return          0                           offset length                return memory[offset:offset+length]                                                   returns from this contract call
     *
     * contract: 0x36603057343d52307f830d2d700a97af574b186c80d40429385d24241565b08a7c559ba283a964d9b160203da23d3df35b3d3d3d3d363d3d37363d73bebebebebebebebebebebebebebebebebebebebe5af43d3d93803e605b57fd5bf3
     *     0x000     36       calldatasize      cds
     *     0x001     6030     push1 0x30        0x30 cds
     * ,=< 0x003     57       jumpi
     * |   0x004     34       callvalue         cv
     * |   0x005     3d       returndatasize    0 cv
     * |   0x006     52       mstore
     * |   0x007     30       address           addr
     * |   0x008     7f830d.. push32 0x830d..   id addr
     * |   0x029     6020     push1 0x20        0x20 id addr
     * |   0x02b     3d       returndatasize    0 0x20 id addr
     * |   0x02c     a2       log2
     * |   0x02d     3d       returndatasize    0
     * |   0x02e     3d       returndatasize    0 0
     * |   0x02f     f3       return
     * `-> 0x030     5b       jumpdest
     *     0x031     3d       returndatasize    0
     *     0x032     3d       returndatasize    0 0
     *     0x033     3d       returndatasize    0 0 0
     *     0x034     3d       returndatasize    0 0 0 0
     *     0x035     36       calldatasize      cds 0 0 0 0
     *     0x036     3d       returndatasize    0 cds 0 0 0 0
     *     0x037     3d       returndatasize    0 0 cds 0 0 0 0
     *     0x038     37       calldatacopy      0 0 0 0
     *     0x039     36       calldatasize      cds 0 0 0 0
     *     0x03a     3d       returndatasize    0 cds 0 0 0 0
     *     0x03b     73bebe.. push20 0xbebe..   0xbebe 0 cds 0 0 0 0
     *     0x050     5a       gas               gas 0xbebe 0 cds 0 0 0 0
     *     0x051     f4       delegatecall      suc 0 0
     *     0x052     3d       returndatasize    rds suc 0 0
     *     0x053     3d       returndatasize    rds rds suc 0 0
     *     0x054     93       swap4             0 rds suc 0 rds
     *     0x055     80       dup1              0 0 rds suc 0 rds
     *     0x056     3e       returndatacopy    suc 0 rds
     *     0x057     605b     push1 0x5b        0x5b suc 0 rds
     * ,=< 0x059     57       jumpi             0 rds
     * |   0x05a     fd       revert
     * `-> 0x05b     5b       jumpdest          0 rds
     *     0x05c     f3       return
     *
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d605d80600a3d3981f336603057343d52307f00000000000000000000000000)
            mstore(add(ptr, 0x13), 0x830d2d700a97af574b186c80d40429385d24241565b08a7c559ba283a964d9b1)
            mstore(add(ptr, 0x33), 0x60203da23d3df35b3d3d3d3d363d3d37363d7300000000000000000000000000)
            mstore(add(ptr, 0x46), shl(0x60, implementation))
            mstore(add(ptr, 0x5a), 0x5af43d3d93803e605b57fd5bf300000000000000000000000000000000000000)
            instance := create(0, ptr, 0x67)
        }
        if (instance == address(0)) revert CreateError();
    }

    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d605d80600a3d3981f336603057343d52307f00000000000000000000000000)
            mstore(add(ptr, 0x13), 0x830d2d700a97af574b186c80d40429385d24241565b08a7c559ba283a964d9b1)
            mstore(add(ptr, 0x33), 0x60203da23d3df35b3d3d3d3d363d3d37363d7300000000000000000000000000)
            mstore(add(ptr, 0x46), shl(0x60, implementation))
            mstore(add(ptr, 0x5a), 0x5af43d3d93803e605b57fd5bf300000000000000000000000000000000000000)
            instance := create2(0, ptr, 0x67, salt)
        }
        if (instance == address(0)) revert Create2Error();
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt, address deployer) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d605d80600a3d3981f336603057343d52307f00000000000000000000000000)
            mstore(add(ptr, 0x13), 0x830d2d700a97af574b186c80d40429385d24241565b08a7c559ba283a964d9b1)
            mstore(add(ptr, 0x33), 0x60203da23d3df35b3d3d3d3d363d3d37363d7300000000000000000000000000)
            mstore(add(ptr, 0x46), shl(0x60, implementation))
            mstore(add(ptr, 0x5a), 0x5af43d3d93803e605b57fd5bf3ff000000000000000000000000000000000000)
            mstore(add(ptr, 0x68), shl(0x60, deployer))
            mstore(add(ptr, 0x7c), salt)
            mstore(add(ptr, 0x9c), keccak256(ptr, 0x67))
            predicted := keccak256(add(ptr, 0x67), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.17;

/// @title IManger
/// @author Matthew Harrison
/// @notice The Manager interface
interface IManager {
    /// @notice The address of the Milestones implementation
    function msImpl() external view returns (address);

    /// @notice The address of the Intervals implementation
    function intvImpl() external view returns (address);

    /// @notice Emits stream created event
    /// @param streamId, logs id for stream
    event StreamCreated(address streamId, string streamType);

    /// @notice A batch interface to release funds across multiple streams
    /// @param streams List of streams to distribute funds from
    function batchRelease(address[] calldata streams) external;

    /// @notice Get current version of contract
    /// @param daoStream Address of DAO version lookup
    function getStreamVersion(address daoStream) external pure returns (string memory);

    /// @notice Get the address for an interval stream
    /// @param   _owner      The owner of the stream
    /// @param   _msPayments Milestones payments array
    /// @param   _msDates    Milestones date array
    /// @param   _tip        Chosen percentage allocated to bots who disburse funds
    /// @param   _recipient  Receiver of payouts
    /// @param   _token      ERC20 token address
    /// @return  address     Address of the stream
    function createMSStream(
        address _owner,
        uint256[] calldata _msPayments,
        uint64[] calldata _msDates,
        uint96 _tip,
        address _recipient,
        address _token
    ) external returns (address);

    /// @notice Creates a stream
    /// @param _owner The owner of the stream
    /// @param _startDate Start date for stream
    /// @param _endDate End date for stream
    /// @param _interval The frequency at which the funds are being released
    /// @param _owed How much is owed to the stream recipient
    /// @param _tip Chosen percentage allocated to bots who disburse funds
    /// @param _recipient Account which receives disbursed funds
    /// @param _token Token address
    /// @return address The address of the stream
    function createIntvStream(
        address _owner,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _interval,
        uint256 _owed,
        uint256 _tip,
        address _recipient,
        address _token
    ) external returns (address);

    /// @notice Get the address for a milestone stream
    /// @param   _owner      Contract owner
    /// @param   _msDates    Dates of milestones
    /// @param   _recipient   Receiver of payouts
    /// @param   _token      ERC20 token address
    /// @return  address     Address of the stream
    function getMSSStreamAddress(address _owner, uint64[] calldata _msDates, address _recipient, address _token) external view returns (address);

    /// @notice Get the address for an interval stream
    /// @param   _owner      Contract owner
    /// @param   _startDate  Start date of the stream
    /// @param   _endDate    End date of the stream
    /// @param   _interval   Interval to issue payouts
    /// @param   _token      ERC20 token address
    /// @param   _recipient  Receiver of payouts
    /// @return  address     Address of the stream
    function getIntvStreamAddress(
        address _owner,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _interval,
        address _token,
        address _recipient
    ) external view returns (address);
}

pragma solidity 0.8.17;

import { IStream } from "../../lib/interfaces/IStream.sol";

/// @title IIntervals
/// @author Matthew Harrison
/// @notice An interface for the Intervals stream contract
interface IIntervals is IStream {
    /// @notice Initialize the contract
    /// @param _owner The owner address of the contract
    /// @param _startDate The start date of the stream
    /// @param _endDate The end date of the stream
    /// @param _interval The interval of the stream
    /// @param _tip The tip of the stream, paid to the bot
    /// @param _owed The amount owed to the recipient
    /// @param _recipient The recipient address of the stream
    /// @param _token The token address of the stream
    function initialize(
        address _owner,
        uint64 _startDate,
        uint64 _endDate,
        uint32 _interval,
        uint96 _tip,
        uint256 _owed,
        address _recipient,
        address _token,
        address _botDAO
    ) external;

    /// @notice Get the current meta information about the stream
    /// @return The start date of the stream
    /// @return The end date of the stream
    /// @return The interval of the stream
    /// @return The tip of the stream
    /// @return The amount paid to the recipient
    /// @return The amount owed to the recipient
    /// @return The recipient address of the stream
    function getCurrentInterval() external view returns (uint64, uint64, uint32, uint96, uint256, uint256, address);
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

pragma solidity ^0.8.16;

import { IERC1822Proxiable } from "@openzeppelin/contracts/interfaces/draft-IERC1822.sol";
import { IERC1967Upgrade } from "./IERC1967Upgrade.sol";

/// @title IUUPS
/// @author Rohan Kulkarni
/// @notice The external UUPS errors and functions
/// @notice repo github.com/ourzora/nouns-protocol
interface IUUPS is IERC1967Upgrade, IERC1822Proxiable {
    ///                                                          //
    ///                            ERRORS                        //
    ///                                                          //

    /// @dev Reverts if not called directly
    error ONLY_CALL();

    /// @dev Reverts if not called via delegatecall
    error ONLY_DELEGATECALL();

    /// @dev Reverts if not called via proxy
    error ONLY_PROXY();

    ///                                                          //
    ///                           FUNCTIONS                      //
    ///                                                          //

    /// @notice Upgrades to an implementation
    /// @param newImpl The new implementation address
    function upgradeTo(address newImpl) external;

    /// @notice Upgrades to an implementation with an additional function call
    /// @param newImpl The new implementation address
    /// @param data The encoded function call
    function upgradeToAndCall(address newImpl, bytes memory data) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { IERC1822Proxiable } from "@openzeppelin/contracts/interfaces/draft-IERC1822.sol";
import { StorageSlot } from "@openzeppelin/contracts/utils/StorageSlot.sol";

import { IERC1967Upgrade } from "./interfaces/IERC1967Upgrade.sol";
import { Address } from "../utils/Address.sol";

// @title ERC1967Upgrade
// @author Rohan Kulkarni
// @notice Modified from OpenZeppelin Contracts v4.8.1 (proxy/ERC1967/ERC1967Upgrade.sol)
// @notice repo github.com/ourzora/nouns-protocol
abstract contract ERC1967Upgrade is IERC1967Upgrade {
    /// @dev bytes32(uint256(keccak256('eip1967.proxy.rollback')) - 1)
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /// @dev bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @dev Upgrades to an implementation with security checks for UUPS proxies and an additional function call
    /// @param _newImpl The new implementation address
    /// @param _data The encoded function call
    function _upgradeToAndCallUUPS(address _newImpl, bytes memory _data, bool _forceCall) internal {
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(_newImpl);
        } else {
            try IERC1822Proxiable(_newImpl).proxiableUUID() returns (bytes32 slot) {
                if (slot != _IMPLEMENTATION_SLOT) revert UNSUPPORTED_UUID();
            } catch {
                revert ONLY_UUPS();
            }

            _upgradeToAndCall(_newImpl, _data, _forceCall);
        }
    }

    /// @dev Upgrades to an implementation with an additional function call
    /// @param _newImpl The new implementation address
    /// @param _data The encoded function call
    function _upgradeToAndCall(address _newImpl, bytes memory _data, bool _forceCall) internal {
        _upgradeTo(_newImpl);

        if (_data.length > 0 || _forceCall) {
            Address.functionDelegateCall(_newImpl, _data);
        }
    }

    /// @dev Performs an implementation upgrade
    /// @param _newImpl The new implementation address
    function _upgradeTo(address _newImpl) internal {
        _setImplementation(_newImpl);

        emit Upgraded(_newImpl);
    }

    /// @dev Stores the address of an implementation
    /// @param _impl The implementation address
    function _setImplementation(address _impl) private {
        if (!Address.isContract(_impl)) revert INVALID_UPGRADE(_impl);

        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = _impl;
    }

    /// @dev The address of the current implementation
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.17;

// @title IERC1967Upgrade
// @author Matthew Harrison
// @notice The external ERC1967Upgrade events and errors from
/// @notice Modified from OpenZeppelin Contracts v4.7.3 (proxy/ERC1967/ERC1967Upgrade.sol)
/// - Uses custom errors declared in IERC1967Upgrade
/// - Removes ERC1967 admin and beacon support
// @notice repo github.com/ourzora/nouns-protocol
interface IERC1967Upgrade {
    /// @notice Emitted when the implementation is upgraded
    /// @param impl The address of the implementation
    event Upgraded(address impl);

    /// @dev Reverts if an implementation is an invalid upgrade
    /// @param impl The address of the invalid implementation
    error INVALID_UPGRADE(address impl);

    /// @dev Reverts if an implementation upgrade is not stored at the storage slot of the original
    error UNSUPPORTED_UUID();

    /// @dev Reverts if an implementation does not support ERC1822 proxiableUUID()
    error ONLY_UUPS();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}