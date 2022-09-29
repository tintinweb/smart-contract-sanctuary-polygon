// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

//
//   +-+ +-+ +-+   +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+ +-+ +-+
//   |T| |h| |e|   |R| |e| |d|   |V| |i| |l| |l| |a| |g| |e|
//   +-+ +-+ +-+   +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+ +-+ +-+
//
//
//   The Red Village + Pellar 2022
//

contract TRVDeployer is Ownable {
  // 0 -> access control
  // 1 -> ca state
  // 2 -> cf state
  // 3 -> tournament state
  // 4 -> champion utils // new
  // 5 -> blooding service
  // 6 -> bloodbath service
  // 7 -> blood elo service
  // 8 -> solo service
  // 9 -> tournament route
  // 10 -> zoo keeper
  // 11 -> summoning state
  mapping(uint256 => address) public elements;

  // 0xAC5281BC8Ec677C6cC0E8A4889BF8Eb99D01D125 deployed deployer

  constructor() {
    // replace deployed contract here.
    elements[0] = 0x0bF8b07D3A0C83C5DDe4e12143A4203897f55F90;

    elements[1] = 0x5A06c52A8B4eF58173A91A8fFE342A09AaF4Fc9D;
    elements[2] = 0xCF25D328550Bd4e2A214e57331b04d80F0C088Ca;
    elements[3] = 0x913B34CB9597f899EEE159a0b5564e4cC2958330;

    elements[4] = 0xC26056434F8aE5E95Ef65c8791E8C100962e4817; // new
    elements[5] = 0x86Bc7B6993Cd70ce1F3E9454eC036bb72C517ad5;
    elements[6] = 0xb9c8ba130fEe062ee9d07567Cc7247497F7e60bD;
    elements[7] = 0x954895DdC8BBCE3805F837d7d12AF83913eF0D1C;
    elements[8] = 0xA6DDBAf74eDd8A2A1A38f743dAEC6Ebe71499531;

    elements[9] = 0x570F2d96a114F272Fc461440B4C3b08dC7007F5E;

    elements[10] = 0x50509eCacA1665129280B5eaBFd5E93a8e5F58de;

    // summoning
    elements[11] = 0x73fb5053685FCCB63E9d7B1557c8efB9D7F0Bde0;
  }

  function setContracts(uint256[] memory _ids, address[] memory _contracts) external onlyOwner {
    require(_ids.length == _contracts.length, "Input mismatch");

    for (uint256 i = 0; i < _ids.length; i++) {
      elements[_ids[i]] = _contracts[i];
    }
  }

  function setupRouterRolesForAdmin(address[] memory _contracts) external onlyOwner {
    for (uint256 i = 0; i < _contracts.length; i++) {
      IAll(elements[0]).grantMaster(_contracts[i], elements[9]);
    }
  }

  function init() external onlyOwner {
    IAll(elements[0]).grantMaster(address(this), elements[1]);
    IAll(elements[0]).grantMaster(address(this), elements[2]);
    IAll(elements[0]).grantMaster(address(this), elements[3]);

    IAll(elements[0]).grantMaster(address(this), elements[4]);
    IAll(elements[0]).grantMaster(address(this), elements[5]);
    IAll(elements[0]).grantMaster(address(this), elements[6]);
    IAll(elements[0]).grantMaster(address(this), elements[7]);
    IAll(elements[0]).grantMaster(address(this), elements[8]);

    IAll(elements[0]).grantMaster(address(this), elements[9]);
    IAll(elements[0]).grantMaster(address(this), elements[10]);
  }

  function setup() external onlyOwner {
    IAll(elements[0]).setAccessControlProvider(elements[0]);
    IAll(elements[1]).setAccessControlProvider(elements[0]);
    IAll(elements[2]).setAccessControlProvider(elements[0]);
    IAll(elements[3]).setAccessControlProvider(elements[0]);
    IAll(elements[4]).setAccessControlProvider(elements[0]);
    IAll(elements[5]).setAccessControlProvider(elements[0]);
    IAll(elements[6]).setAccessControlProvider(elements[0]);
    IAll(elements[7]).setAccessControlProvider(elements[0]);
    IAll(elements[8]).setAccessControlProvider(elements[0]);
    IAll(elements[9]).setAccessControlProvider(elements[0]);
    IAll(elements[10]).setAccessControlProvider(elements[0]);
  }

  function bindingService() external onlyOwner {
    bindingRoleForService(elements[5]);
    bindingRoleForService(elements[6]);
    bindingRoleForService(elements[7]);
    bindingRoleForService(elements[8]);

    IAll(elements[5]).bindSummoningState(elements[11]);
    IAll(elements[6]).bindSummoningState(elements[11]);
    IAll(elements[7]).bindSummoningState(elements[11]);
  }

  function bindingRoleForService(address _service) internal {
    IAll(elements[0]).grantMaster(_service, elements[1]);
    IAll(elements[0]).grantMaster(_service, elements[2]);
    IAll(elements[0]).grantMaster(_service, elements[3]);
    IAll(elements[0]).grantMaster(_service, elements[10]);
    IAll(elements[0]).grantMaster(_service, elements[11]);

    IAll(_service).bindChampionAttributesState(elements[1]);
    IAll(_service).bindChampionFightingState(elements[2]);
    IAll(_service).bindTournamentState(elements[3]);
    IAll(_service).bindChampionUtils(elements[4]);
    IAll(_service).bindZooKeeper(elements[10]);
  }

  function bindingRoleForRoute() external onlyOwner {
    IAll(elements[0]).grantMaster(elements[9], elements[5]);
    IAll(elements[0]).grantMaster(elements[9], elements[6]);
    IAll(elements[0]).grantMaster(elements[9], elements[7]);
    IAll(elements[0]).grantMaster(elements[9], elements[8]);
  }

  function bindingServiceForRoute() external onlyOwner {
    IAll(elements[9]).updateService(0, elements[8]);
    IAll(elements[9]).updateService(1, elements[5]);
    IAll(elements[9]).updateService(2, elements[6]);
    IAll(elements[9]).updateService(3, elements[7]);
  }
}

interface IAll {
  function setAccessControlProvider(address) external;

  function grantMaster(address, address) external;

  function bindChampionAttributesState(address) external;

  function bindChampionFightingState(address) external;

  function bindTournamentState(address) external;

  function bindChampionUtils(address) external;

  function bindSummoningState(address) external;

  function bindZooKeeper(address) external;

  function updateService(uint64, address) external;
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