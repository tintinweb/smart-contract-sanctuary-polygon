/**
 *Submitted for verification at polygonscan.com on 2022-12-06
*/

// File: contracts/tunnel/FxBaseChildTunnel.sol

// //: MIT
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor {
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external virtual {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal virtual;
}

// File: contracts/lib/Create2.sol

// //: MIT
pragma solidity ^0.8.0;

// Create2 adds common methods for minimal proxy with create2
abstract contract Create2 {
    // creates clone using minimal proxy
    function createClone(bytes32 _salt, address _target) internal returns (address _result) {
        bytes20 _targetBytes = bytes20(_target);

        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), _targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            _result := create2(0, clone, 0x37, _salt)
        }

        require(_result != address(0), "Create2: Failed on minimal deploy");
    }

    // get minimal proxy creation code
    function minimalProxyCreationCode(address logic) internal pure returns (bytes memory) {
        bytes10 creation = 0x3d602d80600a3d3981f3;
        bytes10 prefix = 0x363d3d373d3d3d363d73;
        bytes20 targetBytes = bytes20(logic);
        bytes15 suffix = 0x5af43d82803e903d91602b57fd5bf3;
        return abi.encodePacked(creation, prefix, targetBytes, suffix);
    }

    // get computed create2 address
    function computedCreate2Address(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) public pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}

// File: contracts/lib/IERC165.sol

// //: MIT

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

// File: contracts/lib/IERC721.sol

// //: MIT

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

// File: contracts/tokens/IFxERC721.sol

// //: MIT
pragma solidity ^0.8.0;


interface IFxERC721 is IERC721 {
    function fxManager() external returns (address);

    function connectedToken() external returns (address);

    function initialize(
        address _fxManager,
        address _connectedToken,
        string memory _name,
        string memory _symbol
    ) external;

    function mint(
        address user,
        uint256 tokenId,
        bytes memory _data
    ) external;

    function burn(uint256 tokenId) external;
}

// File: contracts/lib/IERC721Receiver.sol

// //: MIT

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

// File: @openzeppelin/contracts/utils/Context.sol

// //: MIT

pragma solidity ^0.8.0;

/*
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

// //: MIT

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
}

// File: contracts/examples/erc721-transfer/FxERC721ChildTunnel.sol

// //: MIT
pragma solidity ^0.8.0;





/**
 * @title FxERC721ChildTunnel
 */
contract FxERC721ChildTunnel is FxBaseChildTunnel, Create2, IERC721Receiver, Ownable {
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");
    bytes32 public constant MAP_TOKEN = keccak256("MAP_TOKEN");
    string public constant SUFFIX_NAME = " (FXERC721)";
    string public constant PREFIX_SYMBOL = "fx";

    // event for token mapping
    event TokenMapped(address indexed rootToken, address indexed childToken);
    // root to child token
    mapping(address => address) public rootToChildToken;
    // token template
    address public tokenTemplate;

    constructor(address _fxChild, address _tokenTemplate) FxBaseChildTunnel(_fxChild) {
        tokenTemplate = _tokenTemplate;
        require(_isContract(_tokenTemplate), "Token template is not contract");
    }

    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256, /* tokenId */
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function withdraw(
        address childToken,
        uint256 tokenId,
        bytes memory data
    ) external {
        _withdraw(childToken, msg.sender, tokenId, data);
    }

    function withdrawTo(
        address childToken,
        address receiver,
        uint256 tokenId,
        bytes memory data
    ) external {
        _withdraw(childToken, receiver, tokenId, data);
    }

    //
    // Internal methods
    //

    function _processMessageFromRoot(
        uint256, /* stateId */
        address sender,
        bytes memory data
    ) internal override validateSender(sender) {
        // decode incoming data
        (bytes32 syncType, bytes memory syncData) = abi.decode(data, (bytes32, bytes));

        if (syncType == DEPOSIT) {
            _syncDeposit(syncData);
        } else if (syncType == MAP_TOKEN) {
            _mapToken(syncData);
        } else {
            revert("FxERC721ChildTunnel: INVALID_SYNC_TYPE");
        }
    }

    function mapToken (address rootToken, address childToken) external onlyOwner{
        address _childToken = rootToChildToken[rootToken];

        // check if it's already mapped
        //require(_childToken == address(0x0), "FxERC721ChildTunnel: ALREADY_MAPPED");

        // map the token
        rootToChildToken[rootToken] = childToken;
        emit TokenMapped(rootToken, childToken);
    }

    function _mapToken(bytes memory syncData) internal returns (address) {
        (address rootToken, string memory name, string memory symbol) = abi.decode(syncData, (address, string, string));

        // get root to child token
        address childToken = rootToChildToken[rootToken];

        // check if it's already mapped
        require(childToken == address(0x0), "FxERC721ChildTunnel: ALREADY_MAPPED");

        // deploy new child token
        bytes32 salt = keccak256(abi.encodePacked(rootToken));
        childToken = createClone(salt, tokenTemplate);
        IFxERC721(childToken).initialize(
            address(this),
            rootToken,
            string(abi.encodePacked(name, SUFFIX_NAME)),
            string(abi.encodePacked(PREFIX_SYMBOL, symbol))
        );

        // map the token
        rootToChildToken[rootToken] = childToken;
        emit TokenMapped(rootToken, childToken);

        // return new child token
        return childToken;
    }

    function _syncDeposit(bytes memory syncData) internal {
        (address rootToken, address depositor, address to, uint256 tokenId, bytes memory depositData) = abi.decode(
            syncData,
            (address, address, address, uint256, bytes)
        );
        address childToken = rootToChildToken[rootToken];

        // deposit tokens
        IFxERC721 childTokenContract = IFxERC721(childToken);
        childTokenContract.mint(to, tokenId, depositData);
    }

    function _withdraw(
        address childToken,
        address receiver,
        uint256 tokenId,
        bytes memory data
    ) internal {
        IFxERC721 childTokenContract = IFxERC721(childToken);
        // child token contract will have root token
        address rootToken = childTokenContract.connectedToken();

        // validate root and child token mapping
        require(
            childToken != address(0x0) && rootToken != address(0x0) && childToken == rootToChildToken[rootToken],
            "FxERC721ChildTunnel: NO_MAPPED_TOKEN"
        );

        require(msg.sender == childTokenContract.ownerOf(tokenId));

        // withdraw tokens
        childTokenContract.burn(tokenId);

        // send message to root regarding token burn
        _sendMessageToRoot(abi.encode(rootToken, childToken, receiver, tokenId, data));
    }

    // check if address is contract
    function _isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}