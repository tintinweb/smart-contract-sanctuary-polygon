// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IAuthorityBase.sol";

contract MurmesAuthority is IAuthorityBase {
    /**
     * @notice 提交任务之前，判断提交者的权限
     * @param boxId 任务所属Box的ID
     * @param source 众包任务的源地址（详细说明）
     * @param settlement 众包任务所采用的结算策略
     * @return 实际与该众包任务关联Box的ID
     * Fn 1
     */
    function forPostTask(
        address,
        uint256 boxId,
        string memory source,
        address,
        DataTypes.SettlementType settlement
    ) external override returns (uint256) {
        require(settlement == DataTypes.SettlementType.ONETIME, "MA16");
        require(bytes(source).length > 0, "MA11");
        return boxId;
    }

    // Fn 2
    function forCreateBox(
        address,
        uint256,
        address
    ) external view override returns (bool) {
        return false;
    }

    // Fn 3
    function forUpdateBoxRevenue(
        uint256,
        uint256,
        address,
        address
    ) external override returns (uint256) {
        return 0;
    }
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