// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { OwnableInternal } from "@solidstate/contracts/access/ownable/OwnableInternal.sol";

import { IWalletFactoryFacet } from "../interfaces/IWalletFactoryFacet.sol";
import { WalletFactory } from "../wallet/factory/WalletFactory.sol";


/**
 * @title WalletFactoryFacet 
 */
contract WalletFactoryFacet is IWalletFactoryFacet, WalletFactory, OwnableInternal {
    /**
     * @notice return the current version of WalletFactoryFacets
     */
    function walletFactoryFacetVersion() external pure override returns (string memory) {
        return "0.1.0.alpha";
    }

    function _beforeSetDiamond(address diamond)
        internal
        view
        virtual
        override
        onlyOwner
    {
        super._beforeSetDiamond(diamond);
    }

    function _beforeAddFacet(
        string memory name,
        address facetAddress,
        string memory version
    ) internal view virtual override onlyOwner {
        super._beforeAddFacet(name, facetAddress, version);
    }

     function _beforeRemoveFacet(string memory name) internal view virtual override onlyOwner {
        super._beforeRemoveFacet(name);
     }

    function _beforeAddGuardian(bytes32 hashId, bytes32 guardian)
        internal
        view
        virtual
        override
        onlyOwner
    {
        super._beforeAddGuardian(hashId, guardian);
    }

    function _beforeRemoveGuardian(bytes32 hashId)
        internal
        view
        virtual
        override
        onlyOwner
    {
        super._beforeRemoveGuardian(hashId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnableInternal } from './IOwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal is IOwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(
            msg.sender == OwnableStorage.layout().owner,
            'Ownable: sender must be owner'
        );
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transferOwnership(address account) internal virtual {
        OwnableStorage.layout().setOwner(account);
        emit OwnershipTransferred(msg.sender, account);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { IWalletFactory } from "../wallet/factory/IWalletFactory.sol";


/**
 * @title WalletFactoryFacet Interface
 */
interface IWalletFactoryFacet is IWalletFactory {
    /**
     * @notice return the current version of WalletFactoryFacets
     */
    function walletFactoryFacetVersion() external pure returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { IWalletFactory } from "./IWalletFactory.sol";
import { WalletFactoryInternal } from "./WalletFactoryInternal.sol";
import { WalletFactoryStorage } from "./WalletFactoryStorage.sol";

abstract contract WalletFactory is IWalletFactory, WalletFactoryInternal {
    /**
     * @inheritdoc IWalletFactory
     */
    function setDiamond(address diamond) external override {
        _beforeSetDiamond(diamond);

        _setDiamond(diamond);

        _afterSetDiamond(diamond);
    }

     /**
     * @inheritdoc IWalletFactory
     */
    function addFacet(
        string memory name,
        address facetAddress,
        string memory version
    ) external override {
        _beforeAddFacet(name, facetAddress, version);

        _addFacet(name, facetAddress, version);

        _afterAddFacet(name, facetAddress, version);
    }

    /**
     * @inheritdoc IWalletFactory
     */
    function addGuardian(bytes32 hashId, bytes32 guardian) external override {
        _addGuardian(hashId, guardian);
    }

    /**
     * @inheritdoc IWalletFactory
     */
    function removeGuardian(bytes32 hashId) external override {
        _removeGuardian(hashId);
    }

    /**
     * @inheritdoc IWalletFactory
     */
    function createWallet(
        bytes32 hashId,
        address owner,
        VerifierDTO[] memory verifier
    ) external override returns (address) {
        _beforeCreateWallet(hashId, owner, verifier);
        
        return _createWallet(hashId, owner, verifier);
    }

    /**
     * @inheritdoc IWalletFactory
     */
    function createWalletDeterministic(
        bytes32 hashId,
        address owner,
        VerifierDTO[] memory verifiers,
        bytes32 salt
    )
        external
        override
        returns (address)
    {
        _beforeCreateWalletDeterministic(hashId, owner,verifiers, salt);

        return _createWalletDeterministic(hashId, owner, verifiers, salt);
    }

    /**
     * @inheritdoc IWalletFactory
     */
    function getFacetIndex(address facetAddress) external view override returns (uint) {
        return _getFacetIndex(facetAddress);
    }

     /**
     * @inheritdoc IWalletFactory
     */
    function getFacet(uint256 arrayIndex) external view override returns (WalletFactoryStorage.Facet memory) {
        return _getFacet(arrayIndex);
    }

     /**
     * @inheritdoc IWalletFactory
     */
    function getFacets() external view override returns (WalletFactoryStorage.Facet[] memory) {
        return _getFacets();
    }
    
    /**
     * @inheritdoc IWalletFactory
     */
    function predictDeterministicAddress(bytes32 salt)
        public
        view
        override
        returns (address predicted)
    {
        return _predictDeterministicAddress(salt);
    }

    /**
     * @inheritdoc IWalletFactory
     */
    function getDiamond() public view override returns (address) {
        return _getDiamond();
    }

    /**
     * @inheritdoc IWalletFactory
     */
    function getWallet(bytes32 hashId) external view returns (address) {
        return _getWallet(hashId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC173Internal } from '../IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import { IWalletFactoryInternal } from "./IWalletFactoryInternal.sol";
import { WalletFactoryStorage } from "./WalletFactoryStorage.sol";

/**
 * @title Semaphore interface
 */
interface IWalletFactory is IWalletFactoryInternal {
    /**
     * @notice set the address of the Diamond contract.
     * @param diamond: the address of the Diamond contract.
     */
    function setDiamond(address diamond) external;

    /**
     * @notice add facet to facets array.
     * @param name: the name of the facet.
     * @param facetAddress: the address of the facet contract.
     * @param version: the version of the facet.
     */
    function addFacet(
        string memory name,
        address facetAddress,
        string memory version
    ) external;

    /**
     * @notice add a guardian into WalletFactory.
     * @param hashId: the hash of the identification of the guardian.
     * @param guardian: the identityCommitment of the guardian.
     */
    function addGuardian(bytes32 hashId, bytes32 guardian) external;

    /**
     * @notice remove a guardian into WalletFactory.
     * @param hashId: the hash of the identification of the guardian.
     */
    function removeGuardian(bytes32 hashId) external;

    /**
     * @notice deploy a new wallet from WalletDiamond.
     * @param hashId: the hash of the identification of the user.
     * @param owner: the owner of the wallet.
     * @param verifiers: the verfiers contract to be added to Semaphore.
     *
     * @return the address of the new wallet.
     */
    function createWallet(
        bytes32 hashId,
        address owner,
        VerifierDTO[] memory verifiers
    ) external returns (address);

    /**
     * @notice create a new wallet from WalletDiamond.
     * @param hashId: the hash of the identification of the user.
     * @param owner: the owner of the wallet.
     * @param verifiers: the verfiers contract to be added to Semaphore.
     * @param salt: salt to deterministically deploy the clone.
     */
    function createWalletDeterministic(
        bytes32 hashId,
        address owner,
        VerifierDTO[] memory verifiers, 
        bytes32 salt
    ) external  returns (address);

    /**
     * @notice query the mapping index of facet.
     * @param facetAddress: the address of the facet.
     */
    function getFacetIndex(address facetAddress) external view returns (uint);

    /**
     * @notice query a facet.
     * @param arrayIndex: the index of Facet array.
     */
    function getFacet(uint256 arrayIndex) external view returns (WalletFactoryStorage.Facet memory);

    /**
     * @notice query all facets from the storage.
     */
    function getFacets() external view returns (WalletFactoryStorage.Facet[] memory);

    /**
     * @notice predict the address of the new wallet.
     * @param salt: salt to deterministically deploy the clone.
     */
    function predictDeterministicAddress(bytes32 salt)
        external
        view
        returns (address predicted);

    /**
     * @notice query the address of the stored diamond contract.
     */
    function getDiamond() external view returns (address);

    /**
     * @notice query the address of the wallet contract.
     * @param hashId: the hash id of the user.
     */
    function getWallet(bytes32 hashId) external view returns (address);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title WalletFactory interface needed by internal functions
 */
interface IWalletFactoryInternal {
    struct VerifierDTO {
        uint8 merkleTreeDepth;
        address contractAddress;
    }

    /**
     * @notice emitted when anew diamond wallet is created by user
     * @param instance: the address of the instance
     */
    event WalletIsCreated(address instance);

    /**
     * @notice emitted when Diamond address is set
     * @param wallet: the address of the wallet
     */
    event DiamondIsSet(address wallet);

    /**
     * @notice emitted when a new facet is added to WalletFactory
     * @param name: the name of the facet
     * @param facetAddress: the address of the facet contract
     * @param version: the version of the facet
     */
    event FacetIsAdded(string name, address facetAddress, string version);

    /**
     * @notice emitted when a new facet is removed to WalletFactory
     * @param facetAddress: the address of the facet contract
     *
     */
    event FacetIsRemoved(address facetAddress);

    /**
     * @notice emitted when a guardian is added to WalletFactory
     * @param hashId: the hash of the identification of the guardian
     * @param guardian: the identityCommitment of the guardian
     */
    event GuardianAdded(bytes32 indexed hashId, bytes32 guardian);

    /**
     * @notice emitted when a guardian is removed to WalletFactory
     * @param hashId: the hash of the identification of the guardian
     * @param guardian: the identityCommitment of the guardian
     */
    event GuardianRemoved(bytes32 indexed hashId, bytes32 guardian);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import {ISolidStateDiamond} from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";

/**
 * @title WalletFactory Storage base on Diamond Standard Layout storage pattern
 */
library WalletFactoryStorage {
    struct Facet {
        string name;
        address facetAddress;
        string version;
    }
    struct Layout {
        mapping(bytes32 => bytes32) guardians;
        mapping(bytes32 => address) wallets;
        mapping(address => uint256) indexOfErc721Token;
        address diamond;

        // facet address -> facetsIdx
        mapping(address => uint256) facetIndex;
        Facet[] facets;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("simplicy.contracts.storage.WalletFactory");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /**
     * @notice set the address of the Diamond contract
     * @param diamond: the address of the Diamond contract
     */
    function setDiamond(Layout storage s, address diamond) internal {
        s.diamond = diamond;
    }

     /**
     * @notice store a new facet in WalletFactory.
     * @param name: the name of the Facet.
     * @param facetAddress: the address of the facet.
     * @param version: the version of the facet.
     * @return returns a boolean value indicating whether the operation succeeded.
     */
    function storeFacet(
        Layout storage s,
        string memory name,
        address facetAddress,
        string memory version
    ) internal returns (bool){
        uint256 arrayIndex = s.facets.length;
        uint256 index = arrayIndex + 1;
        s.facets.push(
            Facet(
                name,
                facetAddress,
                version
            )
        );
        s.facetIndex[facetAddress] = index;
        return true;
    }

     /**
     * @notice delete a facet from the storage,
     * we are going to switch the last item in the array with the one we are replacing.
     * That way when we pop, we are removing the correct item. 
     *
     * There are two cases we need to handle:
     *  - the address we are removing is not the last address in the array
     *  - or it is the last address in the array. 
     * @param facetAddress: the address of the facet.
     * @return returns a boolean value indicating whether the operation succeeded. 
     */
    function deleteFacet(
        Layout storage s,
        address facetAddress
    ) internal returns (bool) {
        uint256 index = s.facetIndex[facetAddress];
        require(index > 0, "WalletFactory: FACET_NOT_EXISTS");

        uint arrayIndex = index - 1;
        require(arrayIndex >= 0, "WalletFactory: ARRAY_INDEX_OUT_OF_BOUNDS");

        if(arrayIndex != s.facets.length - 1) {
            s.facets[arrayIndex] = s.facets[s.facets.length - 1];
            s.facetIndex[s.facets[arrayIndex].facetAddress] = index;
        }
        s.facets.pop();
        delete s.facetIndex[facetAddress];
        return true;
    }

    /**
     * @notice add a guardian into WalletFactoryStorage
     * @param hashId: the hash of the identification of the guardian
     * @param guardian: the identityCommitment of the guardian
     */
    function storeGuardian(
        Layout storage s,
        bytes32 hashId,
        bytes32 guardian
    ) internal {
        s.guardians[hashId] = guardian;
    }

    /**
     * @notice delete a guardian from WalletFactoryStorage
     * @param hashId: the hash of the identification of the guardian
     */
    function deleteGuardian(Layout storage s, bytes32 hashId) internal {
        delete s.guardians[hashId];
    }

    /**
     * @notice store a wallet into WalletFactoryStorage
     * @param hashId: the hash of the identification of the wallet
     * @param wallet: the address of the wallet
     */
    function storeWallet(
        Layout storage s,
        bytes32 hashId,
        address wallet
    ) internal {
        s.wallets[hashId] = wallet;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ISafeOwnable } from '../../access/ownable/ISafeOwnable.sol';
import { IERC165 } from '../../introspection/IERC165.sol';
import { IDiamondBase } from './base/IDiamondBase.sol';
import { IDiamondReadable } from './readable/IDiamondReadable.sol';
import { IDiamondWritable } from './writable/IDiamondWritable.sol';

interface ISolidStateDiamond is
    IDiamondBase,
    IDiamondReadable,
    IDiamondWritable,
    ISafeOwnable,
    IERC165
{
    receive() external payable;

    /**
     * @notice get the address of the fallback contract
     * @return fallback address
     */
    function getFallbackAddress() external view returns (address);

    /**
     * @notice set the address of the fallback contract
     * @param fallbackAddress fallback address
     */
    function setFallbackAddress(address fallbackAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnable } from './IOwnable.sol';

interface ISafeOwnable is IOwnable {
    /**
     * @notice get the nominated owner who has permission to call acceptOwnership
     */
    function nomineeOwner() external view returns (address);

    /**
     * @notice accept transfer of contract ownership
     */
    function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IProxy } from '../../IProxy.sol';

interface IDiamondBase is IProxy {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Diamond proxy introspection interface
 * @dev see https://eips.ethereum.org/EIPS/eip-2535
 */
interface IDiamondReadable {
    struct Facet {
        address target;
        bytes4[] selectors;
    }

    /**
     * @notice get all facets and their selectors
     * @return diamondFacets array of structured facet data
     */
    function facets() external view returns (Facet[] memory diamondFacets);

    /**
     * @notice get all selectors for given facet address
     * @param facet address of facet to query
     * @return selectors array of function selectors
     */
    function facetFunctionSelectors(address facet)
        external
        view
        returns (bytes4[] memory selectors);

    /**
     * @notice get addresses of all facets used by diamond
     * @return addresses array of facet addresses
     */
    function facetAddresses()
        external
        view
        returns (address[] memory addresses);

    /**
     * @notice get the address of the facet associated with given selector
     * @param selector function selector to query
     * @return facet facet address (zero address if not found)
     */
    function facetAddress(bytes4 selector)
        external
        view
        returns (address facet);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Diamond proxy upgrade interface
 * @dev see https://eips.ethereum.org/EIPS/eip-2535
 */
interface IDiamondWritable {
    enum FacetCutAction {
        ADD,
        REPLACE,
        REMOVE
    }

    event DiamondCut(FacetCut[] facetCuts, address target, bytes data);

    struct FacetCut {
        address target;
        FacetCutAction action;
        bytes4[] selectors;
    }

    /**
     * @notice update diamond facets and optionally execute arbitrary initialization function
     * @param facetCuts array of structured Diamond facet update data
     * @param target optional target of initialization delegatecall
     * @param data optional initialization function call data
     */
    function diamondCut(
        FacetCut[] calldata facetCuts,
        address target,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC173 } from '../IERC173.sol';

interface IOwnable is IERC173 {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC173Internal } from './IERC173Internal.sol';

/**
 * @title Contract ownership standard interface
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173 is IERC173Internal {
    /**
     * @notice get the ERC173 contract owner
     * @return conrtact owner
     */
    function owner() external view returns (address);

    /**
     * @notice transfer contract ownership to new account
     * @param account address of new owner
     */
    function transferOwnership(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IProxy {
    fallback() external payable;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { ERC165, IERC165, ERC165Storage } from "@solidstate/contracts/introspection/ERC165.sol";
import { IDiamondWritable } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";
import { ISafeOwnable, IOwnable } from "@solidstate/contracts/access/ownable/ISafeOwnable.sol";
import { AddressUtils } from "@solidstate/contracts/utils/AddressUtils.sol";

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import { IZkWalletDiamond } from "../../interfaces/IZkWalletDiamond.sol";
import { ZkWalletDiamond } from "../../diamond/zkWallet/ZkWalletDiamond.sol";
import { IWalletFactoryInternal } from "./IWalletFactoryInternal.sol";
import { WalletFactoryStorage } from "./WalletFactoryStorage.sol";

/**
 * @title WalletFactory internal functions
 */
abstract contract WalletFactoryInternal is IWalletFactoryInternal {
    using WalletFactoryStorage for WalletFactoryStorage.Layout;
    using WalletFactoryStorage for WalletFactoryStorage.Facet;
    using ERC165Storage for ERC165Storage.Layout;
    using AddressUtils for address;
    using Clones for address;

    string public constant WALLET_CREATION = "WALLET_CREATION";

    /**
     * @notice internal function set the address of the Diamond contract
     * @param diamond: the address of the Diamond contract
     */
    function _setDiamond(address diamond) internal virtual {
        WalletFactoryStorage.layout().setDiamond(diamond);

        emit DiamondIsSet(diamond);
    }

    /**
     * @notice internal function add facet to facets mapping
     * @param name: the name of the facet
     * @param facetAddress: the address of the facet contract
     * @param version: the version of the facet
     */
    function _addFacet(
        string memory name,
        address facetAddress,
        string memory version
    ) internal virtual {
        require(
            WalletFactoryStorage.layout().storeFacet(name, facetAddress, version),
            "WalletFactory: not able to store facet"
        );
        
        emit FacetIsAdded(name, facetAddress, version);
    }

    /**
     * @notice internal function remove facet to facets mapping
     * @param facetAddress: facet name to be removed
     */
    function _removeFacet(address facetAddress) internal virtual {
        require(
            WalletFactoryStorage.layout().deleteFacet(facetAddress),
            "WalletFactory: not able to remove facet"
        );

        emit FacetIsRemoved(facetAddress);
    }

    /**
     * @notice internal function add a guardian into WalletFactory
     * @param hashId: the hash of the identification of the guardian
     * @param guardian: the identityCommitment of the guardian
     */
    function _addGuardian(bytes32 hashId, bytes32 guardian) internal virtual {
        WalletFactoryStorage.layout().storeGuardian(hashId, guardian);

        emit GuardianAdded(hashId, guardian);
    }

    /**
     * @notice internal function remove a guardian into WalletFactory
     * @param hashId: the hash of the identification of the guardian
     */
    function _removeGuardian(bytes32 hashId) internal virtual {
        bytes32 guardian = WalletFactoryStorage.layout().guardians[hashId];

        WalletFactoryStorage.layout().deleteGuardian(hashId);

        emit GuardianRemoved(hashId, guardian);
    }

    /**
     * @notice internal function create a new wallet from WalletDiamond
     * @param hashId: the hash of the identification of the user
     * @param owner; the owner of the wallet
     * @param verifiers: the verfiers contract to be added to Semaphore
     * @return the address of the new wallet
     */
    function _createWallet(
        bytes32 hashId,
        address owner,
        VerifierDTO[] memory verifiers
    )
        internal
        virtual
        returns (address)
    {
        WalletFactoryStorage.Facet[] memory facets = _getFacets();

        address deployed = address(new ZkWalletDiamond(owner, facets, verifiers));
        
        WalletFactoryStorage.layout().storeWallet(hashId, deployed);

        emit WalletIsCreated(deployed);

        return deployed;
    }

   /**
     * @notice internal function create a new wallet from WalletDiamond.
     * @param hashId: the hash of the identification of the user.
     * @param owner: the owner of the wallet.
     * @param verifiers: the verfiers contract to be added to Semaphore
     * @param salt: salt to deterministically deploy the clone.
    * @return the address of the new wallet
     */
    function _createWalletDeterministic(
        bytes32 hashId,
        address owner,
        VerifierDTO[] memory verifiers,
        bytes32 salt
    )
        internal
        virtual
        returns (address)
    {
        address diamond = _getDiamond();
        WalletFactoryStorage.Facet[] memory facets = _getFacets();

        address newClone = diamond.cloneDeterministic(salt);

        (bool success, bytes memory data) = newClone.call(
            abi.encodeWithSignature("init(address,(string,address,string),(uint8,address))", owner, facets, verifiers)
        );

        WalletFactoryStorage.layout().storeWallet(hashId, newClone);

        emit WalletIsCreated(newClone);

        return newClone;
    }

     /**
     * @notice internal function query the mapping index of facet.
     * @param facetAddress: the address of the facet.
     */
    function _getFacetIndex(address facetAddress) internal view virtual returns (uint) {
        return WalletFactoryStorage.layout().facetIndex[facetAddress];
    }

    /**
     * @notice internal function query a facet.
     * @param arrayIndex: the index of Facet array.
     */
    function _getFacet(uint256 arrayIndex) internal view virtual returns (WalletFactoryStorage.Facet memory) {
        return WalletFactoryStorage.layout().facets[arrayIndex];
    }

    /**
     * @notice internal function query all facets from the storage
     */
    function _getFacets() internal view virtual returns (WalletFactoryStorage.Facet[] memory) {
        return WalletFactoryStorage.layout().facets;
    }

    /**
     * @notice internal function query the address of the Diamond contract
     */
    function _getDiamond() internal view virtual returns (address) {
        return WalletFactoryStorage.layout().diamond;
    }

    /**
     * @notice internal function query the address of a wallet
     * @param hashId: the hash id of the user
     */
    function _getWallet(bytes32 hashId)
        internal
        view
        virtual
        returns (address)
    {
        return WalletFactoryStorage.layout().wallets[hashId];
    }

    /**
     * @notice internal function predict the address of the new wallet
     * @param salt: salt to deterministically deploy the clone
     */
    function _predictDeterministicAddress(bytes32 salt)
        internal
        view
        virtual
        returns (address predicted)
    {
        return address(0); // TODO: _getDiamond().predictDeterministicAddress(salt);
    }

    /**
     * @notice hook that is called before a wallet is created
     * to learn more about hooks: https://docs.openzeppelin.com/contracts/4.x/extending-contracts#using-hooks
     */
    function _beforeCreateWallet( 
        bytes32 hashId,
        address owner,
        VerifierDTO[] memory verifiers
    ) internal view virtual {
        // require(
        //     _getDiamond() != address(0),
        //     "WalletFactory: Diamond address is the zero address  "
        // );

        require(
            hashId != bytes32(0),
            "WalletFactory: hashId is the zero value"
        );
    }

    /**
     * @notice hook that is called before a wallet is created
     * to learn more about hooks: https://docs.openzeppelin.com/contracts/4.x/extending-contracts#using-hooks
     */
    function _beforeCreateWalletDeterministic(
        bytes32 hashId,
        address owner,
        VerifierDTO[] memory verifiers,
        bytes32 salt
    )
        internal
        view
        virtual
    {
        _beforeCreateWallet(hashId, owner, verifiers );
    }

    /**
     * @notice hook that is called before Diamond is set
     * to learn more about hooks: https://docs.openzeppelin.com/contracts/4.x/extending-contracts#using-hooks
     */
    function _beforeSetDiamond(address diamond) internal view virtual {
        require(
            diamond != address(0),
            "WalletFactory: Diamond address is the zero address"
        );
    }

    /**
     * @notice hook that is called after Diamond is set
     * to learn more about hooks: https://docs.openzeppelin.com/contracts/4.x/extending-contracts#using-hooks
     */
    function _afterSetDiamond(address diamond) internal view virtual {}

    /**
     * @notice hook that is called before facet is added
     * to learn more about hooks: https://docs.openzeppelin.com/contracts/4.x/extending-contracts#using-hooks
     */
    function _beforeAddFacet(
        string memory name,
        address facetAddress,
        string memory version
    ) internal view virtual {
        require(
            keccak256(abi.encodePacked(name)) !=
                (keccak256(abi.encodePacked(""))),
            "WalletFactory: name is empty"
        );

        require(
            facetAddress != address(0),
            "WalletFactory: facetAddress is the zero address"
        );

        require(
            keccak256(abi.encodePacked(version)) !=
                (keccak256(abi.encodePacked(""))),
            "WalletFactory: version is empty"
        );
    }

    /**
     * @notice hook that is called after facet is added
     * to learn more about hooks: https://docs.openzeppelin.com/contracts/4.x/extending-contracts#using-hooks
     */
    function _afterAddFacet(
        string memory name,
        address facetAddress,
        string memory version
    ) internal view virtual {}

    /**
     * @notice hook that is called before facet is removed
     * to learn more about hooks: https://docs.openzeppelin.com/contracts/4.x/extending-contracts#using-hooks
     */
    function _beforeRemoveFacet(string memory name) internal view virtual {
        require(
            keccak256(abi.encodePacked(name)) !=
                (keccak256(abi.encodePacked(""))),
            "WalletFactory: name is the zero value"
        );
    }

    /**
     * @notice hook that is called after facet is removed
     * to learn more about hooks: https://docs.openzeppelin.com/contracts/4.x/extending-contracts#using-hooks
     */
    function _afterRemoveFacet(string memory name) internal view virtual {}

    /**
     * @notice hook that is called before a guardian is added
     * to learn more about hooks: https://docs.openzeppelin.com/contracts/4.x/extending-contracts#using-hooks
     */
    function _beforeAddGuardian(bytes32 hashId, bytes32 guardian)
        internal
        view
        virtual
    {
        require(
            hashId != bytes32(0),
            "WalletFactory: hashId is the zero value"
        );

        require(
            guardian != bytes32(0),
            "WalletFactory: guardian is the zero value"
        );
    }

    /**
     * @notice hook that is called after a guardian is added
     * to learn more about hooks: https://docs.openzeppelin.com/contracts/4.x/extending-contracts#using-hooks
     */
    function _afterAddGuardian(bytes32 hashId, bytes32 guardian)
        internal
        view
        virtual
    {}

    /**
     * @notice hook that is called before a guardian is removed
     * to learn more about hooks: https://docs.openzeppelin.com/contracts/4.x/extending-contracts#using-hooks
     */
    function _beforeRemoveGuardian(bytes32 hashId) internal view virtual {
        require(
            hashId != bytes32(0),
            "WalletFactory: hashId is the zero value"
        );
    }

    /**
     * @notice hook that is called after a guardian is removed
     * to learn more about hooks: https://docs.openzeppelin.com/contracts/4.x/extending-contracts#using-hooks
     */
    function _afterRemoveGuardian(bytes32 hashId) internal view virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165 } from './IERC165.sol';
import { ERC165Storage } from './ERC165Storage.sol';

/**
 * @title ERC165 implementation
 */
abstract contract ERC165 is IERC165 {
    using ERC165Storage for ERC165Storage.Layout;

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return ERC165Storage.layout().isSupportedInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        require(success, 'AddressUtils: failed to send value');
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            'AddressUtils: insufficient balance for call'
        );
        return _functionCallWithValue(target, data, value, error);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        require(
            isContract(target),
            'AddressUtils: function call to non-contract'
        );

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { IZkWalletDiamondBase } from "../diamond/zkWallet/base/IZkWalletDiamondBase.sol";
import { WalletFactoryStorage } from "../wallet/factory/WalletFactoryStorage.sol";
import { IWalletFactoryInternal } from "../wallet/factory/IWalletFactoryInternal.sol";


/**
 * @title ZkWalletDiamond  interface
 */
interface IZkWalletDiamond is IZkWalletDiamondBase  { 
    function version() external view returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import "hardhat/console.sol";
import { IERC173 } from "@solidstate/contracts/access/IERC173.sol";
import { ERC165, IERC165, ERC165Storage } from "@solidstate/contracts/introspection/ERC165.sol";
import { DiamondBaseStorage } from "@solidstate/contracts/proxy/diamond/base/DiamondBase.sol";
import { IDiamondWritable } from "@solidstate/contracts/proxy/diamond/writable/DiamondWritable.sol";

import { IGuardianFacet } from "../../interfaces/IGuardianFacet.sol";
import { IGuardian } from "../../guardian/IGuardian.sol";

import { ISemaphoreGroupsFacet } from "../../interfaces/ISemaphoreGroupsFacet.sol";
import { ISemaphoreGroups } from "../../semaphore/ISemaphoreGroups.sol";
import { ISemaphoreGroupsBase } from "../../semaphore/base/SemaphoreGroupsBase/ISemaphoreGroupsBase.sol";

import { IERC20ServiceFacet } from "../../interfaces/IERC20ServiceFacet.sol";
import { IERC20Service} from "../../token/ERC20/IERC20Service.sol";

import { IERC721ServiceFacetSelector } from "../../interfaces/IERC721ServiceFacetSelector.sol";
import { IERC721Service } from "../../token/ERC721/IERC721Service.sol";

import { IRecoveryFacet } from "../../interfaces/IRecoveryFacet.sol";
import { IRecovery } from "../../recovery/IRecovery.sol";

import { ISemaphoreFacet } from "../../interfaces/ISemaphoreFacet.sol";
import { ISemaphore } from "../../semaphore/ISemaphore.sol";

import { IEtherServiceFacet } from "../../interfaces/IEtherServiceFacet.sol";

import { IZkWalletDiamond } from "../../interfaces/IZkWalletDiamond.sol";
import { IWalletFactoryInternal } from "../../wallet/factory/IWalletFactoryInternal.sol";
import { ZkWalletDiamondBase } from "./base/ZkWalletDiamondBase.sol";
import { WalletFactoryStorage } from "../../wallet/factory/WalletFactoryStorage.sol";
import { IVerifier } from "../../interfaces/IVerifier.sol";

import { SemaphoreStorage } from "../../semaphore/SemaphoreStorage.sol";
/**
 * @title ZkWalletDiamond 
 */
contract ZkWalletDiamond is IZkWalletDiamond, ZkWalletDiamondBase {
    using SemaphoreStorage for SemaphoreStorage.Layout;
    using DiamondBaseStorage for DiamondBaseStorage.Layout;
    using ERC165Storage for ERC165Storage.Layout;
    // using OwnableStorage for OwnableStorage.Layout;

    constructor(
        address owner_,
        WalletFactoryStorage.Facet[] memory facets_, 
        IWalletFactoryInternal.VerifierDTO[] memory _verifiers
    ) {
        require(owner_ != address(0), "ZkWalletDiamond: owner is the zero address");        
        
        __ZkWalletDiamondBase_init(owner_);
        _setVerifiers(_verifiers);
        _addFacets(facets_);        
    }

    /**
     * @notice return the current version of the diamond
     */
    function version()
        public
        pure
        override(IZkWalletDiamond)
        returns (string memory)
    {
        return "0.1.0.alpha";
    }

    function _addFacets(WalletFactoryStorage.Facet[] memory facets_)
        private
    {
        // register facets
        for (uint i = 0; i < facets_.length; i++) {
            string memory facetName = facets_[i].name;
            address facetAddress_ = facets_[i].facetAddress;

            if (keccak256(abi.encodePacked(facetName)) == keccak256(abi.encodePacked("GuardianFacet"))) {
                FacetCut[] memory facetCuts = new FacetCut[](1);
                bytes4[] memory guardianFacetSelectors = new bytes4[](10);

                guardianFacetSelectors[0] = IGuardianFacet.guardianFacetVersion.selector;
                guardianFacetSelectors[1] = IGuardianFacet.addGuardians.selector;
                guardianFacetSelectors[2] = IGuardianFacet.addGuardian.selector;
                guardianFacetSelectors[3] = IGuardianFacet.removeGuardian.selector;
                guardianFacetSelectors[4] = IGuardian.getGuardian.selector;
                guardianFacetSelectors[5] = IGuardian.getGuardians.selector;
                guardianFacetSelectors[6] = IGuardian.numGuardians.selector;
                guardianFacetSelectors[7] = IGuardian.requireMajority.selector;                
                guardianFacetSelectors[8] = IGuardian.removeGuardians.selector;
                guardianFacetSelectors[9] = IGuardian.cancelPendingGuardians.selector;

                facetCuts[0] = FacetCut({
                    target: facetAddress_,
                    action: IDiamondWritable.FacetCutAction.ADD,
                    selectors: guardianFacetSelectors
                });
                DiamondBaseStorage.layout().diamondCut(facetCuts, address(0), "");
            } else if (keccak256(abi.encodePacked(facetName)) == keccak256(abi.encodePacked("SemaphoreGroupsFacet"))) {
                FacetCut[] memory facetCuts = new FacetCut[](1);
                bytes4[] memory semaphoreGroupsFacetSelectors = new bytes4[](10);

                semaphoreGroupsFacetSelectors[0] = ISemaphoreGroupsFacet.semaphoreGroupsFacetVersion.selector;
                semaphoreGroupsFacetSelectors[1] = ISemaphoreGroups.getRoot.selector;
                semaphoreGroupsFacetSelectors[2] = ISemaphoreGroups.getDepth.selector;
                semaphoreGroupsFacetSelectors[3] = ISemaphoreGroups.getNumberOfLeaves.selector;
                semaphoreGroupsFacetSelectors[4] = ISemaphoreGroupsBase.getGroupAdmin.selector;
                semaphoreGroupsFacetSelectors[5] = ISemaphoreGroupsBase.createGroup.selector;
                semaphoreGroupsFacetSelectors[6] = ISemaphoreGroupsBase.updateGroupAdmin.selector;
                semaphoreGroupsFacetSelectors[7] = ISemaphoreGroupsBase.addMembers.selector;
                semaphoreGroupsFacetSelectors[8] = ISemaphoreGroupsBase.removeMember.selector;
                semaphoreGroupsFacetSelectors[9] = ISemaphoreGroupsBase.addMember.selector;

                facetCuts[0] = FacetCut({
                    target: facetAddress_,
                    action: IDiamondWritable.FacetCutAction.ADD,
                    selectors: semaphoreGroupsFacetSelectors
                });
                DiamondBaseStorage.layout().diamondCut(facetCuts, address(0), "");
            } else if (keccak256(abi.encodePacked(facetName)) == keccak256(abi.encodePacked("RecoveryFacet"))) {
                FacetCut[] memory facetCuts = new FacetCut[](1);
                bytes4[] memory recoveryFacetSelectors = new bytes4[](7);
                recoveryFacetSelectors[0] = IRecoveryFacet.recoveryFacetVersion.selector;
                recoveryFacetSelectors[1] = IRecovery.getMajority.selector;
                recoveryFacetSelectors[2] = IRecovery.getRecoveryStatus.selector;
                recoveryFacetSelectors[3] = IRecovery.getRecoveryNominee.selector;
                recoveryFacetSelectors[4] = IRecovery.getRecoveryCounter.selector;
                recoveryFacetSelectors[5] = IRecovery.recover.selector;
                recoveryFacetSelectors[6] = IRecovery.resetRecovery.selector;

                facetCuts[0] = FacetCut({
                    target: facetAddress_,
                    action: IDiamondWritable.FacetCutAction.ADD,
                    selectors: recoveryFacetSelectors
                });
                DiamondBaseStorage.layout().diamondCut(facetCuts, address(0), "");
            } else if (keccak256(abi.encodePacked(facetName)) == keccak256(abi.encodePacked("ERC20ServiceFacet"))) {
                FacetCut[] memory facetCuts = new FacetCut[](1);
                bytes4[] memory erc20FacetSelectors = new bytes4[](9);

                erc20FacetSelectors[0] = IERC20ServiceFacet.erc20ServiceFacetVersion.selector;
                erc20FacetSelectors[1] = IERC20Service.getAllTrackedERC20Tokens.selector;
                erc20FacetSelectors[2] = IERC20Service.balanceOfERC20.selector;
                erc20FacetSelectors[3] = IERC20Service.transferERC20.selector;
                erc20FacetSelectors[4] = IERC20Service.transferERC20From.selector;
                erc20FacetSelectors[5] = IERC20Service.approveERC20.selector;
                erc20FacetSelectors[6] = IERC20Service.registerERC20.selector;
                erc20FacetSelectors[7] = IERC20Service.removeERC20.selector;
                erc20FacetSelectors[8] = IERC20Service.depositERC20.selector;

                facetCuts[0] = FacetCut({
                    target: facetAddress_,
                    action: IDiamondWritable.FacetCutAction.ADD,
                    selectors: erc20FacetSelectors
                });
                DiamondBaseStorage.layout().diamondCut(facetCuts, address(0), "");
            } else if (keccak256(abi.encodePacked(facetName)) == keccak256(abi.encodePacked("ERC721ServiceFacet"))) {
                FacetCut[] memory facetCuts = new FacetCut[](1);
                bytes4[] memory erc721FacetSelectors = new bytes4[](12);

                erc721FacetSelectors[0] = IERC721ServiceFacetSelector.erc721ServiceFacetVersion.selector;
                erc721FacetSelectors[1] = IERC721ServiceFacetSelector.onERC721Received.selector;
                erc721FacetSelectors[2] = IERC721ServiceFacetSelector.safeTransferERC721From.selector;
                erc721FacetSelectors[3] = IERC721Service.getAllTrackedERC721Tokens.selector;
                erc721FacetSelectors[4] = IERC721Service.balanceOfERC721.selector;
                erc721FacetSelectors[5] = IERC721Service.ownerOfERC721.selector;
                erc721FacetSelectors[6] = IERC721Service.transferERC721.selector;
                erc721FacetSelectors[7] = IERC721Service.transferERC721From.selector;
                erc721FacetSelectors[8] = IERC721Service.approveERC721.selector;
                erc721FacetSelectors[9] = IERC721Service.registerERC721.selector;
                erc721FacetSelectors[10] = IERC721Service.removeERC721.selector;
                erc721FacetSelectors[11] = IERC721Service.depositERC721.selector;

                facetCuts[0] = FacetCut({
                    target: facetAddress_,
                    action: IDiamondWritable.FacetCutAction.ADD,
                    selectors: erc721FacetSelectors
                });
                DiamondBaseStorage.layout().diamondCut(facetCuts, address(0), "");
            } else if (keccak256(abi.encodePacked(facetName)) == keccak256(abi.encodePacked("EtherServiceFacet"))) {
                FacetCut[] memory facetCuts = new FacetCut[](1);
                bytes4[] memory ethersFacetSelectors = new bytes4[](3);

                ethersFacetSelectors[0] = IEtherServiceFacet.transferEther.selector;
                ethersFacetSelectors[1] = IEtherServiceFacet.etherServiceFacetVersion.selector;
                ethersFacetSelectors[2] = IEtherServiceFacet.getEtherBalance.selector;

                facetCuts[0] = FacetCut({
                    target: facetAddress_,
                    action: IDiamondWritable.FacetCutAction.ADD,
                    selectors: ethersFacetSelectors
                });
                DiamondBaseStorage.layout().diamondCut(facetCuts, address(0), "");
            }

        }
    }

    function _setVerifiers(IWalletFactoryInternal.VerifierDTO[] memory _verifiers) private {
        for (uint8 i = 0; i < _verifiers.length; i++) {
            SemaphoreStorage.layout().verifiers[
                _verifiers[i].merkleTreeDepth
            ] = IVerifier(_verifiers[i].contractAddress);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC165Storage {
    struct Layout {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC165');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function isSupportedInterface(Layout storage l, bytes4 interfaceId)
        internal
        view
        returns (bool)
    {
        return l.supportedInterfaces[interfaceId];
    }

    function setSupportedInterface(
        Layout storage l,
        bytes4 interfaceId,
        bool status
    ) internal {
        require(interfaceId != 0xffffffff, 'ERC165: invalid interface id');
        l.supportedInterfaces[interfaceId] = status;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        require(value == 0, 'UintUtils: hex length insufficient');

        return string(buffer);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";
import { IZkWalletDiamondBaseInternal } from "./IZkWalletDiamondBaseInternal.sol";

/**
 * @title ZkWalletDiamondBase interface
 */
interface IZkWalletDiamondBase is IZkWalletDiamondBaseInternal, ISolidStateDiamond {}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title Partial ZkWalletDiamondBase interface needed by internal functions
 */
interface IZkWalletDiamondBaseInternal {}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Proxy } from '../../Proxy.sol';
import { IDiamondBase } from './IDiamondBase.sol';
import { DiamondBaseStorage } from './DiamondBaseStorage.sol';

/**
 * @title EIP-2535 "Diamond" proxy base contract
 * @dev see https://eips.ethereum.org/EIPS/eip-2535
 */
abstract contract DiamondBase is IDiamondBase, Proxy {
    /**
     * @inheritdoc Proxy
     */
    function _getImplementation() internal view override returns (address) {
        // inline storage layout retrieval uses less gas
        DiamondBaseStorage.Layout storage l;
        bytes32 slot = DiamondBaseStorage.STORAGE_SLOT;
        assembly {
            l.slot := slot
        }

        address implementation = address(bytes20(l.facets[msg.sig]));

        if (implementation == address(0)) {
            implementation = l.fallbackAddress;
            require(
                implementation != address(0),
                'DiamondBase: no facet found for function signature'
            );
        }

        return implementation;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { OwnableInternal } from '../../../access/ownable/OwnableInternal.sol';
import { DiamondBaseStorage } from '../base/DiamondBaseStorage.sol';
import { IDiamondWritable } from './IDiamondWritable.sol';

/**
 * @title EIP-2535 "Diamond" proxy update contract
 */
abstract contract DiamondWritable is IDiamondWritable, OwnableInternal {
    using DiamondBaseStorage for DiamondBaseStorage.Layout;

    /**
     * @inheritdoc IDiamondWritable
     */
    function diamondCut(
        FacetCut[] calldata facetCuts,
        address target,
        bytes calldata data
    ) external onlyOwner {
        DiamondBaseStorage.layout().diamondCut(facetCuts, target, data);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IGuardian} from "../guardian/IGuardian.sol";

/**
 * @title GuardianFacet interface
 */
interface IGuardianFacet is IGuardian {
    /**
     * @notice add guardians
     * @param groupId: the group id of the semaphore group
     * @param identityCommitments: the identity commitments of guardians
     *
     */
     function addGuardians(
        uint256 groupId,
        uint256[] memory identityCommitments
    ) external;

    /**
     * @notice add guardian
     * @param groupId: the group id of the semaphore group
     * @param hashId: the hash id of the guardian
     * @param identityCommitment: the identity commitment of the guardian
     *
     */
    function addGuardian(uint256 groupId, uint256 hashId, uint256 identityCommitment) external;

    /**
     * @notice remove guardian
     * @param groupId: the group id of the semaphore group
     * @param hashId: the hash id of the guardian
     * @param identityCommitment: existing identity commitment to be deleted
     * @param proofSiblings: array of the sibling nodes of the proof of membership of the semaphoregroup.
     * @param proofPathIndices: path of the proof of membership of the semaphoregroup
     *
     */
    function removeGuardian(
        uint256 groupId,
        uint256 hashId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) external;

    /**
     * @notice return the current version of GuardianFacet
     */
    function guardianFacetVersion() external pure returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import {IGuardianInternal} from "./IGuardianInternal.sol";
import {GuardianStorage} from "./GuardianStorage.sol";

/**
 * @title Guardian interface 
 */
interface IGuardian is IGuardianInternal {
    /**
     * @notice set multiple guardians to the group.
     * @param guardians: guardians to be added.
     *
     * Emits multiple {GuardianAdded} event.
     */
    function setInitialGuardians(uint256[] memory guardians) external;

    /**
     * @notice add a new guardian to the group.
     * @param hashId: the hashId of the guardian.
     * @return returns a boolean value indicating whether the operation succeeded. 
     *
     * Emits a {GuardianAdded} event.
     */
    function addGuardian(uint256 hashId) external returns(bool);

    /**
     * @notice remove guardian from the group.
     * @param hashId: the hashId of the guardian.
     * @return returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {GuardianRemoved} event.
     */
    function removeGuardian(uint256 hashId) external returns(bool);

    /**
     * @notice remove multiple guardians from the group.
     * @param guardians: guardians to be removed.
     *
     * Emits multiple {GuardianRemoved} event.
     */
    function removeGuardians(uint256[] memory guardians) external;


    /**
     * @notice remove all pending guardians from the group.
     *
     * Emits multiple {GuardianRemoved} event.
     */
    function cancelPendingGuardians() external;

    /**
     * @notice query a guardian.
     * @param hashId: the hashId of the guardian.
     */
    function getGuardian(uint256 hashId) external returns (GuardianStorage.Guardian memory);

    /**
     * @notice query all guardians from the storage
     * @param includePendingAddition: whether to include pending addition guardians.
     */
    function getGuardians(bool includePendingAddition)
        external view returns (GuardianStorage.Guardian[] memory);

    /**
     * @notice query the length of the active guardians
     * @param includePendingAddition: whether to include pending addition guardians
     */
    function numGuardians(bool includePendingAddition) external view returns (uint256);

    
    /**
     * @notice check if the guardians are majority.
     * @param guardians: list of guardians to check.
     */
    function requireMajority(GuardianDTO[] calldata guardians) external view;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { ISemaphoreGroups } from "../semaphore/ISemaphoreGroups.sol";


/**
 * @title SemaphoreGroupsFacet interface
 */
interface ISemaphoreGroupsFacet is ISemaphoreGroups {
    /**
     * @notice return the current version of SemaphoreGroupsFacet
     */
    function semaphoreGroupsFacetVersion() external pure returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import {ISemaphoreGroupsBase} from "./base/SemaphoreGroupsBase/ISemaphoreGroupsBase.sol";

/**
 * @title SemaphoreGroups interface
 */
interface ISemaphoreGroups is ISemaphoreGroupsBase {
    /**
     * @notice query the last root hash of a group
     * @param groupId: Id of the group
     * @return root hash of the group.
     */
    function getRoot(uint256 groupId) external view returns (uint256);

    /**
     * @notice query the depth of the tree of a group
     * @param groupId: Id of the group
     * @return depth of the group tree
     */
    function getDepth(uint256 groupId) external view returns (uint8);

    /**
     * @notice query the number of tree leaves of a group
     * @param groupId: Id of the group
     * @return number of tree leaves
     */
    function getNumberOfLeaves(uint256 groupId) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import {ISemaphoreGroupsInternal} from "./ISemaphoreGroupsInternal.sol";

/**
 * @title SemaphoreGroups base interface
 */
interface ISemaphoreGroupsBase is ISemaphoreGroupsInternal { 
    /**
     * @notice Updates the group admin.
     * @param groupId: Id of the group.
     * @param newAdmin: New admin of the group.
     *
     * Emits a {GroupAdminUpdated} event.
     */
    function updateGroupAdmin(uint256 groupId, address newAdmin) external;
    
    /**
     * @notice ceates a new group by initializing the associated tree.
     * @param groupId: Id of the group.
     * @param depth: Depth of the tree.
     * @param zeroValue: Zero value of the tree.
     * @param admin: Admin of the group.
     *
     * Emits {GroupCreated} and {GroupAdminUpdated} events.
     */
    function createGroup(
        uint256 groupId,
        uint8 depth,
        uint256 zeroValue,
        address admin
    ) external;

    /**
     * @notice adds identity commitments to an existing group.
     * @param groupId: Id of the group.
     * @param identityCommitments: array of new identity commitments.
     *
     * TODO: hash the identityCommitments to make sure users can't see
     *       which identityCommitment belongs to the guardian
     *
     *
     * Emits multiple {MemberAdded} events.
     */
    function addMembers(uint256 groupId, uint256[] memory identityCommitments)
        external;

    /**
     * @notice add a identity commitment to an existing group.
     * @param groupId: Id of the group.
     * @param identityCommitment: the identity commitment of the member.
     *
     * TODO: hash the identityCommitment to make sure users can't see
     *       which identityCommitment belongs to the guardian
     *
     *
     * Emits a {MemberAdded} event.
     */
    function addMember(uint256 groupId, uint256 identityCommitment)
        external;

    /**
     * @notice removes an identity commitment from an existing group. A proof of membership is
     *         needed to check if the node to be deleted is part of the tree.
     * @param groupId: Id of the group.
     * @param identityCommitment: existing identity commitment to be deleted.
     * @param proofSiblings: array of the sibling nodes of the proof of membership.
     * @param proofPathIndices: path of the proof of membership.
     *
     * TODO: hash the identityCommitment to make sure users can't see
     *       which identityCommitment belongs to the guardian
      *
     * Emits a {MemberRemoved} event.
     */
    function removeMember(
        uint256 groupId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) external;

    /**
     * @notice query a groupAdmin.
     * @param groupId: the groupId of the group.
     */
    function getGroupAdmin(uint256 groupId) external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { IERC20Service } from "../token/ERC20/IERC20Service.sol";


/**
 * @title ERC20ServiceFacet interface
 */
interface IERC20ServiceFacet is IERC20Service {
    /**
     * @notice return the current version of ERC20ServiceFacet
     */
    function erc20ServiceFacetVersion() external pure returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import {IERC20ServiceInternal} from "./IERC20ServiceInternal.sol";

/**
 * @title ERC20Service interface 
 */
interface IERC20Service is IERC20ServiceInternal {
    /**
     * @notice sets `amount` as the allowance of `spender` over the caller's tokens.
     * @param token: the address of tracked token to move.
     * @param spender: the address of the spender.
     * @param amount: the amount of tokens to set as allowance.
     * @return returns a boolean value indicating whether the operation succeeded.
     */
    function approveERC20(address token, address spender, uint256 amount) external returns (bool);

    /**
     * @notice moves `amount` tracked tokens from the caller's account to `to`.
     * @param token: the address of tracked token to move.
     * @param to: the address of the recipient.
     * @param amount: the amount of tokens to move.
     * @return returns a boolean value indicating whether the operation succeeded.
     */
    function transferERC20(address token, address to, uint256 amount) external returns (bool);

    /**
     * @notice transfer tokens to given recipient on behalf of given holder.
     * @param token: the address of tracked token to move.
     * @param from: holder of tokens prior to transfer.
     * @param to: beneficiary of token transfer.
     * @param amount quantity of tokens to transfer.
     * @return success status (always true; otherwise function should revert).
     */
    function transferERC20From(
        address token,
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice register a new ERC20 token.
     * @param token: the address of the ERC721 token.
     */
    function registerERC20(address token) external;

    /**
     * @notice remove a new ERC20 token from ERC20Service.
     * @param token: the address of the ERC20 token.
     */
    function removeERC20(address token) external;

    /**
     * @notice deposit a ERC20 token to ERC20Service.
     * @param token: the address of the ERC20 token.
     * @param amount: the amount of token to deposit.
     */
    function depositERC20(address token, uint256 amount) external;

     /**
     * @notice query all tracked ERC20 tokens.
     * @return tracked ERC20 tokens.
     */
    function getAllTrackedERC20Tokens() external view returns (address[] memory);

    /**
     * @notice query the token balance of the given token for this address.
     * @param token : the address of the token.
     * @return token balance of this address.
     */
    function balanceOfERC20(address token) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { IERC721Service } from "../token/ERC721/IERC721Service.sol";


/**
 * @title ERC721ServiceFacet interface
 */
interface IERC721ServiceFacetSelector is IERC721Service {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) external returns (bytes4);

     /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param token: the address of tracked token to move
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     * @param data data payload
     */
    function safeTransferERC721From(
        address token,
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external override;

      /**
     * @notice return the current version of ERC721Facet
     */
    function erc721ServiceFacetVersion() external pure returns (string memory);

}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import {IERC721ServiceInternal} from "./IERC721ServiceInternal.sol";

/**
 * @title ERC20Service interface.
 */
interface IERC721Service is IERC721ServiceInternal {
    /**
     * @notice safely transfers `tokenId` token from `from` to `to`.
     * @param token: the address of tracked token to move.
     * @param to: the address of the recipient.
     * @param tokenId: the tokenId to transfer.
     */
    function transferERC721(address token, address to, uint256 tokenId) external;

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable.
     * @param token: the address of tracked token to move.
     * @param from sender of token.
     * @param to receiver of token.
     * @param tokenId token id.
     * @param data data payload.
     */
    function safeTransferERC721From(
        address token,
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable.
     * @param token: the address of tracked token to move.
     * @param from sender of token.
     * @param to receiver of token.
     * @param tokenId token id.
     */
    function safeTransferERC721From(
        address token,
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @notice transfer token between given addresses, without checking for ERC721Receiver implementation if applicable.
     * @param token: the address of tracked token to move.
     * @param from sender of token.
     * @param to receiver of token.
     * @param tokenId token id.
     */
    function transferERC721From(
        address token,
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @notice gives permission to `to` to transfer `tokenId` token to another account.
     * @param token: the address of tracked token to move.
     * @param spender: the address of the spender.
     * @param tokenId: the tokenId to approve.
     */
    function approveERC721(address token, address spender, uint256 tokenId) external;

    /**
     * @notice register a new ERC721 token.
     * @param token: the address of the ERC721 token.
     */
    function registerERC721(address token) external;

    /**
     * @notice remove a new ERC721 token from ERC721Service.
     * @param token: the address of the ERC721 token.
     */
    function removeERC721(address token) external;

     /**
     * @notice deposit a ERC721 token to ERC721Service.
     * @param token: the address of the ERC721 token.
     * @param tokenId: the tokenId of token to deposit.
     */
    function depositERC721(address token, uint256 tokenId) external;

    /**
     * @notice query all tracked ERC721 tokens.
     * @return tracked ERC721  tokens.
     */
    function getAllTrackedERC721Tokens() external view returns (address[] memory);

     /**
     * @notice query the token balance of the given ERC721 token for this address.
     * @param token : the address of the ERC721 token.
     * @return token balance.
     */
    function balanceOfERC721(address token) external view returns (uint256);

    /**
     * @notice query the owner of the `tokenId` token.
     * @param token: the address of tracked token to query.
     * @param tokenId: the tokenId of the token to query.
     *
     */
    function ownerOfERC721(address token, uint256 tokenId) external view returns (address owner);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { IRecovery } from "../recovery/IRecovery.sol";


/**
 * @title RecoveryFacet interface
 */
interface IRecoveryFacet is IRecovery {
    /**
     * @notice return the current version of RecoveryFacet
     */
    function recoveryFacetVersion() external pure returns (string memory);

}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import {IRecoveryInternal} from "./IRecoveryInternal.sol";

/**
 * @title Recovery interface 
 */
interface IRecovery is IRecoveryInternal {
    /**
     * @notice recover the wallet by setting a new owner.
     * @param groupId the group id of the semaphore groups
     * @param signal: semaphore signal
     * @param nullifierHash: nullifier hash
     * @param externalNullifier: external nullifier
     * @param proof: Zero-knowledge proof
     */
    function recover(
        uint256 groupId,
        bytes32 signal,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof,
        address newOwner
    ) external;

    /**
     * @notice reset the recovery
     */
    function resetRecovery() external;

    /**
     * @notice query the status of the recovery
     */
    function getRecoveryStatus() external view returns (RecoveryStatus);

    /**
     * @notice query the majority of the recovery
     */
    function getMajority() external view returns (uint256);

    /**
     * @notice query the nominee of the recovery
     */
    function getRecoveryNominee() external view returns (address);

    /**
     * @notice query the counter of the recovery
     */
    function getRecoveryCounter() external view returns (uint8);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { ISemaphore } from "../semaphore/ISemaphore.sol";

/**
 * @title SemaphoreFacet interface
 */
interface ISemaphoreFacet is ISemaphore {
    /**
     * @notice add Verifiers contracts to the SemaphoreFacet
     * @param _verifiers array of Verifier contracts
     */
    function setVerifiers(Verifier[] memory _verifiers) external;

     /**
     * @notice return the current version of SemaphoreFacet
     */
    function semaphoreFacetVersion() external pure returns (string memory);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IVerifier} from "../interfaces/IVerifier.sol";
import {ISemaphoreInternal} from "./ISemaphoreInternal.sol";

/**
 * @title Semaphore interface
 */
interface ISemaphore is ISemaphoreInternal {
    /**
     * @notice saves the nullifier hash to avoid double signaling and emits an event
     * if the zero-knowledge proof is valid
     * @param groupId: group id of the group
     * @param signal: semaphore signal
     * @param nullifierHash: nullifier hash
     * @param externalNullifier: external nullifier
     * @param proof: Zero-knowledge proof
     */
    function verifyProof(
        uint256 groupId,
        bytes32 signal,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) external;

    /**
     * @notice query the verifier address by merkle tree depth
     */
    function getVerifier(uint8 merkleTreeDepth) external returns (IVerifier);

}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;


/**
 * @title RecoveryFacet interface
 */
interface IEtherServiceFacet {
    /**
     * @notice moves `amount` of ether from the caller's account to `to`.
     * @param to: the payable address of the recipient.
     * @param amount: the amount of tokens to move.
     * @return returns a boolean value indicating whether the operation succeeded.
     */
    function transferEther(address payable to, uint amount) external returns (bool);

    /**
     * @notice return the current version of RecoveryFacet
     */
    function etherServiceFacetVersion() external pure returns (string memory);

    /**
     * @notice return the current balance of this contract
     */
    function getEtherBalance() external view returns (uint);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { IZkWalletDiamondBase} from "./IZkWalletDiamondBase.sol";
import { IWalletFactoryInternal } from "../../../wallet/factory/IWalletFactoryInternal.sol";
import { WalletFactoryStorage} from "../../../wallet/factory/WalletFactoryStorage.sol";

import { SimplicyDiamond } from "../../SimplicyDiamond.sol";

/**
 * @title zkWallet "Diamond" Base proxy reference implementation
 */
abstract contract ZkWalletDiamondBase is
    IZkWalletDiamondBase,
    SimplicyDiamond
{
    function __ZkWalletDiamondBase_init(address owner_) internal {
        __SimplicyDiamond_init(owner_);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title verifier interface.
 */
interface IVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input
    ) external view;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { IVerifier } from "../interfaces/IVerifier.sol";

library SemaphoreStorage {
    struct Layout {
        mapping(uint256 => IVerifier) verifiers;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("simplicy.contracts.storage.Semaphore");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressUtils } from '../utils/AddressUtils.sol';
import { IProxy } from './IProxy.sol';

/**
 * @title Base proxy contract
 */
abstract contract Proxy is IProxy {
    using AddressUtils for address;

    /**
     * @notice delegate all calls to implementation contract
     * @dev reverts if implementation address contains no code, for compatibility with metamorphic contracts
     * @dev memory location in use by assembly may be unsafe in other contexts
     */
    fallback() external payable virtual {
        address implementation = _getImplementation();

        require(
            implementation.isContract(),
            'Proxy: implementation must be contract'
        );

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )
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

    /**
     * @notice get logic implementation address
     * @return implementation address
     */
    function _getImplementation() internal virtual returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressUtils } from '../../../utils/AddressUtils.sol';
import { IDiamondWritable } from '../writable/IDiamondWritable.sol';

/**
 * @dev derived from https://github.com/mudgen/diamond-2 (MIT license)
 */
library DiamondBaseStorage {
    using AddressUtils for address;
    using DiamondBaseStorage for DiamondBaseStorage.Layout;

    struct Layout {
        // function selector => (facet address, selector slot position)
        mapping(bytes4 => bytes32) facets;
        // total number of selectors registered
        uint16 selectorCount;
        // array of selector slots with 8 selectors per slot
        mapping(uint256 => bytes32) selectorSlots;
        address fallbackAddress;
    }

    bytes32 constant CLEAR_ADDRESS_MASK =
        bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.DiamondBase');

    event DiamondCut(
        IDiamondWritable.FacetCut[] facetCuts,
        address target,
        bytes data
    );

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /**
     * @notice update functions callable on Diamond proxy
     * @param l storage layout
     * @param facetCuts array of structured Diamond facet update data
     * @param target optional recipient of initialization delegatecall
     * @param data optional initialization call data
     */
    function diamondCut(
        Layout storage l,
        IDiamondWritable.FacetCut[] memory facetCuts,
        address target,
        bytes memory data
    ) internal {
        unchecked {
            uint256 originalSelectorCount = l.selectorCount;
            uint256 selectorCount = originalSelectorCount;
            bytes32 selectorSlot;

            // Check if last selector slot is not full
            if (selectorCount & 7 > 0) {
                // get last selectorSlot
                selectorSlot = l.selectorSlots[selectorCount >> 3];
            }

            for (uint256 i; i < facetCuts.length; i++) {
                IDiamondWritable.FacetCut memory facetCut = facetCuts[i];
                IDiamondWritable.FacetCutAction action = facetCut.action;

                require(
                    facetCut.selectors.length > 0,
                    'DiamondBase: no selectors specified'
                );

                if (action == IDiamondWritable.FacetCutAction.ADD) {
                    (selectorCount, selectorSlot) = l.addFacetSelectors(
                        selectorCount,
                        selectorSlot,
                        facetCut
                    );
                } else if (action == IDiamondWritable.FacetCutAction.REPLACE) {
                    l.replaceFacetSelectors(facetCut);
                } else if (action == IDiamondWritable.FacetCutAction.REMOVE) {
                    (selectorCount, selectorSlot) = l.removeFacetSelectors(
                        selectorCount,
                        selectorSlot,
                        facetCut
                    );
                }
            }

            if (selectorCount != originalSelectorCount) {
                l.selectorCount = uint16(selectorCount);
            }

            // If last selector slot is not full
            if (selectorCount & 7 > 0) {
                l.selectorSlots[selectorCount >> 3] = selectorSlot;
            }

            emit DiamondCut(facetCuts, target, data);
            initialize(target, data);
        }
    }

    function addFacetSelectors(
        Layout storage l,
        uint256 selectorCount,
        bytes32 selectorSlot,
        IDiamondWritable.FacetCut memory facetCut
    ) internal returns (uint256, bytes32) {
        unchecked {
            require(
                facetCut.target == address(this) ||
                    facetCut.target.isContract(),
                'DiamondBase: ADD target has no code'
            );

            for (uint256 i; i < facetCut.selectors.length; i++) {
                bytes4 selector = facetCut.selectors[i];
                bytes32 oldFacet = l.facets[selector];

                require(
                    address(bytes20(oldFacet)) == address(0),
                    'DiamondBase: selector already added'
                );

                // add facet for selector
                l.facets[selector] =
                    bytes20(facetCut.target) |
                    bytes32(selectorCount);
                uint256 selectorInSlotPosition = (selectorCount & 7) << 5;

                // clear selector position in slot and add selector
                selectorSlot =
                    (selectorSlot &
                        ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) |
                    (bytes32(selector) >> selectorInSlotPosition);

                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    l.selectorSlots[selectorCount >> 3] = selectorSlot;
                    selectorSlot = 0;
                }

                selectorCount++;
            }

            return (selectorCount, selectorSlot);
        }
    }

    function removeFacetSelectors(
        Layout storage l,
        uint256 selectorCount,
        bytes32 selectorSlot,
        IDiamondWritable.FacetCut memory facetCut
    ) internal returns (uint256, bytes32) {
        unchecked {
            require(
                facetCut.target == address(0),
                'DiamondBase: REMOVE target must be zero address'
            );

            uint256 selectorSlotCount = selectorCount >> 3;
            uint256 selectorInSlotIndex = selectorCount & 7;

            for (uint256 i; i < facetCut.selectors.length; i++) {
                bytes4 selector = facetCut.selectors[i];
                bytes32 oldFacet = l.facets[selector];

                require(
                    address(bytes20(oldFacet)) != address(0),
                    'DiamondBase: selector not found'
                );

                require(
                    address(bytes20(oldFacet)) != address(this),
                    'DiamondBase: selector is immutable'
                );

                if (selectorSlot == 0) {
                    selectorSlotCount--;
                    selectorSlot = l.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }

                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;

                // adding a block here prevents stack too deep error
                {
                    // replace selector with last selector in l.facets
                    lastSelector = bytes4(
                        selectorSlot << (selectorInSlotIndex << 5)
                    );

                    if (lastSelector != selector) {
                        // update last selector slot position info
                        l.facets[lastSelector] =
                            (oldFacet & CLEAR_ADDRESS_MASK) |
                            bytes20(l.facets[lastSelector]);
                    }

                    delete l.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }

                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = l.selectorSlots[
                        oldSelectorsSlotCount
                    ];

                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);

                    // update storage with the modified slot
                    l.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    selectorSlot =
                        (selectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }

                if (selectorInSlotIndex == 0) {
                    delete l.selectorSlots[selectorSlotCount];
                    selectorSlot = 0;
                }
            }

            selectorCount = (selectorSlotCount << 3) | selectorInSlotIndex;

            return (selectorCount, selectorSlot);
        }
    }

    function replaceFacetSelectors(
        Layout storage l,
        IDiamondWritable.FacetCut memory facetCut
    ) internal {
        unchecked {
            require(
                facetCut.target.isContract(),
                'DiamondBase: REPLACE target has no code'
            );

            for (uint256 i; i < facetCut.selectors.length; i++) {
                bytes4 selector = facetCut.selectors[i];
                bytes32 oldFacet = l.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));

                require(
                    oldFacetAddress != address(0),
                    'DiamondBase: selector not found'
                );

                require(
                    oldFacetAddress != address(this),
                    'DiamondBase: selector is immutable'
                );

                require(
                    oldFacetAddress != facetCut.target,
                    'DiamondBase: REPLACE target is identical'
                );

                // replace old facet address
                l.facets[selector] =
                    (oldFacet & CLEAR_ADDRESS_MASK) |
                    bytes20(facetCut.target);
            }
        }
    }

    function initialize(address target, bytes memory data) private {
        require(
            (target == address(0)) == (data.length == 0),
            'DiamondBase: invalid initialization parameters'
        );

        if (target != address(0)) {
            if (target != address(this)) {
                require(
                    target.isContract(),
                    'DiamondBase: initialization target has no code'
                );
            }

            (bool success, ) = target.delegatecall(data);

            if (!success) {
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

/**
 * @title Partial Guardian interface needed by internal functions
 */
interface IGuardianInternal {
    enum GuardianStatus
    {
        REMOVE,    // Being removed or removed after validUntil timestamp
        ADD        // Being added or added after validSince timestamp.
    }

    struct GuardianDTO {        
        uint256 hashId;
    }

    /**
     * @notice emitted when a new Guardian is added
     * @param hashId: the hashId of the guardian
     * @param effectiveTime: the timestamp when the guardian is added
     */
    event GuardianAdded(uint256 indexed hashId, uint effectiveTime);


    /**
     * @notice emitted when a Guardian is removed
     * @param hashId: the hashId of the guardian
     * @param effectiveTime: the timestamp when the guardian is added
     */
    event GuardianRemoved (uint256 indexed hashId, uint effectiveTime);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import {SafeCast} from "@solidstate/contracts/utils/SafeCast.sol";

/**
 * @title Guardian Storage base on Diamond Standard Layout storage pattern
 */
library GuardianStorage {
    using SafeCast for uint;

    struct Guardian {
        uint256 hashId;
        uint8 status;
        uint64 timestamp;
    }
    struct Layout {
        // hashId -> guardianIdx
        mapping(uint256 => uint) guardianIndex;

        Guardian[] guardians;
        
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("simplicy.contracts.storage.Guardian");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /**
     * @notice store an new guardian to the storage.
     * @param hashId: the hashId of the guardian.
     * @param validSince: the valid period since the guardian is added.
     * @return returns a boolean value indicating whether the operation succeeded.
     */
    function storeGuardian(
        Layout storage s,
        uint256 hashId,
        uint validSince
    ) internal returns (bool){
        uint arrayIndex = s.guardians.length;
        uint index = arrayIndex + 1;
        s.guardians.push(
            Guardian(
                hashId,
                1,
                validSince.toUint64()
            )
        );
        s.guardianIndex[hashId] = index;
        return true;
    }

    /**
     * @notice delete a guardian from the storage,
     * we are going to switch the last item in the array with the one we are replacing.
     * That way when we pop, we are removing the correct item. 
     *
     * There are two cases we need to handle:
     *  - the address we are removing is not the last address in the array
     *  - or it is the last address in the array. 
     * @param hashId: the hashId of the guardian.
     * @return returns a boolean value indicating whether the operation succeeded. 
     */
     function deleteGuardian(
        Layout storage s,
        uint256 hashId
    ) internal returns (bool) {
        uint index = s.guardianIndex[hashId];
        require(index > 0, "Guardian: GUARDIAN_NOT_EXISTS");

        uint arrayIndex = index - 1;
         require(arrayIndex >= 0, "Guardian: ARRAY_INDEX_OUT_OF_BOUNDS");

        if(arrayIndex != s.guardians.length - 1) {
            s.guardians[arrayIndex] = s.guardians[s.guardians.length - 1];
            s.guardianIndex[s.guardians[arrayIndex].hashId] = index;
        }
        s.guardians.pop();
        delete s.guardianIndex[hashId];
        return true;
    }

    /**
     * @notice delete all guardians from the storage.
     */
    function deleteAllGuardians(Layout storage s) internal {
        uint count = s.guardians.length;

        for(int i = int(count) - 1; i >= 0; i--) {
            uint256 hashId = s.guardians[uint(i)].hashId;
            deleteGuardian(s, hashId);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Helper library for safe casting of uint and int values
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library SafeCast {
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, 'SafeCast: value does not fit');
        return uint224(value);
    }

    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, 'SafeCast: value does not fit');
        return uint128(value);
    }

    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, 'SafeCast: value does not fit');
        return uint96(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, 'SafeCast: value does not fit');
        return uint64(value);
    }

    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, 'SafeCast: value does not fit');
        return uint32(value);
    }

    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, 'SafeCast: value does not fit');
        return uint16(value);
    }

    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, 'SafeCast: value does not fit');
        return uint8(value);
    }

    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, 'SafeCast: value must be positive');
        return uint256(value);
    }

    function toInt128(int256 value) internal pure returns (int128) {
        require(
            value >= type(int128).min && value <= type(int128).max,
            'SafeCast: value does not fit'
        );
        return int128(value);
    }

    function toInt64(int256 value) internal pure returns (int64) {
        require(
            value >= type(int64).min && value <= type(int64).max,
            'SafeCast: value does not fit'
        );
        return int64(value);
    }

    function toInt32(int256 value) internal pure returns (int32) {
        require(
            value >= type(int32).min && value <= type(int32).max,
            'SafeCast: value does not fit'
        );
        return int32(value);
    }

    function toInt16(int256 value) internal pure returns (int16) {
        require(
            value >= type(int16).min && value <= type(int16).max,
            'SafeCast: value does not fit'
        );
        return int16(value);
    }

    function toInt8(int256 value) internal pure returns (int8) {
        require(
            value >= type(int8).min && value <= type(int8).max,
            'SafeCast: value does not fit'
        );
        return int8(value);
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        require(
            value <= uint256(type(int256).max),
            'SafeCast: value does not fit'
        );
        return int256(value);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

/**
 * @title Partial SemaphoreGroups interface needed by internal functions
 */
interface ISemaphoreGroupsInternal {
    struct RemoveMembersDTO {
        uint256 identityCommitment;
        uint256[] proofSiblings;
        uint8[] proofPathIndices;
    }

    /**
     * @notice emitted when a new group is created
     * @param groupId: group id of the group
     * @param depth: depth of the tree
     * @param zeroValue: zero value of the tree
     */
    event GroupCreated(uint256 indexed groupId, uint8 depth, uint256 zeroValue);

    /**
     * @notice emitted when an admin is assigned to a group
     * @param groupId: Id of the group
     * @param oldAdmin: Old admin of the group
     * @param newAdmin: New admin of the group
     */
    event GroupAdminUpdated(
        uint256 indexed groupId,
        address indexed oldAdmin,
        address indexed newAdmin
    );

    /**
     * @notice emitted when a new identity commitment is added
     * @param groupId: group id of the group
     * @param identityCommitment: New identity commitment
     * @param root: New root hash of the tree
     */
    event MemberAdded(
        uint256 indexed groupId,
        uint256 identityCommitment,
        uint256 root
    );

    /**
     * @notice emitted when a new identity commitment is removed
     * @param groupId: group id of the group
     * @param identityCommitment: New identity commitment
     * @param root: New root hash of the tree
     */
    event MemberRemoved(
        uint256 indexed groupId,
        uint256 identityCommitment,
        uint256 root
    );
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

/**
 * @title Partial ERC20Service interface needed by internal functions
 */
interface IERC20ServiceInternal {
    /**
     * @notice emitted when a new ERC20 token is registered
     * @param tokenAddress: the address of the ERC20 token
     */
    event ERC20TokenTracked(address indexed tokenAddress);

    /**
     * @notice emitted when a new ERC20 token is removed
     * @param tokenAddress: the address of the ERC20 token
     */
    event ERC20TokenRemoved(address tokenAddress); 

    /**
     * @notice emitted when a ERC20 token is deposited.
     * @param tokenAddress: the address of the ERC20 token.
     * @param amount: the amount of token deposited.
     */
    event ERC20Deposited(address indexed tokenAddress, uint256 amount);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

/**
 * @title Partial ERC721Service interface needed by internal functions
 */
interface IERC721ServiceInternal {
    /**
     * @notice emitted when a new ERC721 token is registered
     * @param tokenAddress: the address of the ERC721 token
     */
    event ERC721TokenTracked(address indexed tokenAddress);

    /**
     * @notice emitted when a new ERC721 token is removed
     * @param tokenAddress: the address of the ERC721 token
     */
    event ERC721TokenRemoved(address indexed tokenAddress); 

     /**
     * @notice emitted when a ERC721 token is deposited.
     * @param tokenAddress: the address of the ERC721 token.
     * @param tokenId: the tokenId of token deposited.
     */
    event ERC721Deposited(address indexed tokenAddress, uint256 tokenId);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

/**
 * @title Partial Recovery interface needed by internal functions
 */
interface IRecoveryInternal {
    enum RecoveryStatus {
        NONE,
        PENDING,
        ACCEPTED,
        REJECTED
    }

    /**
     * @notice emitted when a wallet is recoverd
     * @param newOwner: the address of the new owner
     */
    event Recovered(address newOwner);

    /**
     * @notice emitted when _recovery is called.
     * @param status: the new status of the recovery.
     * @param majority: the majority amount of the recovery.
     * @param nominee: the nominee address of the recovery.
     */
    event RecoveryUpdated(RecoveryStatus status, uint256 majority, address nominee, uint8 counter);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title Partial Semaphore interface needed by internal functions
 */
interface ISemaphoreInternal {
    struct Verifier {
        address contractAddress;
        uint8 merkleTreeDepth;
    }
    
    /**
     * @notice emitted when a Semaphore proof is verified
     * @param signal: semaphore signal
     */
    event ProofVerified(uint256 indexed groupId, bytes32 signal);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { IOwnable, Ownable, OwnableInternal, OwnableStorage } from "@solidstate/contracts/access/ownable/Ownable.sol";
import { ISafeOwnable, SafeOwnable } from "@solidstate/contracts/access/ownable/SafeOwnable.sol";
import { IERC173 } from "@solidstate/contracts/access/IERC173.sol";
import { ERC165, IERC165, ERC165Storage } from "@solidstate/contracts/introspection/ERC165.sol";
import { DiamondBase, DiamondBaseStorage } from "@solidstate/contracts/proxy/diamond/base/DiamondBase.sol";
import { DiamondReadable, IDiamondReadable } from "@solidstate/contracts/proxy/diamond/readable/DiamondReadable.sol";
import { DiamondWritable, IDiamondWritable } from "@solidstate/contracts/proxy/diamond/writable/DiamondWritable.sol";
import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";

/**
 * @title SolidState "Diamond" proxy reference implementation
 */
abstract contract SimplicyDiamond is
    ISolidStateDiamond,
    DiamondBase,
    DiamondReadable,
    DiamondWritable,
    SafeOwnable,
    ERC165
{
    using DiamondBaseStorage for DiamondBaseStorage.Layout;
    using ERC165Storage for ERC165Storage.Layout;
    using OwnableStorage for OwnableStorage.Layout;

    function __SimplicyDiamond_init(address owner_) internal {
        ERC165Storage.Layout storage erc165 = ERC165Storage.layout();
        bytes4[] memory selectors = new bytes4[](12);

        // register DiamondWritable

        selectors[0] = IDiamondWritable.diamondCut.selector;

        erc165.setSupportedInterface(type(IDiamondWritable).interfaceId, true);

        // register DiamondReadable

        selectors[1] = IDiamondReadable.facets.selector;
        selectors[2] = IDiamondReadable.facetFunctionSelectors.selector;
        selectors[3] = IDiamondReadable.facetAddresses.selector;
        selectors[4] = IDiamondReadable.facetAddress.selector;

        erc165.setSupportedInterface(type(IDiamondReadable).interfaceId, true);

        // register ERC165

        selectors[5] = IERC165.supportsInterface.selector;

        erc165.setSupportedInterface(type(IERC165).interfaceId, true);

        // register SafeOwnable

        selectors[6] = Ownable.owner.selector;
        selectors[7] = SafeOwnable.nomineeOwner.selector;
        selectors[8] = Ownable.transferOwnership.selector;
        selectors[9] = SafeOwnable.acceptOwnership.selector;

        erc165.setSupportedInterface(type(IERC173).interfaceId, true);

        // register Diamond

        selectors[10] = SimplicyDiamond.getFallbackAddress.selector;
        selectors[11] = SimplicyDiamond.setFallbackAddress.selector;

        // diamond cut

        FacetCut[] memory facetCuts = new FacetCut[](1);

        facetCuts[0] = FacetCut({
            target: address(this),
            action: IDiamondWritable.FacetCutAction.ADD,
            selectors: selectors
        });

        DiamondBaseStorage.layout().diamondCut(facetCuts, address(0), "");

        // set owner
        OwnableStorage.layout().setOwner(owner_);
    }

    receive() external payable {}

    /**
     * @inheritdoc ISolidStateDiamond
     */
    function getFallbackAddress() external view returns (address) {
        return DiamondBaseStorage.layout().fallbackAddress;
    }

    /**
     * @inheritdoc ISolidStateDiamond
     */
    function setFallbackAddress(address fallbackAddress) external onlyOwner {
        DiamondBaseStorage.layout().fallbackAddress = fallbackAddress;
    }

    function _transferOwnership(address account)
        internal
        virtual
        override(OwnableInternal, SafeOwnable)
    {
        super._transferOwnership(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC173 } from '../IERC173.sol';
import { IOwnable } from './IOwnable.sol';
import { OwnableInternal } from './OwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

/**
 * @title Ownership access control based on ERC173
 */
abstract contract Ownable is IOwnable, OwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;

    /**
     * @inheritdoc IERC173
     */
    function owner() public view virtual returns (address) {
        return _owner();
    }

    /**
     * @inheritdoc IERC173
     */
    function transferOwnership(address account) public virtual onlyOwner {
        _transferOwnership(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Ownable, OwnableStorage } from './Ownable.sol';
import { ISafeOwnable } from './ISafeOwnable.sol';
import { OwnableInternal } from './OwnableInternal.sol';
import { SafeOwnableInternal } from './SafeOwnableInternal.sol';

/**
 * @title Ownership access control based on ERC173 with ownership transfer safety check
 */
abstract contract SafeOwnable is ISafeOwnable, Ownable, SafeOwnableInternal {
    /**
     * @inheritdoc ISafeOwnable
     */
    function nomineeOwner() public view virtual returns (address) {
        return _nomineeOwner();
    }

    /**
     * @inheritdoc ISafeOwnable
     */
    function acceptOwnership() public virtual onlyNomineeOwner {
        _acceptOwnership();
    }

    function _transferOwnership(address account)
        internal
        virtual
        override(OwnableInternal, SafeOwnableInternal)
    {
        super._transferOwnership(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { DiamondBaseStorage } from '../base/DiamondBaseStorage.sol';
import { IDiamondReadable } from './IDiamondReadable.sol';

/**
 * @title EIP-2535 "Diamond" proxy introspection contract
 * @dev derived from https://github.com/mudgen/diamond-2 (MIT license)
 */
abstract contract DiamondReadable is IDiamondReadable {
    /**
     * @inheritdoc IDiamondReadable
     */
    function facets() external view returns (Facet[] memory diamondFacets) {
        DiamondBaseStorage.Layout storage l = DiamondBaseStorage.layout();

        diamondFacets = new Facet[](l.selectorCount);

        uint8[] memory numFacetSelectors = new uint8[](l.selectorCount);
        uint256 numFacets;
        uint256 selectorIndex;

        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < l.selectorCount; slotIndex++) {
            bytes32 slot = l.selectorSlots[slotIndex];

            for (
                uint256 selectorSlotIndex;
                selectorSlotIndex < 8;
                selectorSlotIndex++
            ) {
                selectorIndex++;

                if (selectorIndex > l.selectorCount) {
                    break;
                }

                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address facet = address(bytes20(l.facets[selector]));

                bool continueLoop;

                for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                    if (diamondFacets[facetIndex].target == facet) {
                        diamondFacets[facetIndex].selectors[
                            numFacetSelectors[facetIndex]
                        ] = selector;
                        // probably will never have more than 256 functions from one facet contract
                        require(numFacetSelectors[facetIndex] < 255);
                        numFacetSelectors[facetIndex]++;
                        continueLoop = true;
                        break;
                    }
                }

                if (continueLoop) {
                    continue;
                }

                diamondFacets[numFacets].target = facet;
                diamondFacets[numFacets].selectors = new bytes4[](
                    l.selectorCount
                );
                diamondFacets[numFacets].selectors[0] = selector;
                numFacetSelectors[numFacets] = 1;
                numFacets++;
            }
        }

        for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
            uint256 numSelectors = numFacetSelectors[facetIndex];
            bytes4[] memory selectors = diamondFacets[facetIndex].selectors;

            // setting the number of selectors
            assembly {
                mstore(selectors, numSelectors)
            }
        }

        // setting the number of facets
        assembly {
            mstore(diamondFacets, numFacets)
        }
    }

    /**
     * @inheritdoc IDiamondReadable
     */
    function facetFunctionSelectors(address facet)
        external
        view
        returns (bytes4[] memory selectors)
    {
        DiamondBaseStorage.Layout storage l = DiamondBaseStorage.layout();

        selectors = new bytes4[](l.selectorCount);

        uint256 numSelectors;
        uint256 selectorIndex;

        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < l.selectorCount; slotIndex++) {
            bytes32 slot = l.selectorSlots[slotIndex];

            for (
                uint256 selectorSlotIndex;
                selectorSlotIndex < 8;
                selectorSlotIndex++
            ) {
                selectorIndex++;

                if (selectorIndex > l.selectorCount) {
                    break;
                }

                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));

                if (facet == address(bytes20(l.facets[selector]))) {
                    selectors[numSelectors] = selector;
                    numSelectors++;
                }
            }
        }

        // set the number of selectors in the array
        assembly {
            mstore(selectors, numSelectors)
        }
    }

    /**
     * @inheritdoc IDiamondReadable
     */
    function facetAddresses()
        external
        view
        returns (address[] memory addresses)
    {
        DiamondBaseStorage.Layout storage l = DiamondBaseStorage.layout();

        addresses = new address[](l.selectorCount);
        uint256 numFacets;
        uint256 selectorIndex;

        for (uint256 slotIndex; selectorIndex < l.selectorCount; slotIndex++) {
            bytes32 slot = l.selectorSlots[slotIndex];

            for (
                uint256 selectorSlotIndex;
                selectorSlotIndex < 8;
                selectorSlotIndex++
            ) {
                selectorIndex++;

                if (selectorIndex > l.selectorCount) {
                    break;
                }

                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address facet = address(bytes20(l.facets[selector]));

                bool continueLoop;

                for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                    if (facet == addresses[facetIndex]) {
                        continueLoop = true;
                        break;
                    }
                }

                if (continueLoop) {
                    continue;
                }

                addresses[numFacets] = facet;
                numFacets++;
            }
        }

        // set the number of facet addresses in the array
        assembly {
            mstore(addresses, numFacets)
        }
    }

    /**
     * @inheritdoc IDiamondReadable
     */
    function facetAddress(bytes4 selector)
        external
        view
        returns (address facet)
    {
        facet = address(bytes20(DiamondBaseStorage.layout().facets[selector]));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ISafeOwnableInternal } from './ISafeOwnableInternal.sol';
import { OwnableInternal } from './OwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';
import { SafeOwnableStorage } from './SafeOwnableStorage.sol';

abstract contract SafeOwnableInternal is ISafeOwnableInternal, OwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;
    using SafeOwnableStorage for SafeOwnableStorage.Layout;

    modifier onlyNomineeOwner() {
        require(
            msg.sender == _nomineeOwner(),
            'SafeOwnable: sender must be nominee owner'
        );
        _;
    }

    /**
     * @notice get the nominated owner who has permission to call acceptOwnership
     */
    function _nomineeOwner() internal view virtual returns (address) {
        return SafeOwnableStorage.layout().nomineeOwner;
    }

    /**
     * @notice accept transfer of contract ownership
     */
    function _acceptOwnership() internal virtual {
        OwnableStorage.Layout storage l = OwnableStorage.layout();
        emit OwnershipTransferred(l.owner, msg.sender);
        l.setOwner(msg.sender);
        SafeOwnableStorage.layout().setNomineeOwner(address(0));
    }

    /**
     * @notice set nominee owner, granting permission to call acceptOwnership
     */
    function _transferOwnership(address account) internal virtual override {
        SafeOwnableStorage.layout().setNomineeOwner(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnableInternal } from './IOwnableInternal.sol';

interface ISafeOwnableInternal is IOwnableInternal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeOwnableStorage {
    struct Layout {
        address nomineeOwner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.SafeOwnable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setNomineeOwner(Layout storage l, address nomineeOwner) internal {
        l.nomineeOwner = nomineeOwner;
    }
}