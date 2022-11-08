// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./extensions/ChestHolder.sol";
import "./IChest.sol";

contract Chest is IChest, ChestHolder, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Strings for address;

    struct Metadata {
      Counters.Counter opennedCounter;
      uint256 lastTimeOpenned;
      address creator;
      string name;
      string type_;
    }

    // Information about the chest
    Metadata public chest;

    /***********************************|
   |            Constructor             |
   |__________________________________*/

    /**
     * @dev Sets the values for {name} and {type_}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory type_) {
        chest.name = name;
        chest.type_ = type_;
        chest.creator = msg.sender;
    }

    /***********************************|
   |           Write Functions          |
   |__________________________________*/

    /**
     * @dev Deposit a set of {ERC20}, {ERC721}, {ERC1155} white listed by the owner 
     * of the chest.
     *
     * @param items: The addresses of the tokens to be deposited.
     *
     * @param tokenIds: The id of token to be deposited. 
     * @notice For ERC20 token which don't have id any value will fit.
     *
     * @param amounts: The quantities of the tokens to be deposited.
     * @notice For ERC721 the quantity must be 1 as any id is a unique NFT.
     *
     * WARNING: items <=> tokenIds <=> amounts {indexes} much match each others.
     *
     * Example: Alice want to deposit 10 DAI token and 1 GOTCHI (21345), here is her input
     *  items = ["0x8f3cf7ad23cd3cadbd9735aff958023239c6a063", "0x86935F11C86623deC8a25696E1C19a8659CbF95d"],
     *  tokenIds = [{whatever id as it is a ERC20}, 21345],
     *  amounts = ["10", "1"]  
     *
     * Requirements:
     * 
     * - {msg.sender} must be the owner of the chest.
     * - If The length of the 3 params are not equal the Tx will revert.
     * - If the address of one token is not white listed, the Tx will revert.
     *
     */
    function batchDeposit(
        address[] memory items, 
        uint256[] memory tokenIds, 
        uint256[] memory amounts
    ) external virtual onlyOwner notLocked returns(bool success) {
        require(items.length == tokenIds.length && 
                items.length == amounts.length,
                "Chest: length of items and ids and amounts are not the same.");
        
        for (uint i; i < items.length; i++) {
            if (tokenType[items[i]] == Token.ERC20) {
                IERC20(items[i]).transferFrom(msg.sender, address(this), amounts[i]);
                onERC20Received(address(this), msg.sender, amounts[i], items[i]);
            } else if (tokenType[items[i]] == Token.ERC721) {
                IERC721(items[i]).safeTransferFrom(msg.sender, address(this), tokenIds[i]);
            } else if (tokenType[items[i]] == Token.ERC1155) {
                IERC1155(items[i]).safeTransferFrom(msg.sender, address(this), tokenIds[i], amounts[i], "");
            } else {
                revert(string(abi.encodePacked("Chest: token ", items[i].toHexString(), " is not white listed to be in this chest.")));
            }
        }

        success = true;
    }

    /**
     * @dev Loot a single token in the chest
     *
     * @param item: The address of the token.
     *
     * @param tokenId: The id of token. 
     * @notice For ERC20 token any value will fit.
     *
     * @param amount: The quantity of the token.
     * @notice For ERC721 the quantity must be 1 as any id is a unique NFT.
     *
     * Requirements:
     * 
     * - The token specified in params must be inside the chest.
     * - The amount specified in params must not exceed the amount present in the chest.
     *
     * Emits a {Looted} event.
     */
    function loot(address item, uint256 tokenId, uint256 amount) external virtual nonReentrant notLocked returns (
    address[] memory items, 
    uint256[] memory tokenIds, 
    uint256[] memory amounts, 
    uint8[] memory type_) 
    {
        require(isInside[item][tokenId], "loot: item is not in the chest");
        require(_amountIn[item][tokenId] >= amount, "loot: amount exceed the quantity available in the chest");

        items = new address[](1);
        tokenIds = new uint256[](1);
        amounts = new uint256[](1);
        type_ = new uint8[](1);

        
        if (tokenType[item] == Token.ERC20) {
            IERC20(item).transfer(msg.sender, amount);
        } else if (tokenType[item] == Token.ERC721) {
            IERC721(item).safeTransferFrom(address(this), msg.sender, tokenId);
        } else if (tokenType[item] == Token.ERC1155) {
            IERC1155(item).safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
        }

        items[0] = item;
        tokenIds[0] = tokenId;
        amounts[0] = amount;
        type_[0] = uint8(tokenType[item]);

        chest.opennedCounter.increment();
        chest.lastTimeOpenned = block.timestamp;

        emit Looted(msg.sender, items, tokenIds, amounts);

        _removeTokenFromChest(items, tokenIds, amounts);
    }

    /**
     * @dev Loot a batch of tokens in the chest
     *
     * @param items: The addresses of the tokens to be deposited.
     *
     * @param tokenIds: The id of token to be deposited. 
     * @notice For ERC20 token which don't have id any value will fit.
     *
     * @param amounts: The quantities of the tokens to be deposited.
     * @notice For ERC721 the quantity must be 1 as any id is a unique NFT.
     *
     * WARNING: items <=> tokenIds <=> amounts {indexes} much match each others.
     *
     * Example: Bob want to withdraw 10 DAI token and 1 (ERC721) GOTCHI {id: 21345} and 2 (ERC1155) Aave boat {id: 35}, here is his input.
     * - items = [
        "0x8f3cf7ad23cd3cadbd9735aff958023239c6a063", 
        "0x86935F11C86623deC8a25696E1C19a8659CbF95d", 
        "0x86935F11C86623deC8a25696E1C19a8659CbF95d"
        ],
     * - tokenIds = [{whatever id as it is a ERC20}, 21345, 35],
     * - amounts = ["10", "1", "2"]  
     *
     * Requirements:
     * 
     * - If The length of the 3 params are not equal the Tx will revert.
     * - The token specified in params must be inside the chest.
     * - The amount specified in params must not exceed the amount present in the chest.
     *
     * Emits a {Looted} event.
     */
    function batchLoot(
        address[] memory items, 
        uint256[] memory tokenIds, 
        uint256[] memory amounts
    ) external virtual nonReentrant notLocked returns(
        address[] memory items_, 
        uint256[] memory tokenIds_, 
        uint256[] memory amounts_, 
        uint8[] memory type_)
    {
        require(items.length == tokenIds.length && 
                items.length == amounts.length,
                "batchDeposit: length of items and ids and amounts are not the same.");

        items_ = new address[](items.length);
        tokenIds_ = new uint256[](items.length);
        amounts_ = new uint256[](items.length);
        type_ = new uint8[](items.length);
        
        for (uint i; i < items.length; i++) 
        {
            require(isInside[items[i]][tokenIds[i]], 
                    string(
                        abi.encodePacked(
                            "Chest: token ", 
                            items[i].toHexString(), 
                            "id ", 
                            tokenIds[i].toString(), 
                            " is not white listed to be in this chest."
                        )
                    )
            );
            require(_amountIn[items[i]][tokenIds[i]] >= amounts[i], 
                    string(
                        abi.encodePacked(
                            "Chest: Amount of token ", 
                            items[i].toHexString(), 
                            "id ", 
                            tokenIds[i].toString(), 
                            " exceed the amount present in the chest"
                        )
                    )
            );

            if (tokenType[items[i]] == Token.ERC20) {
                IERC20(items[i]).transfer(msg.sender, amounts[i]);
            } else if (tokenType[items[i]] == Token.ERC721) {
                IERC721(items[i]).safeTransferFrom(address(this), msg.sender, tokenIds[i]);
            } else {
                IERC1155(items[i]).safeTransferFrom(address(this), msg.sender, tokenIds[i], amounts[i], "");
            }

            items_[i] = items[i];
            tokenIds_[i] = tokenIds[i];
            amounts_[i] = amounts[i];
            type_[i] = uint8(tokenType[items[i]]);
        }

        chest.opennedCounter.increment();
        chest.lastTimeOpenned = block.timestamp;

        emit Looted(msg.sender, items_, tokenIds_, amounts_);

        _removeTokenFromChest(items_, tokenIds_, amounts_);
    }

    /***********************************|
   |           Read Functions           |
   |__________________________________*/

    /**
     * @dev Returns the tokens and their amounts in the chest.
     */
   function look() external view returns (
    address[] memory items, 
    uint256[] memory tokenIds, 
    uint256[] memory amounts, 
    uint8[] memory type_) 
    {
        items = new address[](_allTokens.length);
        tokenIds = new uint256[](_allTokens.length);
        amounts = new uint256[](_allTokens.length);
        type_ = new uint8[](_allTokens.length);

        items = _allTokens;
        for (uint i; i < _allTokens.length; i++) {
            tokenIds[i] = _allTokensId[items[i]][i];
            amounts[i] = _amountIn[items[i]][tokenIds[i]];
            type_[i] = uint8(tokenType[items[i]]);
        }    
    }

    /**
     * @dev Support IChest interface.
     */
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IChest).interfaceId;
    }

    /***********************************|
   |        Internal Functions          |
   |__________________________________*/

    /**
     * @dev Remove tokens's all datas from the chest if their amount reach 0.
     * this function is called after a successfull loot.
     *
     * @notice This function is inspired by openzeppelin ERC721 enumerable (openzeppelin/token/ERC721/extensions/ERC721Enumerable.sol)
     */
    function _removeTokenFromChest(
        address[] memory items, 
        uint256[] memory tokenIds, 
        uint256[] memory amounts
    ) internal virtual {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        for (uint i; i < items.length; i++) {

            if (_amountIn[items[i]][tokenIds[i]] - amounts[i] == 0) {
                uint256 tokenIndex = _allTokensIndex[items[i]][tokenIds[i]];

                // Get all datas of the last token as this one will be swapped with the to-delete current token.
                // if the to-delete token is also the last one, it will be swapped by himself and still deleted by the pop function.
                uint256 lastTokenIndex = _allTokens.length - 1;
                address lastTokenAddress = _allTokens[lastTokenIndex];
                uint256 lastTokenId = _allTokensId[lastTokenAddress][lastTokenIndex];

                _allTokens[tokenIndex] = lastTokenAddress; // Move the last token to the slot of the to-delete token
                _allTokensIndex[lastTokenAddress][lastTokenId] = tokenIndex; // Update the moved token's index
                _allTokensId[lastTokenAddress][tokenIndex] = lastTokenId; // Update the moved token's id

                // Delete all the datas of the to-delete "items[i]" token.
                delete _allTokensIndex[items[i]][tokenIds[i]];
                delete _amountIn[items[i]][tokenIds[i]];
                delete isInside[items[i]][tokenIds[i]];
                
                // delete the previous mapping of the token that has been swapped by the to-delete token.
                delete _allTokensId[lastTokenAddress][lastTokenIndex];

                _allTokens.pop();
            } else {
                _amountIn[items[i]][tokenIds[i]] -= amounts[i];
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";

interface IChest {

    event Looted(
        address indexed looter, 
        address[] indexed items, 
        uint256[] indexed tokenIds, 
        uint256[] amounts
    );
    
    function batchDeposit(address[] memory items, uint256[] memory tokenIds, uint256[] memory amounts) external returns(bool success);
    function loot(address item, uint256 tokenId, uint256 amount) external returns(
        address[] memory items, 
        uint256[] memory tokenIds, 
        uint256[] memory amounts, 
        uint8[] memory type_
    );
    function batchLoot(address[] memory items, uint256[] memory tokenIds, uint256[] memory amounts) external returns(
        address[] memory items_, 
        uint256[] memory tokenIds_, 
        uint256[] memory amounts_, 
        uint8[] memory type_
    );
    function look() external view returns(
        address[] memory items, 
        uint256[] memory tokenIds, 
        uint256[] memory amounts, 
        uint8[] memory type_
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


abstract contract ChestHolder is IERC1155Receiver, ERC721Holder, Ownable {
    using Strings for address;

    enum Token { ZERO, ERC20, ERC721, ERC1155 }

    bool private _locked;

    // Check if the token can be stored in the chest (only aavegotchi & GW3S tokens allowed)
    mapping(address => bool) public tokenWhiteListed;

    // Check if ERC20 or ERC721 is in the chest: contract => token id => boolean
    mapping(address => mapping(uint256 => bool)) public isInside;

    // Array with all token address, used for enumeration
    address[] internal _allTokens;

    // Mapping from token address => tokenId => position in the _allTokens array
    mapping(address => mapping(uint256 => uint256)) internal _allTokensIndex;
    
    // Mapping from token address => index in the _allTokens array => tokenId
    mapping(address => mapping(uint256 => uint256)) internal _allTokensId;

    // token address => id => quantity
    mapping(address => mapping(uint256 => uint256)) internal _amountIn;

    // Check if ERC20 or ERC721 is in the chest: contract => token id => boolean
    mapping(address => Token) public tokenType;

    /***********************************|
   |              Modifiers             |
   |__________________________________*/

    /**
     * @dev Throws if locked is set to true.
     */
    modifier notLocked() {
      require(_locked == false, "This chest is actually locked");
        _;
    }


    /***********************************|
   |           Write Functions          |
   |__________________________________*/

     /**
     * @dev When ERC721 is deposited this function is call by the token's smart contract.
     *
     * Requirements:
     *
     * - Revert if the token address is not white listed to be stored in.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data ) public virtual override returns (bytes4) {
      operator; from; data;
      require(tokenWhiteListed[msg.sender] == true, "onRC721Received: Token is not white listed to be stored in the chest");

      if (!isInside[msg.sender][tokenId]) {
        _allTokensId[msg.sender][_allTokens.length] = tokenId;
        _allTokensIndex[msg.sender][tokenId] = _allTokens.length;
        _allTokens.push(msg.sender);

        isInside[msg.sender][tokenId] = true;
      }
      
      _amountIn[msg.sender][tokenId] += 1;
      return this.onERC721Received.selector;
    }

     /**
     * @dev When ERC1155 is deposited this function is call by the token's smart contract.
     *
     * Requirements:
     *
     * - Revert if the token address is not white listed to be stored in.
     */
    function onERC1155Received(
        address operator, 
        address from, 
        uint256 id, 
        uint256 value, 
        bytes calldata data
    ) external virtual returns (bytes4) {
      operator; from; data;
      require(tokenWhiteListed[msg.sender] == true, "onERC1155Received: Token is not white listed to be stored in the chest");

      if (!isInside[msg.sender][id]) {
        _allTokensId[msg.sender][_allTokens.length] = id;
        _allTokensIndex[msg.sender][id] = _allTokens.length;
        _allTokens.push(msg.sender);

        isInside[msg.sender][id] = true;
      }
      _amountIn[msg.sender][id] += value;

      return this.onERC1155Received.selector;
    }

    /**
     * @dev When ERC1155 is batch deposited this function is call by the token's smart contract.
     *
     * Requirements:
     *
     * - Revert if the token address is not white listed to be stored in.
     *
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external virtual returns (bytes4) {
      operator; from; data;
      require(tokenWhiteListed[msg.sender] == true, "onERC1155BatchReceived: Token is not white listed to be stored in the chest");

      for(uint i; i < ids.length; i++) {

        if (!isInside[msg.sender][ids[i]]) {
          _allTokensId[msg.sender][_allTokens.length] = ids[i];
          _allTokensIndex[msg.sender][ids[i]] = _allTokens.length;
          _allTokens.push(msg.sender);

          isInside[msg.sender][ids[i]] = true;
        }
        _amountIn[msg.sender][ids[i]] += values[i];
      }

      return this.onERC1155Received.selector;
    }

    /**
     * @dev When ERC20 is deposited {batchDeposit} this function is call by this smart contract.
     *
     * Requirements:
     *
     * - Revert if the token address must be white listed to be stored in.
     */
    function onERC20Received(address operator, address from, uint256 value, address token) public virtual returns (bytes4) {
      operator; from;
      require(tokenWhiteListed[token] == true, "onERC20Received: Token is not white listed to be stored in the chest");
      
      if (!isInside[token][0]) {
        _allTokensId[token][_allTokens.length] = 0;
        _allTokensIndex[token][0] = _allTokens.length;
        _allTokens.push(token);

        isInside[token][0] = true;
      }
      _amountIn[token][0] += value;

      return this.onERC20Received.selector;
    }

    /**
     * @dev Authorize tokens to be stored in the chest 
     *
     * @param tokens: An array of all the tokens to be white listed to be stored in.
     *
     * Requirements:
     *
     * - Only owner can whitelist
     * - Only ERC20, ERC721, ERC1155 accepted
     */
    function addWhitelist(address[] memory tokens) external onlyOwner {

      for(uint i; i < tokens.length; i++) {

        if (tokens[i].code.length == 0) revert(string(abi.encodePacked("ChestHolder: token ", tokens[i].toHexString(), " is not a smart contract")));

        if (_isERC20(tokens[i])) {
          tokenWhiteListed[tokens[i]] = true;
          tokenType[tokens[i]] = Token.ERC20;
        }
        else if (_isERC721(tokens[i])) {
          tokenWhiteListed[tokens[i]] = true;
          tokenType[tokens[i]] = Token.ERC721;
        }
        else if (_isERC1155(tokens[i])) {
          tokenWhiteListed[tokens[i]] = true;
          tokenType[tokens[i]] = Token.ERC1155;
        }
        else {
          revert(string(abi.encodePacked("ChestHolder: token ", tokens[i].toHexString(), " is not supported. Only ERC20, 721, 1155 is allowed")));
        }
      }
    }

    /**
     * @dev Remove white listed tokens. 
     *
     * @param tokens: An array of all the tokens to be removed of white list.
     *
     * Requirements:
     *
     * - Only owner can remove whitelist
     */
    function removeWhiteList(address[] memory tokens) external onlyOwner {
      for(uint i; i < tokens.length; i++) {
        delete tokenWhiteListed[tokens[i]];
      }
    }

    /**
     * @dev Lock/unlock the chest meaning that no one can loot if it is locked.
     *
     * Requirements:
     *
     * - Only owner can use this lock
     */
    function switchLock() external onlyOwner {
      _locked = !_locked;
    }

    /***********************************|
   |          Private Functions         |
   |__________________________________*/

    /**
     * @dev Check if the given address is a ERC20 standard. 
     *
     * @param addr: The token address to be verified.
     */
    function _isERC20(address addr) private view returns(bool) {
        try ERC20(addr).decimals() returns (uint8 decimals) {
            return decimals > 0;
        } catch {
            return false;
        }
    }

    /**
     * @dev Check if the given address is a ERC721 standard. 
     *
     * @param addr: The token address to be verified.
     */
    function _isERC721(address addr) private view returns(bool) {
        try IERC721(addr).supportsInterface(0x80ac58cd) returns (bool result) {
            return result;
        } catch {
            return false;
        }
    }

    /**
     * @dev Check if the given address is a ERC1155 standard. 
     *
     * @param addr: The token address to be verified.
     */
    function _isERC1155(address addr) private view returns(bool) {
        try IERC1155(addr).supportsInterface(0xd9b67a26) returns (bool result) {
            return result;
        } catch {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}