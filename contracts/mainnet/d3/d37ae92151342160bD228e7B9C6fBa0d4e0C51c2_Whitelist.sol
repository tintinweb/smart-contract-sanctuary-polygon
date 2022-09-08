// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// Import base Initializable contract
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";

contract Whitelist is Initializable {
    bool whitelistEnabled;
    mapping(address => bool) allowedAccounts;
    mapping(bytes32 => bool) allowedKeyHashes;
    address[] allowedAccountsArray;
    address admin;

    // administrative
    modifier onlyAdmin() {
        require(
            msg.sender == admin,
            "Only administrator can perform this action"
        );
        _;
    }

    function changeAdmin(address _newAdmin) public onlyAdmin {
        admin = _newAdmin;
    }

    function initialize(address _admin, bool _whitelistEnabled)
        public
        initializer
    {
        admin = _admin;
        whitelistEnabled = _whitelistEnabled;
    }

    // public getters
    function getNAllowed() public view returns (uint256) {
        return allowedAccountsArray.length;
    }

    function isWhitelisted(address _addr) public view returns (bool) {
        if (!whitelistEnabled) {
            return true;
        }
        return allowedAccounts[_addr];
    }

    function keyHash(string memory key) public view returns (bytes32) {
        return keccak256(abi.encodePacked(key));
    }

    function isKeyValid(string memory key) public view returns (bool) {
        bytes32 hashed = keccak256(abi.encodePacked(key));
        return allowedKeyHashes[hashed];
    }

    // modify whitelist
    function addKeys(bytes32[] memory hashes) public onlyAdmin {
        for (uint16 i = 0; i < hashes.length; i++) {
            allowedKeyHashes[hashes[i]] = true;
        }
    }

    function useKey(string memory key, address owner) public onlyAdmin {
        require(!allowedAccounts[owner], "player already whitelisted");
        bytes32 hashed = keccak256(abi.encodePacked(key));
        require(allowedKeyHashes[hashed], "invalid key");
        allowedAccounts[owner] = true;
        allowedAccountsArray.push(owner);
        allowedKeyHashes[hashed] = false;
    }

    function removeFromWhitelist(address toRemove) public onlyAdmin {
        require(
            allowedAccounts[toRemove],
            "player was not whitelisted to begin with"
        );
        allowedAccounts[toRemove] = false;
        for (uint256 i = 0; i < allowedAccountsArray.length; i++) {
            if (allowedAccountsArray[i] == toRemove) {
                allowedAccountsArray[i] = allowedAccountsArray[allowedAccountsArray
                    .length - 1];
                allowedAccountsArray.pop();
            }
        }
    }
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}