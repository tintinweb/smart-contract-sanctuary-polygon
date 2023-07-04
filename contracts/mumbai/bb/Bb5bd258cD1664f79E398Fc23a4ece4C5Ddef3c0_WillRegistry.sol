// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";


contract WillRegistry {
  struct Testament {
    address testator;
    uint256 lastTimeSendProofOfLife;
    bool isActivated;
    uint256 money;
  }

  /*================= STAGE =====================*/
  address[] willAddresses;
  mapping(address => Testament) public registry;

  /* ================ CONSTANT ================= */
  string private constant SEND_POOF_OF_LIFE_REQUEST =
  "sendProofOfLifeRequest()";
  string private constant UPDATE_REGISTRY_STATUS = "setRegistrationStatus(bool)";

  /*================= EVENT =====================*/
  event RegisterSuccess(address indexed willAdrress, uint256 registionTime);
  event UpdatedSuccess(address indexed willAdrress, uint256 timestamp);

  /* ================ ERROR ===================== */
  error WillAddressNotFound(address _address);
  error RegistryNotFound(address _address);
  error CallSendMoneyToAddressFailed(address _address);
  error CallUpdateRegisteredStatusFailed(address _address);
  error OnlyWillContractCanUpdate(address _address);

  /*================= MODIFIER =====================*/
  modifier onlyRegistered(address _willAddress) {
    require(
      registry[_willAddress].lastTimeSendProofOfLife != 0,
      "Address not registered yet."
    );
    _;
  }

  modifier onlyNotRegisteredYet(address _willAddress) {
    require(
      registry[_willAddress].lastTimeSendProofOfLife == 0,
      "Address already registered."
    );
    _;
  }

  modifier onlyNotActivatedYet(address _willAddress) {
    require(
      !registry[_willAddress].isActivated,
      "Will is already activated, it cannot be updated."
    );
    _;
  }

  /*================= FUNCTIONS =====================*/

  function register(
    address _willAddress,
    uint256 _lastTimeSendProofOfLife
  ) public payable onlyNotRegisteredYet(_willAddress) {
    require(_willAddress != address(0), "Invalid address provided.");
    require(
      registry[_willAddress].testator == address(0),
      'Address already registered.'
    );
    require(msg.value > 0, "Registration requires a non-zero payment.");

    registry[_willAddress] = Testament({
      testator: msg.sender,
      lastTimeSendProofOfLife: _lastTimeSendProofOfLife,
      isActivated: false,
      money: msg.value
    });
    willAddresses.push(_willAddress);

    (bool success,) = _willAddress.call(
      abi.encodeWithSignature(UPDATE_REGISTRY_STATUS, true)
    );
    if (!success) {
      revert CallUpdateRegisteredStatusFailed(_willAddress);
    }

    emit RegisterSuccess(_willAddress, block.timestamp);
  }

  function updateActivated(
    address _willAddress,
    bool _isActivated
  )
  public
  payable
  onlyRegistered(_willAddress)
  onlyNotActivatedYet(_willAddress)
  {

    uint256 index = findIndexOfWillAddress(_willAddress);
    if (msg.sender != willAddresses[index]) {
      revert OnlyWillContractCanUpdate(_willAddress);
    }

    if (registry[_willAddress].isActivated != _isActivated) {
      registry[_willAddress].isActivated = _isActivated;
    }

    emit UpdatedSuccess(_willAddress, block.timestamp);
  }

  function removeWill(address _willAddress)
  public
  onlyRegistered(_willAddress)
  onlyNotActivatedYet(_willAddress)
  {

    uint lastContractIndex = willAddresses.length - 1;
    uint indexOfWillAddr = findIndexOfWillAddress(_willAddress);
    if (indexOfWillAddr < lastContractIndex) {
      willAddresses[indexOfWillAddr] = willAddresses[lastContractIndex];
    }

    // remove contract will in mapping.
    Testament memory testamentRemoved = registry[_willAddress];
    if (testamentRemoved.testator == address(0)) {
      revert RegistryNotFound(_willAddress);
    }
    if (testamentRemoved.money > 0) {
      (bool sentStatus,) = payable(testamentRemoved.testator).call{
          value: testamentRemoved.money
        }('');
      if (!sentStatus) {
        revert CallSendMoneyToAddressFailed(testamentRemoved.testator);
      }
    }
    delete registry[_willAddress];

    willAddresses.pop();
  }

  function getRegisteredWills() public view returns (address[] memory) {
    return willAddresses;
  }

  //   TODO: calculate price automation
  //   Function for chainlink automation
  function checkForExpiredWills() public {
    // uint256 startGas = gasleft();
    uint256 contractAddressesSize = willAddresses.length;

    address willAddress;
    for (uint256 i = 0; i < contractAddressesSize; i++) {
      willAddress = willAddresses[i];
      if (isEnoughMoney(willAddress) && checkExpired(willAddress)) {
        (bool success,) = willAddress.call(
          abi.encodeWithSignature(SEND_POOF_OF_LIFE_REQUEST)
        );

      }
    }

    // uint256 endGas = gasleft();
  }

  function checkExpired(address _willAddress) internal view returns (bool) {
    // Assuming that a will is considered expired if there hasn't been a proof of life for more than a year
    uint256 SECONDS_IN_A_YEAR = 31536000;
    Testament memory will = registry[_willAddress];
    if (
      !will.isActivated &&
    will.lastTimeSendProofOfLife + SECONDS_IN_A_YEAR < block.timestamp
    ) {
      return true;
    }
    return false;
  }


  function findIndexOfWillAddress(address _willAddress) private view returns (uint) {
    for (uint index = 0; index < willAddresses.length; index ++) {
      if (willAddresses[index] == _willAddress) {
        return index;
      }
    }
    revert WillAddressNotFound(_willAddress);
  }

  function isEnoughMoney(address _willAddress) private view returns (bool) {
    if (registry[_willAddress].money > 0) {
      return true;
    }
    return false;
  }
}