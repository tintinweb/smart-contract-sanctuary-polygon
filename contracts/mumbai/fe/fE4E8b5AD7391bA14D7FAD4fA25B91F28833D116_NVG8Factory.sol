//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC721Template.sol";
import "./interfaces/IERC20Template.sol";
import "./interfaces/INVG8Marketplace.sol";
import "./interfaces/pools/IFixPrice.sol";
import "./interfaces/pools/IUniswapV2.sol";
import "./utils/Utils.sol";

contract NVG8Factory is Ownable {
    // EVENTS
    event TemplateAdded(TemplateType _type, address _template);
    event TemplateRemoved(TemplateType _type, address _template);
    event TemplateStatusChanged(
        TemplateType _type,
        address _template,
        bool _status
    );
    event DataTokenCreated(
        address _erc721Token,
        address _erc20Token,
        uint256 dataTokenId,
        address _owner,
        string _name,
        string _symbol,
        uint256 _totalSupply
        // string _uri
    );
    event poolAdded(PoolTypes _poolType, address _poolAddress);
    event poolRemoved(PoolTypes _poolType);

    // ENUM
    enum TemplateType {
        ERC721,
        ERC20
    }

    // STRUCTS
    struct Template {
        address templateAddress;
        bool isActive;
        TemplateType templateType;
    }
    struct DataToken {
        address erc721Token;
        address erc20Token;
        address owner;
        string name;
        string symbol;
        uint256 usagePrice;
    }

    // STATE VARIABLES
    mapping(uint256 => Template) public templates;
    address public nvg8Marketplace;
    mapping(PoolTypes => address) public poolAddresses; // stores the address of the pricing pools like Uniswap and fix price etc

    // MODIFIERS
    //Modifier onlyMarketplaceOrOwner
    modifier onlyMarketplaceOrOwner() {
        require(
            msg.sender == nvg8Marketplace || msg.sender == owner(),
            "Only marketplace or factory can do this"
        );
        _;
    }

    // CONSTRUCTOR
    constructor() {}

    // TEMPLATE FUNCTIONS
    /**
    * @notice Add a new template to the factory
    * @dev Add a `Template` struct in `templates` mapping with `_index` as key.
    * @param _type The type of the template to be added.
    * @param _template The address of the template to be added.
    * @param _index The index of the template to be added.
    * @dev Emit the `TemplateAdded` event.
    */
    function createTemplate(
        TemplateType _type,
        address _template,
        uint256 _index
    ) public onlyOwner {
        require(
            templates[_index].templateAddress == address(0),
            "Template already exists"
        );

        templates[_index] = Template({
            templateAddress: _template,
            isActive: true,
            templateType: _type
        });

        emit TemplateAdded(_type, _template);
    }

    /**
    * @notice Remove a template from the factory
    * @dev it just delete the template from the `templates` mapping againsts the `_index` key.
    * @param _index The index of the template to be removed.
    * @dev Emit the `TemplateRemoved` event.
    */
    function removeTemplate(uint256 _index) public onlyOwner {
        require(
            templates[_index].templateAddress != address(0),
            "Template does not exist"
        );

        emit TemplateRemoved(
            templates[_index].templateType,
            templates[_index].templateAddress
        );

        delete templates[_index];
    }

    /**
    * @notice Change the status of a template
    * @dev Set the `isActive` field of the template against the `_index` key to `_status`.
    * @param _index The index of the template to be changed.
    * @param _status The new status of the template.
    * @dev Emit the `TemplateStatusChanged` event.
    */
    function changeTemplateStatus(uint256 _index, bool _status)
        public
        onlyOwner
    {
        require(
            templates[_index].templateAddress != address(0),
            "Template does not exist"
        );

        templates[_index].isActive = _status;

        emit TemplateStatusChanged(
            templates[_index].templateType,
            templates[_index].templateAddress,
            _status
        );
    }

    /** 
    * @notice Add a new pricing pool address to the factory
    * @dev Add a new pricing pool address to the `poolAddresses` mapping againsts the `_poolType` key.
    * @param _poolType The type of the pricing pool to be added.
    * @param _poolAddress The address of the pricing pool to be added.
    * @dev Emit the `PoolAdded` event.
    */
    function addPoolAddress(PoolTypes _poolType, address _poolAddress)
        public
        onlyOwner
    {
        require(poolAddresses[_poolType] == address(0), "Pool already exists"); // ? Should we allow Owner to update the pool address?

        poolAddresses[_poolType] = _poolAddress;

        emit poolAdded(_poolType, _poolAddress);
    }

    /**
    * @notice Remove a pricing pool address from the factory
    * @dev it just delete the pricing pool address from the `poolAddresses` mapping againsts the `_poolType` key.
    * @param _poolType The type of the pricing pool to be removed.
    * @dev Emit the `PoolRemoved` event.
    */
    function removePoolAddress(PoolTypes _poolType) public onlyOwner {
        require(poolAddresses[_poolType] != address(0), "Pool does not exist");
        delete poolAddresses[_poolType];

        emit poolRemoved(_poolType);
    }

    /**
    * @notice Create a new data token
    * @dev Create a new data token with the given parameters, it's an internal function.
    * @param _ERC721TemplateIndex The index of the ERC721 template to be used.
    * @param _ERC20TemplateIndex The index of the ERC20 template to be used.
    * @param _name The name of the data token.
    * @param _symbol The symbol of the data token.
    * @param _uri The URI of the data token.
    * @param _totalSupply The total supply of the data token.
    * @param _poolType The type of the pricing pool to be used.
    * @dev Emit the `DataTokenCreated` event.
    * @return The erc721 address of the new data token.
    * @return The erc20 address of the new data token.
    * @return The data token Id of the new data token.
    */
    function _createDataToken(
        uint256 _ERC721TemplateIndex,
        uint256 _ERC20TemplateIndex,
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _totalSupply,
        PoolTypes _poolType
    )
        internal
        returns (
            address,
            address,
            uint256
        )
    {
        require(
            templates[_ERC721TemplateIndex].templateAddress != address(0) &&
                templates[_ERC721TemplateIndex].isActive &&
                templates[_ERC721TemplateIndex].templateType ==
                TemplateType.ERC721,
            "ERC721 template does not exist or is not active"
        );

        require(
            templates[_ERC20TemplateIndex].templateAddress != address(0) &&
                templates[_ERC20TemplateIndex].isActive &&
                templates[_ERC20TemplateIndex].templateType ==
                TemplateType.ERC20,
            "ERC20 template does not exist or is not active"
        );

        require(
            nvg8Marketplace != address(0),
            "NVG8 Marketplace does not exist"
        );

        // clone ERC721Template
        address erc721Token = Clones.clone(
            templates[_ERC721TemplateIndex].templateAddress
        );

        // clone ERC20Template
        address erc20Token = Clones.clone(
            templates[_ERC20TemplateIndex].templateAddress
        );

        // initialize erc721Token
        IERC721Template(erc721Token).initialize(
            _name,
            _symbol,
            msg.sender,
            _uri
        );

        // initialize erc20Token
        IERC20Template(erc20Token).initialize(
            _name,
            _symbol,
            msg.sender,
            _totalSupply
        );

        uint256 dataTokenId = enlistDataTokenOnMarketplace(
            erc721Token,
            erc20Token,
            msg.sender,
            _name,
            _symbol,
            1,
            _poolType
        );

        emit DataTokenCreated(
            erc721Token,
            erc20Token,
            dataTokenId,
            msg.sender,
            _name,
            _symbol,
            _totalSupply
        );

        return (erc721Token, erc20Token, dataTokenId);
    }

    /**
    * @notice Create a new data token with fixed price
    * @dev This funtion will create a Fixed price data token.
    * @param _ERC721TemplateIndex The index of the ERC721 template to be used.
    * @param _ERC20TemplateIndex The index of the ERC20 template to be used.
    * @param _name The name of the data token.
    * @param _symbol The symbol of the data token.
    * @param _uri The URI of the data token.
    * @param _totalSupply The total supply of the data token.
    * @param _tokensPerUnit The nvg8 tokens per unit of the data token.
    */
    function createDataTokenWithFixedPrice(
        uint256 _ERC721TemplateIndex,
        uint256 _ERC20TemplateIndex,
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _totalSupply,
        uint256 _tokensPerUnit
    ) public {
        (
            address erc721Token,
            address erc20Token,
            uint256 dataTokenId
        ) = _createDataToken(
                _ERC721TemplateIndex,
                _ERC20TemplateIndex,
                _name,
                _symbol,
                _uri,
                _totalSupply,
                PoolTypes.FIX_PRICE
            );

        require(
            poolAddresses[PoolTypes.FIX_PRICE] != address(0),
            "Fixed Price Pool does not exist"
        );

        IFixPrice(poolAddresses[PoolTypes.FIX_PRICE]).addDataToken(
            erc20Token,
            erc721Token,
            _tokensPerUnit,
            dataTokenId
        );
    }

    /**
    * @notice Create a new data token with dynamic price, using UniswapV2 as the pricing pool.
    * @dev This funtion will create a Dynamic price data token, and will use UniswapV2 as the pricing pool.
    * @param _ERC721TemplateIndex The index of the ERC721 template to be used.
    * @param _ERC20TemplateIndex The index of the ERC20 template to be used.
    * @param _name The name of the data token.
    * @param _symbol The symbol of the data token.
    * @param _uri The URI of the data token.
    * @param _totalSupply The total supply of the data token.
    */
    function createDataTokenWithUniswapV2(
        uint256 _ERC721TemplateIndex,
        uint256 _ERC20TemplateIndex,
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _totalSupply
    ) public {
        (
            address erc721Token,
            address erc20Token,
            uint256 dataTokenId
        ) = _createDataToken(
                _ERC721TemplateIndex,
                _ERC20TemplateIndex,
                _name,
                _symbol,
                _uri,
                _totalSupply,
                PoolTypes.UNISWAP_V2
            );
        require(
            poolAddresses[PoolTypes.UNISWAP_V2] != address(0),
            "UniswapV2 pool does not exist"
        );

        IUniswapV2(poolAddresses[PoolTypes.UNISWAP_V2]).addDataToken(
            erc20Token,
            erc721Token,
            dataTokenId
        );
    }

    /**
    * @notice Set the nvg8 marketplace address.
    * @dev This function will set the nvg8 marketplace address.
    * @param _marketplace The nvg8 marketplace address.
    */
    function setMarketplace(address _marketplace) public onlyOwner {
        nvg8Marketplace = _marketplace;
    }

    /**
    * @notice Enlist a data token on the nvg8 marketplace.
    * @dev This function will enlist a data token on the nvg8 marketplace, it's a private function.
    * @param _erc721Token The ERC721 token address.
    * @param _erc20Token The ERC20 token address.
    * @param _owner The owner of the data token.
    * @param _name The name of the data token.
    * @param _symbol The symbol of the data token.
    * @param _usagePrice The usage price of the data token.
    * @param _poolType The pool type of the data token.
    * @return The data token id.
    */
    function enlistDataTokenOnMarketplace(
        address _erc721Token,
        address _erc20Token,
        address _owner,
        string memory _name,
        string memory _symbol,
        uint256 _usagePrice,
        PoolTypes _poolType
    ) private returns (uint256) {
        require(nvg8Marketplace != address(0), "Nvg8 Marketplace is not set");
        // TODO: is valid ERC721 & ERC20 token
        //! Can only be Validated from the web3.js

        uint256 dataTokenId = INVG8Marketplace(nvg8Marketplace).enlistDataToken(
            _erc721Token,
            _erc20Token,
            _owner,
            _name,
            _symbol,
            _usagePrice,
            _poolType
        );
        // require(dataTokenId > 0, "Failed to enlist data token on marketplace");
        return dataTokenId;
    }
}

// Todo: how to manage who can use the token?
// Todo: add tests
// Todo: add documentation

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../utils/Utils.sol";
interface INVG8Marketplace {

    function enlistDataToken(
        address _erc721Token,
        address _erc20Token,
        address _owner,
        string memory _name,
        string memory _symbol,
        uint256 _usagePrice,
        PoolTypes _poolType
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IFixPrice{
    function buyToken(uint256 _dataToken, uint256 _amount, address _owner, address _buyer) external returns (bool _success);
    function addDataToken(address _erc20address, address _erc721Address, uint256 _tokensPerUnit, uint256 _dataTokenId) external;
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