// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IMurmes.sol";
import "../interfaces/IItemNFT.sol";
import "../interfaces/IPlatforms.sol";
import "../interfaces/ISettlement.sol";
import "../interfaces/IModuleGlobal.sol";
import "../interfaces/IPlatformToken.sol";
import "../interfaces/IComponentGlobal.sol";
import "../interfaces/ISettlementModule.sol";
import {Constant} from "../libraries/Constant.sol";
import {Events} from "../libraries/Events.sol";

contract Settlement is ISettlement {
    /**
     * @notice Murmes主合约地址
     */
    address public Murmes;

    constructor(address ms) {
        Murmes = ms;
    }

    /**
     * @notice 更新Item收益
     * @param taskId Item所属任务ID
     * @param counts 更新的收益
     * Fn 1
     */
    function updateItemRevenue(uint256 taskId, uint256 counts) external {
        address platform = IMurmes(Murmes).getPlatformAddressByTaskId(taskId);
        require(
            IMurmes(Murmes).isOperator(msg.sender) || msg.sender == platform,
            "S15"
        );
        (DataTypes.SettlementType settlementType, , uint256 amount) = IMurmes(
            Murmes
        ).getTaskSettlementData(taskId);
        require(settlementType == DataTypes.SettlementType.DIVIDEND, "S16");
        address componentGlobal = IMurmes(Murmes).componentGlobal();
        address platforms = IComponentGlobal(componentGlobal).platforms();
        (uint16 rateCountsToProfit, ) = IPlatforms(platforms).getPlatformRate(
            platform
        );
        address moduleGlobal = IMurmes(Murmes).moduleGlobal();
        address settlement = IModuleGlobal(moduleGlobal)
            .getSettlementModuleAddress(settlementType);
        ISettlementModule(settlement).updateDebtOrRevenue(
            taskId,
            counts,
            amount,
            rateCountsToProfit
        );
        emit Events.ItemRevenueUpdate(taskId, counts);
    }

    /**
     * @notice 预结算收益，众包任务的结算类型为：一次性
     * @param taskId 众包任务ID
     * Fn 2
     */
    function preExtractForNormal(uint256 taskId) external {
        (DataTypes.SettlementType settlementType, ) = IMurmes(Murmes)
            .getTaskSettlementModuleAndItems(taskId);
        require(settlementType == DataTypes.SettlementType.ONETIME, "S26");
        address componentGlobal = IMurmes(Murmes).componentGlobal();
        address moduleGlobal = IMurmes(Murmes).moduleGlobal();
        address platforms = IComponentGlobal(componentGlobal).platforms();
        address itemNFT = IComponentGlobal(componentGlobal).itemToken();
        (, uint16 rateAuditorDivide) = IPlatforms(platforms).getPlatformRate(
            Murmes
        );
        address settlement = IModuleGlobal(moduleGlobal)
            .getSettlementModuleAddress(DataTypes.SettlementType.ONETIME);
        (
            uint256 adoptedItemId,
            address currency,
            address[] memory supporters
        ) = IMurmes(Murmes).getAdoptedItemData(taskId);
        ISettlementModule(settlement).settlement(
            taskId,
            currency,
            IItemNFT(itemNFT).ownerOf(adoptedItemId),
            0,
            rateAuditorDivide,
            supporters
        );
        emit Events.ExtractRevenuePre(taskId, msg.sender);
    }

    /**
     * @notice 预结算Box收益，同时完成众包任务结算
     * @param boxId Box ID
     * Fn 3
     */
    function preExtractForOther(uint256 boxId) external {
        address componentGlobal = IMurmes(Murmes).componentGlobal();
        address platforms = IComponentGlobal(componentGlobal).platforms();
        DataTypes.BoxStruct memory box = IPlatforms(platforms).getBox(boxId);
        require(box.unsettled > 0, "S31");
        DataTypes.PlatformStruct memory platform = IPlatforms(platforms)
            .getPlatform(box.platform);
        uint256 unsettled = (platform.rateCountsToProfit *
            box.unsettled *
            (10 ** 6)) / Constant.BASE_RATE;
        uint256 surplus = _ergodic(
            IComponentGlobal(componentGlobal).itemToken(),
            unsettled,
            box.platform,
            box.tasks,
            platform.rateAuditorDivide
        );

        if (surplus > 0) {
            address platformToken = IComponentGlobal(componentGlobal)
                .platformToken();
            IPlatformToken(platformToken).mintPlatformTokenByMurmes(
                platform.platformId,
                box.creator,
                surplus
            );
        }
        IPlatforms(platforms).updateBoxUnsettledRevenueByMurmes(
            boxId,
            int256(box.unsettled) * -1
        );
        emit Events.ExtractRevenue(boxId, msg.sender);
    }

    // ***************** Internal Functions *****************
    /**
     * @notice 遍历结算Box的所有众包任务
     * @param itemToken Item NFT组件合约
     * @param unsettled 可支付代币数目
     * @param platform box所属平台
     * @param tasks box的所有众包任务ID集合
     * @param rateAuditorDivide 审核分成比率
     * Fn 4
     */
    function _ergodic(
        address itemToken,
        uint256 unsettled,
        address platform,
        uint256[] memory tasks,
        uint16 rateAuditorDivide
    ) internal returns (uint256) {
        for (uint256 i = 0; i < tasks.length; i++) {
            (uint256 adoptedItemId, , address[] memory supporters) = IMurmes(
                Murmes
            ).getAdoptedItemData(tasks[i]);
            if (adoptedItemId > 0 && unsettled > 0) {
                (DataTypes.SettlementType settlementType, ) = IMurmes(Murmes)
                    .getTaskSettlementModuleAndItems(tasks[i]);
                address settlement = IModuleGlobal(
                    IMurmes(Murmes).moduleGlobal()
                ).getSettlementModuleAddress(settlementType);
                uint256 itemGetRevenue = ISettlementModule(settlement)
                    .settlement(
                        tasks[i],
                        platform,
                        IItemNFT(itemToken).ownerOf(adoptedItemId),
                        unsettled,
                        rateAuditorDivide,
                        supporters
                    );
                unsettled -= itemGetRevenue;
            }
        }
        return unsettled;
    }
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

interface ISettlement {
    function updateItemRevenue(uint256 taskId, uint256 counts) external;
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