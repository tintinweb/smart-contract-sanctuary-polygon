//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IERC721Template.sol";
import "./interfaces/IERC20Template.sol";
import "./utils/DataPool.sol";
import "./interfaces/pools/IFixPrice.sol";
import "./interfaces/INVG8Factory.sol";
import "./interfaces/pools/IUniswapV2.sol";
import "./utils/Utils.sol";

contract NVG8Marketplace is Ownable, DataPool {
    using Counters for Counters.Counter;
    Counters.Counter private _dataTokenIdCounter;

    // EVENTS

    // STRUCTS
    struct DataToken {
        address erc721Token;
        address erc20Token;
        address owner;
        string name;
        string symbol;
        uint256 usagePrice;
        bool isActive;
        PoolTypes poolType;
    }

    // STATE VARIABLES
    mapping(uint256 => DataToken) public dataTokens;
    address public nvg8Factory;
    address public nvg8Token;
    mapping(uint256 => mapping(address => uint256))
        public dataTokenUseAllowance;

    // MODIFIERS
    modifier onlyFactoryOrOwner() {
        require(
            msg.sender == nvg8Factory || msg.sender == owner(),
            "Only factory or owner can do this"
        );
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == nvg8Factory, "Only factory can do this");
        _;
    }

    // CONSTRUCTOR
    constructor(address _nvg8Token) {
        nvg8Token = _nvg8Token;
    }

    function enlistDataToken(
        address _erc721Token,
        address _erc20Token,
        address _owner,
        string memory _name,
        string memory _symbol,
        uint256 _usagePrice,
        PoolTypes _poolType
    ) public onlyFactory returns (uint256) {
        // check if the data token is already enlisted
        uint256 _dataTokenId = _dataTokenIdCounter.current();
        _dataTokenIdCounter.increment();
        // enlist data token
        DataToken memory dataToken = DataToken(
            _erc721Token,
            _erc20Token,
            _owner,
            _name,
            _symbol,
            _usagePrice,
            true,
            _poolType
        );
        dataTokens[_dataTokenId] = dataToken;
        return _dataTokenId;
    }

    function unlistDataToken(uint256 _dataTokenId) public {
        // verify the owner & unlist datatoken if it is active
        require(dataTokens[_dataTokenId].isActive, "Data token is not active");
        require(
            dataTokens[_dataTokenId].owner == msg.sender ||
                msg.sender == owner(),
            "Only the datatoken owner or contract owner can unlist data token"
        );

        dataTokens[_dataTokenId].isActive = false;
    }

    function getDataToken(uint256 _dataTokenId)
        public
        view
        returns (DataToken memory)
    {
        return dataTokens[_dataTokenId];
    }

    function deleteDataToken(uint256 _dataTokenId) public onlyOwner {
        // delete data token
        delete dataTokens[_dataTokenId];
    }

    function _buyDataTokenForUse(uint256 _dataTokenId, uint256 _days) private {
        // TODO: validate _days
        // require(IERC20Template(dataTokens[_dataTokenId].erc20Token).allowance(msg.sender, address(this)) >= _amount * dataTokens[_dataTokenId].usagePrice, "Not enough allowance");
        dataTokenUseAllowance[_dataTokenId][msg.sender] = block.timestamp + _days * 24 * 60 * 60;       
    }

    function getDataPool(PoolTypes _poolType) public view returns (address) {
        address poolAddress = INVG8Factory(nvg8Factory).getPoolAddress(_poolType);
        return poolAddress;
    }

    function buyDataTokenForUse(uint256 _dataTokenId) public {
        require(
            dataTokens[_dataTokenId].erc20Token != address(0) &&
                dataTokens[_dataTokenId].isActive,
            "Data token not enlisted"
        );
        require(
            IERC20Template(nvg8Token).balanceOf(
                msg.sender
            ) >= dataTokens[_dataTokenId].usagePrice,
            "Not enough NVG8 Token"
        );

        // get the data token pricing pool type
        PoolTypes poolType = dataTokens[_dataTokenId].poolType;
        // get the data token pricing pool using if...else statement
        if (poolType == PoolTypes.FIX_PRICE) {
            address poolAddress = INVG8Factory(nvg8Factory).getPoolAddress(poolType);
            IFixPrice(poolAddress).buyToken(
                _dataTokenId,
                dataTokens[_dataTokenId].usagePrice,
                dataTokens[_dataTokenId].owner,
                msg.sender
            );
            _buyDataTokenForUse(_dataTokenId, 1);
        } else if (poolType == PoolTypes.UNISWAP_V2) {
            address poolAddress = INVG8Factory(nvg8Factory).getPoolAddress(poolType);
            IUniswapV2(poolAddress).swapTokens(
                _dataTokenId,
                1,
                1,
                msg.sender,
                1000
            );
            _buyDataTokenForUse(_dataTokenId, 1);
        } else {
            revert("Data token pricing pool type not supported");
        }
    }

    function isAllowedToUseDataToken(uint256 _dataTokenId)
        public
        view
        returns (bool _allowed)
    {
        if (dataTokenUseAllowance[_dataTokenId][msg.sender] > block.timestamp) {
            _allowed = true;
        } else {
            _allowed = false;
        }
    }

    // FUCTIONS FOR FACTORY CONTRACT
    function setFactory(address _nvg8Factory) public onlyOwner {
        nvg8Factory = _nvg8Factory;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Template is IERC721{
    function initialize(string memory name_, string memory symbol_, address _owner, string memory _uri) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
interface IERC20Template is IERC20{
    function initialize(string memory name_, string memory symbol_, address _owner, uint256 _totalSupply) external;
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./StringUtils.sol";

abstract contract DataPool is StringUtils{
    using Counters for Counters.Counter;
    Counters.Counter private _dataPoolIdCounter;
    // DataPoolId is a unique identifier for a DataPool

    // EVENTS
    event DataPoolCreated(uint256 indexed _dataPool);
    event DataTokenAddedToPool(uint256 indexed _dataToken, uint256 indexed _dataPool);
    event DataTokenRemovedFromPool(uint256 indexed _dataToken, uint256 indexed _dataPool);
    event DataTokenRequested(uint256 indexed _dataToken, uint256 indexed _dataPool, address indexed _requestor);

    // STORAGE
    struct DPool {
        uint256 id;
        uint256 timestamp;
        string name;
        string description;
        address owner;
        uint256[] dataTokens;
    }

    mapping(uint256 => DPool) public dataPools;
    mapping(uint256 => mapping(uint256 => uint256)) public dPoolIdToDTokenIdToIndex; // dataPoolId => dataTokenId => index
    mapping(uint256 => mapping(uint256 => address)) public dTokenToDPoolRequests; // dataPoolId => dataTokenId => address(requestor)

    // METHODS
    /**
     * @dev Creates a new DataPool
     * @param _name Name of the DataPool
     * @param _description Description of the DataPool
     * @notice it emits a DataPoolCreated(uint256 indexed _dataPool) event with the id of the new DataPool
     */

    function createDataPool( string memory _name, string memory _description) public {
        require(!StringUtils.compareStringsbyBytes(_name, ""), "DataPool: Invalid name");
        require(!StringUtils.compareStringsbyBytes(_description, ""), "DataPool: Invalid description");


        _createDataPool(_dataPoolIdCounter.current(), block.timestamp, _name, _description, msg.sender);

        emit DataPoolCreated(_dataPoolIdCounter.current());

        _dataPoolIdCounter.increment();
    }

    /**
     * @dev private function to create a new DataPool
     * @param _id Id of the new DataPool
     * @param _timestamp Timestamp of the creation of the DataPool
     * @param _name Name of the DataPool
     * @param _description Description of the DataPool
     * @param _owner Owner of the DataPool
     * @notice its an internal function that is not exposed to the outside world so it is not part of the public interface
     */
    function _createDataPool(uint256 _id, uint256 _timestamp,  string memory _name, string memory _description, address _owner) private {
        uint256[] memory empDataTokens;
        dataPools[_id] = DPool(_id, _timestamp, _name, _description, _owner, empDataTokens);
    }

    /** 
     * @dev function to get the details of a DataPool
     * @param _id Id of the DataPool
     * @return the DataPool with the given id
     */
    function getDataPool(uint256 _id) public view returns (DPool memory) {
        return dataPools[_id];
    }

    /**
     * @dev function to add a DataToken to a DataPool
     * @param _dataPoolId Id of the DataPool
     * @param _dataTokenId Id of the DataToken
     * @notice it emits a DataTokenAddedToPool(uint256 indexed _dataToken, uint256 indexed _dataPool) event with the id of the DataToken and the id of the DataPool
     */
    function addDataTokenToPool(uint256 _dataTokenId, uint256 _dataPoolId) public {
        require(dataPools[_dataPoolId].owner == msg.sender, "DataPool: Only owner can add data tokens");

        dPoolIdToDTokenIdToIndex[_dataPoolId][_dataTokenId] = dataPools[_dataPoolId].dataTokens.length;
        dataPools[_dataPoolId].dataTokens.push(_dataTokenId);

        emit DataTokenAddedToPool(_dataTokenId, _dataPoolId);
    }

    /**
     * @dev function to get the index of a DataToken in dataTokens array inside DataPool
     * @param _dataPoolId Id of the DataPool
     * @param _dataTokenId Id of the DataToken
     * @return the index of the DataToken in dataTokens array inside DataPool
     */
    function getDataTokenIndexInPool(uint256 _dataPoolId, uint256 _dataTokenId) public view returns (uint256) {
        return dPoolIdToDTokenIdToIndex[_dataPoolId][_dataTokenId];
    }

    /**
     * @dev function to get the DataToken ids in a DataPool
     * @param _dataPoolId Id of the DataPool
     * @return the DataToken ids in a DataPool
     */
    function getDataTokenIdsInPool(uint256 _dataPoolId) public view returns (uint256[] memory) {
        return dataPools[_dataPoolId].dataTokens;
    }

    // removeDataTokenFromPool
    /**
     * @dev function to remove a DataToken from a DataPool
     * @param _dataPoolId Id of the DataPool
     * @param _dataTokenId Id of the DataToken
     * @notice it emits a DataTokenRemovedFromPool(uint256 indexed _dataToken, uint256 indexed _dataPool) event with the id of the DataToken and the id of the DataPool
     */
    function removeDataTokenFromPool(uint256 _dataPoolId, uint256 _dataTokenId) public {
        require(dataPools[_dataPoolId].owner == msg.sender, "DataPool: Only owner can remove data tokens");

        uint256 dataTokenIndex = dPoolIdToDTokenIdToIndex[_dataPoolId][_dataTokenId];
        uint256[] memory dataTokens = dataPools[_dataPoolId].dataTokens;

        delete dataTokens[dataTokenIndex]; 

        dPoolIdToDTokenIdToIndex[_dataPoolId][_dataTokenId] = 0;

        emit DataTokenRemovedFromPool(_dataTokenId, _dataPoolId);
    }

    function requestToAddDataTokenToPool(uint256 _dataPoolId, uint256 _dataTokenId) public {
        // check if data token is already in the pool
        // require(dPoolIdToDTokenIdToIndex[_dataPoolId][_dataTokenId] == 0, "DataPool: DataToken already in the pool");
        dTokenToDPoolRequests[_dataPoolId][_dataTokenId] = msg.sender;

        emit DataTokenRequested(_dataTokenId, _dataPoolId, msg.sender);
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IFixPrice{
    function buyToken(uint256 _dataToken, uint256 _amount, address _owner, address _buyer) external returns (bool _success);
    function addDataToken(address _erc20address, address _erc721Address, uint256 _tokensPerUnit, uint256 _dataTokenId) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../utils/Utils.sol";
interface INVG8Factory{
    function getPoolAddress(PoolTypes _poolType) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IUniswapV2{
    function addLiquidity(uint256 _dataToken, uint256 _tAmountDesired, uint256 _tAmountMin, uint256 _nAmountDesired, uint256 _nAmountMin ) external returns( uint256, uint256, uint256);
    function swapTokens(uint256 _dataToken, uint256 _amountIn, uint256 _amountOutMin, address _to, uint256 _deadline) external;
    function addDataToken(address _erc20address, address _erc721Address, uint256 _dataTokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

enum PoolTypes {
    FIX_PRICE,
    UNISWAP_V2
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
pragma solidity ^0.8.12;

abstract contract StringUtils {
    function compareStringsbyBytes(string memory s1, string memory s2)
        internal
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }
}