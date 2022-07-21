// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC165} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

import {IStandardProject} from "./projects/IStandard.sol";
import {IDutchAuctionDrop, Project, Implementation} from "./IDutchAuctionDrop.sol";
import {SeededPurchaseHandler} from "./SeededPurchaseHandler.sol";
import {StandardPurchaseHandler} from "./StandardPurchaseHandler.sol";
import {Utils} from "./Utils.sol";

/**
 * @title A dutch auction house, for initial drops of projects
 */
contract DutchAuctionDrop is
  IDutchAuctionDrop,
  Utils,
  SeededPurchaseHandler,
  StandardPurchaseHandler,
  ReentrancyGuard
{
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  // minimum time interval before price can drop in seconds
  uint8 minStepTime;

  bytes4 constant ERC721_interfaceId = 0x80ac58cd; // ERC-721 interface
  bytes4[2] projectImplentaion_interfaceIds;

  // A mapping of project contract addresses to bool, declaring if an auction is active
  mapping (address => bool) private hasActiveAuction;

  // A mapping of all the auctions currently running
  mapping (uint256 => IDutchAuctionDrop.Auction) public auctions;

  Counters.Counter private _auctionIdTracker;

  /**
   * @notice Require that the specified auction exists
   */
  modifier auctionExists(uint256 auctionId) {
    require(_exists(auctionId), "Auction doesn't exist");
    _;
  }

  modifier auctionPurchaseChecks(uint256 auctionId) {
    require(auctions[auctionId].approved, "Auction has not been approved");
    require(block.timestamp >= auctions[auctionId].startTimestamp, "Auction has not started yet");
    require( _numberCanMint(auctionId) != 0, "Sold out");
    _;
  }

  /**
   * Constructor
   */
  constructor() {
    minStepTime = 2 * 60; // 2 minutes
    projectImplentaion_interfaceIds[uint8(Implementation.standard)] = 0x2fc51e5a;
    projectImplentaion_interfaceIds[uint8(Implementation.seeded)] = 0x26057e5e;
  }

  /**
   * @notice Create an auction.
   * @dev Store the auction details in the auctions mapping and emit an AuctionCreated event.
   * If there is no curator, or if the curator is the auction creator,
   * automatically approve the auction and emit an AuctionApproved event.
   * @param project the contract address and implementation of which NFT's will be minted
   * @param startTimestamp the time the auction will start
   * @param duration the duration the auction will run for
   * @param startPrice the price in eth the auction will start at
   * @param endPrice the price in eth the auction will end at
   * @param numberOfPriceDrops the number of times the price will drop between starting and ending price
   * @param curator the address of the allocated curator
   * @param curatorRoyaltyBPS the royalty the curator will recieve per purchase in basis points
   * @return auction id
   */
  function createAuction(
    Project memory project,
    uint256 startTimestamp,
    uint256 duration,
    uint256 startPrice,
    uint256 endPrice,
    uint8 numberOfPriceDrops,
    address curator,
    uint256 curatorRoyaltyBPS,
    address auctionCurrency
  ) external override nonReentrant returns (uint256) {
    require(
      IERC165(project.id).supportsInterface(ERC721_interfaceId),
      "Doesn't support NFT interface"
    );

    require(
      IERC165(project.id).supportsInterface(
        projectImplentaion_interfaceIds[uint8(project.implementation)]
      ),
      "Doesn't support chosen Editions interface"
    );

    address creator = IStandardProject(project.id).owner();
    require(msg.sender == creator, "Caller must be creator of project");
    require(hasActiveAuction[project.id] == false, "Auction already exists");
    require(startPrice > endPrice, "Start price must be higher then end price");

    if(curator == address(0)){
      require(curatorRoyaltyBPS == 0, "Royalties would be sent into the void");
    }

    require(duration.div(numberOfPriceDrops) >= minStepTime, "Step time must be higher than minimuim step time");

    uint256 auctionId = _auctionIdTracker.current();

    auctions[auctionId] = Auction({
      project: project,
      startTimestamp: startTimestamp,
      duration: duration,
      startPrice: startPrice,
      endPrice: endPrice,
      numberOfPriceDrops: numberOfPriceDrops,
      creator: creator,
      approved: false,
      curator: curator,
      curatorRoyaltyBPS: curatorRoyaltyBPS,
      auctionCurrency: auctionCurrency,
      collectorGiveAway: false
    });

    // set project to active auction
    hasActiveAuction[project.id] = true;

    _auctionIdTracker.increment();

    emit AuctionCreated(
      auctionId,
      creator,
      project,
      startTimestamp,
      duration,
      startPrice,
      endPrice,
      numberOfPriceDrops,
      curator,
      curatorRoyaltyBPS,
      auctionCurrency
    );

    // auto approve auction
    if(curator == address(0) || curator == creator){
      _approveAuction(auctionId, true);
    }

    return auctionId;
  }

  /**
   * @dev mints a NFT and splits purchase fee between creator and curator
   * @param auctionId the id of the auction
   * @param value the amount paid in erc-20 tokens to mint
   * @return id of the NFT
   */
  function purchase(
    uint256 auctionId,
    uint256 value
  ) external payable override
    auctionExists(auctionId)
    auctionPurchaseChecks(auctionId)
    returns (uint256)
  {
    return _handleStandardPurchase(auctionId, auctions[auctionId], value);
  }

  /**
   * @dev mints a seeded NFT and splits purchase fee between creator and curator
   * @param auctionId the id of the auction
   * @param value the amount paid in erc-20 tokens to mint
   * @param seed the seed of the NFT to mint
   * @return id of the NFT
   */
  function purchase(
    uint256 auctionId,
    uint256 value,
    uint256 seed
  ) external payable override
    auctionExists(auctionId)
    auctionPurchaseChecks(auctionId)
    returns (uint256)
  {
    return _handleSeededPurchase(auctionId, auctions[auctionId], value, seed);
  }

  function numberCanMint(uint256 auctionId) external view override returns (uint256) {
    return _numberCanMint(auctionId);
  }

  /**
   * @notice allows curator to approve auction
   * @dev sets auction approved to approval and emits an AuctionApprovalUpdated event
   * @param auctionId the id of the auction
   * @param approved the curators approval decision
   */
  function setAuctionApproval(uint256 auctionId, bool approved) external override auctionExists(auctionId) {
    require(msg.sender == auctions[auctionId].curator, "must be curator");
    require(block.timestamp < auctions[auctionId].startTimestamp, "Auction has already started");
    // TODO: see if auction should be cancled/ended if approval is set to false?
    _approveAuction(auctionId, approved);
  }

  /**
   * @notice allows the creator to trigger a collector only give away once an auction is over
   * @dev sets auction collectorGiveAway to giveAway and emits an CollectorGiveAwayUpdated event
   * @param auctionId the id of the auction
   * @param giveAway the creators giveAway decision
   */
  function setCollectorGiveAway(
    uint256 auctionId,
    bool giveAway
  ) external
    override
    auctionExists(auctionId)
  {
    require(
      msg.sender == auctions[auctionId].creator,
      "Must be creator"
    );
    require(
      block.timestamp > auctions[auctionId].startTimestamp.add(auctions[auctionId].duration),
      "Auction is not over"
    );

    auctions[auctionId].collectorGiveAway = giveAway;

    emit CollectorGiveAwayUpdated(
      auctionId,
      auctions[auctionId].project.id,
      giveAway
    );
  }

  /**
   * @notice gets the current sale price of an auction
   * @dev calculates the price based on the block.timestamp
   * @param auctionId the id of the auction
   * @return price in wei
   */
  function getSalePrice(uint256 auctionId) external view override returns (uint256) {
    return _getSalePrice(auctions[auctionId]);
  }

    /**
   * @notice allows creator or curator to cancel an auction before it's started
   * @dev the caller must be creator or curator and the auction must either
   * not of started yet or not been approved by the curator
   * @param auctionId the id of the auction
   */
  function cancelAuction(uint256 auctionId) external override {
    require(
      msg.sender == auctions[auctionId].creator || msg.sender == auctions[auctionId].curator,
      "Must be creator or curator"
    );

    if(!auctions[auctionId].approved){
      _cancelAuction(auctionId);
      return;
    }

    // ensure auction has not started or not been approved
    require(
      block.timestamp < auctions[auctionId].startTimestamp,
      "Auction has already started"
    );

    _cancelAuction(auctionId);
  }

  function endAuction(uint256 auctionId) external override {
    require(
      msg.sender == auctions[auctionId].creator || msg.sender == auctions[auctionId].curator,
      "Must be creator or curator"
    );

    // check the auction has run it's full duration
    require(
      block.timestamp > auctions[auctionId].startTimestamp + auctions[auctionId].duration,
      "Auction is not over"
    );

    emit AuctionEnded(auctionId, auctions[auctionId].project.id);
    hasActiveAuction[auctions[auctionId].project.id] = false;
    delete auctions[auctionId];
  }

  /**
   * @dev emits auction canceled, sets has ativeauction to false and deletes the auction from storage
   * @param auctionId the id of the auction
   */
  function _cancelAuction(uint256 auctionId) internal {
    emit AuctionCanceled(auctionId, auctions[auctionId].project.id);
    hasActiveAuction[auctions[auctionId].project.id] = false;
    delete auctions[auctionId];
  }

  function _numberCanMint(uint256 auctionId) internal view returns (uint256) {
    return IStandardProject(auctions[auctionId].project.id).numberCanMint();
  }

  function _exists(uint256 auctionId) internal view returns(bool) {
    return auctions[auctionId].creator != address(0);
  }

  function _approveAuction(uint256 auctionId, bool approved) internal {
    auctions[auctionId].approved = approved;
    emit AuctionApprovalUpdated(auctionId, auctions[auctionId].project.id, approved);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

interface IStandardProject {
  function mintEdition(address to) external returns (uint256);
  function mintEditions(address[] memory to) external returns (uint256);
  function numberCanMint() external view returns (uint256);
  function owner() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

enum Implementation {
  standard,
  seeded
}

struct Project {
  address id;
  Implementation implementation;
}

interface IDutchAuctionDrop {
  struct Auction {
    Project project;
    uint256 startTimestamp;
    uint256 duration;
    uint256 startPrice;
    uint256 endPrice;
    uint8 numberOfPriceDrops;
    address creator;
    bool approved;
    address curator;
    uint256 curatorRoyaltyBPS;
    address auctionCurrency;
    bool collectorGiveAway;
  }

  event EditionPurchased(
    uint256 auctionId,
    address project,
    uint256 editionId,
    uint256 price,
    address owner
  );

  event SeededEditionPurchased(
    uint256 auctionId,
    address project,
    uint256 editionId,
    uint256 seed,
    uint256 price,
    address owner
  );

  event AuctionCreated(
    uint256 auctionId,
    address creator,
    Project project,
    uint256 startTimestamp,
    uint256 duration,
    uint256 startPrice,
    uint256 endPrice,
    uint8 numberOfPriceDrops,
    address curator,
    uint256 curatorRoyaltyBPS,
    address auctionCurrency
  );

  event AuctionApprovalUpdated(
    uint256 auctionId,
    address project,
    bool approved
  );

  event CollectorGiveAwayUpdated(
    uint256 auctionId,
    address project,
    bool giveAway
  );

  event AuctionCanceled(
    uint256 auctionId,
    address project
  );

  event AuctionEnded(
    uint256 auctionId,
    address project
  );

  function createAuction(
    Project memory project,
    uint256 startTimestamp,
    uint256 duration,
    uint256 startPrice,
    uint256 endPrice,
    uint8 numberOfPriceDrops,
    address curator,
    uint256 curatorRoyaltyBPS,
    address auctionCurrency
  ) external returns (uint256);

  function setAuctionApproval(uint auctionId, bool approved) external;

  function setCollectorGiveAway(uint256 auctionId, bool giveAway) external;

  function getSalePrice(uint256 auctionId) external returns (uint256);

  function purchase(uint256 auctionId, uint256 amount) external payable returns (uint256);
  function purchase(uint256 auctionId, uint256 amount, uint256 seed) external payable returns (uint256);

  function numberCanMint(uint256 auctionId) external view returns (uint256);

  function cancelAuction(uint256 auctionId) external;

  function endAuction(uint256 auctionId) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import {ISeededProject, MintData} from "./projects/ISeeded.sol";
import {IDutchAuctionDrop, Project, Implementation} from "./IDutchAuctionDrop.sol";
import {Utils} from "./Utils.sol";

abstract contract SeededPurchaseHandler is IDutchAuctionDrop, Utils {
  function _handleSeededPurchase(uint256 auctionId, Auction memory auction, uint256 value, uint256 seed) internal returns (uint256){
    // check project is seeded implementation
    require(
      auction.project.implementation == Implementation.seeded,
      "Must be seeded edition contract"
    );

    // cache
    uint256 atEditionId;

    if(auction.collectorGiveAway){
      return  _handleSeededCollectorGiveAway(auctionId, auction, seed);
    }

    // check value is more or equal to current sale price
    uint256 salePrice = _getSalePrice(auction);
    require(value >= salePrice, "Must be more or equal to sale price");

    // if not free handle payment
    if(salePrice != 0){
      _handlePurchasePayment(auction, salePrice);
    }

    atEditionId = _handleSeededMint(auction, seed);

    emit SeededEditionPurchased(
      auctionId,
      auction.project.id,
      atEditionId - 1,
      seed,
      salePrice,
      msg.sender
    );

    return atEditionId;
  }

  function _handleSeededCollectorGiveAway(uint256 auctionId, Auction memory auction, uint256 seed) internal returns (uint256){
    require(
      _isCollector(auction.project.id, msg.sender),
      "Must be a collector"
    );

    uint256 atEditionId = _handleSeededMint(auction, seed);

    emit SeededEditionPurchased(
      auctionId,
      auction.project.id,
      atEditionId - 1,
      seed,
      0,
      msg.sender
    );

    return atEditionId;
  }

  function _handleSeededMint(Auction memory auction, uint256 seed) internal returns (uint256) {
    MintData[] memory toMint = new MintData[](1);
    toMint[0] = MintData(msg.sender, seed);

    // mint new nft
    return ISeededProject(auction.project.id).mintEditions(toMint);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import {IStandardProject} from "./projects/IStandard.sol";
import {IDutchAuctionDrop, Project, Implementation} from "./IDutchAuctionDrop.sol";
import {Utils} from "./Utils.sol";

abstract contract StandardPurchaseHandler is IDutchAuctionDrop, Utils {
  function _handleStandardPurchase(uint256 auctionId, Auction memory auction, uint256 value) internal returns (uint256){
    // check edtions contract is standard implementation
    require(
      auction.project.implementation == Implementation.standard,
      "Must be edition contract"
    );

    if(auction.collectorGiveAway){
      return _handleStandardCollectorGiveAway(auctionId, auction);
    }

    uint256 salePrice = _getSalePrice(auction);
    require(value >= salePrice, "Must be more or equal to sale price");

    // if not free carry out purchase
    if(salePrice != 0){
      _handlePurchasePayment(auction, salePrice);
    }

    uint256 atEditionId = _handleStandardMint(auction);

    emit EditionPurchased(
      auctionId,
      auction.project.id,
      atEditionId - 1,
      salePrice,
      msg.sender
    );

    return atEditionId;
  }

  function _handleStandardCollectorGiveAway(uint256 auctionId, Auction memory auction) internal returns (uint256){
    require(
      _isCollector(auction.project.id, msg.sender),
      "Must be a collector"
    );

    uint256 atEditionId = _handleStandardMint(auction);

    emit EditionPurchased(
      auctionId,
      auction.project.id,
      atEditionId - 1,
      0,
      msg.sender
    );

    return atEditionId;
  }

  function _handleStandardMint(Auction memory auction) internal returns (uint256) {
    address[] memory toMint = new address[](1);
    toMint[0] = msg.sender;

    // mint new nft
    return IStandardProject(auction.project.id).mintEditions(toMint);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import {IDutchAuctionDrop} from "./IDutchAuctionDrop.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ERC721 {
  function balanceOf(address owner) external view returns (uint256);
  function royaltyInfo(uint256, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount);
}

abstract contract Utils is IDutchAuctionDrop {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  function _isCollector(address editionId, address collector) internal view returns (bool) {
    return (ERC721(editionId).balanceOf(collector) > 0);
  }

  function _handlePurchasePayment(Auction memory auction, uint256 salePrice) internal{
    IERC20 token = IERC20(auction.auctionCurrency);

    // We must check the balance that was actually transferred to this contract,
    // as some tokens impose a transfer fee and would not actually transfer the
    // full amount to the market, resulting in potentally locked funds
    uint256 beforeBalance = token.balanceOf(address(this));
    token.safeTransferFrom(msg.sender, address(this), salePrice);
    uint256 afterBalance = token.balanceOf(address(this));
    require(beforeBalance + salePrice == afterBalance, "_handleIncomingTransfer token transfer call did not transfer expected amount");

    // get receiver for funds from project
    // tokenId can be set to 0 as all have the same royalties
    // returned royalty amount is ignored as it's the initial sale
    (address receiver, ) = ERC721(auction.project.id).royaltyInfo(0, salePrice);

    // if no curator, add payment to creator
    if(auction.curator == address(0)){
      token.safeTransfer(
        receiver,
        salePrice
      );
    }

    // else split payment between curator and creator
    else {
      uint256 curatorFee = (salePrice.mul(auction.curatorRoyaltyBPS)).div(10000);
      token.safeTransfer(
        auction.curator,
        curatorFee
      );

      uint256 creatorFee = salePrice.sub(curatorFee);
      token.safeTransfer(
        receiver,
        creatorFee
      );
    }

    return;
  }

  function _getSalePrice(Auction memory auction) internal view returns (uint256) {
    // return endPrice if auction is over
    if(block.timestamp > auction.startTimestamp.add(auction.duration)){
      return auction.endPrice;
    }

    uint256 stepTime = _calcStepTime(auction);

    // return startPrice if auction hasn't started yet
    if(block.timestamp < auction.startTimestamp.add(stepTime)){
      return auction.startPrice;
    }

    // calculate price based of block.timestamp
    uint256 timeSinceStart = block.timestamp.sub(auction.startTimestamp);
    uint256 dropNum = _floor(timeSinceStart, stepTime).div(stepTime);

    uint256 stepPrice = _calcStepPrice(auction);

    uint256 price = auction.startPrice.sub(stepPrice.mul(dropNum));

    return _floor(
      price,
      _unit10(stepPrice, 2)
    );
  }

  function _calcStepPrice(
    Auction memory auction
  ) internal pure returns (uint256) {
      return auction.startPrice.sub(auction.endPrice).div(auction.numberOfPriceDrops);
  }

  function _calcStepTime(
    Auction memory auction
  ) internal pure returns (uint256) {
      return auction.duration.div(auction.numberOfPriceDrops);
  }

  /**
   * @dev floors number to nearest specified unit
   * @param value number to floor
   * @param unit number specififying the smallest uint to floor to
   * @return result number floored to nearest unit
  */
  function _floor(uint256 value, uint256 unit) internal pure returns (uint256){
    uint256 remainder = value.mod(unit);
    return value - remainder;
  }

  /** @dev calculates exponent from given value number of digits minus the offset
   * and returns 10 to the power of the resulting exponent
   * @param value the number of which the exponent is calculated from
   * @param exponentOffset the number to offset the resulting exponent
   * @return result 10 to the power of calculated exponent
   */
  function _unit10(uint256 value, uint256 exponentOffset) internal pure returns (uint256){
    uint256 exponent = _getDigits(value);

    if (exponent == 0) {
        return 0;
    }

    if(exponent < exponentOffset || exponentOffset == 0){
      exponentOffset = 1;
    }

    return 10**(exponent - exponentOffset);
  }

   /**
    * @dev gets number of digits of a number
    * @param value number to count digits of
    * @return digits number of digits in value
    */
  function _getDigits(uint256 value) internal pure returns (uint256) {
      if (value == 0) {
          return 0;
      }
      uint256 digits;
      while (value != 0) {
          digits++;
          value /= 10;
      }
      return digits;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

struct MintData {
  address to;
  uint256 seed;
}

interface ISeededProject {
  function mintEdition(address to, uint256 seed) external returns (uint256);
  function mintEditions(MintData[] memory to) external returns (uint256);
  function numberCanMint() external view returns (uint256);
  function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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