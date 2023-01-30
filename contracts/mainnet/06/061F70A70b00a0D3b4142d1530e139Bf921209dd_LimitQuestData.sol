/**
 *Submitted for verification at polygonscan.com on 2023-01-30
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

// File: contracts/Admin/data/LimitQuestData.sol


pragma solidity ^0.8.16;


contract LimitQuestData is Ownable {

    event SetQuestData(uint256 indexed questNo, string indexed name, uint256 timestamp);
    // event SetCharacterData(string indexed name, uint256 indexed tier, uint256 indexed gachaGrade, uint256 classType, uint256 nation, uint256 element, bool isValid);

    struct Quest {
        uint256 questNo;
        string name;
        uint256 mainQuestGroup;
        uint256 subQuestGroup;
        uint256 requireQuest;
        uint256 questCategory;
        uint256 stakingTime;
        uint256 reward;
        uint256 rewardAmount;
        uint256[] nextQuest;
        QuestConditionSlot[] questConditionSlot;
    }

    struct QuestConditionSlot {
        uint256 questType;       // 미션 타입
        uint256 conditionType;   // 미션 조건 타입
        uint256 conditionValue;  // 미션 조건 값
        uint256 conditionAmount; // 개수
    }

    enum QuestCategory {
        NONE,
        MISSION,
        REWARD
    }

    enum MissionType {
        NONE,
        BURN,
        STAKE,
        REGIST
    }

    enum ConditionType {
        NONE,
        CHARACTER,
        CHARACTER_TIER,
        PACK
    }

    enum Difficulty {
        NONE,
        EASY,
        NORMAL,
        HARD,
        VERYHARD
    }

    uint256 lastQuestTableNo = 0;
    uint[] private questNoTable;
    mapping(uint => Quest) questConditionMap;

    function getFirstQuest() public view returns (Quest[] memory) {
        Quest[] memory _quest = new Quest[](10);
        uint arrCnt = 0;
        for (uint i = 0; i < questNoTable.length; i++) {
            Quest memory quest = questConditionMap[questNoTable[i]];
            if (0 == quest.requireQuest) {
                _quest[arrCnt] = quest;
                arrCnt++;
            }
        }
        return _quest;
    }

    function getQuest(uint _questNo) public view returns (Quest memory) {
        return questConditionMap[_questNo];
    }

    function getQuests(uint256 startCount, uint256 endCount) public view returns (Quest[] memory) {
        require((endCount - startCount) < questNoTable.length, "Invalid range");

        Quest[] memory _result = new Quest[](endCount - startCount + 1); 
        for (uint256 i = startCount; i < endCount + 1; i++) {
            _result[i] = questConditionMap[questNoTable[i]];
        }

        return _result;
    }

    function getQuestAll() public view returns (Quest[] memory) {
        Quest[] memory _result = new Quest[](questNoTable.length); 
        for (uint i = 0; i < questNoTable.length; i++) {
            _result[i] = questConditionMap[questNoTable[i]];
        }

        return _result;
    }

    function setQuestData(Quest[] calldata _questData) external onlyOwner {
        for (uint i = 0; i < _questData.length; i++) {
            uint questNo = _questData[i].questNo;

            Quest storage quest_ = questConditionMap[questNo];
            delete quest_.nextQuest;
            delete quest_.questConditionSlot;
            
            quest_.questNo = questNo;
            quest_.name = _questData[i].name;
            quest_.mainQuestGroup = _questData[i].mainQuestGroup;
            quest_.subQuestGroup = _questData[i].subQuestGroup;
            quest_.requireQuest = _questData[i].requireQuest;
            quest_.questCategory = _questData[i].questCategory;
            quest_.stakingTime = _questData[i].stakingTime;
            quest_.reward = _questData[i].reward;
            quest_.rewardAmount = _questData[i].rewardAmount;

            for (uint j = 0; j < _questData[i].nextQuest.length; j++) {
                quest_.nextQuest.push(_questData[i].nextQuest[j]);
            }
            
            for (uint j = 0; j < _questData[i].questConditionSlot.length; j++) {
                quest_.questConditionSlot.push(QuestConditionSlot(
                    _questData[i].questConditionSlot[j].questType,
                    _questData[i].questConditionSlot[j].conditionType,
                    _questData[i].questConditionSlot[j].conditionValue,
                    _questData[i].questConditionSlot[j].conditionAmount
                ));
            }

            setQuestNoTable(questNo);

            emit SetQuestData(questNo, quest_.name, block.timestamp);
        }
    }

    function setQuestNoTable(uint256 questNo) private {
        bool isExist = false;
        if (0 < questNoTable.length) {
            for (uint i = 0; i < questNoTable.length; i++) {
                if (questNo == questNoTable[i]) {
                    isExist = true;
                }
            }
        } else {
            questNoTable.push(questNo);
            isExist = true;
        }

        if (!isExist) {
            questNoTable.push(questNo);
        }
    }

    function deleteQuestData(uint _questNo) public onlyOwner {
        delete questConditionMap[_questNo];

        removeByValue(_questNo, questNoTable);
    }

    function getQuestTableNo() public view returns (uint256[] memory) {
        return questNoTable;
    }

    ////////////////////// remove //////////////////////

    function findUserIndexByValue(uint value, uint[] storage list) private view returns(uint) {
        uint i = 0;
        while (list[i] != value && i <= list.length) {
            i++;
        }
        return i;
    }

    function removeByValue(uint value, uint[] storage list) private {
        uint i = findUserIndexByValue(value, list);
        if (i < list.length) {
            removeByIndex(i, list);
        }
    }

    function removeByIndex(uint i, uint[] storage list) private {
        uint256 size = list.length;
        while (i < size - 1) {
            list[i] = list[i + 1];
            i++;
        }

        list.pop();
    }
}