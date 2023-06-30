// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../../interfaces/ISettlementModule.sol";

interface MurmesInterface {
    function isOperator(address operator) external view returns (bool);

    function updateLockedReward(
        address platform,
        uint256 day,
        int256 amount,
        address user
    ) external;
}

contract SettlementOneTime0 is ISettlementModule {
    /**
     * @notice Murmes主合约地址
     */
    address public Murmes;
    /**
     * @notice 记录每个Item的详细结算信息
     */
    mapping(uint256 => ItemSettlement) settlements;

    constructor(address ms) {
        Murmes = ms;
    }

    // Fn 1
    modifier auth() {
        require(MurmesInterface(Murmes).isOperator(msg.sender), "SO15");
        _;
    }

    /**
     * @notice 完成结算策略为分成的申请的结算
     * @param taskId 结算策略为一次性结算的申请ID
     * @param platform 任务所属平台的区块链地址
     * @param maker Item制作者区块链地址
     * @param auditorDivide 该平台设置的审核员分成Item制作者收益的比例
     * @param supporters 申请下被采纳Item的支持者们
     * @return 本次结算所支付的Item制作费用
     * Fn 2
     */
    function settlement(
        uint256 taskId,
        address platform,
        address maker,
        uint256,
        uint16 auditorDivide,
        address[] memory supporters
    ) external override auth returns (uint256) {
        uint256 itemGet;
        if (settlements[taskId].unsettled > 0) {
            itemGet = settlements[taskId].unsettled;
            uint256 supporterGet = (itemGet * auditorDivide) /
                Constant.BASE_RATE;
            uint256 divide = supporterGet / supporters.length;

            for (uint256 i = 0; i < supporters.length; i++) {
                MurmesInterface(Murmes).updateLockedReward(
                    platform,
                    block.timestamp / 86400,
                    int256(divide),
                    supporters[i]
                );
            }

            MurmesInterface(Murmes).updateLockedReward(
                platform,
                block.timestamp / 86400,
                int256(itemGet - divide * supporters.length),
                maker
            );

            settlements[taskId].settled += itemGet;
            settlements[taskId].unsettled -= itemGet;
        }
        return itemGet;
    }

    /**
     * @notice 更新相应申请下被采纳Item的预期收益情况
     * @param taskId 结算策略为分成结算的申请ID
     * @param amount 申请中设置的支付代币数
     * Fn 3
     */
    function updateDebtOrRevenue(
        uint256 taskId,
        uint256,
        uint256 amount,
        uint16
    ) external override auth {
        settlements[taskId].unsettled += amount;
    }

    /**
     * @notice 更改特定申请的未结算代币数，为仲裁服务
     * @param taskId 申请的 ID
     * @param amount 恢复的代币数量
     * Fn 4
     */
    function resetSettlement(
        uint256 taskId,
        uint256 amount
    ) external override auth {
        settlements[taskId].unsettled += amount;
        settlements[taskId].settled -= amount;
    }

    // ***************** View Functions *****************
    function getItemSettlement(
        uint256 taskId
    ) external view override returns (ItemSettlement memory) {
        return settlements[taskId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Constant} from "../libraries/Constant.sol";

struct ItemSettlement {
    uint256 settled;
    uint256 unsettled;
}

interface ISettlementModule {
    function Murmes() external view returns (address);

    function settlement(
        uint256 taskId,
        address platform,
        address maker,
        uint256 unsettled,
        uint16 auditorDivide,
        address[] memory supporters
    ) external returns (uint256);

    function updateDebtOrRevenue(
        uint256 taskId,
        uint256 number,
        uint256 amount,
        uint16 rateCountsToProfit
    ) external;

    function resetSettlement(uint256 taskId, uint256 amount) external;

    function getItemSettlement(
        uint256 taskId
    ) external view returns (ItemSettlement memory);
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