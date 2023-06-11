// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./utils/Ownable.sol";
import "./Vault.sol";
import "./utils/SigUtils.sol";

contract PeerSafeDeployer is Ownable {
    mapping(address => Vault) vaults;
    address[] keys;

    constructor () Ownable(msg.sender, msg.sender) {}

    function getVault(address _vaultOwner) external view returns(address) {
        Vault _v = vaults[_vaultOwner];
        if (_v.getOwner() == _vaultOwner) {
            return address(_v);
        }
        revert("ERR691: vault doesn't exist");
    }

    function deploy(string memory _userName, bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s) external returns(address) {
        address signer = SigUtils.recoverSigner(_hashedMessage, _v, _r, _s);
        Vault _vault = new Vault(owner, _userName);
        vaults[signer] = _vault;
        return address(_vault);
    }

    function createFile(string memory name, string memory fileType, string memory ipfsHash, string memory key, bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s) external {
        address signer = SigUtils.recoverSigner(_hashedMessage, _v, _r, _s);
        Vault _vault = vaults[signer];
        _vault.createFile(name, fileType, ipfsHash, key);
    }

    function getAllFiles(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s) external view returns(File[] memory) {
        address signer = SigUtils.recoverSigner(_hashedMessage, _v, _r, _s);
        Vault _vault = vaults[signer];
        return _vault.getAllFiles();
    }

    function deleteFile(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s, uint256 index) external {
        address signer = SigUtils.recoverSigner(_hashedMessage, _v, _r, _s);
        Vault _vault = vaults[signer];
        return _vault.deleteFile(index);
    }

    function adminAllVaults() external view onlyOwnerOrCreator returns(address[] memory, Vault[] memory) {
        Vault[] memory _vaults;

        for (uint i = 0; i < keys.length; i++) {
            _vaults[i] = (vaults[keys[i]]);
        }

        return (keys, _vaults);
    }

    function adminMigrate(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s, address[] memory _users, address[] memory _oldVaults) external onlyOwnerOrCreator{
        require(_users.length == _oldVaults.length, 'length should be equal');

        for (uint i = 0; i < _users.length; i++) {
            Vault _newVault = new Vault(owner, Vault(_oldVaults[i]).user());
            vaults[_users[i]] = _newVault;
            _newVault.migrateFiles(_hashedMessage, _v, _r, _s, Vault(_oldVaults[i]).getAllFiles());
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


library SigUtils {
    function recoverSigner(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s) internal pure returns(address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        return ecrecover(prefixedHashMessage, _v, _r, _s);
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
import "./utils/SigUtils.sol";


struct File {
    string _name;
    string _fileType;
    string _ipfsHash;
    string _key;
}

contract Vault is Ownable {
    string public user;
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

    function deleteFile(uint256 index) external onlyOwnerOrCreator {
        require( index >= files.length );
        files[index] = files[files.length-1];
        files.pop();
    }

    function migrateFiles(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s, File[] memory _files) public{
        address signer = SigUtils.recoverSigner(_hashedMessage, _v, _r, _s);
        require(signer == owner || signer == creator, 'neither owner nor creator');
        for (uint i = 0; i < _files.length; i++ ){
            files.push(_files[i]);
        }
    }
}