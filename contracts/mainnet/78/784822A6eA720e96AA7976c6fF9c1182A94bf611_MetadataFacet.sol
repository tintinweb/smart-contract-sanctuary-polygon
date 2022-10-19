// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libraries/AppStorage.sol";
import "../../libraries/LibDiamond.sol";
import "../../libraries/LibStrings.sol";
import "../../libraries/LibMeta.sol";
import "../../libraries/LibERC721.sol";
import "../../interfaces/IFakeGotchisCardDiamond.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces/IERC721.sol";
import "../../interfaces/IERC1155.sol";

contract MetadataFacet is Modifiers {
    event MetadataActionLog(uint256 indexed id, Metadata metaData);
    event MetadataFlag(uint256 indexed _id, address _flaggedBy);
    event MetadataLike(uint256 indexed _id, address _likedBy);
    event ReviewPass(uint256 indexed _id, address _reviewer);
    event MetadataDecline(uint256 indexed _id, address _declinedBy);

    function getMetadata(uint256 _id) external view returns (Metadata memory) {
        validateMetadata(_id);
        return s.metadata[_id];
    }

    struct MetadataInput {
        string name;
        string publisherName;
        string externalLink;
        string description;
        address artist;
        string artistName;
        uint16[2] royalty; // royalty[0]: publisher, royalty[1]: artist, sum should be 400 (4%)
        uint16 editions;
        string fileHash;
        string fileType;
        string thumbnailHash;
        string thumbnailType;
    }

    function addMetadata(MetadataInput memory mData, uint256 series) external {
        address _sender = LibMeta.msgSender();
        // check blocked
        require(!s.blocked[_sender], "Metadata: Blocked address");

        // Parameter validation
        verifyMetadata(mData);

        if (bytes(s.publisherToName[_sender]).length == 0) {
            require(s.nameToPublisher[mData.publisherName] == address(0), "Metadata: Publisher name already used");
            s.publisherToName[_sender] = mData.publisherName;
            s.nameToPublisher[mData.publisherName] = _sender;
        } else {
            require(s.nameToPublisher[mData.publisherName] == _sender, "Metadata: Invalid publisher name");
        }

        // Burn card
        IFakeGotchisCardDiamond(s.fakeGotchisCardDiamond).burn(_sender, series, 1);

        // save
        s.metadataIdCounter++;
        uint256 _metadataId = s.metadataIdCounter;
        s.metadata[_metadataId] = Metadata({
            name: mData.name,
            description: mData.description,
            externalLink: mData.externalLink,
            editions: mData.editions,
            publisher: _sender,
            publisherName: mData.publisherName,
            artist: mData.artist,
            artistName: mData.artistName,
            royalty: mData.royalty,
            fileHash: mData.fileHash,
            fileType: mData.fileType,
            thumbnailHash: mData.thumbnailHash,
            thumbnailType: mData.thumbnailType,
            minted: false,
            createdAt: uint40(block.timestamp),
            status: METADATA_STATUS_PENDING,
            flagCount: 0,
            likeCount: 0
        });

        s.ownerMetadataIdIndexes[_sender][_metadataId] = s.ownerMetadataIds[_sender].length;
        s.ownerMetadataIds[_sender].push(_metadataId);
        s.metadataIds.push(_metadataId);
        s.metadataOwner[_metadataId] = _sender;

        // emit event with metadata
        emit MetadataActionLog(_metadataId, s.metadata[_metadataId]);
    }

    function declineMetadata(uint256 _id, bool isBadFaith) external onlyOwner {
        validateMetadata(_id);
        require(s.metadata[_id].status != METADATA_STATUS_APPROVED, "Metadata: Already approved");

        s.metadata[_id].status = METADATA_STATUS_DECLINED;
        if (isBadFaith) {
            s.blocked[s.metadataOwner[_id]] = true;
        }

        // emit event with metadata
        emit MetadataActionLog(_id, s.metadata[_id]);
        emit MetadataDecline(_id, msg.sender);
    }

    function mint(uint256 _id) external {
        Metadata memory mData = s.metadata[_id];
        require(mData.status != METADATA_STATUS_DECLINED, "Metadata: Declined");
        require(mData.status != METADATA_STATUS_PAUSED, "Metadata: Paused for review");

        require(!mData.minted, "Metadata: Already minted");

        if (mData.status == METADATA_STATUS_PENDING) {
            require(mData.createdAt + 5 days <= block.timestamp, "Metadata: Still pending");
            s.metadata[_id].status = METADATA_STATUS_APPROVED;
            // emit event with metadata
            emit MetadataActionLog(_id, s.metadata[_id]);
        }

        LibERC721.safeBatchMint(mData.publisher, _id, mData.editions);
        s.metadata[_id].minted = true;
    }

    function verifyMetadata(MetadataInput memory mData) internal pure {
        require(bytes(mData.fileHash).length > 0, "Metadata: File hash should exist");
        require(bytes(mData.fileType).length > 0, "Metadata: File type should exist");
        require(mData.artist != address(0), "Metadata: Artist should exist");
        require(bytes(mData.fileType).length <= 20, "Metadata: Max file type length is 20 bytes");
        require(bytes(mData.name).length > 0, "Metadata: Name should exist");
        require(bytes(mData.name).length <= 50, "Metadata: Max name length is 50 bytes");
        require(bytes(mData.description).length > 0, "Metadata: Description should exist");
        require(bytes(mData.description).length <= 120, "Metadata: Max description length is 120 bytes");
        require(bytes(mData.externalLink).length <= 50, "Metadata: Max external link length is 50 bytes");
        require(bytes(mData.publisherName).length > 0, "Metadata: Publisher name should exist");
        require(bytes(mData.publisherName).length <= 30, "Metadata: Max publisher name length is 30 bytes");
        require(bytes(mData.artistName).length > 0, "Metadata: Artist name should exist");
        require(bytes(mData.artistName).length <= 30, "Metadata: Max artist name length is 30 bytes");
        if (bytes(mData.thumbnailHash).length > 0) {
            require(bytes(mData.thumbnailType).length > 0, "Metadata: Thumbnail type should exist");
            require(bytes(mData.thumbnailType).length <= 20, "Metadata: Max thumbnail type length is 20 bytes");
        } else {
            require(bytes(mData.thumbnailType).length <= 0, "Metadata: Thumbnail type should not exist");
        }

        require(mData.royalty[0] + mData.royalty[1] == 400, "Metadata: Sum of royalty splits not 400");
        if (mData.artist == address(0)) {
            require(mData.royalty[1] == 0, "Metadata: Artist royalty split must be 0 with zero address");
        }
        require(mData.editions > 0, "Metadata: Invalid editions value");
        require(mData.editions <= 100, "Metadata: Max editions value is 100");
    }

    function validateMetadata(uint256 _id) internal view {
        require((_id > 0) && (_id <= s.metadataIdCounter), "Metadata: Invalid metadata id");
    }

    function checkForActions(address _sender) internal view {
        uint256 cardSeries; // TODO: Think for the next card series
        require(
            (IERC1155(s.fakeGotchisCardDiamond).balanceOf(_sender, cardSeries) > 0) || // Fake gotchi card owner
                (s.ownerTokenIds[_sender].length > 0) || // Fake gotchi owner
                (IERC721(s.aavegotchiDiamond).balanceOf(_sender) > 0) || // Aavegotchi owner
                (IERC20(s.ghstContract).balanceOf(_sender) >= 1e20), // 100+ GHST holder
            "MetadataFacet: Should own a Fake Gotchi NFT or an aavegotchi or 100 GHST"
        );
    }

    function flag(uint256 _id) external {
        validateMetadata(_id);

        address _sender = LibMeta.msgSender();

        checkForActions(_sender);

        // can only flag if in queue
        require(s.metadata[_id].status == METADATA_STATUS_PENDING, "MetadataFacet: Can only flag in queue");
        require(!s.metadataFlagged[_id][_sender], "MetadataFacet: Already flagged");

        s.metadata[_id].flagCount++;
        s.metadataFlagged[_id][_sender] = true;

        // pause after 10 flags
        if (s.metadata[_id].flagCount == 10) {
            s.metadata[_id].status = METADATA_STATUS_PAUSED;
        }

        emit MetadataFlag(_id, _sender);
    }

    function passReview(uint256 _id) external onlyOwner {
        validateMetadata(_id);

        require(s.metadata[_id].status == METADATA_STATUS_PAUSED, "Metadata: Not paused");

        s.metadata[_id].status = METADATA_STATUS_PENDING;

        // emit event with metadata
        emit MetadataActionLog(_id, s.metadata[_id]);

        emit ReviewPass(_id, msg.sender);
    }

    function like(uint256 _id) external {
        validateMetadata(_id);

        address _sender = LibMeta.msgSender();

        checkForActions(_sender);

        require(!s.metadataLiked[_id][_sender], "MetadataFacet: Already liked");
        s.metadata[_id].likeCount++;
        s.metadataLiked[_id][_sender] = true;

        emit MetadataLike(_id, _sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "./LibDiamond.sol";

uint8 constant METADATA_STATUS_PENDING = 0;
uint8 constant METADATA_STATUS_PAUSED = 1;
uint8 constant METADATA_STATUS_APPROVED = 2;
uint8 constant METADATA_STATUS_DECLINED = 3;

struct Metadata {
    // storage slot 1
    address publisher;
    uint16[2] royalty; // royalty[0]: publisher, royalty[1]: artist, sum should be 10000 (100%)
    uint16 editions; // decrease when fake gotchi burned
    uint32 flagCount;
    uint32 likeCount;
    // storage slot 2
    address artist;
    uint40 createdAt;
    uint8 status;
    bool minted;
    // storage slot 3+
    string name;
    string description;
    string externalLink;
    string artistName;
    string publisherName;
    string fileHash;
    string fileType;
    string thumbnailHash;
    string thumbnailType;
}

struct AppStorage {
    address ghstContract;
    address aavegotchiDiamond;
    address fakeGotchisCardDiamond;
    // Metadata
    mapping(address => bool) blocked;
    uint256 metadataIdCounter; // start from 1, not 0
    uint256[] metadataIds;
    mapping(uint256 => Metadata) metadata;
    mapping(uint256 => address) metadataOwner;
    mapping(address => mapping(uint256 => uint256)) ownerMetadataIdIndexes;
    mapping(address => uint256[]) ownerMetadataIds;
    mapping(uint256 => mapping(address => bool)) metadataLiked;
    mapping(uint256 => mapping(address => bool)) metadataFlagged;
    // Fake Gotchis ERC721
    uint256 tokenIdCounter;
    uint256[] tokenIds;
    mapping(uint256 => uint256) fakeGotchis; // fake gotchi id => metadata id
    mapping(uint256 => address) fakeGotchiOwner; // fake gotchi id => owner
    mapping(address => mapping(uint256 => uint256)) ownerTokenIdIndexes;
    mapping(address => uint256[]) ownerTokenIds;
    mapping(address => mapping(address => bool)) operators;
    mapping(uint256 => address) approved;
    mapping(string => address) nameToPublisher;
    mapping(address => string) publisherToName;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers {
    AppStorage internal s;

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
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
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
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
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
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
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
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
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
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

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
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
                    // bubble up the error
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

    function addSupportForERC165(bytes4 _interfaceId) internal {
        DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[_interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// From Open Zeppelin contracts: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol

/**
 * @dev String operations.
 */
library LibStrings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function strWithUint(string memory _str, uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        bytes memory buffer;
        unchecked {
            if (value == 0) {
                return string(abi.encodePacked(_str, "0"));
            }
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 10;
            }
            buffer = new bytes(digits);
            uint256 index = digits - 1;
            temp = value;
            while (temp != 0) {
                buffer[index--] = bytes1(uint8(48 + (temp % 10)));
                temp /= 10;
            }
        }
        return string(abi.encodePacked(_str, buffer));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibMeta {
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(bytes("EIP712Domain(string name,string version,uint256 salt,address verifyingContract)"));

    function domainSeparator(string memory name, string memory version) internal view returns (bytes32 domainSeparator_) {
        domainSeparator_ = keccak256(
            abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes(version)), getChainID(), address(this))
        );
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender_ = msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC721TokenReceiver.sol";
import {LibAppStorage, AppStorage} from "./AppStorage.sol";
import "./LibMeta.sol";

library LibERC721 {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

    event Mint(address indexed _owner, uint256 indexed _tokenId);

    function checkOnERC721Received(
        address _operator,
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_to)
        }
        if (size > 0) {
            require(
                ERC721_RECEIVED == IERC721TokenReceiver(_to).onERC721Received(_operator, _from, _tokenId, _data),
                "LibERC721: Transfer rejected/failed by _to"
            );
        }
    }

    // This function is used by transfer functions
    function transferFrom(
        address _sender,
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_to != address(0), "ERC721: Can't transfer to 0 address");
        address owner = s.fakeGotchiOwner[_tokenId];
        require(owner != address(0), "ERC721: Invalid tokenId or can't be transferred");
        require(_sender == owner || s.operators[owner][_sender] || s.approved[_tokenId] == _sender, "LibERC721: Not owner or approved to transfer");
        require(_from == owner, "ERC721: _from is not owner, transfer failed");
        s.fakeGotchiOwner[_tokenId] = _to;

        //Update indexes and arrays

        //Get the index of the tokenID to transfer
        uint256 transferIndex = s.ownerTokenIdIndexes[_from][_tokenId];

        uint256 lastIndex = s.ownerTokenIds[_from].length - 1;
        uint256 lastTokenId = s.ownerTokenIds[_from][lastIndex];
        uint256 newIndex = s.ownerTokenIds[_to].length;

        //Move the last element of the ownerIds array to replace the tokenId to be transferred
        s.ownerTokenIdIndexes[_from][lastTokenId] = transferIndex;
        s.ownerTokenIds[_from][transferIndex] = lastTokenId;
        delete s.ownerTokenIdIndexes[_from][_tokenId];

        //pop from array
        s.ownerTokenIds[_from].pop();

        //update index of new token
        s.ownerTokenIdIndexes[_to][_tokenId] = newIndex;
        s.ownerTokenIds[_to].push(_tokenId);

        if (s.approved[_tokenId] != address(0)) {
            delete s.approved[_tokenId];
            emit Approval(owner, address(0), _tokenId);
        }

        emit Transfer(_from, _to, _tokenId);
    }

    function safeBatchMint(
        address _to,
        uint256 _metadataId,
        uint256 _count
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 _tokenId = s.tokenIdCounter;
        for (uint256 i; i < _count; i++) {
            require(s.fakeGotchiOwner[_tokenId] == address(0), "LibERC721: tokenId already minted");

            s.fakeGotchis[_tokenId] = _metadataId;
            s.fakeGotchiOwner[_tokenId] = _to;
            s.tokenIds.push(_tokenId);
            s.ownerTokenIdIndexes[_to][_tokenId] = s.ownerTokenIds[_to].length;
            s.ownerTokenIds[_to].push(_tokenId);

            emit Mint(_to, _tokenId);
            emit Transfer(address(0), _to, _tokenId);

            _tokenId = _tokenId + 1;
        }
        s.tokenIdCounter = _tokenId;
    }

    function safeMint(address _to, uint256 _metadataId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 _tokenId = s.tokenIdCounter;
        require(s.fakeGotchiOwner[_tokenId] == address(0), "LibERC721: tokenId already minted");

        s.fakeGotchis[_tokenId] = _metadataId;
        s.fakeGotchiOwner[_tokenId] = _to;
        s.tokenIds.push(_tokenId);
        s.ownerTokenIdIndexes[_to][_tokenId] = s.ownerTokenIds[_to].length;
        s.ownerTokenIds[_to].push(_tokenId);
        s.tokenIdCounter = _tokenId + 1;

        emit Mint(_to, _tokenId);
        emit Transfer(address(0), _to, _tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFakeGotchisCardDiamond {
    function burn(
        address _cardOwner,
        uint256 _cardSeriesId,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
/* is ERC165 */
interface IERC721 {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata data
    ) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter, except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for this NFT.
    /// Throws if `_from` is not the current owner. Throws if `_to` is the zero address. Throws if `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    /// Throws unless `msg.sender` is the current NFT owner, or an authorized operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
    @title ERC-1155 Multi Token Standard
    @dev See https://eips.ethereum.org/EIPS/eip-1155
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
/* is ERC165 */
interface IERC1155 {
    /**
    @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
    @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    MUST revert if `_to` is the zero address.
    MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
    MUST revert on any other error.
    MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
    After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).        
    @param _from    Source address
    @param _to      Target address
    @param _id      ID of the token type
    @param _value   Transfer amount
    @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    /**
    @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
    @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    MUST revert if `_to` is the zero address.
    MUST revert if length of `_ids` is not the same as length of `_values`.
    MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
    MUST revert on any other error.        
    MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
    Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
    After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).                      
    @param _from    Source address
    @param _to      Target address
    @param _ids     IDs of each token type (order and length must match _values array)
    @param _values  Transfer amounts per token type (order and length must match _ids array)
    @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    /**
    @notice Get the balance of an account's tokens.
    @param _owner  The address of the token holder
    @param _id     ID of the token
    @return        The _owner's balance of the token type requested
    */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
    @notice Get the balance of multiple account/token pairs
    @param _owners The addresses of the token holders
    @param _ids    ID of the tokens
    @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
    */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    /**
    @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
    @dev MUST emit the ApprovalForAll event on success.
    @param _operator  Address to add to the set of authorized operators
    @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
    @notice Queries the approval status of an operator for a given owner.
    @param _owner     The owner of the tokens
    @param _operator  Address of authorized operator
    @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
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

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/// @title IERC721TokenReceiver
/// @dev See https://eips.ethereum.org/EIPS/eip-721. Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}