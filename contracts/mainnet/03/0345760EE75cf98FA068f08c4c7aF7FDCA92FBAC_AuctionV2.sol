/**
 *Submitted for verification at polygonscan.com on 2022-02-22
*/

/*
* ███╗░░░███╗███████╗████████╗░█████╗░        ███╗░░██╗░█████╗░███╗░░██╗░█████╗░░██████╗
* ████╗░████║██╔════╝╚══██╔══╝██╔══██╗        ████╗░██║██╔══██╗████╗░██║██╔══██╗██╔════╝
* ██╔████╔██║█████╗░░░░░██║░░░███████║        ██╔██╗██║███████║██╔██╗██║██║░░██║╚█████╗░
* ██║╚██╔╝██║██╔══╝░░░░░██║░░░██╔══██║        ██║╚████║██╔══██║██║╚████║██║░░██║░╚═══██╗
* ██║░╚═╝░██║███████╗░░░██║░░░██║░░██║        ██║░╚███║██║░░██║██║░╚███║╚█████╔╝██████╔╝
* ╚═╝░░░░░╚═╝╚══════╝░░░╚═╝░░░╚═╝░░╚═╝        ╚═╝░░╚══╝╚═╝░░╚═╝╚═╝░░╚══╝░╚════╝░╚═════╝░
*
*
* META NANOs
* The next level 3D play-to-earn metaverse
*
* Our vision is to create a next level, high quality 3D play-to-earn metaverse where users can buy, train and trade
* their NANOs and let them compete against each other in a universe of different games. Each game can interpret the
* NANOs and its power gems in its own specific way and thus differently. Games can require additional equipment which
* NANOs need to use in order to join the game. Each NANO has its own stats and a power gem that can be used to win within
* the game.
*
* META NANOs is an official HERO ecosystem project (www.herocoin.io)
*
* Official Links:
* https://www.metananos.com
* https://twitter.com/metananos
* https://instagram.com/metananos
*
* */


// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT
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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

// 
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

// 
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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

// 
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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol

// 
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

// 
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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

// 
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

// File: contracts/MetaNanoDataI.sol

/*
 * Interface for data storage of the metananos system.
 *
 *
 */
pragma solidity ^0.8.0;

interface MetaNanoDataI {

    event AddressChanged(string name, address previousAddress, address newAddress);

    /**
     * @dev Set an address for a name.
     */
    function setAddress(string memory name, address newAddress) external;

    /**
     * @dev Get an address for a name.
     */
    function getAddress(string memory name) external view returns (address);
}

// File: contracts/AuctionV2DeployI.sol

/*
 * AlphaPass Auction V2 deployment interface
 *
 *
 */
pragma solidity ^0.8.0;

interface AuctionV2DeployI {

    function initialRegister(address previousAuction) external;

}

// File: contracts/PassType.sol

/*
 *
 */
pragma solidity ^0.8.0;

uint constant MAX_PASS_TYPE_COUNT = 3;

enum PassType {
    Silver,
    Gold,
    Crystal
}

// File: contracts/DropV2I.sol

/*
 * Interface for metananos drop.
 *
 *
 */
pragma solidity ^0.8.0;


interface DropV2I {

    /**
     * @dev Emitted when a new auction is created.
     */

    event NewAuction(address auctionAddress, address dropAddress, uint256 auctionIndex);

    event MinBidSet(uint256 bidWei, address paymenToken);
    event NewBid(address indexed bidder, uint256 bidWei, address paymentToken, address auction);
    event BidChanged(address indexed bidder, uint256 newBidWei, address paymentToken, address auction);
    event AssetSold(address indexed buyer, uint256 indexed tokenId);
    event DistributionFailed(address indexed buyer, uint256 indexed tokenId, string reason);
    event AuctionDistributionFinished(address indexed nextAuction);
    event DropDistributionFinished();
    event NoMoreUsersToDistribute(uint256 indexed tokenId);
    event PaymentForwarded(address indexed recipient, uint256 paymentAmount, address paymentToken);
    event PaymentRefunded(address indexed recipient, uint256 refundAmount, address paymentToken);

    function floorPrice(PassType pass) external view returns (uint256);

    function bidForUser(address user, address paymentToken, uint256 bidAmount, address candidateHigherBidder) external;

    function adjustBidForUser(address _paymentToken, address _bidder, uint256 _newBidWei, address _candidateHigherBidder, address _previousNextHigherBidder) external;

    function metaNanoData() external view returns (MetaNanoDataI);

    function bidWei(address) external view returns (uint256);

}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol

// 
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: contracts/ERC721SignedTransferI.sol

/*
 * Interface for ERC721 Signed Transfers.
 *
 *
 */
pragma solidity ^0.8.0;

/**
 * @dev Outward-facing interface of a Collections contract.
 */
interface ERC721SignedTransferI is IERC721 {

    /**
     * @dev Emitted when a signed transfer is being executed.
     */
    event SignedTransfer(address operator, address indexed from, address indexed to, uint256 indexed tokenId, uint256 signedTransferNonce);

    /**
     * @dev The signed transfer nonce for an account.
     */
    function signedTransferNonce(address account) external view returns (uint256);

    /**
     * @dev Outward-facing function for signed transfer: assembles the expected data and then calls the internal function to do the rest.
     * Can called by anyone knowing about the right signature, but can only transfer to the given specific target.
     */
    function signedTransfer(uint256 tokenId, address to, bytes memory signature) external;

    /**
     * @dev Outward-facing function for operator-driven signed transfer: assembles the expected data and then calls the internal function to do the rest.
     * Can transfer to any target, but only be called by the trusted operator contained in the signature.
     */
    function signedTransferWithOperator(uint256 tokenId, address to, bytes memory signature) external;

}

// File: contracts/ERC721ExistsI.sol

/*
 * Interface for an ERC721 compliant contract with an exists() function.
 *
 *
 */
pragma solidity ^0.8.0;

/**
 * @dev ERC721 compliant contract with an exists() function.
 */
interface ERC721ExistsI is IERC721 {

    // Returns whether the specified token exists
    function exists(uint256 tokenId) external view returns (bool);

}

// File: contracts/AlphaPassTokenI.sol

/*
 * Interface for functions of the AlphaPassToken token that need to be accessed by
 * other contracts.
 *
 *
 */
pragma solidity ^0.8.0;




interface AlphaPassTokenI is IERC721Enumerable, ERC721ExistsI, ERC721SignedTransferI {

    /**
     * @dev The base URI of the token.
     */
    function baseURI() external view returns (string memory);

    /**
     * @dev The passType ID for a specific asset / token ID.
     */
    function passType(uint256 tokenId) external view returns (PassType);

    function createMulti(uint _amount, address _owner, PassType _passType) external;

    function moveMulti(uint256 fromTokenInclusive, uint256 toTokenInclusive, address _destination) external;


}

// File: contracts/ContextMixin.sol

//

pragma solidity ^0.8.0;

abstract contract ContextMixin {
    function msgSender()
    internal
    view
    returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
            // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                mload(add(array, index)),
                0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// File: contracts/EIP721Base.sol

//
pragma solidity ^0.8.0;

abstract contract EIP712Base {

    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(bytes("EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"));

    bytes32 internal domainSeparator;

    constructor(string memory name, string memory version) {
        domainSeparator = keccak256(abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                address(this),
                bytes32(getChainID())
            ));
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function getDomainSeparator() private view returns (bytes32) {
        return domainSeparator;
    }

    /**
    * Accept message hash and returns hash message in EIP712 compatible form
    * So that it can be used to recover signer from signature signed using EIP712 formatted data
    * https://eips.ethereum.org/EIPS/eip-712
    * "\\x19" makes the encoding deterministic
    * "\\x01" is the version byte to make it compatible to EIP-191
    */
    function toTypedMessageHash(bytes32 messageHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeparator(), messageHash));
    }

}

// File: contracts/NativeMetaTransaction.sol

//
pragma solidity ^0.8.0;

abstract contract NativeMetaTransaction is EIP712Base {
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );

    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );

    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
        nonce : nonces[userAddress],
        from : userAddress,
        functionSignature : functionSignature
        });
        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress] + 1;

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
    internal
    pure
    returns (bytes32)
    {
        return
        keccak256(
            abi.encode(
                META_TRANSACTION_TYPEHASH,
                metaTx.nonce,
                metaTx.from,
                keccak256(metaTx.functionSignature)
            )
        );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
        signer ==
        ecrecover(
            toTypedMessageHash(hashMetaTransaction(metaTx)),
            sigV,
            sigR,
            sigS
        );
    }
}

// File: contracts/AuctionV2I.sol

/*
 * Interface for metananos drop.
 *
 *
 */
pragma solidity ^0.8.0;



interface AuctionV2I {

    /**
     * @dev Emitted when a new auction is created.
     */
    event AuctionStartSet(uint256 startTimestamp, uint256 endTimestamp);
    event AuctionEndSet(uint256 endTimestamp);

    function ownedPassCount(PassType p) external view returns (uint256);

    function assetToken() external view returns (AlphaPassTokenI);

    function distributionDone() external view returns (bool);

    function tokenCountIncluding(PassType pass) external view returns (uint256);

    function startAuction(uint256 startTimestamp, uint256 endTimestamp) external;

    function setAuctionEnd(uint256 endTimestamp) external;

    function bid(address paymentToken, uint256 weiBid, address candidateHigherBidder) external;

    function adjustBid(address paymentToken, uint256 weiBid, address candidateHigherBidder, address previousNextHigherBidder) external;


}

// File: contracts/AuctionV2.sol

/*
 * metananos Auction V2 contract
 *
 * Preparation steps:
 *   1. Create new auction via the factory.
 *   2. Transfer NFTs to auction
 *   3. start auction (no NFTs accepted after this!)
 *
 *
 */
pragma solidity ^0.8.0;














contract AuctionV2 is ERC165, AuctionV2DeployI, ReentrancyGuard, ContextMixin, NativeMetaTransaction, AuctionV2I {
    using Address for address payable;
    using Address for address;

    bool public isPrototype;

    MetaNanoDataI public metaNanoData;
    DropV2I public parentDrop;

    uint256[] public silverTokenIds;
    uint256[] public goldTokenIds;
    uint256[] public crystalTokenIds;

    uint256 public startTimestamp;
    uint256 public endTimestamp;

    address public predecessor;

    modifier requireIsInstance {
        require(!isPrototype, "Needs an active contract, not the prototype.");
        _;
    }

    modifier onlyTokenAssignmentControl() {
        //it is not intended to do system setup tasks gasless, therefore no _msgSender() here
        require(msg.sender == metaNanoData.getAddress("tokenAssignmentControl"), "tokenAssignmentControl key required for this function.");
        _;
    }

    modifier onlyAdmin() {
        //it is not intended to do system setup tasks gasless, therefore no _msgSender() here
        require(msg.sender == metaNanoData.getAddress("auctionCreateControl"), "Admin key required for this function.");
        _;
    }

    modifier requireStarted() {
        if (predecessor != address(0)) {
            require(AuctionV2(predecessor).distributionDone(), "the previous auction has not been distributed yet");
        }
        require(startTimestamp > 0 && startTimestamp <= block.timestamp, "Auction has to be started.");
        _;
    }

    modifier requireNotFinished() {
        require(endTimestamp > block.timestamp, "Auction is already finished - this operation is no longer possible");
        _;
    }

    modifier requireFinished() {
        require(endTimestamp > 0 && endTimestamp <= block.timestamp, "Auction has to be finished.");
        _;
    }

    constructor(address _metaNanoDataAddress)
    EIP712Base("Meta Nanos Alpha Pass Auction", "1.0")
    {
        metaNanoData = MetaNanoDataI(_metaNanoDataAddress);
        require(address(metaNanoData) != address(0x0), "You need to provide an actual metaNano data contract.");
        // The initially deployed contract is just a prototype and code holder.
        // Clones will proxy their commends to this one and actually work.
        isPrototype = true;
    }

    function initialRegister(address _predecessor)
    external
    requireIsInstance
    {
        // Make sure that this function has not been called on this contract yet.
        require(address(metaNanoData) == address(0), "Cannot be initialized twice.");
        predecessor = _predecessor;
        metaNanoData = DropV2I(msg.sender).metaNanoData();
        //it is not intended to do system setup tasks gasless, therefore no _msgSender() here
        parentDrop = DropV2I(msg.sender);
        //it is not intended to do system setup tasks gasless, therefore no _msgSender() here
    }

    function ownedPassCount(PassType _p) public view returns (uint256){
        if (_p == PassType.Silver) return silverTokenIds.length;
        if (_p == PassType.Gold) return goldTokenIds.length;
        if (_p == PassType.Crystal) return crystalTokenIds.length;
        revert("unknown pass type");
    }

    /*** ERC165 ***/

    function supportsInterface(bytes4 interfaceId)
    public view override
    returns (bool)
    {
        return interfaceId == type(IERC721Receiver).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /*** Get contracts with their ABI ***/


    function assetToken()
    public view
    returns (AlphaPassTokenI)
    {
        return AlphaPassTokenI(metaNanoData.getAddress("AlphaPassToken"));
    }

    /*** Deal with ERC721 tokens we receive ***/

    // Override ERC721Receiver to record receiving of ERC721 tokens.
    // Also, comment out all params that are in the interface but not actually used, to quiet compiler warnings.
    function onERC721Received(address /*_operator*/, address /*_from*/, uint256 _tokenId, bytes memory /*_data*/)
    public
    requireIsInstance
    returns (bytes4)
    {
        //it is not intended to do system setup tasks gasless, therefore no _msgSender() here
        address _tokenAddress = msg.sender;
        // Make sure whoever called this plays nice, check for token being from the contract we need.
        require(_tokenAddress == address(assetToken()), "We only accept tokens from the configured asset");
        require(startTimestamp == 0 || startTimestamp > block.timestamp, "Auction cannot have started yet.");
        PassType p = AlphaPassTokenI(_tokenAddress).passType(_tokenId);
        if (p == PassType.Silver) {
            silverTokenIds.push(_tokenId);
        } else if (p == PassType.Gold) {
            goldTokenIds.push(_tokenId);
        } else if (p == PassType.Crystal) {
            crystalTokenIds.push(_tokenId);
        } else revert("unknown pass type");
        return IERC721Receiver.onERC721Received.selector;
    }

    /*** Auction-realted properties / view functions ***/

    // Returns true if all semi-automatic distribution is finished.
    function distributionDone()
    public view
    requireIsInstance
    returns (bool)
    {
        return endTimestamp != 0 && endTimestamp <= block.timestamp && assetToken().balanceOf(address(this)) == 0;
    }

    /*** Actual auction functionality ***/

    // Start the auction. At this point, NFTs already need to be owned by this auction.
    function startAuction(uint256 _startTimestamp, uint256 _endTimestamp)
    external
    requireIsInstance
    onlyAdmin
    {
        require(assetToken().balanceOf(address(this)) > 0, "The auction needs to own tokens to be started.");
        if (_startTimestamp <= block.timestamp) {
            startTimestamp = block.timestamp;
            //this starts right away
        } else {
            startTimestamp = _startTimestamp;
        }
        require(_endTimestamp > startTimestamp, "End needs to be after the start.");
        endTimestamp = _endTimestamp;
        emit AuctionStartSet(startTimestamp, endTimestamp);
    }

    function isActive()
    public
    view
    returns (bool)
    {
        return startTimestamp > 0 && block.timestamp >= startTimestamp && block.timestamp < endTimestamp;
    }

    // Adjust the end of the auction, potentially while it's already running.
    function setAuctionEnd(uint256 _endTimestamp)
    external
    requireIsInstance
    onlyAdmin
    {
        require(_endTimestamp > block.timestamp, "End needs to be in the future.");
        require(_endTimestamp > startTimestamp, "End needs to be after the start.");
        endTimestamp = _endTimestamp;
        emit AuctionEndSet(endTimestamp);
    }

    // Bid on an amount to be handed over to the drop. `candidateHigherBidder` ideally is just the exactly next higher bidder.
    function bid(address _paymentToken, uint256 _weiBid, address _candidateHigherBidder)
    external
    requireIsInstance
    requireStarted
    requireNotFinished
    {
        //we explicitly support gasless tx for bid and adjustBid, therefore we use _msgSender() here
        parentDrop.bidForUser(_msgSender(), _paymentToken, _weiBid, _candidateHigherBidder);
    }

    // Adjust your bid to higher price and/or amount of NFTs. `_candidateHigherBidder` ideally is just the exactly next higher bidder.
    // `_previousNextHigherBidder` needs to be the one exactly above this current bid previously, use the zero address if it's the highest bidder.
    function adjustBid(address _paymentToken, uint256 _weiBid, address _candidateHigherBidder, address _previousNextHigherBidder)
    external
    requireIsInstance
    requireStarted
    requireNotFinished
    {
        //we explicitly support gasless tx for bid and adjustBid, therefore we use _msgSender() here
        parentDrop.adjustBidForUser(_msgSender(), _paymentToken, _weiBid, _candidateHigherBidder, _previousNextHigherBidder);

    }

    function tokenCountIncluding(PassType _pass) public view returns (uint256) {
        if (_pass == PassType.Crystal) return crystalTokenIds.length;
        if (_pass == PassType.Gold) return crystalTokenIds.length + goldTokenIds.length;
        if (_pass == PassType.Silver) return crystalTokenIds.length + goldTokenIds.length + silverTokenIds.length;
        revert();
    }

    function getBestTokenId()
    public view
    returns (uint256){
        if (crystalTokenIds.length > 0) {
            return crystalTokenIds[crystalTokenIds.length - 1];
        } else if (goldTokenIds.length > 0) {
            return goldTokenIds[goldTokenIds.length - 1];
        } else if (silverTokenIds.length > 0) {
            return silverTokenIds[silverTokenIds.length - 1];
        } else {
            revert("unable to distribute token, no tokens left");
        }
    }

    function sendBestTokenTo(address destination)
    public
    {
        //it is not intended to do token distribution gasless, therefore no _msgSender() here
        require(msg.sender == address(parentDrop), "not called by parent drop");
        uint256 tokenId;
        if (crystalTokenIds.length > 0) {
            tokenId = crystalTokenIds[crystalTokenIds.length - 1];
            crystalTokenIds.pop();
        } else if (goldTokenIds.length > 0) {
            tokenId = goldTokenIds[goldTokenIds.length - 1];
            goldTokenIds.pop();
        } else if (silverTokenIds.length > 0) {
            tokenId = silverTokenIds[silverTokenIds.length - 1];
            silverTokenIds.pop();
        } else {
            revert("unable to distribute token, no tokens left");
        }
        require(assetToken().ownerOf(tokenId) == address(this), "unable to send, we are not the owner");
        assetToken().safeTransferFrom(address(this), destination, tokenId);

    }

    /*** Make sure currency or NFT doesn't get stranded in this contract ***/

    // If this contract gets a balance in some ERC20 contract after it's finished, then we can rescue it.
    function rescueToken(IERC20 _foreignToken, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignToken.transfer(_to, _foreignToken.balanceOf(address(this)));
    }

    // If this contract gets a balance in some ERC721 contract after it's finished, then we can rescue it.
    function approveNFTrescue(IERC721 _foreignNFT, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignNFT.setApprovalForAll(_to, true);
    }


    // This is to support Native meta transactions
    // "never" use msg.sender directly, use _msgSender() instead
    //use msg.sender where no support for gasless tx is required
    function _msgSender()
    internal
    view
    returns (address payable sender)
    {
        return ContextMixin.msgSender();
    }
}