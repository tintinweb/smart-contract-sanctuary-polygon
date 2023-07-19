// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./utils/Ownable.sol";
import "./utils/SigUtils.sol";
import "./utils/SECP256K1.sol";
import "./utils/ShareManager.sol";
import "./utils/File.sol";
import "./utils/UseDeployer.sol";
import "./utils/User.sol";
import "./interfaces/IVaultDeployer.sol";
import "./interfaces/IVault.sol";

contract PeerSafeDeployer is Ownable {
    mapping(address => User) users;
    address[] keys;
    address deployer;
    using ShareManager for ShareRequests;
    ShareRequests shareRequests;

    constructor (address _deployer) Ownable(msg.sender, msg.sender) {
        deployer = _deployer;
    }

    function getVault(address _vaultOwner) external view returns(address) {
        IVault _v = users[_vaultOwner].vault;
        require(address(_v) != address(0), "does not exist");
        return address(_v);
    }

    function deploy(string memory _userName, bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s) external returns(address) {
        (address signer, bytes memory pubKey) = SECP256K1.recoverSignerAndPubKey(_hashedMessage, _v, _r, _s);
        IVault _vault = IVault(IVaultDeployer(deployer).deploy(signer, _userName));
        users[signer] = User(_vault, pubKey);
        keys.push(signer);
        return address(_vault);
    }

    function createFile(string memory name, string memory fileType, string memory ipfsHash, string memory key, bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s) external {
        address signer = SigUtils.recoverSigner(_hashedMessage, _v, _r, _s);
        IVault _vault = users[signer].vault;
        _vault.createFile(name, fileType, ipfsHash, key);
    }

    function getAllFiles(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s) external view returns(File[] memory) {
        address signer = SigUtils.recoverSigner(_hashedMessage, _v, _r, _s);
        IVault _vault = users[signer].vault;
        return _vault.getAllFiles();
    }

    function deleteFile(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s, string memory ipfsHash) external {
        address signer = SigUtils.recoverSigner(_hashedMessage, _v, _r, _s);
        IVault _vault = users[signer].vault;
        return _vault.deleteFile(ipfsHash);
    }

    function getPubKey(address _user) external view returns(bytes memory) {
        return users[_user].pubKey;
    }

    function sendShareRequest(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s, address _to, string memory _fileHash, string memory _keyHash, string memory _name, string memory _fileType) external {
        require(_to != address(0), "ERR691");
        require(users[_to].pubKey.length != 0, "ERR691");
        address signer = SigUtils.recoverSigner(_hashedMessage, _v, _r, _s);
        shareRequests.addShareRequest(signer, _to, _fileHash, _keyHash, _name, _fileType);
    }

    function getShareRequests(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s) external view returns(ShareRequest[] memory) {
        address signer = SigUtils.recoverSigner(_hashedMessage, _v, _r, _s);
        require(signer != address(0), "ERR691");
        return shareRequests.getShareRequests(signer);
    }

    function acceptShareRequest(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s, string memory _fileHash) external {
        address signer = SigUtils.recoverSigner(_hashedMessage, _v, _r, _s);
        require(shareRequests._shareRequests[signer][_fileHash]._from != address(0), "ERR214");
        require(users[signer].pubKey.length != 0, "ERR691");
        IVault _vault = users[signer].vault;
        ShareRequest memory _shareRequest = shareRequests._shareRequests[signer][_fileHash];
        _vault.addSharedFile(_shareRequest._name, _shareRequest._fileType, _shareRequest._fileHash, _shareRequest._keyHash, _shareRequest._from);
        shareRequests.deleteShareRequest(signer, _fileHash);
    }

    function rejectShareRequest(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s, string memory _fileHash) external {
        address signer = SigUtils.recoverSigner(_hashedMessage, _v, _r, _s);
        shareRequests.deleteShareRequest(signer, _fileHash);
    }

    function adminAllVaults() external view onlyOwnerOrCreator returns(address[] memory, address[] memory) {
        address[] memory _vaults;

        for (uint i = 0; i < keys.length; i++) {
            _vaults[i] = address(users[keys[i]].vault);
        }

        return (keys, _vaults);
    }

    // function adminMigrate(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s, address[] memory _users, address[] memory _oldVaults) external onlyOwnerOrCreator{
    //     require(_users.length == _oldVaults.length, 'length should be equal');

    //     for (uint i = 0; i < _users.length; i++) {
    //         IVault _newVault = IVault(UseDeployer.deployVault(deployer, owner, IVault(_oldVaults[i]).getUser()));
    //         users[_users[i]] = _newVault;
    //         _newVault.migrateFiles(_hashedMessage, _v, _r, _s, IVault(_oldVaults[i]).getAllFiles());
    //     }
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../interfaces/IVault.sol";

struct User {
    IVault vault;
    bytes pubKey;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


library UseDeployer {
    function deployVault(address deployer, address owner, string memory userName) internal returns(address) {
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("deploy(address owner, string memory userName)")), owner, userName);
        (bool success, bytes memory returnedData) = deployer.delegatecall(data);
        require(success, "depl fail");
        return abi.decode(returnedData, (address));
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


struct ShareRequest {
    address _from;
    string _fileHash;
    string _keyHash;
    string _name;
    string _fileType;
}

struct ShareRequests {
    mapping(address => mapping(string => ShareRequest)) _shareRequests;
    mapping(address => string[]) _keys;
}

library ShareManager {
    function addShareRequest(ShareRequests storage self, address _from, address _to, string memory _fileHash, string memory _keyHash, string memory _name, string memory _fileType) internal {
        require(self._shareRequests[_to][_fileHash]._from == address(0), "SRAExists");
        ShareRequest memory _shareRequest = ShareRequest(
            {
                _from: _from,
                _fileHash: _fileHash,
                _keyHash: _keyHash,
                _name: _name,
                _fileType: _fileType
            }
        );
        self._shareRequests[_to][_fileHash] = _shareRequest;
        self._keys[_to].push(_fileHash);
    }

    function getShareRequests(ShareRequests storage self, address _sender) internal view returns(ShareRequest[] memory) {
        ShareRequest[] memory _shareRequest = new ShareRequest[](self._keys[_sender].length);
        for (uint i = 0; i < self._keys[_sender].length; i++) {
            _shareRequest[i] = self._shareRequests[_sender][self._keys[_sender][i]];
        }
        return _shareRequest;
    }

    function deleteShareRequest(ShareRequests storage self, address sender, string memory _fileHash) internal {
        delete self._shareRequests[sender][_fileHash];
        for (uint i = 0; i < self._keys[sender].length; i++) {
            if (keccak256(abi.encodePacked(self._keys[sender][i])) == keccak256(abi.encodePacked(_fileHash))) {
                delete self._keys[sender][i];
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SECPK256K1 public key recovery Library
 * @dev Library providing arithmetic operations over signed `secpk256k1` signed message due to recover the signer public key EC point in `Solidity`.
 * @author cyphered.eth
 */
library SECP256K1 {
    // Elliptic curve Constants
    uint256 private constant U255_MAX_PLUS_1 =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;

    // Curve Constants
    uint256 private constant A = 0;
    uint256 private constant B = 7;
    uint256 private constant GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 private constant GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
    uint256 private constant P = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
    uint256 private constant N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    function recoverSignerAndPubKey(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s) internal pure returns(address, bytes memory) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        (uint256 x, uint256 y) = recover(uint256(prefixedHashMessage), _v - 27, uint256(_r), uint256(_s));
        return (ecrecover(prefixedHashMessage, _v, _r, _s), abi.encodePacked(x, y));
    }

    /// @dev recovers signer public key point value.
    /// @param digest hashed message
    /// @param v recovery
    /// @param r first 32 bytes of signature
    /// @param v last 32 bytes of signature
    /// @return (x, y) EC point
    function recover(
        uint256 digest,
        uint8 v,
        uint256 r,
        uint256 s
    ) public pure returns (uint256, uint256) {
        uint256 x = addmod(r, P * (v >> 1), P);
        if (x > P || s > N || r > N || s == 0 || r == 0 || v > 1) {
            return (0, 0);
        }
        uint256 rInv = invMod(r, N);

        uint256 y2 = addmod(mulmod(x, mulmod(x, x, P), P), addmod(mulmod(x, A, P), B, P), P);
        y2 = expMod(y2, (P + 1) / 4);
        uint256 y = ((y2 + v + 2) & 1 == 0) ? y2 : P - y2;

        (uint256 qx, uint256 qy, uint256 qz) = jacMul(mulmod(rInv, N - digest, N), GX, GY, 1);
        (uint256 qx2, uint256 qy2, uint256 qz2) = jacMul(mulmod(rInv, s, N), x, y, 1);
        (uint256 qx3, uint256 qy3) = ecAdd(qx, qy, qz, qx2, qy2, qz2);

        return (qx3, qy3);
    }

    /// @dev Modular exponentiation, b^e % P.
    /// Source: https://github.com/witnet/elliptic-curve-solidity/blob/master/contracts/EllipticCurve.sol
    /// Source: https://github.com/androlo/standard-contracts/blob/master/contracts/src/crypto/ECCMath.sol
    /// @param _base base
    /// @param _exp exponent
    /// @return r such that r = b**e (mod P)
    function expMod(uint256 _base, uint256 _exp) internal pure returns (uint256) {
        if (_base == 0) return 0;
        if (_exp == 0) return 1;

        uint256 r = 1;
        uint256 bit = U255_MAX_PLUS_1;
        assembly {
            for {

            } gt(bit, 0) {

            } {
                r := mulmod(mulmod(r, r, P), exp(_base, iszero(iszero(and(_exp, bit)))), P)
                r := mulmod(mulmod(r, r, P), exp(_base, iszero(iszero(and(_exp, div(bit, 2))))), P)
                r := mulmod(mulmod(r, r, P), exp(_base, iszero(iszero(and(_exp, div(bit, 4))))), P)
                r := mulmod(mulmod(r, r, P), exp(_base, iszero(iszero(and(_exp, div(bit, 8))))), P)
                bit := div(bit, 16)
            }
        }

        return r;
    }

    /// @dev Adds two points (x1, y1, z1) and (x2 y2, z2).
    /// Source: https://github.com/witnet/elliptic-curve-solidity/blob/master/contracts/EllipticCurve.sol
    /// @param _x1 coordinate x of P1
    /// @param _y1 coordinate y of P1
    /// @param _z1 coordinate z of P1
    /// @param _x2 coordinate x of square
    /// @param _y2 coordinate y of square
    /// @param _z2 coordinate z of square
    /// @return (qx, qy, qz) P1+square in Jacobian
    function jacAdd(
        uint256 _x1,
        uint256 _y1,
        uint256 _z1,
        uint256 _x2,
        uint256 _y2,
        uint256 _z2
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (_x1 == 0 && _y1 == 0) return (_x2, _y2, _z2);
        if (_x2 == 0 && _y2 == 0) return (_x1, _y1, _z1);

        // We follow the equations described in https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf Section 5
        uint256[4] memory zs; // z1^2, z1^3, z2^2, z2^3
        zs[0] = mulmod(_z1, _z1, P);
        zs[1] = mulmod(_z1, zs[0], P);
        zs[2] = mulmod(_z2, _z2, P);
        zs[3] = mulmod(_z2, zs[2], P);

        // u1, s1, u2, s2
        zs = [mulmod(_x1, zs[2], P), mulmod(_y1, zs[3], P), mulmod(_x2, zs[0], P), mulmod(_y2, zs[1], P)];

        // In case of zs[0] == zs[2] && zs[1] == zs[3], double function should be used
        require(zs[0] != zs[2] || zs[1] != zs[3], 'Use jacDouble function instead');

        uint256[4] memory hr;
        //h
        hr[0] = addmod(zs[2], P - zs[0], P);
        //r
        hr[1] = addmod(zs[3], P - zs[1], P);
        //h^2
        hr[2] = mulmod(hr[0], hr[0], P);
        // h^3
        hr[3] = mulmod(hr[2], hr[0], P);
        // qx = -h^3  -2u1h^2+r^2
        uint256 qx = addmod(mulmod(hr[1], hr[1], P), P - hr[3], P);
        qx = addmod(qx, P - mulmod(2, mulmod(zs[0], hr[2], P), P), P);
        // qy = -s1*z1*h^3+r(u1*h^2 -x^3)
        uint256 qy = mulmod(hr[1], addmod(mulmod(zs[0], hr[2], P), P - qx, P), P);
        qy = addmod(qy, P - mulmod(zs[1], hr[3], P), P);
        // qz = h*z1*z2
        uint256 qz = mulmod(hr[0], mulmod(_z1, _z2, P), P);
        return (qx, qy, qz);
    }

    /// @dev Multiply point (x, y, z) times d.
    /// Source: https://github.com/witnet/elliptic-curve-solidity/blob/master/contracts/EllipticCurve.sol
    /// @param _d scalar to multiply
    /// @param _x coordinate x of P1
    /// @param _y coordinate y of P1
    /// @param _z coordinate z of P1
    /// @return (qx, qy, qz) d*P1 in Jacobian
    function jacMul(
        uint256 _d,
        uint256 _x,
        uint256 _y,
        uint256 _z
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // Early return in case that `_d == 0`
        if (_d == 0) {
            return (_x, _y, _z);
        }

        uint256 remaining = _d;
        uint256 qx = 0;
        uint256 qy = 0;
        uint256 qz = 1;

        // Double and add algorithm
        while (remaining != 0) {
            if ((remaining & 1) != 0) {
                (qx, qy, qz) = jacAdd(qx, qy, qz, _x, _y, _z);
            }
            remaining = remaining / 2;
            (_x, _y, _z) = jacDouble(_x, _y, _z);
        }
        return (qx, qy, qz);
    }

    /// @dev Doubles a points (x, y, z).
    /// Source: https://github.com/witnet/elliptic-curve-solidity/blob/master/contracts/EllipticCurve.sol
    /// @param _x coordinate x of P1
    /// @param _y coordinate y of P1
    /// @param _z coordinate z of P1
    /// @return (qx, qy, qz) 2P in Jacobian
    function jacDouble(
        uint256 _x,
        uint256 _y,
        uint256 _z
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (_z == 0) return (_x, _y, _z);

        // We follow the equations described in https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf Section 5
        // Note: there is a bug in the paper regarding the m parameter, M=3*(x1^2)+a*(z1^4)
        // x, y, z at this point represent the squares of _x, _y, _z
        uint256 x = mulmod(_x, _x, P); //x1^2
        uint256 y = mulmod(_y, _y, P); //y1^2
        uint256 z = mulmod(_z, _z, P); //z1^2

        // s
        uint256 s = mulmod(4, mulmod(_x, y, P), P);
        // m
        uint256 m = addmod(mulmod(3, x, P), mulmod(A, mulmod(z, z, P), P), P);

        // x, y, z at this point will be reassigned and rather represent qx, qy, qz from the paper
        // This allows to reduce the gas cost and stack footprint of the algorithm
        // qx
        x = addmod(mulmod(m, m, P), P - addmod(s, s, P), P);
        // qy = -8*y1^4 + M(S-T)
        y = addmod(mulmod(m, addmod(s, P - x, P), P), P - mulmod(8, mulmod(y, y, P), P), P);
        // qz = 2*y1*z1
        z = mulmod(2, mulmod(_y, _z, P), P);

        return (x, y, z);
    }

    /// @dev Add two points (x1, y1) and (x2, y2) in affine coordinates.
    /// Source: https://github.com/witnet/elliptic-curve-solidity/blob/master/contracts/EllipticCurve.sol
    /// @param _x1 coordinate x of P1
    /// @param _y1 coordinate y of P1
    /// @param _x2 coordinate x of P2
    /// @param _y2 coordinate y of P2
    /// @return (qx, qy) = P1+P2 in affine coordinates
    function ecAdd(
        uint256 _x1,
        uint256 _y1,
        uint256 _z1,
        uint256 _x2,
        uint256 _y2,
        uint256 _z2
    ) internal pure returns (uint256, uint256) {
        uint256 x = 0;
        uint256 y = 0;
        uint256 z = 0;

        // Double if x1==x2 else add
        if (_x1 == _x2) {
            // y1 = -y2 mod p
            if (addmod(_y1, _y2, P) == 0) {
                return (0, 0);
            } else {
                // P1 = P2
                (x, y, z) = jacDouble(_x1, _y1, _z1);
            }
        } else {
            (x, y, z) = jacAdd(_x1, _y1, _z1, _x2, _y2, _z2);
        }
        // Get back to affine
        return toAffine(x, y, z);
    }

    /// @dev Converts a point (x, y, z) expressed in Jacobian coordinates to affine coordinates (x', y', 1).
    /// Source: https://github.com/witnet/elliptic-curve-solidity/blob/master/contracts/EllipticCurve.sol
    /// @param _x coordinate x
    /// @param _y coordinate y
    /// @param _z coordinate z
    /// @return (x', y') affine coordinates
    function toAffine(
        uint256 _x,
        uint256 _y,
        uint256 _z
    ) internal pure returns (uint256, uint256) {
        uint256 zInv = invMod(_z, P);
        uint256 zInv2 = mulmod(zInv, zInv, P);
        uint256 x2 = mulmod(_x, zInv2, P);
        uint256 y2 = mulmod(_y, mulmod(zInv, zInv2, P), P);

        return (x2, y2);
    }

    /// @dev Modular euclidean inverse of a number (mod p).
    /// Source: https://github.com/witnet/elliptic-curve-solidity/blob/master/contracts/EllipticCurve.sol
    /// @param _x The number
    /// @param _pp The modulus
    /// @return q such that x*q = 1 (mod _pp)
    function invMod(uint256 _x, uint256 _pp) internal pure returns (uint256) {
        require(_x != 0 && _x != _pp && _pp != 0, 'Invalid number');
        uint256 q = 0;
        uint256 newT = 1;
        uint256 r = _pp;
        uint256 t;
        while (_x != 0) {
            t = r / _x;
            (q, newT) = (newT, addmod(q, (_pp - mulmod(t, newT, _pp)), _pp));
            (r, _x) = (_x, r - t * _x);
        }

        return q;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


struct File {
    string _name;
    string _fileType;
    string _ipfsHash;
    string _key;
    address _sharedBy;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVaultDeployer {
    function deploy(address owner, string memory userName) external returns(address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../utils/File.sol";


interface IVault {
    function getAllFiles() external view returns(File[] memory);
    function createFile(string memory name, string memory fileType, string memory ipfsHash, string memory key) external;
    function addSharedFile(string memory name, string memory fileType, string memory ipfsHash, string memory key, address sharedBy) external;
    function deleteFile(string memory ipfsHash) external;
    function migrateFiles(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s, File[] memory _files) external;
    function getOwner() external view returns (address);
    function getCreator() external view returns (address);
    function getUser() external view returns(string memory);
}