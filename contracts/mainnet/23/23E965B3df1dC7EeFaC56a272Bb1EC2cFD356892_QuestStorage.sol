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
// File: contracts/LUXON/quest/QuestStructure.sol


pragma solidity ^0.8.16;

struct QuestSlotInfo {
    uint256 tokenId;
    uint256 amount;
    bool isValid;
    uint256 createdAt;
}

struct QuestBox {
    mapping(uint256 => QuestInfo) quest;
    uint256 questSize;
    uint256[] questGroupList;
}

struct QuestInfo {
    uint256 questNo;
    uint256 slotDataSize;
    uint256 createAt;
    uint256 startAt;
    uint256 endAt;
    bool isGetReward;
    mapping(uint256 => QuestSlotInfo) slotData;
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

struct QuestDataOutDto {
    uint256 questNo;
    string name;
    uint256 mainQuestGroup;
    uint256 subQuestGroup;
    uint256 questCategory;
    uint256 stakingTime;
    uint256 reward;
    uint256 rewardAmount;
    uint256[] nextQuest;
    uint256 createAt;
    uint256 startAt;
    uint256 endAt;
    bool isGetReward;
    QuestSlotInfo[] slotData;
}

////////////////////////////////////////////////////////
/////// V2

struct QuestInfoOutDto {
    uint256 questNo;
    uint256 createAt;
    uint256 startAt;
    uint256 endAt;
    bool isGetReward;
    QuestSlotInfo[] slotData;
}
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

// File: contracts/LUXON/quest/QuestStorage.sol


pragma solidity ^0.8.16;






contract QuestStorage is LuxOnSuperOperators, LuxOnData {
    event SubQuestSize(address indexed userAddress, uint256 indexed questSize);
    event InitQuest(address indexed userAddress, uint256 indexed questGroup, uint256 questNo, uint256 createAt, uint256 startAt, uint256 endAt, bool isGetReward, uint256 questSize, uint256[] questGroupList);
    event InitSlotData(address indexed userAddress, uint256 indexed questGroup);
    event StartQuest(address indexed userAddress, uint256 indexed questGroup, uint256 startAt, uint256 endAt);
    event SetStakeInfo(address indexed userAddress, uint256 indexed questNo, uint256 indexed tokenId, uint256 amt, uint256 conditionType);
    event SetBurnWaitList(address indexed userAddress, uint256 indexed questNo, uint256 indexed tokenId, uint256 amt, uint256 questType, uint256 idx);
    event RmUserStakingInfo(address indexed userAddress, uint256 indexed questNo, uint256 indexed tokenId);
    event SetSlotData(address indexed userAddress, uint256 indexed questGroup, uint256 indexed tokenId, uint256 amt, uint256 idx, uint256 conditionAmt);
    event RmQuestClearList(address indexed userAddress, uint256 indexed questNo);
    event SetClear(address indexed userAddress, uint256 indexed questNo, uint256 indexed questGroup);
    event RmGroup(address indexed userAddress, uint256 indexed questGroup);
    event CancelQuest(address indexed userAddress, uint256 indexed questGroup, uint256 indexed questNo);
    event GetNewQuest(address indexed userAddress, uint256 indexed questGroup);
    event SetQuestClearList(address indexed userAddress, uint256[] questNos);
    event SetQuestInfo(address indexed userAddress, uint256 indexed questGroup, uint256 indexed questNo);

    using SafeMath for uint256;

    mapping(address => QuestBox) public userQuestInfo;
    mapping(address => uint256[]) public userQuestClearInfo;
    mapping(address => mapping(uint256 => StakeInfo[])) public userStakeInfo;
    mapping(address => mapping(uint256 => BurnWaitInfo[])) public userBurnWaitList; // address, questNo, [StakeInfo]

    constructor(
        address dataAddress,
        string memory operator,
        address luxOnAdmin
    ) LuxOnData(dataAddress) LuxOnSuperOperators(operator, luxOnAdmin) {}

    function getQuestStorage(address _address, uint256 _questGroup) private view returns (QuestInfo storage) {
        return userQuestInfo[_address].quest[_questGroup];
    }

    function getQuestInfo(address _address, uint256 _questGroup) external view returns (QuestInfoOutDto memory) {
        QuestInfo storage qI = getQuestStorage(_address, _questGroup);
        QuestSlotInfo[] memory slotData = new QuestSlotInfo[](qI.slotDataSize);
        for (uint i = 0; i < qI.slotDataSize; i++) {
            slotData[i] = qI.slotData[i];
        }

        return QuestInfoOutDto(qI.questNo, qI.createAt, qI.startAt, qI.endAt, qI.isGetReward, slotData);
    }

    function subQuestSize(address _address) external onlySuperOperator {
        userQuestInfo[_address].questSize = userQuestInfo[_address].questSize.sub(1);
        emit SubQuestSize(_address, userQuestInfo[_address].questSize);
    }

    function initQuest(address _address, uint256 _questGroup, LimitQuestData.Quest memory _qD) external onlySuperOperator {
        QuestInfo storage qI = getQuestStorage(_address, _questGroup);
        for (uint256 i = 0; i < _qD.questConditionSlot.length; i++) {
            qI.slotData[qI.slotDataSize] = QuestSlotInfo(0, 0, false, block.timestamp);
            qI.slotDataSize++;    
        }
        qI.questNo = _qD.questNo;
        qI.createAt = block.timestamp;
        qI.startAt = 0;
        qI.endAt = 0;
        qI.isGetReward = false;
        userQuestInfo[_address].questSize++;
        userQuestInfo[_address].questGroupList.push(_questGroup);

        emit InitQuest(
            _address,
            _questGroup,
            qI.questNo,
            qI.createAt,
            qI.startAt,
            qI.endAt,
            qI.isGetReward,
            userQuestInfo[_address].questSize,
            userQuestInfo[_address].questGroupList
        );
    }

    function initSlotData(address _address, uint256 _questGroup) external onlySuperOperator {
        QuestInfo storage qI = getQuestStorage(_address, _questGroup);
        if (0 < qI.questNo) {
            for (uint256 j = 0; j < qI.slotDataSize; j++) {
                delete qI.slotData[j];
            }
            qI.slotDataSize = 0;
        }
        emit InitSlotData(_address, _questGroup);
    }

    function isStartQuest(address _address, uint256 _questGroup) external view returns (bool isSuccess) {
        uint256 successCount = 0;
        QuestInfo storage qI = getQuestStorage(_address, _questGroup);
        for (uint256 i = 0; i < qI.slotDataSize; i++) {
            if (true == qI.slotData[i].isValid) {
                successCount++;
            }

            if (qI.slotDataSize == successCount) {
                return true;
            }
        }

        return false;
    }

    function startQuest(address _address, uint256 _questGroup, uint256 _endAt) external onlySuperOperator {
        QuestInfo storage qI = getQuestStorage(_address, _questGroup);
        qI.startAt = block.timestamp;
        qI.endAt = block.timestamp.add(_endAt);
        emit StartQuest(_address, _questGroup, block.timestamp, block.timestamp.add(_endAt));
    }

    function setStakeInfo(address _address, uint256 _questNo, uint256 _tokenId, uint256 _amt, uint256 _conditionType) external onlySuperOperator {
        userStakeInfo[_address][_questNo].push(StakeInfo(_tokenId, _amt, _conditionType));
        emit SetStakeInfo(_address, _questNo, _tokenId, _amt, _conditionType);
    }

    function setBurnWaitList(address _address, uint256 _questNo, uint256 _tokenId, uint256 _amt, uint256 _questType, uint256 _idx) external onlySuperOperator {
        userBurnWaitList[_address][_questNo].push(BurnWaitInfo(_tokenId, _amt, _questType, _idx));
        emit SetBurnWaitList(_address, _questNo, _tokenId, _amt, _questType, _idx);
    }

    function rmUserStakingInfo(address _address, uint256 _questNo, uint256 _tokenId) external onlySuperOperator {
        uint256 idx = 0;
        while (userStakeInfo[_address][_questNo][idx].tokenId != _tokenId && idx <= userStakeInfo[_address][_questNo].length) {
            idx++;
        }

        uint256 size = userStakeInfo[_address][_questNo].length;
        while (idx < size - 1) {
            userStakeInfo[_address][_questNo][idx] = userStakeInfo[_address][_questNo][idx + 1];
            idx++;
        }

        userStakeInfo[_address][_questNo].pop();
        emit RmUserStakingInfo(_address, _questNo, _tokenId);
    }

    function setSlotData(address _address, uint256 _questGroup, uint256 _tokenId, uint256 _amt, uint256 _idx, uint256 _conditionAmt) external onlySuperOperator {
        QuestInfo storage qI = getQuestStorage(_address, _questGroup);
        qI.slotData[_idx].tokenId = _tokenId;
        qI.slotData[_idx].amount = qI.slotData[_idx].amount.add(_amt);

        if (qI.slotData[_idx].amount == _conditionAmt) {
            qI.slotData[_idx].isValid = true;
        }
        emit SetSlotData(_address, _questGroup, _tokenId, _amt, _idx, _conditionAmt);
    }

    function rmQuestClearList(address _address, uint256 _questNo) external onlySuperOperator {
        uint256[] storage clearList = userQuestClearInfo[_address];
        uint256 idx = 0;
        for (uint i = 0; i < clearList.length; i++) {
            if (_questNo == clearList[i]) {
                idx = i;
            }
        }

        clearList[idx] = clearList[clearList.length - 1];
        clearList.pop();
        emit RmQuestClearList(_address, _questNo);
    }

    function checkClearQuest(address _address, uint256 _questNo) external view returns (bool isChecked) {
        for (uint i = 0; i < userQuestClearInfo[_address].length; i++) {
            if (_questNo == userQuestClearInfo[_address][i]) {
                return true;
            }
        }

        return false;
    }

    function getBurnInfo(address _address, uint256 _questNo) external view returns(BurnWaitInfo[] memory) {
        BurnWaitInfo[] memory burnInfo = new BurnWaitInfo[](userBurnWaitList[_address][_questNo].length);
        for (uint256 i = 0; i < userBurnWaitList[_address][_questNo].length; i++) {
            burnInfo[i] = userBurnWaitList[_address][_questNo][i];
        }

        return burnInfo;
    }

    function getStakingInfo(address _address, uint256 _questNo) external view returns (StakeInfo[] memory) {
        StakeInfo[] memory stakeInfo = new StakeInfo[](userStakeInfo[_address][_questNo].length);
        for (uint256 i = 0; i < userStakeInfo[_address][_questNo].length; i++) {
            stakeInfo[i] = userStakeInfo[_address][_questNo][i];
        }

        return stakeInfo;
    }

    function setClear(address _address, uint256 _questNo, uint256 _questGroup) external onlySuperOperator {
        userQuestClearInfo[_address].push(_questNo);
        getQuestStorage(_address, _questGroup).isGetReward = true;

        delete userBurnWaitList[_address][_questNo];
        delete userStakeInfo[_address][_questNo];

        userQuestInfo[_address].questSize = userQuestInfo[_address].questSize.sub(1);

        emit SetClear(_address, _questNo, _questGroup);
    }

    function rmGroup(address _address, uint256 _questGroup) external onlySuperOperator {
        uint256 index;
        if (0 < userQuestInfo[_address].questGroupList.length) {
            for (uint i = 0; i < userQuestInfo[_address].questGroupList.length; i++) {
                if (_questGroup == userQuestInfo[_address].questGroupList[i]) {
                    index = i;
                }
            }
            userQuestInfo[_address].questGroupList[index] = userQuestInfo[_address].questGroupList[userQuestInfo[_address].questGroupList.length - 1];
            userQuestInfo[_address].questGroupList.pop();
        }
        emit RmGroup(_address, _questGroup);
    }

    function cancelQuest(address _address, uint256 _questGroup, uint256 _questNo) external onlySuperOperator {
        QuestInfo storage qI = getQuestStorage(_address, _questGroup);
        require(_questNo == qI.questNo, "INVALID questNo");

        qI.startAt = 0;
        qI.endAt = 0;
        
        for (uint256 i = 0; i < qI.slotDataSize; i++) {
            qI.slotData[i].tokenId = 0;
            qI.slotData[i].isValid = false;
            qI.slotData[i].createdAt = 0;
            qI.slotData[i].amount = 0;
        }

        delete userBurnWaitList[_address][_questNo];
        delete userStakeInfo[_address][_questNo];

        emit CancelQuest(_address, _questGroup, _questNo);
    }

    function getNewQuest(address _address, uint256 _questGroup) external onlySuperOperator {
        require(true == getQuestStorage(_address, _questGroup).isGetReward, "You haven't cleared the previous quest yet.");
        userQuestInfo[_address].questSize = userQuestInfo[_address].questSize.sub(1);
        emit GetNewQuest(_address, _questGroup);
    }

    ////////////////////////////////////////////////////////////////////////////////////

    function getQuestDataInfo(address _address) external view returns (QuestDataOutDto[] memory) {
        QuestBox storage questBox = userQuestInfo[_address];
        QuestDataOutDto[] memory dto;
        dto = new QuestDataOutDto[](questBox.questSize);
        uint256 cnt = 0;
        for (uint i = 0; i < questBox.questGroupList.length; i++) {
            uint256 questGroup = questBox.questGroupList[i];
            QuestInfo storage qI = questBox.quest[questGroup];
            LimitQuestData.Quest memory qD = LimitQuestData(getDataAddress("LimitQuestData")).getQuest(qI.questNo);
            QuestSlotInfo[] memory slotData = new QuestSlotInfo[](qI.slotDataSize);

            for (uint j = 0; j < qI.slotDataSize; j++) {
                slotData[j] = qI.slotData[j];
            }

            dto[cnt] = QuestDataOutDto(
                qI.questNo,
                qD.name,
                qD.mainQuestGroup,
                qD.subQuestGroup,
                qD.questCategory,
                qD.stakingTime,
                qD.reward,
                qD.rewardAmount,
                qD.nextQuest,
                qI.createAt,
                qI.startAt,
                qI.endAt,
                qI.isGetReward,
                slotData
            );
            cnt++;
        }

        return dto;
    }

    function getClearQuestList(address _address) public view returns (uint256[] memory) {
        return userQuestClearInfo[_address];
    }

    ////////////////////////////////////////////////////////////////////////////////////

    function setQuestClearList(address _address, uint256[] calldata _questNos) external onlySuperOperator {
        uint256[] memory realQuestNos = new uint256[](_questNos.length);
        uint256 cnt = 0;
        for (uint i = 0; i < _questNos.length; i++) {
            bool isExists = false;
            uint256 questNo = _questNos[i];
            for (uint j = 0; j < userQuestClearInfo[_address].length; j++) {
                uint256 diffQuestNo = userQuestClearInfo[_address][j];
                if (questNo == diffQuestNo) {
                    isExists = true;
                }
            }

            if (!isExists) {
                realQuestNos[cnt] = questNo;
                cnt++;
            }
        }

        for (uint i = 0; i < realQuestNos.length; i++) {
            userQuestClearInfo[_address].push(realQuestNos[i]);
        }
        emit SetQuestClearList(_address, _questNos);
    }

    function setQuestInfo(address _address, uint256 _questGroup, uint256 _questNo) external onlySuperOperator {
        LimitQuestData.Quest memory qD = LimitQuestData(getDataAddress("LimitQuestData")).getQuest(_questNo);
        QuestInfo storage qI = getQuestStorage(_address, _questGroup);

        for (uint256 i = 0; i < qD.questConditionSlot.length; i++) {
            qI.slotData[qI.slotDataSize] = QuestSlotInfo(0, 0, false, block.timestamp);
            qI.slotDataSize++;    
        }
        qI.createAt = block.timestamp;
        qI.startAt = 0;
        qI.endAt = 0;
        qI.isGetReward = false;
        qI.questNo = _questNo;

        emit SetQuestInfo(_address, _questGroup, _questNo);
    }
}