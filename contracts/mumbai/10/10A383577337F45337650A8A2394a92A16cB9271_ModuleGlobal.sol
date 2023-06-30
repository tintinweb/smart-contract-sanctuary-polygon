// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IModuleGlobal.sol";
import {Events} from "../libraries/Events.sol";

interface MurmesInterface {
    function owner() external view returns (address);

    function setOperatorByTool(address old, address replace) external;
}

contract ModuleGlobal is IModuleGlobal {
    /**
     * @notice Murmes主合约地址
     */
    address public Murmes;
    /**
     * @notice 记录白名单内的审核（Item状态改变）模块合约地址
     */
    mapping(address => bool) whitelistAuditModule;
    /**
     * @notice 记录白名单内的个人守护模块合约地址
     */
    mapping(address => bool) whitelistGuardModule;
    /**
     * @notice 记录白名单内的Item检测模块合约地址
     */
    mapping(address => bool) whitelistDetectionModule;
    /**
     * @notice 记录白名单内的特殊权限模块合约地址
     */
    mapping(address => bool) whitelistAuthorityModule;
    /**
     * @notice 记录不同结算策略的模块合约地址
     */
    mapping(DataTypes.SettlementType => address) settlementModule;
    /**
     * @notice 记录白名单内的代币合约地址
     */
    mapping(address => bool) whitelistCurrency;

    constructor(address ms) {
        Murmes = ms;
        whitelistCurrency[address(0)] = true;
    }

    // Fn 1
    modifier auth() {
        require(MurmesInterface(Murmes).owner() == msg.sender, "M15");
        _;
    }

    /**
     * @notice 设置执行结算逻辑的合约地址
     * @param moduleId 结算类型
     * @param module 合约地址
     * Fn 2
     */
    function setSettlementModule(
        DataTypes.SettlementType moduleId,
        address module
    ) external auth {
        MurmesInterface(Murmes).setOperatorByTool(
            settlementModule[moduleId],
            module
        );
        settlementModule[moduleId] = module;
        emit Events.MurmesSetSettlementModule(moduleId, module);
    }

    /**
     * @notice 设置支持的用于支付的代币
     * @param currency 代币合约地址
     * @param result 加入或撤出白名单
     * Fn 3
     */
    function setWhitelistedCurrency(
        address currency,
        bool result
    ) external auth {
        whitelistCurrency[currency] = result;
        emit Events.MurmesSetCurrencyIsWhitelisted(currency, result);
    }

    /**
     * @notice 设置支持的守护合约
     * @param guard 守护模块合约地址
     * @param result 加入或撤出白名单
     * Fn 4
     */
    function setWhitelistedGuardModule(
        address guard,
        bool result
    ) external auth {
        whitelistGuardModule[guard] = result;
        emit Events.MurmesSetGuardModuleIsWhitelisted(guard, result);
    }

    /**
     * @notice 设置支持的审核合约
     * @param module 审核模块合约地址
     * @param result 加入或撤出白名单
     * Fn 5
     */
    function setWhitelistedAuditModule(
        address module,
        bool result
    ) external auth {
        whitelistAuditModule[module] = result;
        emit Events.MurmesSetAuditModuleIsWhitelisted(module, result);
    }

    /**
     * @notice 设置支持的检测合约
     * @param module 检测模块合约地址
     * @param result 加入或撤出白名单
     * Fn 6
     */
    function setDetectionModuleIsWhitelisted(
        address module,
        bool result
    ) external auth {
        whitelistDetectionModule[module] = result;
        emit Events.MurmesSetDetectionModuleIsWhitelisted(module, result);
    }

    /**
     * @notice 设置支持的平台权限控制模块
     * @param module 权限控制模块合约地址
     * @param result 加入或撤出白名单
     * Fn 7
     */
    function setAuthorityModuleIsWhitelisted(
        address module,
        bool result
    ) external auth {
        whitelistAuthorityModule[module] = result;
        emit Events.MurmesSetAuthorityModuleIsWhitelisted(module, result);
    }

    // ***************** View Functions *****************
    function isAuditModuleWhitelisted(
        address module
    ) external view override returns (bool) {
        return whitelistAuditModule[module];
    }

    function isDetectionModuleWhitelisted(
        address module
    ) external view override returns (bool) {
        return whitelistDetectionModule[module];
    }

    function isGuardModuleWhitelisted(
        address module
    ) external view override returns (bool) {
        return whitelistGuardModule[module];
    }

    function isAuthorityModuleWhitelisted(
        address module
    ) external view override returns (bool) {
        return whitelistAuthorityModule[module];
    }

    function isCurrencyWhitelisted(
        address currency
    ) external view override returns (bool) {
        return whitelistCurrency[currency];
    }

    function isPostTaskModuleValid(
        address currency,
        address audit,
        address detection
    ) external view override returns (bool) {
        bool can = true;
        if (
            !whitelistCurrency[currency] ||
            !whitelistAuditModule[audit] ||
            !whitelistDetectionModule[detection]
        ) {
            can = false;
        }
        return can;
    }

    function getSettlementModuleAddress(
        DataTypes.SettlementType moduleId
    ) external view override returns (address) {
        return settlementModule[moduleId];
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import {DataTypes} from "../libraries/DataTypes.sol";

interface IModuleGlobal {
    function Murmes() external view returns (address);

    function isAuditModuleWhitelisted(
        address module
    ) external view returns (bool);

    function isDetectionModuleWhitelisted(
        address module
    ) external view returns (bool);

    function isGuardModuleWhitelisted(
        address module
    ) external view returns (bool);

    function isAuthorityModuleWhitelisted(
        address module
    ) external view returns (bool);

    function isCurrencyWhitelisted(
        address currency
    ) external view returns (bool);

    function isPostTaskModuleValid(
        address currency,
        address audit,
        address detection
    ) external view returns (bool);

    function getSettlementModuleAddress(
        DataTypes.SettlementType moduleId
    ) external view returns (address);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import {DataTypes} from "./DataTypes.sol";

library Events {
    /**********Murmes-Ownable**********/
    event OperatorStateUpdate(address operator, bool state);
    /**********Murmes-EntityManager**********/
    event RegisterRepuire(string require, uint256 id);
    event UserJoin(address user, uint256 reputation, int256 deposit);
    event UserBaseDataUpdate(
        address user,
        int256 reputationSpread,
        int256 tokenSpread
    );
    event UserGuardUpdate(address user, address guard);
    event UserWithdrawDeposit(address user, uint256 amount);
    event UserLockedRevenueUpdate(
        address user,
        address platform,
        uint256 day,
        int256 revenue
    );
    /**********Murmes-ItemManager**********/
    event ItemStateUpdate(uint256 itemId, DataTypes.ItemState state);
    /**********Murmes-TaskManager**********/
    event TaskStateUpdate(uint256 taskId, uint256 plusAmount, uint256 plusTime);
    event TaskCancelled(uint256 taskId);
    event TaskReset(uint256 taskId, uint256 amount);
    /**********Murmes**********/
    event TaskPosted(
        DataTypes.PostTaskData vars,
        uint256 taskId,
        address caller
    );
    event ItemSubmitted(
        DataTypes.ItemMetadata vars,
        uint256 itemId,
        address maker
    );
    event ItemAudited(
        uint256 itemId,
        DataTypes.AuditAttitude attitude,
        address auditor
    );
    event UserWithdrawRevenue(
        address platform,
        uint256[] day,
        uint256 all,
        address caller
    );
    /**********Arbitration**********/
    event ReportPosted(
        DataTypes.ReportReason reason,
        uint256 itemId,
        uint256 proofSubtitleId,
        string otherProof,
        address reporter
    );
    event ReportResult(uint256 reportId, string resultProof, bool result);
    /**********ComponentGlobal**********/
    event MurmesSetComponent(uint8 id, address components);
    event MurmesSetLockUpTime(uint256 oldTime, uint256 newTime);
    /**********ModuleGlobal**********/
    event MurmesSetCurrencyIsWhitelisted(address token, bool result);
    event MurmesSetGuardModuleIsWhitelisted(address guard, bool result);
    event MurmesSetAuditModuleIsWhitelisted(address module, bool result);
    event MurmesSetDetectionModuleIsWhitelisted(address module, bool result);
    event MurmesSetAuthorityModuleIsWhitelisted(address module, bool result);
    event MurmesSetSettlementModule(
        DataTypes.SettlementType moduleId,
        address module
    );
    /**********Platforms**********/
    event RegisterPlatform(
        address platform,
        string name,
        string symbol,
        uint16 rate1,
        uint16 rate2,
        address authority,
        uint256 platformId
    );
    event PlatformStateUpdate(address platform, uint16 rate1, uint16 rate2);
    event BoxCreated(
        uint256 realId,
        address platform,
        address creator,
        uint256 boxId
    );
    event BoxRevenueUpdate(uint256 id, uint256 amounts, address caller);
    /**********Vault**********/
    event MurmesSetFee(uint16 oldFee, uint16 newFee);
    event PenaltyTransferred(address token, address to, uint256 amount);
    /**********ItemVersionManagement**********/
    event ItemVersionReportInvaild(uint256 itemId, uint256 versionId);
    event ItemVersionUpdate(
        uint256 itemId,
        uint256 fingerprint,
        string source,
        uint256 versionId
    );
    /**********Settlement**********/
    event ItemRevenueUpdate(uint256 taskId, uint256 counts);
    event ExtractRevenuePre(uint256 taskId, address caller);
    event ExtractRevenue(uint256 taskId, address caller);
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