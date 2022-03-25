/**
 *Submitted for verification at polygonscan.com on 2022-03-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)
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
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
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
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)
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
// File: @openzeppelin/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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
// File: @openzeppelin/contracts/utils/Counters.sol
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)
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
// File: EZPony.sol
// EZPonyReceiver.sol


contract EZPonyReceiver is IERC721Receiver, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;
    struct EZPToken {
        uint256 id;
        address nftAddress;
        bool isSale;
        address owner;
        address winningBidder;
        uint256 nftId;
        uint priceInCent; // price in MATIC WEI
        bool active;
    }
    mapping (uint256 => EZPToken) public ezpTokens;
    address public wethAddress = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    mapping (address => bool) nftAddresses;
    
    function onERC721Received(
        address,
        address from,
        uint256 nftId,
        bytes memory
    ) public virtual override returns(bytes4) {
        if (nftAddresses[msg.sender]) {
            tokenIds.increment();
            uint256 _tokenId = tokenIds.current();
            ezpTokens[_tokenId] = EZPToken({
                id: _tokenId,
                nftAddress: msg.sender,
                isSale: false,
                owner: from,
                winningBidder: address(0),
                nftId: nftId,
                priceInCent: 0,
                active: true
            });
            return this.onERC721Received.selector;
        } else {
            revert();
        }
        
    }
    function getTokenCount() public view returns (uint256) {
        return tokenIds.current();
    }
    
    function getTokensbyOwner(address _owner) public view returns(EZPToken[] memory) {
        uint256 token_counts = tokenIds.current();
        EZPToken[] memory ret = new EZPToken[](token_counts);
        uint tmpCount = 0;
        for (uint256 i=0; i<=token_counts; i++) {
            if (ezpTokens[i].active && ezpTokens[i].owner == _owner) {
                ret[tmpCount] = ezpTokens[i];
                tmpCount++;
            }
        }
        return ret;
    }
    function getSaleTokens() public view returns(EZPToken[] memory) {
        uint256 token_counts = tokenIds.current();
        EZPToken[] memory ret = new EZPToken[](token_counts);
        uint tmpCount = 0;
        for (uint256 i=0; i<=token_counts; i++) {
            if (ezpTokens[i].isSale == true) {
                ret[tmpCount] = ezpTokens[i];
                tmpCount++;
            }
        }
        return ret;
    }
    function getToken(uint256 _tokenId) public view returns (EZPToken memory) {
        EZPToken memory ezpToken = ezpTokens[_tokenId];
        return ezpToken;
    }
    
    function withdrawToOwnerByAdmin(uint256 _tokenId) external onlyOwner {
        EZPToken memory ezpToken = ezpTokens[_tokenId];
        require(ezpToken.active, "Token is not exist.");
        require(!ezpToken.isSale, "Token is on sale now.");
        IERC721(ezpToken.nftAddress).safeTransferFrom(address(this), ezpToken.owner, ezpToken.nftId);
        delete ezpTokens[_tokenId];
    }
    function withdrawToOwner(uint256 _tokenId) external {
        EZPToken memory ezpToken = ezpTokens[_tokenId];
        require(ezpToken.active, "Token is not exist.");
        require(msg.sender == ezpToken.owner, "Wrong owner!");
        require(!ezpToken.isSale, "Token is on sale now.");
        IERC721(ezpToken.nftAddress).safeTransferFrom(address(this), ezpToken.owner, ezpToken.nftId);
        delete ezpTokens[_tokenId];
    }
    function transferToBuyer(uint256 _tokenId, address _buyer) external onlyOwner {
        require(ezpTokens[_tokenId].isSale, "Token is not on sale now.");
        require(_buyer != address(0));
        EZPToken memory ezpToken = ezpTokens[_tokenId];
        
        IERC721(ezpToken.nftAddress).safeTransferFrom(address(this), _buyer, ezpToken.nftId);
        delete ezpTokens[_tokenId];
    }
    function addNFTAddress(address _address) external onlyOwner {
        nftAddresses[_address] = true;
    }
    function removeNFTAddress(address _address) external onlyOwner {
        nftAddresses[_address] = false;
    }
    
    function buy(uint256 _tokenId) external {
        require(msg.sender != address(0), "Invalid buyer address");
        require(ezpTokens[_tokenId].isSale, "Token is not on sale now.");
        require(ezpTokens[_tokenId].owner != address(0), "Wrong owner");
        uint256 _amount = ezpTokens[_tokenId].priceInCent;
        require(IERC20(wethAddress).balanceOf(msg.sender) > _amount, "WETH balance is insufficient");
        IERC20(wethAddress).transferFrom(msg.sender, ezpTokens[_tokenId].owner, _amount);
        IERC721(ezpTokens[_tokenId].nftAddress).safeTransferFrom(address(this), msg.sender, ezpTokens[_tokenId].nftId);
        delete ezpTokens[_tokenId];
    }
    function setPriceInCent(uint256 _tokenId, uint256 _price) external {
        require(msg.sender == ezpTokens[_tokenId].owner, "Wrong owner!");
        EZPToken storage ezpToken = ezpTokens[_tokenId];
        ezpToken.priceInCent = _price;
    }
    function setIsSale(uint256 _tokenId, bool _isSale) external {
        require(msg.sender == ezpTokens[_tokenId].owner, "Wrong owner!");
        EZPToken storage ezpToken = ezpTokens[_tokenId];
        ezpToken.isSale = _isSale;
    }
    function setPriceInCentAndListForSale(uint256 _tokenId, uint256 _price) external {
        require(msg.sender == ezpTokens[_tokenId].owner, "Wrong owner!");
        EZPToken storage ezpToken = ezpTokens[_tokenId];
        ezpToken.priceInCent = _price;
        ezpToken.isSale = true;
    }
}