// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libraries/AppStorage.sol";
import "../../libraries/LibDiamond.sol";
import "../../libraries/LibStrings.sol";
import "../../libraries/LibMeta.sol";
import "../../libraries/LibERC721.sol";
import "../../interfaces/IERC721.sol";
import "../../interfaces/IERC721Marketplace.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FakeGotchisNFTFacet is Modifiers {
    event GhstAddressUpdated(address _ghstContract);
    event AavegotchiAddressUpdated(address _aavegotchiDiamond);
    event FakeGotchisCardAddressUpdated(address _fakeGotchisCardDiamond);

    function setGhstAddress(address _ghstContract) external onlyOwner {
        s.ghstContract = _ghstContract;
        emit GhstAddressUpdated(_ghstContract);
    }

    function setAavegotchiAddress(address _aavegotchiDiamond) external onlyOwner {
        s.aavegotchiDiamond = _aavegotchiDiamond;
        emit AavegotchiAddressUpdated(_aavegotchiDiamond);
    }

    function setFakeGotchisCardAddress(address _fakeGotchisCardDiamond) external onlyOwner {
        s.fakeGotchisCardDiamond = _fakeGotchisCardDiamond;
        emit FakeGotchisCardAddressUpdated(_fakeGotchisCardDiamond);
    }

    /**
     * @notice Called with the sale price to determine how much royalty is owed and to whom.
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     * @return receivers - address of who should be sent the royalty payment
     * @return royaltyAmounts - the royalty payment amount for _salePrice
     */
    function multiRoyaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address[] memory receivers, uint256[] memory royaltyAmounts)
    {
        Metadata memory mData = s.metadata[s.fakeGotchis[_tokenId]];
        receivers = new address[](2);
        royaltyAmounts = new uint256[](2);
        receivers[0] = mData.publisher;
        receivers[1] = mData.artist;

        //Fake Gotchis royalties are 4% of the salePrice
        royaltyAmounts[0] = (_salePrice * mData.royalty[0]) / 10000;
        royaltyAmounts[1] = (_salePrice * mData.royalty[1]) / 10000;

        return (receivers, royaltyAmounts);
    }

    function tokenIdsOfOwner(address _owner) external view returns (uint256[] memory tokenIds_) {
        return s.ownerTokenIds[_owner];
    }

    function totalSupply() external view returns (uint256) {
        return s.tokenIds.length;
    }

    /**
     * @notice Enumerate valid NFTs
     * @dev Throws if `_index` >= `totalSupply()`.
     * @param _index A counter less than `totalSupply()`
     * @return tokenId_ The token identifier for the `_index`th NFT, (sort order not specified)
     */
    function tokenByIndex(uint256 _index) external view returns (uint256 tokenId_) {
        require(_index < s.tokenIds.length, "ERC721: _index is greater than total supply.");
        tokenId_ = s.tokenIds[_index];
    }

    /**
     * @notice Count all NFTs assigned to an owner
     * @dev NFTs assigned to the zero address are considered invalid, and this. function throws for queries about the zero address.
     * @param _owner An address for whom to query the balance
     * @return balance_ The number of NFTs owned by `_owner`, possibly zero
     */
    function balanceOf(address _owner) external view returns (uint256 balance_) {
        balance_ = s.ownerTokenIds[_owner].length;
    }

    /**
     * @notice Find the owner of an NFT
     * @dev NFTs assigned to zero address are considered invalid, and queries about them do throw.
     * @param _tokenId The identifier for an NFT
     * @return owner_ The address of the owner of the NFT
     */
    function ownerOf(uint256 _tokenId) external view returns (address owner_) {
        owner_ = s.fakeGotchiOwner[_tokenId];
    }

    /**
     * @notice Get the approved address for a single NFT
     * @dev Throws if `_tokenId` is not a valid NFT.
     * @param _tokenId The NFT to find the approved address for
     * @return approved_ The approved address for this NFT, or the zero address if there is none
     */
    function getApproved(uint256 _tokenId) external view returns (address approved_) {
        require(s.fakeGotchiOwner[_tokenId] != address(0), "ERC721: tokenId is invalid or is not owned");
        approved_ = s.approved[_tokenId];
    }

    /**
     * @notice Query if an address is an authorized operator for another address
     * @param _owner The address that owns the NFTs
     * @param _operator The address that acts on behalf of the owner
     * @return approved_ True if `_operator` is an approved operator for `_owner`, false otherwise
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool approved_) {
        approved_ = s.operators[_owner][_operator];
    }

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev Throws unless `msg.sender` is the current owner, an authorized
     *  operator, or the approved address for this NFT. Throws if `_from` is
     *  not the current owner. Throws if `_to` is the zero address. Throws if
     *  `_tokenId` is not a valid NFT. When transfer is complete, this function
     *  checks if `_to` is a smart contract (code size > 0). If so, it calls
     *  `onERC721Received` on `_to` and throws if the return value is not
     *  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     * @param _data Additional data with no specified format, sent in call to `_to`
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) public {
        address sender = LibMeta.msgSender();
        LibERC721.transferFrom(sender, _from, _to, _tokenId);
        LibERC721.checkOnERC721Received(sender, _from, _to, _tokenId, _data);

        //Update baazaar listing
        if (s.aavegotchiDiamond != address(0)) {
            IERC721Marketplace(s.aavegotchiDiamond).updateERC721Listing(address(this), _tokenId, _from);
        }
    }

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev This works identically to the other function with an extra data parameter, except this function just sets data to "".
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        address sender = LibMeta.msgSender();
        LibERC721.transferFrom(sender, _from, _to, _tokenId);
        LibERC721.checkOnERC721Received(sender, _from, _to, _tokenId, "");

        //Update baazaar listing
        if (s.aavegotchiDiamond != address(0)) {
            IERC721Marketplace(s.aavegotchiDiamond).updateERC721Listing(address(this), _tokenId, _from);
        }
    }

    /**
     * @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE THEY MAY BE PERMANENTLY LOST
     * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero address. Throws if `_tokenId` is not a valid NFT.
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        address sender = LibMeta.msgSender();
        LibERC721.transferFrom(sender, _from, _to, _tokenId);

        if (s.aavegotchiDiamond != address(0)) {
            IERC721Marketplace(s.aavegotchiDiamond).updateERC721Listing(address(this), _tokenId, _from);
        }
    }

    /**
     * @notice Change or reaffirm the approved address for an NFT
     * @dev The zero address indicates there is no approved address. Throws unless `msg.sender` is the current NFT owner, or an authorized operator of the current owner.
     * @param _approved The new approved NFT controller
     * @param _tokenId The NFT to approve
     */
    function approve(address _approved, uint256 _tokenId) external {
        address owner = s.fakeGotchiOwner[_tokenId];
        address sender = LibMeta.msgSender();
        require(owner == sender || s.operators[owner][sender], "ERC721: Not owner or operator of token.");
        s.approved[_tokenId] = _approved;
        emit LibERC721.Approval(owner, _approved, _tokenId);
    }

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage all of `msg.sender`'s assets
     * @dev Emits the ApprovalForAll event. The contract MUST allow multiple operators per owner.
     * @param _operator Address to add to the set of authorized operators
     * @param _approved True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) external {
        address sender = LibMeta.msgSender();
        s.operators[sender][_operator] = _approved;
        emit LibERC721.ApprovalForAll(sender, _operator, _approved);
    }

    function name() external pure returns (string memory) {
        return "FAKE Gotchis";
    }

    /**
     * @notice An abbreviated name for NFTs in this contract
     */
    function symbol() external pure returns (string memory) {
        return "FG";
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC 3986. The URI may point to a JSON file that conforms to the "ERC721 FakeGotchi JSON Schema".
     */
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        Metadata memory mData = s.metadata[s.fakeGotchis[_tokenId]];
        require(mData.publisher != address(0), "ERC721: Invalid token id");

        bytes memory json = abi.encodePacked(
            '{"trait_type":"Publisher","value":"',
            Strings.toHexString(uint256(uint160(mData.publisher)), 20),
            '"},'
        );
        json = abi.encodePacked(json, '{"trait_type":"Publisher Name","value":"', mData.publisherName, '"},');
        json = abi.encodePacked(json, '{"trait_type":"Artist","value":"', Strings.toHexString(uint256(uint160(mData.artist)), 20), '"},');
        json = abi.encodePacked(json, '{"trait_type":"Artist Name","value":"', mData.artistName, '"},');
        json = abi.encodePacked(json, '{"trait_type":"External Link","value":"', mData.externalLink, '"},');
        json = abi.encodePacked(json, '{"trait_type":"File MIME Type","value":"', mData.fileType, '"},');
        json = abi.encodePacked(json, '{"trait_type":"Thumbnail Link","value":"https://arweave.net/', mData.thumbnailHash, '"},');
        json = abi.encodePacked(json, '{"trait_type":"Thumbnail MIME Type","value":"', mData.thumbnailType, '"},');
        json = abi.encodePacked(json, '{"trait_type":"Editions","value":"', Strings.toString(mData.editions), '"},');
        json = abi.encodePacked(json, '{"trait_type":"Created At","value":"', Strings.toString(mData.createdAt), '"},');
        json = abi.encodePacked(json, '{"trait_type":"Flag Count","value":"', Strings.toString(mData.flagCount), '"},');
        json = abi.encodePacked(json, '{"trait_type":"Like Count","value":"', Strings.toString(mData.likeCount), '"}');
        json = abi.encodePacked('"attributes": [', json, "]");
        json = abi.encodePacked('"image":"https://arweave.net/', mData.fileHash, '",', json);
        json = abi.encodePacked('"description":"', mData.description, '",', json);
        json = abi.encodePacked('{"name":"', mData.name, '",', json, "}");

        return string(json);
    }

    function safeBatchTransfer(
        address _from,
        address _to,
        uint256[] calldata _tokenIds,
        bytes calldata _data
    ) external {
        for (uint256 index = 0; index < _tokenIds.length; index++) {
            safeTransferFrom(_from, _to, _tokenIds[index], _data);
        }
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
    //publisher => operator => whitelisted
    mapping(address => mapping(address => bool)) publishingOperators;
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

interface IERC721Marketplace {
    function updateERC721Listing(
        address _erc721TokenAddress,
        uint256 _erc721TokenId,
        address _owner
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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