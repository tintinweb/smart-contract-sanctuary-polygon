/**
 *Submitted for verification at polygonscan.com on 2022-05-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor ()  { }

  function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor ()  {
    address payable msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract DomainVerify is Ownable {
    struct DomainInfo {
        address owner;

        string websiteName;
        string phoneNumber;
        string emailAddress;
        string webCategory;
        string ownerName;

        uint256 verifiedTime;
        uint256 validTill;
    }

    constructor() {

    }

    mapping(string => DomainInfo) public domain;

    string[] public verifiedDomainsList;

    uint256 public verificationFee = 0.001 * 10 ** 18;

    function storeDomain(
        string memory _rootDomain,

        string memory _websiteName,
        string memory _phoneNumber,
        string memory _emailAddress,
        string memory _webCategory,
        string memory _ownerName
    ) public payable {
        require(
            domain[_rootDomain].verifiedTime == 0
            || block.timestamp > domain[_rootDomain].validTill,
            "This domain is currently verified!"
        );

        require(msg.value >= verificationFee, "Not enough value sent with the transaction!");

        domain[_rootDomain].owner = msg.sender;

        domain[_rootDomain].websiteName = _websiteName;
        domain[_rootDomain].phoneNumber = _phoneNumber;
        domain[_rootDomain].emailAddress = _emailAddress;
        domain[_rootDomain].webCategory = _webCategory;
        domain[_rootDomain].ownerName = _ownerName;

        domain[_rootDomain].verifiedTime = block.timestamp;
        domain[_rootDomain].validTill = block.timestamp + 365 days;

        payable(owner()).transfer(msg.value);

        verifiedDomainsList.push(_rootDomain);

        emit DomainStored(msg.sender, _rootDomain);
    }

    function changeVerificationFee(uint256 _newFee) public onlyOwner {
        verificationFee = _newFee;
        emit FeesChanged(msg.sender, _newFee);
    }

    event DomainStored(address domainOwner, string rootDomain);
    event FeesChanged(address owner, uint256 newFee);
}