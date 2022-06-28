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
pragma solidity 0.8.15;

import "./interfaces/IRegistryContract.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RegistryContract is Ownable, IRegistryContract {
    address public override getHoldingContract;
    address public override getMetaForceContract;
    address public override getCoreContract;
    address public override getMFS;
    address public override getStableCoin;
    address public override getEnergyCoin;
    address public override getRequestMFSContract;
    address public override getRewardsFund;
    address public override getLiquidityPool;
    address public override getForsageParticipants;
    address public override getMetaDevelopmentAndIncentiveFund;
    address public override getTeamFund;
    address public override getLiquidityListingFund;
    address public override getMetaPool;
    address public override getRequestPool;
    mapping(uint256 => address) public override getHMFS;

    function setHoldingContract(address _holdingContract) external override onlyOwner {
        getHoldingContract = _holdingContract;
    }

    function setMetaForceContract(address _metaForceContract) external override onlyOwner {
        getMetaForceContract = _metaForceContract;
    }

    function setCoreContract(address _coreContract) external override onlyOwner {
        getCoreContract = _coreContract;
    }

    function setMFS(address _mfs) external override onlyOwner {
        getMFS = _mfs;
    }

    function setHMFS(uint256 level, address _hMFS) external override onlyOwner {
        getHMFS[level] = _hMFS;
    }

    function setStableCoin(address _stableCoin) external override onlyOwner {
        getStableCoin = _stableCoin;
    }

    function setEnergyCoin(address _energyCoin) external override onlyOwner {
        getEnergyCoin = _energyCoin;
    }

    function setRequestMFSContract(address _requestMFSContract) external override onlyOwner {
        getRequestMFSContract = _requestMFSContract;
    }

    function setRewardsFund(address _rewardsFund) external override onlyOwner {
        getRewardsFund = _rewardsFund;
    }

    function setLiquidityPool(address _liquidityPool) external override onlyOwner {
        getLiquidityPool = _liquidityPool;
    }

    function setForsageParticipants(address _forsageParticipants) external override onlyOwner {
        getForsageParticipants = _forsageParticipants;
    }

    function setMetaDevelopmentAndIncentiveFund(address _metaDevelopmentAndIncentiveFund) external override onlyOwner {
        getMetaDevelopmentAndIncentiveFund = _metaDevelopmentAndIncentiveFund;
    }

    function setTeamFund(address _teamFund) external override onlyOwner {
        getTeamFund = _teamFund;
    }

    function setLiquidityListingFund(address _liquidityListingFund) external override onlyOwner {
        getLiquidityListingFund = _liquidityListingFund;
    }

    function setMetaPool(address _metaPool) external override onlyOwner {
        getMetaPool = _metaPool;
    }

    function setRequestPool(address _requestPool) external override onlyOwner {
        getRequestPool = _requestPool;
    }
}

// SPDX-License-Identifier:  MIT
pragma solidity 0.8.15;

interface IRegistryContract {
    function setHoldingContract(address _holdingContract) external;

    function setMetaForceContract(address _metaForceContract) external;

    function setCoreContract(address _coreContract) external;

    function setMFS(address _mfs) external;

    function setHMFS(uint256 level, address _hMFS) external;

    function setStableCoin(address _stableCoin) external;

    function setRequestMFSContract(address _requestMFSContract) external;

    function setEnergyCoin(address _energyCoin) external;

    function setRewardsFund(address addresscontract) external;

    function setLiquidityPool(address addresscontract) external;

    function setForsageParticipants(address addresscontract) external;

    function setMetaDevelopmentAndIncentiveFund(address addresscontract) external;

    function setTeamFund(address addresscontract) external;

    function setLiquidityListingFund(address addresscontract) external;

    function setMetaPool(address) external;

    function setRequestPool(address) external;

    function getHoldingContract() external view returns (address);

    function getMetaForceContract() external view returns (address);

    function getCoreContract() external view returns (address);

    function getMFS() external view returns (address);

    function getHMFS(uint256 level) external view returns (address);

    function getStableCoin() external view returns (address);

    function getEnergyCoin() external view returns (address);

    function getRequestMFSContract() external view returns (address);

    function getRewardsFund() external view returns (address);

    function getLiquidityPool() external view returns (address);

    function getForsageParticipants() external view returns (address);

    function getMetaDevelopmentAndIncentiveFund() external view returns (address);

    function getTeamFund() external view returns (address);

    function getLiquidityListingFund() external view returns (address);

    function getMetaPool() external view returns (address);

    function getRequestPool() external view returns (address);
}