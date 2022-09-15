/**
 *Submitted for verification at polygonscan.com on 2022-09-15
*/

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/Strings.sol

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

// File: @xaya/eth-account-registry/contracts/IXayaPolicy.sol

// Copyright (C) 2021-2022 Autonomous Worlds Ltd

pragma solidity ^0.8.4;

/**
 * @dev Interface for a contract that defines the validation and fee
 * policy for Xaya accounts, as well as the NFT metadata returned for
 * a particular name.  This contract is the "part" of the Xaya account
 * registry that can be configured by the owner.
 *
 * All fees are denominated in WCHI tokens, this is not configurable
 * by the policy (but instead coded into the non-upgradable parts
 * of the account registry).
 */
interface IXayaPolicy
{

  /**
   * @dev Returns the address to which fees should be paid.
   */
  function feeReceiver () external returns (address);

  /**
   * @dev Verifies if the given namespace/name combination is valid; if it
   * is not, the function throws.  If it is valid, the fee that should be
   * charged is returned.
   */
  function checkRegistration (string memory ns, string memory name)
      external returns (uint256);

  /**
   * @dev Verifies if the given value is valid as a move for the given
   * namespace.  If it is not, the function throws.  If it is, the fee that
   * should be charged is returned.
   *
   * Note that the function does not know the exact name.  This ensures that
   * the policy cannot be abused to censor specific names (and the associated
   * game assets) after they have already been accepted for registration.
   */
  function checkMove (string memory ns, string memory mv)
      external returns (uint256);

  /**
   * @dev Constructs the full metadata URI for a given name.
   */
  function tokenUriForName (string memory ns, string memory name)
      external view returns (string memory);

  /**
   * @dev Returns the contract-level metadata for OpenSea.
   */
  function contractUri () external view returns (string memory);

}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @xaya/eth-account-registry/contracts/IXayaAccounts.sol

// Copyright (C) 2021-2022 Autonomous Worlds Ltd

pragma solidity ^0.8.4;




/**
 * @dev Interface for the Xaya account registry contract.  This is the base
 * component of Xaya on any EVM chain, which keeps tracks of user accounts
 * and their moves.
 */
interface IXayaAccounts is IERC721
{

  /**
   * @dev Returns the address of the WCHI token used for payments
   * of fees and in moves.
   */
  function wchiToken () external returns (IERC20);

  /**
   * @dev Returns the address of the policy contract used.
   */
  function policy () external returns (IXayaPolicy);

  /**
   * @dev Returns the next nonce that should be used for a move with
   * the given token ID.  Nonces start at zero and count up for every move
   * sent.
   */
  function nextNonce (uint256 tokenId) external returns (uint256);

  /**
   * @dev Returns the unique token ID that corresponds to a given namespace
   * and name combination.  The token ID is determined deterministically from
   * namespace and name, so it does not matter if the account has been
   * registered already or not.
   */
  function tokenIdForName (string memory ns, string memory name)
      external pure returns (uint256);

  /**
   * @dev Returns the namespace and name for a token ID, which must exist.
   */
  function tokenIdToName (uint256)
      external view returns (string memory, string memory);

  /**
   * @dev Returns true if the given namespace/name combination exists.
   */
  function exists (string memory ns, string memory name)
      external view returns (bool);

  /**
   * @dev Returns true if the given token ID exists.
   */
  function exists (uint256 tokenId) external view returns (bool);

  /**
   * @dev Registers a new name.  The newly minted account NFT will be owned
   * by the caller.  Returns the token ID of the new account.
   */
  function register (string memory ns, string memory name)
      external returns (uint256);

  /**
   * @dev Sends a move with a given name, optionally attaching a WCHI payment
   * to the given receiver.  For no payment, amount and receiver should be
   * set to zero.
   *
   * If a nonce other than uint256.max is passed, then the move is valid
   * only if it matches exactly the account's next nonce.  The nonce used
   * is returned.
   */
  function move (string memory ns, string memory name, string memory mv,
                 uint256 nonce, uint256 amount, address receiver)
      external returns (uint256);

  /**
   * @dev Computes and returns the message to be signed for permitOperator.
   */
  function permitOperatorMessage (address operator)
      external view returns (bytes memory);

  /**
   * @dev Gives approval as per setApprovalForAll to an operator via a signed
   * permit message.  The owner to whose names permission is given is recovered
   * from the signature and returned.
   */
  function permitOperator (address operator, bytes memory signature)
      external returns (address);

  /**
   * @dev Emitted when a name is registered.
   */
  event Registration (string ns, string name, uint256 indexed tokenId,
                      address owner);

  /**
   * @dev Emitted when a move is sent.  If no payment is attached,
   * then the amount and address are zero.
   */
  event Move (string ns, string name, string mv,
              uint256 indexed tokenId,
              uint256 nonce, address mover,
              uint256 amount, address receiver);

}

// File: contracts/PackGifter.sol

// SPDX-License-Identifier: MIT
// Copyright (C) 2022 Autonomous Worlds Ltd

pragma solidity ^0.8.4;






/**
 * @dev Helper contract for distributing free-to-play packs
 * for Soccerverse.
 *
 * This account holds a balance of MATIC and is approved for WCHI
 * and a sender account on its owner address.  The owner can then gift
 * packs to others, which includes some steps like registering and sending
 * them a name, sending some MATIC and some SMC / share packs.
 *
 * The MATIC sent are from the contract's balance, which needs to stay
 * topped up sufficiently.  Remaining MATIC can be withdrawn by the owner
 * at any time.
 */
contract PackGifter is Ownable, IERC721Receiver
{

  /* ************************************************************************ */

  /** @dev The address of the accounts contract used.  */
  IXayaAccounts public immutable accounts;
  /** @dev The address of the WCHI token.  */
  IERC20 public immutable wchi;

  /** @dev Whether or not the parameters have been initialised.  */
  bool public initialised;

  /** @dev The amount in MATIC to send with a gift pack.  */
  uint256 public coins;

  /** @dev The number of share packs to gift.  */
  uint256 public packs;

  /** @dev The number of SMC to gift.  */
  uint256 public smc;
  /** @dev The number of SMC to gift to referrers.  */
  uint256 public referrer;

  /** @dev WCHI cost (in sat) for a share pack.  */
  uint256 public packCost;
  /** @dev Dev address to receive WCHI for packs.  */
  address public wchiReceiver;
  /** @dev Account name that is sending out the SMC and share packs.  */
  string public senderAccount;

  /**
   * @dev Temporarily set to true while a gift pack is being processed.
   * It allows to receive ERC721 tokens (the name) when set.
   */
  bool internal allowTokenReceive;

  /** @dev Emitted when the parameters are reconfigured.  */
  event Configured (uint256 coins, uint256 packs, uint256 smc,
                    uint256 referrer, uint256 packCost,
                    address wchiReceiver, string senderAccount);

  /** @dev Emitted when a pack is gifted.  */
  event Gifted (address receiver, string name, string referrer);

  /* ************************************************************************ */

  constructor (IXayaAccounts acc)
  {
    accounts = acc;
    wchi = accounts.wchiToken ();
    require (wchi.approve (address (accounts), type (uint256).max),
             "failed to approve WCHI");
  }

  /**
   * @dev Updates the parameters.
   */
  function configure (uint256 coinsNew, uint256 packsNew, uint256 smcNew,
                      uint256 referrerNew, uint256 packCostNew,
                      address wchiReceiverNew,
                      string calldata senderAccountNew)
      public onlyOwner
  {
    initialised = true;

    coins = coinsNew;
    packs = packsNew;
    smc = smcNew;
    referrer = referrerNew;
    packCost = packCostNew;
    wchiReceiver = wchiReceiverNew;
    senderAccount = senderAccountNew;

    emit Configured (coins, packs, smc, referrer,
                     packCost, wchiReceiver, senderAccount);
  }

  /**
   * @dev Withdraws all coins on this account to the owner.
   */
  function withdraw () public onlyOwner
  {
    (bool sent, ) = owner ().call {value: address (this).balance} ("");
    require (sent, "failed to withdraw remaining coins");
  }

  /**
   * @dev We accept ERC-721 token transfers only when in the process
   * of registering a name.
   */
  function onERC721Received (address, address, uint256, bytes calldata)
      public view override returns (bytes4)
  {
    require (allowTokenReceive, "tokens cannot be received at the moment");
    return IERC721Receiver.onERC721Received.selector;
  }

  /**
   * @dev Sending coins to the contract is fine.
   */
  receive () external payable
  {}

  /* ************************************************************************ */

  /**
   * @dev Gifts a pack to someone, with all the things this does.
   *
   * Note that the jsonReferrer and jsonName arguments must be JSON literal
   * strings (including "" around them) prepared by the caller, since they
   * will be used to build up move data with simple concatenation.  Only the
   * owner can call this method, so it is no untrusted user input (in a sense).
   */
  function giftPack (address receiver,
                     string memory name, string memory jsonName,
                     string memory jsonReferrer) public onlyOwner
  {
    require (initialised, "parameters are not initialised yet");

    /* We require that the sender account is owned by the current
       contract owner.  This ensures that there is no confusion and possible
       security issue in case the name was transferred or the contract
       ownership changed.  */
    uint256 senderToken = accounts.tokenIdForName ("p", senderAccount);
    require (accounts.ownerOf (senderToken) == owner (),
             "sender account is not held by contract owner");

    /* Get the required amount of WCHI from the owner to us.  */
    uint256 fee = accounts.policy ().checkRegistration ("p", name);
    uint256 cost = fee + packs * packCost;
    require (wchi.transferFrom (owner (), address (this), cost),
             "failed to get WCHI from owner");

    /* Register and send them their name.  Note that the registration
       throws (and thus also reverts this call) if the name is taken.  */
    allowTokenReceive = true;
    uint256 token = accounts.register ("p", name);
    allowTokenReceive = false;
    accounts.safeTransferFrom (address (this), receiver, token);

    /* Send coins to them.  */
    (bool sent, ) = receiver.call {value: coins} ("");
    require (sent, "failed to send coins in pack");

    /* Build and send the move to gift packs and send SMC to the user.  */
    string memory move = string (abi.encodePacked (
      "{\"g\":{\"smc\":{",
        "\"sc\":{\"u\":", jsonName, ",\"a\":", Strings.toString (smc), "},",
        "\"bp\":{", jsonName, ":", Strings.toString (packs), "}",
      "}}}"
    ));
    accounts.move ("p", senderAccount, move,
                   type (uint256).max, packs * packCost, wchiReceiver);

    /* If there is a referrer, also send them coins.  Sending coins can only
       be done to one user per move, so we need to do it separately.  */
    if (bytes (jsonReferrer).length > 0)
      {
        require (
            keccak256 (bytes (jsonReferrer)) != keccak256 (bytes (jsonName)),
            "referrer is the receiver name");
        move = string (abi.encodePacked (
          "{\"g\":{\"smc\":{",
            "\"sc\":{\"u\":", jsonReferrer,
            ",\"a\":", Strings.toString (referrer), "}",
          "}}}"
        ));
        accounts.move ("p", senderAccount, move,
                       type (uint256).max, 0, address (0));
      }

    emit Gifted (receiver, name, jsonReferrer);
  }

  /* ************************************************************************ */

}