// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IAuditModule.sol";

interface MurmesInterface {
    function owner() external view returns (address);
}

contract AuditModule is IAuditModule {
    /**
     * @notice Murmes主合约地址
     */
    address public Murmes;
    /**
     * @notice 审核/检测的基本数目
     */
    uint256 public auditUnit;
    /**
     * @notice 介绍该模块的名称
     */
    string private _name;

    constructor(address ms, uint256 unit, string memory name_) {
        Murmes = ms;
        auditUnit = unit;
        _name = name_;
    }

    /**
     * @notice 设置新的审核/检测基本数目
     * @param newAuditUnit 新的审核/检测基本数目
     */
    function changeAuditUnit(uint256 newAuditUnit) external {
        require(MurmesInterface(Murmes).owner() == msg.sender, "ATM5");
        auditUnit = newAuditUnit;
        emit SetAuditUnit(newAuditUnit);
    }

    // ***************** Internal Functions *****************
    /**
     * @notice 判断Item是否被采纳
     * @param uploaded 众包任务下已上传的Item总数
     * @param support 当前Item获得的支持数
     * @param oppose 当前Item获得的反对数
     * @param allSupport 众包任务下已上传的Item获得的总支持数
     * @return state 最新的Item状态
     */
    function _adopt(
        uint256 uploaded,
        uint256 support,
        uint256 oppose,
        uint256 allSupport
    ) internal view returns (DataTypes.ItemState state) {
        if (uploaded > 1) {
            if (
                support > auditUnit &&
                ((support - oppose) >= (allSupport / uploaded))
            ) {
                state = DataTypes.ItemState.ADOPTED;
            }
        } else {
            if (
                support > auditUnit &&
                (((support - oppose) * 10) / (support + oppose) >= 6)
            ) {
                state = DataTypes.ItemState.ADOPTED;
            }
        }
    }

    /**
     * @notice 判断Item是否被“删除”
     * @param support 当前Item获得的支持数
     * @param oppose 当前Item获得的反对数
     * @return state 最新的Item状态
     */
    function _delete(
        uint256 support,
        uint256 oppose
    ) internal view returns (DataTypes.ItemState state) {
        if (support > 1) {
            if (oppose >= (auditUnit * support) / 2 + support) {
                state = DataTypes.ItemState.DELETED;
            }
        } else {
            if (oppose >= auditUnit + 1) {
                state = DataTypes.ItemState.DELETED;
            }
        }
    }

    // ***************** View Functions *****************
    /**
     * @notice 获得Item被审核/检测后的最新状态
     * @param uploaded 众包任务下已上传的Item总数
     * @param support 当前Item获得的支持数
     * @param oppose 当前Item获得的反对数
     * @param allSupport 众包任务下已上传的Item获得的总支持数
     * @param uploadTime Item上传时间
     * @param lockUpTime 审核/锁定期
     * @return state 最新的Item状态
     */
    function afterAuditItem(
        uint256 uploaded,
        uint256 support,
        uint256 oppose,
        uint256 allSupport,
        uint256 uploadTime,
        uint256 lockUpTime
    ) external view override returns (DataTypes.ItemState) {
        DataTypes.ItemState state1;
        if (block.timestamp >= uploadTime + lockUpTime) {
            state1 = _adopt(uploaded, support, oppose, allSupport);
        }
        DataTypes.ItemState state2 = _delete(support, oppose);
        if (state1 != DataTypes.ItemState.NORMAL) {
            return state1;
        } else if (state2 != DataTypes.ItemState.NORMAL) {
            return state2;
        } else {
            return DataTypes.ItemState.NORMAL;
        }
    }

    /**
     * @notice 获得模块的名称
     * @return 当前模块的名称
     */
    function name() external view returns (string memory) {
        return _name;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {DataTypes} from "../libraries/DataTypes.sol";

interface IAuditModule {
    function Murmes() external view returns (address);

    function name() external view returns (string memory);

    function auditUnit() external view returns (uint256);

    function afterAuditItem(
        uint256 uploaded,
        uint256 support,
        uint256 against,
        uint256 allSupport,
        uint256 uploadTime,
        uint256 lockUpTime
    ) external view returns (DataTypes.ItemState);

    event SetAuditUnit(uint256 nowAuditUnit);
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