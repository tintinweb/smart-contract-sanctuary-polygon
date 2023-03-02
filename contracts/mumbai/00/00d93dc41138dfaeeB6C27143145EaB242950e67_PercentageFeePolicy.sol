// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IFeePolicy.sol";

/// @notice Fee policy with specific percentage fee without other restrictions.
/// @dev In order to perform correct percentage calculations - this contract needs percentage precision.
contract PercentageFeePolicy is IFeePolicy, Ownable {
    /// @notice Precision needed for correct math calculations.
    uint256 public precision;

    /// @notice The percentage fee of the policy
    uint256 public feePercentage;

    /// @param _precision Precision value to be set.
    /// @param _feePercentage Percentage fee value to be set.
    constructor(uint256 _precision, uint256 _feePercentage) {
        require(_precision > 0, "Value of _precision is zero");
        require(_feePercentage > 0, "Value of _feePercentage is zero");

        precision = _precision;
        feePercentage = _feePercentage;
    }

    /// @notice Sets current precision value.
    /// @param _precision Precision value to be changed.
    function setPrecision(uint256 _precision) external onlyOwner {
        require(_precision > 0, "Value of _precision is zero");

        precision = _precision;
    }

    /// @notice Sets current percentage fee value.
    /// @param _feePercentage Percentage fee value to be changed.
    function setFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage > 0, "Value of _feePercentage is zero");

        feePercentage = _feePercentage;
    }

    /// @notice Calculates the fee amount.
    /// @dev This method is implementation of IFeePolicy.feeAmountFor(uint256,address,address,uint256).
    /// @param _amount The amount to which the service fee will be calculated.
    /// @return feeAmount Calculated value of the fee.
    /// @return exist Flag describing if fee amount is calculated. For the current implementation - it is always true.
    function feeAmountFor(
        uint256,
        address,
        address,
        uint256 _amount
    ) external view override returns (uint256 feeAmount, bool exist) {
        return ((_amount * feePercentage) / precision, true);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/// @notice Interface describing specific fee policy. 
/// @dev The actual contracts implementing this interface may vary by storage structure.
interface IFeePolicy {
    /// @notice Calculates fee amount for given combination of parameters.
    /// @dev Actual implementation may not require all parameters.
    /// @param _targetChain If used - represents a chain ID.
    /// @param _userAddress If used - represents user address.
    /// @param _tokenAddress If used - represents token address.
    /// @param _amount If used - transaction amount subject to the fee.
    /// @return feeAmount value of the fee.
    /// @return exist Flag describing if a fee policy for the given parameters is found and calculated.
    function feeAmountFor(
        uint256 _targetChain,
        address _userAddress,
        address _tokenAddress,
        uint256 _amount
    ) external view returns (uint256 feeAmount, bool exist);
}

// SPDX-License-Identifier: MIT

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