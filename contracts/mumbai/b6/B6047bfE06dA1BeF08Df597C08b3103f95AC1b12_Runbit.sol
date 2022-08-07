// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IRunbit.sol";

contract Runbit is AccessControl {
    bytes32 public constant MANAGE_ROLE = keccak256("MANAGE_ROLE");

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGE_ROLE, admin);
    }
    // 精度为1e18
    struct RewardRate {
        // 跑道与装备不匹配，需要衰减的比例x1000000000000000000
        uint64 trackDecay;
        // 步数不达标，需要衰减，没少一步需要减少的比例，x1000000000000000000
        uint64 stepDecay;
        // 拥挤衰减，每多一个卡片级需要衰减的比例，x1000000000000000000
        uint64 jamDecay;
        // 计算comfort的收益是，拥挤衰减要减去这个值
        uint64 comfortBuff;
        // 赛道上卡片级超过这个值时收益开始衰减
        uint64 trackCapacity;
        // 最多衰减量，超过这个卡片级，停止衰减
        uint64 trackLimit;
        // 每个specialty可获得的rb
        uint128 specialty;
        // 每个aesthetic可获得的rb
        uint112 aesthetic;
        // 每个comfort可获得的rb
        uint112 comfort;
        // 最少要跑到的步数
        uint32 minSteps;
    }

    struct StepCount {
        uint64 count;
        uint64 equipType;
        uint64 trackId;
    }

    struct EquipInfo {
        address owner;
        uint64 emptyId;
        uint32 latestDay;
    }

    struct CardInfo {
        uint64 equipId;
        uint64 idx;
    }

    struct UserState {
        uint8 status; // 0 未收获，1 已收获
        uint8 lottery; // 0 未抽奖，1 已抽奖
        uint16 trackId;
        uint32 cardCount;
        uint64 lastSteps;
        uint128 RBReward;
    }

    struct DailyInfo {
        uint64 track0;
        uint64 track1;
        uint64 track2;
        uint64 userCount;
        uint64 totalSpecialty;
        uint64 totalComfort;
        uint64 totalAesthetic;
    }

    struct TrackInfo {
        uint64 latest;
        uint64 prev;
        uint64 updateDay;
    }

    struct LotteryInfo {
        uint128 RBRate; // 奖金/Aesthetic总值
        uint64 ETRate; // x100000000
        uint64 CTRate; // x100000000
        uint64 RBNum;  // 获奖RB的人数
        uint64 ETNum;  // 获奖装备碎片的人数
        uint64 CTNum;  // 获奖属性卡碎片的人数
    }
    // 周期长度
    uint256 epoch = 86400;
    // 直推奖励 精度1e8
    uint256 refRate;
    // 社区长福利 精度1e8
    uint256 bonusRate;
    IRefStore refs;
    IERC20Burnable RB;
    IRunbitRand randFactory;
    // can exchange card
    IERC20Burnable cardToken;
    // can exchange equipment
    IERC20Burnable equipToken;
    IRunbitCard NFTCard;
    IRunbitEquip NFTEquip;
    // step check contract
    IStepCheck stepCheck;
    RewardRate rewardRate;
    LotteryInfo baseLottery;
    mapping(address => uint256) RBReward;
    // userEquips[user][equipType] = equipTokenId
    mapping(address => mapping(uint256 => uint256)) userEquips;
    // equipCards[equipTokenId][index] = cardTokenId
    mapping(uint256 => mapping(uint256 => uint256)) equipCards;
    // cardConsume[cardTokenId] = days
    mapping(uint256 => uint256) cardConsume;
    // cardStepCount[cardTokenId][day] = count
    mapping(uint256 => mapping(uint256 => StepCount)) cardStepCount;
    // userCards[user][day][index] = cardId
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) userCards;
    // equipInfo[equipId] = info
    mapping(uint256 => EquipInfo) equipInfo;
    // cardInfo[cardId] = info
    mapping(uint256 => CardInfo) cardInfo;
    // userState[user][day] = state
    mapping(address => mapping(uint256 => UserState)) userState;
    // dailyInfo[day] = info
    mapping(uint256 => DailyInfo) dailyInfo;
    // userTrack[user] = TrackInfo
    mapping(address => TrackInfo) userTrack;
    // lotteryInfo[day] = LotteryInfo
    mapping(uint256 => LotteryInfo) lotterInfo;
    // lotteryRand[day] = rand
    mapping(uint256 => uint256) lotteryRand;
    // dailyBonus[day] = bonus
    mapping(uint256 => uint256) dailyBonus;


    modifier onlyReferral {
        require(refs.referrer(msg.sender) != address(0), "Not activated!");
        _;
    }
    
    // 第二天刚开始时调用该函数设置前一天的抽奖随机数
    function setRand() external onlyRole(MANAGE_ROLE) {
        uint256 day = _day() - 1;
        uint256 rand = randFactory.getRand(day);
        require(rand != 0, "not start!");
        lotterInfo[day] = baseLottery;
        lotteryRand[day] = rand;
        emit RandSet(day, rand);
    }
    
    // 领取抽奖
    function lottery(uint256 day) external onlyReferral {
        require(lotteryRand[day] != 0, "E01: not start!");
        UserState storage us = userState[msg.sender][day];
        require(us.lottery == 0 && us.cardCount > 0, "E02: no chance!");
        (uint256 RBAmount, uint256 CTAmount, uint256 ETAmount) = _calcLottery(msg.sender, day);
        // 标记为已领奖
        us.lottery = 1;
        if (RBAmount > 0) {
            RB.mint(msg.sender, RBAmount);
            emit LotteryRB(msg.sender, day, RBAmount);
        }
        if (CTAmount > 0) {
            cardToken.mint(msg.sender, CTAmount);
            emit LotteryCT(msg.sender, day, CTAmount);
        }
        //抽奖 装备碎片
        if (ETAmount > 0) {
            equipToken.mint(msg.sender, ETAmount);
            emit LotteryET(msg.sender, day, ETAmount);
        }
    }
    
    // 更换装备前先update
    function bindEquip(uint256 tokenId) external onlyReferral {
        EquipInfo memory ei = equipInfo[tokenId];
        address equipOwner = NFTEquip.ownerOf(tokenId);
        require(equipOwner != address(0), "E03: burned!");
        // 如果用户当天使用过该装备，则改天只能由该用户使用
        if (ei.latestDay == _day()) {
            require(ei.owner == msg.sender, "E01: owner check failed!");
        } else {
            require(equipOwner == msg.sender, "E02: owner check failed!");
        }
        IRunbitEquip.MetaData memory meta = NFTEquip.tokenMeta(tokenId);
        userEquips[msg.sender][meta.equipType] = tokenId;
        emit EquipBind(tokenId, msg.sender);
    }
    
    // 卸下装备
    function unbindEquip(uint256 equipType) external onlyReferral {
        userEquips[msg.sender][equipType] = 0;
        emit EquipUnbind(msg.sender, equipType);
    }

    // update steps
    function updateSteps(uint256 steps) external onlyReferral {
        steps = stepCheck.stepCheck(steps, msg.sender);
        uint256 today = _day();
        uint256 trackId = _trackId();
        UserState storage us = userState[msg.sender][today];
        DailyInfo storage dinf = dailyInfo[today];
        require(steps > us.lastSteps, "E01: no need to update!");
        // 用户首次更新
        if(us.lastSteps == 0) {
            dinf.userCount += 1;
            us.trackId = uint16(trackId);
        }
        steps -= us.lastSteps;
        us.lastSteps += uint64(steps);
        // 遍历三个装备
        for(uint i = 0; i < 3; ++i) {
            uint256 eid = userEquips[msg.sender][i];
            if (eid != 0) {
                EquipInfo storage info = equipInfo[eid];
                address equipOwner = NFTEquip.ownerOf(eid);
                // 装备是否被销毁
                if (equipOwner == address(0)) {
                    userEquips[msg.sender][i] = 0;
                    continue;
                }
                // 该装备首次更新
                if (info.latestDay != today) {
                    if (equipOwner == msg.sender) {
                        info.owner = msg.sender;
                        info.latestDay = uint32(today);
                    } else {
                        // 装备已经转走了
                        userEquips[msg.sender][i] = 0;
                        continue;
                    }
                }
                IRunbitEquip.MetaData memory meta = NFTEquip.tokenMeta(eid);
                for(uint j = 0; j < meta.capacity; ++j) {
                    uint256 cid = equipCards[eid][j];
                    if (cid != 0) {
                        StepCount storage sc = cardStepCount[cid][today];
                        IRunbitCard.MetaData memory cm = NFTCard.tokenMeta(cid);
                        // 判断耐久是否用完
                        if (cardConsume[cid] >= cm.durability) {
                            continue;
                        } 
                        // 首次update card
                        if (sc.count == 0) {
                            if (NFTCard.ownerOf(cid) != msg.sender) {
                                // 删除该属性卡
                                equipCards[eid][j] = 0;
                                // if (info.emptyId == meta.capacity) {
                                //     info.emptyId = uint64(j);
                                // }
                                continue;
                            }
                            // 更新每日统计信息
                            dinf.totalAesthetic += cm.aesthetic;
                            dinf.totalSpecialty += cm.specialty;
                            dinf.totalComfort += cm.comfort;
                            if (trackId == 0) {
                                dinf.track0 += cm.level;
                            } else if (trackId == 1) {
                                dinf.track1 += cm.level;
                            } else {
                                dinf.track2 += cm.level;
                            }
                            
                            // 记录属性卡使用信息
                            cardConsume[cid] += 1;
                            sc.equipType = uint64(i);
                            sc.trackId = uint64(trackId);
                            userCards[msg.sender][today][us.cardCount] = cid;
                            us.cardCount += 1;
                            emit CardUse(cid, msg.sender);
                        }
                        sc.count += uint64(steps);
                    }
                }
            }
        }
    }
    
    function bindCard(uint256 equipId, uint256 cardId, uint256 index) external onlyReferral {
        // 装备一旦使用，该天不允许更换属性卡
        require(equipInfo[equipId].latestDay != _day(), "Try it tomorrow!");
        require(NFTEquip.ownerOf(equipId) == msg.sender, "Not owner!");
        require(NFTCard.ownerOf(cardId) == msg.sender, "Not owner!");
        // require(cardStepCount[cid][today].count == 0, "Try it tomorrow!");
        IRunbitEquip.MetaData memory equip = NFTEquip.tokenMeta(equipId);
        IRunbitCard.MetaData memory card = NFTCard.tokenMeta(cardId);
        require(index < equip.capacity, "invalid index!");
        require(card.level <= equip.level, "invalid level!");
        equipCards[equipId][index] = cardId;
        emit CardBind(cardId, msg.sender, equipId, index);
    }

    function unbindCard(uint256 equipId, uint256 index) external onlyReferral {
        // 装备一旦使用，该天不允许更换属性卡
        require(equipInfo[equipId].latestDay != _day(), "Try it tomorrow!");
        require(NFTEquip.ownerOf(equipId) == msg.sender, "Not owner!");
        emit CardUnbind(equipCards[equipId][index], msg.sender, equipId, index);
        equipCards[equipId][index] = 0;
    }

    function updateTrack(uint256 trackId) external onlyReferral {
        TrackInfo storage ut = userTrack[msg.sender];
        uint256 today = _day();
        if (today == ut.updateDay) {
            ut.latest = uint64(trackId);
        } else {
            ut.updateDay = uint64(today); 
            ut.prev = ut.latest;
            ut.latest = uint64(trackId);
        }
        emit TrackChange(msg.sender, trackId);
    }
    
    // 用户计算所获奖励
    function harvest(uint256 startDay, uint256 endDay) external onlyReferral {
        for (uint day = startDay; day < endDay; ++day) {
            uint256 reward = _calcReward(msg.sender, day);
            if (reward > 0) {
                UserState storage us = userState[msg.sender][day];
                // 该天的奖励数
                us.RBReward = uint128(reward);
                us.status = 1;
                RBReward[msg.sender] += reward;
                // 直推奖励
                RBReward[refs.referrer(msg.sender)] += reward * refRate / 100000000;
                emit RBHarvest(msg.sender, reward, day);
                emit RefReward(refs.referrer(msg.sender), msg.sender, reward * refRate / 100000000, day);
            }
        }
    }

    //领取社区奖励
    function claimBonus(uint256 day, address to) external onlyRole(MANAGE_ROLE) {
        require(day < _day(), "too early!");
        require(dailyBonus[day] == 0, "already claim!");
        uint256 totalReward = 0;
        totalReward += uint256(dailyInfo[day].totalAesthetic) * rewardRate.aesthetic;
        totalReward += uint256(dailyInfo[day].totalSpecialty) * rewardRate.specialty;
        totalReward += uint256(dailyInfo[day].totalComfort) * rewardRate.comfort;
        uint256 amount = totalReward * bonusRate / 100000000;
        dailyBonus[day] = amount;
        RB.mint(to, amount);
        emit BonusClaim(day, amount);
    }

    // 领取RB
    function claim(uint256 amount, address to) external onlyReferral {
        require(amount <= RBReward[msg.sender], "E01: insufficient amount!");
        RBReward[msg.sender] -= amount;
        RB.mint(to, amount);
        emit RBClaim(msg.sender, to, amount);
    }

    function _calcReward(address user, uint256 day) private view returns (uint256) {
        uint256 reward = 0;
        UserState memory us = userState[user][day];
        uint256 trackCount;
        // 找出用户选的的跑道
        if (us.trackId == 0) {
            trackCount = dailyInfo[day].track0;
        } else if (us.trackId == 1) {
            trackCount = dailyInfo[day].track1;
        } else {
            trackCount = dailyInfo[day].track2;
        }
        //
        if (us.status == 0) {
            for(uint i = 0; i < us.cardCount; ++i) {
                uint256 cid = userCards[user][day][i];
                IRunbitCard.MetaData memory meta = NFTCard.tokenMeta(cid);
                StepCount memory sc = cardStepCount[cid][day];
                //功能收益
                uint256 baseReward = uint256(rewardRate.specialty) * meta.specialty;
                //美观收益
                baseReward += uint256(rewardRate.aesthetic) * meta.aesthetic;
                //舒适收益
                uint256 baseReward2 = uint256(rewardRate.comfort) * meta.comfort;
                // 跑道超过人数，需要衰减 
                if (trackCount > rewardRate.trackCapacity) {
                    if (trackCount > rewardRate.trackLimit) {
                        trackCount = rewardRate.trackLimit;
                    }
                    baseReward -= baseReward * (trackCount - rewardRate.trackCapacity) * rewardRate.jamDecay / 1000000000000000000;
                    //舒适度可以抵消一定的衰减
                    baseReward2 -= baseReward2 * (trackCount - rewardRate.trackCapacity) * (rewardRate.jamDecay - rewardRate.comfortBuff) / 1000000000000000000;
                }
                baseReward += baseReward2;
                // 跑道与装备不匹配，需要衰减
                if (sc.equipType != sc.trackId) {
                    baseReward -= baseReward * rewardRate.trackDecay / 1000000000000000000;
                }
                // 步数不达标，需要衰减
                if(sc.count < rewardRate.minSteps) {
                    baseReward -= baseReward * (rewardRate.minSteps - sc.count) * rewardRate.stepDecay / 1000000000000000000;
                }
                reward += baseReward;
            }
        }
        return reward;
    }

    function _calcLottery(address user, uint256 day) private view returns (uint256 RBAmount, uint256 CTAmount, uint256 ETAmount) {
        uint256 totalAesthetic = dailyInfo[day].totalAesthetic;
        uint256 aesthetic = 0;
        UserState memory us = userState[user][day];
        for(uint i = 0; i < us.cardCount; ++i) {
            uint256 cid = userCards[user][day][i];
            IRunbitCard.MetaData memory meta = NFTCard.tokenMeta(cid);
            aesthetic += meta.aesthetic;
        }
        LotteryInfo memory li = lotterInfo[day];
        //抽奖 RB
        uint256 rand = uint256(keccak256(abi.encodePacked(user, lotteryRand[day])));
        uint256 chance = rand % totalAesthetic;
        if (chance < li.RBNum * aesthetic) {
            RBAmount = totalAesthetic * li.RBRate;
        }
        //抽奖 属性卡碎片
        rand = uint256(keccak256(abi.encodePacked(user, rand)));
        chance = rand % totalAesthetic;
        if (chance < li.RBNum * aesthetic) {
            CTAmount = totalAesthetic * li.CTRate / 100000000;
        }
        //抽奖 装备碎片
        rand = uint256(keccak256(abi.encodePacked(user, rand)));
        chance = rand % totalAesthetic;
        if (chance < li.RBNum * aesthetic) {
            ETAmount = totalAesthetic * li.ETRate / 100000000;
        }
    }

    // 设置直推比例，例如：20% = 20,000,000
    function setRefRate(uint256 _rate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        refRate = _rate;
    }

    // 设置社区奖励，例如：20% = 20,000,000
    function setBonusRate(uint256 _rate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bonusRate = _rate;
    }

    function setRefs(address _refs) external onlyRole(DEFAULT_ADMIN_ROLE) {
        refs = IRefStore(_refs);
    }

    function setRB(address _rb) external onlyRole(DEFAULT_ADMIN_ROLE) {
        RB = IERC20Burnable(_rb);
    }

    function setCardToken(address _cardToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        cardToken = IERC20Burnable(_cardToken);
    }

    function setEquipToken(address _equipToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        equipToken = IERC20Burnable(_equipToken);
    }

    function setCardFactory(address _factory) external onlyRole(DEFAULT_ADMIN_ROLE) {
        NFTCard = IRunbitCard(_factory);
    }

    function setRandFactory(address _factory) external onlyRole(DEFAULT_ADMIN_ROLE) {
        randFactory = IRunbitRand(_factory);
    }

    function setEquipFactory(address _factory) external onlyRole(DEFAULT_ADMIN_ROLE) {
        NFTEquip = IRunbitEquip(_factory);
    }

    function setStepCheck(address _stepCheck) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stepCheck = IStepCheck(_stepCheck);
    }

    function setRewardRate(RewardRate memory rate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardRate = rate;
    }

    function setBaseLottery(LotteryInfo memory _baseLottery) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseLottery = _baseLottery;
    }

    function setEpoch(uint256 _epoch) external onlyRole(DEFAULT_ADMIN_ROLE) {
        epoch = _epoch;
    }

    function _day() private view returns (uint256) {
        return (block.timestamp + 28800) / epoch;
    }
    
    function _trackId() private view returns (uint256) {
        TrackInfo memory ut = userTrack[msg.sender];
        if (_day() == ut.updateDay) {
            return ut.prev;
        } else {
            return ut.latest;
        }
    }

    function getTrackId() external view returns (uint256) {
        return _trackId();
    }

    // 获取用户状态
    function getUserState(address user, uint256 day) external view returns (UserState memory us) {
        us = userState[user][day];
    }
    
    // 如果用户没有harvest，则需要用这个函数来计算出用户的收益
    function getUnharvestReward(address user, uint256 day) external view returns (uint256) {
        UserState memory us = userState[user][day];
        if (us.status == 1) {
            return us.RBReward;
        } else {
            return _calcReward(user, day);
        }
    }

    function getUnclaimReward(address user) external view returns (uint256) {
        return RBReward[user];
    }

    function getBindEquip(address user, uint256 equipType) external view returns (uint256) {
        return userEquips[user][equipType];
    }

    function getBindCard(uint256 equipId, uint256 index) external view returns (uint256) {
        return equipCards[equipId][index];
    }

    function getCardConsume(uint256 cardId) external view returns (uint256) {
        return cardConsume[cardId];
    }

    function getCardStepCount(uint256 cardId, uint256 day) external view returns (StepCount memory count) {
        count = cardStepCount[cardId][day];
    }

    function getEquipInfo(uint256 equipId) external view returns (EquipInfo memory info) {
        info = equipInfo[equipId];
    }

    function getCardInfo(uint256 cardId) external view returns (CardInfo memory info) {
        info = cardInfo[cardId];
    }

    function getDailyInfo(uint256 day) external view returns (DailyInfo memory info) {
        info = dailyInfo[day];
    }

    function getLotteryRand(uint256 day) external view returns (uint256) {
        return lotteryRand[day];
    }

    function getDailyBonus(uint256 day) external view returns (uint256) {
        return dailyBonus[day];
    }

    function isLucky(address user, uint256 day) external view returns (uint256, uint256, uint256) {
        return _calcLottery(user, day);
    }
    
    event EquipBind(uint256 indexed tokenId, address indexed user);
    event EquipUnbind(address indexed user, uint256 equipType);
    event CardUse(uint256 indexed tokenId, address indexed user);
    event CardBind(uint256 indexed cardId, address indexed user, uint256 equipId, uint256 index);
    event CardUnbind(uint256 indexed cardId, address indexed user, uint256 equipId, uint256 index);
    event TrackChange(address indexed user, uint256 trackId);
    event LotteryRB(address indexed user, uint256 day, uint256 amount);
    event LotteryCT(address indexed user, uint256 day, uint256 amount);
    event LotteryET(address indexed user, uint256 day, uint256 amount);
    event RBClaim(address indexed owner, address to, uint256 amount);
    event RBHarvest(address indexed user, uint256 amount, uint256 day);
    event RefReward(address indexed to, address from, uint256 amount, uint256 day);
    event RandSet(uint256 indexed day, uint256 rand);
    event BonusClaim(uint256 indexed day, uint256 amount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
pragma solidity ^0.8.14;

interface IRefStore {
    /// referrer
    function referrer(address from) external view returns (address);
    /// add referrer
    function addReferrer(address from, address to) external;
    /// referrer added
    event ReferrerAdded(address indexed to, address from);
}

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function mint(address to, uint256 amount) external;
}

interface IDataFeed {
    function latestAnswer()  external view returns (int256);
    function latestTimestamp() external view returns (uint256);
}

interface IRunbitRand {
    function getRand(uint256 round) external view returns (uint256);
}

interface IRunbitCard is IERC721 {
    struct MetaData {
        uint64 specialty;
        uint64 comfort;
        uint64 aesthetic;
        uint32 durability;
        uint32 level;
    }

    function safeMint(address to, uint256 tokenId, string memory uri, MetaData memory metaData) external;
    function tokenMeta(uint256 tokenId) external view returns (MetaData memory);
    function burn(uint256 tokenId) external;
}

interface IRunbitEquip is IERC721 {
    struct MetaData {
        uint32 equipType;
        uint32 upgradeable;
        uint64 level;
        uint64 capacity;
        uint64 quality;
    }

    function safeMint(address to, uint256 tokenId, string memory uri, MetaData memory metaData) external;
    function tokenMeta(uint256 tokenId) external view returns (MetaData memory);
    function burn(uint256 tokenId) external;
}

interface IStepCheck {
    function stepCheck(uint256 checkSum, address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}