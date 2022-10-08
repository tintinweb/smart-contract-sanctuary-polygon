// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {Errors} from "./libraries/Errors.sol";
import {Enums} from "./libraries/Enums.sol";

import "./interfaces/IERC721A.sol";
import "./interfaces/IERC1155.sol";
import "./interfaces/IWizardStorage.sol";

/// @title Wizard Factory
/// @notice Factory that creates contracts
contract WizardFactory is Ownable, ReentrancyGuard {
    /// @notice Emitted on ERC Contracts create
    /// @param contractAddress Address of deployed Contract
    /// @param name Contract name
    /// @param symbol Contract symbol
    /// @param standard Contract standard
    /// @param tier Contract standard tier
    /// @param owner Contract owner
    event ContractCreated(
        address indexed contractAddress,
        string name,
        string symbol,
        Enums.Standard standard,
        Enums.Tier tier,
        address indexed owner
    );

    /// @notice AggregatorV3Interface priceFeed address
    AggregatorV3Interface public priceFeed;

    /// @notice Storage Implementation
    address public storageImplementation;

    /// @notice standard: ERC721A => tier: Basic => implementation address
    mapping(Enums.Standard => mapping (Enums.Tier => address)) public contractImplementation;

    /// @notice tier => cost in wei as usd
    mapping(Enums.Tier => int) public cost;

    /// @notice Constructor
    /// @param _basicTierCost Basic tier cost
    /// @param _premiumTierCost Premium tier cost
    /// @param _advancedTierCost Advanced tier cost
    /// @param _priceFeed AggregatorV3Interface priceFeed address
    constructor(
        int _basicTierCost,
        int _premiumTierCost,
        int _advancedTierCost,
        address _priceFeed
    ) {
        cost[Enums.Tier.Basic] = _basicTierCost;
        cost[Enums.Tier.Premium] = _premiumTierCost;
        cost[Enums.Tier.Advanced] = _advancedTierCost;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    modifier createCompliance(Enums.Standard _standard, Enums.Tier _tier) {
        if (msg.value < getCost(_tier)) {
            revert Errors.InsufficientFunds();
        }
        if (contractImplementation[_standard][_tier] == address(0)) {
            revert Errors.InvalidContractImplementation(_standard, _tier);
        }
        _;
    }

    /// @notice Function for creating ERC721A contracts
    /// @param _name Contract name
    /// @param _symbol Contract symbol
    /// @param _cost Mint cost
    /// @param _maxSupply Contract maxSupply
    /// @param _maxMintAmountPerTx Max mint amount per transaction
    /// @param _hiddenMetadataUri Hidden metadata uri
    /// @param _uriPrefix Metadata uri prefix
    /// @param _royaltyReceiver Royalty fee collector
    /// @param _feePercent Royalty fee numerator; denominator is 10,000. So 500 represents 5%
    /// @param _tier Contract standard tier
    function createERC721AContract(
        string memory _name,
        string memory _symbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxMintAmountPerTx,
        string memory _hiddenMetadataUri,
        string memory _uriPrefix,
        address _royaltyReceiver,
        uint96 _feePercent,
        Enums.Tier _tier
    ) public payable createCompliance(Enums.Standard.ERC721A, _tier) {
        address createdContract = Clones.clone(
            contractImplementation[Enums.Standard.ERC721A][_tier]
        );

        IERC721A(createdContract).initialize(
            _name,
            _symbol,
            _cost,
            _maxSupply,
            _maxMintAmountPerTx,
            _hiddenMetadataUri,
            _uriPrefix,
            _royaltyReceiver,
            _feePercent,
            msg.sender
        );

        IWizardStorage(storageImplementation).storeCreatedContract(
            msg.sender,
            Enums.Standard.ERC721A,
            _tier,
            createdContract
        );

        emit ContractCreated(
            createdContract,
            _name,
            _symbol,
            Enums.Standard.ERC1155,
            _tier,
            msg.sender
        );
    }

    /// @notice Function for creating ERC1155 contracts
    /// @param _name Contract name
    /// @param _symbol Contract symbol
    /// @param _id Token id
    /// @param _amount Token supply
    /// @param _uri Token uri
    /// @param _royaltyReceiver Royalty fee collector
    /// @param _feePercent Royalty fee numerator; denominator is 10,000. So 500 represents 5%
    /// @param _tier Contract standard tier
    function createERC1155Contract(
        string memory _name,
        string memory _symbol,
        uint256 _id,
        uint256 _amount,
        string memory _uri,
        address _royaltyReceiver,
        uint96 _feePercent,
        Enums.Tier _tier
    ) public payable createCompliance(Enums.Standard.ERC1155, _tier) {
        address createdContract = Clones.clone(
            contractImplementation[Enums.Standard.ERC1155][_tier]
        );

        IERC1155(createdContract).initialize(
            _name,
            _symbol,
            _id,
            _amount,
            _uri,
            _royaltyReceiver,
            _feePercent,
            msg.sender
        );

        IWizardStorage(storageImplementation).storeCreatedContract(
            msg.sender,
            Enums.Standard.ERC1155,
            _tier,
            createdContract
        );

        emit ContractCreated(
            createdContract,
            _name,
            _symbol,
            Enums.Standard.ERC1155,
            _tier,
            msg.sender
        );
    }

    /// @notice Set address for storageImplementation
    /// @param _storageImplementation New storageImplementation
    function setStorageImplementation(
        address _storageImplementation
    )
        external
        onlyOwner
    {
        if (_storageImplementation == address(0)) {
            revert Errors.InvalidStorageImplementation();
        }

        storageImplementation = _storageImplementation;
    }

    /// @notice Set address for WizardStorageImplementation
    /// @param _contractImplementation New contractImplementation
    function setContractImplementation(
        Enums.Standard _standard,
        Enums.Tier _tier,
        address _contractImplementation
    )
        external
        onlyOwner
    {
        if (_contractImplementation == address(0)) {
            revert Errors.InvalidContractImplementation(_standard, _tier);
        }

        contractImplementation[_standard][_tier] = _contractImplementation;
    }

    /// @notice Set address for AggregatorV3Interface
    /// @param _priceFeedAddress PriceFeed address
    function setPriceFeed(address _priceFeedAddress) public onlyOwner {
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    /// @notice Set contract basic deployment cost
    /// @param _cost Cost in wei (18 dec) as usd
    function setCost(Enums.Tier _tier, int _cost) public onlyOwner {
        cost[_tier] = _cost;
    }

    /// @notice Function to get latest network native token price
    /// @return int256 Equation of price * 1e10
    function getLatestPrice() public view returns (int) {
        (/*uint80 roundID*/,int price,/*uint startedAt*/,/*uint timeStamp*/,/*uint80 answeredInRound*/) = priceFeed.latestRoundData();
        return price * 1e10;
    }

    /// @notice Function to get contract deployment cost
    /// @return uint256 Cost price for contract deployment
    function getCost(Enums.Tier _tier) public view returns (uint) {
        int tokenAmount = (cost[_tier] * 1e18) / getLatestPrice();
        return uint(tokenAmount);
    }

    /// @notice Function to withdraw contract funds
    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library Enums {
  /// @notice Contract standard
    enum Standard { 
      ERC721A,
      ERC1155
    }

    /// @notice Contract standard tier
    enum Tier { 
      Basic,
      Premium,
      Advanced
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/// @title ERC721A
/// @notice Defines the interface of ERC721A
interface IERC721A {
  function initialize(
    string memory _name,
    string memory _symbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri,
    string memory _uriPrefix,
    address _royaltyReceiver,
    uint96 _feePercent,
    address _owner
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {Enums} from "../libraries/Enums.sol";

library Errors {
    /// Insufficient funds!
    error InsufficientFunds();

    /// Invalid Storage Implementation!
    error InvalidStorageImplementation();

    /// Invalid ERC Implementation!
    error InvalidContractImplementation(Enums.Standard _standard, Enums.Tier _tier);

    /// Invalid mint amount!
    error InvalidMintAmount();

    /// Max supply exceeded!
    error MaxSupplyExceeded();

    /// The whitelist sale is not enabled!
    error TheWhitelistSaleIsNotEnabled();

    /// Address already claimed!
    error AddressAlreadyClaimed();

    /// Invalid proof!
    error InvalidProof();

    /// The contract is paused!
    error TheContractIsPaused();

    /// URI query for nonexistent token!
    error ERC721__URIQueryForNonexistentToken();

    /// Caller is not the factory!
    error CallerIsNotTheFactory();
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {Enums} from "../libraries/Enums.sol";

/// @title IWizardStorage
/// @notice Defines the interface of WizardStorage
interface IWizardStorage {
  function storeCreatedContract(
    address _deployer,
    Enums.Standard _standard,
    Enums.Tier _tier,
    address _address
  ) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/// @title ERC1155
/// @notice Defines the interface of ERC1155
interface IERC1155 {
  function initialize(
    string memory _name,
    string memory _symbol,
    uint256 _id,
    uint256 _amount,
    string memory _uri,
    address _royaltyReceiver,
    uint96 _feePercent,
    address _owner
  ) external;
}

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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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