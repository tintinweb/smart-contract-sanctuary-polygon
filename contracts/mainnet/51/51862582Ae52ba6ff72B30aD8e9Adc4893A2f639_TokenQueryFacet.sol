// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ITokenQuery } from "./ITokenQuery.sol";
import { BaseFacet } from "./BaseFacet.sol";
import { TokenType } from './Lib.sol';

contract TokenQueryFacet is BaseFacet, ITokenQuery {
  function tokenOwner(uint _id) view external override returns (address) {
    require(s.tokens.types[_id] != TokenType.INVALID, "Gifter: cannot have owner");
    return s.tokens.owner[_id];
  }
  
  function totalTokensByType(TokenType _type) view external override returns (uint) {
    return s.tokens.totalByType[_type];
  }

  function tokenByType(TokenType _type, uint _index) view external override returns (uint) {
    return s.tokens.byType[_type][_index];
  }
  
  function totalTokensOwnedByType(TokenType _type, address _owner) view external override returns (uint) {
    return s.tokens.totalOwnedByType[_owner][_type];
  }

  function tokenOwnedByType(TokenType _type, address _owner, uint _index) view external override returns (uint) {
    return s.tokens.ownedIdByTypeAndIndex[_owner][_type][_index];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { CardParams, Asset, TokenType } from "./Lib.sol";
import { IDex } from "./IDex.sol";


interface ITokenQuery {
  /**
   * @dev Get token owner.
  */
  function tokenOwner(uint _id) view external returns (address);

  /**
   * @dev Get total no. of of tokens of given type.
   *
   * @param _type type.
  */
  function totalTokensByType(TokenType _type) view external returns (uint);

  /**
   * @dev Get id of token of given type at given index.
   *
   * @param _type type.
   * @param _index 1-based index in list of tokens of given type.
   */
  function tokenByType(TokenType _type, uint _index) view external returns (uint);
  
  /**
   * @dev Get total no. of tokens of given type owned by given account.
   *
   * @param _type type.
   * @param _owner owner.
   */
  function totalTokensOwnedByType(TokenType _type, address _owner) view external returns (uint);

  /**
   * @dev Get id of token of given type owned by given account at given index.
   *
   * @param _type type.
   * @param _owner owner.
   * @param _index 1-based index in list of tokens of given type owned by the account.
   */
  function tokenOwnedByType(TokenType _type, address _owner, uint _index) view external returns (uint);
}

// SPDX-License-Identifier: MIT
// Based on OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)
pragma solidity ^0.8.0;

import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { LibDiamond } from './diamond/libraries/LibDiamond.sol';
import { AppStorage ,TokenType } from './Lib.sol';

abstract contract BaseFacet is Context {
  AppStorage internal s;

  function _getAdmin() internal view returns (address) {
    return LibDiamond.contractOwner();
  }
  
  function _getNewTokenId() internal returns (uint) {
    s.tokens.lastId += 1;
    return s.tokens.lastId;
  }

  modifier isAdmin () {
    require(_msgSender() == _getAdmin(), "Gifter: must be admin");
    _;
  }

  modifier isOwner (uint _id) {
    require(s.tokens.balances[_id][_msgSender()] == 1, "Gifter: must be owner");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Asset {
  address tokenContract;
  uint value;
}

struct GiftParams {
  address recipient;
  bytes config;
  string message;
  uint weiValue;
  Asset fee;
  Asset[] erc20;
  Asset[] nft;
}

struct GiftData {
  GiftParams params;
  address sender;
  uint timestamp;
  uint created;
  uint claimed;
  bool opened; 
  string contentHash;
}

struct CardParams {
  string contentHash;
  Asset fee;
}

struct Card {
  CardParams params;
  bool enabled;
}

enum TokenType { INVALID, GIFT, CARD }

struct Tokens {
  uint lastId;
  mapping(uint => string) URIs;
  mapping(uint => mapping(address => uint)) balances;
  mapping(address => mapping(address => bool)) operatorApprovals;
  // token owner
  mapping(uint => address) owner;
  // token types
  mapping(uint => TokenType) types;
  // total tokens by types
  mapping(TokenType => uint) totalByType;
  // token by type
  mapping(TokenType => mapping(uint => uint)) byType;
  // owner => type => total tokens
  mapping (address => mapping(TokenType => uint)) totalOwnedByType;
  // owner => type => index => token id
  mapping (address => mapping(TokenType => mapping(uint => uint))) ownedIdByTypeAndIndex;
  // owner => type => token id => index
  mapping (address => mapping(TokenType => mapping(uint => uint))) ownedIndexByTypeAndId;
}

struct AppStorage {
  // Generic token stuff
  Tokens tokens;
  // base URI for all metadata
  string baseURI;
  // default content hash for newly sent gifts
  string defaultGiftContentHash;
  // DEX address
  address dex;
  // list of allowed tokens for card fee denominations
  address[] feeTokenList;
  // token => allowed for use as fee token
  mapping(address => bool) isFeeTokenAllowed;
  // fee tax (platform revenue) in basis points
  uint tax;
  // gift id => data
  mapping(uint => GiftData) gifts;
  // sender => total sent
  mapping (address => uint) totalGiftsSent;
  // sender => sent index => gift id
  mapping (address => mapping(uint => uint)) sentGift;
  // card id => data
  mapping(uint => Card) cards;
  // content hash => card id
  mapping(string => uint) cardIdByContentHash;
  // token => total tax
  mapping(address => uint) totalTaxesPerToken;
  // token => total earnings
  mapping(address => uint) totalEarningsPerToken;
  // owner => token => total
  mapping(address => mapping(address => uint)) cardOwnerEarningsPerToken;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDex {
  /**
   * @dev Calculate the minimum native token amount required to trade to the given output token amount.
   *
   * @param _outToken The output token.
   * @param _outAmount The minimum required output amount.
   */
  function calcInAmount(address _outToken, uint _outAmount) external view returns (uint);

  /**
   * @dev Trade the received native token amount to the output token amount.
   *
   * @param _outToken The output token.
   * @param _outAmount The minimum required output amount.
   * @param _outWallet The wallet to send output tokens to.
   */
  function trade(address _outToken, uint _outAmount, address _outWallet) external payable;
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
pragma solidity ^0.8.0;

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

// Based on https://github.com/mudgen/diamond-1-hardhat/blob/main/contracts/libraries/LibDiamond.sol
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
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors, false);
            } else if (action == IDiamondCut.FacetCutAction.AddOrReplace) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors, true);
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

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors, bool replaceIfPresent) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Add facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            // if already have mapping
            if (oldFacetAddress != address(0)) {
              // if replace not enabled then throw
              if (!replaceIfPresent) {
                revert("LibDiamondCut: Can't add function that already exists");                
              } 
              // else let's ensure we're replacing something valid
              else {
                require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
              }
            } 
            // if no mapping then it's new
            else {
              ds.selectors.push(selector);
              selectorCount++;
            }
            // update mapping
            ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(_facetAddress, selectorCount);
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Replace facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Replace facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            // can't replace immutable functions -- functions defined directly in the diamond
            require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
            // replace old facet address
            ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition = ds.facetAddressAndSelectorPosition[selector];
            require(oldFacetAddressAndSelectorPosition.facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
            // can't remove immutable functions -- functions defined directly in the diamond
            require(oldFacetAddressAndSelectorPosition.facetAddress != address(this), "LibDiamondCut: Can't remove immutable function.");
            // replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition = oldFacetAddressAndSelectorPosition.selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
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
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove, AddOrReplace}
    // Add=0, Replace=1, Remove=2, AddOrReplace=3

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