/**
 *Submitted for verification at polygonscan.com on 2023-06-27
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/*
 * @title Collabs Minter
 * @author 0xSumo
 */

/// OwnControll by 0xSumo
abstract contract OwnControll {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AdminSet(bytes32 indexed controllerType, bytes32 indexed controllerSlot, address indexed controller, bool status);
    address public owner;
    mapping(bytes32 => mapping(address => bool)) internal admin;
    constructor() { owner = msg.sender; }
    modifier onlyOwner() { require(owner == msg.sender, "only owner");_; }
    modifier onlyAdmin(string memory type_) { require(isAdmin(type_, msg.sender), "only admin");_; }
    function transferOwnership(address newOwner) external onlyOwner { emit OwnershipTransferred(owner, newOwner); owner = newOwner; }
    function setAdmin(string calldata type_, address controller, bool status) external onlyOwner { bytes32 typeHash = keccak256(abi.encodePacked(type_)); admin[typeHash][controller] = status; emit AdminSet(typeHash, typeHash, controller, status); }
    function isAdmin(string memory type_, address controller) public view returns (bool) { bytes32 typeHash = keccak256(abi.encodePacked(type_)); return admin[typeHash][controller]; }
}

interface IFxMessageProcessor {
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
}

abstract contract FxBaseChildTunnel is IFxMessageProcessor {

    event MessageSent(bytes message);
    address public fxChild;
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    function setFxRootTunnel(address _fxRootTunnel) external virtual {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory message) internal virtual;
}

interface IHOPE {
    function increasePoints(address address_, uint256 amount_) external;
    function decreasePoints(address address_, uint256 amount_) external;
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract Minter is FxBaseChildTunnel, OwnControll {
    IHOPE public HOPE = IHOPE(0xa50eDDc5103911cfDD67e612874885eF96d3D109);
    uint256 public constant pointAmount = 2 ether;
    constructor() FxBaseChildTunnel(0xCf73231F28B7331BBe3124B907840A94851f9f11) {}

    function redeemForCollabs(address to_, uint256 amount) external {
        HOPE.decreasePoints(to_, pointAmount);
        _sendMessageToRoot(abi.encode(to_, amount));

        //bytes memory message = abi.encode(WITHDRAW, abi.encode(rootToken, childToken, msg.sender, id, amount, data));
        //_sendMessageToRoot(message);
    }
    function updateFxRootTunnel(address _fxRootTunnel) external onlyAdmin("ADMIN") {
        fxRootTunnel = _fxRootTunnel;
    }
    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory message) internal override validateSender(sender) {}
}