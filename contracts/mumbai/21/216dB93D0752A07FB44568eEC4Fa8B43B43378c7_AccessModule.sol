// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IAccessModule.sol";

interface MurmesInterface {
    function owner() external view returns (address);
}

contract AccessModule is IAccessModule {
    /**
     * @notice Murmes主合约地址
     */
    address public Murmes;
    /**
     * @notice 奖惩倍数
     */
    uint8 public multiplier;
    /**
     * @notice 质押代币的基本数目
     */
    uint256 public depositUnit;
    /**
     * @notice 惩罚代币的基本数目
     */
    uint256 public punishmentUnit;

    constructor(address ms) {
        Murmes = ms;
        depositUnit = 32 * 10 ** 18;
        multiplier = 150;
        punishmentUnit = 1 * 10 ** 17;
    }

    modifier auth() {
        require(MurmesInterface(Murmes).owner() == msg.sender, "ASM15");
        _;
    }

    /**
     * @notice 设置新的质押代币基本数目
     * @param newDepositUnit 新的质押代币基本数目
     */
    function setDepositUnit(uint256 newDepositUnit) external auth {
        depositUnit = newDepositUnit;
        emit MurmesSetDepositUnit(newDepositUnit);
    }

    /**
     * @notice 设置新的惩罚代币基本数目
     * @param newPunishmentUnit 新的惩罚代币基本数目
     */
    function setPunishmentUnit(uint256 newPunishmentUnit) external auth {
        punishmentUnit = newPunishmentUnit;
        emit MurmesSetPunishmentUnit(newPunishmentUnit);
    }

    /**
     * @notice 设置新的奖惩倍数
     * @param newMultiplier 新的奖惩倍数
     */
    function setMultiplier(uint8 newMultiplier) external auth {
        multiplier = newMultiplier;
        emit MurmesSetMultiplier(newMultiplier);
    }

    // ***************** Internal Functions *****************
    function _sqrt(uint256 x) internal pure returns (uint256) {
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    // ***************** View Functions *****************
    /**
     * @notice 根据当前信誉度分数计算奖励时可额外获得的信誉度分数
     * @param reputation 当前信誉度分数
     * @return 可额外获得的信誉度分数
     */
    function reward(uint256 reputation) public pure returns (uint256) {
        return (reputation / Constant.ACTUAL_REPUTATION);
    }

    /**
     * @notice 根据当前信誉度分数计算惩罚时被扣除的信誉度分数
     * @param reputation 当前信誉度分数
     * @return 被扣除的信誉度分数
     */
    function punishment(uint256 reputation) public pure returns (uint256) {
        return (Constant.MAX_RATE / reputation);
    }

    /**
     * @notice 根据当前信誉度分数计算正常使用Murmes需要质押的代币数目
     * @param reputation 当前信誉度分数
     * @return 需要质押的代币数目
     */
    function deposit(uint256 reputation) public view returns (uint256) {
        if (reputation >= Constant.DEPOSIT_THRESHOLD) {
            return 0;
        } else {
            uint256 baseRate = (Constant.DEPOSIT_THRESHOLD - reputation) / 100;
            return depositUnit * (2 ** baseRate);
        }
    }

    /**
     * @notice 根据当前信誉度分数计算奖惩时信誉度分数和质押代币数目的变化
     * @param reputation 当前信誉度分数
     * @param flag 判断标志，1为奖励，2为惩罚
     * @return 信誉度分数和质押代币数目的变化
     */
    function variation(
        uint256 reputation,
        uint8 flag
    ) external view override returns (uint256, uint256) {
        if (flag == 1) {
            return (reward(reputation), 0);
        } else if (flag == 2) {
            if (reputation < Constant.DEPOSIT_THRESHOLD) {
                uint256 thisPunishment = punishment(reputation);
                return (thisPunishment, thisPunishment * punishmentUnit);
            } else {
                return (punishment(reputation), 0);
            }
        } else {
            return (0, 0);
        }
    }

    /**
     * @notice 根据当前信誉度分数和质押代币数判断用户是否能正常使用Murmes
     * @param reputation 当前信誉度分数
     * @param token 当前质押代币数
     * @return 是否能正常使用Murmes
     */
    function access(
        uint256 reputation,
        int256 token
    ) external view override returns (bool) {
        if (
            (reputation <= Constant.DEPOSIT_THRESHOLD &&
                token <= int256(deposit(reputation))) ||
            reputation <= Constant.BLACKLISTED_THRESHOLD
        ) {
            return false;
        } else {
            return true;
        }
    }

    /**
     * @notice 根据质押代币数判断用户是否有参与审核/检测的权限
     * @param token 当前质押代币数
     * @return 是否有参与审核/检测的权限
     */
    function auditable(int256 token) external pure override returns (bool) {
        return (token >= int256(Constant.DEPOSIT_THRESHOLD));
    }

    /**
     * @notice 根据当前信誉度，判断奖惩发生前用户的信誉度
     * @param reputation 当前信誉度
     * @param flag 判断条件，1为发生了奖励，2为进行了惩罚
     * @return 奖惩发生前用户的信誉度
     */
    function lastReputation(
        uint256 reputation,
        uint8 flag
    ) public pure override returns (uint256) {
        uint256 last = 0;
        if (flag == 2) {
            uint256 _4ac = 4 * Constant.MAX_RATE;
            uint256 _sqrtb2_4ac = _sqrt(reputation * reputation + _4ac);
            last = (reputation + _sqrtb2_4ac) / 2;
        } else if (flag == 1) {
            uint256 _base = Constant.ACTUAL_REPUTATION + 1;
            uint256 _up = reputation * Constant.ACTUAL_REPUTATION;
            last = _up / _base;
        }
        return last;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Constant} from "../libraries/Constant.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

interface IAccessModule {
    function Murmes() external returns (address);

    function variation(
        uint256 reputation,
        uint8 flag
    ) external view returns (uint256, uint256);

    function access(
        uint256 reputation,
        int256 deposit
    ) external view returns (bool);

    function auditable(int256 deposit_) external view returns (bool);

    function depositUnit() external view returns (uint256);

    function punishmentUnit() external view returns (uint256);

    function multiplier() external view returns (uint8);

    function reward(uint256 reputation) external pure returns (uint256);

    function punishment(uint256 reputation) external view returns (uint256);

    function lastReputation(
        uint256 reputation,
        uint8 flag
    ) external pure returns (uint256);

    function deposit(uint256 reputation) external view returns (uint256);

    event MurmesSetMultiplier(uint8 newMultiplier);
    event MurmesSetDepositUnit(uint256 newMinDepositUnit);
    event MurmesSetPunishmentUnit(uint256 newPunishmentTokenUnit);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

library Constant {
    uint8 constant BLACKLISTED_THRESHOLD = 1;

    uint16 constant BASE_RATE = 10000;

    uint16 constant BASE_REPUTATION = 1000;

    uint16 constant ACTUAL_REPUTATION = 100;

    uint16 constant MAX_TOTAL_DIVIDED = 7000;

    uint32 constant MAX_RATE = 100000;

    uint256 constant DEPOSIT_THRESHOLD = 600;

    uint256 constant MIN_PUNISHMENT_FOR_REPOTER = 8 * 10 ** 18;

    uint256 constant MIN_PUNISHMENT_FOR_VALIDATOR = 4 * 10 ** 18;

    uint256 constant MIN_COMPENSATE_FOR_USER = 1 * 10 ** 18;

    uint256 constant MIN_COMPENSATE_REPUTATION = 15;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

library DataTypes {
    enum ItemState {
        NORMAL, // 正常
        ADOPTED, // 被采纳
        DELETED // 被删除
    }

    enum AuditAttitude {
        SUPPORT, // 支持
        OPPOSE // 反对
    }

    enum SettlementType {
        ONETIME, // 一次性结算策略
        DIVIDEND, // 分成结算策略
        ONETIME_MORTGAGE // 一次性抵押结算策略
    }

    enum ReportReason {
        PLAGIARIZE, // 侵权
        WRONG, // 恶意
        MISTAKEN, // 误删
        MISMATCH // 指纹不对应
    }

    struct ItemStruct {
        DataTypes.ItemState state; // 当前状态
        uint256 taskId; // 所属众包任务ID
        address[] supporters; // 支持者们
        address[] opponents; // 反对者们
        uint256 stateChangeTime; // 最新的状态改变时间
    }

    struct ItemMetadata {
        uint256 taskId; // 所属任务ID
        string cid; // 内容标识符
        uint256 requireId; // 所需条件ID
        uint256 fingerprint; // 指纹值
    }

    struct UserStruct {
        uint256 reputation; // 信誉度分数
        uint256 operate; // 最新的操作时间
        address guard; // 守护模块合约地址
        int256 deposit; // 质押代币数
        mapping(address => mapping(uint256 => uint256)) locks; // 被锁定的收益
    }

    struct TaskStruct {
        address applicant; // 申请者
        address platform; // 所属平台
        uint256 boxId; // 所属Box ID
        uint256 requireId; // 所需条件ID
        string source; // 源地址
        DataTypes.SettlementType settlement; // 所采用的结算策略
        uint256 amount; // 支付数目/比例
        address currency; // 支付代币类型
        address auditModule; // 所采用的审核（Item状态改变）模块
        address detectionModule; // 所采用的Item检测模块
        uint256[] items; // 已上传的Item ID集合
        uint256 adopted; // 被采纳的Item ID
        uint256 deadline; // 截止/有效日期
    }

    struct PostTaskData {
        address platform; // 所属第三方平台
        uint256 sourceId; // 在第三方平台内的ID（在Murmes内的顺位）
        uint256 requireId; // 所需条件的ID
        string source; // 源地址
        DataTypes.SettlementType settlement; // 所采用的结算策略
        uint256 amount; // 支付数目/比例
        address currency; // 支付代币类型
        address auditModule; // 所采用的审核（Item状态改变）模块
        address detectionModule; // 所采用的Item检测模块
        uint256 deadline; // 截止/有效日期
    }

    struct PlatformStruct {
        string name; // 平台名称
        string symbol; // 平台标识符
        uint256 platformId; // 平台在Murems内的ID
        uint16 rateCountsToProfit; // 收益转化率
        uint16 rateAuditorDivide; // 审核分成率
        address authorityModule; // 所采用的特殊权限管理模块
    }

    struct BoxStruct {
        address platform; // 所属第三方平台
        uint256 id; // 唯一标识ID
        address creator; // 创作者地址
        uint256 unsettled; // 未结算收益数目
        uint256[] tasks; // 发出的众包任务ID集合
    }

    struct ReportStruct {
        address reporter; // 举报人地址
        DataTypes.ReportReason reason; // 举报原因
        uint256 itemId; // 被举报Item的ID
        uint256 uintProof; // 可选的证据
        string stringProof; // 可选的证据
        string resultProof; // 仲裁结果证明
        bool result; // 仲裁结果
    }

    struct VersionStruct {
        string source; // 源地址
        uint256 fingerprint; // 指纹值
        bool invalid; // 有效性
    }
}