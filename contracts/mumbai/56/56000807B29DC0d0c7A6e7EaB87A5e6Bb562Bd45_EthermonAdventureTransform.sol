/**
 *Submitted for verification at polygonscan.com on 2023-05-30
*/

// File: contracts/EthermonSeasonTransformData.sol

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

// File: contracts/EthermonDataBase.sol

pragma solidity 0.6.6;

interface EtheremonDataBase {
    // write
    function withdrawEther(address _sendTo, uint256 _amount)
        external
        returns (EthermonEnum.ResultCode);

    function addElementToArrayType(
        EthermonEnum.ArrayType _type,
        uint64 _id,
        uint8 _value
    ) external returns (uint256);

    function updateIndexOfArrayType(
        EthermonEnum.ArrayType _type,
        uint64 _id,
        uint256 _index,
        uint8 _value
    ) external returns (uint256);

    function setMonsterClass(
        uint32 _classId,
        uint256 _price,
        uint256 _returnPrice,
        bool _catchable
    ) external returns (uint32);

    function addMonsterObj(
        uint32 _classId,
        address _trainer,
        string calldata _name
    ) external returns (uint64);

    function setMonsterObj(
        uint64 _objId,
        string calldata _name,
        uint32 _exp,
        uint32 _createIndex,
        uint32 _lastClaimIndex
    ) external;

    function increaseMonsterExp(uint64 _objId, uint32 amount) external;

    function decreaseMonsterExp(uint64 _objId, uint32 amount) external;

    function removeMonsterIdMapping(address _trainer, uint64 _monsterId)
        external;

    function addMonsterIdMapping(address _trainer, uint64 _monsterId) external;

    function clearMonsterReturnBalance(uint64 _monsterId)
        external
        returns (uint256 amount);

    function collectAllReturnBalance(address _trainer)
        external
        returns (uint256 amount);

    function transferMonster(
        address _from,
        address _to,
        uint64 _monsterId
    ) external returns (EthermonEnum.ResultCode);

    function addExtraBalance(address _trainer, uint256 _amount)
        external
        returns (uint256);

    function deductExtraBalance(address _trainer, uint256 _amount)
        external
        returns (uint256);

    function setExtraBalance(address _trainer, uint256 _amount) external;

    // read
    function totalMonster() external view returns (uint256);

    function totalClass() external view returns (uint32);

    function getSizeArrayType(EthermonEnum.ArrayType _type, uint64 _id)
        external
        view
        returns (uint256);

    function getElementInArrayType(
        EthermonEnum.ArrayType _type,
        uint64 _id,
        uint256 _index
    ) external view returns (uint8);

    function getMonsterClass(uint32 _classId)
        external
        view
        returns (
            uint32 classId,
            uint256 price,
            uint256 returnPrice,
            uint32 total,
            bool catchable
        );

    function getMonsterObj(uint64 _objId)
        external
        view
        returns (
            uint64 objId,
            uint32 classId,
            address trainer,
            uint32 exp,
            uint32 createIndex,
            uint32 lastClaimIndex,
            uint256 createTime
        );

    function getMonsterName(uint64 _objId)
        external
        view
        returns (string memory name);

    function getExtraBalance(address _trainer) external view returns (uint256);

    function getMonsterDexSize(address _trainer)
        external
        view
        returns (uint256);

    function getMonsterObjId(address _trainer, uint256 index)
        external
        view
        returns (uint64);

    function getExpectedBalance(address _trainer)
        external
        view
        returns (uint256);

    function getMonsterReturn(uint64 _objId)
        external
        view
        returns (uint256 current, uint256 total);
}

// File: contracts/EthermonAdventureTransform.sol

pragma solidity ^0.6.0;


interface EtheremonTradeInterface {
    function isOnTrading(uint64 _objId) external view returns (bool);
}

interface EtheremonMonsterNFTInterface {
    function mintMonster(
        uint32 _classId,
        address _trainer,
        string calldata _name
    ) external returns (uint256);

    function burnMonster(uint64 _tokenId) external;
}

interface EtheremonTransformSettingInterface {
    function getRandomClassId(uint256 _seed) external view returns (uint32);

    function getTransformInfo(
        uint32 _classId
    ) external view returns (uint32 transformClassId, uint8 level);

    function getClassTransformInfo(
        uint32 _classId
    )
        external
        view
        returns (
            uint8 layingLevel,
            uint8 layingCost,
            uint8 transformLevel,
            uint32 transformCLassId
        );
}

contract EthermonAdventureTransform is BasicAccessControl {
    address public transformSettingContract;
    address public seasonTransformDataContract;
    address public monsterNFTContract;
    address public tradeContract;
    address public dataContract;

    event EventTransform(
        address indexed trainer,
        uint256 oldObjId,
        uint256 newObjId
    );

    struct MonsterObjAcc {
        uint64 monsterId;
        uint32 classId;
        address trainer;
        string name;
        uint32 exp;
        uint32 createIndex;
        uint32 lastClaimIndex;
        uint256 createTime;
    }

    struct BasicObjInfo {
        uint32 classId;
        address owner;
        uint8 level;
        uint32 exp;
    }

    constructor(
        address _transformSettingContract,
        address _seasonTransformDataContract,
        address _monsterNFTContract,
        address _tradeContract,
        address _dataContract
    ) public {
        transformSettingContract = _transformSettingContract;
        seasonTransformDataContract = _seasonTransformDataContract;
        monsterNFTContract = _monsterNFTContract;
        tradeContract = _tradeContract;
        dataContract = _dataContract;
    }

    function setContracts(
        address _transformSettingContract,
        address _seasonTransformDataContract,
        address _monsterNFTContract,
        address _tradeContract,
        address _dataContract
    ) external {
        transformSettingContract = _transformSettingContract;
        seasonTransformDataContract = _seasonTransformDataContract;
        monsterNFTContract = _monsterNFTContract;
        tradeContract = _tradeContract;
        dataContract = _dataContract;
    }

    function getObjClass(uint64 _objId) public view returns (uint32, address) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (
            obj.monsterId,
            obj.classId,
            obj.trainer,
            obj.exp,
            obj.createIndex,
            obj.lastClaimIndex,
            obj.createTime
        ) = data.getMonsterObj(_objId);
        return (obj.classId, obj.trainer);
    }

    function transform(
        uint64 _objId,
        uint32 _classId,
        address _owner
    ) external onlyModerators {
        EthermonSeasonTransformData transformData = EthermonSeasonTransformData(
            seasonTransformDataContract
        );
        require(_owner != address(0), "Wrong address");
        if (transformData.getTranformedId(_objId) > 0) revert();

        if (tradeContract != address(0)) {
            EtheremonTradeInterface trade = EtheremonTradeInterface(
                tradeContract
            );
            if (trade.isOnTrading(_objId)) revert();
        }

        uint32 transformClass;
        uint8 transformLevel;
        (transformClass, transformLevel) = EtheremonTransformSettingInterface(
            transformSettingContract
        ).getTransformInfo(_classId);
        if (transformClass == 0 || transformLevel == 0) revert();

        EtheremonMonsterNFTInterface monsterNFT = EtheremonMonsterNFTInterface(
            monsterNFTContract
        );
        uint256 newObjId = monsterNFT.mintMonster(
            transformClass,
            _owner,
            "..name me..."
        );
        monsterNFT.burnMonster(_objId);

        transformData.setTranformed(_objId, uint64(newObjId));
        emit EventTransform(_owner, _objId, newObjId);
    }
}