// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC721 } from "./utils/IERC721.sol";
import { IERC20 } from "./utils/IERC20.sol";
import { ICardMarket } from "./ICardMarket.sol";
import { IGifter } from "./IGifter.sol";
import { BasePlusFacet } from "./BasePlusFacet.sol";
import { IDex } from "./IDex.sol";
import { AppStorage, GiftParams, GiftData, Asset, Card, TokenType } from './Lib.sol';

contract GifterFacet is BasePlusFacet, IGifter, IERC721Receiver {
  using SafeMath for uint;

  // IGifter

  function gift(uint _id) view external override returns (
    GiftParams memory params,
    address sender,
    uint timestamp,
    uint created,
    uint claimed,
    bool opened,
    string memory contentHash
  ) {
    params = s.gifts[_id].params;
    sender = s.gifts[_id].sender;
    timestamp = s.gifts[_id].timestamp;
    created = s.gifts[_id].created;
    claimed = s.gifts[_id].claimed;
    opened = s.gifts[_id].opened;
    contentHash = s.gifts[_id].contentHash;
  }

  function totalSent(address _sender) view external override returns (uint) {
    return s.totalGiftsSent[_sender];
  }

  function sent(address _sender, uint _index) view external override returns (uint) {
    return s.sentGift[_sender][_index];
  }

  function defaultGiftContentHash() external view returns (string memory) {
    return s.defaultGiftContentHash;
  }

  function setDefaultGiftContentHash(string calldata _contentHash) external override isAdmin {
    s.defaultGiftContentHash = _contentHash;
  }

  function baseURI() external view returns (string memory) {
    return s.baseURI;
  }

  function setBaseURI(string calldata _baseURI) external override isAdmin {
    s.baseURI = _baseURI;
  }

  function claim(uint _tokenId) public override isOwner(_tokenId) {
    GiftData storage g = s.gifts[_tokenId];

    // check and flip flag
    require(g.claimed == 0, "Gifter: already claimed");
    g.claimed = block.number;

    // erc20
    for (uint i = 0; i < g.params.erc20.length; i += 1) {
      Asset storage asset = g.params.erc20[i];
      require(IERC20(asset.tokenContract).transfer(_msgSender(), asset.value), "ERC20 transfer failed");
    }

    // nft
    for (uint i = 0; i < g.params.nft.length; i += 1) {
      Asset storage asset = g.params.nft[i];
      IERC721(asset.tokenContract).safeTransferFrom(address(this), _msgSender(), asset.value);
    } 

    // wei
    if (g.params.weiValue > 0) {
      payable(_msgSender()).transfer(g.params.weiValue);
    }

    emit Claimed(_tokenId);
  }

  function openAndClaim(uint _tokenId, string calldata _contentHash) external override isOwner(_tokenId) {
    GiftData storage g = s.gifts[_tokenId];

    // check and flip flag
    require(!g.opened, "Gifter: already opened");
    g.opened = true;
    g.contentHash = _contentHash;

    if (g.claimed == 0) {
      claim(_tokenId);
    }
  }

  function create(GiftParams calldata _params) payable external override {
    address sender = _msgSender();

    // new gift id
    uint id = _getNewTokenId();

    // save data
    GiftData storage g = s.gifts[id];
    g.sender = sender;
    g.created = block.number;
    g.timestamp = block.timestamp;
    g.contentHash = s.defaultGiftContentHash;
    g.params.config = _params.config;
    g.params.recipient = _params.recipient;
    g.params.weiValue = _params.weiValue;
    g.params.fee = _params.fee;

    // erc20
    for (uint i = 0; i < _params.erc20.length; i += 1) {
      Asset calldata asset = _params.erc20[i];
      require(IERC20(asset.tokenContract).transferFrom(_msgSender(), address(this), asset.value), "ERC20 transfer failed");
      g.params.erc20.push(asset);
    }

    // nft
    for (uint i = 0; i < _params.nft.length; i += 1) {
      Asset calldata asset = _params.nft[i];
      IERC721(asset.tokenContract).safeTransferFrom(_msgSender(), address(this), asset.value);
      g.params.nft.push(asset);
    }

    // mint NFT
    _mint(_params.recipient, id, 1, bytes(""), TokenType.GIFT);

    // check and pay card design fee
    uint cardId;
    bytes memory config = g.params.config;
    assembly {
      cardId := mload(add(config, 0x20))
    }

    _useCard(cardId, msg.value.sub(_params.weiValue));

    // update sender info
    s.totalGiftsSent[sender] += 1;
    s.sentGift[sender][s.totalGiftsSent[sender]] = id;

    // event
    emit Created(id, _params.message);
  }

  // IERC721Receiver

  function onERC721Received(
      address /*operator*/,
      address /*from*/,
      uint256 /*tokenId*/,
      bytes calldata /*data*/
  ) external pure returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }

  // Private methods

  function _useCard(uint _id, uint _inputFee) private {
    Card storage c = s.cards[_id];
    Asset storage fee = c.params.fee;

    require(c.enabled, "Gifter: card not enabled");

    IDex(s.dex).trade{value: _inputFee}(
      fee.tokenContract, 
      fee.value, 
      address(this)
    );

    uint earned = (10000 - s.tax) * fee.value / 10000;
    address o = s.tokens.owner[_id];
    s.cardOwnerEarningsPerToken[o][fee.tokenContract] = s.cardOwnerEarningsPerToken[o][fee.tokenContract].add(earned);
    s.totalEarningsPerToken[fee.tokenContract] = s.totalEarningsPerToken[fee.tokenContract].add(earned);
    uint thisTax = fee.value.sub(earned);
    s.totalTaxesPerToken[fee.tokenContract] = s.totalTaxesPerToken[fee.tokenContract].add(thisTax);

    emit UseCard(_id, fee.value, earned, thisTax);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * See https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC721
 */
interface IERC721 {
  function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId
  ) external;  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * See https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC20
 */
interface IERC20 {
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { CardParams, Asset } from "./Lib.sol";
import { IDex } from "./IDex.sol";


interface ICardMarket {
  /**
   * @dev Get card info.
   *
   * @param _id Card id.
   */
  function card(uint _id) view external returns (
    /* struct getter return values must be fully spelled out - https://github.com/ethereum/solidity/issues/11826 */
    CardParams memory params,
    bool enabled
  );

  /**
   * Get card id by CID.
   * 
   * @param _contentHash CID.
   */
  function cardIdByCid(string calldata _contentHash) view external returns (uint);

  /**
   * @dev Add a new card.
   *
   * The admin approval signature must be the `contentHash` signed by the admin's private key.
   *
   * @param _params Parameters.
   * @param _owner Card owner.
   * @param _adminApproval Admin approval signature.
   */
  function addCard(CardParams calldata _params, address _owner, bytes calldata _adminApproval) external;

  /**
   * @dev Set card fee.
   *
   * @param _fee Card fee.
   */
  function setCardFee(uint _id, Asset calldata _fee) external;

  /**
   * @dev Set a card as enabled or disabled.
   *
   * @param _id The card id.
   * @param _enabled true to enable, false to disable.
   */
  function setCardEnabled(uint _id, bool _enabled) external;

  /**
   * Calcualte hash for admins to digitally sign.
   * 
   * @param contentHash CID hash.
   */
  function calculateSignatureHash(string calldata contentHash) external pure returns (bytes32);

  /**
   * Get dex.
   */
  function dex() external view returns (IDex);

  /**
   * Set dex.
   *
   * @param _dex Dex to use.
   */
  function setDex(address _dex) external;

  /**
   * Get card usage tax.
   */
  function tax() external view returns (uint);

  /**
   * Set card usage tax.
   *
   * @param _tax Tax rate in basis points (100 = 1%).
   */
  function setTax(uint _tax) external;

  /**
   * Get allowed fee tokens.
   */
  function allowedFeeTokens() external view returns (address[] memory);

  /**
   * Get whether given token is allowed to be used as a fee token.
   *
   * @param _token The token.
   */
  function feeTokenAllowed(address _token) view external returns (bool);

  /**
   * Set allowed fee tokens.
   *
   * @param _feeTokens Allowed fee tokens.
   */
  function setAllowedFeeTokens(address[] calldata _feeTokens) external;

  /**
   * Get total accumulated withdrawable taxes.
   *
   * @param _feeToken The fee token.
   */
  function totalTaxes(address _feeToken) external view returns (uint);

  /**
   * Withdrawable accumulated taxes.
   *
   * @param _feeToken the fee token.
   */
  function withdrawTaxes(address _feeToken) external;

  /**
   * Get total accumulated withdrawable earnings for all wallets.
   *
   * @param _feeToken the fee token.
   */
  function totalEarnings(address _feeToken) external view returns (uint);

  /**
   * Get accumulated withdrawable earnings for given wallet.
   *
   * @param _wallet Wallet to check for.
   * @param _feeToken the fee token.
   */
  function earnings(address _wallet, address _feeToken) external view returns (uint);

  /**
   * Withdraw caller's accumulated earnings.
   *
   * @param _feeToken the fee token.
   */
  function withdrawEarnings(address _feeToken) external;

  /**
   * @dev Emitted when a new card gets added.
   * @param id The card NFT token id.
   */
  event AddCard( uint id );  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { GiftParams } from "./Lib.sol";

interface IGifter {
  /**
   * @dev Get gift info.
   *
   * @param _id Gift id.
   */
  function gift(uint _id) view external returns (
    /* struct getter return values must be fully spelled out - https://github.com/ethereum/solidity/issues/11826 */
    GiftParams memory params,
    address sender,
    uint timestamp,
    uint created,
    uint claimed,
    bool opened,
    string memory contentHash
  );

  /**
   * Get total no. of GFTs sent by given sender.
   *
   * @param _sender The sender.
   */
  function totalSent(address _sender) view external returns (uint);

  /**
   * Get GFT at given index sent by given sender.
   *
   * @param _sender The sender.
   * @param _index 0-based index.
   */
  function sent(address _sender, uint _index) view external returns (uint);

  /**
   * @dev Create a new gift.
   *
   * @param _params Gift params.
  */
  function create(GiftParams calldata _params) payable external;

  /**
   * @dev Claim the assets within the gift without opening it.
   *
   * @param _tokenId The gift token id.
   */
  function claim(uint _tokenId) external;

  /**
   * @dev Open the gift and claim the assets within.
   *
   * @param _tokenId The gift token id.
   * @param _contentHash The decentralized content hash for fetching the metadata representing the opened card.
   */
  function openAndClaim(uint _tokenId, string calldata _contentHash) external;

  /**
   * Get default decentralized content hash for gifts.
   */
  function defaultGiftContentHash() external view returns (string memory);

  /**
   * Set default decentralized content hash for gifts.
   *
   * The decentralied content hash is used to fetch the metadata representing an un-opened card.
   * 
   * @param _contentHash New default content hash.
   */
  function setDefaultGiftContentHash(string calldata _contentHash) external;

  /**
   * Get base URI for all metadata URIs.
   */
  function baseURI() external view returns (string memory);

  /**
   * Set base URI for all metadata URIs.
   * @param _baseURI base URI.
   */
  function setBaseURI(string calldata _baseURI) external;

  /**
   * @dev Emitted when a new gift gets created.
   * @param id The gift token id.
   * @param message Card message.
   */
  event Created(
    uint indexed id,
    string message
  );  

  /**
   * @dev Emitted when a gift gets claimed.
   * @param id The gift token id.
   */
  event Claimed(
    uint indexed id
  );  

  /**
   * @dev Emitted when a card gets used.
   * @param cardId The card NFT token id.
   * @param fee The total fee.
   * @param earned The actual fee earned by owner.
   * @param tax The actual tax taken from the fee.
   */
  event UseCard(
    uint cardId,
    uint fee,
    uint earned,
    uint tax
  );  
}

// SPDX-License-Identifier: MIT
// Based on OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)
pragma solidity ^0.8.0;


import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import { BaseFacet } from "./BaseFacet.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { AppStorage ,TokenType } from './Lib.sol';


abstract contract BasePlusFacet is BaseFacet {
  using Address for address;

  /**
    * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
    * Taken from IERC115
    */
  event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

  function _mint(
    address to,
    uint id,
    uint amount,
    bytes memory data,
    TokenType tokenType
  ) internal virtual {
    require(to != address(0), "ERC1155: mint to the zero address");

    address operator = _msgSender();

    s.tokens.balances[id][to] += amount;
    emit TransferSingle(operator, address(0), to, id, amount);

    s.tokens.types[id] = tokenType;
    s.tokens.totalByType[tokenType] += 1;
    s.tokens.byType[tokenType][s.tokens.totalByType[tokenType]] = id;

    _postSafeTransfer(operator, address(0), to, id, amount, data);
  }

  function _postSafeTransfer(
    address operator,
    address from,
    address to,
    uint id,
    uint amount,
    bytes memory data
  ) internal {
    if (to.isContract()) {
      try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
        if (response != IERC1155Receiver.onERC1155Received.selector) {
          revert("ERC1155: ERC1155Receiver rejected tokens");
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert("ERC1155: transfer to non ERC1155Receiver implementer");
      }
    }

    _updateTokenOwnerInfo(from, to, id);
  }

  function _postSafeBatchTransfer(
    address operator,
    address from,
    address to,
    uint[] memory ids,
    uint[] memory amounts,
    bytes memory data
  ) internal {
    if (to.isContract()) {
      try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
        bytes4 response
      ) {
        if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
          revert("ERC1155: ERC1155Receiver rejected tokens");
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert("ERC1155: transfer to non ERC1155Receiver implementer");
      }
    }

    for (uint i = 0; i < ids.length; i += 1) {
      if (s.tokens.types[ids[i]] != TokenType.INVALID) {
        _updateTokenOwnerInfo(from, to, ids[i]);
      }
    }
  }

  function _updateTokenOwnerInfo(address from, address to, uint id) internal {
    TokenType t = s.tokens.types[id];
    require(t != TokenType.INVALID, "Token type must be set");
    
    if (from != address(0)) {
      uint total = s.tokens.totalOwnedByType[from][t];
      uint ind = s.tokens.ownedIndexByTypeAndId[from][t][id];
      s.tokens.ownedIndexByTypeAndId[from][t][id] = 0;
      if (ind < total) {
        s.tokens.ownedIdByTypeAndIndex[from][t][ind] = s.tokens.ownedIdByTypeAndIndex[from][t][total];
        s.tokens.ownedIdByTypeAndIndex[from][t][total] = 0;
      }
      s.tokens.totalOwnedByType[from][t] -= 1;
    }

    s.tokens.totalOwnedByType[to][t] += 1;
    uint toTotal = s.tokens.totalOwnedByType[to][t];
    s.tokens.ownedIndexByTypeAndId[to][t][id] = toTotal;
    s.tokens.ownedIdByTypeAndIndex[to][t][toTotal] = id;

    s.tokens.owner[id] = to;
  }
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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