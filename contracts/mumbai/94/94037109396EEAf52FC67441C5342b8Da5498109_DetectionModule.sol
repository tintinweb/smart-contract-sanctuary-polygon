// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IItemNFT.sol";
import "../interfaces/IComponentGlobal.sol";
import "../interfaces/IDetectionModule.sol";

interface MurmesInterface {
    function owner() external view returns (address);

    function componentGlobal() external view returns (address);

    function getTaskSettlementModuleAndItems(
        uint256 taskId
    ) external view returns (DataTypes.SettlementType, uint256[] memory);
}

contract DetectionModule is IDetectionModule {
    /**
     * @notice Murmes主合约地址
     */
    address public Murmes;
    /**
     * @notice 检测阈值
     */
    uint256 public distanceThreshold;
    /**
     * @notice 介绍该模块的名称
     */
    string private _name;

    constructor(address ms, uint256 threshold, string memory name_) {
        Murmes = ms;
        distanceThreshold = threshold;
        _name = name_;
    }

    /**
     * @notice 设置新的检测阈值
     * @param newDistanceThreshold 新的检测阈值
     */
    function setDistanceThreshold(uint8 newDistanceThreshold) external {
        require(MurmesInterface(Murmes).owner() == msg.sender, "DNS15");
        distanceThreshold = newDistanceThreshold;
        emit SetDistanceThreshold(newDistanceThreshold);
    }

    // ***************** Internal Functions *****************
    /**
     * @notice 获得特定众包任务下所有Item的指纹值
     * @param taskId 众包任务ID
     * @return 所有Item的指纹值
     */
    function _getHistoryFingerprint(
        uint256 taskId
    ) internal view returns (uint256[] memory) {
        (, uint256[] memory items) = MurmesInterface(Murmes)
            .getTaskSettlementModuleAndItems(taskId);
        uint256[] memory history = new uint256[](items.length);
        address components = MurmesInterface(Murmes).componentGlobal();
        address itemToken = IComponentGlobal(components).itemToken();
        for (uint256 i = 0; i < items.length; i++) {
            history[i] = IItemNFT(itemToken).getItemFingerprint(items[i]);
        }
        return history;
    }

    // ***************** View Functions *****************
    /**
     * @notice 提交Item之前进行的检测
     * @param taskId 众包任务ID
     * @param origin 新上传Item的指纹值
     * @return 是否通过检测
     */
    function detectionInSubmitItem(
        uint256 taskId,
        uint256 origin
    ) external view override returns (bool) {
        uint256[] memory history = _getHistoryFingerprint(taskId);
        for (uint256 i = 0; i < history.length; i++) {
            uint256 distance = hammingDistance(origin, history[i]);
            if (distance <= distanceThreshold) {
                return false;
            }
        }
        return true;
    }

    /**
     * @notice 更新Item新版本时进行的检测
     * @param newUpload 新上传Item版本的指纹值
     * @param oldUpload 旧版本Item的指纹值
     * @return 是否通过检测
     */
    function detectionInUpdateItem(
        uint256 newUpload,
        uint256 oldUpload
    ) external view override returns (bool) {
        uint256 distance = hammingDistance(newUpload, oldUpload);
        if (distance <= distanceThreshold) {
            return true;
        }
        return false;
    }

    /**
     * @notice 获得模块的名称
     * @return 当前模块的名称
     */
    function name() external view returns (string memory) {
        return _name;
    }

    // 汉明距离计算
    function hammingDistance(
        uint256 a,
        uint256 b
    ) public pure returns (uint256) {
        uint256 c = a ^ b;
        uint256 count = 0;
        while (c != 0) {
            c = c & (c - 1);
            count++;
        }
        return count;
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