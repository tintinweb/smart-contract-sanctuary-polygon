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

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IDiamondLoupe {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    function facets() external view returns (Facet[] memory facets_);

    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    function facetAddresses() external view returns (address[] memory facetAddresses_);

    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);

    function addSupportedInterfaces(bytes4[] calldata _supportedInterfaces) external;
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

import { LibStructStorage as StructStorage } from "../libraries/LibStructStorage.sol";

interface IMarketplaceAdmin {
    function splitsNonces(uint256 nonce) external view returns (bool);

    function sellNonces(uint256 nonce) external view returns (bool);

    function externalIds(uint256 externalId) external view returns (bool);

    function acceptedTokens() external view returns (address[] memory);

    function addAcceptedToken(address token) external;

    function removeAcceptedToken(address token) external;

    function setBaseUtilityUri(string calldata _baseUtilityUri) external;

    function editionsMinted(uint256 tokenId) external view returns (uint256);

    function setDummyImplementation(address _implementation) external;

    function implementation() external view returns (address);
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

import "openzeppelin4/utils/introspection/IERC165.sol";
import "./libraries/LibDiamond.sol";
import "./interfaces/IDiamondCut.sol";
import "./interfaces/IDiamondLoupe.sol";
import "./interfaces/IMarketplace.sol";
import "./interfaces/IMarketplaceAdmin.sol";
import "./interfaces/IAccessControl.sol";
import "./interfaces/IMetaTransaction.sol";
import "./interfaces/IFundsAdmin.sol";

contract KreatorhoodMarketplace {
    constructor(
        address _contractOwner,
        address _diamondCutFacet,
        address _diamondLoupeFacet,
        address _marketplaceFacet,
        address _marketplaceAdminFacet,
        address _accessControlFacet,
        address _metaTransactionFacet,
        address _fundsAdminFacet
    ) payable {
        LibDiamond.setContractOwner(_contractOwner);

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](7);

        bytes4[] memory diamondCutSelectors = new bytes4[](1);
        diamondCutSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: diamondCutSelectors
        });

        bytes4[] memory diamondLoupeSelectors = new bytes4[](6);
        diamondLoupeSelectors[0] = IDiamondLoupe.facets.selector;
        diamondLoupeSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        diamondLoupeSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        diamondLoupeSelectors[3] = IDiamondLoupe.facetAddress.selector;
        diamondLoupeSelectors[4] = IDiamondLoupe.addSupportedInterfaces.selector;
        diamondLoupeSelectors[5] = IERC165.supportsInterface.selector;
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: _diamondLoupeFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: diamondLoupeSelectors
        });

        bytes4[] memory marketplaceSelectors = new bytes4[](8);
        marketplaceSelectors[0] = IMarketplace.initialize.selector;
        marketplaceSelectors[1] = IMarketplace.buyNew.selector;
        marketplaceSelectors[2] = IMarketplace.buyNewFiat.selector;
        marketplaceSelectors[3] = IMarketplace.buyListed.selector;
        marketplaceSelectors[4] = IMarketplace.buyListedFiat.selector;
        marketplaceSelectors[5] = IMarketplace.cancelSell.selector;
        marketplaceSelectors[6] = IMarketplace.buy.selector;
        marketplaceSelectors[7] = IMarketplace.buyFiat.selector;

        cut[2] = IDiamondCut.FacetCut({
            facetAddress: _marketplaceFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: marketplaceSelectors
        });

        bytes4[] memory marketplaceAdminSelectors = new bytes4[](9);
        marketplaceAdminSelectors[0] = IMarketplaceAdmin.splitsNonces.selector;
        marketplaceAdminSelectors[1] = IMarketplaceAdmin.externalIds.selector;
        marketplaceAdminSelectors[2] = IMarketplaceAdmin.acceptedTokens.selector;
        marketplaceAdminSelectors[3] = IMarketplaceAdmin.addAcceptedToken.selector;
        marketplaceAdminSelectors[4] = IMarketplaceAdmin.removeAcceptedToken.selector;
        marketplaceAdminSelectors[5] = IMarketplaceAdmin.editionsMinted.selector;
        marketplaceAdminSelectors[6] = IMarketplaceAdmin.setBaseUtilityUri.selector;
        marketplaceAdminSelectors[7] = IMarketplaceAdmin.setDummyImplementation.selector;
        marketplaceAdminSelectors[8] = IMarketplaceAdmin.implementation.selector;

        cut[3] = IDiamondCut.FacetCut({
            facetAddress: _marketplaceAdminFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: marketplaceAdminSelectors
        });

        bytes4[] memory accessControlSelectors = new bytes4[](11);
        accessControlSelectors[0] = IAccessControl.initializeAccessControl.selector;
        accessControlSelectors[1] = IAccessControl.hasRole.selector;
        accessControlSelectors[2] = IAccessControl.getRoleMemberCount.selector;
        accessControlSelectors[3] = IAccessControl.getRoleMember.selector;
        accessControlSelectors[4] = IAccessControl.getRoleAdmin.selector;
        accessControlSelectors[5] = IAccessControl.grantRole.selector;
        accessControlSelectors[6] = IAccessControl.revokeRole.selector;
        accessControlSelectors[7] = IAccessControl.renounceRole.selector;
        accessControlSelectors[8] = IAccessControl.setRoleAdmin.selector;
        accessControlSelectors[9] = IAccessControl.setDiamondOwner.selector;
        accessControlSelectors[10] = IAccessControl.getDiamondOwner.selector;

        cut[4] = IDiamondCut.FacetCut({
            facetAddress: _accessControlFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: accessControlSelectors
        });

        bytes4[] memory metaTransactionSelectors = new bytes4[](6);
        metaTransactionSelectors[0] = IMetaTransaction.initializeMetaTransaction.selector;
        metaTransactionSelectors[1] = IMetaTransaction.tryRecoverSplitsSigner.selector;
        metaTransactionSelectors[2] = IMetaTransaction.tryRecoverMintDataSigner.selector;
        metaTransactionSelectors[3] = IMetaTransaction.executeMetaTransaction.selector;
        metaTransactionSelectors[4] = IMetaTransaction.getNonce.selector;
        metaTransactionSelectors[5] = IMetaTransaction.tryRecoverMerkleProofOrSellDataSigner.selector;

        cut[5] = IDiamondCut.FacetCut({
            facetAddress: _metaTransactionFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: metaTransactionSelectors
        });

        bytes4[] memory fundsAdminSelectors = new bytes4[](7);
        fundsAdminSelectors[0] = IFundsAdmin.initializeFundsAdmin.selector;
        fundsAdminSelectors[1] = IFundsAdmin.distributeSplits.selector;
        fundsAdminSelectors[2] = IFundsAdmin.setBlocksPerDay.selector;
        fundsAdminSelectors[3] = IFundsAdmin.withdrawPlatformFees.selector;
        fundsAdminSelectors[4] = IFundsAdmin.referenceBlockNumber.selector;
        fundsAdminSelectors[5] = IFundsAdmin.blocksPerDay.selector;
        fundsAdminSelectors[6] = IFundsAdmin.setReferenceBlockNumber.selector;

        cut[6] = IDiamondCut.FacetCut({
            facetAddress: _fundsAdminFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: fundsAdminSelectors
        });

        LibDiamond.diamondCut(cut, address(0), "");
    }

    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("KTHD.LIBDIAMOND.STORAGE");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition;
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition;
    }

    struct DiamondStorage {
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        address[] facetAddresses;
        mapping(bytes4 => bool) supportedInterfaces;
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    // slither-disable-next-line dead-code
    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    function diamondCut(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
        for (uint256 facetIndex = 0; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex = 0; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex = 0; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex = 0; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        if (lastSelectorPosition == 0) {
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
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