// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "../vendor/fx-portal/contracts/FxChild.sol";
import "../BaseBridgeReceiver.sol";

contract PolygonBridgeReceiver is IFxMessageProcessor, BaseBridgeReceiver {
    error InvalidChild();

    event NewFxChild(address indexed oldFxChild, address indexed newFxChild);

    address public fxChild;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    function changeFxChild(address newFxChild) public {
        if (msg.sender != localTimelock) revert Unauthorized();
        address oldFxChild = fxChild;
        fxChild = newFxChild;
        emit NewFxChild(oldFxChild, newFxChild);
    }

    function processMessageFromRoot(
        uint256 stateId,
        address messageSender,
        bytes calldata data
    ) public override {
        if (msg.sender != fxChild) revert InvalidChild();
        processMessage(messageSender, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "../ITimelock.sol";

contract BaseBridgeReceiver {
    error AlreadyInitialized();
    error BadData();
    error InvalidProposalId();
    error ProposalNotQueued();
    error TransactionAlreadyQueued();
    error Unauthorized();

    event Initialized(address indexed govTimelock, address indexed localTimelock);
    event NewLocalTimelock(address indexed oldLocalTimelock, address indexed newLocalTimelock);
    event NewGovTimelock(address indexed oldGovTimelock, address indexed newGovTimelock);
    event ProposalCreated(address indexed messageSender, uint id, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, uint eta);
    event ProposalExecuted(uint id);

    address public govTimelock;
    address public localTimelock;
    bool public initialized;

    uint public proposalCount;

    struct Proposal {
        uint id;
        address[] targets;
        uint[] values;
        string[] signatures;
        bytes[] calldatas;
        uint eta;
        bool executed;
    }

    mapping (uint => Proposal) public proposals;

    enum ProposalState {
        Queued,
        Expired,
        Executed
    }

    function initialize(address _govTimelock, address _localTimelock) external {
        if (initialized) revert AlreadyInitialized();
        govTimelock = _govTimelock;
        localTimelock = _localTimelock;
        initialized = true;
        emit Initialized(_govTimelock, _localTimelock);
    }

    function acceptLocalTimelockAdmin() external {
        if (msg.sender != localTimelock) revert Unauthorized();
        ITimelock(localTimelock).acceptAdmin();
    }

    function setLocalTimelock(address newTimelock) public {
        if (msg.sender != localTimelock) revert Unauthorized();
        address oldLocalTimelock = localTimelock;
        localTimelock = newTimelock;
        emit NewLocalTimelock(oldLocalTimelock, newTimelock);
    }

    function setGovTimelock(address newTimelock) public {
        if (msg.sender != localTimelock) revert Unauthorized();
        address oldGovTimelock = govTimelock;
        govTimelock = newTimelock;
        emit NewGovTimelock(oldGovTimelock, newTimelock);
    }

    function processMessage(
        address messageSender,
        bytes calldata data
    ) internal {
        if (messageSender != govTimelock) revert Unauthorized();

        address[] memory targets;
        uint256[] memory values;
        string[] memory signatures;
        bytes[] memory calldatas;

        (targets, values, signatures, calldatas) = abi.decode(
            data,
            (address[], uint256[], string[], bytes[])
        );

        if (values.length != targets.length) revert BadData();
        if (signatures.length != targets.length) revert BadData();
        if (calldatas.length != targets.length) revert BadData();

        uint delay = ITimelock(localTimelock).delay();
        uint eta = block.timestamp + delay;

        for (uint8 i = 0; i < targets.length; ) {
            if (ITimelock(localTimelock).queuedTransactions(keccak256(abi.encode(targets[i], values[i], signatures[i], calldatas[i], eta)))) revert TransactionAlreadyQueued();
            ITimelock(localTimelock).queueTransaction(targets[i], values[i], signatures[i], calldatas[i], eta);
            unchecked { i++; }
        }

        proposalCount++;
        Proposal memory proposal = Proposal({
            id: proposalCount,
            targets: targets,
            values: values,
            signatures: signatures,
            calldatas: calldatas,
            eta: eta,
            executed: false
        });

        proposals[proposal.id] = proposal;
        emit ProposalCreated(messageSender, proposal.id, targets, values, signatures, calldatas, eta);
    }

    function executeProposal(uint proposalId) external {
        if (state(proposalId) != ProposalState.Queued) revert ProposalNotQueued();
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            ITimelock(localTimelock).executeTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }
        emit ProposalExecuted(proposalId);
    }

    function state(uint proposalId) public view returns (ProposalState) {
        if (proposalId > proposalCount || proposalId == 0) revert InvalidProposalId();
        Proposal memory proposal = proposals[proposalId];
        if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= (proposal.eta + ITimelock(localTimelock).GRACE_PERIOD())) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @dev Interface for interacting with a Timelock
 */
interface ITimelock {
    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint indexed newDelay);
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);

    function GRACE_PERIOD() virtual external view returns (uint);
    function MINIMUM_DELAY() virtual external view returns (uint);
    function MAXIMUM_DELAY() virtual external view returns (uint);

    function admin() virtual external view returns (address);
    function pendingAdmin() virtual external view returns (address);
    function setPendingAdmin(address pendingAdmin_) virtual external;
    function acceptAdmin() virtual external;

    function delay() virtual external view returns (uint);
    function setDelay(uint delay) virtual external;

    function queuedTransactions(bytes32 txHash) virtual external returns (bool);
    function queueTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) virtual external returns (bytes32);
    function cancelTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) virtual external;
    function executeTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) virtual external payable returns (bytes memory);
}