// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract SummoningDeployer is Ownable {
  // 0 -> access control
  // 1 -> ca state
  // 2 -> erc721 summoning champion // new
  // 3 -> summoning state // new
  // 4 -> champion utils // new
  // 5 -> summoning service // new
  // 6 -> summoning route // new
  // 7 -> zoo keeper
  mapping(uint256 => address) public elements;

  constructor() {
    // replace deployed contract here.
    elements[0] = 0x3f0B50B7A270de536D5De35C11C2613284C4304e;

    elements[1] = 0x54a5Bd715f60931627B8d67C4B7b82758F3B8a16;
    elements[2] = 0x258d199Af50187CbE1e12bd10C6269aB82b98730; // new
    elements[3] = 0x20A1eD3F23bC35c8c607F10EE367BeD4C9c68d89; // new

    elements[4] = 0xf793365C80D189de5751d6323cE646f210e4692A;
    elements[5] = 0x160b5F308c7DDBF345b13F2ec04E3fFda812ee69; // new
    elements[6] = 0x509f0dCFbd49BAcA2ddE4C83E452C42261be87f2; // new
    elements[7] = 0x426d27190A2DdB87f1C6235F710e159a0A3774D4;
  }

  function setContracts(uint256[] memory _ids, address[] memory _contracts) external onlyOwner {
    require(_ids.length == _contracts.length, "Input mismatch");

    for (uint256 i = 0; i < _ids.length; i++) {
      elements[_ids[i]] = _contracts[i];
    }
  }

  function setupRouterRolesForAdmin(address[] memory _contracts) external onlyOwner {
    for (uint256 i = 0; i < _contracts.length; i++) {
      IAll(elements[0]).grantMaster(_contracts[i], elements[6]);
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
  }

  function bindingService() external onlyOwner {
    IAll(elements[0]).grantMaster(elements[5], elements[1]);
    IAll(elements[0]).grantMaster(elements[5], elements[2]);
    IAll(elements[0]).grantMaster(elements[5], elements[3]);
    IAll(elements[0]).grantMaster(elements[5], elements[7]);

    IAll(elements[5]).bindChampionAttributesState(elements[1]);
    IAll(elements[5]).bindSummoningChampionContract(elements[2]);
    IAll(elements[5]).bindSummoningState(elements[3]);
    IAll(elements[5]).bindChampionUtils(elements[4]);
    IAll(elements[5]).bindZooKeeper(elements[7]);
  }

  function bindingServiceForRoute() external onlyOwner {
    IAll(elements[0]).grantMaster(elements[6], elements[5]);
    IAll(elements[6]).bindService(elements[5]);
  }
}

interface IAll {
  function setAccessControlProvider(address) external;

  function grantMaster(address, address) external;

  function bindChampionAttributesState(address) external;

  function bindSummoningChampionContract(address) external;

  function bindSummoningState(address) external;

  function bindChampionUtils(address) external;

  function bindZooKeeper(address) external;

  function bindService(address) external;
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