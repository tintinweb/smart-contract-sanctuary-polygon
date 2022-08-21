/**
 *Submitted for verification at polygonscan.com on 2022-08-20
*/

// File: contracts/EthermonEnum.sol

pragma solidity 0.6.6;

contract EthermonEnum {
    enum ResultCode {
        SUCCESS,
        ERROR_CLASS_NOT_FOUND,
        ERROR_LOW_BALANCE,
        ERROR_SEND_FAIL,
        ERROR_NOT_TRAINER,
        ERROR_NOT_ENOUGH_MONEY,
        ERROR_INVALID_AMOUNT
    }

    enum ArrayType {
        CLASS_TYPE,
        STAT_STEP,
        STAT_START,
        STAT_BASE,
        OBJ_SKILL
    }

    enum BattleResult {
        CASTLE_WIN,
        CASTLE_LOSE,
        CASTLE_DESTROYED
    }

    enum PropertyType {
        ANCESTOR,
        XFACTOR
    }
}

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
    mapping(address => bool) public moderators;
    bool public isMaintaining = false;

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

    function Kill() public onlyOwner {
        selfdestruct(owner);
    }
}

// File: contracts/EthermonRarityData.sol

pragma solidity 0.6.6;


contract EthermonRarityData is BasicAccessControl {
    string[] ethRarity = ["C", "UC", "R", "L", "M", "NPC"];
    string[] maticRarity = ["C", "UC", "R", "L", "M", "NPC"];

    mapping(uint32 => string) classRarityMatic;
    mapping(uint32 => string) classRarityEth;
    mapping(uint32 => uint256) reRollPriceEmon;

    function setRerollPrice(uint32 class_id, uint256 _price_in_emon)
        external
        onlyModerators
    {
        reRollPriceEmon[class_id] = _price_in_emon;
    }

    function getRerollPrice(uint32 _classId)
        public
        view
        returns (uint256 price_in_emon)
    {
        return reRollPriceEmon[_classId];
    }

    function getMaticRarityString(uint8 index)
        public
        view
        returns (string memory)
    {
        return maticRarity[index];
    }

    function getEthRarityString(uint8 index)
        public
        view
        returns (string memory)
    {
        return ethRarity[index];
    }

    function getKey(string[] memory rarityArray, string memory rarity)
        internal
        pure
        returns (int8)
    {
        int8 key = -1;
        for (uint8 i; i < rarityArray.length; i++) {
            if (
                keccak256(abi.encodePacked(rarityArray[i])) ==
                keccak256(abi.encodePacked(rarity))
            ) {
                key = int8(i);
            }
        }
        return key;
    }

    function addToMaticRarity(string calldata rarity) external onlyModerators {
        maticRarity.push(rarity);
    }

    function addToEthRarity(string calldata rarity) external onlyModerators {
        ethRarity.push(rarity);
    }

    function deleteAllMaticRarity() external onlyModerators {
        delete maticRarity;
    }

    function deleteAllEthRarity() external onlyModerators {
        delete ethRarity;
    }

    function getClassRarityMatic(uint32 class_id)
        public
        view
        returns (string memory)
    {
        return classRarityMatic[class_id];
    }

    function getClassRarityEth(uint32 class_id)
        public
        view
        returns (string memory)
    {
        return classRarityEth[class_id];
    }

    function assignClassRarityMatic(uint32 class_id, string calldata rarity)
        external
        onlyModerators
    {
        int8 key = getKey(maticRarity, rarity);
        if (key == -1) {
            revert();
        }
        classRarityMatic[class_id] = rarity;
    }

    function assignClassRarityEth(uint32 class_id, string calldata rarity)
        external
        onlyModerators
    {
        int8 key = getKey(ethRarity, rarity);
        if (key == -1) {
            revert();
        }
        classRarityEth[class_id] = rarity;
    }
}