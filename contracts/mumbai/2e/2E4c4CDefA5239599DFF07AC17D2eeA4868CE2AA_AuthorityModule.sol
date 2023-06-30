// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IPlatforms.sol";
import "../interfaces/IAuthorityBase.sol";
import "../interfaces/IComponentGlobal.sol";
import "../interfaces/IAuthorityModule.sol";

interface MurmesInterface {
    function isOperator(address operator) external view returns (bool);
}

contract AuthorityModule is IAuthorityModule {
    /**
     * @notice Murmes主合约地址
     */
    address public Murmes;
    /**
     * @notice 当采用分成结算策略时，单个Box已经分成过的比例
     */
    mapping(uint256 => uint16) occupied;

    constructor(address ms) {
        Murmes = ms;
    }

    /**
     * @notice 判断调用者的申请权限
     * @param components Murmes全局组件合约
     * @param platform 所属平台地址
     * @param boxId box在第三方平台内的ID
     * @param source box源地址
     * @param caller 调用者
     * @param settlement 结算策略
     * @param amount 支付数量/比例
     * @return 在协议内该box的ID
     * Fn 1
     */
    function formatBoxIdOfPostTask(
        address components,
        address platform,
        uint256 boxId,
        string memory source,
        address caller,
        DataTypes.SettlementType settlement,
        uint256 amount
    ) external override returns (uint256) {
        require(msg.sender == Murmes, "AYM15");
        if (settlement == DataTypes.SettlementType.DIVIDEND) {
            require(
                uint16(amount) + occupied[boxId] <= Constant.MAX_TOTAL_DIVIDED,
                "AYM11"
            );
            occupied[boxId] += uint16(amount);
        }
        address platforms = IComponentGlobal(components).platforms();
        address authorityModule = IPlatforms(platforms)
            .getPlatformAuthorityModule(platform);

        uint256 id = IAuthorityBase(authorityModule).forPostTask(
            platform,
            boxId,
            source,
            caller,
            settlement
        );

        return id;
    }

    /**
     * @notice 判断调用者是否有创建Box的权限
     * @param platform Box所属平台
     * @param platformId Box所属平台的ID
     * @param authorityModule Box所属平台设置的特殊权限合约
     * @param caller 调用者
     * Fn 2
     */
    function isOwnCreateBoxAuthority(
        address platform,
        uint256 platformId,
        address authorityModule,
        address caller
    ) external view override returns (bool) {
        return
            IAuthorityBase(authorityModule).forCreateBox(
                platform,
                platformId,
                caller
            );
    }

    /**
     * @notice 判断调用者是否有更新Box收益的权限
     * @param realId Box在第三方平台内的真实ID
     * @param counts 收益数目
     * @param platform 第三方平台地址
     * @param caller 调用者
     * @param authorityModule Box所属平台设置的特殊权限合约
     * @return 实际可更新的收益
     * Fn 3
     */
    function formatCountsOfUpdateBoxRevenue(
        uint256 realId,
        uint256 counts,
        address platform,
        address caller,
        address authorityModule
    ) external override returns (uint256) {
        require(MurmesInterface(Murmes).isOperator(msg.sender), "AYM35");
        return
            IAuthorityBase(authorityModule).forUpdateBoxRevenue(
                realId,
                counts,
                platform,
                caller
            );
    }

    /**
     * @notice 更新Box已使用的分成比例
     * @param boxId Box的唯一ID
     * @param amount 新增使用
     */
    function updateTaskAmountOccupied(uint256 boxId, uint256 amount) external {
        require(msg.sender == Murmes, "AYW45");
        occupied[boxId] += uint16(amount);
        require(
            uint16(amount) + occupied[boxId] <= Constant.MAX_TOTAL_DIVIDED,
            "AYM41"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {DataTypes} from "../libraries/DataTypes.sol";

interface IPlatforms {
    function Murmes() external view returns (address);

    function createBox(
        uint256 id,
        address from,
        address creator
    ) external returns (uint256);

    function setPlatformRate(uint16 rate1, uint16 rate2) external;

    function updateBoxTasksByMurmes(
        uint256 boxId,
        uint256[] memory tasks
    ) external;

    function updateBoxesRevenue(
        uint256[] memory ids,
        uint256[] memory
    ) external;

    function updateBoxUnsettledRevenueByMurmes(
        uint256 boxId,
        int256 differ
    ) external;

    function getBox(
        uint256 boxId
    ) external view returns (DataTypes.BoxStruct memory);

    function getBoxTasks(
        uint256 boxId
    ) external view returns (uint256[] memory);

    function getBoxOrderIdByRealId(
        address platfrom,
        uint256 realId
    ) external view returns (uint256);

    function getPlatform(
        address platform
    ) external view returns (DataTypes.PlatformStruct memory);

    function getPlatformRate(
        address platform
    ) external view returns (uint16, uint16);

    function getPlatformIdByAddress(
        address platform
    ) external view returns (uint256);

    function getPlatformAuthorityModule(
        address platform
    ) external view returns (address);

    event RegisterPlatform(
        address platform,
        string name,
        string symbol,
        uint16 rate1,
        uint16 rate2,
        address authority
    );
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import {DataTypes} from "../libraries/DataTypes.sol";

interface IAuthorityBase {
    function forPostTask(
        address platform,
        uint256 boxId,
        string memory source,
        address caller,
        DataTypes.SettlementType settlement
    ) external returns (uint256);

    function forCreateBox(
        address platform,
        uint256 platformId,
        address caller
    ) external view returns (bool);

    function forUpdateBoxRevenue(
        uint256 realId,
        uint256 counts,
        address platform,
        address caller
    ) external returns (uint256);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IComponentGlobal {
    function Murmes() external view returns (address);

    function vault() external view returns (address);

    function access() external view returns (address);

    function version() external view returns (address);

    function platforms() external view returns (address);

    function settlement() external view returns (address);

    function authority() external view returns (address);

    function arbitration() external view returns (address);

    function itemToken() external view returns (address);

    function platformToken() external view returns (address);

    function defaultDepositableToken() external view returns (address);

    function lockUpTime() external view returns (uint256);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import {Constant} from "../libraries/Constant.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

interface IAuthorityModule {
    function Murmes() external view returns (address);

    function isOwnCreateBoxAuthority(
        address platform,
        uint256 platformId,
        address authorityModule,
        address caller
    ) external view returns (bool);

    function formatCountsOfUpdateBoxRevenue(
        uint256 realId,
        uint256 counts,
        address platform,
        address caller,
        address authorityModule
    ) external returns (uint256);

    function formatBoxIdOfPostTask(
        address components,
        address platform,
        uint256 boxId,
        string memory source,
        address caller,
        DataTypes.SettlementType settlement,
        uint256 amount
    ) external returns (uint256);

    function updateTaskAmountOccupied(uint256 boxId, uint256 amount) external;
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