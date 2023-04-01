/**
 *Submitted for verification at polygonscan.com on 2023-03-31
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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
// File: contracts/Admin/LuxOnAdmin.sol


pragma solidity ^0.8.16;


contract LuxOnAdmin is Ownable {

    mapping(string => mapping(address => bool)) private _superOperators;

    event SuperOperator(string operator, address superOperator, bool enabled);

    function setSuperOperator(string memory operator, address[] memory _operatorAddress, bool enabled) external onlyOwner {
        for (uint256 i = 0; i < _operatorAddress.length; i++) {
            _superOperators[operator][_operatorAddress[i]] = enabled;
            emit SuperOperator(operator, _operatorAddress[i], enabled);
        }
    }

    function isSuperOperator(string memory operator, address who) public view returns (bool) {
        return _superOperators[operator][who];
    }
}
// File: contracts/LUXON/utils/LuxOnSuperOperators.sol


pragma solidity ^0.8.16;



contract LuxOnSuperOperators is Ownable {

    event SetLuxOnAdmin(address indexed luxOnAdminAddress);
    event SetOperator(string indexed operator);

    address private luxOnAdminAddress;
    string private operator;

    constructor(
        string memory _operator,
        address _luxOnAdminAddress
    ) {
        operator = _operator;
        luxOnAdminAddress = _luxOnAdminAddress;
    }

    modifier onlySuperOperator() {
        require(LuxOnAdmin(luxOnAdminAddress).isSuperOperator(operator, msg.sender), "LuxOnSuperOperators: not super operator");
        _;
    }

    function getLuxOnAdmin() public view returns (address) {
        return luxOnAdminAddress;
    }

    function getOperator() public view returns (string memory) {
        return operator;
    }

    function setLuxOnAdmin(address _luxOnAdminAddress) external onlyOwner {
        luxOnAdminAddress = _luxOnAdminAddress;
        emit SetLuxOnAdmin(_luxOnAdminAddress);
    }

    function setOperator(string memory _operator) external onlyOwner {
        operator = _operator;
        emit SetOperator(_operator);
    }

    function isSuperOperator(address spender) public view returns (bool) {
        return LuxOnAdmin(luxOnAdminAddress).isSuperOperator(operator, spender);
    }
}
// File: contracts/Admin/data/DataAddress.sol


pragma solidity ^0.8.16;


contract DspDataAddress is Ownable {

    event SetDataAddress(string indexed name, address indexed dataAddress, bool indexed isValid);

    struct DataAddressInfo {
        string name;
        address dataAddress;
        bool isValid;
    }

    mapping(string => DataAddressInfo) private dataAddresses;

    function getDataAddress(string memory _name) public view returns (address) {
        require(dataAddresses[_name].isValid, "this data address is not valid");
        return dataAddresses[_name].dataAddress;
    }

    function setDataAddress(DataAddressInfo memory _dataAddressInfo) external onlyOwner {
        dataAddresses[_dataAddressInfo.name] = _dataAddressInfo;
        emit SetDataAddress(_dataAddressInfo.name, _dataAddressInfo.dataAddress, _dataAddressInfo.isValid);
    }

    function setDataAddresses(DataAddressInfo[] memory _dataAddressInfos) external onlyOwner {
        for (uint256 i = 0; i < _dataAddressInfos.length; i++) {
            dataAddresses[_dataAddressInfos[i].name] = _dataAddressInfos[i];
            emit SetDataAddress(_dataAddressInfos[i].name, _dataAddressInfos[i].dataAddress, _dataAddressInfos[i].isValid);
        }
    }
}
// File: contracts/LUXON/utils/LuxOnData.sol


pragma solidity ^0.8.16;



contract LuxOnData is Ownable {
    address private luxonData;
    event SetLuxonData(address indexed luxonData);

    constructor(
        address _luxonData
    ) {
        luxonData = _luxonData;
    }

    function getLuxOnData() public view returns (address) {
        return luxonData;
    }

    function setLuxOnData(address _luxonData) external onlyOwner {
        luxonData = _luxonData;
        emit SetLuxonData(_luxonData);
    }

    function getDataAddress(string memory _name) public view returns (address) {
        return DspDataAddress(luxonData).getDataAddress(_name);
    }
}
// File: contracts/LUXON/quest/PeriodQuestStorage.sol


pragma solidity ^0.8.18;







contract PeriodQuestStorage is LuxOnSuperOperators, LuxOnData {
    event SetStakeInfo(address indexed userAddress, uint256 indexed id, uint256 indexed tokenId, uint256 amt, uint256 conditionType);
    event SetBurnWaitList(address indexed userAddress, uint256 indexed id, uint256 indexed tokenId, uint256 amt, uint256 questType, uint256 idx);
    event SetSlotData(address indexed userAddress, uint256 indexed id, uint256 indexed tokenId, uint256 amt, uint256 idx);
    event SetClear(address indexed userAddress, uint256 indexed id);
    event CancelQuest(address indexed userAddress, uint256 indexed id);
    using SafeMath for uint256;

    // address => quest id
    mapping(address => uint256[]) public userQuestClearInfo;
    // id => count
    mapping(uint256 => uint256) public questClearCount;
    // address => id => state
    mapping(address => mapping(uint256 => bool)) public userClearState;
    // address => id => quest info
    mapping(address => mapping(uint256 => QuestInfo)) public userQuestInfo;
    mapping(address => mapping(uint256 => StakeInfo[])) public userStakeInfo;
    mapping(address => mapping(uint256 => BurnWaitInfo[])) public userBurnWaitList;
    uint256 constant HOUR = 3600;
    // address => type => clear
    mapping(address => mapping(uint256 => uint256[])) public userPeriodClearInfo;
    constructor(
        address dataAddress,
        string memory operator,
        address luxOnAdmin
    ) LuxOnData(dataAddress) LuxOnSuperOperators(operator, luxOnAdmin) {}

    function getQuestCount(uint256 id) public view returns (uint256) {
        PeriodQuestInfo memory periodQuestInfo = QuestCalendar(getDataAddress("QuestCalendar")).getQuestCalendar(id);
        return questClearCount[periodQuestInfo.finishId];
    }

    function getQuestCounts(uint256[] memory ids) public view returns (uint256[] memory) {
        uint256[] memory counts = new uint256[](ids.length);
        PeriodQuestInfo[] memory periodQuestInfos = QuestCalendar(getDataAddress("QuestCalendar")).getQuestCalendars(ids);
        for (uint256 i = 0; i < ids.length; i++) {
            counts[i] = questClearCount[periodQuestInfos[i].finishId];
        }
        return counts;
    }

    function getClearState(address _address, uint256 id) public view returns (bool) {
        return userClearState[_address][id];
    }

    function getQuestStorage(address _address, uint256 id) public view returns (QuestInfo memory) {
        return userQuestInfo[_address][id];
    }

    function getBurnInfo(address _address, uint256 id) public view returns(BurnWaitInfo[] memory) {
        return userBurnWaitList[_address][id];
    }

    function getStakingInfo(address _address, uint256 id) public view returns (StakeInfo[] memory) {
        return userStakeInfo[_address][id];
    }

    function getClearQuestList(address _address) public view returns (uint256[] memory) {
        return userQuestClearInfo[_address];
    }

    function getUserPeriodClearInfo(address _address, uint256 questType) public view returns (uint256[] memory) {
        return userPeriodClearInfo[_address][questType];
    }

    function getAdminDashboard(address _address, uint256[] memory ids) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, Dashboard[] memory) {
        Dashboard[] memory dashboards = new Dashboard[](ids.length);
        PeriodQuestInfo[] memory periodQuestInfos = QuestCalendar(getDataAddress("QuestCalendar")).getQuestCalendars(ids);
        for (uint256 i = 0; i < ids.length; i++) {
            Dashboard memory dashboard = Dashboard(
                ids[i],
                getQuestCount(periodQuestInfos[i].finishId),
                getClearState(_address, ids[i]),
                getQuestStorage(_address, ids[i]),
                getBurnInfo(_address, ids[i]),
                getStakingInfo(_address, ids[i])
            );
            dashboards[i] = dashboard;
        }
        (uint256[] memory daily, uint256[] memory weekly, uint256[] memory premium) = getClearPeriodQuestList(_address);
        return (
            getClearQuestList(_address),
            daily,
            weekly,
            premium,
            dashboards
        );
    }

    function getQuestInfoView(address _address, uint256 id) public view returns (uint256, QuestInfo memory, Quest memory) {
        PeriodQuestInfo memory periodQuestInfo = QuestCalendar(getDataAddress("QuestCalendar")).getQuestCalendar(id);
        return (
            getQuestCount(periodQuestInfo.finishId),
            getQuestStorage(_address, id),
            PeriodQuestData(getDataAddress("PeriodQuestData")).getQuest(periodQuestInfo.questId)
        );
    }

    function getClearPeriodQuestList(address _address) public view returns (uint256[] memory, uint256[] memory, uint256[] memory) {
        return (
            userPeriodClearInfo[_address][uint256(QuestType.DAILY)],
            userPeriodClearInfo[_address][uint256(QuestType.WEEKLY)],
            userPeriodClearInfo[_address][uint256(QuestType.PREMIUM)]
        );
    }

    function getClearCondition(address user, uint256 currentId, uint256 requireId, uint256 finishId) public view returns (uint256, bool, bool) {
        return (
            getQuestCount(finishId),
            getClearState(user, currentId),
            getClearState(user, requireId)
        );
    }

    function resetUserPeriodClearInfo(address _address, uint256 questType) external onlySuperOperator {
        if (0 != userPeriodClearInfo[_address][questType].length) {
            delete userPeriodClearInfo[_address][questType];
        }
    }

    function setClearQuestList(address _address, uint256[] memory ids, uint256 questType, bool isClear) external onlySuperOperator {
        PeriodQuestInfo[] memory calendars = QuestCalendar(getDataAddress("QuestCalendar")).getQuestCalendars(ids);
        for (uint256 i = 0; i < ids.length; i++) {
            if (isClear && !userClearState[_address][ids[i]]) {
                userQuestClearInfo[_address].push(ids[i]);
                userClearState[_address][ids[i]] = true;
                userPeriodClearInfo[_address][questType].push(ids[i]);
                if (calendars[i].finishId == ids[i]) {
                    questClearCount[ids[i]]++;
                }
            } else if (!isClear && userClearState[_address][ids[i]]) {
                for (uint256 j = 0; j < userQuestClearInfo[_address].length; j++) {
                    if (userQuestClearInfo[_address][j] == ids[i]) {
                        userQuestClearInfo[_address][j] = 0;
                        break;
                    }
                }
                userClearState[_address][ids[i]] = false;
                delete userPeriodClearInfo[_address][questType];
                if (calendars[i].finishId == ids[i]) {
                    questClearCount[ids[i]]--;
                }
            }
        }
    }

    function setClearCount(CalculateType setType, uint256 id, uint256 count) external onlySuperOperator {
        if (CalculateType.SET == setType) {
            questClearCount[id] = count;
        } else if (CalculateType.ADD == setType) {
            questClearCount[id] += count;
        } else if (CalculateType.SUB == setType) {
            questClearCount[id] -= count;
        }
    }

    function setStakeInfo(address _address, uint256 id, uint256 _tokenId, uint256 _amt, uint256 _conditionType) external onlySuperOperator {
        userStakeInfo[_address][id].push(StakeInfo(_tokenId, _amt, _conditionType));
        emit SetStakeInfo(_address, id, _tokenId, _amt, _conditionType);
    }

    function setBurnWaitList(address _address, uint256 id, uint256 _tokenId, uint256 _amt, uint256 _questType, uint256 _idx) external onlySuperOperator {
        userBurnWaitList[_address][id].push(BurnWaitInfo(_tokenId, _amt, _questType, _idx));
        emit SetBurnWaitList(_address, id, _tokenId, _amt, _questType, _idx);
    }

    function setSlotData(address _address, uint256 id, uint256 _tokenId, uint256 _amt, uint256 _idx) external onlySuperOperator {
        userQuestInfo[_address][id].slotData.push(QuestSlotInfo(_tokenId, _amt, true));
        emit SetSlotData(_address, id, _tokenId, _amt, _idx);
    }

    function setClear(address _address, uint256 id, uint256 finishId, uint256 questType) external onlySuperOperator {
        userQuestClearInfo[_address].push(id);
        userClearState[_address][id] = true;
        userPeriodClearInfo[_address][questType].push(id);
        if (finishId == id) {
            questClearCount[id]++;
        }

        emit SetClear(_address, id);
    }

    function cancelQuest(address _address, uint256 id) external onlySuperOperator {
        require(id == userQuestInfo[_address][id].questNo, "INVALID questNo");

        userQuestInfo[_address][id].startAt = 0;
        userQuestInfo[_address][id].endAt = 0;
        uint256 popLength = userQuestInfo[_address][id].slotData.length;
        for (uint256 i = 0; i < popLength; i++) {
            userQuestInfo[_address][id].slotData.pop();
        }

        delete userBurnWaitList[_address][id];
        delete userStakeInfo[_address][id];

        emit CancelQuest(_address, id);
    }

    function startQuest(address _address, uint256 id, uint256 stakingTime) external onlySuperOperator {
        userQuestInfo[_address][id].questNo = id;
        userQuestInfo[_address][id].startAt = block.timestamp;
        userQuestInfo[_address][id].endAt = block.timestamp.add(HOUR.mul(stakingTime));
    }
}