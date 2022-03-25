// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRegistry.sol";

/// @title Registry for an NFT matketplace
/// @author Linum Labs
contract Registry is IRegistry, Ownable {
    mapping(address => bool) private platformContracts;
    mapping(address => bool) private approvedCurrencies;
    bool allowAllCurrencies;
    address systemWallet;
    // scale: how many zeroes should follow the fee
    // in the default values, there would be a 3% tax on a 18 decimal asset
    uint256 fee = 300;
    uint256 scale = 1e4;

    constructor() {
        approvedCurrencies[address(0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa)] = true;
    }

    /// @notice Returns if a contract is recognized by the registry
    /// @dev no validation is done to verify a contract exists at the address
    /// @param toCheck the address of the contract to check
    /// @return bool if the contract is approved by the registry
    function isPlatformContract(address toCheck) external view override returns (bool) {
        return platformContracts[toCheck];
    }

    /// @notice Returns if a token is approved for use on the platform
    /// @dev no validation is done to verify a token contract exists at the address
    /// @dev use address(0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa) for ETH
    /// @param tokenContract the address of the token to check
    /// @return bool if the token is approved for use on the platform
    function isApprovedCurrency(address tokenContract) external view override returns (bool) {
        if (allowAllCurrencies) return true;
        return approvedCurrencies[tokenContract];
    }

    /// @notice Given a sum, returns the address of the platforms's wallet and fees due
    /// @dev structured similar to ERC2981
    /// @param _salePrice the uint256 amount being paid
    /// @return the address of the sustem wallet and the uint256 amount of fees to pay
    function feeInfo(uint256 _salePrice) external view override returns (address, uint256) {
        return (systemWallet, ((_salePrice * fee) / scale));
    }

    /// @notice Sets the address of the platform's wallet (for fees)
    /// @param newWallet the address of the new platform wallet
    function setSystemWallet(address newWallet) external override onlyOwner {
        systemWallet = newWallet;

        emit SystemWalletUpdated(newWallet);
    }

    /// @notice Sets the fee and scaling factor
    /// @dev for example, a fee of 500 with a scale of 10,000 would be 5%
    /// @param newFee the adjusted percentage to take as fees
    /// @param newScale the scale the fee is adjusted by
    function setFeeVariables(uint256 newFee, uint256 newScale) external override onlyOwner {
        fee = newFee;
        scale = newScale;
        emit FeeVariablesChanged(newFee, newScale);
    }

    /// @notice Sets the status of a particular contract
    /// @dev deprecated contracts should be set to false
    /// @param toChange the address of the contract to set
    /// @param status the bool status to set the contract to
    function setContractStatus(address toChange, bool status) external override onlyOwner {
        string memory boolString = status == true ? "true" : "false";
        require(
            platformContracts[toChange] != status,
            string(abi.encodePacked("contract status is already ", boolString))
        );
        platformContracts[toChange] = status;
        emit ContractStatusChanged(toChange, status);
    }

    /// @notice Sets the status of a particular token
    /// @param tokenContract the address of the token
    /// @param status the bool status to set the token to
    function setCurrencyStatus(address tokenContract, bool status) external override onlyOwner {
        require(!allowAllCurrencies, "all currencies approved");
        string memory boolString = status == true ? "true" : "false";
        require(
            approvedCurrencies[tokenContract] != status,
            string(abi.encodePacked("token status is already ", boolString))
        );
        approvedCurrencies[tokenContract] = status;
        emit CurrencyStatusChanged(tokenContract, status);
    }

    /// @notice Allows all token to be used in the platform
    /// @dev this is an irreversible function
    function approveAllCurrencies() external override onlyOwner {
        require(!allowAllCurrencies, "already approved");
        allowAllCurrencies = true;
        emit CurrencyStatusChanged(address(0), true);
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
pragma solidity 0.8.10;

interface IRegistry {
    event SystemWalletUpdated(address newWallet);
    event FeeVariablesChanged(uint256 indexed newFee, uint256 indexed newScale);
    event ContractStatusChanged(address indexed changed, bool indexed status);
    event CurrencyStatusChanged(address indexed changed, bool indexed status);

    function feeInfo(uint256 _salePrice) external view returns (address, uint256);

    function isPlatformContract(address toCheck) external view returns (bool);

    function isApprovedCurrency(address tokenContract) external view returns (bool);

    function setSystemWallet(address newWallet) external;

    function setFeeVariables(uint256 newFee, uint256 newScale) external;

    function setContractStatus(address toChange, bool status) external;

    function setCurrencyStatus(address tokenContract, bool status) external;

    function approveAllCurrencies() external;
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