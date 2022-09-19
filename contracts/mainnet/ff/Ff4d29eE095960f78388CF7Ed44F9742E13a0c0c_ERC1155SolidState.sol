// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC1155, ERC1155Base, ERC1155BaseInternal } from './base/ERC1155Base.sol';
import { IERC1155Enumerable, ERC1155Enumerable } from './enumerable/ERC1155Enumerable.sol';
import { ERC1155EnumerableInternal } from './enumerable/ERC1155EnumerableInternal.sol';
import { IERC1155Metadata, ERC1155Metadata } from './metadata/ERC1155Metadata.sol';
import { ISolidStateERC1155 } from './ISolidStateERC1155.sol';
import { IERC2981 } from '../0_diamond/interfaces/IERC2981.sol';
import { LibDiamond } from '../0_diamond/libraries/LibDiamond.sol';
import { WordsInternal } from '../2_words/WordsInternal.sol';
import { OnchainMetadata } from '../5_Onchain_Metadata/OnchainMetadata.sol';


/**
 * @title SolidState ERC1155 implementation
 */
contract ERC1155SolidState is
    ISolidStateERC1155,
    ERC1155Base,
    ERC1155Enumerable,
    ERC1155Metadata,
    WordsInternal,
    OnchainMetadata
{


    function init() external {
        // _setName("Votable Valued Words");
        // _setSymbol("VV");

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC1155).interfaceId] = true;
        ds.supportedInterfaces[type(IERC1155Enumerable).interfaceId] = true;
        ds.supportedInterfaces[type(IERC1155Metadata).interfaceId] = true;
    }

    function safeMint1155(
        address account,
        uint256 id,
        bytes memory data
    ) public payable {
        _safeMint(account, id, msg.value, data);
    }

    function uri(uint256 tokenId) public view virtual 
        override(IERC1155Metadata, ERC1155Metadata)
        returns (string memory) 
    {
        return OnchainMetadata.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        override(ERC1155BaseInternal, ERC1155EnumerableInternal)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if(from != address(0)) {
            _updateVotingPower(from);
        }

        if(to != address(0)) {
            _updateVotingPower(to);
        }

        if(from != address(0) && to != address(0)) {
            uint256 idsPower;
            for(uint256 i; i < ids.length; i++) {
                idsPower += _cardPower(ids[i]);
            }
            _decreaseUserPower(from, idsPower);
            _increaseUserPower(to, idsPower);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC1155 } from '../IERC1155.sol';
import { IERC1155Receiver } from '../IERC1155Receiver.sol';
import { IERC1155Base } from './IERC1155Base.sol';
import { ERC1155BaseInternal, ERC1155BaseStorage } from './ERC1155BaseInternal.sol';

/**
 * @title Base ERC1155 contract
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
abstract contract ERC1155Base is IERC1155Base, ERC1155BaseInternal {
    /**
     * @inheritdoc IERC1155
     */
    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        returns (uint256)
    {
        return _balanceOf(account, id);
    }

    /**
     * @inheritdoc IERC1155
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            'ERC1155: accounts and ids length mismatch'
        );

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        uint256[] memory batchBalances = new uint256[](accounts.length);

        unchecked {
            for (uint256 i; i < accounts.length; i++) {
                require(
                    accounts[i] != address(0),
                    'ERC1155: batch balance query for the zero address'
                );
                batchBalances[i] = balances[ids[i]][accounts[i]];
            }
        }

        return batchBalances;
    }

    /**
     * @inheritdoc IERC1155
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        returns (bool)
    {
        return ERC1155BaseStorage.layout().operatorApprovals[account][operator];
    }

    /**
     * @inheritdoc IERC1155
     */
    function setApprovalForAll(address operator, bool status) public virtual {
        require(
            msg.sender != operator,
            'ERC1155: setting approval status for self'
        );
        ERC1155BaseStorage.layout().operatorApprovals[msg.sender][
            operator
        ] = status;
        // emit ApprovalForAll(msg.sender, operator, status);
    }

    /**
     * @inheritdoc IERC1155
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            'ERC1155: caller is not owner nor approved'
        );
        _safeTransfer(msg.sender, from, to, id, amount, data);
    }

    /**
     * @inheritdoc IERC1155
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            'ERC1155: caller is not owner nor approved'
        );
        _safeTransferBatch(msg.sender, from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '@solidstate/contracts/utils/EnumerableSet.sol';
import { ERC1155BaseInternal } from '../base/ERC1155BaseInternal.sol';
import { IERC1155Enumerable } from './IERC1155Enumerable.sol';
import { ERC1155EnumerableInternal, ERC1155EnumerableStorage } from './ERC1155EnumerableInternal.sol';

/**
 * @title ERC1155 implementation including enumerable and aggregate functions
 */
abstract contract ERC1155Enumerable is
    IERC1155Enumerable,
    ERC1155EnumerableInternal
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @inheritdoc IERC1155Enumerable
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply(id);
    }

    /**
     * @inheritdoc IERC1155Enumerable
     */
    function totalHolders(uint256 id) public view virtual returns (uint256) {
        return _totalHolders(id);
    }

    /**
     * @inheritdoc IERC1155Enumerable
     */
    function accountsByToken(uint256 id)
        public
        view
        virtual
        returns (address[] memory)
    {
        return _accountsByToken(id);
    }

    /**
     * @inheritdoc IERC1155Enumerable
     */
    function tokensByAccount(address account)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        return _tokensByAccount(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '@solidstate/contracts/utils/EnumerableSet.sol';
import { ERC1155BaseInternal, ERC1155BaseStorage } from '../base/ERC1155BaseInternal.sol';
import { ERC1155EnumerableStorage } from './ERC1155EnumerableStorage.sol';

/**
 * @title ERC1155Enumerable internal functions
 */
abstract contract ERC1155EnumerableInternal is ERC1155BaseInternal {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @notice query total minted supply of given token
     * @param id token id to query
     * @return token supply
     */
    function _totalSupply(uint256 id) internal view virtual returns (uint256) {
        return ERC1155EnumerableStorage.layout().totalSupply[id];
    }

    /**
     * @notice query total number of holders for given token
     * @param id token id to query
     * @return quantity of holders
     */
    function _totalHolders(uint256 id) internal view virtual returns (uint256) {
        return ERC1155EnumerableStorage.layout().accountsByToken[id].length();
    }

    /**
     * @notice query holders of given token
     * @param id token id to query
     * @return list of holder addresses
     */
    function _accountsByToken(uint256 id)
        internal
        view
        virtual
        returns (address[] memory)
    {
        EnumerableSet.AddressSet storage accounts = ERC1155EnumerableStorage
            .layout()
            .accountsByToken[id];

        address[] memory addresses = new address[](accounts.length());

        unchecked {
            for (uint256 i; i < accounts.length(); i++) {
                addresses[i] = accounts.at(i);
            }
        }

        return addresses;
    }

    /**
     * @notice query tokens held by given address
     * @param account address to query
     * @return list of token ids
     */
    function _tokensByAccount(address account)
        internal
        view
        virtual
        returns (uint256[] memory)
    {
        EnumerableSet.UintSet storage tokens = ERC1155EnumerableStorage
            .layout()
            .tokensByAccount[account];

        uint256[] memory ids = new uint256[](tokens.length());

        unchecked {
            for (uint256 i; i < tokens.length(); i++) {
                ids[i] = tokens.at(i);
            }
        }

        return ids;
    }

    /**
     * @notice ERC1155 hook: update aggregate values
     * @inheritdoc ERC1155BaseInternal
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from != to) {
            ERC1155EnumerableStorage.Layout storage l = ERC1155EnumerableStorage
                .layout();
            mapping(uint256 => EnumerableSet.AddressSet)
                storage tokenAccounts = l.accountsByToken;
            EnumerableSet.UintSet storage fromTokens = l.tokensByAccount[from];
            EnumerableSet.UintSet storage toTokens = l.tokensByAccount[to];

            for (uint256 i; i < ids.length; ) {
                uint256 amount = amounts[i];

                if (amount > 0) {
                    uint256 id = ids[i];

                    if (from == address(0)) {
                        l.totalSupply[id] += amount;
                    } else if (_balanceOf(from, id) == amount) {
                        tokenAccounts[id].remove(from);
                        fromTokens.remove(id);
                    }

                    if (to == address(0)) {
                        l.totalSupply[id] -= amount;
                    } else if (_balanceOf(to, id) == 0) {
                        tokenAccounts[id].add(to);
                        toTokens.add(id);
                    }
                }

                unchecked {
                    i++;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { UintUtils } from '@solidstate/contracts/utils/UintUtils.sol';
import { IERC1155Metadata } from './IERC1155Metadata.sol';
import { ERC1155MetadataInternal } from './ERC1155MetadataInternal.sol';
import { ERC1155MetadataStorage } from './ERC1155MetadataStorage.sol';

/**
 * @title ERC1155 metadata extensions
 */
abstract contract ERC1155Metadata is IERC1155Metadata, ERC1155MetadataInternal {
    using UintUtils for uint256;

    /**
     * @notice inheritdoc IERC1155Metadata
     */
    function uri(uint256 tokenId) public view virtual returns (string memory) {
        ERC1155MetadataStorage.Layout storage l = ERC1155MetadataStorage
            .layout();

        string memory tokenIdURI = l.tokenURIs[tokenId];
        string memory baseURI = l.baseURI;

        if (bytes(baseURI).length == 0) {
            return tokenIdURI;
        } else if (bytes(tokenIdURI).length > 0) {
            return string(abi.encodePacked(baseURI, tokenIdURI));
        } else {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC1155Base } from './base/IERC1155Base.sol';
import { IERC1155Enumerable } from './enumerable/IERC1155Enumerable.sol';
import { IERC1155Metadata } from './metadata/IERC1155Metadata.sol';

interface ISolidStateERC1155 is
    IERC1155Base,
    IERC1155Enumerable,
    IERC1155Metadata
{}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.7;

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

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


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./WordsStorage.sol";
import "../3_power/PowerInternal.sol";
import "./utils/UTF8HoldingSpace.sol";
import "./utils/StringUtils.sol";
import '@solidstate/contracts/utils/UintUtils.sol';

abstract contract WordsInternal is PowerInternal {
    using WordsStorage for WordsStorage.Layout;
    using WordsStorage for WordsStorage.Word;
    using UTF8HoldingSpace for *;
    using UintUtils for uint;
    using StringUtils for *;

    event NewWord(
        uint256 indexed tokenId,
        address indexed author,
        uint64 indexed category
    );

    event NewCategory(
        uint256 catId,
        string catStr
    );

    function __wordsInternal_init() internal {
        // _setMinInitialValue(10 ** 18);
        // _setMinDomValue(10 ** 17);
        // _setWithdrawableValueFraction(8000); //denominator is 10,000
        // _setVotingPowerFraction(2000); //denominator is 10,000
        // _setTimeToFullVotingPower(30 days);
        // _initBlockNumber(block.number);

        // WordsStorage.Word storage t = WordsStorage.layout().words[9];
        // uint256 falsePower = t.power;
        // uint256 newPower = _powerCalculator(t.value);
        // t.initialPower = newPower;
        // t.power = newPower;
    }

    function _inviteRequired() internal view returns(bool) {
        return WordsStorage.layout().inviteRequired;
    }

    function _nextTokenId() internal view returns(uint256) {
        return WordsStorage.layout().nextTokenId;
    }

    function _tokenIdIncrement() internal returns(uint256) {
        return WordsStorage.layout().nextTokenId++;
    }

    function _tags(uint256 tokenId) internal view returns(string[] memory tagsArr) {
        string memory tagsStr = WordsStorage.layout().words[tokenId].tags;
        
        StringUtils.slice memory s = tagsStr.toSlice();                
        StringUtils.slice memory delim = " ".toSlice();                            
        tagsArr = new string[](s.count(delim)+1);                  
        for (uint i = 0; i < tagsArr.length; i++) {                              
           tagsArr[i] = s.split(delim).toString();                               
        }                                                                      
    }

    function _externalURL(uint256 tokenId) internal view returns(string memory) {
        return WordsStorage.layout().words[tokenId].externalURL;                                                              
    }
    
    function _newWord(
        string[] calldata word,
        string calldata tags,
        string calldata externalURL,
        address author,
        address userAddr,
        uint256 id,
        uint256 value
    ) internal {
        WordsStorage.Layout storage l = WordsStorage.layout();
        WordsStorage.Word storage t = l.words[id];

        require(
            word.length <= 3,
            "WordsInternal: only three lines permited for this template."
        );
        
        require(
            word[0].checkLine(33) && word[1].checkLine(33) && word[2].checkLine(66),
            "WordsInternal: word lines overflow."
        );

        (uint256 min, uint256 max) = _allowedValueRange();
        require(
            value >= min,
            "WordsInternal: minimum value error."
        );
        require(
            t.value <= max,
            "WordsInternal: maximum value error."
        );

        uint256 power = _powerCalculator(value);

        t.word = word;
        t.tags = tags;
        t.externalURL = externalURL;
        t.author = author;
        t.initialValue = value;
        t.initialPower = power;
        t.value = value;
        t.power = power;
        t.blockNumber = block.number - l.initialBlock;

        if (userAddr != author){
            t.category = 1;
        }

        _increaseUserPower(userAddr, power);
        _increaseTotalPower(power);
        _increaseTotalValue(value);

        _registerWord(word, id);

        emit NewWord(id, author, t.category);
        emit UpdateValue(id, value, power, l.totalValue, l.totalPower);
    }

    function _takeBackWord(uint256 tokenId, address valueReceiver) internal {
        WordsStorage.Layout storage l = WordsStorage.layout();
        WordsStorage.Word storage t = l.words[tokenId];

        uint256 paidValue = t.value;
        uint256 withdrawableValue = paidValue * l.withdrawableValueFraction / 10000;
        uint256 power = t.power;

        _decreaseUserPower(valueReceiver, power);
        _decreaseTotalPower(power);
        _decreaseTotalValue(paidValue);


        delete t.value;
        delete t.power;

        payable(valueReceiver).transfer(withdrawableValue);

        emit UpdateValue(tokenId, 0, 0, l.totalValue, l.totalPower);
    }

////////// wordhash //////////

    function _registerWord(string[] calldata word, uint256 tokenId) internal {

        for(uint8 i; i<word.length; i++){
            _registerWordHash(word[i], tokenId);
        }

        string memory temp = string.concat(word[0], '/', word[1]);
        _registerWordHash(temp, tokenId);
        _registerWordHash(string.concat(word[1], '/', word[2]), tokenId);
        temp = string.concat(temp, '/', word[2]);
        require(
            _wordHashCounter(temp) == 0,
            string.concat(
                "WordsInternal: exact same word in tokenId ", 
                _wordHashTokenId(temp, 0).toString()
            )
        );
        _registerWordHash(temp, tokenId);
        
    }

    function _wordHashCounter(string memory word) internal view returns(uint256) {
        return WordsStorage.layout().wordHashes[
            keccak256(abi.encodePacked(word))
        ].wordHashCounter;
    }

    function _wordHashTokenId(
        string memory word,
        uint256 index
    ) internal view returns(uint256) {
        return WordsStorage.layout().wordHashes[
            keccak256(abi.encodePacked(word))
        ].indexToId[index];
    }

    function _registerWordHash(string memory word, uint256 tokenId) internal {
        WordsStorage.WordHash storage w = WordsStorage.layout().wordHashes[
            keccak256(abi.encodePacked(word))
        ];

        uint256 index = w.wordHashCounter++;
        w.indexToId[index] = tokenId;
        w.idToIndex[tokenId] = index;
    }

////////// setting /////////

    function _initBlockNumber(uint256 blockNumber) internal {
        WordsStorage.layout().initialBlock = blockNumber;
        emit UpdateVariable(bytes32(abi.encodePacked("initialBlock")), blockNumber);
    }

    function _setCategories(uint64[] calldata category, string[] calldata catStr) internal {
        require(category.length == catStr.length, "arrays length not same");
        for(uint8 i; i < category.length; i++) {
            WordsStorage.layout().categories[category[i]] = catStr[i];
            emit NewCategory(category[i], catStr[i]);
        }
    }

    function _setNotification(
        string calldata notification1,
        string calldata notification2
    ) internal {
        WordsStorage.layout().notification1 = notification1;
        WordsStorage.layout().notification2 = notification2;
    }

    function _setDefaultExternalURL(string calldata url) internal {
        WordsStorage.layout().defaultExternalURL = url;
    }

    function _setInviteRequirement(bool inviteRequired) internal {
        WordsStorage.layout().inviteRequired = inviteRequired;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../1_ERC721SolidState/base/ERC721BaseInternal.sol";
import "../2_words/WordsStorage.sol";
import "../4_Chainlink_VRF/VRFStorage.sol";
import '@solidstate/contracts/utils/AddressUtils.sol';
import '@solidstate/contracts/utils/UintUtils.sol';
import "@openzeppelin/contracts/utils/Base64.sol";
import "./utils/UintToFloatString.sol";
import "./utils/SVGTextValidator.sol";
import "../2_words/utils/StringUtils.sol";

contract OnchainMetadata is ERC721BaseInternal {
    using AddressUtils for address;
    using UintUtils for uint;
    using UintToFloatString for uint;
    using ERC721BaseStorage for ERC721BaseStorage.Layout;
    using SVGTextValidator for string;
    using StringUtils for *;

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        WordsStorage.Layout storage l = WordsStorage.layout();
        WordsStorage.Word storage t = WordsStorage.layout().words[tokenId];

        require(t.blockNumber != 0, "ERC721Metadata: URI query for nonexistent token");

        uint256 power = t.power;

        string memory doms;
        for (uint256 i; i < t.domsCount; i++){
            doms = string.concat(
                t.doms[i].dommer.toString(),
                ", ",
                t.doms[i].amount.floatString(18, 3),
                ", ",
                t.doms[i].mention,
                " /n"
            );
        }

        uint256 randomResult = VRFStorage.layout().randomResults[tokenId];
        string memory image =_image({
            word1 : t.word[0].validate(),
            word2 : t.word[1].validate(),
            word3 : t.word[2].validate(),
            cardPower : power.floatString(18, 3),
            notification1 : l.notification1,
            notification2 : bytes(l.notification2).length > 0 ? l.notification2 : 
            string.concat('First Goal : ',l.totalValue.floatString(18, 2),' of 8000 MATIC'),
            blockNumber : t.blockNumber.toString(),
            value : t.value.floatString(18, 2),
            points : randomResult % 2 == 0 ? _points(randomResult, power) : "",
            burned : t.value == 0
        });

        return string.concat('data:application/json;base64,', Base64.encode(abi.encodePacked(
              '{"name": "#', tokenId.toString(), 
            '", "description": "', doms,
            '", "external_url": "', bytes(t.externalURL).length>0 ? t.externalURL : string.concat(l.defaultExternalURL, tokenId.toString()),
            '", "image": "', image,
            '", "attributes": [', attributes(tokenId),
            '], "interaction" : {"read":[],"write":[{"inputs": [{"internalType": "uint256","name": "tokenId","type": "uint256"},{"internalType": "string","name": "mention","type": "string"}],"name": "dom","outputs": [],"stateMutability": "payable","type": "function"},{"inputs": [{"internalType": "uint256","name": "tokenId","type": "uint256"}],"name": "withdrawWord","outputs": [],"stateMutability": "nonpayable","type": "function"}]}}'
            ))
        ); 
    }

    function _image(
        string memory word1,
        string memory word2,
        string memory word3,
        string memory cardPower,
        string memory notification1,
        string memory notification2,
        string memory blockNumber,
        string memory value,
        string memory points,
        bool burned
    ) private pure returns(string memory) {      
        string memory imageString = string.concat(
            '<?xml version="1.0" encoding="utf-8"?><svg viewBox="150 0 700 1000" xmlns="http://www.w3.org/2000/svg"><defs><filter id="motion-blur-duotone" color-interpolation-filters="sRGB" x="-500%" y="-500%" width="1000%" height="1000%"><feGaussianBlur stdDeviation="7 0" edgeMode="none"/><feColorMatrix type="matrix" result="grayscale" values="1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 0 0 0 1 0"/><feComponentTransfer result="duotone"><feFuncR type="table" tableValues="0.741 0.988"/><feFuncG type="table" tableValues="0.043 0.733"/><feFuncB type="table" tableValues="0.569 0.051"/><feFuncA type="table" tableValues="0 1"/></feComponentTransfer></filter><clipPath id="clip-path"><rect width="700" height="1000" x="150" y="0"/></clipPath><style>.cls-1{clip-path:url(#clip-path); font-family:Courier New;}.cls-2{stroke:#1d1d1b;}.cls-3{fill:none; stroke-miterlimit:10; stroke:#dadada;stroke-width:1px;}.cls-4{fill:#1b1718;opacity:0.97;}.cls-5{font-size: 70px;}.cls-6{font-size: 32px; fill:#fff; font-family:Courier New;}.cls-7{font-size: 50px; fill:#fff;}.cls-8{font-size: 35px;}.cls-9{font-size: 40px;}.cls-10{fill:#99cf29; font-size: 35px; font-family:CourierNewPSMT}</style></defs><g class="cls-1"',
            burned ?   ' style="filter: url(#motion-blur-duotone);"' : '',
            '><rect class="cls-2" x="150" y="0" width="700" height="1000"/><polyline class="cls-3" points="',
            points,
            '"/><rect class="cls-4" x="150" y="0" width="700" height="210"/><rect class="cls-4" x="150" y="800" width="700" height="200"/><text class="cls-5" x="180" y="95" style="fill:#99cf29;">VVords</text><text class="cls-6" x="180" y="155">',
            word1,
            '<tspan x="180" y="195">',
            word2,
            '</tspan><tspan x="180" y="235" style="font-size: 16px;">',
            word3,
            '</tspan></text><text class="cls-7" x="180" y="600">',
            value,
            ' Matic</text><text class="cls-8" x="180" y="685" style="fill:#dd6400;">Block<tspan style="fill:#00e1f2;"> number</tspan><tspan style="fill:#a80054;"> ',
            blockNumber,
            '</tspan></text><text class="cls-9" x="180" y="750" style="fill:#99cf29;">Voting <tspan style="fill:#dd6400;" >Power </tspan><tspan style="fill:#00e1f2;">',
            cardPower,
            '</tspan></text><text class="cls-10" x="185" y="850" >notification<tspan x="180" y="910" style="font-size: 30px;">',
            notification1,
            '<tspan  x="180" y="955">',
            notification2,
            '</tspan></tspan></text></g></svg>'
        );
        
        return string.concat('data:image/svg+xml;base64,', Base64.encode(abi.encodePacked(imageString)));
    }

    function _points(uint256 hashNum, uint256 cardPower) private pure returns(string memory points) {
        cardPower /= 10 ** 17;
        uint256 numPoints;
        while (cardPower >= 10) {
            cardPower /= 10;
            numPoints ++;
        }
        numPoints = 10 * numPoints + cardPower;
        while(numPoints > 0) {
            if(hashNum > 1000) {
                points = string.concat(
                    points,
                    ((hashNum /= 100) % 100 * 10).toString(),
                    " "
                );
                numPoints--;
            }
        }
    }
    
    function attributes(uint256 tokenId) private view returns(string memory tagsOut){
        WordsStorage.Layout storage l = WordsStorage.layout();
        string memory tagsStr = l.words[tokenId].tags;
        string memory category = l.categories[l.words[tokenId].category];
        
        tagsOut = string.concat(
            tagsOut,
            '{"trait_type": "category", "value": "',
            category,
            '"}'
        );

        StringUtils.slice memory s = tagsStr.toSlice();                
        StringUtils.slice memory delim = " ".toSlice(); 
        uint256 sLen = s.count(delim);
        for(uint8 i; i <= sLen; i++){
            tagsOut = string.concat(
                tagsOut, 
                ', {"trait_type": "tag", "value": "',
                s.split(delim).toString(),
                '"}'
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC1155Internal } from './IERC1155Internal.sol';

/**
 * @title ERC1155 interface
 * @dev see https://github.com/ethereum/EIPs/issues/1155
 */
interface IERC1155 is IERC1155Internal {
    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @notice query the balances of given tokens held by given addresses
     * @param accounts addresss to query
     * @param ids tokens to query
     * @return token balances
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @notice grant approval to or revoke approval from given operator to spend held tokens
     * @param operator address whose approval status to update
     * @param status whether operator should be considered approved
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice transfer tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @notice transfer batch of tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to transfer
     * @param data data payload
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC1155 transfer receiver interface
 */
interface IERC1155Receiver {
    /**
     * @notice validate receipt of ERC1155 transfer
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param id token ID received
     * @param value quantity of tokens received
     * @param data data payload
     * @return function's own selector if transfer is accepted
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @notice validate receipt of ERC1155 batch transfer
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param ids token IDs received
     * @param values quantities of tokens received
     * @param data data payload
     * @return function's own selector if transfer is accepted
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC1155 } from '../IERC1155.sol';

/**
 * @title ERC1155 base interface
 */
interface IERC1155Base is IERC1155 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { AddressUtils } from '@solidstate/contracts/utils/AddressUtils.sol';
import { IERC1155Internal } from '../IERC1155Internal.sol';
import { IERC1155Receiver } from '../IERC1155Receiver.sol';
import { ERC1155BaseStorage } from './ERC1155BaseStorage.sol';

/**
 * @title Base ERC1155 internal functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
abstract contract ERC1155BaseInternal is IERC1155Internal {
    using AddressUtils for address;

    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function _balanceOf(address account, uint256 id)
        internal
        view
        virtual
        returns (uint256)
    {
        require(
            account != address(0),
            'ERC1155: balance query for the zero address'
        );
        return ERC1155BaseStorage.layout().balances[id][account];
    }

    /**
     * @notice mint given quantity of tokens for given address
     * @dev ERC1155Receiver implementation is not checked
     * @param account beneficiary of minting
     * @param id token ID
     * @param amount quantity of tokens to mint
     * @param data data payload
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), 'ERC1155: mint to the zero address');

        _beforeTokenTransfer(
            msg.sender,
            address(0),
            account,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        ERC1155BaseStorage.layout().balances[id][account] += amount;

        emit TransferSingle(msg.sender, address(0), account, id, amount);
    }

    /**
     * @notice mint given quantity of tokens for given address
     * @param account beneficiary of minting
     * @param id token ID
     * @param amount quantity of tokens to mint
     * @param data data payload
     */
    function _safeMint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _mint(account, id, amount, data);

        _doSafeTransferAcceptanceCheck(
            msg.sender,
            address(0),
            account,
            id,
            amount,
            data
        );
    }

    /**
     * @notice mint batch of tokens for given address
     * @dev ERC1155Receiver implementation is not checked
     * @param account beneficiary of minting
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to mint
     * @param data data payload
     */
    function _mintBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(account != address(0), 'ERC1155: mint to the zero address');
        require(
            ids.length == amounts.length,
            'ERC1155: ids and amounts length mismatch'
        );

        _beforeTokenTransfer(
            msg.sender,
            address(0),
            account,
            ids,
            amounts,
            data
        );

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        for (uint256 i; i < ids.length; ) {
            balances[ids[i]][account] += amounts[i];
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, address(0), account, ids, amounts);
    }

    /**
     * @notice mint batch of tokens for given address
     * @param account beneficiary of minting
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to mint
     * @param data data payload
     */
    function _safeMintBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        _mintBatch(account, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            msg.sender,
            address(0),
            account,
            ids,
            amounts,
            data
        );
    }

    /**
     * @notice burn given quantity of tokens held by given address
     * @param account holder of tokens to burn
     * @param id token ID
     * @param amount quantity of tokens to burn
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), 'ERC1155: burn from the zero address');

        _beforeTokenTransfer(
            msg.sender,
            account,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ''
        );

        mapping(address => uint256) storage balances = ERC1155BaseStorage
            .layout()
            .balances[id];

        unchecked {
            require(
                balances[account] >= amount,
                'ERC1155: burn amount exceeds balances'
            );
            balances[account] -= amount;
        }

        emit TransferSingle(msg.sender, account, address(0), id, amount);
    }

    /**
     * @notice burn given batch of tokens held by given address
     * @param account holder of tokens to burn
     * @param ids token IDs
     * @param amounts quantities of tokens to burn
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), 'ERC1155: burn from the zero address');
        require(
            ids.length == amounts.length,
            'ERC1155: ids and amounts length mismatch'
        );

        _beforeTokenTransfer(msg.sender, account, address(0), ids, amounts, '');

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        unchecked {
            for (uint256 i; i < ids.length; i++) {
                uint256 id = ids[i];
                require(
                    balances[id][account] >= amounts[i],
                    'ERC1155: burn amount exceeds balance'
                );
                balances[id][account] -= amounts[i];
            }
        }

        emit TransferBatch(msg.sender, account, address(0), ids, amounts);
    }

    /**
     * @notice transfer tokens between given addresses
     * @dev ERC1155Receiver implementation is not checked
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _transfer(
        address operator,
        address sender,
        address recipient,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(
            recipient != address(0),
            'ERC1155: transfer to the zero address'
        );

        _beforeTokenTransfer(
            operator,
            sender,
            recipient,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        unchecked {
            uint256 senderBalance = balances[id][sender];
            require(
                senderBalance >= amount,
                'ERC1155: insufficient balances for transfer'
            );
            balances[id][sender] = senderBalance - amount;
        }

        balances[id][recipient] += amount;

        emit TransferSingle(operator, sender, recipient, id, amount);
    }

    /**
     * @notice transfer tokens between given addresses
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _safeTransfer(
        address operator,
        address sender,
        address recipient,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _transfer(operator, sender, recipient, id, amount, data);

        _doSafeTransferAcceptanceCheck(
            operator,
            sender,
            recipient,
            id,
            amount,
            data
        );
    }

    /**
     * @notice transfer batch of tokens between given addresses
     * @dev ERC1155Receiver implementation is not checked
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _transferBatch(
        address operator,
        address sender,
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(
            recipient != address(0),
            'ERC1155: transfer to the zero address'
        );
        require(
            ids.length == amounts.length,
            'ERC1155: ids and amounts length mismatch'
        );

        _beforeTokenTransfer(operator, sender, recipient, ids, amounts, data);

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        for (uint256 i; i < ids.length; ) {
            uint256 token = ids[i];
            uint256 amount = amounts[i];

            unchecked {
                uint256 senderBalance = balances[token][sender];

                require(
                    senderBalance >= amount,
                    'ERC1155: insufficient balances for transfer'
                );

                balances[token][sender] = senderBalance - amount;

                i++;
            }

            // balance increase cannot be unchecked because ERC1155Base neither tracks nor validates a totalSupply
            balances[token][recipient] += amount;
        }

        emit TransferBatch(operator, sender, recipient, ids, amounts);
    }

    /**
     * @notice transfer batch of tokens between given addresses
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _safeTransferBatch(
        address operator,
        address sender,
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        _transferBatch(operator, sender, recipient, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            sender,
            recipient,
            ids,
            amounts,
            data
        );
    }

    /**
     * @notice wrap given element in array of length 1
     * @param element element to wrap
     * @return singleton array
     */
    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;
        return array;
    }

    /**
     * @notice revert if applicable transfer recipient is not valid ERC1155Receiver
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                require(
                    response == IERC1155Receiver.onERC1155Received.selector,
                    'ERC1155: ERC1155Receiver rejected tokens'
                );
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert('ERC1155: transfer to non ERC1155Receiver implementer');
            }
        }
    }

    /**
     * @notice revert if applicable transfer recipient is not valid ERC1155Receiver
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                require(
                    response ==
                        IERC1155Receiver.onERC1155BatchReceived.selector,
                    'ERC1155: ERC1155Receiver rejected tokens'
                );
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert('ERC1155: transfer to non ERC1155Receiver implementer');
            }
        }
    }

    /**
     * @notice ERC1155 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @dev called for both single and batch transfers
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC1155 interface needed by internal functions
 */
interface IERC1155Internal {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    // event ApprovalForAll(
    //     address indexed account,
    //     address indexed operator,
    //     bool approved
    // );
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

pragma solidity ^0.8.0;

library ERC1155BaseStorage {
    struct Layout {
        mapping(uint256 => mapping(address => uint256)) balances;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC1155Base');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, value);
    }

    function indexOf(AddressSet storage set, address value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(UintSet storage set, uint256 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            'EnumerableSet: index out of bounds'
        );
        return set._values[index];
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _indexOf(Set storage set, bytes32 value)
        private
        view
        returns (uint256)
    {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC1155Internal } from '../IERC1155Internal.sol';

/**
 * @title ERC1155 enumerable and aggregate function interface
 */
interface IERC1155Enumerable is IERC1155Internal {
    /**
     * @notice query total minted supply of given token
     * @param id token id to query
     * @return token supply
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @notice query total number of holders for given token
     * @param id token id to query
     * @return quantity of holders
     */
    function totalHolders(uint256 id) external view returns (uint256);

    /**
     * @notice query holders of given token
     * @param id token id to query
     * @return list of holder addresses
     */
    function accountsByToken(uint256 id)
        external
        view
        returns (address[] memory);

    /**
     * @notice query tokens held by given address
     * @param account address to query
     * @return list of token ids
     */
    function tokensByAccount(address account)
        external
        view
        returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '@solidstate/contracts/utils/EnumerableSet.sol';

library ERC1155EnumerableStorage {
    struct Layout {
        mapping(uint256 => uint256) totalSupply;
        mapping(uint256 => EnumerableSet.AddressSet) accountsByToken;
        mapping(address => EnumerableSet.UintSet) tokensByAccount;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC1155Enumerable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC1155MetadataInternal } from './IERC1155MetadataInternal.sol';

/**
 * @title ERC1155Metadata interface
 */
interface IERC1155Metadata is IERC1155MetadataInternal {
    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function uri(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC1155MetadataInternal } from './IERC1155MetadataInternal.sol';
import { ERC1155MetadataStorage } from './ERC1155MetadataStorage.sol';

/**
 * @title ERC1155Metadata internal functions
 */
abstract contract ERC1155MetadataInternal is IERC1155MetadataInternal {

    function _setName(string memory _name) internal virtual {
        ERC1155MetadataStorage.layout().name = _name;
    }

    function _setSymbol(string memory _symbol) internal virtual {
        ERC1155MetadataStorage.layout().symbol = _symbol;
    }
    
    /**
     * @notice set base metadata URI
     * @dev base URI is a non-standard feature adapted from the ERC721 specification
     * @param baseURI base URI
     */
    function _setBaseURI(string memory baseURI) internal {
        ERC1155MetadataStorage.layout().baseURI = baseURI;
    }

    /**
     * @notice set per-token metadata URI
     * @param tokenId token whose metadata URI to set
     * @param tokenURI per-token URI
     */
    function _setTokenURI(uint256 tokenId, string memory tokenURI) internal {
        ERC1155MetadataStorage.layout().tokenURIs[tokenId] = tokenURI;
        emit URI(tokenURI, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC1155 metadata extensions
 */
library ERC1155MetadataStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC1155Metadata');

    struct Layout {
        string name;
        string symbol;
        string baseURI;
        mapping(uint256 => string) tokenURIs;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC1155Metadata interface needed by internal functions
 */
interface IERC1155MetadataInternal {
    event URI(string value, uint256 indexed tokenId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


library WordsStorage {

    bytes32 constant VALUABLE_WORDS_STORAGE_POSITION = keccak256("VALUABLE_WORDS_STORAGE_POSITION");

    struct Layout {
        mapping(uint256 => Word) words;
        mapping(address => User) users;
        mapping(bytes32 => WordHash) wordHashes;
        mapping(uint256 => string) categories;
        uint256 nextTokenId;
        uint256 minInitialValue;
        uint256 minDomValue;
        uint256 withdrawableValueFraction; //denominator is 10,000
        uint256 votingPowerFraction; //denominator is 10,000
        uint256 timeToFullVotingPower; 
        uint256 totalValue;
        uint256 totalPower;
        uint256 initialBlock;
        string defaultExternalURL;
        string notification1;
        string notification2;
        bool inviteRequired;
    }

    struct User {
        uint256 power;
        uint256 lastVotingPowerRecorded;
        uint256 lastTransferTimestamp;
        uint256 votingPowerSpent;
    }

    struct WordHash {
        mapping(uint256 => uint256) indexToId;
        mapping(uint256 => uint256) idToIndex;
        uint256 wordHashCounter;
    }

    struct Word {
        mapping(uint256 => Dom) doms;
        string[] word;
        string tags;
        string externalURL;
        address author;
        uint256 domsCount;
        uint256 initialValue;
        uint256 initialPower;
        uint256 value;
        uint256 power;
        uint256 blockNumber;
        uint64 category;
        uint64 template;
    }

    struct Dom{
        address dommer;
        uint256 amount;
        string mention;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = VALUABLE_WORDS_STORAGE_POSITION;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../2_words/WordsStorage.sol";

abstract contract PowerInternal {

    event Dom(
        uint256 indexed tokenId,
        address indexed dommer,
        uint256 dommerPower,
        int256 value,
        int256 votingPower,
        string mention
    );

    event UpdateVariable(
        bytes32 indexed varName,
        uint256 value
    );

    event UpdateValue(
        uint256 indexed tokenId,
        uint256 value,
        uint256 power,
        uint256 totalValue,
        uint256 totalPower
    );

    event Withdraw(
        uint256 amount, 
        address receiver
    );


    function _dom(
        uint256 id,
        address tokenOwner,
        uint256 value,
        string calldata mention
    ) internal {
        WordsStorage.Layout storage l = WordsStorage.layout();
        require(
            value >= l.minDomValue,
            "WordsInternal: minimum value error."
        );

        uint256 power = _powerCalculator(value * (10000 - l.withdrawableValueFraction) / 10000);

        l.words[id].value += value;
        l.words[id].power += power;
        l.words[id].doms[l.words[id].domsCount++] =
            WordsStorage.Dom(msg.sender, value, mention);

        _increaseUserPower(tokenOwner, power);
        _increaseTotalPower(power);
        _increaseTotalValue(value);

        emit UpdateValue(
            id, 
            l.words[id].value, 
            l.words[id].power, 
            l.totalValue, 
            l.totalPower
        );

        emit Dom(id, msg.sender, _userPower(msg.sender), int(value), 0, mention);
    }

////////// power ///////////
    

    function _powerDetails(address userAddr) internal view returns(
        uint256 stakingTime,
        uint256 userLastTransferTimestamp,
        uint256 timeToFullVotingPower,
        uint256 userLastVotingPowerRecorded,
        uint256 votingPowerSpent
    ) {
        WordsStorage.Layout storage l = WordsStorage.layout();
        WordsStorage.User storage user = l.users[userAddr];

        stakingTime = block.timestamp - user.lastTransferTimestamp;
        userLastTransferTimestamp = user.lastTransferTimestamp;
        timeToFullVotingPower = l.timeToFullVotingPower;
        userLastVotingPowerRecorded = user.lastVotingPowerRecorded;
        votingPowerSpent = user.votingPowerSpent;
    }


    function _userVotingPower(address userAddr) internal view returns(uint256 votingPower) {
        WordsStorage.Layout storage l = WordsStorage.layout();
        WordsStorage.User storage user = l.users[userAddr];

        uint256 votingPowerMax = user.power * l.votingPowerFraction / 10000;

        uint256 stakingTime = block.timestamp - user.lastTransferTimestamp;

        votingPower = votingPowerMax * stakingTime / l.timeToFullVotingPower;

        votingPower += user.lastVotingPowerRecorded;
        votingPower -= user.votingPowerSpent;
        
        if(votingPower > votingPowerMax){
            votingPower = votingPowerMax;
        }
    }

    function _updateVotingPower(address userAddr) internal {
        WordsStorage.User storage user = WordsStorage.layout().users[userAddr];
        user.lastVotingPowerRecorded = _userVotingPower(userAddr) + user.votingPowerSpent;
        user.lastTransferTimestamp = block.timestamp;
    } 

    function _spendVotingPower(address userAddr, uint256 spendingAmount) internal {
        WordsStorage.User storage user = WordsStorage.layout().users[userAddr];
        _updateVotingPower(userAddr);
        uint256 votingPower = _userVotingPower(userAddr);
        require(spendingAmount <= votingPower);
        user.votingPowerSpent += spendingAmount;
    } 
    
    function _userVotingPowerMax(address userAddr) internal view returns(uint256 votingPowerMax) {
        WordsStorage.Layout storage l = WordsStorage.layout();
        WordsStorage.User storage user = l.users[userAddr];

        votingPowerMax = user.power * l.votingPowerFraction / 10000;
    }

    function _cardPower(uint256 tokenId) internal view returns(uint256) {
        return WordsStorage.layout().words[tokenId].power;
    }

    function _userPower(address userAddr) internal view returns(uint256) {
        return WordsStorage.layout().users[userAddr].power;
    }

    function _totalPower() internal view returns(uint256) {
        return WordsStorage.layout().totalPower;
    }

    function _increaseUserPower(address userAddr, uint256 amount) internal {
        _updateVotingPower(userAddr);
        WordsStorage.layout().users[userAddr].power += amount;
    }

    function _increaseTotalPower(uint256 amount) internal {
        WordsStorage.layout().totalPower += amount;
    }

    function _decreaseUserPower(address userAddr, uint256 amount) internal {
        _updateVotingPower(userAddr);
        WordsStorage.layout().users[userAddr].power -= amount;
    }

    function _decreaseTotalPower(uint256 amount) internal {
        WordsStorage.layout().totalPower -= amount;
    }

    function _powerCalculator(uint256 value) internal view returns(uint256 power) {
        // uint256 supply = _nextTokenId();
        // uint8 divisor = 1;
        // while(supply > 10) {
        //     supply /= 10;
        //     divisor *= 5;
        // }
        // power = value / divisor * 100;

        power = value * 8/10 *
            WordsStorage.layout().totalPower /
            address(this).balance;
            
    }


/////////// value ///////////

    function _allowedValueRange() internal view returns(uint256 min, uint256 max) {
        WordsStorage.Layout storage l = WordsStorage.layout();
        min = l.minInitialValue;
        max = (l.nextTokenId + 1) * 10 ** 18;
    }

    function _increaseTotalValue(uint256 amount) internal {
        WordsStorage.layout().totalValue += amount;
    }

    function _decreaseTotalValue(uint256 amount) internal {
        WordsStorage.layout().totalValue -= amount;
    }

    function _withdraw(uint256 amount, address receiver) internal {
        payable(receiver).transfer(amount);
        emit Withdraw(amount, receiver);
    }

////////// setting /////////

    function _setMinInitialValue(uint256 minInitialValue) internal {
        WordsStorage.layout().minInitialValue = minInitialValue;
        emit UpdateVariable(bytes32(abi.encodePacked("minInitialValue")), minInitialValue);
    }

    function _setMinDomValue(uint256 minDomValue) internal {
        WordsStorage.layout().minDomValue = minDomValue;
        emit UpdateVariable(bytes32(abi.encodePacked("minDomValue")), minDomValue);
    }

    function _setTimeToFullVotingPower(uint256 timeToFullVotingPower) internal {
        WordsStorage.layout().timeToFullVotingPower = timeToFullVotingPower;
        emit UpdateVariable(bytes32(abi.encodePacked("timeToFullVotingPower")), timeToFullVotingPower);
    }

    function _setWithdrawableValueFraction(uint256 fractoin) internal {
        WordsStorage.layout().withdrawableValueFraction = fractoin;
        emit UpdateVariable(bytes32(abi.encodePacked("withdrawableValueFraction")), fractoin);
    }

    function _setVotingPowerFraction(uint256 fractoin) internal {
        WordsStorage.layout().votingPowerFraction = fractoin;
        emit UpdateVariable(bytes32(abi.encodePacked("votingPowerFraction")), fractoin);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library UTF8HoldingSpace {

    function holdingSpace(
        string memory input
    ) internal pure returns(uint256) {

        uint256 char;
        uint256 len2;

        bytes memory inputBytes = bytes(input);

        while (char < inputBytes.length){
            if (inputBytes[char]>>7==0){
                char += 1;
                len2 += 2;
            } else if (inputBytes[char]>>5==bytes1(uint8(0x6))){
                char += 2;
                len2 += 2;
            } else if (inputBytes[char]>>4==bytes1(uint8(0xE))){
                char += 3;
                len2 += 3;
            } else if (inputBytes[char]>>3==bytes1(uint8(0x1E))){
                char += 4;
                len2 += 4;
            } else {
                //For safety
                char += 1;
                len2 += 2;
            }
        }
        return len2 / 2;
    }

    
    function numLines(
        string memory input,
        uint256 lenLimit
    ) internal pure returns(uint256 lineCount) {

        uint256 char;
        uint256 len2;
        uint256 lenLimit2 = lenLimit * 2;
        
        bytes memory inputBytes = bytes(input);

        if (inputBytes.length > 0) lineCount++;

        while (char < inputBytes.length) {

            if (inputBytes[char] == 0x5c && inputBytes[char+1] == 0x6e){
                lineCount ++;
                char += 2;
                len2 = 0;
                continue;
            } else if (len2 >= lenLimit2) {
                lineCount ++;
                len2 = 0;
            } 
            
            if (inputBytes[char]>>7==0){
                char += 1;
                len2 += 2;
            } else if (inputBytes[char]>>5==bytes1(uint8(0x6))){
                char += 2;
                len2 += 2;
            } else if (inputBytes[char]>>4==bytes1(uint8(0xE))){
                char += 3;
                len2 += 3;
            } else if (inputBytes[char]>>3==bytes1(uint8(0x1E))){
                char += 4;
                len2 += 4;
            } else {
                //For safety
                char += 1;
                len2 += 2;
            }
        }
    }
    
    function checkLine(
        string memory input,
        uint256 lenLimit
    ) internal pure returns(bool isFit) {
        isFit = true;

        uint256 char;
        uint256 len2;
        uint256 lenLimit2 = lenLimit * 2;

        bytes memory inputBytes = bytes(input);
    
        while (char < inputBytes.length) {
            if (len2 >= lenLimit2) {
                return false;
            } else if (inputBytes[char]>>7==0){
                char += 1;
                len2 += 2;
            } else if (inputBytes[char]>>5==bytes1(uint8(0x6))){
                char += 2;
                len2 += 2;
            } else if (inputBytes[char]>>4==bytes1(uint8(0xE))){
                char += 3;
                len2 += 3;
            } else if (inputBytes[char]>>3==bytes1(uint8(0x1E))){
                char += 4;
                len2 += 4;
            } else {
                //For safety
                char += 1;
                len2 += 2;
            }
        }
    }
    
    function checkLines(
        string[] memory input,
        uint256 lenLimit
    ) internal pure returns(bool allFit) {
        allFit = true;
        
        uint256 char;
        uint256 len2;
        uint256 lenLimit2 = lenLimit * 2;

        for(uint8 i; i < input.length; i++) {
            bytes memory inputBytes = bytes(input[i]);
    
            while (char < inputBytes.length) {
                if (len2 >= lenLimit2) {
                    return false;
                } else if (inputBytes[char]>>7==0){
                    char += 1;
                    len2 += 2;
                } else if (inputBytes[char]>>5==bytes1(uint8(0x6))){
                    char += 2;
                    len2 += 2;
                } else if (inputBytes[char]>>4==bytes1(uint8(0xE))){
                    char += 3;
                    len2 += 3;
                } else if (inputBytes[char]>>3==bytes1(uint8(0x1E))){
                    char += 4;
                    len2 += 4;
                } else {
                    //For safety
                    char += 1;
                    len2 += 2;
                }
            }

            char = 0;
            len2 = 0;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library StringUtils {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint _len) private pure {
        // Copy word-length chunks while possible
        for(; _len >= 32; _len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = type(uint).max;
        if (_len > 0) {
            mask = 256 ** (32 - _len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (uint(self) & type(uint128).max == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint(self) & type(uint64).max == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint(self) & type(uint32).max == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint(self) & type(uint16).max == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint(self) & type(uint8).max == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint mask = type(uint).max; // 0xffff...
                if(shortest < 32) {
                  mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                unchecked {
                    uint diff = (a & mask) - (b & mask);
                    if (diff != 0)
                        return int(diff);
                }
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import { AddressUtils } from '@solidstate/contracts/utils/AddressUtils.sol';
import { EnumerableMap } from '@solidstate/contracts/utils/EnumerableMap.sol';
import { EnumerableSet } from '@solidstate/contracts/utils/EnumerableSet.sol';
import { IERC721Internal } from '../IERC721Internal.sol';
import { IERC721Receiver } from '../IERC721Receiver.sol';
import { ERC721BaseStorage } from './ERC721BaseStorage.sol';

/**
 * @title Base ERC721 internal functions
 */
abstract contract ERC721BaseInternal is IERC721Internal {
    using ERC721BaseStorage for ERC721BaseStorage.Layout;
    using AddressUtils for address;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    function _balanceOf(address account) internal view returns (uint256) {
        require(
            account != address(0),
            'ERC721: balance query for the zero address'
        );
        return ERC721BaseStorage.layout().holderTokens[account].length();
    }

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        address owner = ERC721BaseStorage.layout().tokenOwners.get(tokenId);
        require(owner != address(0), 'ERC721: invalid owner');
        return owner;
    }

    function _getApproved(uint256 tokenId) internal view returns (address) {
        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();

        require(
            l.exists(tokenId),
            'ERC721: approved query for nonexistent token'
        );

        return l.tokenApprovals[tokenId];
    }

    function _isApprovedForAll(address account, address operator)
        internal
        view
        returns (bool)
    {
        return ERC721BaseStorage.layout().operatorApprovals[account][operator];
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(
            ERC721BaseStorage.layout().exists(tokenId),
            'ERC721: query for nonexistent token'
        );

        address owner = _ownerOf(tokenId);

        return (spender == owner ||
            _getApproved(tokenId) == spender ||
            _isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), 'ERC721: mint to the zero address');

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();

        require(!l.exists(tokenId), 'ERC721: token already minted');

        _beforeTokenTransfer(address(0), to, tokenId);

        l.holderTokens[to].add(tokenId);
        l.tokenOwners.set(tokenId, to);

        _afterTokenTransfer(address(0), to, tokenId);

        emit Transfer(address(0), to, tokenId);
    }

    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, '');
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            'ERC721: transfer to non ERC721Receiver implementer'
        );
    }

    function _burn(uint256 tokenId) internal {
        address owner = _ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        _approve(address(0), tokenId);

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();
        l.holderTokens[owner].remove(tokenId);
        l.tokenOwners.remove(tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            _ownerOf(tokenId) == from,
            'ERC721: transfer of token that is not own'
        );
        require(to != address(0), 'ERC721: transfer to the zero address');

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();
        l.holderTokens[from].remove(tokenId);
        l.holderTokens[to].add(tokenId);
        l.tokenOwners.set(tokenId, to);

        _afterTokenTransfer(from, to, tokenId);

        emit Transfer(from, to, tokenId);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            'ERC721: transfer to non ERC721Receiver implementer'
        );
    }

    function _approve(address operator, uint256 tokenId) internal {
        ERC721BaseStorage.layout().tokenApprovals[tokenId] = operator;
        emit Approval(_ownerOf(tokenId), operator, tokenId);
    }

    function _setApprovalForAll(address holder, address operator, bool status) internal {
        require(operator != holder, 'ERC721: approve to caller');
        ERC721BaseStorage.layout().operatorApprovals[holder][
            operator
        ] = status;
        emit ApprovalForAll(holder, operator, status);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        bytes memory returnData = to.functionCall(
            abi.encodeWithSelector(
                IERC721Receiver(to).onERC721Received.selector,
                msg.sender,
                from,
                tokenId,
                data
            ),
            'ERC721: transfer to non ERC721Receiver implementer'
        );

        bytes4 returnValue = abi.decode(returnData, (bytes4));
        return returnValue == type(IERC721Receiver).interfaceId;
    }

    /**
     * @notice ERC721 hook, called before externally called approvals for processing of included message value
     * @param operator beneficiary of approval
     * @param tokenId id of transferred token
     * @param value message value
     */
    function _handleApproveMessageValue(
        address operator,
        uint256 tokenId,
        uint256 value
    ) internal virtual {}

    /**
     * @notice ERC721 hook, called before externally called transfers for processing of included message value
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId id of transferred token
     * @param value message value
     */
    function _handleTransferMessageValue(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal virtual {}

    /**
     * @notice ERC721 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId id of transferred token
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @notice ERC721 hook, called after all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId id of transferred token
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

library VRFStorage {

    bytes32 constant VRF_STORAGE_POSITION = keccak256("VRF_STORAGE_POSITION");

    struct Layout {
        LinkTokenInterface LINK;
        address vrfCoordinator;
        mapping(bytes32 => uint256) nonces;

        bytes32 keyHash;
        uint256 fee;
        mapping(bytes32 => uint256) randomRequests;
        mapping(uint256 => uint256) randomResults;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = VRF_STORAGE_POSITION;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@solidstate/contracts/utils/UintUtils.sol';

/**
 * @author https://www.linkedin.com/in/renope/
 */
library UintToFloatString {
    using UintUtils for uint;

    function floatString(
        uint256 number, 
        uint8 inDecimals,
        uint8 outDecimals
    ) internal pure returns(string memory h) {
        h = string.concat(
            (number / 10 ** inDecimals).toString(),
            outDecimals > 0 ? '.': ''
        );
        while(outDecimals > 0){
            h = string.concat(
                h,
                inDecimals > 0 ?
                (number % 10 ** (inDecimals--) / 10 ** (inDecimals-1)).toString()
                : '0'
            );
            outDecimals--;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library SVGTextValidator {

    function validate(string memory input) internal pure returns(string memory output) {
        bytes memory inBytes = bytes(input);
        bool has;
        for (uint16 i; i < inBytes.length; i++) {
            if (inBytes[i] == 0x26){
                has = true;
            }
        }
        if(!has) {
            return input;
        } else {
            bytes memory outBytes;
            for (uint16 i; i < inBytes.length; i++) {
                outBytes = bytes.concat(outBytes, inBytes[i]);
                if(inBytes[i] == 0x26) {
                    outBytes = bytes.concat(outBytes, "amp;");
                }
            }
            return string(outBytes);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Map implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableMap {
    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        MapEntry[] _entries;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct AddressToAddressMap {
        Map _inner;
    }

    struct UintToAddressMap {
        Map _inner;
    }

    function at(AddressToAddressMap storage map, uint256 index)
        internal
        view
        returns (address, address)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        address addressKey;
        assembly {
            addressKey := mload(add(key, 20))
        }
        return (addressKey, address(uint160(uint256(value))));
    }

    function at(UintToAddressMap storage map, uint256 index)
        internal
        view
        returns (uint256, address)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    function contains(AddressToAddressMap storage map, address key)
        internal
        view
        returns (bool)
    {
        return _contains(map._inner, bytes32(uint256(uint160(key))));
    }

    function contains(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (bool)
    {
        return _contains(map._inner, bytes32(key));
    }

    function length(AddressToAddressMap storage map)
        internal
        view
        returns (uint256)
    {
        return _length(map._inner);
    }

    function length(UintToAddressMap storage map)
        internal
        view
        returns (uint256)
    {
        return _length(map._inner);
    }

    function get(AddressToAddressMap storage map, address key)
        internal
        view
        returns (address)
    {
        return
            address(
                uint160(
                    uint256(_get(map._inner, bytes32(uint256(uint160(key)))))
                )
            );
    }

    function get(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    function set(
        AddressToAddressMap storage map,
        address key,
        address value
    ) internal returns (bool) {
        return
            _set(
                map._inner,
                bytes32(uint256(uint160(key))),
                bytes32(uint256(uint160(value)))
            );
    }

    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    function remove(AddressToAddressMap storage map, address key)
        internal
        returns (bool)
    {
        return _remove(map._inner, bytes32(uint256(uint160(key))));
    }

    function remove(UintToAddressMap storage map, uint256 key)
        internal
        returns (bool)
    {
        return _remove(map._inner, bytes32(key));
    }

    function _at(Map storage map, uint256 index)
        private
        view
        returns (bytes32, bytes32)
    {
        require(
            map._entries.length > index,
            'EnumerableMap: index out of bounds'
        );

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    function _contains(Map storage map, bytes32 key)
        private
        view
        returns (bool)
    {
        return map._indexes[key] != 0;
    }

    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, 'EnumerableMap: nonexistent key');
        unchecked {
            return map._entries[keyIndex - 1]._value;
        }
    }

    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            map._entries.push(MapEntry({ _key: key, _value: value }));
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            unchecked {
                map._entries[keyIndex - 1]._value = value;
            }
            return false;
        }
    }

    function _remove(Map storage map, bytes32 key) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            unchecked {
                MapEntry storage last = map._entries[map._entries.length - 1];

                // move last entry to now-vacant index
                map._entries[keyIndex - 1] = last;
                map._indexes[last._key] = keyIndex;
            }

            // clear last index
            map._entries.pop();
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/**
 * @title Partial ERC721 interface needed by internal functions
 */
interface IERC721Internal {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import { EnumerableMap } from '@solidstate/contracts/utils/EnumerableMap.sol';
import { EnumerableSet } from '@solidstate/contracts/utils/EnumerableSet.sol';

library ERC721BaseStorage {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC721Base');

    struct Layout {
        EnumerableMap.UintToAddressMap tokenOwners;
        mapping(address => EnumerableSet.UintSet) holderTokens;
        mapping(uint256 => address) tokenApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function exists(Layout storage l, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        return l.tokenOwners.contains(tokenId);
    }

    function totalSupply(Layout storage l) internal view returns (uint256) {
        return l.tokenOwners.length();
    }

    function tokenOfOwnerByIndex(
        Layout storage l,
        address owner,
        uint256 index
    ) internal view returns (uint256) {
        return l.holderTokens[owner].at(index);
    }

    function tokenByIndex(Layout storage l, uint256 index)
        internal
        view
        returns (uint256)
    {
        (uint256 tokenId, ) = l.tokenOwners.at(index);
        return tokenId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}