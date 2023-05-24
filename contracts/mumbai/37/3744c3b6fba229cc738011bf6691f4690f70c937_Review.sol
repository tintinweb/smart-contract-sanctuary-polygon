// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    /// uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    /// `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

pragma solidity ^0.8.1;

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
// copied from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.1;

import "./Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
// copied from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/metatx/ERC2771Context.sol
abstract contract ERC2771Context is Context {
    address private immutable _trustedForwarder;

    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder)
        public
        view
        virtual
        returns (bool)
    {
        return forwarder == _trustedForwarder;
    }

    function _msgSender()
        internal
        view
        virtual
        override
        returns (address sender)
    {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData()
        internal
        view
        virtual
        override
        returns (bytes calldata)
    {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// solhint-disable avoid-low-level-calls
// solhint-disable private-vars-leading-underscore
/// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import {ByteHasher} from "./helpers/ByteHasher.sol";
import {IWorldID} from "./interfaces/IWorldID.sol";
import {IInterchainQueryRouter} from './interfaces/IInterchainQueryRouter.sol';
import {IInterchainGasPaymaster} from './interfaces/IInterchainGasPaymaster.sol';

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import {IERC165} from "forge-std/interfaces/IERC165.sol";
import {ERC2771Context} from "relay-context-contracts/vendor/ERC2771Context.sol";
import './constants/Call.sol';

contract Review is ERC2771Context {
    using ByteHasher for bytes;

    /// Token => EOA => hasCommented
    mapping(address => mapping(address => bool)) public accountReviewedToken;
    /// Token => tokenId => EOA => hasCommented
    mapping(address => mapping(uint256 => mapping(address => bool))) public accountReviewedERC1155;
    /// EOA => counter
    mapping(address => uint256) public counter;

    bytes32 public immutable name = "Transparenza";
    bytes4 private immutable _interfaceIdERC1155 = 0xd9b67a26;
    bytes4 private immutable _interfaceIdERC721 = 0x80ac58cd;

    /// @notice Thrown when attempting to reuse a nullifier
    error InvalidNullifier();

    /// @dev The World ID instance that will be used for verifying proofs
    IWorldID internal immutable worldId;

    /// @dev The contract's external nullifier hash
    uint256 internal immutable externalNullifier;

    /// @dev The World ID group ID (always 1)
    uint256 internal immutable groupId = 1;

    address constant iqsRouter = 0x234b19282985882d6d6fd54dEBa272271f4eb784;

    /// @dev Whether a nullifier hash has been used already. Used to guarantee an action is only performed once by a
    /// single person
    mapping(uint256 => bool) internal nullifierHashes;

    mapping(address => uint256) public contextCounter;

    event IncrementContextCounter(address _msgSender);

    event CommentERC20(address indexed token, address indexed sender, string cid);
    event CommentERC721(address indexed token, address indexed sender, string cid);
    event CommentERC1155(address indexed token, uint256 indexed tokenId, address indexed sender, string cid);

    /// @param _worldId The WorldID instance that will verify the proofs
    /// @param _appId The World ID app ID
    /// @param _actionId The World ID action ID
    constructor(IWorldID _worldId, string memory _appId, string memory _actionId, address trustedForwarder)
        ERC2771Context(trustedForwarder)
    {
        worldId = _worldId;
        externalNullifier = abi.encodePacked(abi.encodePacked(_appId).hashToField(), _actionId).hashToField();
    }

    modifier onlyCallback() {
        require(msg.sender == iqsRouter);
        _;
    }

    function commentERC20(
        address token,
        string calldata cid,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] memory proof
    ) public {
        verifyAndExecute(_msgSender(), root, nullifierHash, proof);
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.balanceOf.selector, _msgSender()));
        _checkIsHolder(success, data);

        _setReview(token, _msgSender());

        _count(_msgSender());

        emit CommentERC20(token, _msgSender(), cid);
    }

    /*
    function commentERC721(
        address token,
        string calldata cid,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] memory proof
    ) public {
        verifyAndExecute(_msgSender(), root, nullifierHash, proof);

        (bool success721, bytes memory data721) =
            token.call(abi.encodeWithSelector(IERC165.supportsInterface.selector, _interfaceIdERC721));

        require(success721 && abi.decode(data721, (bool)), "Not ERC721");

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC721.balanceOf.selector, _msgSender()));
        _checkIsHolder(success, data);

        uint256 chainId;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }

        /// Mumbai chain should allow multiple reviews to demo easily
        if (chainId == 137) {
            _setReview(token, _msgSender());
        } else {
            accountReviewedToken[token][_msgSender()] = true;
        }

        _count(_msgSender());

        emit CommentERC721(token, _msgSender(), cid);
    }
    */

   function commentERC721(address tokenAddress, string calldata cid) public {
        uint32 destinationDomain = 5; // goerli
        uint256 gasAmount = 100000;
        IERC721 token = IERC721(tokenAddress);
        Call memory _balanceOfCall = Call({
            to: tokenAddress,
            data: abi.encodeWithSelector(IERC721.balanceOf.selector, _msgSender())
        });

        bytes memory _callback = abi.encodePacked(this._writeCommentERC721.selector);

        bytes32 messageId = IInterchainQueryRouter(iqsRouter).query(
            destinationDomain, // goerli
            _balanceOfCall,
            _callback
        );


        IInterchainGasPaymaster igp = IInterchainGasPaymaster(0x56f52c0A1ddcD557285f7CBc782D3d83096CE1Cc);
            uint256 quote = igp.quoteGasPayment(
            destinationDomain,
            gasAmount
        );

        igp.payForGas{ value: quote }(
            messageId, // The ID of the message that was just dispatched
            destinationDomain, // The destination domain of the message
            gasAmount,
            address(this) // refunds are returned to this contract
        );
   }


    function commentERC1155(
        address token,
        uint256 tokenId,
        string calldata cid,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] memory proof
    ) public {
        verifyAndExecute(_msgSender(), root, nullifierHash, proof);
        (bool success1155, bytes memory data1155) =
            token.call(abi.encodeWithSelector(IERC165.supportsInterface.selector, _interfaceIdERC1155));

        require(success1155 && abi.decode(data1155, (bool)), "Not ERC1155");

        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC1155.balanceOf.selector, _msgSender(), tokenId));
        _checkIsHolder(success, data);

        _setReview1155(token, tokenId, _msgSender());

        _count(_msgSender());

        emit CommentERC1155(token, tokenId, _msgSender(), cid);
    }

    /// @param signal An arbitrary input from the user, usually the user's wallet address (check README for further
    /// details)
    /// @param root The root of the Merkle tree (returned by the JS widget).
    /// @param nullifierHash The nullifier hash for this proof, preventing double signaling (returned by the JS widget).
    /// @param proof The zero-knowledge proof that demonstrates the claimer is registered with World ID (returned by
    /// the JS widget).
    /// @dev Feel free to rename this method however you want! We've used `claim`, `verify` or `execute` in the past.
    function verifyAndExecute(address signal, uint256 root, uint256 nullifierHash, uint256[8] memory proof) public {
        uint256 chainId;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }

        /// Only works in Polygon chain currently
        if (chainId == 137) {
            // First, we make sure this person hasn't done this before
            if (nullifierHashes[nullifierHash]) revert InvalidNullifier();

            // We now verify the provided proof is valid and the user is verified by World ID
            worldId.verifyProof(
                root, groupId, abi.encodePacked(signal).hashToField(), nullifierHash, externalNullifier, proof
            );

            // We now record the user has done this, so they can't do it again (proof of uniqueness)
            nullifierHashes[nullifierHash] = true;
        }
    }

    // `incrementContext` is the target function to call
    // This function increments a counter variable which is
    // mapped to every _msgSender(), the address of the user.
    // This way each user off-chain has their own counter
    // variable on-chain.
    function incrementContext() external {
        // Remember that with the context shift of relaying,
        // where we would use `_msgSender()` before,
        // this now refers to Gelato Relay's address,
        // and to find the address of the user,
        // which has been verified using a signature,
        // please use _msgSender()!

        // If this contract was not not called by the
        // trusted forwarder, _msgSender() will simply return
        // the value of _msgSender() instead.

        // Incrementing the counter mapped to the _msgSender!
        contextCounter[_msgSender()]++;

        // Emitting an event for testing purposes
        emit IncrementContextCounter(_msgSender());
    }

    function _count(address sender) private {
        counter[sender] = counter[sender] + 1;
    }

    function _setReview(address token, address sender) private {
        require(!accountReviewedToken[token][sender], "Already commented");
        accountReviewedToken[token][sender] = true;
    }

    function _setReview1155(address token, uint256 tokenId, address sender) private {
        require(!accountReviewedERC1155[token][tokenId][sender], "Already commented");
        accountReviewedERC1155[token][tokenId][sender] = true;
    }

    function _checkIsHolder(bool success, bytes memory data) private pure {
        require(success && (abi.decode(data, (uint256)) > 0), "Not a holder");
    }

    function _writeCommentERC721() onlyCallback() external {
        emit CommentERC721(0xb7F7F6C52F2e2fdb1963Eab30438024864c313F6, _msgSender(), '3');
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity =0.8.18;

struct Call {
    address to;
    bytes data;
}

/// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

library ByteHasher {
    /// @dev Creates a keccak256 hash of a bytestring.
    /// @param value The bytestring to hash
    /// @return The hash of the specified value
    /// @dev `>> 8` makes sure that the result is included in our field
    function hashToField(bytes memory value) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(value))) >> 8;
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity =0.8.18;

/**
 * @title IInterchainGasPaymaster
 * @notice Manages payments on a source chain to cover gas costs of relaying
 * messages to destination chains.
 */
interface IInterchainGasPaymaster {
    /**
     * @notice Emitted when a payment is made for a message's gas costs.
     * @param messageId The ID of the message to pay for.
     * @param gasAmount The amount of destination gas paid for.
     * @param payment The amount of native tokens paid.
     */
    event GasPayment(
        bytes32 indexed messageId,
        uint256 gasAmount,
        uint256 payment
    );

    /**
     * @notice Deposits msg.value as a payment for the relaying of a message
     * to its destination chain.
     * @dev Overpayment will result in a refund of native tokens to the _refundAddress.
     * Callers should be aware that this may present reentrancy issues.
     * @param _messageId The ID of the message to pay for.
     * @param _destinationDomain The domain of the message's destination chain.
     * @param _gasAmount The amount of destination gas to pay for.
     * @param _refundAddress The address to refund any overpayment to.
     */
    function payForGas(
        bytes32 _messageId,
        uint32 _destinationDomain,
        uint256 _gasAmount,
        address _refundAddress
    ) external payable;

    /**
     * @notice Quotes the amount of native tokens to pay for interchain gas.
     * @param _destinationDomain The domain of the message's destination chain.
     * @param _gasAmount The amount of destination gas to pay for.
     * @return The amount of native tokens required to pay for interchain gas.
     */
    function quoteGasPayment(uint32 _destinationDomain, uint256 _gasAmount)
        external
        view
        returns (uint256);
}

/// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;
import '../constants/Call.sol';

interface IInterchainQueryRouter {
    /**
     * @param _destinationDomain Domain of destination chain
     * @param target The address of the contract to query on destination chain.
     * @param queryData The calldata of the view call to make on the destination
     * chain.
     * @param callback Callback function selector on `msg.sender` and optionally
     * abi-encoded prefix arguments.
     * @return messageId The ID of the Hyperlane message encoding the query.
     */
    function query(
        uint32 _destinationDomain,
        address target,
        bytes calldata queryData,
        bytes calldata callback
    ) external returns (bytes32);

    /**
     * @param _destinationDomain Domain of destination chain
     * @param call The target address of the contract to query on destination
     * chain, and the calldata of the view call to make.
     * @param callback Callback function selector on `msg.sender` and optionally
     * abi-encoded prefix arguments.
     * @return messageId The ID of the Hyperlane message encoding the query.
     */
    function query(
        uint32 _destinationDomain,
        Call calldata call,
        bytes calldata callback
    ) external returns (bytes32);

    /**
     * @param _destinationDomain Domain of destination chain
     * @param calls Array of calls (to and data packed struct) to be made on
     * destination chain in sequence.
     * @param callbacks Array of callback function selectors on `msg.sender`
     * and optionally abi-encoded prefix arguments.
     */
    function query(
        uint32 _destinationDomain,
        Call[] calldata calls,
        bytes[] calldata callbacks
    ) external returns (bytes32);
}

/// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

interface IWorldID {
    /// @notice Reverts if the zero-knowledge proof is invalid.
    /// @param root The of the Merkle tree
    /// @param groupId The id of the Semaphore group
    /// @param signalHash A keccak256 hash of the Semaphore signal
    /// @param nullifierHash The nullifier hash
    /// @param externalNullifierHash A keccak256 hash of the external nullifier
    /// @param proof The zero-knowledge proof
    /// @dev  Note that a double-signaling check is not included here, and should be carried by the caller.
    function verifyProof(
        uint256 root,
        uint256 groupId,
        uint256 signalHash,
        uint256 nullifierHash,
        uint256 externalNullifierHash,
        uint256[8] calldata proof
    ) external view;
}