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

interface IOriumSplitter {
    function initialize(
        address _oriumTreasury,
        address _guildOwner,
        uint256 _scholarshipProgramId,
        address _factory,
        uint256 _platformId,
        address _scholarshipManager,
        address _vaultAddress,
        address _vaultOwner
    ) external;

    function getSharesWithOriumFee(
        uint256[] memory _shares
    ) external view returns (uint256[] memory _sharesWithOriumFee);

    function split() external;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

interface IOriumSplitterFactory {
    function deploySplitter(uint256 _programId, address _vaultAddress) external returns (address);

    function isValidSplitterAddress(address _splitter) external view returns (bool);

    function getPlatformSupportsSplitter(uint256 _platform) external view returns (bool);

    function splitterOf(uint256 _programId, address _vaultAddress) external view returns (address);

    function splittersOfVault(address _vaultAddress) external view returns (address[] memory);

    function splittersOfProgram(uint256 _programId) external view returns (address[] memory);
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

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

import { IOriumSplitter } from "../../base/interface/IOriumSplitter.sol";

interface IComethSplitter is IOriumSplitter {
    function createRentalOffer(
        uint256 _tokenId,
        address _nftAddress,
        uint64 _duration,
        uint256 _nonce,
        uint256 _feeAmount,
        uint256 _deadline,
        address _taker
    ) external;

    function cancelRentalOffer(uint256 _tokenId, address _nftAddress) external;

    function endRental(address _nftAddress, uint256 _tokenId) external;

    function endRentalAndRelist(
        address _nftAddress,
        uint256 _tokenId,
        uint64 _duration,
        uint256 _nonce,
        uint256 _feeAmount,
        uint256 _deadline,
        address _taker
    ) external;

    function unDelegateNft(address _nftAddress, uint256 _tokenId) external;

    function nonceOf(address _nftAddress, uint256 _tokenId) external view returns (uint256);

    function deadlineOf(uint256 _nonce) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title Rental Protocol
 *
 * @notice A rental can only begin when a `RentalOffer` has been created either on-chain (`preSignRentalOffer`)
 * or off-chain. When a rental is started (`rent`), a `LentNFT` and `BorrowedNFT` are minted and given
 * respectively to the lender and the tenant. A rental can be also sublet to a specific borrower, at the
 * choosing of the tenant.
 *
 *
 * Rental NFTs:
 * - `LentNFT`: anyone having one can reclaim the original NFT at the end of the rental
 * - `BorrowedNFT`: allowed the tenant to play the game and earn some rewards as if he owned the original NFT
 * - `SubLentNFT`: a sublender is given this NFT in order to reclaim the `BorrowedNFT` when the sublet ends
 */
interface IRentalProtocol {
    enum SignatureType {
        PRE_SIGNED,
        EIP_712,
        EIP_1271
    }
    struct Rental {
        uint256 end;
        uint256 lenderFee;
        uint256 sublenderFee;
    }
    struct RentalOffer {
        /// address of the user renting his NFTs
        address maker;
        /// address of the allowed tenant if private rental or `0x0` if public rental
        address taker;
        /// NFTs included in this rental offer
        NFT[] nfts;
        /// address of the ERC20 token for rental fees
        address feeToken;
        /// amount of the rental fee
        uint256 feeAmount;
        /// nonce
        uint256 nonce;
        /// until when the rental offer is valid
        uint256 deadline;
    }

    // guild -> manager -> vault -> splitter

    struct NFT {
        /// address of the contract of the NFT to rent
        address token;
        /// specific NFT to be rented
        uint256 tokenId;
        /// how long the rent should be
        uint64 duration;
        /// percentage of rewards for the lender, in basis points format
        uint16 basisPoints;
    }

    struct Fee {
        // fee collector
        address to;
        /// percentage of rewards for the lender or sublender, in basis points format
        uint256 basisPoints;
    }

    /**
     * @param nonce nonce of the rental offer
     * @param maker address of the user renting his NFTs
     * @param taker address of the allowed tenant if private rental or `0x0` if public rental
     * @param nfts details about each NFT included in the rental offer
     * @param feeToken address of the ERC20 token for rental fees
     * @param feeAmount amount of the upfront rental cost
     * @param deadline until when the rental offer is valid
     */
    event RentalOfferCreated(
        uint256 indexed nonce,
        address indexed maker,
        address taker,
        NFT[] nfts,
        address feeToken,
        uint256 feeAmount,
        uint256 deadline
    );
    /**
     * @param nonce nonce of the rental offer
     * @param maker address of the user renting his NFTs
     */
    event RentalOfferCancelled(uint256 indexed nonce, address indexed maker);

    /**
     * @param nonce nonce of the rental offer
     * @param lender address of the lender
     * @param tenant address of the tenant
     * @param token address of the contract of the NFT rented
     * @param tokenId tokenId of the rented NFT
     * @param duration how long the NFT is rented
     * @param basisPoints percentage of rewards for the lender, in basis points format
     * @param start when the rent begins
     * @param end when the rent ends
     */
    event RentalStarted(
        uint256 indexed nonce,
        address indexed lender,
        address indexed tenant,
        address token,
        uint256 tokenId,
        uint64 duration,
        uint16 basisPoints,
        uint256 start,
        uint256 end
    );
    /**
     * @param lender address of the lender
     * @param tenant address of the tenant
     * @param token address of the contract of the NFT rented
     * @param tokenId tokenId of the rented NFT
     */
    event RentalEnded(
        address indexed lender,
        address indexed tenant,
        address token,
        uint256 tokenId
    );

    /**
     * @param lender address of the lender
     * @param tenant address of the tenant
     * @param token address of the contract of the NFT rented
     * @param tokenId tokenId of the rented NFT
     * @param basisPoints percentage of rewards for the sublender, in basis points format
     */
    event SubletStarted(
        address indexed lender,
        address indexed tenant,
        address token,
        uint256 tokenId,
        uint16 basisPoints
    );
    /**
     * @param lender address of the lender
     * @param tenant address of the tenant
     * @param token address of the contract of the NFT rented
     * @param tokenId tokenId of the rented NFT
     */
    event SubletEnded(
        address indexed lender,
        address indexed tenant,
        address token,
        uint256 tokenId
    );

    /**
     * @param requester address of the first party (lender or tenant) requesting to end the rental prematurely
     * @param token address of the contract of the NFT rented
     * @param tokenId tokenId of the rented NFT
     */
    event RequestToEndRentalPrematurely(
        address indexed requester,
        address indexed token,
        uint256 indexed tokenId
    );

    /**
     * @notice Link `originalNFT` to `lentNFT`, `borrowedNFT` and `subLentNFT`.
     * @param originalNFT address of the contract of the NFT to rent
     * @param lentNFT address of the `LentNFT` contract associated to `originalNFT`
     * @param borrowedNFT address of the `BorrowedNFT` contract associated to `originalNFT`
     * @param subLentNFT address of the `SubLentNFT` contract associated to `originalNFT`
     */
    event AssociatedNFTs(
        address originalNFT,
        address lentNFT,
        address borrowedNFT,
        address subLentNFT
    );

    event FeesCollectorChanged(address feeCollector);
    event FeesBasisPointsChanged(uint16 basisPoints);

    /**
     * @notice Create a new on-chain rental offer.
     * @notice In order to create a private offer, specify the `taker` address, otherwise use the `0x0` address
     * @dev When using pre-signed order, pass `SignatureType.PRE_SIGNED` as the `signatureType` for `rent`
     * @param offer the rental offer to store on-chain
     */
    function preSignRentalOffer(RentalOffer calldata offer) external;

    /**
     * @notice Cancel an on-chain rental offer.
     * @param nonce the nonce of the rental offer to cancel
     */
    function cancelRentalOffer(uint256 nonce) external;

    /**
     * @notice Start a rental between the `offer.maker` and `offer.taker`.
     * @param offer the rental offer
     * @param signatureType the signature type
     * @param signature optional signature when using `SignatureType.EIP_712` or `SignatureType.EIP_1271`
     * @dev `SignatureType.EIP_1271` is not yet supported, call will revert
     */
    function rent(
        RentalOffer calldata offer,
        SignatureType signatureType,
        bytes calldata signature
    ) external;

    /**
     * @notice End a rental when its duration is over.
     * @dev A rental can only be ended by the lender or the tenant.
     *      If there is a sublet it will be automatically ended.
     * @param token address of the contract of the NFT rented
     * @param tokenId tokenId of the rented NFT
     */
    function endRental(address token, uint256 tokenId) external;

    /**
     * @notice End a rental *before* its duration is over.
     *         Doing so need both the lender and the tenant to call this function.
     * @dev If there is an ongoing sublet the call will revert.
     * @param token address of the contract of the NFT rented
     * @param tokenId tokenId of the rented NFT
     */
    function endRentalPrematurely(address token, uint256 tokenId) external;

    /**
     * @notice Sublet a rental.
     * @dev Only a single sublet depth is allowed.
     * @param token address of the contract of the NFT rented
     * @param tokenId tokenId of the rented NFT
     * @param subtenant address of whom the sublet is done for
     * @param basisPoints how many basis points the tenant keeps
     */
    function sublet(address token, uint256 tokenId, address subtenant, uint16 basisPoints) external;

    /**
     * @notice End a sublet. Can be called by the tenant / sublender at any time.
     * @param token address of the contract of the NFT rented
     * @param tokenId tokenId of the rented NFT
     */
    function endSublet(address token, uint256 tokenId) external;

    /**
     * Fees table for a given `token` and `tokenId`.
     *
     * `pencentage` is not based on the rewards to be distributed, but the what these
     * specific users keeps for themselves.
     * If lender keeps 30% and tenant keeps 20%, the 20% are 20% of the remaining 70%.
     * This is stored as `3000` and `2000` and maths should be done accordingly at
     * rewarding time.
     *
     * @param token address of the contract of the NFT rented
     * @param tokenId tokenId of the rented NFT
     * @return fees table
     */
    function getFeesTable(address token, uint256 tokenId) external view returns (Fee[] memory);

    /**
     * @notice Set the address which will earn protocol fees.
     * @param feesCollector address collecting protocol fees
     */
    function setFeesCollector(address feesCollector) external;

    /**
     * @notice Set the protocol fee percentage as basis points.
     * @param basisPoints percentage of the protocol fee
     */
    function setFeesBasisPoints(uint16 basisPoints) external;

    function invalidNonce(address maker, uint256 nonce) external view returns (bool);

    function rentals(address token, uint256 tokenId) external view returns (Rental memory);

    function endRentalPrematurelyRequests(
        address token,
        uint256 tokenId
    ) external view returns (address);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

import { IOriumNftVault, NftState, INftVaultPlatform } from "../../base/interface/IOriumNftVault.sol";
import { IOriumFactory } from "../../base/interface/IOriumFactory.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IRentalProtocol } from "../interface/IRentalProtocol.sol";
import { IScholarshipManager } from "../../base/interface/IScholarshipManager.sol";
import { IComethSplitter } from "../interface/IComethSplitter.sol";
import { IOriumSplitterFactory } from "../../base/interface/IOriumSplitterFactory.sol";

library LibComethNftVault {
    function onlyScholarshipManager(address _factory) public view {
        require(
            msg.sender == address(IOriumFactory(_factory).getScholarshipManagerAddress()),
            "OriumNftVault:: Only scholarshipManager can call this function"
        );
    }

    /**
     * @notice Function to create a rental offer
     * @dev This function is called by the Orium Scholarships Manager
     * @param _tokenId uint256 id of the NFT
     * @param _nftAddress address of the NFT contract
     * @param data bytes data to be passed to the NFT contract
     */
    function createRentalOffer(
        uint256 _tokenId,
        address _nftAddress,
        bytes memory data,
        address _factory,
        address _scholarshipManager,
        address _vault
    ) external {
        onlyScholarshipManager(_factory);
        require(
            getNftState(_nftAddress, _tokenId, _factory, _scholarshipManager) == NftState.IDLE,
            "ComethNftVault: NFT is not IDLE"
        );
        
        (
            uint64 _duration,
            uint256 _nonce,
            uint256 _feeAmount,
            uint256 _deadline,
            address _taker
        ) = abi.decode(data, (uint64, uint256, uint256, uint256, address));

        validateDurationAndDeadline(_duration, _deadline, _vault, _nftAddress, _tokenId);

        address _guildSplitter = getGuildSplitterOfNft(
            _nftAddress,
            _tokenId,
            _factory,
            _scholarshipManager
        );
        IComethSplitter(_guildSplitter).createRentalOffer(
            _tokenId,
            _nftAddress,
            _duration,
            _nonce,
            _feeAmount,
            _deadline,
            _taker
        );
    }

    /**
     * @notice Function to cancel a rental offer
     * @dev This function is called by the Orium Scholarships Manager
     * @param _tokenId uint256 id of the NFT
     * @param _nftAddress address of the NFT contract
     */
    function cancelRentalOffer(
        uint256 _tokenId,
        address _nftAddress,
        address _factory,
        address _scholarshipManager
    ) external {
        onlyScholarshipManager(_factory);
        // This is needed to not allow to cancel a expired rental offer
        require(
            getNftState(_nftAddress, _tokenId, _factory, _scholarshipManager) == NftState.LISTED,
            "ComethNftVault: NFT is not LISTED"
        );
        address _guildSplitter = getGuildSplitterOfNft(
            _nftAddress,
            _tokenId,
            _factory,
            _scholarshipManager
        );
        IComethSplitter(_guildSplitter).cancelRentalOffer(_tokenId, _nftAddress);
    }

    /**
     * @notice Function to end a rental
     * @dev This function is called by the Orium Scholarships Manager
     * @param _nftAddress address of the NFT contract
     * @param _tokenId uint256 id of the NFT
     */
    function endRental(
        address _nftAddress,
        uint256 _tokenId,
        address _factory,
        address _scholarshipManager
    ) external {
        onlyScholarshipManager(_factory);
        address _guildSplitter = getGuildSplitterOfNft(
            _nftAddress,
            _tokenId,
            _factory,
            _scholarshipManager
        );
        IComethSplitter(_guildSplitter).endRental(_nftAddress, _tokenId);
    }

    /**
     * @notice Function to end rental and relist the NFT
     * @dev This function is called by the Orium Scholarships Manager
     * @param _nftAddress address of the NFT contract
     * @param _tokenId uint256 id of the NFT
     * @param data bytes data to be passed to the NFT contract
     */
    function endRentalAndRelist(
        address _nftAddress,
        uint256 _tokenId,
        bytes memory data,
        address _factory,
        address _scholarshipManager,
        address _vault
    ) external {
        onlyScholarshipManager(_factory);
        (
            uint64 _duration,
            uint256 _nonce,
            uint256 _feeAmount,
            uint256 _deadline,
            address _taker
        ) = abi.decode(data, (uint64, uint256, uint256, uint256, address));

        validateDurationAndDeadline(_duration, _deadline, _vault, _nftAddress, _tokenId);

        address _guildSplitter = getGuildSplitterOfNft(
            _nftAddress,
            _tokenId,
            _factory,
            _scholarshipManager
        );
        IComethSplitter(_guildSplitter).endRentalAndRelist(
            _nftAddress,
            _tokenId,
            _duration,
            _nonce,
            _feeAmount,
            _deadline,
            _taker
        );
    }

    function getNftState(
        address _nftAddress,
        uint256 _tokenId,
        address _factory,
        address _scholarshipManager
    ) public view returns (NftState) {
        address _nftOwner = IERC721(_nftAddress).ownerOf(_tokenId);
        if (_nftOwner == address(this)) {
            return NftState.IDLE;
        }

        address _rentalImplementation = IOriumFactory(_factory).rentalImplementationOf(_nftAddress);
        if (_nftOwner == _rentalImplementation) {
            uint256 _end = IRentalProtocol(_rentalImplementation)
                .rentals(_nftAddress, _tokenId)
                .end;
            if (_end > block.timestamp) {
                address requester = IRentalProtocol(_rentalImplementation)
                    .endRentalPrematurelyRequests(_nftAddress, _tokenId);
                if (requester != address(0)) return NftState.CLAIMABLE;
                else return NftState.BORROWED;
            } else {
                return NftState.CLAIMABLE;
            }
        }

        address _guildSplitter = getGuildSplitterOfNft(
            _nftAddress,
            _tokenId,
            _factory,
            _scholarshipManager
        );
        if (_nftOwner == _guildSplitter) {
            uint256 _nonce = IComethSplitter(_guildSplitter).nonceOf(_nftAddress, _tokenId);
            bool _isInvalidNonce = IRentalProtocol(_rentalImplementation).invalidNonce(
                _guildSplitter,
                _nonce
            );
            if (_isInvalidNonce) {
                return NftState.IDLE;
            } else {
                uint256 _deadline = IComethSplitter(_guildSplitter).deadlineOf(_nonce);
                if (_deadline > block.timestamp) {
                    return NftState.LISTED;
                } else {
                    return NftState.IDLE;
                }
            }
        } else {
            return NftState.NOT_DEPOSITED;
        }
    }

    function getGuildSplitterOfNft(
        address _nftAddress,
        uint256 _tokenId,
        address _factory,
        address _scholarshipManager
    ) public view returns (address _guildSplitter) {
        uint256 _programId = IScholarshipManager(_scholarshipManager).programOf(
            _nftAddress,
            _tokenId
        );
        _guildSplitter = getGuildSplitterOfProgram(_programId, _factory);
    }

    function getGuildSplitterOfProgram(
        uint256 _programId,
        address _factory
    ) public view returns (address _guildSplitter) {
        address _splitterFactory = IOriumFactory(address(_factory)).getOriumSplitterFactory();

        _guildSplitter = IOriumSplitterFactory(_splitterFactory).splitterOf(
            _programId,
            address(this)
        );
    }

    function validateDurationAndDeadline(
        uint256 _duration,
        uint256 _deadline,
        address _vault,
        address _nftAddress,
        uint256 _tokenId
    ) public view {
        require(
            _duration <= IOriumNftVault(_vault).maxRentalPeriodAllowedOf(_nftAddress, _tokenId),
            "ComethNftVault: Rental period exceeds max allowed"
        );
        require(_deadline >= block.timestamp, "ComethNftVault: Deadline is in the past");
    }

     function claimTokensOfRentals(
        address[] memory _nftAddresses,
        uint256[] memory _tokenIds,
        address _factory,
        address _scholarshipManager
    ) public {
        require(
            _nftAddresses.length == _tokenIds.length,
            "LibComethNftVault:: Arrays must be equal"
        );
        address[] memory _guildSplitters = getUniqueSplitters(_nftAddresses, _tokenIds, _factory, _scholarshipManager);

        for (uint256 i = 0; i < _guildSplitters.length; i++) {
            IComethSplitter(_guildSplitters[i]).split();
        }
    }

    function validateAndFetchSplitter(
        address _nftAddress,
        uint256 _tokenId,
        address _factory,
        address _scholarshipManager
    ) public view returns (address _splitter) {
        uint256 nftTypeId = IOriumFactory(_factory).getPlatformNftType(
            INftVaultPlatform(address(this)).platform(),
            _nftAddress
        );
        require(nftTypeId != 0, "LibAavegotchiNftVault:: NFT is not trusted");
    
        uint256 _programId = IScholarshipManager(_scholarshipManager).programOf(
            _nftAddress,
            _tokenId
        );
        require(_programId != 0, "LibComethNftVault:: NFT is not delegated to a program");

        _splitter = getGuildSplitterOfProgram(_programId, _factory);
    }

    function getUniqueSplitters(
        address[] memory _nftAddresses,
        uint256[] memory _tokenIds,
        address _factory,
        address _scholarshipManager
    ) public view returns (address[] memory _uniqueSplitters) {

        _uniqueSplitters = new address[](_nftAddresses.length);
        _uniqueSplitters[0] = validateAndFetchSplitter(_nftAddresses[0], _tokenIds[0], _factory, _scholarshipManager);
        uint256 _uniqueSplittersLength = 1;

        for (uint256 i = 1; i < _nftAddresses.length; i++) {
            bool _isDuplicate = false;
            address _splitter = validateAndFetchSplitter(_nftAddresses[i], _tokenIds[i], _factory, _scholarshipManager);

            for (uint256 j = 0; j < _uniqueSplittersLength; j++) {
                if (_splitter == _uniqueSplitters[j]) {
                    _isDuplicate = true;
                    break;
                }
            }
            if (!_isDuplicate) {
                _uniqueSplitters[_uniqueSplittersLength] = _splitter;
                _uniqueSplittersLength++;
            }
        }

        assembly {
            // resize the array to the correct size (truncate the trailing zeros)
            mstore(_uniqueSplitters, _uniqueSplittersLength)
        }
    }
}