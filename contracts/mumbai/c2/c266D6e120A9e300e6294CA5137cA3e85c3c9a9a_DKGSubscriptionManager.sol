// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

library LibNuCypher {
    function toPolicyId(
        string memory label,
        string memory aliceVerifyingKey,
        string memory bobVerifyingKey
    ) internal pure returns (bytes16 policyId) {
        return
            bytes16(
                keccak256(
                    abi.encodePacked(aliceVerifyingKey, bobVerifyingKey, label)
                )
            );
    }

    function toLabel(string memory labelSuffix, address requestor)
        internal
        view
        returns (string memory label)
    {
        return
            string(
                abi.encodePacked(
                    _toString(requestor),
                    _toString(block.chainid),
                    labelSuffix
                )
            );
    }

    function _toString(address addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(addr)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function _toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {LibNuCypher} from "../LibNuCypher.sol";

struct PolicyRequest {
    uint16 size;
    uint16 threshold;
    // TODO: Keys are 33 bytes. Easier to handle as strings
    string verifyingKey;
    string decryptingKey;
    uint32 startTimestamp;
    uint32 endTimestamp;
}

contract DKGSubscriptionManager is Ownable {
    using LibNuCypher for string;

    // ERRORS
    error NotSubscriptionOwner(uint256 subscriptionId, address caller);
    error NotSubscriptionConsumer(uint256 subscriptionId, address caller);
    error InvalidFunding(uint256 fundsRequired, uint256 fundsProvided);
    error SubscriptionExpired(uint256 subscriptionId);

    // EVENTS
    event SubscriptionCreated(
        uint256 indexed subscriptionId,
        address indexed owner,
        uint16 dkgNodes,
        uint32 endTimestamp
    );
    event ConsumerAdded(
        uint256 indexed subscriptionId,
        address indexed consumer
    );
    event PolicyRequested(
        uint256 indexed subscriptionId,
        address indexed consumer,
        bytes16 indexed policyId,
        string label,
        PolicyRequest policyRequest
    );

    // TODO: Pack Struct
    struct SubscriptionConfig {
        address payable owner;
        // Security level of dkg
        uint16 dkgNodes;
        // When subscription ends
        uint32 endTimestamp;
        uint16 numConsumers;
    }

    string public verifyingKey;
    // Per-second, per-node service fee rate
    uint256 public feeRate;
    uint256 internal subscriptionNonce;

    mapping(uint256 => SubscriptionConfig) public subscriptions;
    mapping(address => mapping(uint256 => uint256)) public consumers;

    modifier onlySubscriber(uint256 _subscriptionId) {
        if (subscriptions[_subscriptionId].owner != msg.sender) {
            revert NotSubscriptionOwner(_subscriptionId, msg.sender);
        }
        _;
    }

    modifier onlyConsumer(uint256 _subscriptiondId) {
        if (consumers[msg.sender][_subscriptiondId] == 0) {
            revert NotSubscriptionConsumer(_subscriptiondId, msg.sender);
        }
        _;
    }

    constructor(string memory _verifyingKey, uint256 _feeRate) {
        verifyingKey = _verifyingKey;
        feeRate = _feeRate;
    }

    function createSubscription(
        uint16 _dkgNodes,
        // Duration of subscription
        uint32 _duration
    ) external payable returns (uint256 subscriptionId) {
        // TODO: Check payment
        uint256 requiredPayment = _dkgNodes * _duration * feeRate;

        if (requiredPayment != msg.value) {
            revert InvalidFunding(requiredPayment, msg.value);
        }

        uint32 endTimestamp = uint32(block.timestamp + _duration);

        // Save config
        subscriptions[subscriptionNonce] = SubscriptionConfig(
            payable(msg.sender),
            _dkgNodes,
            endTimestamp,
            1
        );
        // Add owner as consumer
        consumers[msg.sender][subscriptionNonce] = 1;

        subscriptionNonce += 1;
        emit SubscriptionCreated(
            subscriptionId,
            msg.sender,
            _dkgNodes,
            endTimestamp
        );
        emit ConsumerAdded(subscriptionId, msg.sender);
    }

    // function extendSubscription(uint256 _subscriptionId, uint256 _duration)
    //     external
    //     payable
    //     onlySubscriber(_subscriptionId)
    // {
    //     // TODO: Emit Event
    // }

    /**
     *
     */
    function addConsumer(uint256 _subscriptionId, address _consumer)
        external
        onlySubscriber(_subscriptionId)
    {
        // TODO: Set max consumers per subscription
        consumers[_consumer][_subscriptionId] = 1;
        subscriptions[_subscriptionId].numConsumers += 1;

        emit ConsumerAdded(_subscriptionId, _consumer);
    }

    /**
     * @dev consumer is responsible for making sure that these parameters line up with
     * @dev polcy created on PRE SubscriptionManager
     */
    function requestPolicy(
        uint256 _subscriptionId,
        string memory _labelSuffix,
        // TODO: Check the size of these keys
        PolicyRequest memory _policyRequest
    )
        external
        onlyConsumer(_subscriptionId)
        returns (bytes16 policyId, string memory label)
    {
        if (subscriptions[_subscriptionId].endTimestamp < block.timestamp) {
            revert SubscriptionExpired(_subscriptionId);
        }

        // Requestor provides a uuid for their label. We append it to the
        // requesting address so we dont get conflicting labels
        label = _labelSuffix.toLabel(msg.sender);

        // Derive the policy id by hashing label, alice verifying key, and bob verifying key
        // This doesn't technically need to be on chain but is a big convience since
        // the user will most likely directly call the PRE createPolicy method after this.
        policyId = label.toPolicyId(verifyingKey, _policyRequest.verifyingKey);

        emit PolicyRequested(
            _subscriptionId,
            msg.sender,
            policyId,
            label,
            _policyRequest
        );
    }

    function sweep(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool sent, ) = recipient.call{value: balance}("");
        require(sent, "Failed transfer");
    }
}