/**
 *Submitted for verification at polygonscan.com on 2023-05-09
*/

// SPDX-License-Identifier: MIT

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


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

// File: contracts/marketplace/interfaces/IERC721Token.sol


pragma solidity ^0.8.17;


interface IERC721Token is IERC721 {
    function publish(
        string memory tokenURI, 
        uint256 price, 
        uint256 lockPeriod, 
        uint32 tokenLimit, 
        uint8 royalty,
        bool isOpenEdition
    ) external returns (uint);
    function getItem(uint256 _tokenId) external returns (address, uint256, uint256, bool, bool);
    function mint(uint256 _tokenId) external returns (uint256);
    function getToken (uint256 tokenId) view external returns (address, uint256, uint32, uint8, bool);
    function setAuction (uint256 _tokenId, bool _status) external ;    
    function buyNFT(address _user, uint _tokenId, bool fromCalling) external payable;
    function owner() view external returns (address);
    function getPrice(uint tokenId) external view returns (uint);
    function setPrice(uint tokenId,uint _price) external;
    function setPublish(uint tokenId, bool _publish) external;
    function withdraw() external;
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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

// File: contracts/marketplace/interfaces/IERC1155Token.sol


pragma solidity ^0.8.17;


interface IERC1155Token is IERC1155 {
    function name() external view returns (string memory);
    function uri(uint256 _tokenId) external view returns (string memory);
    function publish(
        string memory _uri, 
        uint256 price, 
        uint256 lockPeriod, 
        uint256 quantity,
        uint32 tokenLimit, 
        uint8 royalty,
        bool isOpenEdition
    )  external returns (uint256);
    function setAuction (address _owner, uint256 _tokenId, bool _status) external;
    function getItem(address _owner, uint256 _tokenId) external returns (uint256, uint256, uint256, bool, bool);
    function mint(uint256 _tokenId) external returns (uint256);
    function buyNFT(address _user, address _owner, uint256 _tokenId, uint256 _qty, bool fromCalling) external;
    function getToken (uint256 tokenId) view external returns (address, uint256, uint32, uint8, bool);
    function setPrice (uint256 tokenId, uint256 _price) external;
    function setPublish (uint256 tokenId, bool publish) external;
    function owner() view external returns(address);
    function totalSupply() view external returns(uint256); 
    function setURI(uint256 tokenId, string memory _uri) external;
    function withdraw() external;
}

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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/marketplace/MCaller.sol


pragma solidity ^0.8.17;

//ERC1155


// import "hardhat/console.sol";

contract MCaller is Ownable {
    // Events
    event Publish(
        string uri,
        address indexed _owner,
        uint256 contractId,
        uint256 tokenId,
        uint256 price,
        uint256 lockPeriod,
        uint256 quantity,
        uint32 tokenLimit,
        uint8 royalty,
        bool publish,
        bool isOpenEdition,
        bool is1155
    );

    event Bought(
        address indexed _owner,
        address indexed _buyer,
        uint256 tokenId,
        uint256 quantity,
        bool is1155,
        bool isRoyaltyPaid
    );

    event Contract(
        address indexed _owner,
        uint256 contractId,
        bool is1155
    );

    event SetPrice(
        address indexed _owner,
        uint256 tokenId,
        uint256 price,
        bool is1155
    );
    
    event SetPublish(
        address indexed _owner,
        uint256 tokenId,
        bool publish,
        bool is1155
    );
    event UnknownPayment (address indexed account, uint256 paidAmount);

    event Mint(
        address indexed _creator,
        address indexed _owner,
        uint256 oldTokenId,
        uint256 newTokenId,
        bool is1155
    );
    event OfferEvent (
        address indexed owner,
        address indexed user,
        uint256 offerId,
        uint256 tokenId,
        uint256 lockPeriod,
        uint256 price,
        uint256 quantity,
        bool isClosed,
        bool is1155
    );
    event OfferUpdateEvent (
        uint256 offerId,
        bool isClosed
    );

    // ********************************************************************
    // ********************************************************************
    // ********************************************************************
    struct Offer {
        address owner;
        address user;
        uint256 tokenId;
        uint256 lockPeriod;
        uint256 price;
        uint256 quantity;
        bool isClosed;
        bool is1155;
    }

    struct Collection {
        address creator;
        bool is1155;
    }

    struct Info {
        address payable feeAccount;
        uint16 contractLimit;
        uint8 feePercent;
        bool isPrivate;
    }
    address public erc1155Id;
    address public erc721Id;
    Info private _info;

    string private _name;
    mapping(uint256 =>  Offer) private _offers;
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public isPrivateUser;
    mapping(uint256 => Collection) private _collections;
    mapping(address => mapping(bool => uint256[])) private _collectionIds;
    uint256 public collectionSupply;
    uint256 public offerSupply;    
    
    constructor() {
        _info = Info(payable(msg.sender), 1, 5, true);
        isWhitelisted[msg.sender] = true;
        _name = "Interality Marketplace - Caller";
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function makeOffer(
        address _owner,
        uint256 _tokenId,
        uint256 _price,
        uint256 _qty,
        uint256 lockperiod,
        bool is1155
    ) public payable {
        require(_price <= msg.value, "Underpaid");
        if(is1155) {
            require(erc1155Id != address(0), "Invalid ERC1155");
            (,, uint256 qty,, bool auction) = IERC1155Token(erc1155Id).getItem(_owner, _tokenId);
            uint256 fqty = auction ? _qty + 1 : _qty;
            require(qty >= fqty, "Quantity Exceeded");
        } else {
            require(erc721Id != address(0), "Invalid ERC721");
            (address owner02,,,, bool auction) = IERC721Token(erc721Id).getItem(_tokenId);
            require(!auction, "Under Auction");
            require(_owner == owner02, "Quantity Exceeded");
        }
        require(lockperiod <= block.timestamp + (15 * 1 days), "Exceeded Locking Period");
        offerSupply++;
        Offer storage offer = _offers[offerSupply];
        offer.owner = _owner;
        offer.user = msg.sender;
        offer.tokenId = _tokenId;
        offer.lockPeriod = lockperiod;
        offer.price = _price;
        offer.quantity = _qty;
        offer.isClosed = false;
        offer.is1155 = is1155;
        emit OfferEvent(_owner, msg.sender, offerSupply, _tokenId, lockperiod, _price, _qty, false, is1155);
    }

    function updateOffer(
        uint256 offerId,
        bool status
    )  external {
        Offer storage offer = _offers[offerId];
        require(!offer.isClosed, "Offer Already Closed");
        bool resStatus;
        if(offer.user == msg.sender || offer.lockPeriod <= block.timestamp) {
            resStatus = false;
        } else if(offer.owner == msg.sender) {
            resStatus = status;
        } else {
            revert("Offer In-Progress");
        }
        if(resStatus) {
            if(!offer.is1155) {
                require(erc721Id != address(0), "Invalid ERC721");
                (address owner,,,, ) = IERC721Token(erc721Id).getItem(offer.tokenId);
                require(owner == offer.owner, "Not Owner");
            }
            checkPrice(offer.owner, offer.tokenId, offer.price, 3, offer.is1155);                
            if(offer.is1155) {
                require(erc1155Id != address(0), "Invalid ERC1155");
                IERC1155Token(erc1155Id).buyNFT(offer.user, offer.owner, offer.tokenId, offer.quantity, true);
            } else {
                IERC721Token(erc721Id).buyNFT(offer.user, offer.tokenId, true);
            }
        } else {
            payable(offer.user).transfer(offer.price);
        }
        offer.isClosed = true;
        emit OfferUpdateEvent(offerId, true);
    }

    /**
    * @notice Updates the Fee Account address
    * @dev Updates the Fee Account address if address is valid
    * @param _feeAccount Fee Account Address
    */
    function setFeeAccount(
        address _feeAccount
    ) external onlyOwner {
        require(_feeAccount != address(0), "Invalid Address");
        _info.feeAccount = payable(_feeAccount);
    }
    function setFeePercent(
        uint8 _feePercent
    ) external onlyOwner {
        require(_feePercent < 6, "Invalid Percent");
        _info.feePercent = _feePercent;
    }

    function setPrivateAccount(
        address[] memory _users,
        bool _isPrivate
    ) external onlyOwner {
        for (uint256 idx = 0; idx < _users.length; idx++) {
            if(_users[idx] != address(0)) isPrivateUser[_users[idx]] = _isPrivate;
        }
    }

    function setPrivateStatus(
        bool _isPrivate
    ) external onlyOwner {
        _info.isPrivate = _isPrivate;
    }

    function contractInfo() external view returns(address, uint16, uint8, bool) {
        return(_info.feeAccount, _info.contractLimit, _info.feePercent, _info.isPrivate);
    }
    function collectionInfo(
        uint256 colId
    ) external view returns(address, bool) {
        return(
            _collections[colId].creator, 
            _collections[colId].is1155
        );
    }

    function setContractLimit(
        uint16 _contractLimit
    ) external onlyOwner {
        _info.contractLimit = _contractLimit;
    }
    function setWhitelist(
        address _user,
        bool _status
    ) external onlyOwner {
        require(_user != address(0), "Invalid Address");
        isWhitelisted[_user] = _status;
    }

    /**
    * @notice Extarcts the user collection addresses
    * @dev returns array of address for collection 
    * @param _user User address
    * @return address[] Collection or Contract addresse which belongs to user
    */
    function collectionIds(
        address _user,
        bool is1155
    ) external view returns(uint256[] memory) {
        return _collectionIds[_user][is1155];
    }

    /**
    * @notice Updates Factory contract address for ERC1155
    * @dev Checks if the address is valid or not and Updates Factory contract address for ERC1155
    * @param _factoryContract Factory contract address
    */
    function setContractFactory(
        address _factoryContract,
        bool is1155
    ) external {
        require(tx.origin == owner(), "Tx.Origin must be owner");
        require(_factoryContract != address(0), "Invalid Address");
        if(is1155) erc1155Id = _factoryContract;
        else erc721Id = _factoryContract;
    }

    function createColletion(
        bool is1155
    ) external returns (uint256) {
        // checkUnderCollection
        if(_info.isPrivate) require(isPrivateUser[msg.sender], "Not a Private User");
        uint256 count = _collectionIds[msg.sender][is1155].length;
        uint16 limit = _info.contractLimit;
        if(limit <= count) {
            uint count02 = _collectionIds[msg.sender][!is1155].length;
            require(limit == count && isWhitelisted[msg.sender] && limit >= count02, "Limit Exceeded");
        }
        collectionSupply++;
        _collections[collectionSupply] = Collection(msg.sender, is1155);
        _collectionIds[msg.sender][is1155].push(collectionSupply);
        emit Contract(msg.sender, collectionSupply, is1155);
        return collectionSupply;
    }

    function publish(
        string memory _uri,
        uint256 contractId,
        uint256 price, 
        uint256 lockPeriod,
        uint256 quantity, 
        uint32 tokenLimit,
        uint8 _royalty,
        bool isOpenEdition,
        bool is1155
    )  external returns (uint256 tokenId) {
        if(_info.isPrivate) require(isPrivateUser[msg.sender], "Not a Private User");
        require(_royalty <= 10, "Royalty Exceeded (Max:10%)");
        require(msg.sender != address(0), "Empty Caller");
        require(msg.sender == _collections[contractId].creator, "Not Collection Owner");
        require(_collections[contractId].is1155 == is1155, "Invalid Type");

        uint256 qty = is1155 && !isOpenEdition ? quantity : 1;
        if(is1155) {
            tokenId = IERC1155Token(erc1155Id)
                .publish(_uri, price, lockPeriod, qty, tokenLimit, _royalty, isOpenEdition);
        } else {
            tokenId = IERC721Token(erc721Id)
                .publish(_uri, price, lockPeriod, tokenLimit, _royalty, isOpenEdition);
        }
        emit Publish(_uri, msg.sender, contractId, tokenId, price, lockPeriod, qty, tokenLimit, _royalty, true, isOpenEdition, is1155);
    }

    function checkPrice(
        address _owner02, 
        uint256 _tokenId,
        uint256 price,
        uint8 payType,
        bool isERC1155
    ) internal {
        address _creator;
        address _owner;
        uint256 lockPeriod;
        uint8 _royalty;
        bool isOpenEdition;
        if(isERC1155) {
            (_creator, lockPeriod,, _royalty, isOpenEdition) = IERC1155Token(erc1155Id).getToken(_tokenId);        
            _owner = _owner02;
        } else {
            (_creator, lockPeriod,, _royalty, isOpenEdition) = IERC721Token(erc721Id).getToken(_tokenId);
            _owner = IERC721Token(erc721Id).ownerOf(_tokenId);
        }
        require(_owner != address(0), "Unkown Owner");
        if(payType != 3) {
            require(price <= msg.value, "Insufficient Amount");
            require(_owner != msg.sender, "Own Asset");
        } 
        
        if(payType == 1 && isOpenEdition) {
            require(lockPeriod < block.timestamp, "Under Open Edition");
        }
        uint256 contractFee = (price * _info.feePercent) / 100;        
        // Owner Fee
        if(_owner == _creator) {
            address payable owner = payable(_owner);
            _info.feeAccount.transfer(contractFee);
            owner.transfer(price - contractFee);
        } else {
            require(_creator != address(0), "Unkown Creator");
            uint256 royaltyFee = (price * _royalty) / 100;
            // Tranfer Fee
            _info.feeAccount.transfer(contractFee);
            payable(_creator).transfer(royaltyFee);
            payable(_owner).transfer(price - royaltyFee - contractFee);
        }
    }

    function purchase(
        address _owner,
        uint256 _tokenId,
        uint256 _qty,
        bool is1155,
        bool isDirectPay
    ) external payable {
        uint256 price; 
        uint256 tqty; 
        bool auction;
        if(is1155) {
            (price,, tqty,, auction ) = IERC1155Token(erc1155Id).getItem(_owner, _tokenId);
            if(auction) require(tqty > _qty, "Asset Under Auction (Qty)");
        } else {
            (, price,,, auction) = IERC721Token(erc721Id).getItem(_tokenId);
            require(auction == false, "Asset Under Auction");
        }

        checkPrice(_owner, _tokenId, price, isDirectPay ? 1 : 2, is1155);
        if(isDirectPay) {
            if(is1155) IERC1155Token(erc1155Id).buyNFT(address(0), _owner, _tokenId, _qty, true);
            else IERC721Token(erc721Id).buyNFT(address(0), _tokenId, true);
            // emit Bought(_from, _to, _tokenId, is1155 ? _qty : 1, is1155);
        } else {
            uint256 newId;
            if(is1155) newId = IERC1155Token(erc1155Id).mint(_tokenId);
            else newId = IERC721Token(erc721Id).mint(_tokenId);
            emit Mint(_owner, msg.sender, _tokenId, newId, is1155);
        }
    }

    function _bought(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _qty,
        bool is1155,
        bool isRoyaltyPaid
    ) external {
        emit Bought(_from, _to, _tokenId, is1155 ? _qty : 1, is1155, isRoyaltyPaid);
    }
    
    function setPrice(
        uint256 tokenId, 
        uint256 price,
        bool is1155
    ) external {
        if(_info.isPrivate) require(isPrivateUser[msg.sender], "Not a Private User");
        if(is1155) IERC1155Token(erc1155Id).setPrice(tokenId, price);
        else IERC721Token(erc721Id).setPrice(tokenId, price);
        emit SetPrice(msg.sender, tokenId, price, is1155);
    }

    function setPublish(
        uint256 tokenId, 
        bool _publish,
        bool is1155
    ) external {
        if(_info.isPrivate) require(isPrivateUser[msg.sender], "Not a Private User");
        if(is1155) IERC1155Token(erc1155Id).setPublish(tokenId, _publish);
        else IERC721Token(erc721Id).setPublish(tokenId, _publish);
        emit SetPublish(msg.sender, tokenId, _publish, is1155);
    }

    /// @notice Withdraws Ether stored on Contract & only called by Calling Contract Owner
    function withdraw() external payable onlyOwner {
        (bool success, ) = payable(owner()).call{ value: address(this).balance }("");
        require(success, "Failed");
    }

    /// @notice Updates the information about unknowm payments to the Contract
    receive() external payable {
        emit UnknownPayment(msg.sender, msg.value);
    }
}