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

// SPDX-License-Identifier: BSL
// https://zan.top
pragma solidity ^0.8.18;

contract MerkleTreeWithHistory {
  // uint256 public constant FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
  //  uint256 private constant ZERO_VALUE = 15340071473835708773084050001895289394898835954344072938734588345380677720271; // = keccak256("zan.top") % FIELD_SIZE

  // the following variables are made public only for debug purpose. should be changed to private in production
  uint32 private constant levels = 20;
  uint32 private currentRootIndex = 0;
  uint32 private nextIndex = 0;

  // roots could be bytes32[size], but using mappings makes it cheaper because
  // it removes index range check on every interaction
  mapping(uint256 => bytes32) private roots;
  uint32 private constant ROOT_HISTORY_SIZE = 30;


  constructor() {
    roots[0] = bytes32(0x00504c636f632a1f8552f6f4d1e61c80484220b8122d3c3195d2607ace012933);
    /*
    Level 0 is: 0x21ea2c3aa09ab5ae95b0856d8ca9f355c4e9eb0ec95968f9c601237adb8198cf
    Level 1 is: 0x1a49b7e5144b923a6e87ba5be58acf3944309db77a58d66ae50ef4fbb41a5032
    Level 2 is: 0x1b1ef1e390bf4ec6716729eb509cb81574c7d309173d13c81a9538f862731004
    Level 3 is: 0x14b3afd015ec438200faded502f3b1333c3e60f13098b3b4d46b01814dfbadd4
    Level 4 is: 0x15b0458e0c608f3a945d088d9cdef6082ae599018d86e8c23bc47cff1ab95ecb
    Level 5 is: 0x0a9aa077feaa6966b94efdbf619342bc421be7dbb023f0aae2ae1596820588e5
    Level 6 is: 0x2f845300c8897e63fd723f5a49f1d28d667a2ca4ce9da692ba2eba9efc98fb1e
    Level 7 is: 0x21cad187ac37e7b3a6cda6ca4a23743924c0d8f72ba55a5918b1ee49ce595584
    Level 8 is: 0x12e6fbcb409840cc00871ae97f4cb828f7216971ac9079cc98b973328e85ae05
    Level 9 is: 0x2976d3dec0f099a625b5fa70114920e1a0591b2063d28185928b36b831dff0d4
    Level 10 is: 0x1d9ec8fe6e8196f6a1834cd55ca6bea077ba501951913ad000c725ce60c3f7b0
    Level 11 is: 0x05a339f668815ee114f935adedfd430dc1939b57bd258a336d13a4b999afb208
    Level 12 is: 0x15085c3d59d0bcff60f75600c231d3546813625c8feeea5c05f4b4caef1c3bae
    Level 13 is: 0x12821caed38f9130ccd03a7d4120464cddc54de6ccc67ebb78a793ab72856feb
    Level 14 is: 0x11f84136fe2c1d88eeacfec8ee7ca61724c0d743741356ddd4036096edb04276
    Level 15 is: 0x1c15c15ae647d4b0f8d33cf74cd0039a87840e7bd18cc9511f90cbe0394615f0
    Level 16 is: 0x0e92e891aa1acae582ecf86769cc0100f7258cee4fc25228c2b9251768a0c062
    Level 17 is: 0x0adec924f21fd1446cdee40861b9fb058c1e2fabe110d567305597a9a5acc524
    Level 18 is: 0x1498b66534c1bea8cec6df6d3359b7858a90f471dffe31a6b26e6f8a9c2e0cf3
    Level 19 is: 0x2d74d1d5cc2121101f9d1388440af4d6e5dccae2ee80039d5650c438e561fde9
    Level 20 is: 0x00504c636f632a1f8552f6f4d1e61c80484220b8122d3c3195d2607ace012933
    */
  }

  function _insert(bytes32 rootHash, uint32 startIndex, uint32 leafNum) internal {
    uint32 _nextIndex = nextIndex;
    require(_nextIndex + leafNum < uint32(2)**levels, "Merkle tree is full.");
    require(_nextIndex == startIndex, "Insert leaf in wrong position");

    uint32 newRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
    currentRootIndex = newRootIndex;
    roots[newRootIndex] = rootHash;
    nextIndex = _nextIndex + leafNum;
  }

  /**
    @dev Whether the root is present in the root history
  */
  function isKnownRoot(bytes32 root) public view returns (bool) {
    if (root == 0) {
      return false;
    }
    uint32 _currentRootIndex = currentRootIndex;
    uint32 i = _currentRootIndex;
    do {
      if (root == roots[i]) {
        return true;
      }
      if (i == 0) {
        i = ROOT_HISTORY_SIZE;
      }
      i--;
    } while (i != _currentRootIndex);
    return false;
  }

  /**
    @dev Returns the last root
  */
  function getLastRoot() public view returns (bytes32) {
    return roots[currentRootIndex];
  }
}

// SPDX-License-Identifier: BSL
// https://zan.top
pragma solidity ^0.8.18;

import "./MerkleTreeWithHistory.sol";
import "./Verifier.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Pov is MerkleTreeWithHistory, Verifier, Ownable {

  event SubmitCommitment(bytes32 commitment, bytes32 rootHash, uint32 indexed leafIndex, uint256 timestamp);
  event SubmitCommitmentBatch(bytes32[] commitments, bytes32 rootHash, uint32 indexed leafIndexStart, uint256 timestamp);
  event VerifyCommitment(address indexed validator, bytes32 userSecret);

  /**
    @dev submit commitment with its merkle root and position
    @param commitment the credential commitment, which is poseidonHash(UserAddress + Credential)
    @param rootHash the merkle tree root after current commitment is inserted in the tree
    @param index the position of current commitment in the merkle tree
  */
  function submit(bytes32 commitment, bytes32 rootHash, uint32 index) external onlyOwner {
    _insert(rootHash, index, 1);
    emit SubmitCommitment(commitment, rootHash, index, block.timestamp);
  }

  /**
    @dev submit multiple commitments in batch
    @param commitments an array of credential commitments
    @param rootHash the merkle tree root after commitments are all inserted in the tree
    @param startIndex the position of the first commitment in the merkle tree
  */
  function submitBatch(bytes32[] calldata commitments, bytes32 rootHash, uint32 startIndex) external onlyOwner {
    uint32 _commitLength = uint32(commitments.length); 
    uint32 _index = startIndex;

    _insert(rootHash, _index, _commitLength);

    emit SubmitCommitmentBatch(commitments, rootHash, startIndex, block.timestamp);
  }


  /**
    @dev verify a user's commitment in the contract.
    `proof` is a zokrates proof data, and other parameters are circuit public inputs:
      - merkle root of user's commitment in the contract
      - addrSecret is poseidonHash(UserAddress + proofSalt)
      - validator address is msg.sender, which is a validator address that bounded with proof
  */
  function verify(
    bytes calldata proof,
    bytes32 root,
    bytes32 addrSecret
  ) external {
    require(isKnownRoot(root), "Cannot find your merkle root"); // Make sure to use a recent one
    address validator = msg.sender;
    require(
      _verifyProof(
        proof,
        [uint256(root), uint256(uint160(validator)), uint256(addrSecret)]
      ),
      "Invalid proof"
    );
    emit VerifyCommitment(validator, addrSecret);
  }
}

// SPDX-License-Identifier: BSL
// https://zan.top
pragma solidity ^0.8.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
            11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
            4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }


    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
        G1Point memory a1, G2Point memory a2,
        G1Point memory b1, G2Point memory b2,
        G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
        G1Point memory a1, G2Point memory a2,
        G1Point memory b1, G2Point memory b2,
        G1Point memory c1, G2Point memory c2,
        G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function _verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x00ab193408dc501eeabca24e28c3393e77b1ff0756e0928ec3d02e6550e200b1), uint256(0x0e739ada0547d21a94d1dedd7f1b9dd1364912b9f0a7868b8077c4efc94f94ec));
        vk.beta = Pairing.G2Point([uint256(0x20fee5cded2da425ddbbef1457d0ae9108e03f66896580bd3312db6f19f5197e), uint256(0x1687aa657e79af1058e0390b50c0e98acaac88d0b305add2e9300e2b7dda33ac)], [uint256(0x16f47511953ae76466d98b6f1f7358869ea8f734128ace2cf97bf818b098b94e), uint256(0x2309a8c929488c7ae4e2c81d0be7bab82a451ef994c78434c808787f0939fb97)]);
        vk.gamma = Pairing.G2Point([uint256(0x2c399d6cdce042115964e741fbd557e0dbb8445ec5f9f0d4131df241d83353a1), uint256(0x23587b97d871120eeb4624ca09dfaf9dc963dc86b5ff55e996e64540e5521d04)], [uint256(0x03c52bf199fa5e2137c02deba54e5de1c381247e92a7fbffa18798f50230986a), uint256(0x1e20a6798d4127de343d787eac4f9bff203f68a19e41d8c69994470e6a504954)]);
        vk.delta = Pairing.G2Point([uint256(0x0ce2dded580aae98d1d32c51439458e19d3f911d068641f22127b8d6c3f46b8b), uint256(0x1e0fad263eabb4b51068996ec0693a3794f238bb22f66ddc18e3f1c0cc922eeb)], [uint256(0x0dddb384ae06be1a63c64452e89d5962903f55a6763222ca087aae613b47f2df), uint256(0x2f454b2f790107622d14b0ba250fd316d2697a69571eaf87c5f8020d9209d3b2)]);
        vk.gamma_abc = new Pairing.G1Point[](4);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x19a67775c1de1ff5efac377331a97c8b1f6d67dcc7ecbd69dba2749714862d31), uint256(0x1ea06fd5ed8a15fe977c40bd21b58d5e408835222e52e19904a55c07b2a681ba));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x28919c3ac9efca24fb19f8277212065f41cb055b53aaa120479d7879cec50035), uint256(0x2a3545d982ba2952fe47fa3a41ef120b4359b7e3af47b8eb472ca55c9c0dfb2a));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x04f4f67488ba4c6a9d73f87f41d10e1457280d1ab043cd73f15eef00d81223ed), uint256(0x224aea947edb1ac8b3b63313cb0ffb87de7bcbe78be465483bc843cf8a58842b));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x0e84893e73d504770c635be136b905195fee90aa1b477832593702d5d17d41f5), uint256(0x003d0ab56663221ccca5024ea28c2574f0f740651148b9a392c16ae923d1e49a));
    }
    function _verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = _verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if(!Pairing.pairingProd4(
            proof.a, proof.b,
            Pairing.negate(vk_x), vk.gamma,
            Pairing.negate(proof.c), vk.delta,
            Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }

    function _verifyProof(bytes memory proof, uint256[3] memory input) internal view returns (bool) {
        uint256[8] memory p = abi.decode(proof, (uint256[8]));

        Proof memory _proof;
        _proof.a = Pairing.G1Point(p[0], p[1]);
        _proof.b = Pairing.G2Point([p[2], p[3]], [p[4], p[5]]);
        _proof.c = Pairing.G1Point(p[6], p[7]);

        uint[] memory inputValues = new uint[](3);

        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }

        if (_verify(inputValues, _proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}