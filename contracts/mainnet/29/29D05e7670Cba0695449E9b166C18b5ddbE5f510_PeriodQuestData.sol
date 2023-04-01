/**
 *Submitted for verification at polygonscan.com on 2023-03-31
*/

// File: contracts/Admin/data/PeriodQuestStruct.sol


pragma solidity ^0.8.18;

    enum CalculateType {
        NONE,
        SET,
        ADD,
        SUB
    }

    enum ConditionType {
        NONE,
        CHARACTER,
        CHARACTER_TIER,
        PACK,
        CHARACTER_ELEMENT,
        CHARACTER_NATION
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

    enum TokenType {
        NONE,
        ERC20,
        ERC721,
        ERC1155
    }

    enum QuestType {
        NONE,
        MAIN,
        HIDDEN,
        DAILY,
        WEEKLY,
        PREMIUM
    }

    struct BurnWaitInfo {
        uint256 tokenId;
        uint256 amount;
        uint256 conditionType;
        uint256 slotNo;
    }

    struct StakeInfo {
        uint256 tokenId;
        uint256 amount;
        uint256 conditionType;
    }

    struct Quest {
        uint256 questNo;
        string name;
        uint256 requireQuest;
        uint256 questCategory;
        uint256 stakingTime;
        Reward[] rewards;
        QuestConditionSlot[] questConditionSlot;
    }

    struct Reward {
        uint256 rewardType;
        uint256 reward;
        uint256 rewardAmount;
    }

    struct QuestConditionSlot {
        uint256 questType;       // 미션 타입
        uint256 conditionType;   // 미션 조건 타입
        uint256 conditionValue;  // 미션 조건 값
        uint256 conditionAmount; // 개수
        uint256 subConditionType;
        uint256 subConditionValue;
    }

    struct PeriodQuestInfo {
        uint256 id;
        uint256 requireId;
        uint256 questType;
        uint256 questId;
        uint256 startAt;
        uint256 endAt;
        uint256 limit;
        uint256 finishId;
        bool isValid;
    }

    struct QuestInfo {
        uint256 questNo;
        uint256 startAt;
        uint256 endAt;
        QuestSlotInfo[] slotData;
    }

    struct QuestSlotInfo {
        uint256 tokenId;
        uint256 amount;
        bool isValid;
    }

    struct Dashboard {
        uint256 id;
        uint256 clearCount;
        bool clearState;
        QuestInfo userQuestInfo;
        BurnWaitInfo[] burnInfo;
        StakeInfo[] stakeInfo;
    }

    struct RewardInfo {
        uint256 goodsType;
        uint256 tokenType;
        address tokenAddress;
        bool isValid;
    }
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

// File: contracts/Admin/data/PeriodQuestData.sol


pragma solidity ^0.8.18;



contract PeriodQuestData is Ownable {
    // quest id => quest
    mapping(uint256 => Quest) questConditionMap;

    function getQuest(uint256 questNo) public view returns (Quest memory) {
        return questConditionMap[questNo];
    }

    function getQuests(uint256[] memory questNo) public view returns (Quest[] memory) {
        Quest[] memory quests = new Quest[](questNo.length);
        for (uint256 i = 0; i < questNo.length; i++) {
            quests[i] = questConditionMap[questNo[i]];
        }
        return quests;
    }

    function setQuestDataMany(Quest[] memory _questData) external onlyOwner {
        for (uint i = 0; i < _questData.length; i++) {
            uint questNo = _questData[i].questNo;

            Quest storage quest_ = questConditionMap[questNo];
            delete quest_.questConditionSlot;

            quest_.questNo = questNo;
            quest_.name = _questData[i].name;
            quest_.requireQuest = _questData[i].requireQuest;
            quest_.questCategory = _questData[i].questCategory;
            quest_.stakingTime = _questData[i].stakingTime;
            for (uint j = 0; j < _questData[i].rewards.length; j++) {
                quest_.rewards.push(
                    Reward(
                        _questData[i].rewards[j].rewardType,
                        _questData[i].rewards[j].reward,
                        _questData[i].rewards[j].rewardAmount
                    )
                );
            }

            for (uint j = 0; j < _questData[i].questConditionSlot.length; j++) {
                quest_.questConditionSlot.push(QuestConditionSlot(
                        _questData[i].questConditionSlot[j].questType,
                        _questData[i].questConditionSlot[j].conditionType,
                        _questData[i].questConditionSlot[j].conditionValue,
                        _questData[i].questConditionSlot[j].conditionAmount,
                        _questData[i].questConditionSlot[j].subConditionType,
                        _questData[i].questConditionSlot[j].subConditionValue
                    ));
            }
        }
    }

    function setQuestData(Quest memory _questData) external onlyOwner {
        Quest storage quest_ = questConditionMap[_questData.questNo];
        delete quest_.questConditionSlot;

        quest_.questNo = _questData.questNo;
        quest_.name = _questData.name;
        quest_.requireQuest = _questData.requireQuest;
        quest_.questCategory = _questData.questCategory;
        quest_.stakingTime = _questData.stakingTime;

        for (uint j = 0; j < _questData.rewards.length; j++) {
            quest_.rewards.push(
                Reward(
                    _questData.rewards[j].rewardType,
                    _questData.rewards[j].reward,
                    _questData.rewards[j].rewardAmount
                )
            );
        }

        for (uint j = 0; j < _questData.questConditionSlot.length; j++) {
            quest_.questConditionSlot.push(QuestConditionSlot(
                    _questData.questConditionSlot[j].questType,
                    _questData.questConditionSlot[j].conditionType,
                    _questData.questConditionSlot[j].conditionValue,
                    _questData.questConditionSlot[j].conditionAmount,
                    _questData.questConditionSlot[j].subConditionType,
                    _questData.questConditionSlot[j].subConditionValue
                ));
        }
    }
}