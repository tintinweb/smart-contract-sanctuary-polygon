// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FxBaseChildTunnel} from "./tunnel/FxBaseChildTunnel.sol";
import "../IColorableOwnershipManager.sol";

contract ChildTunnel is FxBaseChildTunnel {
    uint256 public latestStateId;
    address public latestRootMessageSender;
    IColorableOwnershipManager public ownershipManager;

    // TODO: remove before deployment
    event MessageFromRoot(
      address collection,
      uint256 tokenId,
      address newOwner
    );

    constructor(address _fxChild) FxBaseChildTunnel(_fxChild) {}

    function setOwnershipManager(address ownershipManager_)  public {
        ownershipManager = IColorableOwnershipManager(ownershipManager_);
    }

    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory data
    ) internal override validateSender(sender) {
        latestStateId = stateId;
        latestRootMessageSender = sender;

        (bytes memory syncData) = abi.decode(data, (bytes));
        (address collection, uint256 tokenId, address newOwner) = abi.decode(syncData, (address, uint256, address));

        // TODO: remove before deployment
        emit MessageFromRoot(collection, tokenId, newOwner);

        ownershipManager.syncOwnership(collection, tokenId, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../Ownable.sol";

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor, Ownable {
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external onlyOwner {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal virtual;
}

// SPDX-License-Identifier: MIT
// Creator: 0xVinasaur
pragma solidity ^0.8.4;

interface IColorableOwnershipManager {
    function syncOwnership(address collection, uint256 tokenId, address newOwner) external;
    function ownerOf(address collection, uint256 tokenId) external returns(address owner);
    function balanceOf(address collection, address owner) external returns(uint256 tokenId);   
}

// SPDX-License-Identifier: MIT
// Creator: 0xVinasaur
pragma solidity ^0.8.4;

abstract contract Ownable {
    address public owner;
    event OwnershipTransferred(
        address indexed oldOwner_,
        address indexed newOwner_
    );

    constructor() {
        owner = msg.sender;
    }

    function _onlyOwner() internal view {
      require(owner == msg.sender, "Ownable: caller is not the owner");
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _transferOwnership(address newOwner_) internal virtual {
        address _oldOwner = owner;
        owner = newOwner_;
        emit OwnershipTransferred(_oldOwner, newOwner_);
    }

    function transferOwnership(address newOwner_) public virtual onlyOwner {
        require(
            newOwner_ != address(0x0),
            "Ownable: new owner is the zero address!"
        );
        _transferOwnership(newOwner_);
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0x0));
    }
}