/**
 * @Author: LaplaceMan
 * @Description: 基于区块链的众包协议 - Murmes
 * @Copyright (c) 2023 by LaplaceMan [email protected], All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "./base/TaskManager.sol";
import "./interfaces/IGuard.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IPlatforms.sol";
import "./interfaces/IAuditModule.sol";
import "./interfaces/IAccessModule.sol";
import "./interfaces/IPlatformToken.sol";
import "./interfaces/IDetectionModule.sol";

contract Murmes is TaskManager {
    constructor(address dao, address mutliSig) {
        _setOwner(dao);
        _setMutliSig(mutliSig);
        operators[address(this)] = true;
        requiresNoteById.push("None");
    }

    /**
     * @notice 发布众包任务
     * @param vars 任务的信息和需求
     * @return 任务ID
     * Fn 1
     */
    function postTask(
        DataTypes.PostTaskData calldata vars
    ) external returns (uint256) {
        require(
            vars.deadline > block.timestamp &&
                vars.requireId < requiresNoteById.length,
            "11"
        );

        require(
            IModuleGlobal(moduleGlobal).isPostTaskModuleValid(
                vars.currency,
                vars.auditModule,
                vars.detectionModule
            ),
            "16"
        );

        _userInitialization(msg.sender, 0);
        _validateCaller(msg.sender);

        totalTasks++;
        address authority = IComponentGlobal(componentGlobal).authority();
        uint256 boxId = IAuthorityModule(authority).formatBoxIdOfPostTask(
            componentGlobal,
            vars.platform,
            vars.sourceId,
            vars.source,
            msg.sender,
            vars.settlement,
            vars.amount
        );
        if (vars.platform == address(this)) {
            assert(vars.settlement == DataTypes.SettlementType.ONETIME);
            require(
                IERC20(vars.currency).transferFrom(
                    msg.sender,
                    address(this),
                    vars.amount
                ),
                "112"
            );
        } else {
            address platforms = IComponentGlobal(componentGlobal).platforms();
            uint256[] memory _tasks = IPlatforms(platforms).getBoxTasks(boxId);
            for (uint256 i = 0; i < _tasks.length; i++) {
                require(tasks[_tasks[i]].requireId != vars.requireId, "10");
            }
            uint256[] memory newTasks = _sortSettlementPriority(
                _tasks,
                vars.settlement,
                totalTasks
            );
            IPlatforms(platforms).updateBoxTasksByMurmes(boxId, newTasks);
        }

        if (vars.settlement != DataTypes.SettlementType.DIVIDEND) {
            address settlementModule = IModuleGlobal(moduleGlobal)
                .getSettlementModuleAddress(vars.settlement);
            ISettlementModule(settlementModule).updateDebtOrRevenue(
                totalTasks,
                0,
                vars.amount,
                0
            );
        }

        tasks[totalTasks].applicant = msg.sender;
        tasks[totalTasks].platform = vars.platform;
        tasks[totalTasks].boxId = boxId;
        tasks[totalTasks].requireId = vars.requireId;
        tasks[totalTasks].source = vars.source;
        tasks[totalTasks].settlement = vars.settlement;
        tasks[totalTasks].amount = vars.amount;
        tasks[totalTasks].currency = vars.currency;
        tasks[totalTasks].auditModule = vars.auditModule;
        tasks[totalTasks].detectionModule = vars.detectionModule;
        tasks[totalTasks].deadline = vars.deadline;

        emit Events.TaskPosted(vars, totalTasks, msg.sender);
        return totalTasks;
    }

    /**
     * @notice 完成任务后提交成果
     * @param vars 成果的信息
     * @return 成果ID
     * Fn 2
     */
    function submitItem(
        DataTypes.ItemMetadata calldata vars
    ) external returns (uint256) {
        require(tasks[vars.taskId].adopted == 0, "23");
        if (tasks[vars.taskId].items.length == 0) {
            require(block.timestamp < tasks[vars.taskId].deadline, "26");
        }
        require(vars.requireId == tasks[vars.taskId].requireId, "29");

        if (
            tasks[vars.taskId].detectionModule != address(0) &&
            tasks[vars.taskId].items.length > 0
        ) {
            address detection = tasks[vars.taskId].detectionModule;
            require(
                IDetectionModule(detection).detectionInSubmitItem(
                    vars.taskId,
                    vars.fingerprint
                ),
                "26-2"
            );
        }

        _userInitialization(msg.sender, 0);
        _validateCaller(msg.sender);

        address guard = users[tasks[vars.taskId].applicant].guard;
        if (guard != address(0)) {
            require(
                IGuard(guard).beforeSubmitItem(
                    msg.sender,
                    users[msg.sender].reputation,
                    users[msg.sender].deposit,
                    vars.requireId
                ),
                "25"
            );
        }

        uint256 itemId = _submitItem(msg.sender, vars);
        tasks[vars.taskId].items.push(itemId);

        emit Events.ItemSubmitted(vars, itemId, msg.sender);
        return itemId;
    }

    /**
     * @notice 审核/检测Item
     * @param itemId Item的ID
     * @param attitude 检测结果，支持或反对
     * Fn 3
     */
    function auditItem(
        uint256 itemId,
        DataTypes.AuditAttitude attitude
    ) external {
        uint256 taskId = itemsNFT[itemId].taskId;
        require(taskId > 0, "31");
        require(tasks[taskId].adopted == 0, "33");

        _userInitialization(msg.sender, 0);
        _validateCaller(msg.sender);

        {
            address access = IComponentGlobal(componentGlobal).access();
            require(
                IAccessModule(access).auditable(users[msg.sender].deposit),
                "35"
            );
        }

        address guard = users[tasks[taskId].applicant].guard;
        if (guard != address(0)) {
            require(
                IGuard(guard).beforeAuditItem(
                    msg.sender,
                    users[msg.sender].reputation,
                    users[msg.sender].deposit,
                    tasks[taskId].requireId,
                    attitude
                ),
                "35-2"
            );
        }

        _auditItem(itemId, attitude, msg.sender);

        (
            uint256 uploaded,
            uint256 support,
            uint256 against,
            uint256 allSupport,
            uint256 uploadTime
        ) = getItemAuditData(itemId);
        DataTypes.ItemState state = IAuditModule(tasks[taskId].auditModule)
            .afterAuditItem(
                uploaded,
                support,
                against,
                allSupport,
                uploadTime,
                IComponentGlobal(componentGlobal).lockUpTime()
            );
        if (state != DataTypes.ItemState.NORMAL) {
            _changeItemState(itemId, state);
            _updateUsers(itemId, state);
            if (state == DataTypes.ItemState.ADOPTED) {
                tasks[taskId].adopted = itemId;
            }
        }
        emit Events.ItemAudited(itemId, attitude, msg.sender);
    }

    /**
     * @notice 提取锁定的代币收益
     * @param platform 所属平台/代币类型
     * @param day 解锁的日期
     * @return 减去手续费外，提取的代币总数
     * Fn 4
     */
    function withdraw(
        address platform,
        uint256[] memory day
    ) external returns (uint256) {
        _userInitialization(msg.sender, 0);

        uint256 all = 0;
        uint256 lockUpTime = IComponentGlobal(componentGlobal).lockUpTime();
        for (uint256 i = 0; i < day.length; i++) {
            if (
                users[msg.sender].locks[platform][day[i]] > 0 &&
                block.timestamp > day[i] + lockUpTime
            ) {
                all += users[msg.sender].locks[platform][day[i]];
                users[msg.sender].locks[platform][day[i]] = 0;
            }
        }

        if (all > 0) {
            address platforms = IComponentGlobal(componentGlobal).platforms();
            DataTypes.PlatformStruct memory platformData = IPlatforms(platforms)
                .getPlatform(platform);
            address vault = IComponentGlobal(componentGlobal).vault();
            uint256 fee = IVault(vault).fee();
            address platformToken = IComponentGlobal(componentGlobal)
                .platformToken();

            if (fee > 0) {
                uint256 thisFee = (all * fee) / Constant.BASE_RATE;
                address recipient = IVault(vault).feeRecipient();
                all -= thisFee;
                if (platformData.platformId > 0) {
                    IPlatformToken(platformToken).mintPlatformTokenByMurmes(
                        platformData.platformId,
                        recipient,
                        thisFee
                    );
                } else {
                    require(
                        IERC20(platform).transfer(recipient, thisFee),
                        "412"
                    );
                }
            }

            if (platformData.platformId > 0) {
                IPlatformToken(platformToken).mintPlatformTokenByMurmes(
                    platformData.platformId,
                    msg.sender,
                    all
                );
            } else {
                require(IERC20(platform).transfer(msg.sender, all), "412-2");
            }
        }
        emit Events.UserWithdrawRevenue(platform, day, all, msg.sender);
        return all;
    }

    // ***************** Internal Functions *****************
    /**
     * @notice 根据Item状态变化更新多个利益相关者的信息
     * @param itemId 唯一标识Item的ID
     * @param state Item更新后的状态
     * Fn 7
     */
    function _updateUsers(uint256 itemId, DataTypes.ItemState state) internal {
        int8 flag = 1;
        uint8 reverseState = (uint8(state) == 1 ? 2 : 1);
        if (state == DataTypes.ItemState.DELETED) flag = -1;
        address access = IComponentGlobal(componentGlobal).access();

        {
            uint8 multiplier = IAccessModule(access).multiplier();
            address itemToken = IComponentGlobal(componentGlobal).itemToken();
            address owner = IItemNFT(itemToken).ownerOf(itemId);
            _updateUser(owner, access, flag, uint8(state), multiplier);
        }

        for (uint256 i = 0; i < itemsNFT[itemId].supporters.length; i++) {
            _updateUser(
                itemsNFT[itemId].supporters[i],
                access,
                flag,
                uint8(state),
                100
            );
        }

        for (uint256 i = 0; i < itemsNFT[itemId].opponents.length; i++) {
            _updateUser(
                itemsNFT[itemId].opponents[i],
                access,
                flag * (-1),
                reverseState,
                100
            );
        }
    }

    /**
     * @notice 根据Item状态变化更新利益相关者的信息
     * @param user 利益相关者
     * @param access access模块合约地址
     * @param flag 默认判断标志
     * @param state 状态
     * @param multiplier 奖惩倍数
     * Fn 8
     */
    function _updateUser(
        address user,
        address access,
        int8 flag,
        uint8 state,
        uint8 multiplier
    ) internal {
        (uint256 reputationDValue, uint256 tokenDValue) = IAccessModule(access)
            .variation(users[user].reputation, state);
        _updateUser(
            user,
            int256((reputationDValue * multiplier) / 100) * flag,
            int256((tokenDValue * multiplier) / 100) * flag
        );
    }

    /**
     * @notice 根据结算策略的优先级保持Box众包任务ID集合的有序性
     * @param arr 众包任务ID集合
     * @param spot 新的众包任务的结算策略
     * @param id 新的众包任务的ID
     * @return 针对特定Box排好序的众包任务集合
     * Fn 9
     */
    function _sortSettlementPriority(
        uint256[] memory arr,
        DataTypes.SettlementType spot,
        uint256 id
    ) internal view returns (uint256[] memory) {
        uint256[] memory newArr = new uint256[](arr.length + 1);
        if (newArr.length == 1) {
            newArr[0] = id;
            return newArr;
        }
        uint256 flag;
        for (flag = arr.length - 1; flag > 0; flag--) {
            if (uint8(spot) >= uint8(tasks[arr[flag]].settlement)) {
                break;
            }
        }
        for (uint256 i = 0; i < newArr.length; i++) {
            if (i <= flag) {
                newArr[i] = arr[i];
            } else if (i == flag + 1) {
                newArr[i] = id;
            } else {
                newArr[i] = arr[i - 1];
            }
        }
        return newArr;
    }

    /**
     * @notice 根据信誉度分数和质押资产数判断用户是否有调用权限
     * @param caller 调用者地址
     * Fn 10
     */
    function _validateCaller(address caller) internal view {
        address access = IComponentGlobal(componentGlobal).access();
        require(
            IAccessModule(access).access(
                users[caller].reputation,
                users[caller].deposit
            ),
            "115"
        );
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "./ItemManager.sol";
import "../interfaces/IModuleGlobal.sol";
import "../interfaces/IAuthorityModule.sol";
import "../interfaces/ISettlementModule.sol";

contract TaskManager is ItemManager {
    /**
     * @notice Murmes已经存在的众包任务总数
     */
    uint256 public totalTasks;
    /**
     * @notice task的信息, 从1开始（提交任务的顺位）
     */
    mapping(uint256 => DataTypes.TaskStruct) public tasks;

    /**
     * @notice 更新（增加）任务中的额度和（延长）到期时间
     * @param taskId 申请顺位 ID
     * @param plusAmount 增加支付额度
     * @param plusTime 延长到期时间
     * Fn 1
     */
    function updateTask(
        uint256 taskId,
        uint256 plusAmount,
        uint256 plusTime
    ) public {
        require(msg.sender == tasks[taskId].applicant, "T15");
        require(tasks[taskId].adopted == 0, "T10");
        tasks[taskId].amount += plusAmount;
        tasks[taskId].deadline += plusTime;
        require(tasks[taskId].deadline > block.timestamp + 1 days, "T11");
        if (tasks[taskId].settlement == DataTypes.SettlementType.ONETIME) {
            IERC20(tasks[taskId].currency).transferFrom(
                msg.sender,
                address(this),
                plusAmount
            );
        } else if (
            tasks[taskId].settlement ==
            DataTypes.SettlementType.ONETIME_MORTGAGE
        ) {
            address settlementModule = IModuleGlobal(moduleGlobal)
                .getSettlementModuleAddress(
                    DataTypes.SettlementType.ONETIME_MORTGAGE
                );
            ISettlementModule(settlementModule).updateDebtOrRevenue(
                taskId,
                0,
                plusAmount,
                0
            );
        } else {
            address authority = IComponentGlobal(componentGlobal).authority();
            IAuthorityModule(authority).updateTaskAmountOccupied(
                tasks[taskId].boxId,
                plusAmount
            );
        }
        emit Events.TaskStateUpdate(taskId, plusAmount, plusTime);
    }

    /**
     * @notice 取消任务
     * @param taskId 众包任务ID
     * Fn 2
     */
    function cancelTask(uint256 taskId) external {
        require(msg.sender == tasks[taskId].applicant, "T25");
        require(
            tasks[taskId].adopted == 0 &&
                tasks[taskId].items.length == 0 &&
                block.timestamp >= tasks[taskId].deadline,
            "T26"
        );
        if (tasks[taskId].settlement == DataTypes.SettlementType.ONETIME) {
            require(
                IERC20(tasks[taskId].currency).transferFrom(
                    address(this),
                    msg.sender,
                    tasks[taskId].amount
                ),
                "T212"
            );
        }
        delete tasks[taskId];
        emit Events.TaskCancelled(taskId);
    }

    /**
     * @notice 该功能服务于后续的仲裁法庭，取消被确认的Item，相当于重新发出申请
     * @param taskId 被重置的申请 ID
     * @param amount 恢复的代币奖励数量（注意这里以代币计价）
     * Fn 3
     */
    function resetTask(uint256 taskId, uint256 amount) public auth {
        delete tasks[taskId].adopted;
        uint256 lockUpTime = IComponentGlobal(componentGlobal).lockUpTime();
        tasks[taskId].deadline = block.timestamp + lockUpTime;
        address settlement = IModuleGlobal(moduleGlobal)
            .getSettlementModuleAddress(tasks[taskId].settlement);
        ISettlementModule(settlement).resetSettlement(taskId, amount);
        emit Events.TaskReset(taskId, amount);
    }

    // ***************** View Functions *****************
    function getTaskPublisher(uint256 taskId) external view returns (address) {
        return tasks[taskId].applicant;
    }

    function getPlatformAddressByTaskId(
        uint256 taskId
    ) external view returns (address) {
        require(tasks[taskId].applicant != address(0), "181");
        return tasks[taskId].platform;
    }

    function getTaskSettlementModuleAndItems(
        uint256 taskId
    ) external view returns (DataTypes.SettlementType, uint256[] memory) {
        return (tasks[taskId].settlement, tasks[taskId].items);
    }

    function getTaskItemsState(
        uint256 taskId
    ) external view returns (uint256, uint256, uint256) {
        return (
            tasks[taskId].items.length,
            tasks[taskId].adopted,
            tasks[taskId].deadline
        );
    }

    function getTaskSettlementData(
        uint256 taskId
    ) external view returns (DataTypes.SettlementType, address, uint256) {
        return (
            tasks[taskId].settlement,
            tasks[taskId].currency,
            tasks[taskId].amount
        );
    }

    function getItemCustomModuleOfTask(
        uint256 itemId
    ) external view returns (address, address, address) {
        uint256 taskId = itemsNFT[itemId].taskId;
        return (
            tasks[taskId].currency,
            tasks[taskId].auditModule,
            tasks[taskId].detectionModule
        );
    }

    function getAdoptedItemData(
        uint256 taskId
    ) external view returns (uint256, address, address[] memory) {
        return (
            tasks[taskId].adopted,
            tasks[taskId].currency,
            itemsNFT[tasks[taskId].adopted].supporters
        );
    }

    function getItemAuditData(
        uint256 itemId
    ) public view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 taskId = itemsNFT[itemId].taskId;
        uint256 uploaded = tasks[taskId].items.length;
        uint256 allSupport;
        for (uint256 i = 0; i < uploaded; i++) {
            uint256 singleItem = tasks[taskId].items[i];
            allSupport += itemsNFT[singleItem].supporters.length;
        }
        return (
            uploaded,
            itemsNFT[itemId].supporters.length,
            itemsNFT[itemId].opponents.length,
            allSupport,
            itemsNFT[itemId].stateChangeTime
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {DataTypes} from "../libraries/DataTypes.sol";

interface IGuard {
    function beforeSubmitItem(
        address caller,
        uint256 reputation,
        int256 deposit,
        uint256 requireId
    ) external view returns (bool);

    function beforeAuditItem(
        address caller,
        uint256 reputation,
        int256 deposit,
        uint256 requireId,
        DataTypes.AuditAttitude attitude
    ) external view returns (bool);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {DataTypes} from "../libraries/DataTypes.sol";

interface IDetectionModule {
    function Murmes() external view returns (address);

    function name() external view returns (string memory);

    function detectionInSubmitItem(
        uint256 taskId,
        uint256 origin
    ) external view returns (bool);

    function detectionInUpdateItem(
        uint256 newUpload,
        uint256 oldUpload
    ) external view returns (bool);

    function distanceThreshold() external view returns (uint256);

    event SetDistanceThreshold(uint8 newDistanceThreshold);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../common/token/ERC1155/IERC1155.sol";

interface IPlatformToken is IERC1155 {
    function Murmes() external view returns (address);

    function decimals() external view returns (uint8);

    function tokenUri(uint256 tokenId) external view returns (string memory);

    function createPlatformToken(
        string memory symbol,
        address endorser,
        uint256 platformId
    ) external;

    function mintPlatformTokenByMurmes(
        uint256 platformId,
        address to,
        uint256 amount
    ) external;

    function burn(address from, uint256 platformId, uint256 amount) external;

    event RewardFromMurmesStateUpdate(bool state);
    event RewardFromMurmesBoostUpdate(uint8 flag, uint40 amount);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "./EntityManager.sol";
import "../interfaces/IItemNFT.sol";

contract ItemManager is EntityManager {
    /**
     * @notice 记录Item详细信息
     */
    mapping(uint256 => DataTypes.ItemStruct) itemsNFT;
    /**
     * @notice 用户是否对Item评价过
     */
    mapping(address => mapping(uint256 => bool)) evaluated;
    /**
     * @notice 用户建议特定任务应该采纳的Item
     */
    mapping(address => mapping(uint256 => uint256)) adopted;

    /**
     * @notice 当DAO判定Item为恶意时，"删除"它
     * @param itemId 恶意Item的ID
     * @param state Item新的状态
     * Fn 1
     */
    function holdItemStateByDAO(
        uint256 itemId,
        DataTypes.ItemState state
    ) external auth {
        assert(state != DataTypes.ItemState.ADOPTED);
        _changeItemState(itemId, state);
    }

    // ***************** Internal Functions *****************
    /**
     * @notice 创建Item
     * @param maker Item制作者地址
     * @param vars Item信息
     * @return 相应Item ID
     * Fn 2
     */
    function _submitItem(
        address maker,
        DataTypes.ItemMetadata calldata vars
    ) internal returns (uint256) {
        address itemToken = IComponentGlobal(componentGlobal).itemToken();
        uint256 itemId = IItemNFT(itemToken).mintItemTokenByMurmes(maker, vars);
        itemsNFT[itemId].taskId = vars.taskId;
        itemsNFT[itemId].stateChangeTime = block.timestamp;
        return itemId;
    }

    /**
     * @notice 改变Item状态
     * @param itemId Item的ID
     * @param state 改变后的状态
     * Fn 3
     */
    function _changeItemState(
        uint256 itemId,
        DataTypes.ItemState state
    ) internal {
        itemsNFT[itemId].state = state;
        itemsNFT[itemId].stateChangeTime = block.timestamp;
        emit Events.ItemStateUpdate(itemId, state);
    }

    /**
     * @notice 审核Item
     * @param itemId Item的ID
     * @param attitude 审核结果
     * @param auditor 审核/检测员
     * Fn 4
     */
    function _auditItem(
        uint256 itemId,
        DataTypes.AuditAttitude attitude,
        address auditor
    ) internal {
        require(itemsNFT[itemId].state == DataTypes.ItemState.NORMAL, "I35");
        require(evaluated[auditor][itemId] == false, "I34");
        if (attitude == DataTypes.AuditAttitude.SUPPORT) {
            uint256 taskId = itemsNFT[itemId].taskId;
            require(adopted[auditor][taskId] == 0, "I30");
            itemsNFT[itemId].supporters.push(auditor);
            adopted[auditor][taskId] = itemId;
        } else {
            itemsNFT[itemId].opponents.push(auditor);
        }
        evaluated[auditor][itemId] = true;
    }

    // ***************** View Functions *****************
    function getItem(
        uint256 itemId
    ) external view returns (DataTypes.ItemStruct memory) {
        return itemsNFT[itemId];
    }

    function isEvaluated(
        address user,
        uint256 itemId
    ) external view returns (bool) {
        return evaluated[user][itemId];
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
import "./Ownable.sol";
import "../common/token/ERC20/IERC20.sol";
import "../interfaces/IComponentGlobal.sol";
import {Constant} from "../libraries/Constant.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

contract EntityManager is Ownable {
    /**
     * @notice 负责管理Murmes内模块的合约地址
     */
    address public moduleGlobal;
    /**
     * @notice 负责管理Murmes内组件的合约地址
     */
    address public componentGlobal;
    /**
     * @notice 提交申请时额外条件的集合，id => 说明
     */
    string[] requiresNoteById;
    /**
     * @notice 提交申请时额外条件的映射，说明 => id
     */
    mapping(string => uint256) requiresIdByNote;
    /**
     * @notice 记录Murmes内每个用户的信息
     */
    mapping(address => DataTypes.UserStruct) users;

    /**
     * @notice 注册提交申请时所需的额外条件
     * @param notes 文本说明
     * Fn 1
     */
    function registerRequires(string[] memory notes) external {
        for (uint256 i = 0; i < notes.length; i++) {
            require(requiresIdByNote[notes[i]] == 0, "E10");
            requiresNoteById.push(notes[i]);
            requiresIdByNote[notes[i]] = requiresNoteById.length - 1;
            emit Events.RegisterRepuire(notes[i], requiresNoteById.length - 1);
        }
    }

    /**
     * @notice 主动加入协议, 并质押一定数目的代币
     * @param user 用户区块链地址
     * @param deposit 质押的代币数量
     * Fn 2
     */
    function userJoin(address user, uint256 deposit) external {
        if (deposit > 0) {
            address token = IComponentGlobal(componentGlobal)
                .defaultDepositableToken();
            require(
                IERC20(token).transferFrom(msg.sender, address(this), deposit),
                "E212"
            );
        }

        if (users[user].reputation == 0) {
            _userInitialization(user, deposit);
            emit Events.UserJoin(
                user,
                Constant.BASE_REPUTATION,
                int256(deposit)
            );
        } else {
            users[user].deposit += int256(deposit);
            emit Events.UserBaseDataUpdate(user, 0, int256(deposit));
        }
    }

    /**
     * @notice 用户设置自己的用于筛选Item制作者的模块
     * @param guard 新的守护模块地址
     * Fn 3
     */
    function setUserGuard(address guard) external {
        require(users[msg.sender].reputation > 0, "E32");
        users[msg.sender].guard = guard;
        emit Events.UserGuardUpdate(msg.sender, guard);
    }

    /**
     * @notice 提取质押的代币
     * @param amount 欲提取代币数
     * Fn 4
     */
    function withdrawDeposit(uint256 amount) external {
        require(users[msg.sender].deposit > 0, "E42");
        uint256 lockUpTime = IComponentGlobal(componentGlobal).lockUpTime();
        require(
            block.timestamp > users[msg.sender].operate + 2 * lockUpTime,
            "E45"
        );
        require(users[msg.sender].deposit - int256(amount) >= 0, "E41");
        users[msg.sender].deposit -= int256(amount);
        address token = IComponentGlobal(componentGlobal)
            .defaultDepositableToken();
        require(IERC20(token).transfer(msg.sender, amount), "E412");
        emit Events.UserWithdrawDeposit(msg.sender, amount);
    }

    /**
     * @notice 更新用户信誉度分数和质押代币数
     * @param user 用户区块链地址
     * @param reputationSpread 有正负（增加或扣除）的信誉度分数
     * @param tokenSpread 有正负的（增加或扣除）代币数量
     * Fn 5
     */
    function updateUser(
        address user,
        int256 reputationSpread,
        int256 tokenSpread
    ) public auth {
        _updateUser(user, reputationSpread, tokenSpread);
    }

    /**
     * @notice 更新用户（在平台内的）被锁定代币数量
     * @param platform 平台地址 / 代币合约地址
     * @param day "天"的Unix格式
     * @param amount 有正负（新增或扣除）的锁定的代币数量
     * @param user 用户区块链地址
     * Fn 6
     */
    function updateLockedReward(
        address platform,
        uint256 day,
        int256 amount,
        address user
    ) public auth {
        require(users[user].reputation != 0, "E62");
        uint256 current = users[user].locks[platform][day];
        int256 newLock = int256(current) + amount;
        users[user].locks[platform][day] = (newLock > 0 ? uint256(newLock) : 0);
        emit Events.UserLockedRevenueUpdate(user, platform, day, amount);
    }

    /**
     * @notice 设置全局管理合约
     * @param note 0为模块管理合约，1为组件管理合约
     * @param addr 相应的合约地址
     * Fn 7
     */
    function setGlobalContract(uint8 note, address addr) external onlyOwner {
        address old;
        if (note == 0) {
            old = moduleGlobal;
            moduleGlobal = addr;
        } else {
            old = componentGlobal;
            componentGlobal = addr;
        }
        operators[addr] = false;
        operators[addr] = true;
    }

    // ***************** Internal Functions *****************
    /**
     * @notice 用户初始化，辅助作用是更新最新操作时间
     * @param user 用户区块链地址
     * @param amount 质押代币数
     * Fn 7
     */
    function _userInitialization(address user, uint256 amount) internal {
        if (users[user].reputation == 0) {
            users[user].reputation = Constant.BASE_REPUTATION;
            users[user].deposit = int256(amount);
        }
        users[user].operate = block.timestamp;
    }

    /**
     * @notice 更新用户基本信息
     * @param user 用户区块链地址
     * @param reputationSpread 信誉度变化
     * @param tokenSpread 质押代币数目变化
     * Fn 8
     */
    function _updateUser(
        address user,
        int256 reputationSpread,
        int256 tokenSpread
    ) internal {
        int256 newReputation = int256(users[user].reputation) +
            reputationSpread;
        users[user].reputation = (
            newReputation > 0 ? uint256(newReputation) : 0
        );
        if (tokenSpread < 0) {
            uint256 penalty = uint256(tokenSpread * -1);
            if (users[user].deposit > 0) {
                if (users[user].deposit + tokenSpread < 0) {
                    penalty = uint256(users[user].deposit);
                }
                address vault = IComponentGlobal(componentGlobal).vault();
                address token = IComponentGlobal(componentGlobal)
                    .defaultDepositableToken();
                require(IERC20(token).transfer(vault, penalty), "E812");
            }
            users[user].deposit = users[user].deposit + tokenSpread;
        }
        if (users[user].reputation == 0) {
            users[user].reputation = 1;
        }
        emit Events.UserBaseDataUpdate(user, reputationSpread, tokenSpread);
    }

    // ***************** View Functions *****************
    function getUserBaseData(
        address user
    ) external view returns (uint256, int256) {
        return (users[user].reputation, users[user].deposit);
    }

    function getUserGuard(address user) external view returns (address) {
        return users[user].guard;
    }

    function getUserLockReward(
        address user,
        address platform,
        uint256 day
    ) external view returns (uint256) {
        return users[user].locks[platform][day];
    }

    function getRequiresNoteById(
        uint256 requireId
    ) external view returns (string memory) {
        return requiresNoteById[requireId];
    }

    function getRequiresIdByNote(
        string memory note
    ) external view returns (uint256) {
        return requiresIdByNote[note];
    }
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
import {Events} from "../libraries/Events.sol";

abstract contract Ownable {
    /**
     * @notice 管理员，一般为DAO
     */
    address private _owner;
    /**
     * @notice 多签地址，受DAO管理
     */
    address private _multiSig;
    /**
     * @notice 相应的区块链地址是否拥有特殊权限
     */
    mapping(address => bool) operators;

    // Fn 1
    modifier onlyOwner() {
        require(msg.sender == _owner, "O15");
        _;
    }
    // Fn 2
    modifier auth() {
        require(operators[msg.sender] == true, "O25");
        _;
    }

    /**
     * @notice 转移Owner权限
     * @param newOwner 新的Owner地址
     * Fn 3
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "O31");
        _setOwner(newOwner);
    }

    /**
     * @notice 转移多签权限
     * @param newMutliSig 新的多签地址
     * @ Fn 4
     */
    function transferMutliSig(address newMutliSig) external {
        require(msg.sender == _multiSig, "O45");
        require(newMutliSig != address(0), "O41");
        _setMutliSig(newMutliSig);
    }

    /**
     * @notice 设置/替换拥有特殊权限的操作员（合约）地址
     * @param old 旧的操作员地址，被撤销
     * @param replace 新的操作员权限，被授予
     * Fn 5
     */
    function setOperatorByTool(address old, address replace) public auth {
        if (old != address(0)) {
            operators[old] = false;
            emit Events.OperatorStateUpdate(old, false);
        }
        if (replace != address(0)) {
            operators[replace] = true;
            emit Events.OperatorStateUpdate(replace, true);
        }
    }

    // ***************** Internal Functions *****************
    function _setOwner(address newOwner) internal {
        _owner = newOwner;
    }

    function _setMutliSig(address newMutliSig) internal {
        _multiSig = newMutliSig;
    }

    // ***************** View Functions *****************
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function multiSig() public view returns (address) {
        return _multiSig;
    }

    function isOperator(address operator) public view returns (bool) {
        return operators[operator];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/***
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /***
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /***
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /***
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /***
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /***
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /***
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /***
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

    /***
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/***
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /***
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /***
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /***
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /***
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /***
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /***
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /***
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /***
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /***
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /***
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}