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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./types/PolicyArguments.sol";
import "./types/Params.sol";
import "./policy/libs/LibPolicy.sol";
import "./utils/libs/LibAutomatorUtils.sol";
import { NonceValidator } from "./utils/NonceValidator.sol";

contract Automator {

    address private polemoFeeAddress;
    IERC20 private usdcTokenInstance;
    // trusted oracle that supplies asset price
    IAssetPriceOracle private priceOracle;
    
    NonceValidator private nonceValidator;

    mapping(bytes32 => AssetDescription) private assets;
    // Assets this Automator instance is familar of (because Asset is either explicitly staked, reclaimed, claimed)
    mapping(bytes32 => bool) private knownAssets;

    event Staked(
        uint256 indexed assetId,
        address indexed assetContract,
        address indexed originalOwner,
        address currentOwner,
        uint256 timestamp
    );
    event Unstaked(
        uint256 indexed assetId,
        address indexed assetContract,
        address indexed originalOwner,
        address currentOwner,
        uint256 timestamp
    );
    event Claimed(
        uint256 indexed assetId,
        address indexed assetContract,
        address indexed originalOwner,
        address currentOwner,
        uint256 timestamp
    );
    event Unclaimed(
        uint256 indexed assetId,
        address indexed assetContract,
        address indexed originalOwner,
        address currentOwner,
        uint256 timestamp
    );
    event Reclaimed(
        uint256 indexed assetId,
        address indexed assetContract,
        address indexed originalOwner,
        address currentOwner,
        uint256 timestamp
    );
    event Returned(
        uint256 indexed assetId,
        address indexed assetContract,
        address indexed originalOwner,
        address currentOwner,
        uint256 timestamp
    );
    event Removed(
        uint256 indexed assetId,
        address indexed assetContract,
        uint256 indexed timestamp
    );
    event PolicyChecked(
        uint256 indexed assetId,
        address indexed assetContract,
        uint256 indexed result,
        address originalOwner,
        address currentOwner,
        uint256 timestamp
    );

    constructor(address _usdcTokenAddress) {
        usdcTokenInstance = IERC20(_usdcTokenAddress);
        nonceValidator = new NonceValidator();
    }

    function getFeeAddress() public view returns (address) {
        require(address(polemoFeeAddress) != address(0), FEE_ADDRESS_NOT_SET_ERR);
        return polemoFeeAddress;
    }

    function getOracleInterface() public view returns (IAssetPriceOracle) {
        require(address(priceOracle) != address(0), ORACLE_NOT_SET_ERR);
        return priceOracle;
    }

    function getErc20Interface() public view returns (IERC20) {
        return usdcTokenInstance;
    }

    function getOracleAssetRentPrice(
        IAssetPriceOracle _priceOracle,
        address assetContract,
        uint256 assetId
    ) public returns (uint256) {
        return _priceOracle.getPrice(assetId, assetContract);
    }

    function getOracleAssetRentPriceMock(
        IAssetPriceOracle _priceOracle,
        address assetContract,
        uint256 assetId
    ) public pure returns (uint256 price) {
        (_priceOracle, assetContract, assetId);
        price = 5e5; // 0.5 usdc
    }

    function getAsset(
        uint256 assetId,
        address assetContract
    ) public view returns (AssetDescription memory asset) {
        bytes32 internalId = LibAutomatorUtils.calculateInternalAssetId(assetContract, assetId);
        asset = assets[internalId];
    }

    function setPolemosFeeAddress(
        address _polemosFeeAddress
        /* bytes memory signature */
    ) public {
        // todo:
        // recover admin signatory
        // compare signatory and admin
        polemoFeeAddress = _polemosFeeAddress;
    }

    function setOracleAddress(
        address oracleAddress
        /* bytes memory signature */
    ) public {
        // todo:
        // recover admin signatory
        // compare signatory and admin
        priceOracle = IAssetPriceOracle(oracleAddress);
    }

    function removeAsset(
        RemoveAssetParams memory params
        /* bytes memory siganture */
    ) public {
        // todo:
        // recover signatory 
        // compare signatory and admin
        bytes32 internalId = LibAutomatorUtils.calculateInternalAssetId(params.assetContract, params.assetId);
        AssetDescription storage gameAsset = assets[internalId];

        LibAutomatorUtils._removeAsset(
            gameAsset
        );
        knownAssets[internalId] = true;

        emit Removed(
            gameAsset.assetId,
            gameAsset.assetContract,
            LibAutomatorUtils.getLatestBlockTimestamp()
        );
    }

    function checkPolicy(
        PolicyArguments memory args
        /* bytes memory signature */
    ) public returns (CheckResult checkStatus) {
        // todo: consider assuring that sender is authenticated and permited to invoke check policy
        bytes32 internalAssetId = LibAutomatorUtils.calculateInternalAssetId(args.tokenContract, args.tokenId);
        bool isAssetKnown = knownAssets[internalAssetId];
        AssetDescription memory gameAsset = assets[internalAssetId];

        checkStatus = LibPolicyCheck.applyPolicy(isAssetKnown, gameAsset, args);

        emit PolicyChecked(
            args.tokenId,
            args.tokenContract,
            uint256(checkStatus),
            gameAsset.originalOwner,
            gameAsset.currentOwner,
            LibAutomatorUtils.getLatestBlockTimestamp()
        );
    }

    function stakeAsset(
        StakeAssetParams memory params
    ) public {
        // todo: recover signatory, this should be lender
        // todo: validate stake params: lender != address(0), assetContract != address(0), timestamp != 0
        bytes32 internalId = LibAutomatorUtils.calculateInternalAssetId(params.assetContract, params.assetId);
        AssetDescription storage gameAsset = assets[internalId];

        LibAutomatorUtils._stakeAsset(gameAsset, params);
        gameAsset.internalId = internalId;
        knownAssets[internalId] = true;

        emit Staked(
            gameAsset.assetId,
            gameAsset.assetContract,
            gameAsset.originalOwner,
            gameAsset.currentOwner,
            LibAutomatorUtils.getLatestBlockTimestamp()
        );
    }

    function claimAsset(
        ClaimAssetParams memory params
    ) public {
        // recover signatory, this should be borrower
        bytes32 internalId = LibAutomatorUtils.calculateInternalAssetId(params.assetContract, params.assetId);
        AssetDescription storage gameAsset = assets[internalId];

        LibAutomatorUtils._claimAsset(
            getErc20Interface(),
            // todo: get actual price
            getOracleAssetRentPriceMock(
                priceOracle,
                params.assetContract,
                params.assetId
            ),
            getFeeAddress(),
            gameAsset,
            params
        );

        emit Claimed(
            gameAsset.assetId,
            gameAsset.assetContract,
            gameAsset.originalOwner,
            gameAsset.currentOwner,
            LibAutomatorUtils.getLatestBlockTimestamp()
        );
    }

    function reclaimAsset(
        ReclaimAssetParams memory params
    ) public {
        // recover signatory, this should be lender
        bytes32 internalId = LibAutomatorUtils.calculateInternalAssetId(params.assetContract, params.assetId);
        AssetDescription storage gameAsset = assets[internalId];

        LibAutomatorUtils._reclaimAsset(
            gameAsset,
            params
        );

        emit Reclaimed(
            gameAsset.assetId,
            gameAsset.assetContract,
            gameAsset.originalOwner,
            gameAsset.currentOwner,
            LibAutomatorUtils.getLatestBlockTimestamp()
        );
    }

    function unclaimAsset(
        UnclaimAssetParams memory params
    ) public {
        // recover signatory, this should be borrower
        bytes32 internalId = LibAutomatorUtils.calculateInternalAssetId(params.assetContract, params.assetId);
        AssetDescription storage gameAsset = assets[internalId];

        LibAutomatorUtils._unclaimAsset(
            gameAsset,
            params
        );

        emit Unclaimed(
            gameAsset.assetId,
            gameAsset.assetContract,
            gameAsset.originalOwner,
            gameAsset.currentOwner,
            LibAutomatorUtils.getLatestBlockTimestamp()
        );
    }

    function unstakeAsset(
        UnstakeAssetParams memory params
    ) public {
        // recover signatory, this should be lender
        bytes32 internalId = LibAutomatorUtils.calculateInternalAssetId(params.assetContract, params.assetId);
        AssetDescription storage gameAsset = assets[internalId];

        LibAutomatorUtils._unstakeAsset(
            gameAsset,
            params
        );

        emit Unstaked(
            gameAsset.assetId,
            gameAsset.assetContract,
            gameAsset.originalOwner,
            gameAsset.currentOwner,
            LibAutomatorUtils.getLatestBlockTimestamp()
        );
    }

    function returnAsset(
        ReturnAssetParams memory params
    ) public {
        bytes32 internalId = LibAutomatorUtils.calculateInternalAssetId(params.assetContract, params.assetId);
        AssetDescription storage gameAsset = assets[internalId];

        LibAutomatorUtils._returnAsset(gameAsset);

        emit Returned(
            gameAsset.assetId,
            gameAsset.assetContract,
            gameAsset.originalOwner,
            gameAsset.currentOwner,
            LibAutomatorUtils.getLatestBlockTimestamp()
        );
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

uint256 constant DEFAULT_RECLAIM_PERIOD = 5 * 60;

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

// todo: replace followings with codes
string constant NONCE_USED_ERR = "N-001";
string constant NO_ERC20_TRANSFER_ERR = "ERC-20 token transfer failure";
string constant NO_ERC721_LENDER_APPROVAL_ERR = "No approval given by lender to operate erc-721 asset";
string constant NO_ERC721_BORROWER_APPROVAL_ERR = "No approval given by borrower to operate erc-721 asset";
string constant BORROWER_NOT_ASSET_OWNER_ERR = "Borrower is not owner of the asset";
string constant LENDER_NOT_ASSET_OWNER_ERR = "Lender is not owner of the asset";
string constant UNKNOWN_ASSET_ERROR = "Given asset is unknown";
string constant LOW_ERC20_ALLOWANCE_ERROR = "Requested allowance is too low";
string constant ORACLE_NOT_SET_ERR = "Oracle not set";
string constant ERC20_NOT_SET_ERR = "ERC20 interface required for token payments is not set";
string constant ASSET_IS_REMOVED_ERR = "Can not apply policy to removed asset";
string constant ASSET_IS_NOT_UNSTAKED_ERR = "Asset status has to be Status.Unstaked";
string constant ASSET_IS_NOT_CLAIMED_ERR = "Asset status has to be Status.Claimed";
string constant ASSET_IS_NOT_STAKED_ERR = "Asset status has to be Status.Staked";
string constant ASSET_IS_NOT_CLAIMED_OR_RECLAIMED = "Asset status has to be Status.Reclaimed or Status.Claimed";
string constant FEE_ADDRESS_NOT_SET_ERR = "Polemos fee address not set";
string constant RENTAL_OR_RECLAIM_PERIOD_CONTINUE_ERR = "Rental period or reclaim period still in progress";
string constant LENDER_NOT_ORIGINAL_OWNER_ERR = "Lender is not original asset owner";
string constant RENTAL_OR_RECLAIM_PERIOD_IS_NIL_ERR = "The value of rental or reclaim period should be larger than nil";
string constant BORROWER_NOT_CURRENT_OWNER_ERR = "Borrower is not current asset owner";
string constant ASSET_CONTRACT_IS_NIL_ERR = "Asset contract can not be equal to address zero";
string constant ASSET_IS_NOT_STAKED_OR_UNSTAKED = "Asset status has to be Status.Unstaked or Status.Staked";

// SPDX-License-Identifier: Unclicense
pragma solidity ^0.8.17;

interface INonceValidator {
    function validate(uint256 nonce) external returns (uint256);
    function isNonceConsumed(uint256 nonce) external view returns (bool);
}

interface IAssetPriceOracle {
    function getPrice(uint256 assetId, address assetContract) external returns (uint256 price);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "../../constants/Errors.sol";
import "../../types/Types.sol";
import "../../types/PolicyArguments.sol";

library LibPolicyCheck {

    function applyPolicy(
        bool isAssetKnown,
        AssetDescription memory gameAsset,
        PolicyArguments memory args
    ) internal view returns (CheckResult checkStatus) {
        Status status = gameAsset.status;
        
        // this means that args.operation is done under native coin, erc20, asset that
        // not been marked as staked, or asset that does not belong to any game nft
        if (!isAssetKnown) {
            return CheckResult.CheckedWhenAssetUnknown;
        }
        // removed asset should not apply any policy
        // note: this validatation is retained just in case;
        // there is no way it should go here, because when removed, asset is set as no longer known for this contract
        // todo: what method to invoke, when someone tries to apply policy to removed asset before manager of Automator actually
        // sets the asset as unknown
        validateAssetIsRemoved(status);

        if (status == Status.Unstaked || status == Status.Staked) {
            return CheckResult.CheckedWhenAssetStakedOrUnstaked;
        }
        // this should only go for the following statuses: Claimed, Reclaimed
        // and when asset operation is unknown or when this is set approval for all where operator is Automator
        if (
            args.operation == OperationType.Unknown
            || (args.operation == OperationType.ApproveForAll_ERC721 && args.operator == address(this))
        ) {
            return CheckResult.CheckedWhenAssetOperationAllowed;
        }
        return CheckResult.Not_Checked;
    }

    function validateAssetIsRemoved(Status assetStatus) private pure {
        require(assetStatus != Status.Removed, ASSET_IS_REMOVED_ERR);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

struct StakeAssetParams {
    address lender;
    address assetContract;
    uint256 assetId;
    uint256 nonce;
    uint256 timestamp;
    // bytes signature; // lender signature
}

struct ClaimAssetParams {
    address lender;
    address borrower;
    address assetContract;
    uint256 assetId;
    uint256 nonce;
    uint256 borrowingPeriodInSeconds;
    uint256 timestamp;
    // bytes signature; // borrower signature
}

struct UnclaimAssetParams {
    address lender;
    address borrower;
    address assetContract;
    uint256 assetId;
    uint256 nonce;
    uint256 timestamp;
    // bytes signature; // borrower signature
}

struct ReclaimAssetParams {
    address lender;
    address borrower;
    address assetContract;
    uint256 assetId;
    uint256 nonce;
    uint256 timestamp;
    // bytes signature; // lender signature
}

struct ReturnAssetParams {
    address assetContract;
    uint256 assetId;
}

struct UnstakeAssetParams {
    address lender;
    address assetContract;
    uint256 assetId;
    uint256 nonce;
    uint256 timestamp;
    // bytes signature; // lender signature
}

struct RemoveAssetParams {
    address assetContract;
    uint256 assetId;
    uint256 nonce;
    uint256 timestamp;
    // bytes signature;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./Types.sol";

// this compatible with erc-721 and sign_typed_data
struct PolicyArguments {
    uint256 tokenId; // using in 'approve', 'transferFrom', 'burn'
    address tokenContract;
    address from; // using in 'transferFrom'
    address to; // using in 'transferFrom', 'approve'
    address operator; // using in 'setApprovalForAll'
    bool approved; // using in 'setApprovalForAll'
    address verifyingContract; // using in _sign_typed_data rpc-api method
    OperationType operation;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

enum CheckResult {
    Not_Checked,
    CheckedWhenAssetUnknown,
    CheckedWhenAssetStakedOrUnstaked,
    CheckedWhenAssetOperationAllowed
}

// todo: use bytes32 value, example: hashedStatus = keccak256(Status.Removed)
enum Status {
    Unstaked,
    Staked,
    Claimed,
    Reclaimed,
    Removed
}

enum OperationType {
    TransferNativeCoin,
    TransferFrom_ERC721,
    Approve_ERC721,
    ApproveForAll_ERC721,
    Burn_ERC721,
    Transfer_ERC20,
    TransferFrom_ERC20,
    Unknown
}

struct AssetDescription {
    uint256 assetId;
    bytes32 internalId;
    address assetContract;
    address originalOwner; // lender
    address currentOwner; // borrower
    // borrowing period timestamp: rental is over when current timestamp is greater than rental timestamp
    uint256 rentalOrReclaimPeriod;
    Status status;
    // who is approved to manage this asset. only Automator address should be added in a list
    // address[] knownOperators;
}

struct History {
    uint256 id;
    uint256 timestamp;
    address lender; // owner of an Asset
    address borrower;
    Status status; // status the Asset has when operation completed
    OperationType operationType; // what operation type was completed
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "../../constants/Errors.sol";
import "../../constants/Constants.sol";
import "../../types/Types.sol";
import "../../types/Params.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IAssetPriceOracle } from "../../interfaces/Interfaces.sol";
import "./LibParamValidator.sol";

library LibAutomatorUtils {

    function getLatestBlockTimestamp() internal view returns (uint256 timestamp) {
        /* solhint-disable not-rely-on-time */
        timestamp = block.timestamp;
        /* solhint-enable not-rely-on-time */
    }

    function calculateInternalAssetId(
        address assetContract,
        uint256 assetId
    ) internal pure returns (bytes32 id) {
        LibParamValidator.validateAssetContractAddress(assetContract);
        id = keccak256(abi.encodePacked(assetId, assetContract));
    }

    function compareSuppliedRentPriceAndOracleRentPriceMock(
        address assetContract,
        uint256 assetId,
        uint256 suppliedPrice, // price supplied as an argument
        uint256 allowedDelta, // todo: include 'allowedDelta' in signature
        uint256 deadline
    ) internal pure returns (bool comparisonResult) {
        bytes32 internalAssetId = calculateInternalAssetId(assetContract, assetId);
        return compareSuppliedRentPriceAndOracleRentPriceMock(internalAssetId, suppliedPrice, allowedDelta, deadline);
    }

    function compareSuppliedRentPriceAndOracleRentPriceMock(
        bytes32 internalAssetId,
        uint256 suppliedPrice, // price supplied as an argument
        uint256 allowedDelta, // todo: include 'allowedDelta' in signed message
        uint256 deadline
    ) internal pure returns (bool comparisonResult) {
        (internalAssetId, suppliedPrice, allowedDelta, deadline);
        // uint256 oraclePirce = fetch price from oracle
        // uint256 delta = uint256 (oraclePirce - suppliedPrice);
        // comparisonResult = delta <= allowedDetla;
        comparisonResult = true;
    }
    
    function _stakeAsset(
        AssetDescription storage gameAsset,
        StakeAssetParams memory params
    ) internal {
        LibParamValidator.validateAssetStatus(gameAsset.status, Status.Unstaked, ASSET_IS_NOT_UNSTAKED_ERR);
        IERC721 tokenContract = IERC721(params.assetContract);

        LibParamValidator.validateErc721AssetOwner(
            params.assetId,
            tokenContract,
            params.lender,
            LENDER_NOT_ASSET_OWNER_ERR
        );

        updateAssetDescription(
            gameAsset,
            Status.Staked,
            params.lender,
            params.lender,
            0,
            params.assetId,
            params.assetContract
        );
    }
    
    function _claimAsset(
        IERC20 erc20TokenContract,
        uint256 totalFees,
        address feeReceiver,
        AssetDescription storage gameAsset,
        ClaimAssetParams memory params
    ) internal {
        LibParamValidator.validateAssetStatus(gameAsset.status, Status.Staked, ASSET_IS_NOT_STAKED_ERR);
        LibParamValidator.validatAssetOwnerShip(params.lender, gameAsset.originalOwner, LENDER_NOT_ORIGINAL_OWNER_ERR);

        payRentalFees(erc20TokenContract, params.borrower, feeReceiver, totalFees);

        transferAssetToBorrower(gameAsset, params.borrower);

        updateAssetDescription(
            gameAsset,
            Status.Claimed,
            gameAsset.originalOwner,
            params.borrower,
            getLatestBlockTimestamp() + params.borrowingPeriodInSeconds,
            gameAsset.assetId,
            gameAsset.assetContract
        );
    }
    
    function _reclaimAsset(
        AssetDescription storage gameAsset,
        ReclaimAssetParams memory params
    ) internal {
        LibParamValidator.validateAssetStatus(gameAsset.status, Status.Claimed, ASSET_IS_NOT_CLAIMED_ERR);
        LibParamValidator.validatAssetOwnerShip(params.lender, gameAsset.originalOwner, LENDER_NOT_ORIGINAL_OWNER_ERR);

        updateAssetDescription(
            gameAsset,
            Status.Reclaimed,
            gameAsset.originalOwner,
            gameAsset.currentOwner,
            getLatestBlockTimestamp() + DEFAULT_RECLAIM_PERIOD,
            gameAsset.assetId,
            gameAsset.assetContract
        );
    }
    
    function _unclaimAsset(
        AssetDescription storage gameAsset,
        UnclaimAssetParams memory params
    ) internal {
        LibParamValidator.validateAssetStatus(gameAsset.status, Status.Claimed, ASSET_IS_NOT_CLAIMED_ERR);
        // todo: consider adding given validation
        // require(params.lender == gameAsset.originalOwner, LENDER_NOT_ORIGINAL_OWNER_ERR);
        LibParamValidator.validatAssetOwnerShip(params.borrower, gameAsset.currentOwner, BORROWER_NOT_CURRENT_OWNER_ERR);

        transferAssetToOriginalOwner(gameAsset);

        updateAssetDescription(
            gameAsset,
            Status.Staked,
            gameAsset.originalOwner,
            gameAsset.originalOwner,
            0,
            gameAsset.assetId,
            gameAsset.assetContract
        );
    }
    
    function _unstakeAsset(
        AssetDescription storage gameAsset,
        UnstakeAssetParams memory params
    ) internal {
        LibParamValidator.validateAssetStatus(gameAsset.status, Status.Staked, ASSET_IS_NOT_STAKED_ERR);
        LibParamValidator.validatAssetOwnerShip(params.lender, gameAsset.originalOwner, LENDER_NOT_ORIGINAL_OWNER_ERR);

        updateAssetDescription(
            gameAsset,
            Status.Unstaked
        );
    }
    
    function _returnAsset(
        AssetDescription storage gameAsset
    ) internal {
        LibParamValidator.validateAssetStatus(
            gameAsset.status,
            Status.Claimed,
            Status.Reclaimed,
            ASSET_IS_NOT_CLAIMED_OR_RECLAIMED
        );
        LibParamValidator.validateRentalOrReclaimPeriod(
            getLatestBlockTimestamp(),
            gameAsset.rentalOrReclaimPeriod
        );

        transferAssetToOriginalOwner(gameAsset);

        updateAssetDescription(
            gameAsset,
            Status.Staked,
            gameAsset.originalOwner,
            gameAsset.originalOwner,
            0,
            gameAsset.assetId,
            gameAsset.assetContract
        );
    }
    
    function _removeAsset(
        AssetDescription storage gameAsset
    ) internal {
        LibParamValidator.validateAssetStatus(
            gameAsset.status,
            Status.Staked,
            Status.Unstaked,
            ASSET_IS_NOT_STAKED_OR_UNSTAKED
        );

        updateAssetDescription(
            gameAsset,
            Status.Removed
        );
    }

    function payRentalFees(
        IERC20 erc20TokenContract,
        address borrower,
        address feeReceiver,
        uint256 totalFees
    ) private returns (bool payed) {
        LibParamValidator.validateErc20Approval(borrower, address(this), erc20TokenContract, totalFees);
        payed = erc20TokenContract
            .transferFrom(
                borrower,
                feeReceiver,
                totalFees
            );
        require(payed, NO_ERC20_TRANSFER_ERR);
    }

    function transferAssetToOriginalOwner(
        AssetDescription storage gameAsset
    ) private returns (bool isTransfered) {
        uint256 tokenId = gameAsset.assetId;
        address currentOwner = gameAsset.currentOwner;
        address originalOwner = gameAsset.originalOwner;
        IERC721 tokenContract = IERC721(gameAsset.assetContract);

        LibParamValidator.validateErc721AssetOwner(
            tokenId,
            tokenContract,
            currentOwner,
            BORROWER_NOT_ASSET_OWNER_ERR
        );
        LibParamValidator.validateErc721Approval(
            currentOwner,
            address(this),
            tokenContract,
            NO_ERC721_BORROWER_APPROVAL_ERR
        );

        tokenContract.transferFrom(currentOwner, originalOwner, tokenId);
        gameAsset.currentOwner = originalOwner;
        isTransfered = true;
    }

    function transferAssetToBorrower(
        AssetDescription memory gameAsset,
        address borrower
    ) private returns (bool isTransfered) {
        uint256 tokenId = gameAsset.assetId;
        address originalOwner = gameAsset.originalOwner;
        IERC721 tokenContract = IERC721(gameAsset.assetContract);

        LibParamValidator.validateErc721AssetOwner(
            tokenId,
            tokenContract,
            originalOwner,
            LENDER_NOT_ASSET_OWNER_ERR
        );
        LibParamValidator.validateErc721Approval(
            originalOwner,
            address(this),
            tokenContract,
            NO_ERC721_LENDER_APPROVAL_ERR
        );

        tokenContract.transferFrom(originalOwner, borrower, tokenId);
        isTransfered = true;
    }

    function updateAssetDescription(
        AssetDescription storage gameAsset,
        Status status,
        address originalOwner,
        address currentOwner,
        uint256 rentalOrReclaimPeriod,
        uint256 assetId,
        address assetContract
    ) private returns (bool updated) {
        gameAsset.status = status;
        gameAsset.originalOwner = originalOwner;
        gameAsset.currentOwner = currentOwner;
        gameAsset.rentalOrReclaimPeriod = rentalOrReclaimPeriod;
        gameAsset.assetId = assetId;
        gameAsset.assetContract = assetContract;
        updated = true;
    }

    function updateAssetDescription(
        AssetDescription storage gameAsset,
        Status status
    ) private returns (bool updated) {
        gameAsset.status = status;
        updated = true;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../types/Types.sol";
import "../../constants/Errors.sol";

library LibParamValidator {

    function validateErc721Approval(
        address owner,
        address operator,
        IERC721 assetContract,
        string memory errorMEssage
    ) internal view {
        require(assetContract.isApprovedForAll(owner, operator), errorMEssage);
    }

    function validateErc721AssetOwner(
        uint256 assetId,
        IERC721 assetContract,
        address expectedOwner,
        string memory errorMessage
    ) internal view {
        require(assetContract.ownerOf(assetId) == expectedOwner, errorMessage);
    }

    function validateErc20Approval(
        address owner,
        address spender,
        IERC20 erc20TokenContract,
        uint256 expectedAlowance
    ) internal view {
        uint256 allowance = erc20TokenContract.allowance(owner, spender);
        require(allowance >= expectedAlowance, LOW_ERC20_ALLOWANCE_ERROR);
    }

    function validateRentalOrReclaimPeriod(
        uint256 currentTimestamp,
        uint256 rentalOrReclaimPeriod
    ) internal pure {
        require(rentalOrReclaimPeriod != 0, RENTAL_OR_RECLAIM_PERIOD_IS_NIL_ERR);
        require(currentTimestamp >= rentalOrReclaimPeriod, RENTAL_OR_RECLAIM_PERIOD_CONTINUE_ERR);
    }

    function validateAssetContractAddress(address assetContract) internal pure {
        require(assetContract != address(0), ASSET_CONTRACT_IS_NIL_ERR);
    }

    function validateAssetStatus(
        Status assetStatus,
        Status expectedStatus,
        string memory errorDescription
    ) internal pure {
        require(assetStatus == expectedStatus, errorDescription);
    }

    function validateAssetStatus(
        Status assetStatus,
        Status expectedStatus,
        Status addtionaExpectedStatus,
        string memory errorDescription
    ) internal pure {
        require(assetStatus == addtionaExpectedStatus || assetStatus == expectedStatus, errorDescription);
    }

    function validatAssetOwnerShip(
        address owner,
        address expectedOwner,
        string memory errorDescription
    ) internal pure {
        require(owner == expectedOwner, errorDescription);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "../constants/Errors.sol";
import { INonceValidator } from "../interfaces/Interfaces.sol";
import "./ownable/BasicOwnable.sol";

contract NonceValidator is INonceValidator, BasicOwnable {
  mapping(uint256 => bool) private isNonceApplied;

  function validate(uint256 nonce)
    public
    override
    onlyUser
    returns (uint256)
  {
    require(!isNonceApplied[nonce], NONCE_USED_ERR);
    isNonceApplied[nonce] = true;
    return nonce;
  }

  function isNonceConsumed(uint256 nonce)
    public
    view
    override
    onlyUser
    returns (bool)
  {
    return isNonceApplied[nonce];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17; 

string constant THE_CALLER_NOT_ADMIN_ERR = "BasicOwnable: The caller is not admin";
string constant THE_CALLER_NOT_USER_ERR = "BasicOwnable: The caller is not user";

contract BasicOwnable { 
  address private _admin; 
  mapping(address => bool) private _users;

  modifier onlyAdmin() {
    require(
      msg.sender == _admin,
      THE_CALLER_NOT_ADMIN_ERR
    ); 
    _;
  }

  modifier onlyUser() {
    address caller = msg.sender;
    require(
      caller == _admin || _users[caller],
      THE_CALLER_NOT_USER_ERR
    );
    _;
  }

  constructor() {
    _admin = msg.sender; 
  }

  function setUser(address group) external onlyAdmin {
    _users[group] = true; 
  } 
}