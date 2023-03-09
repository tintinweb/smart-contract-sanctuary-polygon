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
pragma solidity ^0.8.17;

import "../libraries/LibAppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibERC2771Context.sol";
import "../libraries/LibCards.sol";
import "../libraries/LibProjects.sol";

struct CreateCardArgsStruct {
    uint256 projectId;
    string name;
    string imageCID;
    string animationCID;
    string description;
    string role;
    string category;
    string twitter;
    string opensea;
    string discord;
}

struct CardStruct {
    uint256 tokenId;
    uint256 createdAt;
    uint256 projectId;
    string projectName;
    string projectImageUrl;
    string name;
    string imageCID;
    string description;
    string role;
    string category;
    string twitter;
    string opensea;
    string discord;
    address createdBy;
}

struct CardUserStruct {
    address walletAddress;
    bool isMinted;
    uint256 mintedAt;
}

struct UserCardStruct {
    uint256 tokenId;
    uint256 createdAt;
    uint256 mintedAt;
    uint256 projectId;
    string projectName;
    string projectImageUrl;
    string name;
    string imageCID;
    string description;
    string role;
    string category;
    string twitter;
    string opensea;
    string discord;
    address createdBy;
    address mintedBy;
}

contract CardsFacet is Modifiers {
    LibAppStorage s;

    function createCard(CreateCardArgsStruct calldata _args) external onlyTrustedForwarder {
        require(
            LibProjects.getAdminByProjectId(_args.projectId, LibERC2771Context.msgSender()) == 1,
            "CardsFacet: Not authorized"
        );

        require(s.projectCardIds[_args.projectId].length < LibCards.cardLimit(), "CardsFacet: Card limit reached");

        uint256 tokenId = LibCards.currentTokenId();

        s.tokenMetadata[tokenId] = MetadataStruct({
            tokenId: tokenId,
            projectId: _args.projectId,
            createdAt: block.timestamp,
            name: _args.name,
            imageCID: _args.imageCID,
            animationCID: _args.animationCID,
            description: _args.description,
            role: _args.role,
            category: _args.category,
            twitter: _args.twitter,
            opensea: _args.opensea,
            discord: _args.discord,
            createdBy: LibERC2771Context.msgSender()
        });
        s.userLatestTokenId[LibERC2771Context.msgSender()] = tokenId;
        s.projectCardIds[_args.projectId].push(tokenId);

        LibCards.incrementTokenId();
    }

    function getCreatedTokenId(address _walletAddress) external view returns (uint256) {
        return s.userLatestTokenId[_walletAddress];
    }

    function getCard(uint256 tokenId_) external view returns (CardStruct memory) {
        MetadataStruct memory card = s.tokenMetadata[tokenId_];
        return
            CardStruct({
                tokenId: card.tokenId,
                createdAt: card.createdAt,
                projectId: card.projectId,
                projectName: s.projects[card.projectId].name,
                projectImageUrl: s.projects[card.projectId].imageUrl,
                name: card.name,
                imageCID: card.imageCID,
                description: card.description,
                role: card.role,
                category: card.category,
                twitter: card.twitter,
                opensea: card.opensea,
                discord: card.discord,
                createdBy: card.createdBy
            });
    }

    function getCardUsers(uint256 tokenId_) external view returns (CardUserStruct[] memory) {
        address[] memory users = s.cardUsers[tokenId_];
        uint256 count = users.length;
        CardUserStruct[] memory cardUsers = new CardUserStruct[](count);

        for (uint256 i; i < count; ) {
            address user = users[i];
            MintDetailStruct memory mintDetail = s.mintDetails[user][tokenId_];
            cardUsers[i] = CardUserStruct({
                walletAddress: user,
                isMinted: mintDetail.isMinted == 1,
                mintedAt: mintDetail.mintedAt
            });
            unchecked {
                ++i;
            }
        }

        return cardUsers;
    }

    function getUserCards(address _walletAddress) external view returns (UserCardStruct[] memory) {
        uint256[] memory userCardIds = s.userCardsIds[_walletAddress];
        uint256 count = userCardIds.length;
        UserCardStruct[] memory userCards = new UserCardStruct[](count);

        for (uint256 i; i < count; ) {
            MetadataStruct memory userCard = s.tokenMetadata[userCardIds[i]];
            MintDetailStruct memory mintDetail = s.mintDetails[_walletAddress][userCardIds[i]];
            userCards[i] = UserCardStruct({
                tokenId: userCard.tokenId,
                createdAt: userCard.createdAt,
                mintedAt: mintDetail.mintedAt,
                projectId: userCard.projectId,
                projectName: s.projects[userCard.projectId].name,
                projectImageUrl: s.projects[userCard.projectId].imageUrl,
                name: userCard.name,
                imageCID: userCard.imageCID,
                description: userCard.description,
                role: userCard.role,
                category: userCard.category,
                twitter: userCard.twitter,
                opensea: userCard.opensea,
                discord: userCard.discord,
                createdBy: userCard.createdBy,
                mintedBy: mintDetail.mintedBy
            });
            unchecked {
                ++i;
            }
        }

        return userCards;
    }

    function getProjectCards(uint256 _projectId) external view returns (CardStruct[] memory) {
        uint256[] memory projectCardIds = s.projectCardIds[_projectId];
        uint256 count = projectCardIds.length;
        CardStruct[] memory projectCards = new CardStruct[](count);

        for (uint256 i; i < count; ) {
            MetadataStruct memory projectCard = s.tokenMetadata[projectCardIds[i]];
            projectCards[i] = CardStruct({
                tokenId: projectCard.tokenId,
                createdAt: projectCard.createdAt,
                projectId: projectCard.projectId,
                projectName: s.projects[projectCard.projectId].name,
                projectImageUrl: s.projects[projectCard.projectId].imageUrl,
                name: projectCard.name,
                imageCID: projectCard.imageCID,
                description: projectCard.description,
                role: projectCard.role,
                category: projectCard.category,
                twitter: projectCard.twitter,
                opensea: projectCard.opensea,
                discord: projectCard.discord,
                createdBy: projectCard.createdBy
            });
            unchecked {
                ++i;
            }
        }

        return projectCards;
    }

    function setCardLimit(uint256 _limit) external {
        LibDiamond.enforceIsContractOwner();
        LibCards.setCardLimit(_limit);
    }

    function cardLimit() external view returns (uint256) {
        return LibCards.cardLimit();
    }

    function getMintedCount() external view returns (uint256) {
        uint256 mintedCount;
        uint256 count = LibCards.currentTokenId();
        for (uint256 i; i < count; ) {
            mintedCount += s.cardUsers[i + 1].length;
            unchecked {
                ++i;
            }
        }
        return mintedCount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./LibERC2771Context.sol";

struct LibAppStorage {
    string tokenName;
    string tokenSymbol;
    string baseImageUri;
    // Mapping from token id to card info
    mapping(uint256 => MetadataStruct) tokenMetadata;
    // Mapping from token id to user address
    mapping(uint256 => address[]) cardUsers;
    // Mapping from project id to token ids
    mapping(uint256 => uint256[]) projectCardIds;
    // Mapping from wallet address to last created token id
    mapping(address => uint256) userLatestTokenId;
    // Mapping from user address to token ids
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
}

struct MetadataStruct {
    uint256 tokenId;
    uint256 projectId;
    uint256 createdAt;
    string name;
    string imageCID;
    string animationCID;
    string description;
    string role;
    string category;
    string twitter;
    string opensea;
    string discord;
    address createdBy;
}

struct ProjectStruct {
    uint256 id;
    string name;
    string imageUrl;
    string description;
    address createdBy;
}

struct ProjectUserStruct {
    address walletAddress;
    bool isAdmin;
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

contract Modifiers {
    modifier onlyTrustedForwarder() {
        require(LibERC2771Context.isTrustedForwarder(msg.sender), "ERC2771Context: caller is not a trusted forwarder");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";

library LibCards {
    using Counters for Counters.Counter;

    bytes32 constant CARDS_STORAGE_POSITION = keccak256("diamond.standard.cards.storage");

    struct CardsStorage {
        Counters.Counter tokenIds;
        Counters.Counter mintedCount;
        uint256 cardLimit;
    }

    function cardsStorage() internal pure returns (CardsStorage storage cs) {
        bytes32 position = CARDS_STORAGE_POSITION;
        assembly {
            cs.slot := position
        }
    }

    function incrementTokenId() internal {
        CardsStorage storage cs = cardsStorage();
        cs.tokenIds.increment();
    }

    function currentTokenId() internal view returns (uint256) {
        return cardsStorage().tokenIds.current();
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
pragma solidity ^0.8.17;

library LibContext {
    function msgSender() internal view returns (address) {
        return msg.sender;
    }

    function msgData() internal pure returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

import "./LibContext.sol";

library LibERC2771Context {
    bytes32 constant CONTEXT_STORAGE_POSITION = keccak256("diamond.standard.context.storage");

    struct ContextStorage {
        address trustedForwarder;
    }

    function contextStorage() internal pure returns (ContextStorage storage cs) {
        bytes32 position = CONTEXT_STORAGE_POSITION;
        assembly {
            cs.slot := position
        }
    }

    function setTrustedForwarder(address _trustedForwarder) internal {
        ContextStorage storage cs = contextStorage();
        cs.trustedForwarder = _trustedForwarder;
    }

    function isTrustedForwarder(address _forwarder) internal view returns (bool) {
        return _forwarder == contextStorage().trustedForwarder;
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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./LibAppStorage.sol";
import "./LibCards.sol";
import "./LibERC2771Context.sol";

struct ReturnProjectStruct {
    uint256 id;
    string name;
    string imageUrl;
    string description;
    address createdBy;
    bool canCreateCard;
}

library LibProjects {
    using Counters for Counters.Counter;

    bytes32 constant PROJECTS_STORAGE_POSITION = keccak256("diamond.standard.projects.storage");

    struct ProjectsStorage {
        Counters.Counter projectId;
    }

    function projectsStorage() internal pure returns (ProjectsStorage storage ds) {
        bytes32 position = PROJECTS_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function appStorage() internal pure returns (LibAppStorage storage s) {
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
                imageUrl: project.imageUrl,
                description: project.description,
                createdBy: project.createdBy,
                canCreateCard: appStorage().projectCardIds[_projectId].length < LibCards.cardLimit()
            });
    }

    function getAdminByProjectId(uint256 _projectId, address _walletAddress) internal view returns (uint256) {
        return appStorage().operatorAdmins[_projectId][_walletAddress];
    }

    function addUsersToProject(uint256 _projectId, address[] calldata _addressList) internal {
        LibAppStorage storage s = appStorage();

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