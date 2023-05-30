// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IZKBridgeEntrypoint.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Mailer
/// @notice An example contract for sending messages to other chains, using the ZKBridgeEntrypoint.
contract Mailer is Ownable {
    /// @notice The ZKBridgeEntrypoint contract, which sends messages to other chains.
    IZKBridgeEntrypoint public zkBridgeEntrypoint;

    /// @notice Sequence number of the current emitter
    uint64 private sequence;

    uint256 public maxLength = 200;

    /// @notice Fee for each chain.
    mapping(uint16 => uint256) public fees;

    event MessageSend(
        uint64 indexed sequence,
        uint32 indexed dstChainId,
        address indexed dstAddress,
        address sender,
        address recipient,
        string message
    );
    event NewFee(uint16 chainId, uint256 fee);

    constructor(address _zkBridgeEntrypoint) {
        zkBridgeEntrypoint = IZKBridgeEntrypoint(_zkBridgeEntrypoint);
    }

    /// @notice Sends a message to a destination MessageBridge.
    /// @param dstChainId The chain ID where the destination MessageBridge.
    /// @param dstAddress The address of the destination MessageBridge.
    /// @param recipient Recipient of the target chain message.
    /// @param message The message to send.
    function sendMessage(
        uint16 dstChainId,
        address dstAddress,
        address recipient,
        string memory message
    ) external payable {
        require(msg.value >= fees[dstChainId], "Insufficient Fee");
        require(
            bytes(message).length <= maxLength,
            "Maximum message length exceeded."
        );
        bytes memory payload = abi.encode(msg.sender, recipient, message);

        uint64 _sequence = zkBridgeEntrypoint.send(
            dstChainId,
            dstAddress,
            payload
        );

        emit MessageSend(
            _sequence,
            dstChainId,
            dstAddress,
            msg.sender,
            recipient,
            message
        );
    }

    /// @notice Allows owner to set a new msg length.
    /// @param _maxLength new msg length.
    function setMsgLength(uint256 _maxLength) external onlyOwner {
        maxLength = _maxLength;
    }

    // @notice Allows owner to claim all fees sent to this contract.
    /// @notice Allows owner to set a new fee.
    /// @param _dstChainId The chain ID where the destination MessageBridge.
    /// @param _fee The new fee to use.
    function setFee(uint16 _dstChainId, uint256 _fee) external onlyOwner {
        require(fees[_dstChainId] != _fee, "Fee has already been set.");
        fees[_dstChainId] = _fee;
        emit NewFee(_dstChainId, _fee);
    }

    /// @notice Allows owner to claim all fees sent to this contract.
    function claimFees() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IZKBridgeEntrypoint {
    /// @notice send a ZKBridge message to the specified address at a ZKBridge endpoint.
    /// @param dstChainId - the destination chain identifier
    /// @param dstAddress - the address on destination chain
    /// @param payload - a custom bytes payload to send to the destination contract
    function send(
        uint16 dstChainId,
        address dstAddress,
        bytes memory payload
    ) external payable returns (uint64 sequence);

    /// @return Current chain id.
    function chainId() external view returns (uint16);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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