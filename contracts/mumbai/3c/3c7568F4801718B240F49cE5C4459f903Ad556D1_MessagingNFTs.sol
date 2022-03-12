// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}


abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}


/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
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

contract MessagingNFTs is OwnableUpgradeable{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _messageId;

    constructor(){
        OwnableUpgradeable.__Ownable_init();
    }

    /*function initialize () public initializer {
        OwnableUpgradeable.__Ownable_init();
    }*/
    
    struct Message {
        // send
        uint256 sendType;
        address fromWallet;
        address fromContractAddress;
        uint256 fromCardId;

        //receive
        uint256 receiveType;
        address toWallet;
        address toContractAddress;
        uint256 toCardId;

        // content
        string content;

        // time stamp
        uint256 timeStamp;
    }

    mapping(uint256 => Message) messages;

    /** get current time stamp */
    function getCurrentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function sendMessage (
        uint256 _sendType,
        address _fromWallet,
        address _fromContractAddress,
        uint256 _fromCardId,
        uint256 _receiveType,
        address _toWallet,
        address _toContractAddress,
        uint256 _toCardId,
        string memory _content
    ) public returns(uint256) {
        address _sender = msg.sender;
        uint256 _timeStamp = getCurrentTime();
        require(_sender == _fromWallet || _sender == owner(), 'SEND ERROR: Your address and sender message does not match || you are not contract owner');

        if(_sendType == 2){
            require(IERC721Upgradeable(_fromContractAddress).ownerOf(_fromCardId) == _sender,
            'SEND ERROR: You are not the owner of this NFT');
        }

        /** check nft card ownership in case receiver wallet address is not zero,
         * if receiver wallet address is zero, then don't check
         */        
        if(_receiveType == 3 && _toWallet != address(0)) {
            require(IERC721Upgradeable(_toContractAddress).ownerOf(_toCardId) == _toWallet,
            'SEND ERROR: Receiver wallet is not owner of receiver NFT');
        }
        
        _messageId.increment();
        uint256 _newMessageId = _messageId.current();
        
        Message memory _message = Message(
            _sendType,
            _fromWallet,
            _fromContractAddress,
            _fromCardId,
            _receiveType,
            _toWallet,
            _toContractAddress,
            _toCardId,
            _content,
            _timeStamp
        );

        messages[_newMessageId] = _message;
    
        return _newMessageId;
    }

    /** get received message by msg.sender address */
    function getReceivedMessages () public view returns(Message[] memory){
        Message[] memory receivedMessages = new Message[] (_messageId.current());
        address _sender = msg.sender;

        for (uint256  i = 0; i < _messageId.current(); i++){
            Message memory _message = messages[i+1];
            address _cardOwner;
            
            if(_message.receiveType == 3){
                _cardOwner = IERC721Upgradeable(_message.toContractAddress).ownerOf(_message.toCardId);
            }
            
            // if receive type == 1, this message is sent to a wallet address
            if(_message.receiveType == 1){
                if(_message.toWallet == _sender){
                    receivedMessages[i] = _message;
                }
            }
            
            // if receive type == 2, this message is sent to a contract address
            if(_message.receiveType == 2){
                uint256 _userBalance = IERC721Upgradeable(_message.toContractAddress).balanceOf(_sender);
                if(_userBalance > 0){
                    // this user has NFTs, then send him this message
                    receivedMessages[i] = _message;
                }
            }

            // if receive type == 3, this message is send to specific NFT card
            if(_message.receiveType == 3 && _message.toWallet != address(0)){
                // if receiver is not Null, check if msg.sender is toWallet
                // we don't need to check ownership of card because it's already implemented in sending messages
                if(_sender == _message.toWallet && _sender == _cardOwner) {
                    receivedMessages[i] = _message;
                }
            }

            if(_message.receiveType == 3 && _message.toWallet == address(0)) {
                if(_sender == _cardOwner) {
                    receivedMessages[i] = _message;
                }
            }
        }

        return receivedMessages;
    }

    /** get sent messages by msg.sender */
    function getSentMessages () public view returns(Message[] memory) {
        Message[] memory sentMessages = new Message[] (_messageId.current());
        address _sender = msg.sender;
        
        for (uint256  i = 0; i < _messageId.current(); i++){
            Message memory _message = messages[i+1];
            address _cardOwner;
            if(_message.sendType == 2) {
                _cardOwner = IERC721Upgradeable(_message.fromContractAddress).ownerOf(_message.fromCardId);
            }
 
            if(_message.sendType == 1) {
                if(_message.fromWallet == _sender){
                    sentMessages[i] = _message;
                }
            }

            if(_message.sendType == 2) {
                if(_message.fromWallet == _sender && _cardOwner == _sender){
                    sentMessages[i] = _message;
                }
            }
        }

        return sentMessages;
    }
}