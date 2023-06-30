// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IVault.sol";
import "../interfaces/IMurmes.sol";
import "../interfaces/IItemNFT.sol";
import "../interfaces/IArbitration.sol";
import "../interfaces/IAccessModule.sol";
import "../interfaces/IComponentGlobal.sol";
import "../interfaces/IItemVersionManagement.sol";
import {Constant} from "../libraries/Constant.sol";
import {Events} from "../libraries/Events.sol";

contract Arbitration is IArbitration {
    /**
     * @notice Murmes主合约地址
     */
    address public Murmes;
    /**
     * @notice 已产生的举报总数
     */
    uint256 public totalReports;
    /**
     * @notice 记录每个report的具体信息
     */
    mapping(uint256 => DataTypes.ReportStruct) reports;
    /**
     * @notice 记录与Item相关的所有举报ID
     */
    mapping(uint256 => uint256[]) itemReports;

    constructor(address ms) {
        Murmes = ms;
    }

    /**
     * @notice 发起一个新的举报
     * @param reason 举报理由/原因
     * @param itemId 被举报Item的ID
     * @param uintProof 证明材料，类型为 UINT
     * @param stringProof 证明材料，类型为 STRING
     * Fn 1
     */
    function report(
        DataTypes.ReportReason reason,
        uint256 itemId,
        uint256 uintProof,
        string memory stringProof
    ) external override returns (uint256) {
        {
            (uint256 reputation, int256 deposit) = IMurmes(Murmes)
                .getUserBaseData(msg.sender);
            address components = IMurmes(Murmes).componentGlobal();
            address access = IComponentGlobal(components).access();
            require(IAccessModule(access).access(reputation, deposit), "A15");
            require(
                deposit >= int256(IAccessModule(access).depositUnit()),
                "A15-2"
            );
            address itemNFT = IComponentGlobal(components).itemToken();
            require(IItemNFT(itemNFT).ownerOf(itemId) != address(0), "A11");
            DataTypes.ItemStruct memory item = IMurmes(Murmes).getItem(itemId);
            uint256 lockUpTime = IComponentGlobal(components).lockUpTime();
            require(
                block.timestamp <= item.stateChangeTime + lockUpTime,
                "A16"
            );
            if (reason != DataTypes.ReportReason.MISTAKEN) {
                require(item.state == DataTypes.ItemState.ADOPTED, "A11-2");
            } else {
                require(item.state == DataTypes.ItemState.DELETED, "A11-3");
            }
        }

        if (itemReports[itemId].length > 0) {
            for (uint256 i = 0; i < itemReports[itemId].length; i++) {
                uint256 reportId = itemReports[itemId][i];
                assert(reports[reportId].reason != reason);
            }
        }

        totalReports++;
        itemReports[itemId].push(totalReports);
        reports[totalReports].reason = reason;
        reports[totalReports].reporter = msg.sender;
        reports[totalReports].itemId = itemId;
        reports[totalReports].stringProof = stringProof;
        reports[totalReports].uintProof = uintProof;
        emit Events.ReportPosted(
            reason,
            itemId,
            uintProof,
            stringProof,
            msg.sender
        );
        return totalReports;
    }

    /**
     * @notice 由多签返回经由DAO审核后的结果
     * @param reportId 唯一标识举报的ID
     * @param resultProof 由链下DAO成员共识产生的摘要聚合而成的证明材料
     * @param result 审核结果，true表示举报合理，通过
     * @param params 为了节省链上结算成本和优化逻辑，一些必要的参数由链下提供，这里指的是已经支付的Item制作费用
     * Fn 2
     */
    function uploadDAOVerificationResult(
        uint256 reportId,
        string memory resultProof,
        bool result,
        uint256[] memory params
    ) external override {
        require(
            IMurmes(Murmes).multiSig() == msg.sender ||
                IMurmes(Murmes).owner() == msg.sender,
            "A25"
        );
        reports[reportId].resultProof = resultProof;
        reports[reportId].result = result;
        address components = IMurmes(Murmes).componentGlobal();
        address access = IComponentGlobal(components).access();
        if (result == true) {
            DataTypes.ItemStruct memory item = IMurmes(Murmes).getItem(
                reports[reportId].itemId
            );
            address itemNFT = IComponentGlobal(components).itemToken();
            (address maker, , ) = IItemNFT(itemNFT).getItemBaseData(
                reports[reportId].itemId
            );
            if (reports[reportId].reason != DataTypes.ReportReason.MISTAKEN) {
                _deleteItem(components, reports[reportId].itemId);
                _liquidatingMaliciousUser(access, item.supporters);
                _liquidatingNormalUser(access, components, item.opponents);
                _liquidatingItemMaker(maker, components, reportId);
                _processRevenue(
                    item.taskId,
                    params[0],
                    params[1],
                    params[2],
                    item.supporters,
                    maker,
                    params[3]
                );
            } else {
                _recoverItem(reports[reportId].itemId);
                _liquidatingMaliciousUser(access, item.opponents);
                _liquidatingNormalUser(access, components, item.supporters);
                _recoverItemMaker(maker, access, components);
            }
        } else {
            _punishRepoter(reportId, access);
        }
        emit Events.ReportResult(reportId, resultProof, result);
    }

    // ***************** Internal Functions *****************
    /**
     * @notice 当举报经由DAO审核不通过时，相应的reporter受到惩罚，这是为了防止恶意攻击的举措
     * @param reportId 唯一标识举报的ID
     * @param access Murmes合约的access模块合约地址
     * Fn 3
     */
    function _punishRepoter(uint256 reportId, address access) internal {
        address reporter = reports[reportId].reporter;
        (uint256 reputation, ) = IMurmes(Murmes).getUserBaseData(reporter);
        (uint256 reputationPunishment, uint256 tokenPunishment) = IAccessModule(
            access
        ).variation(reputation, 2);
        if (tokenPunishment == 0)
            tokenPunishment = Constant.MIN_PUNISHMENT_FOR_REPOTER;
        IMurmes(Murmes).updateUser(
            reporter,
            int256(reputationPunishment) * -1,
            int256(tokenPunishment) * -1
        );
    }

    /**
     * @notice 删除恶意Item，并撤销后续版本的有效性
     * @param components Murmes全局组件管理合约地址
     * @param itemId 被举报的Item的ID
     * Fn 4
     */
    function _deleteItem(address components, uint256 itemId) internal {
        IMurmes(Murmes).holdItemStateByDAO(itemId, DataTypes.ItemState.DELETED);
        address vm = IComponentGlobal(components).version();
        IItemVersionManagement(vm).reportInvalidVersion(itemId, 0);
    }

    /**
     * @notice 当Item是被恶意举报导致删除时，用于恢复Item的有效性，由于无法确定对后续版本的影响，并未对版本状态作更新，所以Item制作者可能蒙受损失
     * @param itemId 被举报的Item的ID
     * Fn 5
     */
    function _recoverItem(uint256 itemId) internal {
        IMurmes(Murmes).holdItemStateByDAO(itemId, DataTypes.ItemState.NORMAL);
    }

    /**
     * @notice 清算恶意评价者
     * @param access Murmes合约的access模块合约地址
     * @param users 恶意评价者
     * Fn 6
     */
    function _liquidatingMaliciousUser(
        address access,
        address[] memory users
    ) internal {
        for (uint256 i = 0; i < users.length; i++) {
            (uint256 reputation, ) = IMurmes(Murmes).getUserBaseData(users[i]);
            uint256 lastReputation = IAccessModule(access).lastReputation(
                reputation,
                1
            );
            // 一般来说，lastReputation 小于 reputation
            (
                uint256 reputationPunishment,
                uint256 tokenPunishment
            ) = IAccessModule(access).variation(lastReputation, 2);
            int256 variation = int256(lastReputation) -
                int256(reputation) -
                int256(reputationPunishment);
            uint256 punishmentToken = tokenPunishment >
                Constant.MIN_PUNISHMENT_FOR_VALIDATOR
                ? tokenPunishment
                : Constant.MIN_PUNISHMENT_FOR_VALIDATOR;
            IMurmes(Murmes).updateUser(
                users[i],
                variation,
                int256(punishmentToken) * -1
            );
        }
    }

    /**
     * @notice 恢复诚实评价者被系统扣除的信誉度和代币
     * @param access Murmes合约的access模块合约地址
     * @param components Murmes全局组件管理合约地址
     * @param users 诚实评价者
     * Fn 7
     */
    function _liquidatingNormalUser(
        address access,
        address components,
        address[] memory users
    ) internal {
        for (uint256 i = 0; i < users.length; i++) {
            (uint256 reputation, ) = IMurmes(Murmes).getUserBaseData(users[i]);
            uint256 lastReputation = IAccessModule(access).lastReputation(
                reputation,
                2
            );
            (, uint256 tokenReward) = IAccessModule(access).variation(
                lastReputation,
                2
            );
            // 一般来说，lastReputation 大于 reputation
            tokenReward = tokenReward > Constant.MIN_COMPENSATE_FOR_USER
                ? tokenReward
                : Constant.MIN_COMPENSATE_FOR_USER;
            int256 variation = int256(lastReputation) -
                int256(reputation) +
                int256(Constant.MIN_COMPENSATE_REPUTATION);
            address vault = IComponentGlobal(components).vault();
            address token = IComponentGlobal(components)
                .defaultDepositableToken();
            IVault(vault).transferPenalty(token, users[i], tokenReward);
            IMurmes(Murmes).updateUser(users[i], variation, 0);
        }
    }

    /**
     * @notice 清算恶意Item制作者
     * @param maker 恶意Item制作者
     * @param components Murmes全局组件管理合约地址
     * @param reportId 唯一标识举报的ID
     * Fn 8
     */
    function _liquidatingItemMaker(
        address maker,
        address components,
        uint256 reportId
    ) internal {
        (uint256 reputation, int256 deposit) = IMurmes(Murmes).getUserBaseData(
            maker
        );
        int256 oldDeposit = deposit;
        if (deposit < 0) oldDeposit = 0;

        IMurmes(Murmes).updateUser(
            maker,
            int256(reputation) * -1,
            int256(oldDeposit) * -1
        );
        if (deposit > 0) {
            _rewardRepoter(components, uint256(deposit), reportId);
        }
    }

    /**
     * @notice 奖励举报人，当举报验证通过时
     * @param components Murmes全局组件管理合约地址
     * @param deposit 恶意Item制作者被扣除的代币数
     * @param reportId 唯一标识举报的ID
     * Fn 9
     */
    function _rewardRepoter(
        address components,
        uint256 deposit,
        uint256 reportId
    ) internal {
        address vault = IComponentGlobal(components).vault();
        address token = IComponentGlobal(components).defaultDepositableToken();
        IVault(vault).transferPenalty(
            token,
            reports[reportId].reporter,
            deposit / 2
        );
    }

    /**
     * @notice 当Item被恶意举报导致删除时，恢复Item制作者被扣除的信誉度和代币
     * @param maker Item制作者
     * @param access Murmes的access模块合约地址
     * @param components Murmes全局组件管理合约地址
     * Fn 10
     */
    function _recoverItemMaker(
        address maker,
        address access,
        address components
    ) internal {
        (uint256 reputation, ) = IMurmes(Murmes).getUserBaseData(maker);
        uint256 lastReputation = IAccessModule(access).lastReputation(
            reputation,
            2
        );
        uint8 multipler = IAccessModule(access).multiplier();
        uint256 _reputationSpread = ((lastReputation - reputation) *
            multipler) / 100;
        lastReputation = reputation + _reputationSpread;

        (, uint256 tokenPunishment) = IAccessModule(access).variation(
            lastReputation,
            1
        );
        if (tokenPunishment > 0) {
            // 多补偿被扣掉代币数的百分之一
            address vault = IComponentGlobal(components).vault();
            address token = IComponentGlobal(components)
                .defaultDepositableToken();
            tokenPunishment = (tokenPunishment * (multipler + 1)) / 100;
            IVault(vault).transferPenalty(token, maker, tokenPunishment);
        }

        IMurmes(Murmes).updateUser(maker, int256(_reputationSpread), 0);
    }

    /**
     * @notice 清算收益
     * @param taskId 申请/任务 ID
     * @param share 在结算时每个Item支持者获得的代币数量
     * @param main Item制作者获得的代币数量
     * @param all 申请中设定的Item制作总费用
     * @param suppoters Item的支持者，分成收益的评价者
     * @param maker Item制作者
     * @param day 结算发生的日期
     * Fn 11
     */
    function _processRevenue(
        uint256 taskId,
        uint256 share,
        uint256 main,
        uint256 all,
        address[] memory suppoters,
        address maker,
        uint256 day
    ) internal {
        require(share * suppoters.length + main == all, "A111");
        (DataTypes.SettlementType settlement, address currency, ) = IMurmes(
            Murmes
        ).getTaskSettlementData(taskId);
        address platform;
        if (settlement == DataTypes.SettlementType.ONETIME) {
            platform = currency;
        } else {
            platform = IMurmes(Murmes).getPlatformAddressByTaskId(taskId);
        }
        for (uint256 i = 0; i < suppoters.length; i++) {
            IMurmes(Murmes).updateLockedReward(
                platform,
                day,
                int256(share) * -1,
                suppoters[i]
            );
        }
        IMurmes(Murmes).updateLockedReward(
            platform,
            day,
            int256(main) * -1,
            maker
        );
        IMurmes(Murmes).resetTask(taskId, all);
    }

    // ***************** View Functions *****************
    function getReport(
        uint256 reportId
    ) external view override returns (DataTypes.ReportStruct memory) {
        return reports[reportId];
    }

    function getItemReports(
        uint256 itemId
    ) external view override returns (uint256[] memory) {
        return itemReports[itemId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVault {
    function Murmes() external view returns (address);

    function fee() external view returns (uint16);

    function feeRecipient() external view returns (address);

    function transferPenalty(
        address token,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {DataTypes} from "../libraries/DataTypes.sol";

interface IMurmes {
    // ***** Ownable *****
    function isOperator(address operator) external view returns (bool);

    function owner() external view returns (address);

    function multiSig() external view returns (address);

    // ***** EntityManager *****
    function componentGlobal() external view returns (address);

    function moduleGlobal() external view returns (address);

    function getUserBaseData(
        address user
    ) external view returns (uint256, int256);

    function getUserLockReward(
        address user,
        address platform,
        uint256 day
    ) external view returns (uint256);

    function gutUserGuard(address user) external view returns (address);

    function getRequiresNoteById(
        uint256 requireId
    ) external view returns (string memory);

    function getRequiresIdByNote(
        string memory note
    ) external view returns (uint256);

    function updateUser(
        address user,
        int256 reputationSpread,
        int256 tokenSpread
    ) external;

    function updateLockedReward(
        address platform,
        uint256 day,
        int256 amount,
        address user
    ) external;

    // ***** ItemManager *****
    function getItem(
        uint256 itemId
    ) external view returns (DataTypes.ItemStruct memory);

    function isEvaluated(
        address user,
        uint256 itemId
    ) external view returns (bool);

    function holdItemStateByDAO(
        uint256 itemId,
        DataTypes.ItemState state
    ) external;

    // ***** TaskManager *****
    function totalTasks() external view returns (uint256);

    function tasks(
        uint256 taskId
    ) external view returns (DataTypes.TaskStruct memory);

    function getTaskPublisher(uint256 taskId) external view returns (address);

    function getPlatformAddressByTaskId(
        uint256 taskId
    ) external view returns (address);

    function getTaskSettlementModuleAndItems(
        uint256 taskId
    ) external view returns (DataTypes.SettlementType, uint256[] memory);

    function getTaskItemsState(
        uint256 taskId
    ) external view returns (uint256, uint256, uint256);

    function getTaskSettlementData(
        uint256 taskId
    ) external view returns (DataTypes.SettlementType, address, uint256);

    function getAdoptedItemData(
        uint256 taskId
    ) external view returns (uint256, address, address[] memory);

    function getItemCustomModuleOfTask(
        uint256 itemId
    ) external view returns (address, address, address);

    function getItemAuditData(
        uint256 itemId
    ) external view returns (uint256, uint256, uint256, uint256, uint256);

    function updateTask(
        uint256 taskId,
        uint256 plusAmount,
        uint256 plusTime
    ) external;

    function cancelTask(uint256 taskId) external;

    function resetTask(uint256 taskId, uint256 amount) external;

    // ***** Murmes *****
    function postTask(
        DataTypes.PostTaskData calldata vars
    ) external returns (uint256);

    function updateItemRevenue(uint256 taskId, uint256 counts) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../common/token/ERC721/IERC721.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

interface IItemNFT is IERC721 {
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function mintItemTokenByMurmes(
        address maker,
        DataTypes.ItemMetadata calldata vars
    ) external returns (uint256);

    function getItemFingerprint(
        uint256 tokenId
    ) external view returns (uint256);

    function getItemBaseData(
        uint256 itemId
    ) external view returns (address, uint256, uint256);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import {DataTypes} from "../libraries/DataTypes.sol";

interface IArbitration {
    function Murmes() external view returns (address);

    function totalReports() external view returns (uint256);

    function getReport(
        uint256 reportId
    ) external view returns (DataTypes.ReportStruct memory);

    function getItemReports(
        uint256 itemId
    ) external view returns (uint256[] memory);

    function report(
        DataTypes.ReportReason reason,
        uint256 itemId,
        uint256 uintProof,
        string memory stringProof
    ) external returns (uint256);

    function uploadDAOVerificationResult(
        uint256 reportId,
        string memory resultProof,
        bool result,
        uint256[] memory params
    ) external;

    event ReportPosted(
        DataTypes.ReportReason reason,
        uint256 itemId,
        uint256 proofSubtitleId,
        string otherProof,
        address reporter
    );
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {DataTypes} from "../libraries/DataTypes.sol";

interface IItemVersionManagement {
    function updateItemVersion(
        uint256 itemId,
        uint256 fingerprint,
        string memory source
    ) external returns (uint256);

    function reportInvalidVersion(uint256 itemId, uint256 versionId) external;

    function getSpecifyVersion(
        uint256 itemId,
        uint256 versionId
    ) external view returns (DataTypes.VersionStruct memory);

    function getAllVersion(
        uint256 itemId
    ) external view returns (uint256, uint256);

    function getLatestValidVersion(
        uint256 itemId
    ) external view returns (string memory, uint256);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/***
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /***
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /***
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /***
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /***
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /***
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /***
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

    /***
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

    /***
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

    /***
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

    /***
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

    /***
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /***
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/***
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /***
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}