// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./S10NBaseFacet.sol";
import "../subs/ISubInfoManager.sol";
import "../subs/ISubTokenManager.sol";
import "../plans/IPlanManager.sol";
import "../merchants/IMerchantTokenManager.sol";
import "../IPlatformFeeManager.sol";
import "../libs/Period.sol";

contract SubscriptionFacet is S10NSubManagerBaseFacet {
    event SubscriptionCreated(
        uint256 merchantTokenId,
        uint256 planIndex,
        address subscriber,
        uint256 subscriptionTokenId,
        uint256 subscriptionStartTime,
        uint256 subscriptionEndTime,
        uint256 nextBillingTime
    );
    event SubscriptionCharged(
        uint256 indexed merchantTokenId,
        uint256 indexed planIndex,
        uint256 indexed subscriptionTokenId,
        uint256 price,
        address paymentToken,
        address payeeAddress,
        uint256 billingTime,
        uint256 platformFee,
        address platformFeeAddress
    );
    event SubscriptionCanceled(
        uint256 merchantTokenId,
        uint256 subscriptionTokenId
    );
    event TransferAccepted(
        uint256 indexed subscriptionTokenId,
        address indexed owner
    );

    function createSubscription(
        uint256 merchantTokenId,
        uint256 planIndex
    ) external whenNotPaused {
        IPlanManager.Plan memory plan = IPlanManager(
            _getManagerAddress("PlanManager")
        ).getPlan(merchantTokenId, planIndex);

        require(plan.enabled, "plan disabled");

        uint256 subscriptionTokenId = ISubTokenManager(
            _getManagerAddress("SubTokenManager")
        ).mintSubToken(msg.sender);

        uint256 endTime = Period.getPeriodTimestamp(
            plan.billingPeriod,
            plan.maxTermLength,
            block.timestamp
        );

        uint256 nextBillingTime;
        // free plan will not charge and will not have nextBillingTime
        if (plan.pricePerBillingPeriod == 0) {
            nextBillingTime = endTime;
        } else {
            nextBillingTime = Period.getPeriodTimestamp(
                Period.PeriodType(plan.billingPeriod),
                block.timestamp
            );
            _charge(
                merchantTokenId,
                planIndex,
                subscriptionTokenId,
                msg.sender,
                plan.payeeAddress,
                plan.paymentToken,
                plan.pricePerBillingPeriod,
                block.timestamp
            );
        }

        ISubInfoManager(_getManagerAddress("SubInfoManager")).createSubInfo(
            msg.sender,
            merchantTokenId,
            subscriptionTokenId,
            planIndex,
            block.timestamp,
            endTime,
            nextBillingTime,
            plan.canResubscribe
        );

        emit SubscriptionCreated(
            merchantTokenId,
            planIndex,
            msg.sender,
            subscriptionTokenId,
            block.timestamp,
            endTime,
            nextBillingTime
        );
    }

    // charge
    function charge(uint256 subscriptionTokenId) external whenNotPaused {
        ISubInfoManager.SubInfo memory subInfo = ISubInfoManager(
            _getManagerAddress("SubInfoManager")
        ).getSubInfo(subscriptionTokenId);
        require(
            subInfo.subEndTime > subInfo.nextBillingTime,
            "subscription ended"
        );
        require(
            block.timestamp >
                subInfo.nextBillingTime - diamondStorage().chargeAheadTime,
            "must after bill time"
        );
        require(
            subInfo.transferProtected == false,
            "subscription transfer protected"
        );

        address subOwner = IERC721(_getManagerAddress("SubTokenManager"))
            .ownerOf(subscriptionTokenId);

        IPlanManager.Plan memory plan = IPlanManager(
            _getManagerAddress("PlanManager")
        ).getPlan(subInfo.merchantTokenId, subInfo.planIndex);

        uint billingTime = subInfo.nextBillingTime;
        uint256 newNextBillingTime = Period.getPeriodTimestamp(
            plan.billingPeriod,
            subInfo.nextBillingTime
        );
        require(newNextBillingTime <= subInfo.subEndTime, "term expired");
        subInfo.nextBillingTime = newNextBillingTime;
        ISubInfoManager(_getManagerAddress("SubInfoManager")).updateSubInfo(
            subscriptionTokenId,
            subInfo
        );
        _charge(
            subInfo.merchantTokenId,
            subInfo.planIndex,
            subscriptionTokenId,
            subOwner,
            plan.payeeAddress,
            plan.paymentToken,
            plan.pricePerBillingPeriod,
            billingTime
        );
    }

    function _charge(
        uint merchantTokenId,
        uint planIndex,
        uint subscriptionTokenId,
        address subOwner,
        address payeeAddress,
        address paymentToken,
        uint pricePerBillingPeriod,
        uint billingTime
    ) internal {
        if (pricePerBillingPeriod == 0) {
            return;
        }

        uint256 platformFee = IPlatformFeeManager(
            _getManagerAddress("PlatformFeeManager")
        ).getFee(paymentToken, pricePerBillingPeriod);

        require(pricePerBillingPeriod >= platformFee, "invalid price");

        uint256 adjustedPrice = pricePerBillingPeriod - platformFee;

        if (adjustedPrice > 0) {
            IERC20(paymentToken).transferFrom(
                subOwner,
                payeeAddress,
                adjustedPrice
            );
        }

        if (platformFee > 0) {
            IERC20(paymentToken).transferFrom(
                subOwner,
                diamondStorage().platformFeeAddress,
                platformFee
            );
        }

        if (pricePerBillingPeriod > 0) {
            emit SubscriptionCharged(
                merchantTokenId,
                planIndex,
                subscriptionTokenId,
                pricePerBillingPeriod,
                paymentToken,
                payeeAddress,
                billingTime,
                platformFee,
                diamondStorage().platformFeeAddress
            );
        }
    }

    // cancel sub
    function cancelSubscription(
        uint256 subscriptionTokenId
    ) external whenNotPaused {
        ISubInfoManager.SubInfo memory subInfo = ISubInfoManager(
            _getManagerAddress("SubInfoManager")
        ).getSubInfo(subscriptionTokenId);
        require(subInfo.subEndTime > subInfo.nextBillingTime, "sub closed");
        address merchantOwner = IMerchantTokenManager(
            _getManagerAddress("MerchantTokenManager")
        ).ownerOf(subInfo.merchantTokenId);
        address subOwner = IERC721(_getManagerAddress("SubTokenManager"))
            .ownerOf(subscriptionTokenId);
        require(
            msg.sender == merchantOwner || msg.sender == subOwner,
            "only sub owner or merchant owner"
        );
        subInfo.subEndTime = subInfo.nextBillingTime;
        ISubInfoManager(_getManagerAddress("SubInfoManager")).updateSubInfo(
            subscriptionTokenId,
            subInfo
        );

        emit SubscriptionCanceled(subInfo.merchantTokenId, subscriptionTokenId);
    }

    function acceptTransfer(
        uint256 subscriptionTokenId
    ) external whenNotPaused {
        ISubInfoManager.SubInfo memory subInfo = ISubInfoManager(
            _getManagerAddress("SubInfoManager")
        ).getSubInfo(subscriptionTokenId);
        address subOwner = IERC721(_getManagerAddress("SubTokenManager"))
            .ownerOf(subscriptionTokenId);
        require(msg.sender == subOwner, "only sub owner");
        require(subInfo.transferProtected == true, "transfer not protected");
        subInfo.transferProtected = false;
        ISubInfoManager(_getManagerAddress("SubInfoManager")).updateSubInfo(
            subscriptionTokenId,
            subInfo
        );
        emit TransferAccepted(subscriptionTokenId, subOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
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

    /**
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
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

    /**
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

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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

    /**
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

    /**
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

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract S10NSubManagerBaseFacet {

    // shared storage
    struct PlatformConfig {
        mapping(string => address) managerAddress;
        address platformFeeAddress;
        uint chargeAheadTime;
        bool paused;
    }

    bytes32 constant S10N_SUB_MANAGER_SHARED_STORAGE_POSITION =
        keccak256("diamond.standard.s10n.sub.manager.shared.storage");

    modifier whenNotPaused() {
        require(!diamondStorage().paused, "paused");
        _;
    }

    function diamondStorage() internal pure returns (PlatformConfig storage ds) {
        bytes32 position = S10N_SUB_MANAGER_SHARED_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function _getManagerAddress(
        string memory _managerName
    ) internal view returns (address) {
        return diamondStorage().managerAddress[_managerName];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISubInfoManager {
    struct SubInfo {
        uint256 merchantTokenId;
        uint256 subTokenId;
        uint256 planIndex; // plan Index (name?)
        uint256 subStartTime; // sub valid start time subStartTime
        uint256 subEndTime; // sub valid end time subEndTime
        uint256 nextBillingTime; // next bill time nextBillingTime
        bool transferProtected; // after each transfer, the transferProtected will be set to true
    }

    function setSubManager(address _manager) external;

    function setSubTokenManager(address _subTokenManager) external;

    function createSubInfo(
        address subscriber,
        uint256 merchantTokenId,
        uint256 subTokenId,
        uint256 planIndex,
        uint256 subStartTime,
        uint256 subEndTime,
        uint256 nextBillingTime,
        bool canResubscribe
    ) external;

    function getSubInfo(uint256 subTokenId)
        external
        view
        returns (SubInfo memory subInfo);

    function updateSubInfo(
        uint256 tokenId,
        SubInfo memory subInfo
    ) external;

    function transferProtect(uint256 subTokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISubTokenManager {
    function setSubManager(address _manager) external;

    function mintSubToken(address tokenOwner)
        external
        returns (uint256 tokenId);

    function setSubTokenDescriptor(address descriptor) external;

    function setMerchantTokenManager(address merchantToken) external;

    function setPlanManager(address planManager) external;

    function setSubInfoManager(address subInfoManager) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libs/Period.sol";

interface IPlanManager {

    struct Plan {
        uint256 merchantTokenId;
        string name;
        string description; // plan description
        Period.PeriodType billingPeriod; // Billing Period [DAY, WEEK, MONTH, YEAR]
        address paymentToken;
        address payeeAddress;
        uint256 pricePerBillingPeriod;
        uint maxTermLength; // by month
        bool enabled;
        bool isSBT;
        bool canResubscribe;
    }

    function setSubManager(address _manager) external;

    function createPlan(Plan memory plan) external returns (uint planIndex);

    function updatePlan(
        uint256 merchantTokenId,
        uint256 planIndex,
        Plan memory plan
    ) external;

    function getPlan(uint256 merchant, uint256 planIndex)
    external
    view
    returns (
        Plan memory plan
    );

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IMerchantTokenManager is IERC721Upgradeable {

    struct Merchant {
        string name;
        bool isSBT;
    }

    function setSubManager(address manager) external;

    function createMerchant(string memory name, address merchantOwner, bool isSBT) external returns (uint);

    function updateMerchant(uint merchantTokenId, string memory name) external;

    function getMerchant(uint merchantTokenId) external view returns (Merchant memory merchant);

    function setMerchantTokenDescriptor(address descriptor) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPlatformFeeManager {

    struct FeeConfig {
        uint256 feeRate;
        uint256 minFee;
    }

    function setDefaultFeeRate(uint256 feeRate) external;
    function setFeeConfig(address token, uint256 fee, uint256 minFee) external;
    function getFeeConfig(address token) external view returns (uint256 feeRate, uint256 minFee);
    function getFee(address token, uint256 amount) external view returns (uint256 fee);
    function validPrice(address token, uint256 amount) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./DateTimeLibrary.sol";

library Period {
    enum PeriodType {
        DAY,
        WEEK,
        MONTH,
        QUARTER,
        YEAR
    }

    function getPeriodName(PeriodType periodType)
        external
        pure
        returns (string memory name)
    {
        if (periodType == PeriodType.DAY) {
            name = "DAY";
        } else if (periodType == PeriodType.WEEK) {
            name = "WEEK";
        } else if (periodType == PeriodType.MONTH) {
            name = "MONTH";
        } else if (periodType == PeriodType.QUARTER) {
            name = "QUARTER";
        } else if (periodType == PeriodType.YEAR) {
            name = "YEAR";
        }
    }

    function getPeriodTimestamp(PeriodType period, uint256 curTimestamp)
        external
        pure
        returns (uint ts)
    {
        if (period == PeriodType.DAY) {
            ts = DateTimeLibrary.addDays(curTimestamp, 1);
        } else if (period == PeriodType.WEEK) {
            ts = DateTimeLibrary.addDays(curTimestamp, 7);
        } else if (period == PeriodType.MONTH) {
            ts = DateTimeLibrary.addMonths(curTimestamp, 1);
        } else if (period == PeriodType.QUARTER) {
            ts = DateTimeLibrary.addMonths(curTimestamp, 3);
        } else if (period == PeriodType.YEAR) {
            ts = DateTimeLibrary.addYears(curTimestamp, 1);
        }
    }

    function getPeriodTimestamp(
        PeriodType period,
        uint count,
        uint256 curTimestamp
    ) external pure returns (uint ts) {
        if (period == PeriodType.DAY) {
            ts = DateTimeLibrary.addDays(curTimestamp, count);
        } else if (period == PeriodType.WEEK) {
            ts = DateTimeLibrary.addDays(curTimestamp, count * 7);
        } else if (period == PeriodType.MONTH) {
            ts = DateTimeLibrary.addMonths(curTimestamp, count);
        } else if (period == PeriodType.QUARTER) {
            ts = DateTimeLibrary.addMonths(curTimestamp, count * 3);
        } else if (period == PeriodType.YEAR) {
            ts = DateTimeLibrary.addYears(curTimestamp, count);
        }
    }

    // YYYY-MM-DD hh:mm:ss
    function convertTimestampToDateTimeString(uint256 timestamp)
        external
        pure
        returns (string memory)
    {
        (
            uint256 YY,
            uint256 MM,
            uint256 DD,
            uint256 hh,
            uint256 mm,
            uint256 ss
        ) = DateTimeLibrary.timestampToDateTime(timestamp);

        string memory year = Strings.toString(YY);
        string memory month;
        string memory day;
        string memory hour;
        string memory minute;
        string memory second;
        if (MM == 0) {
            month = "00";
        } else if (MM < 10) {
            month = string(abi.encodePacked("0", Strings.toString(MM)));
        } else {
            month = Strings.toString(MM);
        }
        if (DD == 0) {
            day = "00";
        } else if (DD < 10) {
            day = string(abi.encodePacked("0", Strings.toString(DD)));
        } else {
            day = Strings.toString(DD);
        }

        if (hh == 0) {
            hour = "00";
        } else if (hh < 10) {
            hour = string(abi.encodePacked("0", Strings.toString(hh)));
        } else {
            hour = Strings.toString(hh);
        }

        if (mm == 0) {
            minute = "00";
        } else if (mm < 10) {
            minute = string(abi.encodePacked("0", Strings.toString(mm)));
        } else {
            minute = Strings.toString(mm);
        }

        if (ss == 0) {
            second = "00";
        } else if (ss < 10) {
            second = string(abi.encodePacked("0", Strings.toString(ss)));
        } else {
            second = Strings.toString(ss);
        }
        return
            string(
                abi.encodePacked(
                    year,
                    "-",
                    month,
                    "-",
                    day,
                    " ",
                    hour,
                    ":",
                    minute,
                    ":",
                    second
                )
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library DateTimeLibrary {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    uint256 constant DOW_MON = 1;
    uint256 constant DOW_TUE = 2;
    uint256 constant DOW_WED = 3;
    uint256 constant DOW_THU = 4;
    uint256 constant DOW_FRI = 5;
    uint256 constant DOW_SAT = 6;
    uint256 constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day -
            32075 +
            (1461 * (_year + 4800 + (_month - 14) / 12)) /
            4 +
            (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
            12 -
            (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
            4 -
            OFFSET19700101;

        _days = uint256(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    function timestampFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampFromDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) internal pure returns (uint256 timestamp) {
        timestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            hour *
            SECONDS_PER_HOUR +
            minute *
            SECONDS_PER_MINUTE +
            second;
    }

    function timestampToDate(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function timestampToDateTime(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day,
            uint256 hour,
            uint256 minute,
            uint256 second
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint256 daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }

    function isValidDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }

    function isLeapYear(uint256 timestamp)
        internal
        pure
        returns (bool leapYear)
    {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }

    function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }

    function getDaysInMonth(uint256 timestamp)
        internal
        pure
        returns (uint256 daysInMonth)
    {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(uint256 year, uint256 month)
        internal
        pure
        returns (uint256 daysInMonth)
    {
        if (
            month == 1 ||
            month == 3 ||
            month == 5 ||
            month == 7 ||
            month == 8 ||
            month == 10 ||
            month == 12
        ) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint256 timestamp)
        internal
        pure
        returns (uint256 dayOfWeek)
    {
        uint256 _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    function getYear(uint256 timestamp) internal pure returns (uint256 year) {
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        uint256 year;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint256 timestamp) internal pure returns (uint256 day) {
        uint256 year;
        uint256 month;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    function getMinute(uint256 timestamp)
        internal
        pure
        returns (uint256 minute)
    {
        uint256 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint256 timestamp)
        internal
        pure
        returns (uint256 second)
    {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint256 timestamp, uint256 _years)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addMonths(uint256 timestamp, uint256 _months)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = ((month - 1) % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addDays(uint256 timestamp, uint256 _days)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(uint256 timestamp, uint256 _hours)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }

    function addMinutes(uint256 timestamp, uint256 _minutes)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }

    function addSeconds(uint256 timestamp, uint256 _seconds)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint256 timestamp, uint256 _years)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subMonths(uint256 timestamp, uint256 _months)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = (yearMonth % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subDays(uint256 timestamp, uint256 _days)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subHours(uint256 timestamp, uint256 _hours)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }

    function subMinutes(uint256 timestamp, uint256 _minutes)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }

    function subSeconds(uint256 timestamp, uint256 _seconds)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _years)
    {
        require(fromTimestamp <= toTimestamp);
        uint256 fromYear;
        uint256 fromMonth;
        uint256 fromDay;
        uint256 toYear;
        uint256 toMonth;
        uint256 toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(
            fromTimestamp / SECONDS_PER_DAY
        );
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }

    function diffMonths(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _months)
    {
        require(fromTimestamp <= toTimestamp);
        uint256 fromYear;
        uint256 fromMonth;
        uint256 fromDay;
        uint256 toYear;
        uint256 toMonth;
        uint256 toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(
            fromTimestamp / SECONDS_PER_DAY
        );
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }

    function diffDays(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _days)
    {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    function diffHours(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _hours)
    {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }

    function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _minutes)
    {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }

    function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _seconds)
    {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
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

    /**
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

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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

    /**
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

    /**
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

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}