// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {FxBaseChildTunnel} from "../fx-portal/tunnel/FxBaseChildTunnel.sol";
import {SecuredBase} from "../0xbb/SecuredBase.sol";

struct stake {
    uint128 tokenId;
    uint128 stakedTs;
}

contract TestContractPoly is FxBaseChildTunnel, SecuredBase { 
    error AlreadyBound();
    error NotBound();
    error NotAnOwner();

    event Bound(address indexed bounder, uint[] _id);
    event Unbound(address indexed bounder, uint[] _id);
    
    mapping(address => stake[]) walletToStakes;
    mapping(uint => bool) idToBound;
    mapping(uint => address) idToStaker;
    mapping(uint => uint) idToWalletIndex;

    bytes32 public constant BOUND = keccak256("BOUND");
    bytes32 public constant UNBOUND = keccak256("UNBOUND");

    constructor(
        address _fxChild
    ) FxBaseChildTunnel(_fxChild) {}

    function testtwo(uint[] calldata tokenIds) external {
        _unbound(abi.encode(msg.sender, tokenIds));
    }

    function testone(uint[] calldata tokenIds) external {
        _bound(abi.encode(msg.sender, tokenIds));
    }

    function _unbound(bytes memory stakeData) internal {
        (address staker, uint256[] memory tokenIds) = abi.decode(
            stakeData,
            (address, uint256[])
        );

        for (uint i;i<tokenIds.length;) {
            if (idToStaker[tokenIds[i]] != staker) revert NotAnOwner();
            if (idToBound[tokenIds[i]] == false) {
                unchecked { ++i; }
                continue;
            }

            _removeToken(staker, tokenIds[i]);
            unchecked { ++i; }
        }

        emit Unbound(staker, tokenIds);
    }

    function _bound(bytes memory stakeData) internal {
        (address staker, uint256[] memory tokenIds) = abi.decode(
            stakeData,
            (address, uint256[])
        );

        for (uint i;i<tokenIds.length;) {
            if (idToBound[tokenIds[i]]) {
                if (staker == idToStaker[tokenIds[i]]) {
                    continue;
                }
                revert AlreadyBound();
            }

            _addToken(staker, uint128(tokenIds[i]));
            unchecked { ++i; }
        }

        emit Bound(staker, tokenIds);
    }

    function _addToken(address wallet, uint128 tokenId) internal {
        idToBound[tokenId]=true;
        idToWalletIndex[tokenId]=walletToStakes[wallet].length;
        walletToStakes[wallet].push(stake(tokenId, uint128(block.timestamp)));
        idToStaker[tokenId]=wallet;
    }

    function _removeToken(address wallet, uint tokenId) internal {
        idToBound[tokenId]=false;
        uint index = idToWalletIndex[tokenId];
        
        // Delete stake information
        stake memory lastStake=walletToStakes[wallet][walletToStakes[wallet].length-1];
        walletToStakes[wallet][index]=lastStake;
        idToWalletIndex[lastStake.tokenId]=index;
        walletToStakes[wallet].pop();
        idToStaker[tokenId]=address(0);
    }

    function sendMessageToRoot(bytes memory message) internal {
        //_sendMessageToRoot(message);
        // Not used
    }

    function _processMessageFromRoot(
        uint256,
        address sender,
        bytes memory data
    ) internal override validateSender(sender) {
        (bytes32 cmdType, bytes memory cmdData) = abi.decode(data, (bytes32, bytes));

        if (cmdType == BOUND) {
            _bound(cmdData);
        } else if (cmdType == UNBOUND) {
            _unbound(cmdData);
        }
        else {
            revert("FxERC20ChildTunnel: INVALID_CMD");
        }
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

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor {
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
    function setFxRootTunnel(address _fxRootTunnel) external virtual {
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
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
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

pragma solidity ^0.8.11;

contract SecuredBase {
    address public owner;

    error NoContractsAllowed();
    error NotContractOwner();
    
    constructor() { 
        owner=msg.sender;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner=newOwner;
    }

    modifier onlyOwner() {
        if (msg.sender!=owner) revert NotContractOwner();
        _;
    }

    modifier noContracts() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly { size := extcodesize(acc)}

        if ((msg.sender != tx.origin) || (size != 0)) revert NoContractsAllowed();
        _;
    }
}