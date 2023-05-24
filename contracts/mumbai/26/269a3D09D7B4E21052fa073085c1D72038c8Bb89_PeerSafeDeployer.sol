// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./utils/Ownable.sol";
import "./Vault.sol";


contract PeerSafeDeployer is Ownable {
    mapping(address => Vault) vaults;
    constructor () Ownable(msg.sender, msg.sender) {}

    function getVault(address _vaultOwner) external view returns(address) {
        Vault _v = vaults[_vaultOwner];
        if (_v.getOwner() == _vaultOwner) {
            return address(_v);
        }
        revert("ERR691: vault doesn't exist");
    }

    function deploy(string memory _userName) external returns(address) {
        Vault _v = new Vault(msg.sender, _userName);
        vaults[msg.sender] = _v;
        return address(_v);
    }

    modifier onlyVaultOwner() {
        Vault _v = vaults[msg.sender];
        require(_v.getOwner() == msg.sender, "ERR692: sender is not vault owner or vault doesn't exist");
        _;
    }

    function createFile(string memory name, string memory fileType, string memory ipfsHash, string memory key) external onlyVaultOwner {
        Vault _v = vaults[msg.sender];
        _v.createFile(name, fileType, ipfsHash, key);
    }

    function getAllFiles() external view returns(File[] memory) {
        Vault _v = vaults[msg.sender];
        if (_v.getOwner() == msg.sender) {
            return _v.getAllFiles();
        }
        revert("ERR691: vault doesn't exist");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;



contract Ownable {
  address internal owner;
  address internal creator;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor (address _creator, address _firstOwner) {
    owner = _firstOwner;
    creator = _creator;
    emit OwnershipTransferred(address(0), _firstOwner);
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Ownable#onlyOwner: SENDER_IS_NOT_OWNER");
    _;
  }

  modifier onlyCreator() {
    require(msg.sender == creator, "Ownable#onlyCreator: SENDER_IS_NOT_CREATOR");
    _;
  }

  modifier onlyOwnerOrCreator() {
    require(msg.sender == owner || msg.sender == creator, "Ownable#onlyOwnerOrCreator: SENDER_IS_NOT_OWNER_OR_CREATOR");
    _;
  }

  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0), "Ownable#transferOwnership: INVALID_ADDRESS");
    owner = _newOwner;
    emit OwnershipTransferred(owner, _newOwner);
  }

  function getOwner() public view returns (address) {
    return owner;
  }

  function getCreator() public view returns (address) {
    return creator;
  }  

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./utils/Ownable.sol";


struct File {
    string _name;
    string _fileType;
    string _ipfsHash;
    string _key;
}

contract Vault is Ownable {
    string user;
    File[] files;
    constructor(address _owner, string memory _userName ) Ownable(msg.sender, _owner) {
        user = _userName;
    }

    function getAllFiles() external view returns(File[] memory) {
        return files;
    }

    function createFile(string memory name, string memory fileType, string memory ipfsHash, string memory key) external onlyOwnerOrCreator {
        File memory f = File(
           {
            _name: name,
            _fileType: fileType,
            _ipfsHash: ipfsHash,
            _key: key
           }
        );
        files.push(f);
    }
}