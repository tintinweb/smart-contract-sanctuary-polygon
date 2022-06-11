// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./DIDOwnership.sol";

contract DID is IDID, DIDOwnership {

    address public factory;

    constructor() {
        factory = msg.sender;
    }

    function initialize(address didOwner_, address[] memory alternativeOwners_) public override {
        require(msg.sender == factory, "Err: FORBIDDEN"); // sufficient check
        primaryOwner = didOwner_;
        alternativeOwners = alternativeOwners_;
    }

    function execute(address to, uint256 value, bytes calldata data) external override returns (bool) {
        address sender = msg.sender;


        emit Execute(to, sender, 0, value);
        
        selfExecuting();
    }

    function proxyExecute(address to, uint256 value, bytes calldata data, uint256 nonce, bytes memory signatures) external override returns (bool) {

    }

    function encodeTransactionData(address to, uint256 value, bytes calldata data, uint256 nonce) external {

    }

    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        uint256 nonce
        ) external {

        }

    function checkSignature(
        bytes32 messageHash,
        bytes memory data,
        uint256 nonce,
        bytes memory signatures,
        uint256 requiredSignatures
        ) external returns (bool) {

        }

    function getVersion() external pure returns (uint8) {
        return 1;
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }

    function domainSeparator() external view returns (bytes32) {

    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/IDID.sol";


contract DIDOwnership {

    address public primaryOwner;
    address[] public alternativeOwners;

    function getAlternativeOwners() public view returns (address[] memory) {
        return alternativeOwners;
    }

    modifier isPrimaryOwner() {
        require(primaryOwner == msg.sender, "DID: call limited to the primary owner.");
        _;
    }

    modifier isOwner() {
        require(primaryOwner == msg.sender || isDIDAlternativeOwner(msg.sender), "DID: call limited to the owner.");
        _;
    }

    function isDIDAlternativeOwner(address addr) public view returns (bool) {
        bool _isOwner = false;
        for (uint256 i = 0; i < alternativeOwners.length; i++) {
            if (alternativeOwners[i] == addr) {
                _isOwner = true;
                break;
            }
        }
        return _isOwner;
    }


    
    event AddAlternativeOwner(address sender, address indexed theOwner);
    event DeleteAlternativeOwner(address sender, address indexed theOwner);

    function addAlternativeOwner(address newOwner) external emptyAddress(newOwner) returns (bool) {
        require (!isDIDAlternativeOwner(newOwner), "DIDOwnership: the owner exists");

        alternativeOwners.push(newOwner);
        emit AddAlternativeOwner(msg.sender, newOwner);
        
        selfExecuting();
        return true;
    }

    function deleteAlternativeOwner(address theOwner) external isPrimaryOwner emptyAddress(theOwner) returns (bool) {
        bool _isOwner = false;
        for (uint256 i = 0; i < alternativeOwners.length; i++) {
            if (alternativeOwners[i] == theOwner) {
                _isOwner = true;
                delete alternativeOwners[i];
                break;
            }
        } 

        require (_isOwner, "DIDOwnership: the owner not exists");
        emit DeleteAlternativeOwner(msg.sender, theOwner);
        
        selfExecuting();
        return true;
    }


    struct OwnershipTransaction {
        address initiator;
        address newOwner;
        uint256 startTime;
        uint256 durationTime;
    }

    mapping(address => OwnershipTransaction) _ownershipTransaction;

    event SubmitOwnershipTransfer(address sender, address indexed newOwner, uint256 startTime, uint256 indexed durationTime);
    event TerminateOwnershipTransfer(address sender, address indexed newOwner, uint256 startTime, uint256 indexed durationTime, uint256 terminatedTime);
    event ConfirmOwnershipTransfer(address sender, address indexed oldOwner, address indexed newOwner, uint256 startTime, uint256 indexed durationTime, uint256 confirmedTime);

    /***  紧急联系人: 同时只能有一个新owner可以被转移  ***/

    // 1.发起owner身份转移到新地址，允许发起覆盖操作
    function submitOwnershipTransfer(address newOwner, uint256 durationTime) external isOwner emptyAddress(newOwner) returns (bool) {
        uint256 currentTime = block.timestamp;
        _ownershipTransaction[address(this)] = OwnershipTransaction(msg.sender, newOwner, currentTime, durationTime);
        emit SubmitOwnershipTransfer(msg.sender, newOwner, currentTime, durationTime);
        return true;
    }

    // 2.终止owner身份转移
    function terminateOwnershipTransfer() external isOwner returns (bool) {
        OwnershipTransaction memory _tx = _ownershipTransaction[address(this)];
        delete _ownershipTransaction[address(this)];
        emit TerminateOwnershipTransfer(msg.sender, _tx.newOwner, _tx.startTime, _tx.durationTime, block.timestamp);
        return true;
    }

    // 3.新owner身份确认转移
    function confirmOwnershipTransfer() public isOwner returns (bool) {
        OwnershipTransaction memory _tx = _ownershipTransaction[address(this)];

        bool isDue = _tx.startTime + _tx.durationTime > block.timestamp;
        if (_tx.durationTime == 0 || isDue) {
            if (isDue) {
                delete _ownershipTransaction[address(this)];
            }
            return false;
        }
        
        address oldAddr = primaryOwner;
        primaryOwner = _tx.newOwner;
        delete _ownershipTransaction[address(this)];
        emit ConfirmOwnershipTransfer(msg.sender, oldAddr, _tx.newOwner, _tx.startTime, _tx.durationTime, block.timestamp);

        return true;
    }

    // 4.获取当前新owner身份转移的状态
    function getOwnershipTransferringStatus() external view returns (OwnershipTransaction memory) {
        return _ownershipTransaction[address(this)];
    }


    function selfExecuting() internal {
        confirmOwnershipTransfer();
    }

    modifier emptyAddress(address addr_) {
        require(addr_ != address(0), "DID: Empty address");
        _;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;


interface IDID {

    event Execute(address indexed to, address indexed sender, uint256 indexed nonce, uint256 value);


    function initialize(address didOwner, address[] memory alternativeOwners) external;

    function execute(address to, uint256 value, bytes calldata data) external returns (bool);

    function proxyExecute(address to, uint256 value, bytes calldata data, uint256 nonce, bytes memory signatures) external returns (bool);

    function getVersion() external pure returns (uint8);
    
}