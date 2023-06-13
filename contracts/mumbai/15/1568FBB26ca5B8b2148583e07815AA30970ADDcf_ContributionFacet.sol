// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../libraries/LibAppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibCards.sol";
import "../libraries/LibProjects.sol";

contract ContributionFacet is Modifiers {
    AppStorage s;

    struct CreateContributionArgsStruct {
        uint256 projectId;
        string asset;
        string category;
    }

//    struct ContributionStruct {
//        uint256 tokenId;
//        uint256 createdAt;
//        uint256 mintedAt;
//        uint256 projectId;
//        string projectDisplayName;
//        string projectName;
//        string projectImageCID;
//        string category;
//        string asset;
//        address createdBy;
//        address mintedBy;
//    }
//
//    struct ContributionUserStruct {
//        address walletAddress;
//        address mintedBy;
//        uint256 mintedAt;
//        bool isMinted;
//    }
//
//    struct UserContributionStruct {
//        uint256 tokenId;
//        uint256 createdAt;
//        uint256 mintedAt;
//        uint256 projectId;
//        string projectDisplayName;
//        string projectName;
//        string projectImageCID;
//        string category;
//        string asset;
//        address createdBy;
//        address mintedBy;
//    }
//
//    struct ProjectContributionStruct {
//        uint256 tokenId;
//        uint256 createdAt;
//        uint256 projectId;
//        string projectDisplayName;
//        string projectName;
//        string projectImageCID;
//        string category;
//        string asset;
//        address createdBy;
//    }

    function createContribution(CreateContributionArgsStruct calldata _args) external payable onlyTrustedForwarder {
        address msgSender = LibERC2771Context.msgSender();
        require(LibProjects.getAdminByProjectId(_args.projectId, msgSender) == 1, "ContributionFacet: Not authorized");

        ++s.userExecutionCount[msgSender]["createCard"];

        uint256 tokenId = LibCards.currentCardId();
        LibCards.incrementCardId();

        s.cardMetadata[tokenId] = MetadataStruct({
            cardId: tokenId,
            projectId: _args.projectId,
            createdAt: block.timestamp,
            name: "",
            imageCID: "",
            description: "",
            role: "",
            category: _args.category,
            twitter: "",
            opensea: "",
            discord: "",
            createdBy: msgSender,
            asset: _args.asset
        });
        s.userLatestCardId[msgSender] = tokenId;
        s.projectCardIds[_args.projectId].push(tokenId);
    }

//    function getCreatedContributionTokenId(address _walletAddress) external view returns (uint256) {
//        return s.userLatestCardId[_walletAddress];
//    }

//    function getContribution(uint256 _tokenId, address _walletAddress) external view returns (ContributionStruct memory) {
//        MetadataStruct memory metadata = s.cardMetadata[_tokenId];
//        return ContributionStruct({
//            tokenId: metadata.cardId,
//            createdAt: metadata.createdAt,
//            mintedAt: s.mintDetails[_walletAddress][metadata.cardId].mintedAt,
//            projectId: metadata.projectId,
//            projectDisplayName: s.projects[metadata.projectId].displayName,
//            projectName: s.projects[metadata.projectId].name,
//            projectImageCID: s.projects[metadata.projectId].imageCID,
//            category: metadata.category,
//            asset: metadata.asset,
//            createdBy: metadata.createdBy,
//            mintedBy: s.mintDetails[_walletAddress][metadata.cardId].mintedBy
//        });
//    }

//    function getContributionUsers(uint256 _tokenId) external view returns (ContributionUserStruct[] memory) {
//        address[] memory users = s.cardUsers[_tokenId];
//        uint256 count = users.length;
//        ContributionUserStruct[] memory contributionUsers = new ContributionUserStruct[](count);
//
//        for (uint256 i; i < count; ) {
//            address user = users[i];
//            MintDetailStruct memory mintDetail = s.mintDetails[user][_tokenId];
//            contributionUsers[i] = ContributionUserStruct({
//                walletAddress: user,
//                mintedBy: mintDetail.mintedBy,
//                mintedAt: mintDetail.mintedAt,
//                isMinted: mintDetail.isMinted == 1
//            });
//            unchecked {
//                ++i;
//            }
//        }
//
//        return contributionUsers;
//    }

//    function getUserContributions(address _walletAddress) external view returns (UserContributionStruct[] memory) {
//        uint256[] memory userTokenIds = s.userCardsIds[_walletAddress];
//        uint256 count = userTokenIds.length;
//        UserContributionStruct[] memory userContributions = new UserContributionStruct[](count);
//
//        for (uint256 i; i < count; ) {
//            MetadataStruct memory userContribution = s.cardMetadata[userTokenIds[i]];
//            MintDetailStruct memory mintDetail = s.mintDetails[_walletAddress][userTokenIds[i]];
//            userContributions[i] = UserContributionStruct({
//                tokenId: userContribution.cardId,
//                createdAt: userContribution.createdAt,
//                mintedAt: mintDetail.mintedAt,
//                projectId: userContribution.projectId,
//                projectDisplayName: s.projects[userContribution.projectId].displayName,
//                projectName: s.projects[userContribution.projectId].name,
//                projectImageCID: s.projects[userContribution.projectId].imageCID,
//                category: userContribution.category,
//                asset: userContribution.asset,
//                createdBy: userContribution.createdBy,
//                mintedBy: mintDetail.mintedBy
//            });
//            unchecked {
//                ++i;
//            }
//        }
//
//        return userContributions;
//    }

//    function getProjectContributions(uint256 _projectId) external view returns (ProjectContributionStruct[] memory) {
//        uint256[] memory projectTokenIds = s.projectCardIds[_projectId];
//        uint256 count = projectTokenIds.length;
//        ProjectContributionStruct[] memory projectContributions = new ProjectContributionStruct[](count);
//
//        for (uint256 i; i < count; ) {
//            MetadataStruct memory projectContribution = s.cardMetadata[projectTokenIds[i]];
//            projectContributions[i] = ProjectContributionStruct({
//                tokenId: projectContribution.cardId,
//                createdAt: projectContribution.createdAt,
//                projectId: projectContribution.projectId,
//                projectDisplayName: s.projects[projectContribution.projectId].displayName,
//                projectName: s.projects[projectContribution.projectId].name,
//                projectImageCID: s.projects[projectContribution.projectId].imageCID,
//                category: projectContribution.category,
//                asset: projectContribution.asset,
//                createdBy: projectContribution.createdBy
//            });
//            unchecked {
//                ++i;
//            }
//        }
//
//        return projectContributions;
//    }

    function setKeyChainImageCID(string calldata _keyChainImageCID) external {
        LibDiamond.enforceIsContractOwner();
        s.keyChainImageCID = _keyChainImageCID;
    }

    function keyChainImageCID() external view returns (string memory) {
        return s.keyChainImageCID;
    }

    function setKeyChainAnimationCID(string calldata _keyChainAnimationCID) external {
        LibDiamond.enforceIsContractOwner();
        s.keyChainAnimationCID = _keyChainAnimationCID;
    }

    function keyChainAnimationCID() external view returns (string memory) {
        return s.keyChainAnimationCID;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamond {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {IDiamond} from "./IDiamond.sol";

interface IDiamondCut is IDiamond {
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./LibERC2771Context.sol";

struct AppStorage {
    string cardName;
    string cardSymbol;
    string cardImageCID;
    string cardAnimationCID;
    // Mapping from card id to card info
    mapping(uint256 => MetadataStruct) cardMetadata;
    // Mapping from card id to user address
    mapping(uint256 => address[]) cardUsers;
    // Mapping from project id to card ids
    mapping(uint256 => uint256[]) projectCardIds;
    // Mapping from wallet address to last created card id
    mapping(address => uint256) userLatestCardId;
    // Mapping from user address to card ids
    mapping(address => uint256[]) userCardsIds;
    mapping(address => mapping(uint256 => MintDetailStruct)) mintDetails;
    // Mapping from project id to project info
    mapping(uint256 => ProjectStruct) projects;
    // Mapping from project name to project id
    mapping(string => uint256) projectMapping;
    // Mapping from user address to project ids
    mapping(address => uint256[]) userProjects;
    mapping(address => mapping(uint256 => ExistStruct)) userProjectExists;
    // Mapping from project id to user address
    mapping(uint256 => address[]) projectUsers;
    mapping(uint256 => mapping(address => ExistStruct)) projectUserExists;
    // Mapping from project id to user admin
    mapping(uint256 => mapping(address => uint256)) operatorAdmins;
    // Mapping from user address to method execution count
    mapping(address => mapping(string => uint256)) userExecutionCount;
    string keyChainImageCID;
    string keyChainAnimationCID;
}

struct MetadataStruct {
    uint256 cardId;
    uint256 projectId;
    uint256 createdAt;
    string name;
    string imageCID;
    string description;
    string role;
    string category;
    string twitter;
    string opensea;
    string discord;
    address createdBy;
    string asset;
}

struct ProjectStruct {
    uint256 id;
    string name;
    string imageCID;
    string description;
    address createdBy;
    string displayName;
    string website;
    string twitter;
    string discord;
}

struct MintDetailStruct {
    uint256 isMinted;
    uint256 index; // NOTE: Start at one.
    uint256 mintedAt;
    address mintedBy;
}

struct ExistStruct {
    uint256 isExisted;
    uint256 index; // NOTE: Start at one.
}

library LibAppStorage {
    function appStorage() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }

    function getUserExecutionCount(address _user, string calldata _functionName) internal view returns (uint256) {
        return appStorage().userExecutionCount[_user][_functionName];
    }
}

contract Modifiers {
    modifier onlyTrustedForwarder() {
        require(LibERC2771Context.isTrustedForwarder(msg.sender), "ERC2771Context: caller is not a trusted forwarder");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Counters.sol";

library LibCards {
    using Counters for Counters.Counter;

    bytes32 constant CARDS_STORAGE_POSITION = keccak256("diamond.standard.cards.storage");

    struct CardsStorage {
        Counters.Counter cardIds;
        Counters.Counter mintedCount;
        uint256 cardLimit;
    }

    function cardsStorage() internal pure returns (CardsStorage storage cs) {
        bytes32 position = CARDS_STORAGE_POSITION;
        assembly {
            cs.slot := position
        }
    }

    function incrementCardId() internal {
        CardsStorage storage cs = cardsStorage();
        cs.cardIds.increment();
    }

    function currentCardId() internal view returns (uint256) {
        return cardsStorage().cardIds.current();
    }

    function setCardLimit(uint256 _limit) internal {
        CardsStorage storage cs = cardsStorage();
        cs.cardLimit = _limit;
    }

    function cardLimit() internal view returns (uint256) {
        return cardsStorage().cardLimit;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library LibContext {
    function msgSender() internal view returns (address) {
        return msg.sender;
    }

    function msgData() internal pure returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamond} from "../interfaces/IDiamond.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import "./LibERC2771Context.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error NoSelectorsGivenToAdd();
error NotContractOwner(address _user, address _contractOwner);
error NoSelectorsProvidedForFacetForCut(address _facetAddress);
error CannotAddSelectorsToZeroAddress(bytes4[] _selectors);
error NoBytecodeAtAddress(address _contractAddress, string _message);
error IncorrectFacetCutAction(uint8 _action);
error CannotAddFunctionToDiamondThatAlreadyExists(bytes4 _selector);
error CannotReplaceFunctionsFromFacetWithZeroAddress(bytes4[] _selectors);
error CannotReplaceImmutableFunction(bytes4 _selector);
error CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(bytes4 _selector);
error CannotReplaceFunctionThatDoesNotExists(bytes4 _selector);
error RemoveFacetAddressMustBeZeroAddress(address _facetAddress);
error CannotRemoveFunctionThatDoesNotExist(bytes4 _selector);
error CannotRemoveImmutableFunction(bytes4 _selector);
error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
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

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        if (LibERC2771Context.msgSender() != diamondStorage().contractOwner) {
            revert NotContractOwner(LibERC2771Context.msgSender(), diamondStorage().contractOwner);
        }
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            bytes4[] memory functionSelectors = _diamondCut[facetIndex].functionSelectors;
            address facetAddress = _diamondCut[facetIndex].facetAddress;
            if (functionSelectors.length == 0) {
                revert NoSelectorsProvidedForFacetForCut(facetAddress);
            }
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamond.FacetCutAction.Add) {
                addFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamond.FacetCutAction.Replace) {
                replaceFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamond.FacetCutAction.Remove) {
                removeFunctions(facetAddress, functionSelectors);
            } else {
                revert IncorrectFacetCutAction(uint8(action));
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_facetAddress == address(0)) {
            revert CannotAddSelectorsToZeroAddress(_functionSelectors);
        }
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Add facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            if (oldFacetAddress != address(0)) {
                revert CannotAddFunctionToDiamondThatAlreadyExists(selector);
            }
            ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(
                _facetAddress,
                selectorCount
            );
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        DiamondStorage storage ds = diamondStorage();
        if (_facetAddress == address(0)) {
            revert CannotReplaceFunctionsFromFacetWithZeroAddress(_functionSelectors);
        }
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Replace facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            // can't replace immutable functions -- functions defined directly in the diamond in this case
            if (oldFacetAddress == address(this)) {
                revert CannotReplaceImmutableFunction(selector);
            }
            if (oldFacetAddress == _facetAddress) {
                revert CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(selector);
            }
            if (oldFacetAddress == address(0)) {
                revert CannotReplaceFunctionThatDoesNotExists(selector);
            }
            // replace old facet address
            ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        if (_facetAddress != address(0)) {
            revert RemoveFacetAddressMustBeZeroAddress(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition = ds
                .facetAddressAndSelectorPosition[selector];
            if (oldFacetAddressAndSelectorPosition.facetAddress == address(0)) {
                revert CannotRemoveFunctionThatDoesNotExist(selector);
            }

            // can't remove immutable functions -- functions defined directly in the diamond
            if (oldFacetAddressAndSelectorPosition.facetAddress == address(this)) {
                revert CannotRemoveImmutableFunction(selector);
            }
            // replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition = oldFacetAddressAndSelectorPosition
                    .selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize == 0) {
            revert NoBytecodeAtAddress(_contract, _errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./LibContext.sol";

library LibERC2771Context {
    bytes32 constant CONTEXT_STORAGE_POSITION = keccak256("diamond.standard.context.storage");

    struct ContextStorage {
        mapping(address => uint256) trustedForwarders;
    }

    function contextStorage() internal pure returns (ContextStorage storage cs) {
        bytes32 position = CONTEXT_STORAGE_POSITION;
        assembly {
            cs.slot := position
        }
    }

    function updateTrustedForwarder(address _trustedForwarder, bool _isTrusted) internal {
        ContextStorage storage cs = contextStorage();
        cs.trustedForwarders[_trustedForwarder] = _isTrusted ? 1 : 2;
    }

    function isTrustedForwarder(address _forwarder) internal view returns (bool) {
        return contextStorage().trustedForwarders[_forwarder] == 1;
    }

    function msgSender() internal view returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return LibContext.msgSender();
        }
    }

    function msgData() internal view returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return LibContext.msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./LibAppStorage.sol";
import "./LibCards.sol";
import "./LibERC2771Context.sol";

struct ReturnProjectStruct {
    uint256 id;
    string name;
    string imageCID;
    string description;
    address createdBy;
    bool canCreateCard;
    string displayName;
    string website;
    string twitter;
    string discord;
}

library LibProjects {
    using Counters for Counters.Counter;

    bytes32 constant PROJECTS_STORAGE_POSITION = keccak256("diamond.standard.projects.storage");

    struct ProjectsStorage {
        Counters.Counter projectId;
    }

    function projectsStorage() internal pure returns (ProjectsStorage storage ps) {
        bytes32 position = PROJECTS_STORAGE_POSITION;
        assembly {
            ps.slot := position
        }
    }

    function appStorage() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }

    function incrementProjectId() internal {
        ProjectsStorage storage ps = projectsStorage();
        ps.projectId.increment();
    }

    function currentProjectId() internal view returns (uint256) {
        return projectsStorage().projectId.current();
    }

    function getProjectById(uint256 _projectId) internal view returns (ReturnProjectStruct memory) {
        ProjectStruct memory project = appStorage().projects[_projectId];
        return
            ReturnProjectStruct({
                id: project.id,
                name: project.name,
                imageCID: project.imageCID,
                description: project.description,
                createdBy: project.createdBy,
                canCreateCard: appStorage().projectCardIds[_projectId].length < LibCards.cardLimit(),
                displayName: project.displayName,
                website: project.website,
                twitter: project.twitter,
                discord: project.discord
            });
    }

    function getAdminByProjectId(uint256 _projectId, address _walletAddress) internal view returns (uint256) {
        return appStorage().operatorAdmins[_projectId][_walletAddress];
    }

    function addUsersToProject(uint256 _projectId, address[] calldata _addressList) internal {
        AppStorage storage s = appStorage();

        require(s.operatorAdmins[_projectId][LibERC2771Context.msgSender()] == 1, "LibProjects: Not authorized");

        uint256 count = _addressList.length;
        for (uint256 i; i < count; ) {
            address walletAddress = _addressList[i];

            if (s.projectUserExists[_projectId][walletAddress].isExisted != 1) {
                if (s.projectUserExists[_projectId][walletAddress].index == 0) {
                    s.projectUsers[_projectId].push(walletAddress);
                    s.projectUserExists[_projectId][walletAddress] = ExistStruct({
                        isExisted: 1,
                        index: s.projectUsers[_projectId].length
                    });
                } else {
                    s.projectUsers[_projectId][
                        s.projectUserExists[_projectId][walletAddress].index - 1
                    ] = walletAddress;
                    s.projectUserExists[_projectId][walletAddress].isExisted = 1;
                }

                s.operatorAdmins[_projectId][walletAddress] = 2;
            }

            if (s.userProjectExists[walletAddress][_projectId].isExisted != 1) {
                if (s.userProjectExists[walletAddress][_projectId].index == 0) {
                    s.userProjects[walletAddress].push(_projectId);
                    s.userProjectExists[walletAddress][_projectId] = ExistStruct({
                        isExisted: 1,
                        index: s.userProjects[walletAddress].length
                    });
                } else {
                    s.userProjects[walletAddress][
                        s.userProjectExists[walletAddress][_projectId].index - 1
                    ] = _projectId;
                    s.userProjectExists[walletAddress][_projectId].isExisted = 1;
                }
            }
            unchecked {
                ++i;
            }
        }
    }
}