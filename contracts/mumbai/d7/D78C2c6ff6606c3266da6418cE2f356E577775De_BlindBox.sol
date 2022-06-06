// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


interface IWhitelist {
    function isInWhitelist(address addr) external returns(bool);
    function whitelistDrawn(address addr) external;
}

contract BlindBox is ERC721Holder, Ownable, Pausable {
    
    IERC721 private nftContract;
    IWhitelist private whitelistContract;

    address private _cashierAddress;

    uint256 private _whitelistStart;
    uint256 private _whitelistEnd;

    uint256 private _maxBlindBox;

    uint256[] private _tokenIdsToDraw;
    uint256 private _blindboxPrice;

    event BlindBoxDraw(address participant, uint256 drawnTokenId);
    event CashierAddressUpdate(address cashierAddress);
    event WhitelistPeriodUpdate(uint256 startTimestamp, uint256 endTimestamp);
    event MaxBlindBoxUpdate(uint256 maxBlindBox);
    event BlindBoxPriceUpdate(uint256 newPrice);

    modifier canDraw(uint8 drawAmount) {
        require(_blindboxPrice * drawAmount <= msg.value, "Not enough fund to purchase");
        require(_tokenIdsToDraw.length > 0, "No blindbox to draw");
        require(drawAmount <= _tokenIdsToDraw.length, "Not enough blindbox to draw");
        _;
    }

    modifier whitelistNotStart() {
        require(block.timestamp < _whitelistStart, "Whitelist sale has started");
        _;
    }

    modifier whitelistIsLive() {
        require(block.timestamp >= _whitelistStart, "Whitelist sale not started");
        require(block.timestamp <= _whitelistEnd, "Whitelist sale finished");
        _;
    }

    modifier onlyWhitelisted() {
        require(whitelistContract.isInWhitelist(msg.sender), "Not whitelisted");
        _;
    }

    modifier publicSaleIsLive() {
        require(block.timestamp > _whitelistEnd, "Public sale not started");
        _;
    }

    constructor (
        address nftContractAddress_,
        address whitelistContractAddress_,
        address cashierAddress_,
        uint256 whitelistStart_,
        uint256 whitelistEnd_,
        uint256 maxBlindBox_,
        uint256 blindboxPrice_
    ) {
        require(nftContractAddress_ != address(0), "Zero NFT contract address");
        require(whitelistContractAddress_ != address(0), "Zero whitelist contract address");
        require(cashierAddress_ != address(0), "Zero cashier address");
        require(whitelistStart_ < whitelistEnd_, "Invalid period");
        require(maxBlindBox_ > 0, "Zero max blindbox");
        require(blindboxPrice_ > 0, "Zero blindbox price");
        nftContract = IERC721(nftContractAddress_);
        whitelistContract = IWhitelist(whitelistContractAddress_);
        _cashierAddress = cashierAddress_;
        _whitelistStart = whitelistStart_;
        _whitelistEnd = whitelistEnd_;
        _maxBlindBox = maxBlindBox_;
        _blindboxPrice = blindboxPrice_;
    }

    // --------------------  View Functions  ---------------------
    function getBlindboxPrice() public view returns (uint256) {
        return _blindboxPrice;
    }
    
    function getBlindboxRemaining() public view returns (uint256) {
        return _tokenIdsToDraw.length;
    }

    function getBlindboxDrawn() public view returns (uint256) {
        return _maxBlindBox - _tokenIdsToDraw.length;
    }

    function isWhitelistSale() external view returns (bool) {
        return block.timestamp >= _whitelistStart && block.timestamp <= _whitelistEnd;
    }

    function getWhitelistSalePeriod() external view returns (uint256, uint256) {
        return (_whitelistStart, _whitelistEnd);
    }

    function isPublicSale() external view returns (bool) {
        return block.timestamp > _whitelistEnd;
    }

    // -------------------- Admin View Functions  ------------------

    function getNftContractAddress() external view onlyOwner returns (address) {
        return address(nftContract);
    }

    function getWhitelistContractAddress() external view onlyOwner returns (address) {
        return address(whitelistContract);
    }

    function getCashierAddress() external view onlyOwner returns (address) {
        return _cashierAddress;
    }

    function getTokenIds() external view onlyOwner returns (uint256[] memory) {
        return _tokenIdsToDraw;
    }

    // --------------------  Public Functions  ---------------------

    function whitelistDraw() external payable whenNotPaused whitelistIsLive onlyWhitelisted canDraw(1) {
        _draw(1);
        whitelistContract.whitelistDrawn(msg.sender);
    }

    function publicDraw(uint8 drawAmount) external payable whenNotPaused publicSaleIsLive canDraw(drawAmount) {
        _draw(drawAmount);
    }

    // --------------------  Internal Functions  -----------------

    function _draw(uint8 numberOfTokens) private {
        for (uint256 i = 0; i < numberOfTokens; i ++) {
            uint256 arrayIndex = uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        block.coinbase,
                        block.difficulty,
                        block.gaslimit,
                        block.timestamp
                    )
                )
            ) % _tokenIdsToDraw.length;

            uint256 tokenId = _tokenIdsToDraw[arrayIndex];

            // Transfer NFTs to msg sender
            nftContract.safeTransferFrom(address(this), msg.sender, tokenId);

            // Pop tokenId from array after transfer
            _popTokenId(arrayIndex);
            
            // Cashout
            _withdraw();
            emit BlindBoxDraw(msg.sender, tokenId);
        }
    }

    function _withdraw() private {
        uint balance = address(this).balance;
        payable(_cashierAddress).transfer(balance);
    }

    function _popTokenId(uint256 index) private {
        _tokenIdsToDraw[index] = _tokenIdsToDraw[_tokenIdsToDraw.length - 1];
        _tokenIdsToDraw.pop();
    }

    // --------------------  Overridden Functions  ---------------

    function onERC721Received(address, address, uint256 tokenId, bytes memory) public override virtual returns (bytes4) {
        require(msg.sender == address(nftContract), "Unauthorized access");
        _tokenIdsToDraw.push(tokenId);
        return this.onERC721Received.selector;
    }

    // --------------------  Admin Functions  --------------------

    function setCashierAddress(address cashierAddress) external onlyOwner {
        require(cashierAddress != address(0), "Zero address");
        _cashierAddress = cashierAddress;
        emit CashierAddressUpdate(cashierAddress);
    }

    function setWhitelistPeriod(uint256 startTimestamp, uint256 endTimestamp) external onlyOwner whitelistNotStart {
        require(startTimestamp < endTimestamp, "Invalid period");
        _whitelistStart = startTimestamp;
        _whitelistEnd = endTimestamp;
        emit WhitelistPeriodUpdate(startTimestamp, endTimestamp);
    }

    function setMaxBlindBox(uint256 maxBlindBox) external onlyOwner {
        require(maxBlindBox >= _tokenIdsToDraw.length, "Invalid max blindbox");
        _maxBlindBox = maxBlindBox;
        emit MaxBlindBoxUpdate(maxBlindBox);
    }

    function setBlindboxPrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Invalid blindbox price");
		_blindboxPrice = newPrice;
        emit BlindBoxPriceUpdate(newPrice);
	}

    function recoverNFT(address toAddress, uint256 tokenId) external onlyOwner whenPaused {
        nftContract.safeTransferFrom(address(this), toAddress, tokenId);

        for (uint256 i = 0; i <= _tokenIdsToDraw.length; i++) {
            if(_tokenIdsToDraw[i] == tokenId) {
                _popTokenId(i);
                break;
            }
        }

    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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