/**
 *Submitted for verification at polygonscan.com on 2023-07-31
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

// File: contracts/Admin/data/rank/RankStruct.sol


pragma solidity ^0.8.18;

    enum RankRewardType {
        RankTier,
        Badge
    }

    enum RankTier {
        NONE,
        IRON,
        BRONZE,
        SILVER,
        GOLD,
        PLATINUM
    }

    enum BadgeType {
        NONE,
        RED,
        TITANIUM
    }

    enum TokenType {
        NONE,
        ERC20,
        ERC721,
        ERC1155
    }

    enum RankRewardReceiveType {
        DAILY,
        WEEKLY,
        MONTHLY
    }

    struct Reward {
        uint256 rewardType;
        uint256 reward;
        uint256 rewardAmount;
    }

    struct RankRewardCalender {
        uint256 id;
        uint256 season;
        uint256 rewardType;
        uint256 receiveType;
        RewardId rewardIds;
        // mapping(uint256 => RewardIds) rewardIds;
        uint256 startAt;
        uint256 endAt;
        // mapping(uint256 => RewardIds) rewardIds;
        // RewardIds rewardIds;
        //    uint256[] rewardId; // tier => rewardId
        bool isValid;
    }

    struct RewardId {
        uint256[][] rewardId;
    }

    struct RankReward {
        uint256 id;
        uint256 season;
        uint256 tier;
        uint256 receiveType;
        uint256 rewardType;
        uint256 reward;
        uint256 rewardAmount;
        bool isValid;
    }

    struct RankBadgeReward {
        uint256 id;
        uint256 season;
        uint256 badgeType;
        uint256 receiveType;
        uint256 rewardType;
        uint256 reward;
        uint256 rewardAmount;
        bool isValid;
    }

    struct RewardInfo {
        uint256 goodsType;
        uint256 tokenType;
        address tokenAddress;
        bool isValid;
    }

    struct UserRank {
        uint256 tier;
        uint256 badge;
    }

    struct SetUserRank {
        address userAddress;
        uint256 season;
        uint256 tier;
        uint256 badge;
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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// File: contracts/Admin/LuxOnService.sol


pragma solidity ^0.8.15;


contract LuxOnService is Ownable {
    mapping(address => bool) isInspection;

    event Inspection(address contractAddress, uint256 timestamp, bool live);

    function isLive(address contractAddress) public view returns (bool) {
        return !isInspection[contractAddress];
    }

    function setInspection(address[] memory contractAddresses, bool _isInspection) external onlyOwner {
        for (uint256 i = 0; i < contractAddresses.length; i++) {
            isInspection[contractAddresses[i]] = _isInspection;
            emit Inspection(contractAddresses[i], block.timestamp, _isInspection);
        }
    }
}
// File: contracts/LUXON/utils/LuxOnLive.sol


pragma solidity ^0.8.16;



contract LuxOnLive is Ownable {
    address private luxOnService;

    event SetLuxOnService(address indexed luxOnService);

    constructor(
        address _luxOnService
    ) {
        luxOnService = _luxOnService;
    }

    function getLuxOnService() public view returns (address) {
        return luxOnService;
    }

    function setLuxOnService(address _luxOnService) external onlyOwner {
        luxOnService = _luxOnService;
        emit SetLuxOnService(_luxOnService);
    }

    modifier isLive() {
        require(LuxOnService(luxOnService).isLive(address(this)), "LuxOnLive: not live");
        _;
    }
}
// File: contracts/Admin/data/rank/UserRankData.sol


pragma solidity ^0.8.18;



contract UserRankData is Ownable {

    // address => season => userRank(tier And badge)
    mapping(address => mapping(uint256 => UserRank)) public userRank;

    function getTier(address _address, uint256 season) public view returns (uint256) {
        return userRank[_address][season].tier;
    }

    function getBadge(address _address, uint256 season) public view returns (uint256) {
        return userRank[_address][season].badge;
    }

    // function getUserRank(address _address, uint256 season) public view returns (UserRank) {
    //     return userRank[_address][season];
    // }

    function getUserRankInfo(address user, uint256 season ) public view returns (uint256, uint256) {
        return (
        getTier(user, season),
        getBadge(user, season)
        );
    }

    function setUserRankDataMany(SetUserRank[] memory _setUserRank) external onlyOwner {
        for (uint i = 0; i < _setUserRank.length; i++) {
            address userAddress = _setUserRank[i].userAddress;
            uint256 season = _setUserRank[i].season;
            delete userRank[userAddress][season];
            UserRank storage userRank_ = userRank[userAddress][season];

            userRank_.tier = _setUserRank[i].tier;
            userRank_.badge = _setUserRank[i].badge;
        }
    }

    function setUserRankData(SetUserRank memory _setUserRank) external onlyOwner {
        delete userRank[_setUserRank.userAddress][_setUserRank.season];
        UserRank storage userRank_ = userRank[_setUserRank.userAddress][_setUserRank.season];

        userRank_.tier = _setUserRank.tier;
        userRank_.badge = _setUserRank.badge;
    }
}
// File: contracts/Admin/data/rank/RankRewardCalenderData.sol


pragma solidity ^0.8.18;



contract RankRewardCalenderData is Ownable {
    uint256 public lastId = 0;
    // id => type
    mapping(uint256 => RankRewardCalender) public calendars;
    function getLsatId() public view returns (uint256) {
        return lastId;
    }

    function getRankRewardCalendar(uint256 id) public view returns (RankRewardCalender memory) {
        return calendars[id];
    }

    function getRankRewardCalendars(uint256[] memory ids) public view returns (RankRewardCalender[] memory) {
        RankRewardCalender[] memory _calendars = new RankRewardCalender[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            _calendars[i] = calendars[ids[i]];
        }
        return _calendars;
    }

    function setRankRewardCalendars(RankRewardCalender[] memory rankRewardCalenders) external onlyOwner {
        for (uint256 i = 0; i < rankRewardCalenders.length; i++) {
            calendars[rankRewardCalenders[i].id] = rankRewardCalenders[i];
            if (lastId < rankRewardCalenders[i].id) {
                lastId = rankRewardCalenders[i].id;
            }
        }
    }

    function setRankRewardCalendar(RankRewardCalender memory rankRewardCalender) external onlyOwner {
        calendars[rankRewardCalender.id] = rankRewardCalender;
        if (lastId < rankRewardCalender.id) {
            lastId = rankRewardCalender.id;
        }
    }
}
// File: contracts/Admin/data/rank/RankRewardData.sol


pragma solidity ^0.8.18;



contract RankRewardData is Ownable {

    mapping(uint256 => RankReward) rankRewardMap;
    mapping(uint256 => RankBadgeReward) rankBadgeRewardMap;

    function getRankReward(uint256 id) public view returns (RankReward memory) {
        return rankRewardMap[id];
    }

    function getRankRewards(uint256[] memory id) public view returns (RankReward[] memory) {
        RankReward[] memory rankRewards = new RankReward[](id.length);
        for (uint256 i = 0; i < id.length; i++) {
            rankRewards[i] = rankRewardMap[id[i]];
        }
        return rankRewards;
    }

    function getRankBadgeReward(uint256 id) public view returns (RankBadgeReward memory) {
        return rankBadgeRewardMap[id];
    }

    function getRankBadgeRewards(uint256[] memory id) public view returns (RankBadgeReward[] memory) {
        RankBadgeReward[] memory rankBadgeRewards = new RankBadgeReward[](id.length);
        for (uint256 i = 0; i < id.length; i++) {
            rankBadgeRewards[i] = rankBadgeRewardMap[id[i]];
        }
        return rankBadgeRewards;
    }

    function setRankRewardDataMany(RankReward[] memory _rankRewardData) external onlyOwner {
        for (uint i = 0; i < _rankRewardData.length; i++) {
            uint id = _rankRewardData[i].id;
            delete rankRewardMap[id];
            RankReward storage rankReward_ = rankRewardMap[id];

            rankReward_.id = id;
            rankReward_.season = _rankRewardData[i].season;
            rankReward_.tier = _rankRewardData[i].tier;
            rankReward_.receiveType = _rankRewardData[i].receiveType;
            rankReward_.rewardType = _rankRewardData[i].rewardType;
            rankReward_.reward = _rankRewardData[i].reward;
            rankReward_.rewardAmount = _rankRewardData[i].rewardAmount;
            rankReward_.isValid = _rankRewardData[i].isValid;
        }
    }

    function setRankRewardData(RankReward memory _rankRewardData) external onlyOwner {
        delete rankRewardMap[_rankRewardData.id];
        RankReward storage rankReward_ = rankRewardMap[_rankRewardData.id];

        rankReward_.id = _rankRewardData.id;
        rankReward_.season = _rankRewardData.season;
        rankReward_.tier = _rankRewardData.tier;
        rankReward_.receiveType = _rankRewardData.receiveType;
        rankReward_.rewardType = _rankRewardData.rewardType;
        rankReward_.reward = _rankRewardData.reward;
        rankReward_.rewardAmount = _rankRewardData.rewardAmount;
        rankReward_.isValid = _rankRewardData.isValid;
    }

    function setRankBadgeRewardDataMany(RankBadgeReward[] memory _rankBadgeRewardData) external onlyOwner {
        for (uint i = 0; i < _rankBadgeRewardData.length; i++) {
            uint id = _rankBadgeRewardData[i].id;
            delete rankBadgeRewardMap[id];
            RankBadgeReward storage rankBadgeReward_ = rankBadgeRewardMap[id];

            rankBadgeReward_.id = id;
            rankBadgeReward_.season = _rankBadgeRewardData[i].season;
            rankBadgeReward_.badgeType = _rankBadgeRewardData[i].badgeType;
            rankBadgeReward_.receiveType = _rankBadgeRewardData[i].receiveType;
            rankBadgeReward_.rewardType = _rankBadgeRewardData[i].rewardType;
            rankBadgeReward_.reward = _rankBadgeRewardData[i].reward;
            rankBadgeReward_.rewardAmount = _rankBadgeRewardData[i].rewardAmount;
            rankBadgeReward_.isValid = _rankBadgeRewardData[i].isValid;
        }
    }

    function setRankBadgeRewardData(RankBadgeReward memory _rankBadgeRewardData) external onlyOwner {
        delete rankBadgeRewardMap[_rankBadgeRewardData.id];
        RankBadgeReward storage rankBadgeReward_ = rankBadgeRewardMap[_rankBadgeRewardData.id];

        rankBadgeReward_.id = _rankBadgeRewardData.id;
        rankBadgeReward_.season = _rankBadgeRewardData.season;
        rankBadgeReward_.badgeType = _rankBadgeRewardData.badgeType;
        rankBadgeReward_.receiveType = _rankBadgeRewardData.receiveType;
        rankBadgeReward_.rewardType = _rankBadgeRewardData.rewardType;
        rankBadgeReward_.reward = _rankBadgeRewardData.reward;
        rankBadgeReward_.rewardAmount = _rankBadgeRewardData.rewardAmount;
        rankBadgeReward_.isValid = _rankBadgeRewardData.isValid;
    }
}
// File: contracts/Admin/LuxOnAuthority.sol


pragma solidity ^0.8.16;


contract LuxOnAuthority is Ownable {
    mapping (address => bool) blacklist;

    event Blacklist(address userAddress, uint256 timestamp, bool live);

    function isBlacklist(address user) public view returns (bool){
        return blacklist[user];
    }

    function setBlacklist(address[] memory userAddresses, bool _isBlacklist) external onlyOwner {
        for (uint256 i = 0; i < userAddresses.length; i++) {
            blacklist[userAddresses[i]] = _isBlacklist;
            emit Blacklist(userAddresses[i], block.timestamp, _isBlacklist);
        }
    }
}


// File: contracts/LUXON/utils/LuxOnBlacklist.sol


pragma solidity ^0.8.16;




contract LuxOnBlacklist is Ownable {
    address private luxOnAuthority;

    event SetLuxOnAuthority (address indexed luxOnAuthority);

    constructor(
        address _luxOnAuthority
    ){
        luxOnAuthority = _luxOnAuthority;
    }

    function getLuxOnAuthority() external view returns(address) {
        return luxOnAuthority;
    }

    function setLuxOnAuthority(address _luxOnAuthority) external onlyOwner{
        luxOnAuthority = _luxOnAuthority;
    }

    function getIsInBlacklist(address _userAddress) external view returns(bool) {
        return LuxOnAuthority(luxOnAuthority).isBlacklist(_userAddress);
    }

    modifier isBlacklist(address _userAddress) {
        // blacklist에 등록된 유저 => true / 등록되지 않은 유저 => false ---> !를 붙여서 반대 값으로 에러 발생 (true면 에러 발생)
        require(LuxOnAuthority(luxOnAuthority).isBlacklist(_userAddress) == false, "LuxOnBlacklist: This user is on the blacklist");
        _;
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
// File: contracts/LUXON/rank/RankStorage.sol


pragma solidity ^0.8.18;







contract RankStorage is LuxOnSuperOperators, LuxOnData {
    event SetReceive(address indexed userAddress, uint256 indexed rewardType, uint256 indexed receiveType);

    using SafeMath for uint256;

    // address => type(tier or badge) => receiveType => isReceive
    mapping(address => mapping(uint256 => mapping(uint256 => bool) )) public userReceiveState;
    //    // address => season => tier
    //    mapping(address => mapping(uint256 => uint256)) public userTier;
    //    // address => season => badgeType
    //    mapping(address => mapping(uint256 => uint256)) public userBadgeType;
    // address => type => receiveType => time
    mapping(address => mapping(uint256 => mapping(uint256 => uint256) )) public userReceiveTime;

    constructor(
        address dataAddress,
        string memory operator,
        address luxOnAdmin
    ) LuxOnData(dataAddress) LuxOnSuperOperators(operator, luxOnAdmin) {}

    function getReceiveState(address _address, uint256 rewardType, uint256 receiveType) public view returns (bool) {
        return userReceiveState[_address][rewardType][receiveType];
    }

    //    function getTier(address _address, uint256 season) public view returns (uint256) {
    //        return userTier[_address][season];
    //    }
    //
    //    function getBadgeType(address _address, uint256 season) public view returns (uint256) {
    //        return userBadgeType[_address][season];
    //    }

    function getReceiveTime(address _address, uint256 rewardType, uint256 receiveType) public view returns(uint256) {
        return userReceiveTime[_address][rewardType][receiveType];
    }

    function getUserRankInfo(address user, uint256 rewardType, uint256 receiveType ) public view returns (bool, uint256) {
        return (
        getReceiveState(user, rewardType, receiveType),
        getReceiveTime(user, rewardType, receiveType)
        );
    }

    function resetReceiveState(address _address, uint256 rewardType, uint256 receiveType) external onlySuperOperator {
        userReceiveState[_address][rewardType][receiveType] = false;
        userReceiveTime[_address][rewardType][receiveType] = 0;
    }

    function setReceive(address _address, uint256 rewardType, uint256 receiveType) external onlySuperOperator {
        userReceiveState[_address][rewardType][receiveType] = true;
        userReceiveTime[_address][rewardType][receiveType] = block.timestamp;
        emit SetReceive(_address, rewardType, receiveType);
    }
}

// File: contracts/LUXON/utils/IERC20LUXON.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.16;

interface IERC20LUXON {
    function paybackFrom() external view returns (address);

    function addAllowanceIfNeeded(address owner, address spender, uint256 amountNeeded) external returns (bool success);
    function approveFor(address owner, address spender, uint256 amount) external returns (bool success);

    function paybackByMint(address to, uint256 amount) external;
    function paybackByTransfer(address to, uint256 amount) external;
    function burnFor(address owner, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

// File: contracts/LUXON/utils/IERC1155LUXON.sol


pragma solidity ^0.8.16;

interface IERC1155LUXON {
    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data) external;
    function getValueChipType() external view returns(uint32);
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
}
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;


/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/LUXON/rank/SendRankReward.sol


pragma solidity ^0.8.18;







// import "./IRankStorage.sol";







contract SendRankReward is ReentrancyGuard, LuxOnData, ERC1155Holder, LuxOnLive, LuxOnBlacklist {
    event ReceiveRankReward(address indexed user, uint256 indexed id, uint256 receiveType);
    event SendReward(address indexed user, address indexed to, address indexed tokenAddress, uint256 tokenType, uint256 reward, uint256 rewardAmount);

    address constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 constant errorNo = 9999;

    RankStorage public rankStorage;
    // goods type => address
    mapping(uint256 => RewardInfo) public rewardAddresses;

    constructor(
        address dataAddress,
        address luxonService,
        address _rankStorage,
        address luxonAuthority
    ) LuxOnData(dataAddress) LuxOnLive(luxonService) LuxOnBlacklist(luxonAuthority){
        rankStorage = RankStorage(_rankStorage);
    }

    function setRewardAddress(RewardInfo[] memory rewardInfos) external onlyOwner {
        for (uint256 i = 0; i < rewardInfos.length; i++) {
            rewardAddresses[rewardInfos[i].goodsType] = rewardInfos[i];
        }
    }

    function setRankStorageAddress(address _rankStorage) external onlyOwner {
        rankStorage = RankStorage(_rankStorage);
    }

    function withdraw() external onlyOwner nonReentrant isBlacklist(msg.sender){
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function receiveRankReward(uint256 id) public nonReentrant isBlacklist(msg.sender){
        RankRewardCalender memory rankRewardCalender = RankRewardCalenderData(getDataAddress("RankRewardCalenderData")).getRankRewardCalendar(id);

        checkRewardReceiveValid(rankRewardCalender);

        (bool receiveState, uint256 receiveTime) = rankStorage.getUserRankInfo(msg.sender, uint256(rankRewardCalender.rewardType), uint256(rankRewardCalender.receiveType));
        require(receiveTime < rankRewardCalender.startAt, "already receive reward");

        if (uint256(RankRewardType.RankTier) == rankRewardCalender.rewardType) {
            // tier check
            uint256 tier = UserRankData(getDataAddress("UserRankData")).getTier(msg.sender, rankRewardCalender.season);
            require(uint256(RankTier.NONE) != tier, "user tier is none");

            uint256[] memory rewardIds = rankRewardCalender.rewardIds.rewardId[tier];
            RankReward[] memory rankRewards = RankRewardData(getDataAddress("RankRewardData")).getRankRewards(rewardIds);

            Reward[] memory rewards = new Reward[](rankRewards.length);
            for (uint256 i = 0; i < rankRewards.length; i++) {

                require(rankRewardCalender.receiveType == rankRewards[i].receiveType, "Invalid Data: RewardCalender receiveType Not Match RewardData Receive Type");
                require(tier == rankRewards[i].tier, "Invalid Data: RewardData tier Not Match user tier");
                Reward memory reward = rewards[i];
                reward.rewardType = rankRewards[i].rewardType;
                reward.reward = rankRewards[i].reward;
                reward.rewardAmount = rankRewards[i].rewardAmount;
            }
            require(0 != rewards.length, "not exist reward data");
            sendReward(msg.sender, rewards);
        } else if (uint256(RankRewardType.Badge) == rankRewardCalender.rewardType) {
            uint256 badge = UserRankData(getDataAddress("UserRankData")).getBadge(msg.sender, rankRewardCalender.season);
            require(uint256(BadgeType.NONE) != badge, "user badge is none");

            for (uint i = 1; i <= badge; i++) {
                uint256[] memory rewardIds = rankRewardCalender.rewardIds.rewardId[i];
                RankBadgeReward[] memory rankBadgeRewards = RankRewardData(getDataAddress("RankRewardData")).getRankBadgeRewards(rewardIds);
                Reward[] memory rewards = new Reward[](rankBadgeRewards.length);

                for(uint j = 0; j < rankBadgeRewards.length; j++) {
                    require(rankRewardCalender.receiveType == rankBadgeRewards[j].receiveType, "Invalid Data: RewardCalender receiveType Not Match RewardData Receive Type");
                    require(rankBadgeRewards[j].badgeType <= badge, "Invalid Data: RewardData badge Not Match user badge");
                    Reward memory reward = rewards[j];
                    reward.rewardType = rankBadgeRewards[j].rewardType;
                    reward.reward = rankBadgeRewards[j].reward;
                    reward.rewardAmount = rankBadgeRewards[j].rewardAmount;
                }
                require(0 != rewards.length, "not exist reward data");
                sendReward(msg.sender, rewards);
            }
        }

        rankStorage.setReceive(msg.sender, rankRewardCalender.rewardType, rankRewardCalender.receiveType);
        emit ReceiveRankReward(msg.sender, id, rankRewardCalender.receiveType);
    }

    function checkRewardReceiveValid(RankRewardCalender memory rankRewardCalender) private view {
        require(rankRewardCalender.isValid, "rank reward not valid");
        require(rankRewardCalender.startAt <= block.timestamp && block.timestamp < rankRewardCalender.endAt, "rank reward not open");
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function sendReward(address _to, Reward[] memory _rewards) private {
        for (uint256 i = 0; i < _rewards.length; i++) {
            RewardInfo memory rewardInfo = rewardAddresses[_rewards[i].rewardType];
            require(rewardInfo.isValid, "reward not valid");
            if (uint256(TokenType.ERC1155) == rewardInfo.tokenType) {
                IERC1155LUXON(rewardInfo.tokenAddress).mint(_to, _rewards[i].reward, _rewards[i].rewardAmount,"");
            } else if (uint256(TokenType.ERC20) == rewardInfo.tokenType) {
                IERC20LUXON(rewardInfo.tokenAddress).transfer(_to, _rewards[i].rewardAmount);
            } else if (uint256(TokenType.ERC721) == rewardInfo.tokenType) {
                IERC721(rewardInfo.tokenAddress).transferFrom(address(this), _to, _rewards[i].reward);
            } else {
                revert("INVALID Reward type");
            }
            emit SendReward(msg.sender, _to, rewardInfo.tokenAddress, uint256(rewardInfo.tokenType), _rewards[i].reward, _rewards[i].rewardAmount);
        }
    }
}