// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/utils/ERC721Holder.sol)

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
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
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

// SPDX-License-Identifier: NONE
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INFTBundle {
    function getBundleCurrencyAddress() external returns (IERC20);

    function canBidBundle() external returns (bool status);

    function updateBundleAsset(
        uint256 bookAmount,
        uint256 _nftId,
        IERC721 _nftAddress
    ) external returns (uint256 nftsNewId);

    function mintBundleShare(uint256 amount) external;

    function isVeto(address _address) external view returns (bool);

    function bundleIsPublic() external returns (bool status);

    function getBundleNFT(uint256 _nftId) external returns (IERC721 nftAddress, uint256 bookPrice, uint256 nftId);

    function sbtPrice() external view returns (uint256 price);

    function initialMintedAmount() external view returns (uint256 price);

    function setPrice(uint256 price) external returns (bool status);

    function transferBundleShare(address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IEscrow.sol";
import "./structures/EscrowStructures.sol";

contract Escrow is Ownable, ERC721Holder, IEscrow {
    mapping(uint256 => Receiver) private auctionsReceivers;
    mapping(uint256 => Bidder) private bids;
    mapping(uint256 => Withdrawal) private withdrawalDeposits;
    address private auctionAddress;

    modifier onlyAuction() {
        require(msg.sender == auctionAddress, "Escrow: only auction");
        _;
    }

    /**
     * Send Nft to this Contract
     * Then call the depositNft function identifing the Auction storing the
     */
    function depositNft(
        uint256 auctionId,
        address auctionBundleAddress,
        uint256 _quantity
    ) public onlyAuction returns (uint256 auctionUuid) {
        auctionsReceivers[auctionId] = Receiver({
            auction: auctionId,
            receiver: auctionBundleAddress,
            quantity: _quantity
        });
        return (auctionId);
    }

    function depositERC20(
        uint256 _auctionId,
        address _bidderAddress,
        uint256 _bidderId,
        uint256 amount
    ) public onlyAuction returns (uint256 bidUuid) {
        bids[_bidderId] = Bidder({
            auctionId: _auctionId,
            bidderAddress: _bidderAddress,
            bidId: _bidderId,
            amountSent: amount
        });
        return (_bidderId);
    }

    function depositERC20ForWithrawal(uint256 auctionId, address sender, uint256 amount) public onlyAuction {
        withdrawalDeposits[auctionId] = Withdrawal({ auctionId: auctionId, bidderAddress: sender, amountSent: amount });
    }

    function transferNFt(
        address to,
        IERC721 nftAsset,
        uint256 nftId,
        uint256 _auctionId,
        uint256 quantity
    ) public onlyAuction {
        require(auctionsReceivers[_auctionId].auction == _auctionId, "Escrow: auction does not exists");
        // require(auctionsReceivers[_auctionId].receiver == to, "invalid receiver");
        require(auctionsReceivers[_auctionId].quantity == quantity, "Escrow: quantity value is not correct");
        nftAsset.safeTransferFrom(address(this), to, nftId);
    }

    // Must make sure only the Auction Contract can call this smart contract

    function transferCurrency(
        address to,
        IERC20 bidCurrency,
        uint256 _auctionId,
        uint256 amountSent,
        uint256 _bidId,
        uint256 _fee
    ) public onlyAuction {
        require(bids[_bidId].auctionId == _auctionId, "Escrow:  auction does not exists");
        require(bids[_bidId].bidId == _bidId, "Escrow: bid does not exists");
        // require(bids[_bidId].bidderAddress == to, "only the bidder can withdraw");
        // So the Amount changes when you
        require((bids[_bidId].amountSent - _fee) == amountSent, "Escrow: amount value is not correct");
        bidCurrency.transfer(address(to), amountSent);
    }

    function setAuctionAddress(address _auctionAddress) public onlyOwner returns (bool trnxState) {
        auctionAddress = _auctionAddress;
        return true;
    }

    function transferWithdrawDeposit(uint256 auctionId, address receiver, IERC20 bidCurrency) public onlyAuction {
        Withdrawal memory element = withdrawalDeposits[auctionId];
        require(element.auctionId == auctionId, "Escrow: auction does not exists");
        require(element.bidderAddress == receiver, "Escrow: receiver is not the bidder");
        bidCurrency.transfer(receiver, element.amountSent);
    }

    function transferFee(
        address feeAddress,
        IERC20 bidCurrency,
        uint256 amountSent
    ) public onlyAuction returns (bool trnxStatus) {
        bidCurrency.transfer(feeAddress, amountSent);
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../Bundle/interfaces/INFTBundle.sol";

interface IEscrow {
    function depositNft(
        uint256 auctionId,
        address auctionBundleAddress,
        uint256 _quantity
    ) external returns (uint256 auctionUuid);

    function depositERC20(
        uint256 _auctionId,
        address _bidderAddress,
        uint256 _bidderId,
        uint256 amount
    ) external returns (uint256 bidUuid);

    function depositERC20ForWithrawal(uint256 auctionId, address sender, uint256 amount) external;

    function transferNFt(address to, IERC721 nftAsset, uint256 nftId, uint256 _auctionId, uint256 quantity) external;

    function transferCurrency(
        address to,
        IERC20 bidCurrency,
        uint256 _auctionId,
        uint256 amountSent,
        uint256 _bidId,
        uint256 _fee
    ) external;

    function transferWithdrawDeposit(uint256 auctionId, address receiver, IERC20 bidCurrency) external;

    function transferFee(address feeAddress, IERC20 bidCurrency, uint256 amountSent) external returns (bool trnxStatus);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

struct Receiver {
    uint256 auction;
    address receiver;
    uint256 quantity;
}

struct Bidder {
    uint256 auctionId;
    address bidderAddress;
    uint256 bidId;
    uint256 amountSent;
}

struct Withdrawal {
    uint256 auctionId;
    address bidderAddress;
    uint256 amountSent;
}