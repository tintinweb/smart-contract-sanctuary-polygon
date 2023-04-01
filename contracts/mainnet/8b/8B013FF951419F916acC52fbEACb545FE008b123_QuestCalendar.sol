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

// File: contracts/Admin/data/QuestCalendar.sol


pragma solidity ^0.8.18;



contract QuestCalendar is Ownable {
    uint256 public lastId = 0;
    // id => type
    mapping(uint256 => PeriodQuestInfo) public calendars;

    function getLsatId() public view returns (uint256) {
        return lastId;
    }

    function getQuestCalendar(uint256 id) public view returns (PeriodQuestInfo memory) {
        return calendars[id];
    }

    function getQuestCalendars(uint256[] memory ids) public view returns (PeriodQuestInfo[] memory) {
        PeriodQuestInfo[] memory _calendars = new PeriodQuestInfo[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            _calendars[i] = calendars[ids[i]];
        }
        return _calendars;
    }

    function setQuestInfos(PeriodQuestInfo[] memory periodQuestInfos) external onlyOwner {
        for (uint256 i = 0; i < periodQuestInfos.length; i++) {
            calendars[periodQuestInfos[i].id] = periodQuestInfos[i];
            if (lastId < periodQuestInfos[i].id) {
                lastId = periodQuestInfos[i].id;
            }
        }
    }

    function setQuestInfo(PeriodQuestInfo memory periodQuestInfo) external onlyOwner {
        calendars[periodQuestInfo.id] = periodQuestInfo;
        if (lastId < periodQuestInfo.id) {
            lastId = periodQuestInfo.id;
        }
    }
}