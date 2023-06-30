// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IMurmes.sol";
import "../interfaces/IItemNFT.sol";
import "../interfaces/IDetectionModule.sol";
import "../interfaces/IComponentGlobal.sol";
import "../interfaces/IItemVersionManagement.sol";
import {Events} from "../libraries/Events.sol";

contract ItemVersionManagement is IItemVersionManagement {
    /**
     * @notice Murmes主合约地址
     */
    address public Murmes;
    /**
     * @notice 记录Item不同版本的信息
     */
    mapping(uint256 => DataTypes.VersionStruct[]) items;

    constructor(address ms) {
        Murmes = ms;
    }

    /**
     * @notice 上传/更新Item版本
     * @param itemId 唯一标识Item的ID
     * @param fingerprint 新版本Item的指纹值
     * @param source 新版本Item源地址
     * Fn 1
     */
    function updateItemVersion(
        uint256 itemId,
        uint256 fingerprint,
        string memory source
    ) external override returns (uint256) {
        address components = IMurmes(Murmes).componentGlobal();
        address itemToken = IComponentGlobal(components).itemToken();
        (address maker, , ) = IItemNFT(itemToken).getItemBaseData(itemId);
        uint256 version0 = IItemNFT(itemToken).getItemFingerprint(itemId);

        {
            DataTypes.ItemStruct memory item = IMurmes(Murmes).getItem(itemId);
            require(item.state != DataTypes.ItemState.DELETED, "VM16");
        }
        address owner = IItemNFT(itemToken).ownerOf(itemId);
        require(owner == maker && msg.sender == owner, "VM15");
        require(version0 != fingerprint && fingerprint != 0, "VM11");
        (, , address detection) = IMurmes(Murmes).getItemCustomModuleOfTask(
            itemId
        );
        if (detection != address(0)) {
            require(
                IDetectionModule(detection).detectionInUpdateItem(
                    version0,
                    fingerprint
                ),
                "VM112"
            );
            if (items[itemId].length > 0) {
                for (uint256 i = 0; i < items[itemId].length; i++) {
                    assert(fingerprint != items[itemId][i].fingerprint);
                    if (items[itemId][i].invalid == false) {
                        require(
                            IDetectionModule(detection).detectionInUpdateItem(
                                fingerprint,
                                items[itemId][i].fingerprint
                            ),
                            "VM113"
                        );
                    }
                }
            }
        }

        items[itemId].push(
            DataTypes.VersionStruct({
                source: source,
                fingerprint: fingerprint,
                invalid: false
            })
        );
        emit Events.ItemVersionUpdate(
            itemId,
            fingerprint,
            source,
            items[itemId].length
        );
        return items[itemId].length;
    }

    /**
     * @notice 取消无效的Item，一般是Item源文件和指纹不匹配，注意，这将导致往后的已上传版本全部失效
     * @param itemId 唯一标识Item的ID
     * @param versionId 无效的版本号
     * Fn 2
     */
    function reportInvalidVersion(
        uint256 itemId,
        uint256 versionId
    ) external override {
        require(IMurmes(Murmes).isOperator(msg.sender), "VM25");
        for (uint256 i = versionId; i < items[itemId].length; i++) {
            items[itemId][i].invalid = true;
        }
        emit Events.ItemVersionReportInvaild(itemId, versionId);
    }

    /**
     * @notice 当Item已经被删除时，它的所有版本都应该失效
     * @param itemId 唯一标识Item的ID
     * Fn 3
     */
    function deleteInvaildItem(uint256 itemId) external {
        DataTypes.ItemStruct memory item = IMurmes(Murmes).getItem(itemId);
        require(item.state == DataTypes.ItemState.DELETED, "VM31");
        address components = IMurmes(Murmes).componentGlobal();
        uint256 lockUpTime = IComponentGlobal(components).lockUpTime();

        require(
            block.timestamp > item.stateChangeTime + 3 * lockUpTime,
            "VM35"
        );
        if (items[itemId].length > 0) {
            for (uint256 i = 0; i < items[itemId].length; i++) {
                if (items[itemId][i].invalid == false) {
                    items[itemId][i].invalid = true;
                    emit Events.ItemVersionReportInvaild(itemId, i);
                }
            }
        }
    }

    // ***************** View Functions *****************
    function getSpecifyVersion(
        uint256 itemId,
        uint256 versionId
    ) public view override returns (DataTypes.VersionStruct memory) {
        require(items[itemId][versionId].fingerprint != 0, "ER1");
        return items[itemId][versionId];
    }

    function getAllVersion(
        uint256 itemId
    ) public view override returns (uint256, uint256) {
        if (items[itemId].length == 0) return (0, 0);
        uint256 validNumber = 0;
        for (uint256 i = 0; i < items[itemId].length; i++) {
            if (
                items[itemId][i].fingerprint != 0 &&
                items[itemId][i].invalid == false
            ) {
                validNumber++;
            }
        }
        return (validNumber, items[itemId].length);
    }

    function getLatestValidVersion(
        uint256 itemId
    ) public view override returns (string memory, uint256) {
        string memory source;
        uint256 fingerprint;
        for (uint256 i = items[itemId].length; i > 0; i--) {
            if (items[itemId][i - 1].invalid == false) {
                source = items[itemId][i - 1].source;
                fingerprint = items[itemId][i - 1].fingerprint;
                break;
            }
        }
        return (source, fingerprint);
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