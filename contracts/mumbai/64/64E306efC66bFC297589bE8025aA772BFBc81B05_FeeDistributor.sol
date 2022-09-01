// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IFeeDistributor.sol";

contract FeeDistributor is Ownable, IFeeDistributor {

    struct Distribution {
        uint256 percentage; // to 2 decimal places
        address to;
    }

    Distribution[] public defaultFeeDistribution;
    mapping(uint256 => Distribution[]) public planetFeeDistribution;

    event FeeDistributionUpdated(uint256[] percentage, address[] to);

    function updateDefaultFeeDistribution(uint256[] memory _percentage, address[] memory _to) public onlyOwner {
        require(_percentage.length == _to.length, "FeeDistributor: array length not match");
        delete defaultFeeDistribution;
        _updateFeeDistribution(defaultFeeDistribution, _percentage, _to);
    }

    function updatePlanetFeeDistribution(uint256 planetId, uint256[] memory _percentage, address[] memory _to)
        public
        onlyOwner
    {
        require(_percentage.length == _to.length, "FeeDistributor: array length not match");
        delete planetFeeDistribution[planetId];
        _updateFeeDistribution(planetFeeDistribution[planetId], _percentage, _to);
    }

    function getFeeDistribution(uint256 planetId)
        external
        view
        override
        returns (uint256[] memory, address[] memory)
    {
        Distribution[] storage feeDistribution = planetFeeDistribution[planetId];

        if (feeDistribution.length == 0) {
            feeDistribution = defaultFeeDistribution;
        }
        uint256 length = feeDistribution.length;
        uint256[] memory percentages = new uint256[](length);
        address[] memory tos = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            percentages[i] = feeDistribution[i].percentage;
            tos[i] = feeDistribution[i].to;
        }

        return (percentages, tos);
    }

    function _updateFeeDistribution(
        Distribution[] storage distribution, 
        uint256[] memory _percentage,
        address[] memory _to
    ) internal {
        require(_percentage.length == _to.length, "FeeDistributor: array length not match");
        uint256 percentageSum;
        for (uint256 i = 0; i < _percentage.length; i++) {
            Distribution memory newDistribution = Distribution({
                percentage: _percentage[i],
                to: _to[i]
            });
            distribution.push(newDistribution);
        }
        require(percentageSum <= 10000, "FeeDistributor: sum of percentage cannot 10000");
        emit FeeDistributionUpdated(_percentage, _to);
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
pragma solidity ^0.8.4;

interface IFeeDistributor {
    function getFeeDistribution(uint256 planetId)
        external
        view
        returns (uint256[] memory, address[] memory);
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