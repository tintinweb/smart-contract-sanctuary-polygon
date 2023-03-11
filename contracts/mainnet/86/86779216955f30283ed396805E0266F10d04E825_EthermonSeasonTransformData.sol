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

// File: contracts/EthermonSeasonTransformData.sol

/**
 *Submitted for verification at Etherscan.io on 2018-01-29
*/

pragma solidity 0.6.6;

// copyright [email protected]

contract EthermonSeasonTransformData is  BasicAccessControl {

    mapping(uint64 => uint64) public transformed; //objId -> newObjId

    // only moderators
    /*
    TO AVOID ANY BUGS, WE ALLOW MODERATORS TO HAVE PERMISSION TO ALL THESE FUNCTIONS AND UPDATE THEM IN EARLY BETA STAGE.
    AFTER THE SYSTEM IS STABLE, WE WILL REMOVE OWNER OF THIS SMART CONTRACT AND ONLY KEEP ONE MODERATOR WHICH IS ETHEREMON BATTLE CONTRACT.
    HENCE, THE DECENTRALIZED ATTRIBUTION IS GUARANTEED.
    */
    function setTranformed(uint64 _objId, uint64 _newObjId) onlyModerators external {
        transformed[_objId] = _newObjId;
    }

    function getTranformedId(uint64 _objId) view external returns(uint64) {
        return transformed[_objId];
    }
}