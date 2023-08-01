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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

interface IGotchiLendingFacet {
    // @param _erc721TokenId The identifier of the NFT to lend
    // @param _initialCost The lending fee of the aavegotchi in $GHST
    // @param _period The lending period of the aavegotchi, unit: second
    // @param _revenueSplit The revenue split of the lending, 3 values, sum of the should be 100
    // @param _originalOwner The account for original owner, can be set to another address if the owner wishes to have profit split there.
    // @param _thirdParty The 3rd account for receive revenue split, can be address(0)
    // @param _whitelistId The identifier of whitelist for agree lending, if 0, allow everyone
    struct AddGotchiListing {
        uint32 tokenId;
        uint96 initialCost;
        uint32 period;
        uint8[3] revenueSplit;
        address originalOwner;
        address thirdParty;
        uint32 whitelistId;
        address[] revenueTokens;
    }

    // @notice Allow aavegotchi lenders (msg sender) or their lending operators to add request for lending
    // @dev If the lending request exist, cancel it and replaces it with the new one
    // @dev If the lending is active, unable to cancel
    function addGotchiListing(AddGotchiListing memory p) external;

    // @notice Allow a borrower to agree an lending for the NFT
    // @dev Will throw if the NFT has been lent or if the lending has been canceled already
    // @param _listingId The identifier of the lending to agree
    function agreeGotchiLending(
        uint32 _listingId,
        uint32 _erc721TokenId,
        uint96 _initialCost,
        uint32 _period,
        uint8[3] calldata _revenueSplit
    ) external;

    function cancelGotchiLending(uint32 _listingId) external;

    function claimGotchiLending(uint32 _tokenId) external;

    function claimAndEndGotchiLending(uint32 _tokenId) external;

    function claimAndEndAndRelistGotchiLending(uint32 _tokenId) external;

    function addGotchiLending(
        uint32 _erc721TokenId,
        uint96 _initialCost,
        uint32 _period,
        uint8[3] calldata _revenueSplit,
        address _originalOwner,
        address _thirdParty,
        uint32 _whitelistId,
        address[] calldata _revenueTokens,
        uint256 _permissions
    ) external;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.9;

import { AavegotchiInfo, GotchiLending, LendingOperatorInputs } from "../libraries/LibAavegotchiStorage.sol";

interface ILendingGetterAndSetterFacet {
    struct GotchiLendingAdd {
        uint32 listingId;
        address lender;
        uint32 tokenId;
        uint96 initialCost;
        uint32 period;
        uint8[3] revenueSplit;
        address originalOwner;
        address thirdParty;
        uint32 whitelistId;
        address[] revenueTokens;
        uint256 timeCreated;
        uint256 permissions;
    }

    struct GotchiLendingExecution {
        uint32 listingId;
        address lender;
        address borrower;
        uint32 tokenId;
        uint96 initialCost;
        uint32 period;
        uint8[3] revenueSplit;
        address originalOwner;
        address thirdParty;
        uint32 whitelistId;
        address[] revenueTokens;
        uint256 timeAgreed;
        uint256 permissions;
    }

    struct GotchiLendingCancellation {
        uint32 listingId;
        address lender;
        uint32 tokenId;
        uint96 initialCost;
        uint32 period;
        uint8[3] revenueSplit;
        address originalOwner;
        address thirdParty;
        uint32 whitelistId;
        address[] revenueTokens;
        uint256 timeCancelled;
        uint256 permissions;
    }

    struct GotchiLendingClaim {
        uint32 listingId;
        address lender;
        address borrower;
        uint32 tokenId;
        uint96 initialCost;
        uint32 period;
        uint8[3] revenueSplit;
        address originalOwner;
        address thirdParty;
        uint32 whitelistId;
        address[] revenueTokens;
        uint256[] amounts;
        uint256 timeClaimed;
        uint256 permissions;
    }

    struct GotchiLendingEnd {
        uint32 listingId;
        address lender;
        address borrower;
        uint32 tokenId;
        uint96 initialCost;
        uint32 period;
        uint8[3] revenueSplit;
        address originalOwner;
        address thirdParty;
        uint32 whitelistId;
        address[] revenueTokens;
        uint256 timeEnded;
        uint256 permissions;
    }

    event GotchiLendingAdded(GotchiLendingAdd);
    event GotchiLendingExecuted(GotchiLendingExecution);
    event GotchiLendingCancelled(GotchiLendingCancellation);
    event GotchiLendingClaimed(GotchiLendingClaim);
    event GotchiLendingEnded(GotchiLendingEnd);

    /// @notice Enable or disable approval for a third party("operator") to help pet LibMeta.msgSender()'s gotchis
    ///@dev Emits the PetOperatorApprovalForAll event
    ///@param _operator Address to disable/enable as a pet operator
    ///@param _approved True if operator is approved,False if approval is revoked

    function setPetOperatorForAll(address _operator, bool _approved) external;

    // @notice Get an aavegotchi lending details through an identifier
    // @dev Will throw if the lending does not exist
    // @param _listingId The identifier of the lending to query
    // @return listing_ A struct containing certain details about the lending like timeCreated etc
    // @return aavegotchiInfo_ A struct containing details about the aavegotchi
    function getGotchiLendingListingInfo(uint32 _listingId) external view returns (GotchiLending memory listing_, AavegotchiInfo memory aavegotchiInfo_);

    // @notice Get an ERC721 lending details through an identifier
    // @dev Will throw if the lending does not exist
    // @param _listingId The identifier of the lending to query
    // @return listing_ A struct containing certain details about the ERC721 lending like timeCreated etc
    function getLendingListingInfo(uint32 _listingId) external view returns (GotchiLending memory listing_);

    // @notice Get an aavegotchi lending details through an NFT
    // @dev Will throw if the lending does not exist
    // @param _erc721TokenId The identifier of the NFT associated with the lending
    // @return listing_ A struct containing certain details about the lending associated with an NFT of contract identifier `_erc721TokenId`
    function getGotchiLendingFromToken(uint32 _erc721TokenId) external view returns (GotchiLending memory listing_);

    function getGotchiLendingIdByToken(uint32 _erc721TokenId) external view returns (uint32);

    function isAavegotchiLent(uint32 _erc721TokenId) external view returns (bool);

    function isAavegotchiListed(uint32 _erc721TokenId) external view returns (bool);

    function aavegotchiClaimTime(uint256 _tokenId) external view returns (uint256 claimTime_);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

struct WithdrawVoucher {
    address recipient;
    address[] tokens;
    uint256[] amounts;
    uint256 userNonce;
}

struct SignatureData {
    bytes32 r;
    bytes32 s;
    uint8 v;
}

interface IOriumAavegotchiSplitter {
    function withdraw(WithdrawVoucher calldata voucher, SignatureData calldata signature)
        external;
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.9;

interface IRealmGettersAndSettersFacet {
    event ParcelAccessRightSet(uint256 _realmId, uint256 _actionRight, uint256 _accessRight);
    event ParcelWhitelistSet(uint256 _realmId, uint256 _actionRight, uint256 _whitelistId);

    function setParcelsAccessRightWithWhitelists(
        uint256[] calldata _realmIds,
        uint256[] calldata _actionRights,
        uint256[] calldata _accessRights,
        uint32[] calldata _whitelistIds
    ) external;

    function getParcelsAccessRights(uint256[] calldata _parcelIds, uint256[] calldata _actionRights) external view returns (uint256[] memory output_);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IGotchiLendingFacet } from "../interface/IGotchiLendingFacet.sol";
import { ILendingGetterAndSetterFacet } from "../interface/ILendingGetterAndSetterFacet.sol";
import { IOriumNftVault, NftState, INftVaultPlatform } from "../../base/interface/IOriumNftVault.sol";
import { IOriumFactory } from "../../base/interface/IOriumFactory.sol";
import { IRealmGettersAndSettersFacet } from "../interface/IRealmGettersAndSettersFacet.sol";
import { GotchiLending } from "../libraries/LibAavegotchiStorage.sol";
import { IOriumAavegotchiSplitter, WithdrawVoucher, SignatureData } from "../interface/IOriumAavegotchiSplitter.sol";
import { IScholarshipManager } from "../../base/interface/IScholarshipManager.sol";

library LibAavegotchiNftVaultExtension {
    function onlyScholarshipManager(address _factory) public view {
        require(
            msg.sender == address(IOriumFactory(_factory).getScholarshipManagerAddress()),
            "OriumNftVault:: Only scholarshipManager can call this function"
        );
    }

    function transferPendingGHSTBalance(IOriumFactory factory, address vault) public {
        IScholarshipManager _scholarshipManager = IScholarshipManager(
            factory.getScholarshipManagerAddress()
        );
        IERC20 _ghst = IERC20(factory.getAavegotchiGHSTAddress());
        if (address(_ghst) == address(0)) return;
        uint256 _ghstBalance = _ghst.balanceOf(vault);
        if (_ghstBalance <= 0) return;
        address _splitter = factory.getOriumAavegotchiSplitter();
        _ghst.transfer(_splitter, _ghstBalance);
        _scholarshipManager.onTransferredGHST(vault, _ghstBalance);
    }

    // Helpers
    function createValidAavegotchiListingStruct(
        uint256 _tokenId,
        uint96 _initialCost,
        uint32 _period,
        uint32 _whitelistId,
        address _nftVault,
        address _factory,
        address _thirdPartyAddress,
        address[] memory _alchemicaTokens,
        uint8[3] memory _revenueSplit
    ) public pure returns (IGotchiLendingFacet.AddGotchiListing memory _listings) {
        _listings = IGotchiLendingFacet.AddGotchiListing({
            tokenId: uint32(_tokenId),
            initialCost: _initialCost,
            period: _period,
            revenueSplit: _revenueSplit,
            originalOwner: _nftVault,
            thirdParty: _thirdPartyAddress,
            whitelistId: _whitelistId,
            revenueTokens: _alchemicaTokens
        });
    }

    function getAavegotchiListingHelpers(
        address _factory,
        address _nftVault,
        address _nftAddress,
        uint256 _tokenId
    ) public view returns (address, address[] memory, uint8[3] memory) {
        uint256 _platform = INftVaultPlatform(_nftVault).platform();
        address thirdPartyAddress = IOriumFactory(_factory).getOriumAavegotchiSplitter();
        address[] memory alchemicaTokens = IOriumFactory(_factory).getPlatformTokens(_platform);
        address _scholarshipManager = IOriumFactory(_factory).getScholarshipManagerAddress();

        uint256 _programId = IOriumNftVault(_nftVault).programOf(_nftAddress, _tokenId);
        uint256[] memory shares = IScholarshipManager(_scholarshipManager).sharesOf(_programId, 1);
        require(
            shares.length == IOriumFactory(_factory).getPlatformSharesLength(_platform)[0],
            "Orium: Invalid shares"
        );
        uint8[3] memory validShares = getValidRevenueSplit(shares, _factory);

        return (thirdPartyAddress, alchemicaTokens, validShares);
    }

    function getValidRevenueSplit(
        uint256[] memory shares,
        address _factory
    ) public view returns (uint8[3] memory _revenueSplit) {
        uint256 sharesLength = 4;
        require(shares.length == sharesLength, "Orium: Invalid shares");

        uint256 _totalShares = sumShares(shares);
        uint256 _oriumFee = IOriumFactory(_factory).oriumFee();

        require(_totalShares == 100 ether, "Orium: Invalid shares");

        uint256 _totalSharesWithoutOriumFee = _totalShares - _oriumFee;

        uint256[] memory _validShares = new uint256[](sharesLength + 1);

        for (uint256 i = 0; i < sharesLength; i++) {
            _validShares[i] = recalculateShare(shares[i], _totalSharesWithoutOriumFee);
        }

        _validShares[sharesLength] = _oriumFee;

        _revenueSplit = convertSharesToAavegotchi(_validShares);
    }

    function convertSharesToAavegotchi(
        uint256[] memory shares
    ) public pure returns (uint8[3] memory _revenueSplit) {
        _revenueSplit[0] = uint8(shares[0] / 1 ether);
        _revenueSplit[1] = uint8(shares[1] / 1 ether);
        _revenueSplit[2] = uint8((shares[2] + shares[3] + shares[4]) / 1 ether);

        uint8 _sum = sumAavegotchiShares(_revenueSplit);

        _revenueSplit[0] += 100 - _sum;
    }

    function sumShares(uint256[] memory shares) public pure returns (uint256 _sum) {
        for (uint256 i = 0; i < shares.length; i++) {
            _sum += shares[i];
        }
    }

    function sumAavegotchiShares(uint8[3] memory shares) public pure returns (uint8 _sum) {
        for (uint256 i = 0; i < shares.length; i++) {
            _sum += shares[i];
        }
    }

    function recalculateShare(
        uint256 _share,
        uint256 _totalSharesWithoutOriumFee
    ) public pure returns (uint256 _newShare) {
        _newShare = (_share * _totalSharesWithoutOriumFee) / 100 ether;
        _newShare = ceilDown(_newShare, 1 ether);
    }

    function ceilDown(uint256 _value, uint256 _ceil) internal pure returns (uint256 _result) {
        _result = _value - (_value % _ceil);
    }

    function isLendingClaimable(
        uint32 tokenId,
        address _rentalImplementation
    ) public view returns (bool) {
        GotchiLending memory lending = ILendingGetterAndSetterFacet(_rentalImplementation)
            .getGotchiLendingFromToken(tokenId);
        return (lending.timeAgreed + lending.period) < block.timestamp;
    }

    function validateCreateLandRental(
        uint256 _channellingAccessRight,
        uint256 _emptyReservoirAccessRight,
        uint32 _channelingWhitelistId,
        uint32 _emptyReservoirWhitelistId
    ) public pure {
        require(
            _channellingAccessRight != 0 && _emptyReservoirAccessRight != 0,
            "LibAavegotchiNftVault:: Wrong access right"
        );

        if (_emptyReservoirAccessRight == 2) {
            require(
                _emptyReservoirWhitelistId != 0,
                "LibAavegotchiNftVault:: Whitelist id cannot be 0"
            );
        }

        if (_channellingAccessRight == 2) {
            require(
                _channelingWhitelistId != 0,
                "LibAavegotchiNftVault:: Whitelist id cannot be 0"
            );
        }
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

uint256 constant EQUIPPED_WEARABLE_SLOTS = 16;
uint256 constant NUMERIC_TRAITS_NUM = 6;

// @notice Define what action gelato needs to perform with the lending
enum LendingAction {
    DO_NOTHING, // Don't do anything
    REMOVE, // Remove Nft from Scheduling
    LIST, // List NFT for rent
    CLAIM_AND_LIST // Claim and end current rent, and list NFT for rent again
}

struct NftLendingAction {
    uint32 tokenId;
    LendingAction action;
}

struct GotchiLending {
    address lender;
    uint96 initialCost;
    address borrower;
    uint32 listingId;
    uint32 erc721TokenId;
    uint32 whitelistId;
    address originalOwner;
    uint40 timeCreated;
    uint40 timeAgreed;
    bool canceled;
    bool completed;
    address thirdParty;
    uint8[3] revenueSplit;
    uint40 lastClaimed;
    uint32 period;
    address[] revenueTokens;
}

struct Dimensions {
    uint8 x;
    uint8 y;
    uint8 width;
    uint8 height;
}

struct ItemType {
    string name;
    string description;
    string author;
    int8[NUMERIC_TRAITS_NUM] traitModifiers;
    bool[EQUIPPED_WEARABLE_SLOTS] slotPositions;
    uint8[] allowedCollaterals;
    Dimensions dimensions;
    uint256 ghstPrice;
    uint256 maxQuantity;
    uint256 totalQuantity;
    uint32 svgId;
    uint8 rarityScoreModifier;
    bool canPurchaseWithGhst;
    uint16 minLevel;
    bool canBeTransferred;
    uint8 category;
    int16 kinshipBonus;
    uint32 experienceBonus;
}

struct ItemTypeIO {
    uint256 balance;
    uint256 itemId;
    ItemType itemType;
}

struct AavegotchiInfo {
    uint256 tokenId;
    string name;
    address owner;
    uint256 randomNumber;
    uint256 status;
    int16[NUMERIC_TRAITS_NUM] numericTraits;
    int16[NUMERIC_TRAITS_NUM] modifiedNumericTraits;
    uint16[EQUIPPED_WEARABLE_SLOTS] equippedWearables;
    address collateral;
    address escrow;
    uint256 stakedAmount;
    uint256 minimumStake;
    uint256 kinship;
    uint256 lastInteracted;
    uint256 experience;
    uint256 toNextLevel;
    uint256 usedSkillPoints;
    uint256 level;
    uint256 hauntId;
    uint256 baseRarityScore;
    uint256 modifiedRarityScore;
    bool locked;
    ItemTypeIO[] items;
}
struct LendingOperatorInputs {
    uint32 _tokenId;
    bool _isLendingOperator;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

interface IOriumFactory {
    function isTrustedNft(address _nft) external view returns (bool);

    function isPlatformTrustedNft(address _nft, uint256 _platform) external view returns (bool);

    function isNftVault(address _nftVault) external view returns (bool);

    function getPlatformNftType(uint256 _platform, address _nft) external view returns (uint256);

    function rentalImplementationOf(address _nftAddress) external view returns (address);

    function getOriumAavegotchiSplitter() external view returns (address);

    function oriumFee() external view returns (uint256);

    function getPlatformTokens(uint256 _platformId) external view returns (address[] memory);

    function getVaultInfo(
        address _nftVault
    ) external view returns (uint256 platform, address owner);

    function getScholarshipManagerAddress() external view returns (address);

    function getOriumAavegotchiPettingAddress() external view returns (address);

    function getAavegotchiDiamondAddress() external view returns (address);

    function isSupportedPlatform(uint256 _platform) external view returns (bool);

    function supportsRentalOffer(address _nftAddress) external view returns (bool);

    function getPlatformSharesLength(uint256 _platform) external view returns (uint256[] memory);

    function getAavegotchiGHSTAddress() external view returns (address);

    function getOriumSplitterFactory() external view returns (address);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

enum NftState {
    NOT_DEPOSITED,
    IDLE,
    LISTED,
    BORROWED,
    CLAIMABLE
}

interface IOriumNftVault {
    function initialize(
        address _owner,
        address _factory,
        address _scholarshipManager,
        uint256 _platform
    ) external;

    function getNftState(address _nft, uint256 tokenId) external view returns (NftState _nftState);

    function isPausedForListing(address _nftAddress, uint256 _tokenId) external view returns (bool);

    function setPausedForListings(
        address[] memory _nftAddresses,
        uint256[] memory _tokenIds,
        bool[] memory _isPauseds
    ) external;

    function withdrawNfts(address[] memory _nftAddresses, uint256[] memory _tokenIds) external;

    function maxRentalPeriodAllowedOf(
        address _nftAddress,
        uint256 _tokenId
    ) external view returns (uint256);

    function setMaxAllowedRentalPeriod(
        address[] memory _nftAddresses,
        uint256[] memory _tokenIds,
        uint256[] memory _maxAllowedPeriods
    ) external;

    function programOf(address _nftAddress, uint256 _tokenId) external view returns (uint256);
}

interface INftVaultPlatform {
    function platform() external view returns (uint256);

    function owner() external view returns (address);

    function createRentalOffer(uint256 _tokenId, address _nftAddress, bytes memory data) external;

    function cancelRentalOffer(uint256 _tokenId, address _nftAddress) external;

    function endRental(address _nftAddress, uint256 _tokenId) external;

    function endRentalAndRelist(address _nftAddress, uint256 _tokenId, bytes memory data) external;

    function claimTokensOfRentals(
        address[] memory _nftAddresses,
        uint256[] memory _tokenIds
    ) external;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

interface IScholarshipManager {
    function platformOf(uint256 _programId) external view returns (uint256);

    function isProgram(uint256 _programId) external view returns (bool);

    function onDelegatedScholarshipProgram(
        address _owner,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _programId,
        uint256 _maxAllowedPeriod
    ) external;

    function onUnDelegatedScholarshipProgram(
        address owner,
        address nftAddress,
        uint256 tokenId
    ) external;

    function onPausedNft(address _owner, address _nftAddress, uint256 _tokenId) external;

    function onUnPausedNft(address _owner, address _nftAddress, uint256 _tokenId) external;

    function sharesOf(
        uint256 _programId,
        uint256 _eventId
    ) external view returns (uint256[] memory);

    function programOf(address _nftAddress, uint256 _tokenId) external view returns (uint256);

    function onTransferredGHST(address _vault, uint256 _amount) external;

    function ownerOf(uint256 _programId) external view returns (address);

    function vaultOf(
        address _nftAddress,
        uint256 _tokenId
    ) external view returns (address _vaultAddress);

    function isNftPaused(address _nftAddress, uint256 _tokenId) external view returns (bool);

    function onRentalEnded(
        address nftAddress,
        uint256 tokenId,
        address vaultAddress,
        uint256 programId
    ) external;

    function onRentalOfferCancelled(
        address nftAddress,
        uint256 tokenId,
        address vaultAddress,
        uint256 programId
    ) external;
}