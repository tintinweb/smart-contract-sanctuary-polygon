/**
 *Submitted for verification at polygonscan.com on 2023-03-11
*/

// File: contracts/Context.sol

pragma solidity 0.6.6;


contract Context {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

// File: contracts/BasicAccessControl.sol

pragma solidity 0.6.6;

contract BasicAccessControl is Context {
    address payable public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping (address => bool) public moderators;
    bool public isMaintaining = false;

    constructor() public {
        owner = msgSender();
    }

    modifier onlyOwner {
    require(msgSender() == owner);
        _;
    }

    modifier onlyModerators() {
        require(msgSender() == owner || moderators[msgSender()] == true);
        _;
    }

    modifier isActive {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address payable _newOwner) public onlyOwner {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }


    function AddModerator(address _newModerator) public onlyOwner {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        }
    }

    function Kill() public onlyOwner {
        selfdestruct(owner);
    }
}

// File: contracts/EthermonSeasonTransformSetting.sol

/**
 *Submitted for verification at Etherscan.io on 2018-08-28
*/

pragma solidity 0.6.6;

// copyright [email protected]

contract EthermonSeasonTransformSetting is BasicAccessControl {
    mapping(uint32 => uint8) public transformLevels;
    mapping(uint32 => uint32) public transformClasses;

    function setConfigClass(uint32 _classId, uint8 _transformLevel, uint32 _tranformClass) onlyModerators public {
        transformLevels[_classId] = _transformLevel;
        transformClasses[_classId] = _tranformClass;
    }

    function getTransformInfo(uint32 _classId) view external returns(uint32 transformClassId, uint8 level) {
        transformClassId = transformClasses[_classId];
        level = transformLevels[_classId];
    }

    function getClassTransformInfo(uint32 _classId) view external returns(uint8 transformLevel, uint32 transformCLassId) {
        transformLevel = transformLevels[_classId];
        transformCLassId = transformClasses[_classId];
    }
}