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

contract TournamentDeployer is Ownable {
  // 0 -> access control
  // 1 -> champion utils // new
  // 2 -> zoo keeper
  // 3 -> tournament state
  // 4 -> tournament service // new
  // 5 -> solo service
  // 6 -> tournament route
  mapping(uint256 => address) public elements;

  constructor() {
    // replace deployed contract here.
    elements[0] = 0x3f0B50B7A270de536D5De35C11C2613284C4304e;
    elements[1] = 0xcF1552c0627C68F6AeD99911baa2529C6c1C289D;
    elements[2] = 0x426d27190A2DdB87f1C6235F710e159a0A3774D4;
    elements[3] = 0x7EE7072df1BBD168bc6E3c17Ac854Da012b0B147;
    elements[4] = 0xeF167e97A5D87dE766f6a70eb23afbe7F3Fd9b09;
    elements[5] = 0x5Db1786A89ef2462faB97d524DE0f817fd004BDF;
    elements[6] = 0x4C6cAe14066066f169baf7969d9F20E3471C8e29;
  }

  function setContracts(uint256[] memory _ids, address[] memory _contracts) public onlyOwner {
    require(_ids.length == _contracts.length, "Input mismatch");

    for (uint256 i = 0; i < _ids.length; i++) {
      elements[_ids[i]] = _contracts[i];
    }
  }

  function binding() public onlyOwner {
    init();
    setup();
    bindingService();
    bindingRoleForRoute();
    bindingServiceForRoute();
    address[10] memory admins = [
      0x695CCd47Ce61d8aF99134A8B983b58769BcFa39f, //
      0x0e8d0a6598272F8A626De1cA9677aB6C443f7858,
      0x6B011DCb5e1C8b362cdfE4B4e16EE0ed460bb57a,
      0x9c17F3ce22BB702A22f919C1972122f6F3865A1F,
      0x3bA6c4751E9FD5acd7709B1d8867eE78E1036454,
      0x247b014A802E0393879F89D37dcC9575F30D60EA,
      0x5a710FbA9E02c7a422904699B1D664D329572712,
      0x13df66fA5A8f9FF22d1625D3A808C5d47020788c,
      0x88c7a88CD0f009d68d831d74e604cC394E3C4b70,
      0x439bAdED9eb99fd64307dFd6666009C56CFe3d5D
    ];
    for (uint256 i = 0; i < admins.length; i++) {
      IAll(elements[0]).grantMaster(admins[i], elements[6]);
    }
  }

  function setupRouterRolesForAdmin(address[] memory _contracts) public onlyOwner {
    for (uint256 i = 0; i < _contracts.length; i++) {
      IAll(elements[0]).grantMaster(_contracts[i], elements[6]);
    }
  }

  function init() public onlyOwner {
    IAll(elements[0]).grantMaster(address(this), elements[1]);
    IAll(elements[0]).grantMaster(address(this), elements[2]);
    IAll(elements[0]).grantMaster(address(this), elements[3]);
    IAll(elements[0]).grantMaster(address(this), elements[4]);
    IAll(elements[0]).grantMaster(address(this), elements[5]);
    IAll(elements[0]).grantMaster(address(this), elements[6]);
  }

  function setup() public onlyOwner {
    IAll(elements[0]).setAccessControlProvider(elements[0]);
    IAll(elements[1]).setAccessControlProvider(elements[0]);
    IAll(elements[2]).setAccessControlProvider(elements[0]);
    IAll(elements[3]).setAccessControlProvider(elements[0]);
    IAll(elements[4]).setAccessControlProvider(elements[0]);
    IAll(elements[5]).setAccessControlProvider(elements[0]);
    IAll(elements[6]).setAccessControlProvider(elements[0]);
  }

  function bindingService() public onlyOwner {
    bindingRoleForService(elements[4]);
    bindingRoleForService(elements[5]);
  }

  function bindingRoleForService(address _service) internal {
    IAll(elements[0]).grantMaster(_service, elements[1]);
    IAll(elements[0]).grantMaster(_service, elements[2]);
    IAll(elements[0]).grantMaster(_service, elements[3]);

    IAll(_service).bindChampionUtils(elements[1]);
    IAll(_service).bindZooKeeper(elements[2]);
    IAll(_service).bindTournamentState(elements[3]);
  }

  function bindingRoleForRoute() public onlyOwner {
    IAll(elements[0]).grantMaster(elements[6], elements[4]);
    IAll(elements[0]).grantMaster(elements[6], elements[5]);
  }

  function bindingServiceForRoute() public onlyOwner {
    IAll(elements[6]).bindService(0, elements[5]);
    IAll(elements[6]).bindService(1, elements[4]);
    IAll(elements[6]).bindService(2, elements[4]);
    IAll(elements[6]).bindService(3, elements[4]);
  }
}

interface IAll {
  function setAccessControlProvider(address) external;

  function grantMaster(address, address) external;

  function bindTournamentState(address) external;

  function bindChampionUtils(address) external;

  function bindZooKeeper(address) external;

  function bindService(uint64, address) external;
}