/**
 *Submitted for verification at polygonscan.com on 2022-12-19
*/

// File: contracts/Context.sol

pragma solidity 0.6.6;

contract Context {
    function msgSender() internal view returns (address payable sender) {
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
    mapping(address => bool) public moderators;
    bool public isMaintaining = true;

    constructor() public {
        owner = msgSender();
    }

    modifier onlyOwner() {
        require(msgSender() == owner);
        _;
    }

    modifier onlyModerators() {
        require(msgSender() == owner || moderators[msgSender()] == true);
        _;
    }

    modifier isActive() {
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
        } else {
            delete moderators[_newModerator];
            totalModerators -= 1;
        }
    }

    function UpdateMaintaining(bool _isMaintaining) public onlyOwner {
        isMaintaining = _isMaintaining;
    }

    function Kill() public onlyOwner {
        selfdestruct(owner);
    }
}

// File: contracts/EthermonWeightData.sol

pragma solidity 0.6.6;

contract EthermonWeightData is BasicAccessControl {
    mapping(uint32 => uint256) classWeight;

    constructor() public {}

    function setClassWeight(uint32 _classId, uint256 _weight)
        external
        onlyModerators
    {
        require(_classId > 0, "Class is invalid.");
        require(_weight > 0, "Weight is invalid.");

        classWeight[_classId] = _weight;
    }

    function getClassWeight(uint32 _classId)
        public
        view
        returns (uint256 weight)
    {
        return classWeight[_classId];
    }

    function deleteClassWeight(uint32 _classId) external onlyModerators {
        require(_classId > 0, "Invalid class id provided");
        delete classWeight[_classId];
    }
}