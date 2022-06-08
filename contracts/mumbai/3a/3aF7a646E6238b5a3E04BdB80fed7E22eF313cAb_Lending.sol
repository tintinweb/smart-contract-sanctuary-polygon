/**
 *Submitted for verification at polygonscan.com on 2022-06-07
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


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

// File: contracts/LendingV3.sol



pragma solidity ^0.8.0;




contract Lending is Ownable {

    struct Erc20Token {
        bool isAllowed;
        uint32 feePercentage; // 100 == 1%
    }

    struct Offer {
        address from; // lender
        address to; // if this address is set, only this address can borrow NFT
        address erc20Token; // offer can be in a supported erc20Token or in ETH. address(0) = ETH
        uint256 price; // price per day
        uint256 minDuration; // minimum amount od DAYS that nft can be borrowed for
        uint256 expiration; // timestamp when offer expires - NFT cannot be borrowed after this
    }

    struct Lent {
        address from; // lender
        address to; // borrower
        uint256 until; // timestamp when lending ends
    }

    mapping(address => mapping(uint256 => Offer)) offers; // nftContractAddress => tokenId => Offer
    mapping(address => mapping(uint256 => Lent)) lent;  // nftContractAddress => tokenId => Lent
    mapping(address => Erc20Token) public erc20Tokens; // erc20Token => Erc20Token
    mapping(address => mapping(uint256 => address)) public owners; // nftContractAddress => tokenId => Owner . Store the owner of nft when nft is transferred to contract

    event offerCreated(
        address nftContractAddress,
        uint256 tokenId,
        address from,
        address to,
        address erc20Token,
        uint256 price,
        uint256 minDuration,
        uint256 expiration
    );

    event offerAccepted(
        address nftContractAddress,
        uint256 tokenId,
        address from,
        address to,
        address erc20Token,
        uint256 price,
        uint256 duration,
        uint256 until
    );

    event offerCanceled(
        address nftContractAddress,
        uint256 tokenId
    );

    event nftRetrieved(
        address nftContractAddress,
        uint256 tokenId
    );

    event erc20Set(
        address erc20Token,
        bool isAllowed,
        uint32 feePercentage
    );

    function ownerOf(address _nftContractAddress, uint256 _tokenId) public view returns(address) {
        address nftOwner = IERC721(_nftContractAddress).ownerOf(_tokenId);

        if(nftOwner == address(this)) {
            return owners[_nftContractAddress][_tokenId];
        }

        return nftOwner;
    }

    function userOf(address _nftContractAddress, uint256 _tokenId) external view returns(address) {
        if(lent[_nftContractAddress][_tokenId].until >= block.timestamp) {
            return lent[_nftContractAddress][_tokenId].to;
        }

        address nftOwner = IERC721(_nftContractAddress).ownerOf(_tokenId);

        if(nftOwner == address(this)) {
            return address(0);
        }

        return nftOwner;
    }

    function canUse(address _nftContractAddress, uint256 _tokenId, address _user, uint256 _until) external view returns(bool) {
        if(lent[_nftContractAddress][_tokenId].until >= block.timestamp) {
            return lent[_nftContractAddress][_tokenId].to == _user && lent[_nftContractAddress][_tokenId].until >= _until;
        }

        return IERC721(_nftContractAddress).ownerOf(_tokenId) == _user;
    }

    function createOffer(
        address _nftContractAddress,
        uint256 _tokenId,
        address _to,
        address _erc20Token,
        uint256 _price,
        uint256 _minDuration,
        uint256 _expiration
        ) external {
        require(ownerOf(_nftContractAddress, _tokenId) == msg.sender, "Not nft owner");
        require(erc20Tokens[_erc20Token].isAllowed, "erc20Token not allowed");
        offers[_nftContractAddress][_tokenId] = Offer(msg.sender, _to, _erc20Token, _price, _minDuration, _expiration);

        emit offerCreated(_nftContractAddress, _tokenId, msg.sender, _to, _erc20Token, _price, _minDuration, _expiration);
    }

    function acceptOffer(address _nftContractAddress, uint256 _tokenId, uint256 _duration) external payable {
        require(lent[_nftContractAddress][_tokenId].until < block.timestamp, "NFT already lent");

        Offer memory offer = offers[_nftContractAddress][_tokenId];
        address nftOwner = ownerOf(_nftContractAddress, _tokenId);
        uint256 lentUntil = block.timestamp + (_duration * 86400); // there are 86400 seconds in a day

        require(nftOwner == offer.from, "Seller does not own NFT");
        require(nftOwner != nftOwner, "Cannot borrow own NFT");
        require(offer.to == msg.sender || offer.to == address(0));
        require(offer.expiration >= lentUntil && offer.minDuration <= _duration, "Duration out of bounds");

        uint256 price = offer.price * _duration;
        uint256 fee = price * erc20Tokens[offer.erc20Token].feePercentage / 10000;

        if (offer.erc20Token != address(0)) {
            require(msg.value == 0, "Payment not accepted");

            IERC20(offer.erc20Token).transferFrom(msg.sender, address(this), price);
            IERC20(offer.erc20Token).transfer(nftOwner, price - fee);
        } else {
            require(msg.value >= price , "Payment not accepted");

            (bool success, ) = payable(nftOwner).call{
                value: price - fee
            }("");
            require(success, "Eth transfer failed");
        }

        if(IERC721(_nftContractAddress).ownerOf(_tokenId) != address(this)) {
            IERC721(_nftContractAddress).transferFrom(nftOwner, address(this), _tokenId);
            owners[_nftContractAddress][_tokenId] = nftOwner;
        }

        lent[_nftContractAddress][_tokenId] = Lent(nftOwner, msg.sender, lentUntil);

        emit offerAccepted(_nftContractAddress, _tokenId, nftOwner, msg.sender, offer.erc20Token, price, _duration, lentUntil);
    }

    function extendBorrowing(address _nftContractAddress, uint256 _tokenId, uint256 _duration) external {
        uint256 until = lent[_nftContractAddress][_tokenId].until;
        require(until >= block.timestamp, "NFT not lent");
        require(lent[_nftContractAddress][_tokenId].to == msg.sender, "Not borrower");

        until += _duration * 86400; // there are 86400 seconds in a day
        require(until <= offers[_nftContractAddress][_tokenId].expiration, "Duration too long");

        address erc20Token = offers[_nftContractAddress][_tokenId].erc20Token;
        address nftOwner = owners[_nftContractAddress][_tokenId];

        uint256 price = offers[_nftContractAddress][_tokenId].price * _duration;
        uint256 fee = price * erc20Tokens[erc20Token].feePercentage / 10000;

        IERC20(erc20Token).transferFrom(msg.sender, address(this), price);
        
        IERC20(erc20Token).transfer(nftOwner, price - fee);

        lent[_nftContractAddress][_tokenId].until = until;

        emit offerAccepted(_nftContractAddress, _tokenId, nftOwner, msg.sender, erc20Token, price, _duration, until);
    }

    function cancelOffer(address _nftContractAddress, uint256 _tokenId) external {
        require(msg.sender == ownerOf(_nftContractAddress, _tokenId));
        delete offers[_nftContractAddress][_tokenId];
        emit offerCanceled(_nftContractAddress, _tokenId);
    }

    function retrieveNft(address _nftContractAddress, uint256 _tokenId) external {
        require(ownerOf(_nftContractAddress, _tokenId) == msg.sender);
        require(lent[_nftContractAddress][_tokenId].until < block.timestamp);

        IERC721(_nftContractAddress).transferFrom(address(this), msg.sender, _tokenId);

        delete lent[_nftContractAddress][_tokenId];
        delete offers[_nftContractAddress][_tokenId];
        delete owners[_nftContractAddress][_tokenId];

        emit offerCanceled(_nftContractAddress, _tokenId);
        emit nftRetrieved(_nftContractAddress, _tokenId);
    }

    function withdraw(address _currency, uint256 _amount) external onlyOwner {
        if(_currency == address(0)) {
            (bool successfulWithdraw, ) = msg.sender.call{
                value: address(this).balance,
                gas: 20000
            }("");
            require(successfulWithdraw, "withdraw failed");
        } else {
            IERC20(_currency).transfer(msg.sender, _amount);
        }
    }

    function setErc20Token(address _erc20Token, bool _isAllowed, uint32 _feePercentage) external onlyOwner {
        require(_feePercentage <= 1000, "Fee too high"); // can't be more than 10%
        erc20Tokens[_erc20Token].isAllowed = _isAllowed;
        erc20Tokens[_erc20Token].feePercentage = _feePercentage;
        emit erc20Set(_erc20Token, _isAllowed, _feePercentage);
    }

    function getOffer(address _nftContractAddress, uint256 _tokenId) external view returns(Offer memory){
        return offers[_nftContractAddress][_tokenId];
    }

    function getLent(address _nftContractAddress, uint256 _tokenId) external view returns(Lent memory){
        return lent[_nftContractAddress][_tokenId];
    }
}