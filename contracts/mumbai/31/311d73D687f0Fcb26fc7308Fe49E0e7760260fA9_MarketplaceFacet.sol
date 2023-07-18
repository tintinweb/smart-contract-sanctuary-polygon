// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "openzeppelin4/token/ERC721/IERC721.sol";
import "openzeppelin4/token/ERC20/IERC20.sol";
import "openzeppelin4/utils/structs/EnumerableSet.sol";
import "../interfaces/IKreatorhoodERC721.sol";
import "../interfaces/IAccessControl.sol";
import "../interfaces/IMetaTransaction.sol";
import "./../utils/ContextMixin.sol";
import { LibStructStorage as StructStorage } from "./../libraries/LibStructStorage.sol";
import { LibMarketplaceStorage as Storage } from "../libraries/LibMarketplaceStorage.sol";

abstract contract MarketplaceBase is ContextMixin {
    using EnumerableSet for EnumerableSet.AddressSet;

    function verifyMintDataSignature(StructStorage.MintData[] calldata mints, bytes calldata signature) internal view {
        (bool valid, address signer) = IMetaTransaction(address(this)).tryRecoverMintDataSigner(mints, signature);

        if (!valid) revert StructStorage.INVALID_SIGNATURE();
        if (!IAccessControl(address(this)).hasRole(StructStorage.OPERATOR_ROLE, signer))
            revert StructStorage.MINTS_SIGNATURE(signature);
    }

    function verifySplits(StructStorage.Splits calldata splitsInfo, bytes32 tradeDataHash) internal {
        Storage.MarketplaceStorage storage data = Storage.getStorage();

        if (splitsInfo.actionExpiration <= block.timestamp) revert StructStorage.SPLITS_EXPIRED(splitsInfo.nonce);
        if (data.splitsNonces[splitsInfo.nonce]) revert StructStorage.SPLITS_NONCE_INVALID(splitsInfo.nonce);
        data.splitsNonces[splitsInfo.nonce] = true;

        (bool valid, address signer) = IMetaTransaction(address(this)).tryRecoverSplitsSigner(
            splitsInfo,
            tradeDataHash
        );

        if (!valid) revert StructStorage.INVALID_SIGNATURE();
        if (!IAccessControl(address(this)).hasRole(StructStorage.OPERATOR_ROLE, signer))
            revert StructStorage.SPLITS_SIGNATURE(splitsInfo.nonce);
    }

    function verifyExternalId(uint256 externalId) internal {
        Storage.MarketplaceStorage storage data = Storage.getStorage();

        if (data.externalIds[externalId]) revert StructStorage.EXTERNAL_ID_USED(externalId);
        data.externalIds[externalId] = true;
    }

    function isAcceptedToken(address token) internal view returns (bool) {
        Storage.MarketplaceStorage storage data = Storage.getStorage();

        return data.acceptedTokens.contains(token);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "openzeppelin4/utils/Strings.sol";
import "openzeppelin4/utils/Context.sol";
import "openzeppelin4/utils/structs/EnumerableSet.sol";
import "openzeppelin4/token/ERC20/IERC20.sol";
import "./MarketplaceBase.sol";
import "./../interfaces/IMarketplace.sol";
import "./../interfaces/IAccessControl.sol";
import "./../interfaces/IKreatorhoodERC721.sol";
import "./../interfaces/IMetaTransaction.sol";
import "./../interfaces/IFundsAdmin.sol";
import "./../utils/FacetInitializable.sol";
import { LibStructStorage as StructStorage } from "./../libraries/LibStructStorage.sol";
import { LibMarketplaceStorage as Storage } from "./../libraries/LibMarketplaceStorage.sol";

contract MarketplaceFacet is IMarketplace, MarketplaceBase, FacetInitializable {
    using EnumerableSet for EnumerableSet.AddressSet;

    event PrimaryMarketBuy(uint256 indexed externalId, uint256[] firstTokenIds);

    event PrimaryMarketBuyFiat(uint256 indexed externalId, uint256[] firstTokenIds);

    event Buy(uint256 indexed externalId, uint256[] firstTokenIds);

    event BuyFiat(uint256 indexed externalId, uint256[] firstTokenIds);

    event SecondaryMarketBuy(uint256 indexed externalId);

    event SecondaryMarketBuyFiat(uint256 indexed externalId);

    event CancelSell(uint256 indexed sellNonce);

    function initialize(address[] calldata _acceptedTokens) external initializer(Storage.getStorage().inited) {
        Storage.MarketplaceStorage storage data = Storage.getStorage();

        for (uint256 i; i < _acceptedTokens.length; i++) {
            data.acceptedTokens.add(_acceptedTokens[i]);
        }
    }

    function buyNew(
        uint256 externalId,
        bytes calldata mintsSignature,
        StructStorage.Splits calldata splitsInfo,
        StructStorage.MintData[] calldata mints
    ) external payable override {
        verifyExternalId(externalId);
        if (!isAcceptedToken(splitsInfo.token)) revert StructStorage.PAYMENT_TOKEN_NOT_ACCEPTED(splitsInfo.token);

        verifySplits(splitsInfo, keccak256(mintsSignature));
        address payable buyer = _msgSender();

        IFundsAdmin(address(this)).distributeSplits(buyer, splitsInfo);
        emit PrimaryMarketBuy(externalId, createNFTs(buyer, mintsSignature, mints));
    }

    function buyNewFiat(
        address buyer,
        uint256 externalId,
        bytes calldata mintsSignature,
        StructStorage.MintData[] calldata mints
    ) external override only(LibStructStorage.OPERATOR_ROLE) {
        verifyExternalId(externalId);
        emit PrimaryMarketBuyFiat(externalId, createNFTs(buyer, mintsSignature, mints));
    }

    function createNFTs(
        address buyer,
        bytes calldata mintsSignature,
        StructStorage.MintData[] calldata mints
    ) private returns (uint256[] memory) {
        verifyMintDataSignature(mints, mintsSignature);
        uint256 mintsNo = mints.length;
        uint256[] memory firstIndexes = new uint256[](mintsNo);
        for (uint i = 0; i < mintsNo; ) {
            firstIndexes[i] = mintNFT(mints[i], buyer);
            unchecked {
                ++i;
            }
        }
        return firstIndexes;
    }

    function mintNFT(StructStorage.MintData memory mintData, address buyer) private returns (uint) {
        Storage.MarketplaceStorage storage data = Storage.getStorage();
        uint256 totalNFTs;
        uint256 dropsNo = mintData.drops.length;
        for (uint i = 0; i < dropsNo; ) {
            totalNFTs += mintData.drops[i].mintEditions;
            unchecked {
                ++i;
            }
        }

        IKreatorhoodERC721.MintInfo[] memory mintInfos = new IKreatorhoodERC721.MintInfo[](totalNFTs);
        IKreatorhoodERC721.DropInfo[] memory dropInfos = new IKreatorhoodERC721.DropInfo[](totalNFTs);
        IKreatorhoodERC721.CreatorInfo[] memory creatorInfos = new IKreatorhoodERC721.CreatorInfo[](totalNFTs);
        uint nftsMinted = 0;
        for (uint i = 0; i < dropsNo; ) {
            uint256 firstNewEditionId = data.editionsMinted[mintData.drops[i].dropId] + 1;
            // firstNewEditionId starts from 1 more than the #of minted editions so we subtract that from the sum
            if (firstNewEditionId + mintData.drops[i].mintEditions - 1 > mintData.drops[i].maxEditions)
                revert LibStructStorage.EDITION_LIMIT(mintData.drops[i].dropId);
            for (uint e = firstNewEditionId; e < firstNewEditionId + mintData.drops[i].mintEditions; ) {
                mintInfos[nftsMinted] = IKreatorhoodERC721.MintInfo(
                    mintData.drops[i].tokenUri,
                    // the tokenIds array starts at 0, but we're counting editions from editionId
                    getUtilityUri(mintData.drops[i].utilityIds[e - firstNewEditionId])
                );
                dropInfos[nftsMinted] = IKreatorhoodERC721.DropInfo(mintData.drops[i].dropId, e);
                creatorInfos[nftsMinted] = IKreatorhoodERC721.CreatorInfo(
                    mintData.drops[i].creatorAddress,
                    mintData.drops[i].royaltiesPercent
                );
                unchecked {
                    ++e;
                    ++nftsMinted;
                }
            }
            data.editionsMinted[mintData.drops[i].dropId] = firstNewEditionId + mintData.drops[i].mintEditions - 1;
            unchecked {
                ++i;
            }
        }

        IKreatorhoodERC721(mintData.nftAddress).batchMint(
            buyer,
            totalNFTs,
            mintInfos,
            dropInfos,
            creatorInfos,
            new uint256[](totalNFTs),
            "0x"
        );
        return IKreatorhoodERC721(mintData.nftAddress).totalSupply() - nftsMinted + 1;
    }

    function getUtilityUri(string memory utilityId) internal view returns (string memory utilityUri) {
        if (bytes(utilityId).length == 0) {
            utilityUri = utilityId;
        } else {
            Storage.MarketplaceStorage storage data = Storage.getStorage();
            utilityUri = string(abi.encodePacked(data.baseUtilityUri, utilityId));
        }
    }

    function buyListed(
        StructStorage.Splits calldata splitsInfo,
        uint256 externalId,
        StructStorage.SellDTO calldata sellDTO
    ) external payable override {
        if (!isAcceptedToken(splitsInfo.token)) revert StructStorage.PAYMENT_TOKEN_NOT_ACCEPTED(splitsInfo.token);
        verifyExternalId(externalId);
        IMetaTransaction(address(this)).tryRecoverMerkleProofOrSellDataSigner(sellDTO);

        uint256 length = sellDTO.sells.length;
        uint256[] memory sellNonces = new uint256[](length);
        Storage.MarketplaceStorage storage data = Storage.getStorage();

        for (uint256 i; i < length; ) {
            if (sellDTO.sells[i].expirationDate <= block.timestamp)
                revert StructStorage.SELL_DATA_EXPIRED(sellDTO.sells[i].sellNonce);
            if (data.sellNonces[sellDTO.sells[i].sellNonce])
                revert StructStorage.SELL_NONCE_INVALID(sellDTO.sells[i].sellNonce);
            data.sellNonces[sellDTO.sells[i].sellNonce] = true;
            sellNonces[i] = sellDTO.sells[i].sellNonce;
            IERC721(sellDTO.sells[i].nftAddress).safeTransferFrom(
                sellDTO.sells[i].seller,
                _msgSender(),
                sellDTO.sells[i].tokenId
            );
            unchecked {
                ++i;
            }
        }
        verifySplits(splitsInfo, keccak256(abi.encodePacked(sellNonces)));

        IFundsAdmin(address(this)).distributeSplits(_msgSender(), splitsInfo);
        emit SecondaryMarketBuy(externalId);
    }

    function buyListedFiat(
        address buyer,
        uint256 externalId,
        StructStorage.SellDTO calldata sellDTO
    ) external override only(StructStorage.OPERATOR_ROLE) {
        verifyExternalId(externalId);
        IMetaTransaction(address(this)).tryRecoverMerkleProofOrSellDataSigner(sellDTO);
        uint256 length = sellDTO.sells.length;
        Storage.MarketplaceStorage storage data = Storage.getStorage();

        for (uint256 i; i < length; ) {
            if (sellDTO.sells[i].expirationDate <= block.timestamp)
                revert StructStorage.SELL_DATA_EXPIRED(sellDTO.sells[i].sellNonce);
            if (data.sellNonces[sellDTO.sells[i].sellNonce])
                revert StructStorage.SELL_NONCE_INVALID(sellDTO.sells[i].sellNonce);
            data.sellNonces[sellDTO.sells[i].sellNonce] = true;
            IERC721(sellDTO.sells[i].nftAddress).safeTransferFrom(
                sellDTO.sells[i].seller,
                buyer,
                sellDTO.sells[i].tokenId
            );
            unchecked {
                ++i;
            }
        }

        emit SecondaryMarketBuyFiat(externalId);
    }

    function buy(
        uint256 externalId,
        bytes calldata mintsSignature,
        StructStorage.Splits calldata splitsInfo,
        StructStorage.MintData[] calldata mints,
        StructStorage.SellDTO calldata sellDTO
    ) external payable override {
        {
            verifyExternalId(externalId);
            if (!isAcceptedToken(splitsInfo.token)) revert StructStorage.PAYMENT_TOKEN_NOT_ACCEPTED(splitsInfo.token);
            IMetaTransaction(address(this)).tryRecoverMerkleProofOrSellDataSigner(sellDTO);
        }
        uint256 length = sellDTO.sells.length;
        uint256[] memory sellNonces = new uint256[](length);
        Storage.MarketplaceStorage storage data = Storage.getStorage();
        {
            for (uint256 i; i < length; ) {
                if (sellDTO.sells[i].expirationDate <= block.timestamp)
                    revert StructStorage.SELL_DATA_EXPIRED(sellDTO.sells[i].sellNonce);
                if (data.sellNonces[sellDTO.sells[i].sellNonce])
                    revert StructStorage.SELL_NONCE_INVALID(sellDTO.sells[i].sellNonce);
                data.sellNonces[sellDTO.sells[i].sellNonce] = true;
                sellNonces[i] = sellDTO.sells[i].sellNonce;
                IERC721(sellDTO.sells[i].nftAddress).safeTransferFrom(
                    sellDTO.sells[i].seller,
                    _msgSender(),
                    sellDTO.sells[i].tokenId
                );
                unchecked {
                    ++i;
                }
            }
            verifySplits(splitsInfo, keccak256(abi.encodePacked(mintsSignature, sellNonces)));
        }

        address payable buyer = _msgSender();
        IFundsAdmin(address(this)).distributeSplits(buyer, splitsInfo);
        emit Buy(externalId, createNFTs(buyer, mintsSignature, mints));
    }

    function buyFiat(
        address buyer,
        uint256 externalId,
        bytes calldata mintsSignature,
        StructStorage.MintData[] calldata mints,
        StructStorage.SellDTO calldata sellDTO
    ) external override {
        {
            verifyExternalId(externalId);
            IMetaTransaction(address(this)).tryRecoverMerkleProofOrSellDataSigner(sellDTO);
        }

        uint256 length = sellDTO.sells.length;
        Storage.MarketplaceStorage storage data = Storage.getStorage();
        {
            for (uint256 i; i < length; ) {
                if (sellDTO.sells[i].expirationDate <= block.timestamp)
                    revert StructStorage.SELL_DATA_EXPIRED(sellDTO.sells[i].sellNonce);
                if (data.sellNonces[sellDTO.sells[i].sellNonce])
                    revert StructStorage.SELL_NONCE_INVALID(sellDTO.sells[i].sellNonce);
                data.sellNonces[sellDTO.sells[i].sellNonce] = true;

                IERC721(sellDTO.sells[i].nftAddress).safeTransferFrom(
                    sellDTO.sells[i].seller,
                    buyer,
                    sellDTO.sells[i].tokenId
                );
                unchecked {
                    ++i;
                }
            }
        }

        emit BuyFiat(externalId, createNFTs(buyer, mintsSignature, mints));
    }

    function cancelSell(StructStorage.SellData calldata sellData) external override {
        Storage.MarketplaceStorage storage data = Storage.getStorage();
        if (sellData.seller != _msgSender() || IERC721(sellData.nftAddress).ownerOf(sellData.tokenId) != _msgSender())
            revert StructStorage.CALLER_NOT_OWNER_OR_SELLER(sellData.sellNonce);

        if (data.sellNonces[sellData.sellNonce]) revert StructStorage.SELL_NONCE_ALREADY_CANCELED(sellData.sellNonce);
        data.splitsNonces[sellData.sellNonce] = true;

        emit CancelSell(sellData.sellNonce);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IAccessControl {
    function initializeAccessControl(address fundsAdmin) external;

    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    function setDiamondOwner(address newOwner) external;

    function getDiamondOwner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./../libraries/LibStructStorage.sol";

interface IFundsAdmin {
    function initializeFundsAdmin(uint _referenceBlockNumber, uint _blocksPerDay) external;

    function distributeSplits(address buyer, LibStructStorage.Splits memory splitsInfo) external;

    function withdrawPlatformFees(address withdrawer, address token, uint256 amount) external;

    function referenceBlockNumber() external view returns (uint);

    function blocksPerDay() external view returns (uint);

    function setReferenceBlockNumber(uint _referenceBlockNumber) external;

    function setBlocksPerDay(uint _blocksPerDay) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKreatorhoodERC721 {
    struct DropInfo {
        uint256 dropId;
        uint256 editionId;
    }

    struct CreatorInfo {
        address creator;
        uint16 royalties;
    }

    struct MintInfo {
        string tokenUri;
        string utilityUri;
    }

    function totalSupply() external view returns (uint256);

    function batchMint(
        address to,
        uint256 amount,
        MintInfo[] calldata mintInfos,
        DropInfo[] calldata dropInfos_,
        CreatorInfo[] calldata creatorInfos_,
        uint256[] calldata lockTimes_,
        bytes memory _data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { LibStructStorage as StructStorage } from "../libraries/LibStructStorage.sol";

interface IMarketplace {
    function initialize(address[] calldata _acceptedTokens) external;

    function buyNew(
        uint256 externalId,
        bytes calldata mintsSignature,
        StructStorage.Splits calldata splitsInfo,
        StructStorage.MintData[] calldata mints
    ) external payable;

    function buyNewFiat(
        address buyer,
        uint256 externalId,
        bytes calldata mintsSignature,
        StructStorage.MintData[] calldata mints
    ) external;

    function buyListed(
        StructStorage.Splits calldata splitsInfo,
        uint256 externalId,
        StructStorage.SellDTO calldata sellDTO
    ) external payable;

    function buyListedFiat(address buyer, uint256 externalId, StructStorage.SellDTO calldata sellDTO) external;

    function buy(
        uint256 externalId,
        bytes calldata mintsSignature,
        StructStorage.Splits calldata splitsInfo,
        StructStorage.MintData[] calldata mints,
        StructStorage.SellDTO calldata sellDTO
    ) external payable;

    function buyFiat(
        address buyer,
        uint256 externalId,
        bytes calldata mintsSignature,
        StructStorage.MintData[] calldata mints,
        StructStorage.SellDTO calldata sellDTO
    ) external;

    function cancelSell(StructStorage.SellData calldata sellData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { LibStructStorage as StructStorage } from "./../libraries/LibStructStorage.sol";

interface IMetaTransaction {
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function initializeMetaTransaction() external;

    function tryRecoverSplitsSigner(
        StructStorage.Splits calldata splits,
        bytes32 tradeDataHash
    ) external view returns (bool valid, address signer);

    function tryRecoverMintDataSigner(
        StructStorage.MintData[] calldata dropData,
        bytes calldata mintsSignature
    ) external view returns (bool valid, address signer);

    function tryRecoverMerkleProofOrSellDataSigner(StructStorage.SellDTO calldata sellDTO) external view;

    function executeMetaTransaction(
        address userAddress,
        bytes calldata functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external payable returns (bytes memory);

    function getNonce(address user) external view returns (uint256 nonce);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "openzeppelin4/utils/structs/EnumerableSet.sol";
import "./../libraries/LibStructStorage.sol";

library LibMarketplaceStorage {
    using EnumerableSet for EnumerableSet.AddressSet;
    bytes32 public constant MARKETPLACE_STORAGE_SLOT = keccak256("KTHD.MARKETPLACE.STORAGE");

    struct MarketplaceStorage {
        LibStructStorage.InitFlag inited;
        // Mapping used to ensure that a payments payload is used only once
        mapping(uint256 => bool) splitsNonces;
        // Mapping used to ensure that a sell payload is used only once
        mapping(uint256 => bool) sellNonces;
        // Backend number used for processing logs efficiently
        mapping(uint256 => bool) externalIds;
        // Mapping used for limiting the edition number for a drop (dropId => number of editions minted
        mapping(uint256 => uint) editionsMinted;
        // Set used for accepted payment tokens
        EnumerableSet.AddressSet acceptedTokens;
        // String used for computing utility URI for the NFTs with utility associated
        string baseUtilityUri;
        // Address used for dummy implementation used for Etherscan visibility of the Diamond
        address dummyImplementation;
    }

    function getStorage() external pure returns (MarketplaceStorage storage storageStruct) {
        bytes32 position = MARKETPLACE_STORAGE_SLOT;
        assembly {
            storageStruct.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library LibStructStorage {
    //encoded roles
    bytes32 internal constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 internal constant FUNDS_ADMIN_ROLE = keccak256("FUNDS_ADMIN_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    //numeric constants
    uint256 internal constant MAX_CALLDATA_PROOF_LENGTH = 10;

    //general
    error INVALID_SIGNATURE(); //0xa3402a38
    error EXTERNAL_ID_USED(uint256 externalId); //0xcf1823bf
    error PAYMENT_TOKEN_NOT_ACCEPTED(address tokenAddress); //0xb31d0d90

    //merkle proof
    error MERKLE_PROOF_TOO_LARGE(uint256 sellNonce, uint256 length); //0xc4ebf85a
    error MERKLE_PROOF_INVALID(uint256 sellNonce); //0x2e218f81
    error INVALID_PROOF_HEIGHT(uint256 height); //0x56e0614d

    //primary market
    error EDITION_LIMIT(uint256 dropId); //0x452a12bb
    error MINTS_SIGNATURE(bytes signature); //0x670079be

    //funds facet
    error FA_NATIVE_TRANSFER(); //0xe9dd4fbc
    error FA_DISTRIBUTOR_CALLER_TRANSFER(); //0x81522ab7

    //splits
    error SPLITS_EXPIRED(uint256 splitsNonce); //0x2eed249c
    error SPLITS_NONCE_INVALID(uint256 splitsNonce); //0x4cb00050
    error SPLITS_SIGNATURE(uint256 splitsNonce); //0xe9a2746d

    //sell and delist
    error SELL_NONCE_INVALID(uint256 sellNonce); //0x4d7b9199
    error SELL_DATA_EXPIRED(uint256 sellNonce); //0x209878c5
    error SELL_SIGNATURE(uint256 sellNonce); //0x5397bc4f
    error SELL_NONCE_ALREADY_CANCELED(uint256 sellNonce); //0x69df89fa
    error CALLER_NOT_OWNER_OR_SELLER(uint256 sellNonce); //0xe1efaf1e

    //role
    error MISSING_ROLE(bytes32 role); //0x6a9d0f78

    bytes4 internal constant IERC721_INTERFACE = 0x80ac58cd;

    enum MerkleNodePosition {
        Left,
        Right
    }

    struct MerkleNode {
        bytes32 value;
        MerkleNodePosition position;
    }

    struct MerkleTree {
        bytes32 root;
        MerkleNode[] proof;
    }

    struct SellData {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 sellNonce;
        uint256 expirationDate;
    }

    struct SellDTO {
        SellData[] sells;
        bytes[] sellerSignatures;
        MerkleTree[] merkleTrees;
    }

    struct Payment {
        uint256 amount;
        address recipient;
    }

    struct Splits {
        Payment[] payments;
        uint256 actionExpiration;
        address token;
        uint256 nonce;
        bytes signature;
    }

    struct DropData {
        uint dropId;
        uint maxEditions;
        uint mintEditions;
        uint16 royaltiesPercent;
        address creatorAddress;
        string tokenUri;
        string[] utilityIds;
    }

    struct MintData {
        address nftAddress;
        DropData[] drops;
    }

    /*
        @dev: DO NOT modify struct; doing so will break the diamond storage layout
    */
    struct InitFlag {
        bool inited;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

abstract contract ContextMixin {
    function _msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./../libraries/LibStructStorage.sol";
import "./../utils/ContextMixin.sol";
import "./../interfaces/IAccessControl.sol";

abstract contract FacetInitializable is ContextMixin {
    modifier initializer(LibStructStorage.InitFlag storage flag) {
        require(!flag.inited, "already inited");
        _;
        flag.inited = true;
    }

    modifier only(bytes32 role) {
        if (!IAccessControl(address(this)).hasRole(role, msg.sender)) {
            revert LibStructStorage.MISSING_ROLE(role);
        }
        _;
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}