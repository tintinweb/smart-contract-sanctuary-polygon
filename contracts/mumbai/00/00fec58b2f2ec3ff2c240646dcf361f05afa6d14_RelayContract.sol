// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import './MerkleProof.sol';

contract BeaconChain is MerkleProof {
  struct BeaconBlockHeader {
    uint64 slot;
    uint64 proposer_index;
    bytes32 parent_root;
    bytes32 state_root;
    bytes32 body_root;
  }

  function hash_tree_root(BeaconBlockHeader memory beacon_header)
    internal
    pure
    returns (bytes32)
  {
    bytes32[] memory leaves = new bytes32[](5);
    leaves[0] = bytes32(to_little_endian_64(beacon_header.slot));
    leaves[1] = bytes32(to_little_endian_64(beacon_header.proposer_index));
    leaves[2] = beacon_header.parent_root;
    leaves[3] = beacon_header.state_root;
    leaves[4] = beacon_header.body_root;
    return merkle_root(leaves);
  }

  function merkle_root(bytes32[] memory leaves)
    internal
    pure
    returns (bytes32)
  {
    uint256 len = leaves.length;
    if (len == 0) return bytes32(0);
    else if (len == 1) return hash(abi.encodePacked(leaves[0]));
    else if (len == 2) return hash_node(leaves[0], leaves[1]);
    uint256 bottom_length = get_power_of_two_ceil(len);
    bytes32[] memory o = new bytes32[](bottom_length * 2);
    for (uint256 i = 0; i < len; ++i) {
      o[bottom_length + i] = leaves[i];
    }
    for (uint256 i = bottom_length - 1; i > 0; --i) {
      o[i] = hash_node(o[i * 2], o[i * 2 + 1]);
    }
    return o[1];
  }

  //  Get the power of 2 for given input, or the closest higher power of 2 if the input is not a power of 2.
  function get_power_of_two_ceil(uint256 x) internal pure returns (uint256) {
    if (x <= 1) return 1;
    else if (x == 2) return 2;
    else return 2 * get_power_of_two_ceil((x + 1) >> 1);
  }

  function to_little_endian_64(uint64 value) internal pure returns (bytes8 r) {
    return bytes8(reverse64(value));
  }

  function reverse64(uint64 input) internal pure returns (uint64 v) {
    v = input;

    // swap bytes
    v = ((v & 0xFF00FF00FF00FF00) >> 8) | ((v & 0x00FF00FF00FF00FF) << 8);

    // swap 2-byte long pairs
    v = ((v & 0xFFFF0000FFFF0000) >> 16) | ((v & 0x0000FFFF0000FFFF) << 16);

    // swap 4-byte long pairs
    v = (v >> 32) | (v << 32);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract MerkleProof {
  // Check if ``leaf`` at ``index`` verifies against the Merkle ``root`` and ``branch``.
  function is_valid_merkle_branch(
    bytes32 leaf,
    bytes32[] memory branch,
    uint64 depth,
    uint64 index,
    bytes32 root
  ) internal pure returns (bool) {
    bytes32 value = leaf;
    for (uint256 i = 0; i < depth; ++i) {
      if ((index / (2**i)) % 2 == 1) {
        value = hash_node(branch[i], value);
      } else {
        value = hash_node(value, branch[i]);
      }
    }

    return value == root;
  }

  function hash_node(bytes32 left, bytes32 right)
    internal
    pure
    returns (bytes32)
  {
    return hash(abi.encodePacked(left, right));
  }

  function hash(bytes memory value) internal pure returns (bytes32) {
    return sha256(value);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '../../utils/LightClientUpdateVerifier.sol';
import '../../spec/BeaconChain.sol';

contract BeaconLightClient is LightClientUpdateVerifier {
  struct LightClientUpdate {
    bytes32 attested_header_root;
    bytes32 finalized_header_root;
    bytes32 finalized_execution_state_root;
    uint256[2] a;
    uint256[2][2] b;
    uint256[2] c;
  }

  bytes32 _optimistic_header_root;

  bytes32 _finalized_header_root;

  bytes32 _finalized_execution_state_root;

  constructor(
    bytes32 __optimistic_header_root,
    bytes32 __finalized_header_root,
    bytes32 __execution_state_root
  ) {
    _optimistic_header_root = __optimistic_header_root;
    _finalized_header_root = __finalized_header_root;
    _finalized_execution_state_root = __execution_state_root;
  }

  function execution_state_root() public view returns (bytes32) {
    return _finalized_execution_state_root;
  }

  function optimistic_header_root() public view returns (bytes32) {
    return _optimistic_header_root;
  }

  function finalized_header_root() public view returns (bytes32) {
    return _finalized_header_root;
  }

  function light_client_update(LightClientUpdate calldata update)
    external
    payable
  {
    require(
      verifyUpdate(
        update.a,
        update.b,
        update.c,
        optimistic_header_root(),
        update.attested_header_root,
        update.finalized_header_root,
        update.finalized_execution_state_root
      ),
      '!proof'
    );

    _optimistic_header_root = update.attested_header_root;
    _finalized_header_root = update.finalized_header_root;
    _finalized_execution_state_root = update.finalized_execution_state_root;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import './Verifier.sol';

contract LightClientUpdateVerifier is Verifier {
  function verifyUpdate(
    uint256[2] memory a,
    uint256[2][2] memory b,
    uint256[2] memory c,
    bytes32 prev_header_hash,
    bytes32 next_header_hash,
    bytes32 finalized_header_root,
    bytes32 execution_state_root
  ) internal view returns (bool) {
    bytes32 commitment = hash(
      prev_header_hash,
      next_header_hash,
      finalized_header_root,
      execution_state_root
    );

    uint256[2] memory input;

    input[0] = (uint256(commitment) & (((1 << 253) - 1) << 3)) >> 3;
    input[1] = (uint256(commitment) & ((1 << 3) - 1));

    return verifyProof(a, b, c, input);
  }

  function hash(
    bytes32 a,
    bytes32 b,
    bytes32 c,
    bytes32 d
  ) private pure returns (bytes32) {
    bytes memory concatenated = abi.encodePacked(a, b, c, d);
    return sha256(concatenated);
  }
}

//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

library Pairing {
  struct G1Point {
    uint256 X;
    uint256 Y;
  }
  // Encoding of field elements is: X[0] * z + X[1]
  struct G2Point {
    uint256[2] X;
    uint256[2] Y;
  }

  /// @return the generator of G1
  function P1() internal pure returns (G1Point memory) {
    return G1Point(1, 2);
  }

  /// @return the generator of G2
  function P2() internal pure returns (G2Point memory) {
    // Original code point
    return
      G2Point(
        [
          11559732032986387107991004021392285783925812861821192530917403151452391805634,
          10857046999023057135944570762232829481370756359578518086990519993285655852781
        ],
        [
          4082367875863433681332203403145435568316851327593401208105741076214120093531,
          8495653923123431417604973247489272438418190587263600148770280649306958101930
        ]
      );

    /*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
  }

  /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
  function negate(G1Point memory p) internal pure returns (G1Point memory r) {
    // The prime q in the base field F_q for G1
    uint256 q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    if (p.X == 0 && p.Y == 0) return G1Point(0, 0);
    return G1Point(p.X, q - (p.Y % q));
  }

  /// @return r the sum of two points of G1
  function addition(G1Point memory p1, G1Point memory p2)
    internal
    view
    returns (G1Point memory r)
  {
    uint256[4] memory input;
    input[0] = p1.X;
    input[1] = p1.Y;
    input[2] = p2.X;
    input[3] = p2.Y;
    bool success;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }
    require(success, 'pairing-add-failed');
  }

  /// @return r the product of a point on G1 and a scalar, i.e.
  /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
  function scalar_mul(G1Point memory p, uint256 s)
    internal
    view
    returns (G1Point memory r)
  {
    uint256[3] memory input;
    input[0] = p.X;
    input[1] = p.Y;
    input[2] = s;
    bool success;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }
    require(success, 'pairing-mul-failed');
  }

  /// @return the result of computing the pairing check
  /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
  /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
  /// return true.
  function pairing(G1Point[] memory p1, G2Point[] memory p2)
    internal
    view
    returns (bool)
  {
    require(p1.length == p2.length, 'pairing-lengths-failed');
    uint256 elements = p1.length;
    uint256 inputSize = elements * 6;
    uint256[] memory input = new uint256[](inputSize);
    for (uint256 i = 0; i < elements; i++) {
      input[i * 6 + 0] = p1[i].X;
      input[i * 6 + 1] = p1[i].Y;
      input[i * 6 + 2] = p2[i].X[0];
      input[i * 6 + 3] = p2[i].X[1];
      input[i * 6 + 4] = p2[i].Y[0];
      input[i * 6 + 5] = p2[i].Y[1];
    }
    uint256[1] memory out;
    bool success;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      success := staticcall(
        sub(gas(), 2000),
        8,
        add(input, 0x20),
        mul(inputSize, 0x20),
        out,
        0x20
      )
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }
    require(success, 'pairing-opcode-failed');
    return out[0] != 0;
  }

  /// Convenience method for a pairing check for two pairs.
  function pairingProd2(
    G1Point memory a1,
    G2Point memory a2,
    G1Point memory b1,
    G2Point memory b2
  ) internal view returns (bool) {
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
    G1Point memory a1,
    G2Point memory a2,
    G1Point memory b1,
    G2Point memory b2,
    G1Point memory c1,
    G2Point memory c2
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
    G1Point memory a1,
    G2Point memory a2,
    G1Point memory b1,
    G2Point memory b2,
    G1Point memory c1,
    G2Point memory c2,
    G1Point memory d1,
    G2Point memory d2
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
    Pairing.G1Point alfa1;
    Pairing.G2Point beta2;
    Pairing.G2Point gamma2;
    Pairing.G2Point delta2;
    Pairing.G1Point[] IC;
  }
  struct Proof {
    Pairing.G1Point A;
    Pairing.G2Point B;
    Pairing.G1Point C;
  }

  function verifyingKey() internal pure returns (VerifyingKey memory vk) {
    vk.alfa1 = Pairing.G1Point(
      20491192805390485299153009773594534940189261866228447918068658471970481763042,
      9383485363053290200918347156157836566562967994039712273449902621266178545958
    );

    vk.beta2 = Pairing.G2Point(
      [
        4252822878758300859123897981450591353533073413197771768651442665752259397132,
        6375614351688725206403948262868962793625744043794305715222011528459656738731
      ],
      [
        21847035105528745403288232691147584728191162732299865338377159692350059136679,
        10505242626370262277552901082094356697409835680220590971873171140371331206856
      ]
    );
    vk.gamma2 = Pairing.G2Point(
      [
        11559732032986387107991004021392285783925812861821192530917403151452391805634,
        10857046999023057135944570762232829481370756359578518086990519993285655852781
      ],
      [
        4082367875863433681332203403145435568316851327593401208105741076214120093531,
        8495653923123431417604973247489272438418190587263600148770280649306958101930
      ]
    );
    vk.delta2 = Pairing.G2Point(
      [
        11559732032986387107991004021392285783925812861821192530917403151452391805634,
        10857046999023057135944570762232829481370756359578518086990519993285655852781
      ],
      [
        4082367875863433681332203403145435568316851327593401208105741076214120093531,
        8495653923123431417604973247489272438418190587263600148770280649306958101930
      ]
    );
    vk.IC = new Pairing.G1Point[](3);

    vk.IC[0] = Pairing.G1Point(
      2392822642995661005171555009488844088176954870319064822645652947726621638605,
      19622522825149758925846860792412025256115126012155814217617363920694413818355
    );

    vk.IC[1] = Pairing.G1Point(
      18954309538486684917164156025490115873263619829298537818491608339093110373239,
      9185979323690985945295229185629666150037261362996364025399775430832808015475
    );

    vk.IC[2] = Pairing.G1Point(
      16010199862829093037919343395088636768729563763409851148470370813861437396580,
      16457624759801426240698376800316458056002370626757831987377706347248123201023
    );
  }

  function verify(uint256[] memory input, Proof memory proof)
    internal
    view
    returns (uint256)
  {
    uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    VerifyingKey memory vk = verifyingKey();
    require(input.length + 1 == vk.IC.length, 'verifier-bad-input');
    // Compute the linear combination vk_x
    Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
    for (uint256 i = 0; i < input.length; i++) {
      require(input[i] < snark_scalar_field, 'verifier-gte-snark-scalar-field');
      vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
    }
    vk_x = Pairing.addition(vk_x, vk.IC[0]);
    if (
      !Pairing.pairingProd4(
        Pairing.negate(proof.A),
        proof.B,
        vk.alfa1,
        vk.beta2,
        vk_x,
        vk.gamma2,
        proof.C,
        vk.delta2
      )
    ) return 1;
    return 0;
  }

  /// @return r  bool true if proof is valid
  function verifyProof(
    uint256[2] memory a,
    uint256[2][2] memory b,
    uint256[2] memory c,
    uint256[2] memory input
  ) public view returns (bool r) {
    Proof memory proof;
    proof.A = Pairing.G1Point(a[0], a[1]);
    proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
    proof.C = Pairing.G1Point(c[0], c[1]);
    uint256[] memory inputValues = new uint256[](input.length);
    for (uint256 i = 0; i < input.length; i++) {
      inputValues[i] = input[i];
    }
    if (verify(inputValues, proof) == 0) {
      return true;
    } else {
      return false;
    }
  }
}

pragma solidity 0.8.9;

import "./MerklePatriciaProof.sol";
import "./RLPReader.sol";

library GetProofLib {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for RLPReader.Iterator;
    using RLPReader for bytes;

    struct Account {
        uint nonce; // 0
        uint balance; // 1
        bytes32 storageHash; // 2
        bytes32 codeHash; // 3
    }

    struct GetProof {
        bytes account;
        bytes accountProof;
        bytes storageProofs;
    }

    struct BlockHeader {
        bytes32 storageRoot;
    }

    struct StorageProof {
        // key of the storage
        bytes32 key;
        // value of the storage at `key`
        bytes value;
        // rlp-serialized array of rlp-serialized MerkleTree-Nodes, starting with the storageHash-Node
        bytes proof;
    }

    // TODO this can be removed
    function verifyProof(bytes memory rlpAccount, bytes memory rlpAccountNodes, bytes memory encodedPath, bytes32 root) internal pure returns (bool) {
        return MerklePatriciaProof.verify(rlpAccount, encodedPath, rlpAccountNodes, root);
    }


    function verifyStorageProof(bytes memory rlpProof, bytes32 storageHash) internal pure returns (bool) {
        StorageProof memory proof = parseStorageProof(rlpProof);
        bytes memory path = triePath(abi.encodePacked(proof.key));

        return MerklePatriciaProof.verify(
            proof.value, path, proof.proof, storageHash
        );
    }

    function parseStorageProof(bytes memory rlpProof) internal pure returns (StorageProof memory proof) {
        RLPReader.Iterator memory it =
        rlpProof.toRlpItem().iterator();

        uint idx;
        while (it.hasNext()) {
            if (idx == 0) {
                proof.key = bytes32(it.next().toUint());
            } else if (idx == 1) {
                proof.value = it.next().toBytes();
            } else if (idx == 2) {
                proof.proof = it.next().toBytes();
            } else {
                it.next();
            }
            idx++;
        }
        return proof;
    }

    // todo only parses storageRoot for now.
    function parseBlockHeader(bytes memory _blockHeader) internal pure returns (BlockHeader memory blockHeader) {
        RLPReader.Iterator memory it = _blockHeader.toRlpItem().iterator();

        uint idx;
        while (it.hasNext()) {
            if (idx == 3) {
                // storageRoot is at index 3
                bytes32 storageRoot;
                bytes memory storageRootBytes = it.next().toBytes();
                assembly {
                    storageRoot := mload(add(storageRootBytes, 32))
                }
                blockHeader.storageRoot = storageRoot;
                return blockHeader;
            } else {
                it.next();
            }

            idx++;
        }
    }

    function parseAccount(bytes memory rlpAccount) internal pure returns (Account memory account) {
        RLPReader.Iterator memory it =
        rlpAccount.toRlpItem().iterator();

        uint idx;
        while (it.hasNext()) {
            if (idx == 0) {
                account.nonce = it.next().toUint();
            } else if (idx == 1) {
                account.balance = it.next().toUint();
            } else if (idx == 2) {
                account.storageHash = bytes32(it.next().toUint());
            } else if (idx == 3) {
                account.codeHash = bytes32(it.next().toUint());
            } else {
                it.next();
            }
            idx++;
        }

        return account;
    }

    function parseProofTest(bytes memory rlpProof) internal pure returns (bytes memory account, bytes memory accountProof, bytes memory storageProof) {
        GetProof memory proof = parseProof(rlpProof);
        account = proof.account;
        accountProof = proof.accountProof;
        storageProof = proof.storageProofs;
        return (account, accountProof, storageProof);
    }
    /**
    * @dev parses an rlp encoded EIP1186 proof
    * @return proof The parsed Proof
    */
    function parseProof(bytes memory rlpProof) internal pure returns (GetProof memory proof) {
        RLPReader.Iterator memory it =
        rlpProof.toRlpItem().iterator();

        uint idx;
        while (it.hasNext()) {
            if (idx == 0) {
                proof.account = it.next().toBytes();
            } else if (idx == 1) {
                proof.accountProof = it.next().toBytes();
            } else if (idx == 2) {
                proof.storageProofs = it.next().toBytes();
            } else {
                it.next();
            }
            idx++;
        }
        return proof;
    }

    /**
    * @dev Encodes the address `_a` as path leading to its account in the state trie
    * @return path The path in the state trie leading to the account
    */
    function encodedAddress(address _a) internal pure returns (bytes memory) {
        return triePath(abi.encodePacked(_a));
    }

    function triePath(bytes memory _key) internal pure returns (bytes memory path) {
        bytes memory hp = hex"00";
        bytes memory key = abi.encodePacked(keccak256(_key));
        path = abi.encodePacked(hp, key);
    }
}

// taken from https://github.com/KyberNetwork/peace-relay/blob/master/contracts/MerklePatriciaProof.sol
pragma solidity 0.8.9;

import "./RLPReader.sol";

library MerklePatriciaProof {

    event ReturnValue(string msg, uint num, bytes currentNode, bytes32 nodekey);

    /*
    * @dev Verifies a merkle patricia proof.
    * @param value The terminating value in the trie.
    * @param encodedPath The path in the trie leading to value.
    * @param rlpParentNodes The rlp encoded stack of nodes.
    * @param root The root hash of the trie.
    * @return The boolean validity of the proof.
    */
    function verify(bytes memory value, bytes memory encodedPath, bytes memory rlpParentNodes, bytes32 root) internal pure returns (bool) {
        RLPReader.RLPItem memory item = RLPReader.toRlpItem(rlpParentNodes);
        RLPReader.RLPItem[] memory parentNodes = RLPReader.toList(item);
        bytes memory currentNode;
        RLPReader.RLPItem[] memory currentNodeList;

        // stateRoot
        bytes32 nodeKey = root;
        uint pathPtr = 0;

        bytes memory path = _getNibbleArray(encodedPath);
        if (path.length == 0) {
            return false;
        }

        for (uint i = 0; i < parentNodes.length; i++) {
            if (pathPtr > path.length) {return false;}
            currentNode = RLPReader.toRlpBytes(parentNodes[i]);
            if (nodeKey != keccak256(currentNode)) {
                return false;}
            currentNodeList = RLPReader.toList(parentNodes[i]);

            if (currentNodeList.length == 17) {
                if (pathPtr == path.length) {
                    if (keccak256(RLPReader.toBytes(currentNodeList[16])) == keccak256(value)) {
                        return true;
                    } else {
                        return false;
                    }
                }

                uint8 nextPathNibble = uint8(path[pathPtr]);
                if (nextPathNibble > 16) { return false; }
                nodeKey = bytes32(RLPReader.toUint(currentNodeList[nextPathNibble]));
                pathPtr += 1;
            } else if (currentNodeList.length == 2) {
                pathPtr += _nibblesToTraverse(RLPReader.toBytes(currentNodeList[0]), path, pathPtr);

                if (pathPtr == path.length) {//leaf node
                    if (keccak256(RLPReader.toBytes(currentNodeList[1])) == keccak256(value)) {
                        return true;
                    } else {
                        return false;
                    }
                }

                nodeKey = bytes32(RLPReader.toUint(currentNodeList[1]));
            } else {
                return false;
            }
        }
        return false;
    }

    function _nibblesToTraverse(bytes memory encodedPartialPath, bytes memory path, uint pathPtr) private pure returns (uint) {
        uint len;
        // encodedPartialPath has elements that are each two hex characters (1 byte), but partialPath
        // and slicedPath have elements that are each one hex character (1 nibble)
        bytes memory partialPath = _getNibbleArray(encodedPartialPath);
        bytes memory slicedPath = new bytes(partialPath.length);

        // pathPtr counts nibbles in path
        // partialPath.length is a number of nibbles
        for (uint i = pathPtr; i < pathPtr + partialPath.length; i++) {
            bytes1 pathNibble = bytes1(path[i]);
            slicedPath[i - pathPtr] = pathNibble;
        }

        if (keccak256(partialPath) == keccak256(slicedPath)) {
            len = partialPath.length;
        } else {
            len = 0;
        }
        return len;
    }

    // bytes b must be hp encoded
    function _getNibbleArray(bytes memory b) private pure returns (bytes memory) {
        bytes memory nibbles;
        if (b.length > 0) {
            uint8 offset;
            uint8 hpNibble = uint8(_getNthNibbleOfBytes(0, b)[0]);
            if (hpNibble == 1 || hpNibble == 3) {
                nibbles = new bytes(b.length * 2 - 1);
                bytes memory oddNibble = _getNthNibbleOfBytes(1, b);
                nibbles[0] = oddNibble[0];
                offset = 1;
            } else {
                nibbles = new bytes(b.length * 2 - 2);
                offset = 0;
            }

            for (uint i = offset; i < nibbles.length; i++) {
                nibbles[i] = _getNthNibbleOfBytes(i - offset + 2, b)[0];
            }
        }
        return nibbles;
    }

    /*
     *This function takes in the bytes string (hp encoded) and the value of N, to return Nth Nibble.
     *@param Value of N
     *@param Bytes String
     *@return ByteString[N]
     */
    function _getNthNibbleOfBytes(uint n, bytes memory str) private pure returns (bytes memory) {
        return abi.encodePacked(n % 2 == 0 ? uint8(str[n / 2]) / 0x10 : uint8(str[n / 2]) % 0x10);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "./RelayContract.sol";
import "./GetProofLib.sol";
import "./RLPWriter.sol";
import "./RLPReader.sol";

contract ProxyContract {
    enum NodeType { BRANCH, EXTENSION, LEAF, DELETED, HASHED }
    struct NodeInfo { 
        uint mtHeight; 
    }
    event RootObtained(bytes32 root);
    event MigrationConfirmed();
    event ProofVerified();
    event RootsComputedAndVerified();

    struct BranchInfo { 
        uint generalChildAmount;
        uint oldValueIndex;
        uint unhashedValues;
        bool[16] unhashedValuePosition; 
    }
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for RLPReader.Iterator;
    using RLPReader for bytes;

    /**
    * @dev address of the deployed relay contract.
    * The address in the file is a placeholder
    */
    address internal constant RELAY_ADDRESS = 0x00FEC58b2F2EC3fF2c240646dcf361F05Afa6D14;

    /**
    * @dev address of the contract that is being mirrored.
    * The address in the file is a placeholder
    */
    address internal constant SOURCE_ADDRESS = 0xd1bA8846E2ad20173534c631D62CCDc84a1bf364;

    /**
    * @dev address of the contract that is being mirrored.
    * The address in the file is a placeholder
    */
    address internal constant LOGIC_ADDRESS = 0x5870B4aefFC207C87174246e084a781a2ad0F1ef;

    constructor() {
    }

    // constructor(address _relay, address _source, address _logic) {
    //     require(_relay != address(0), 'relay address cannot be 0');
    //     require(_source != address(0), 'source address cannot be 0');
    //     require(_logic != address(0), 'logic address cannot be 0');
    //     RELAY_ADDRESS = _relay;
    //     SOURCE_ADDRESS = _source;
    //     LOGIC_ADDRESS = _logic;
    // }

    /**
    * @dev Adds values to the storage. Used for initialization.
    * @param keys -> Array of keys for storage
    * @param values -> Array of values corresponding to the array keys.
    */
    function addStorage(bytes32[] memory keys, bytes32[] memory values) public {
        require(keys.length == values.length, 'arrays keys and values do not have the same length');
        require(!(getRelay().getMigrationState(address(this))), 'Migration is already completed');

        bytes32 key;
        bytes32 value;
        for (uint i = 0; i < keys.length; i++) {
            key = keys[i];
            value = values[i];
            assembly {
                sstore(key, value)
            }
        }
    }

    /**
    * @dev Used to access the Relay's abi
    */
    function getRelay() internal pure returns (RelayContract) {
        return RelayContract(RELAY_ADDRESS);
    }

    /**
    * @dev Used to get the relay address
    */
    function getRelayAddress() public pure returns (address) {
        return RELAY_ADDRESS;
    }

    /**
    * @dev Used to get the source address
    */
    function getSourceAddress() public pure returns (address) {
        return SOURCE_ADDRESS;
    }

    /**
    * @dev Used to get the logic address
    */
    function getLogicAddress() public pure returns (address) {
        return LOGIC_ADDRESS;
    }

    /**
  * @dev Sets the contract's storage based on the encoded storage
  * @param rlpStorageKeyProofs the rlp encoded list of storage proofs
  * @param storageHash the hash of the contract's storage
  */
    function updateStorageKeys(bytes memory rlpStorageKeyProofs, bytes32 storageHash) internal {
        RLPReader.Iterator memory it = rlpStorageKeyProofs.toRlpItem().iterator();

        while (it.hasNext()) {
            setStorageKey(it.next(), storageHash);
        }
    }

    /**
    * @dev Update a single storage key after validating against the storage key
    */
    function setStorageKey(RLPReader.RLPItem memory rlpStorageKeyProof, bytes32 storageHash) internal {
        // parse the rlp encoded storage proof
        GetProofLib.StorageProof memory proof = GetProofLib.parseStorageProof(rlpStorageKeyProof.toBytes());

        // get the path in the trie leading to the value
        bytes memory path = GetProofLib.triePath(abi.encodePacked(proof.key));

        // verify the storage proof
        require(MerklePatriciaProof.verify(
                proof.value, path, proof.proof, storageHash
            ), "Failed to verify the storage proof");

        // decode the rlp encoded value
        bytes32 value = bytes32(proof.value.toRlpItem().toUint());

        // store the value in the right slot
        bytes32 slot = proof.key;
        assembly {
            sstore(slot, value)
        }
    }

    function _beforeFallback() internal {
        address addr = address(this);
        bytes4 sig = bytes4(keccak256("emitEvent()"));
        
        bool success; 
        assembly {
            let p := mload(0x40)
            mstore(p,sig)
            success := call(950, addr, 0, p, 0x04, p, 0x00)
            mstore(0x20,add(p,0x04))
            //if eq(success, 1) { revert(0,0) }
        }
        require(!success, "only static calls are permitted");
    }

    function emitEvent() public {
        emit Illegal();
    }

    event Illegal();

    /*
     * The address of the implementation contract
     */
    function _implementation() internal pure returns (address) {
        return LOGIC_ADDRESS;
    }

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal {
        _beforeFallback();
        _delegateLogic();
    }
    
    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable {
        _fallback();
    }

    receive() external payable   {

    }
    /**
    * @dev Delegates the current call to `implementation`.
    *
    * This function does not return to its internal call site, it will return directly to the external caller.
    */
    function _delegateLogic() internal {
        // solhint-disable-next-line no-inline-assembly
        address logic = _implementation();
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), logic, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {revert(0, returndatasize())}
            default {return (0, returndatasize())}
        }
    }

    function restoreOldValueState(RLPReader.RLPItem[] memory leaf) internal view returns (bytes memory, bool) {
        RLPReader.RLPItem[] memory keys = leaf[0].toList();
        uint key = keys[0].toUint();
        bytes32 currValue;
        assembly {
            currValue := sload(key)
        }

        // If the slot was empty before, remove branch to get the old contract state
        if(currValue != 0x0) {
            // update the value and compute the new hash
            // rlp(node) = rlp[rlp(encoded Path), rlp(value)]
            bytes[] memory _list = new bytes[](2);
            _list[0] = leaf[1].toRlpBytes();

            if (uint256(currValue) > 127) {
                _list[1] = RLPWriter.encodeBytes(RLPWriter.encodeUint(uint256(currValue)));
            } else {
                _list[1] = RLPWriter.encodeUint(uint256(currValue));
            }
            
            return (RLPWriter.encodeList(_list), true);
        } else {
            return (RLPWriter.encodeUint(0), false);
        }
    }

    /**
    * @dev see https://eth.wiki/fundamentals/patricia-tree for more details
    * @param leaf the leaf itself with the responding value and key in it. We assume that the value is already loaded from storage.
    * @param nodeInfo contains current mtHeight which is needed to build the encodedPath for the leaf
    */
    // todo make this function create also branches, extensions if they were deleted?
    function restoreLeafAtPos(RLPReader.RLPItem[] memory leaf, NodeInfo memory nodeInfo) private pure returns (bytes memory hashedLeaf) {
        // build the remaining encodedPath for the leaf
        uint8 hp_encoding = 0;
        if ((nodeInfo.mtHeight % 2) == 0) {
            hp_encoding = 2;
        } else {
            hp_encoding = 3;
        }
        RLPReader.RLPItem[] memory keys = leaf[0].toList();
        bytes32 hashedKey = keccak256(keys[0].toBytes());
        bytes memory bytesHashedKey = abi.encodePacked(hashedKey);
        // leaf
        bytes memory res = new bytes(32 - (nodeInfo.mtHeight / 2) + ((nodeInfo.mtHeight + 1) % 2));
        // add hp encoding prefix
        res[0] = bytes1(hp_encoding) << 4;
        uint currPos = nodeInfo.mtHeight;
        if (hp_encoding != 2) {
            res[0] = res[0] | _getNthNibbleOfBytes(currPos, bytesHashedKey)[0];
            currPos++;
        }
        // add the rest
        for (uint k = 1; k < res.length; k++) {
            res[k] = _getNthNibbleOfBytes(currPos, bytesHashedKey)[0] << 4 | _getNthNibbleOfBytes(currPos + 1, bytesHashedKey)[0];
            currPos += 2;
        }
        bytes[] memory _list = new bytes[](2);
        _list[0] = RLPWriter.encodeBytes(res);
        // we assume that the value was already loaded from memory
        _list[1] = leaf[2].toRlpBytes();
        bytes32 listHash = keccak256(RLPWriter.encodeList(_list));
        // we return the hashed leaf
        return RLPWriter.encodeKeccak256Hash(listHash);
    }

    /**
    * @dev Does two things: Recursively updates a single proof node and returns the adjusted hash after modifying all the proof node's values
    * @dev and computes state root from adjusted Merkle Tree
    * @param rlpProofNode proof of form of:
    *        [list of common branches..last common branch,], values[0..16; LeafNode || proof node]
    */
    // todo remove redundant code of computeRoots and computeOldItem
    // todo recalculate new parent hash with given info about nodes. Currently, only root node is rehashed.
    function computeRoots(bytes memory rlpProofNode) public view returns (bytes32, bytes32) {
        // the updated reference hash
        // todo validate the new values of the new proof as well by replacing the values in the proof with the real values
        bytes32 newParentHash;
        bytes32 oldParentHash;
        NodeInfo memory nodeInfo;
        nodeInfo.mtHeight = 1;

        RLPReader.RLPItem[] memory proofNode = rlpProofNode.toRlpItem().toList();

        if (!RLPReader.isList(proofNode[1])) {
            // its only one leaf node in the tree
            (bytes memory oldValueState, bool isValue) = restoreOldValueState(proofNode);
            if (!isValue) {
                // there wasn't a value before
                oldParentHash = 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421;
            } else {
                oldParentHash = keccak256(oldValueState);
            }
            nodeInfo.mtHeight = 0;
            bytes memory newParentHashBytes = restoreLeafAtPos(proofNode, nodeInfo).toRlpItem().toBytes();
            assembly {
                newParentHash := mload(add(newParentHashBytes, 32))
            }
            return (oldParentHash, newParentHash);
        }

        // root branch with all hashed values in it
        RLPReader.RLPItem[] memory hashedValuesAtRoot = RLPReader.toList(proofNode[0]);
        // and a list of non-hashed values [0..16] for the root branch node
        RLPReader.RLPItem[] memory valuesAtRoot = RLPReader.toList(proofNode[1]);

        bytes32 encodedZero = keccak256(RLPWriter.encodeUint(0));
        if (valuesAtRoot.length == 1) {
            // todo check if there was only leaf at root before
            // its an extension
            // 1. calculate new parent hash
            bytes[] memory _list = new bytes[](2);
            for (uint j = 0; j < 2; j++) {
                _list[j] = hashedValuesAtRoot[j].toRlpBytes();
            }
            // todo use the valuesAtRoot as well
            newParentHash = keccak256(proofNode[0].toRlpBytes());

            // 2. calulate old parent hash
            RLPReader.RLPItem[] memory valueAtRoot = valuesAtRoot[0].toList();
            (bytes memory oldItem, NodeType nodeType) = computeOldItem(valueAtRoot, nodeInfo);
            if (nodeType != NodeType.HASHED) {
                if (nodeType != NodeType.DELETED) {
                    // todo: what if multiple values are not hashed?
                    // todo: set a counter of unhashed values?
                    valuesAtRoot[0] = oldItem.toRlpItem();
                    // todo: hash new node
                } else {
                    // todo: what if everything was deleted
                }
            } else {
                bytes32 oldItemHash = bytes32(oldItem.toRlpItem().toUint());
                _list[1] = RLPWriter.encodeKeccak256Hash(oldItemHash);
                oldParentHash = keccak256(RLPWriter.encodeList(_list));
            }
        } else {
            // its a branch
            bytes[] memory _newList = new bytes[](17);
            bytes[] memory _oldList = new bytes[](17);
            BranchInfo memory branchInfo;
            branchInfo.generalChildAmount = 0;
            branchInfo.oldValueIndex = 17;
            branchInfo.unhashedValues = 0;
            // loop through every value
            for (uint i = 0; i < 17; i++) {
                // get new entry for new parent hash calculation
                _newList[i] = hashedValuesAtRoot[i].toRlpBytes();
                _oldList[i] = hashedValuesAtRoot[i].toRlpBytes();
                bytes32 currEncoded = keccak256(_oldList[i]);
                if (currEncoded != encodedZero) {
                    branchInfo.generalChildAmount++;
                }

                // the value node either holds the [key, value] directly or another proofnode
                RLPReader.RLPItem[] memory valueNode = RLPReader.toList(valuesAtRoot[i]);
                if (valueNode.length == 3) {
                    // get old entry for old parent hash calculation
                    // leaf value, where the is the value of the latest branch node at index i
                    (bytes memory encodedList, bool isOldValue) = restoreOldValueState(valueNode);
                    if (isOldValue) {
                        if (currEncoded == encodedZero) {
                            branchInfo.generalChildAmount++;
                        }
                        branchInfo.oldValueIndex = i; 
                    } else {
                        branchInfo.generalChildAmount--;
                    }
                    if (encodedList.length > 32) {
                        bytes32 listHash = keccak256(encodedList);
                        _oldList[i] = RLPWriter.encodeKeccak256Hash(listHash);
                    } else {
                        _oldList[i] = encodedList;
                    }
                } else if (valueNode.length == 2) {
                    // branch or extension
                    (bytes memory oldItem, NodeType nodeType) = computeOldItem(valueNode, nodeInfo);
                    if (nodeType != NodeType.HASHED) {
                        if (nodeType == NodeType.DELETED) {
                            // node is not existent in old storage. (was just added at src contract)
                            branchInfo.generalChildAmount--;
                            if (branchInfo.oldValueIndex == i) {
                                branchInfo.oldValueIndex = 17;
                            }
                        } else {
                            // underlying node was changed and needs to be rebuild to the old way
                            // todo: what if multiple values are not hashed?
                            // todo: set an array of unhashed indexes?
                            valuesAtRoot[i] = oldItem.toRlpItem();
                        }
                    } else {
                        branchInfo.oldValueIndex = i;
                        if (currEncoded == encodedZero) {
                            branchInfo.generalChildAmount++;
                        }
                        bytes32 oldItemHash;
                        assembly {
                            oldItemHash := mload(add(oldItem, 32))
                        }
                        _oldList[i] = RLPWriter.encodeKeccak256Hash(oldItemHash);
                    }
                }
            }
            newParentHash = keccak256(RLPWriter.encodeList(_newList));
            // todo: hash all values that were not hashed yet
            if (branchInfo.generalChildAmount == 1 && branchInfo.oldValueIndex < 17) {
                // it was just one value before
                // todo: hash one value as root (branch, extension or leaf)
            } else {
                oldParentHash = keccak256(RLPWriter.encodeList(_oldList));
            }
        }

        return (oldParentHash, newParentHash);
    }

    function computeOldItem(RLPReader.RLPItem[] memory proofNode, NodeInfo memory nodeInfo) internal view returns (bytes memory oldNode, NodeType nt) {
        // the updated reference hash
        bytes32 oldParentHash;
        nodeInfo.mtHeight = nodeInfo.mtHeight + 1;
        // todo also calculate hash for newHash by hashing new values

        // root branch with all hashed values in it
        RLPReader.RLPItem[] memory hashedValuesAtNode = RLPReader.toList(proofNode[0]);
        // and a list of non-hashed values [0..16] for the root branch node
        RLPReader.RLPItem[] memory valuesAtNode = RLPReader.toList(proofNode[1]);

        bytes32 encodedZero = keccak256(RLPWriter.encodeUint(0));
        if (valuesAtNode.length == 1) {
            // its an extension
            bytes[] memory _list = new bytes[](2);
            _list[0] = hashedValuesAtNode[0].toRlpBytes();

            // calulate old parent hash
            RLPReader.RLPItem[] memory valueAtNode = valuesAtNode[0].toList();
            (bytes memory oldItem, NodeType nodeType) = computeOldItem(valueAtNode, nodeInfo);
            if (nodeType != NodeType.HASHED) {
                if (nodeType != NodeType.DELETED) {
                    // todo: what if multiple values are not hashed?
                    // todo: set a counter of unhashed values?
                    valuesAtNode[0] = oldItem.toRlpItem();
                    // todo: hash new node
                } else {
                    // todo: what if everything was deleted
                }
            } else {
                bytes32 oldItemHash;
                assembly {
                    oldItemHash := mload(add(oldItem, 32))
                }
                _list[1] = RLPWriter.encodeKeccak256Hash(oldItemHash);
                oldParentHash = keccak256(RLPWriter.encodeList(_list));
                nodeInfo.mtHeight -= 1;
                return (abi.encodePacked(oldParentHash), NodeType.HASHED);
            }
        } else {
            // its a branch
            bytes[] memory _oldList = new bytes[](17);
            BranchInfo memory branchInfo;
            branchInfo.generalChildAmount = 0;
            branchInfo.oldValueIndex = 17;
            branchInfo.unhashedValues = 0;
            // loop through every value
            for (uint i = 0; i < 17; i++) {
                _oldList[i] = hashedValuesAtNode[i].toRlpBytes();
                bytes32 currEncoded = keccak256(_oldList[i]);
                if (currEncoded != encodedZero) {
                    branchInfo.generalChildAmount++;
                    if (branchInfo.oldValueIndex == 17) {
                        branchInfo.oldValueIndex = i;
                    }
                }

                // get old entry for old parent hash calculation
                // the value node either holds the [key, value]directly or another proofnode
                RLPReader.RLPItem[] memory valueNode = RLPReader.toList(valuesAtNode[i]);
                if (valueNode.length == 3) {
                    // leaf value, where the is the value of the latest branch node at index i
                    (bytes memory encodedList, bool isOldValue) = restoreOldValueState(valueNode);
                    if (isOldValue) {
                        if (currEncoded == encodedZero) {
                            branchInfo.generalChildAmount++;
                        }
                    } else {
                        if (currEncoded != encodedZero) {
                            branchInfo.generalChildAmount--;
                            if (branchInfo.oldValueIndex == i) {
                                branchInfo.oldValueIndex = 17;
                            }
                        }
                    }
                    
                    if (encodedList.length > 32) {
                        bytes32 listHash = keccak256(encodedList);
                        _oldList[i] = RLPWriter.encodeKeccak256Hash(listHash);
                    } else {
                        _oldList[i] = encodedList;
                    }
                } else if (valueNode.length == 2) {
                    // branch or extension
                    (bytes memory oldItem, NodeType nodeType) = computeOldItem(valueNode, nodeInfo);
                    if (nodeType != NodeType.HASHED) {
                        if (nodeType == NodeType.DELETED) {
                            // todo still need to hash 0x0 at the position
                            branchInfo.generalChildAmount--;
                            if (branchInfo.oldValueIndex == i) {
                                branchInfo.oldValueIndex = 17;
                            }
                        } else if (nodeType == NodeType.LEAF) {
                            branchInfo.unhashedValues++;
                            branchInfo.oldValueIndex = i;
                            // todo: what if multiple values are not hashed?
                            // todo: set a counter of unhashed values?
                            // todo: set an array of unhashed indexes?
                            valuesAtNode[i] = oldItem.toRlpItem();
                            branchInfo.unhashedValuePosition[i] = true;
                        } else {
                            branchInfo.unhashedValues++;
                            branchInfo.oldValueIndex = i;
                            valuesAtNode[i] = oldItem.toRlpItem();
                            branchInfo.unhashedValuePosition[i] = true;
                        }
                    } else {
                        branchInfo.oldValueIndex = i;
                        if (currEncoded == encodedZero) {
                            branchInfo.generalChildAmount++;
                        }
                        bytes32 oldItemHash;
                        assembly {
                            oldItemHash := mload(add(oldItem, 32))
                        }
                        _oldList[i] = RLPWriter.encodeKeccak256Hash(oldItemHash);
                    }
                }
            }
            if (branchInfo.generalChildAmount == 1 && branchInfo.oldValueIndex < 17) {
                if (branchInfo.unhashedValues > 0) {
                    // todo check if we got unhashed from lower level
                }
                // its only one value left here.
                // this means we have to return it one level further up to be hashed there
                // it was just one value before
                nodeInfo.mtHeight -= 1;
                return (valuesAtNode[branchInfo.oldValueIndex].toRlpBytes(), NodeType.LEAF);
            } else if (branchInfo.unhashedValues > 0) {
                for (uint8 j = 0; j < 16; j++) {
                    if (branchInfo.unhashedValuePosition[j] == true) {
                        RLPReader.RLPItem[] memory node = RLPReader.toList(valuesAtNode[j]);
                        if (node.length == 2) {
                            // todo its an extension/branch
                        } else {
                            // restoring leaf at the old position
                            _oldList[j] = restoreLeafAtPos(node, nodeInfo);
                        }
                    }
                }
            }
            oldParentHash = keccak256(RLPWriter.encodeList(_oldList));
            nodeInfo.mtHeight -= 1;
            return (abi.encode(oldParentHash), NodeType.HASHED);
        }
    }

    // taken from https://github.com/KyberNetwork/peace-relay/blob/master/contracts/MerklePatriciaProof.sol
    /*
     *This function takes in the bytes string (hp encoded) and the value of N, to return Nth Nibble.
     *@param Value of N
     *@param Bytes String
     *@return ByteString[N]
     */
    function _getNthNibbleOfBytes(uint n, bytes memory str) private pure returns (bytes memory) {
        return abi.encodePacked(n % 2 == 0 ? uint8(str[n / 2]) / 0x10 : uint8(str[n / 2]) % 0x10);
    }

    /**
    * @dev Several steps happen before a storage update takes place:
    * First verify that the provided proof was obtained for the account on the source chain (account proof)
    * Secondly verify that the current value is part of the current storage root (old contract state proof)
    * Third step is verifying the provided storage proofs provided in the `proof` (new contract state proof)
    * @param proof The rlp encoded optimized proof
    */
    function updateStorage(bytes memory proof) public {
        // First verify stateRoot -> account (account proof)
        RelayContract relay = getRelay();
        require(relay.getMigrationState(address(this)), 'migration not completed');
        emit MigrationConfirmed();

        // get the current state root of the source chain
        bytes32 root = relay.getStateRootDendreth();
        emit RootObtained(root);
        // validate that the proof was obtained for the source contract and the account's storage is part of the current state
        bytes memory path = GetProofLib.encodedAddress(SOURCE_ADDRESS);

        GetProofLib.GetProof memory getProof = GetProofLib.parseProof(proof);
        require(GetProofLib.verifyProof(getProof.account, getProof.accountProof, path, root), "Failed to verify the account proof");

        emit ProofVerified();
        GetProofLib.Account memory account = GetProofLib.parseAccount(getProof.account);

        bytes32 lastValidParentHash = getRelay().getStorageRoot();

        (bytes32 oldParentHash, bytes32 newParentHash) = computeRoots(getProof.storageProofs);

        // Second verify proof would map to current state by replacing values with current values (old contract state proof)
        require(lastValidParentHash == oldParentHash, "Failed to verify old contract state proof");

        // Third verify proof is valid according to current block in relay contract
        require(newParentHash == account.storageHash, "Failed to verify new contract state proof");
        emit RootsComputedAndVerified();
        // update the storage or revert on error
        setStorageValues(getProof.storageProofs);

        // update the state in the relay
        relay.updateProxyInfoLatest(account.storageHash);
    }
    
    function updateStorageModified(bytes memory proof, uint blockNumber) public {
        // First verify stateRoot -> account (account proof)
        RelayContract relay = getRelay();
        require(relay.getMigrationState(address(this)), 'migration not completed');
        
        // get the current state root of the source chain
        bytes32 root = relay.getStateRootDendreth();
        // validate that the proof was obtained for the source contract and the account's storage is part of the current state
        bytes memory path = GetProofLib.encodedAddress(SOURCE_ADDRESS);

        GetProofLib.GetProof memory getProof = GetProofLib.parseProof(proof);
        require(GetProofLib.verifyProof(getProof.account, getProof.accountProof, path, root), "Failed to verify the account proof");

        GetProofLib.Account memory account = GetProofLib.parseAccount(getProof.account);

        bytes32 lastValidParentHash = getRelay().getStorageRoot();

        (bytes32 oldParentHash, bytes32 newParentHash) = computeRoots(getProof.storageProofs);

        // Second verify proof would map to current state by replacing values with current values (old contract state proof)
        require(lastValidParentHash == oldParentHash, "Failed to verify old contract state proof");

        // Third verify proof is valid according to current block in relay contract
        require(newParentHash == account.storageHash, "Failed to verify new contract state proof");

        // update the storage or revert on error
        setStorageValues(getProof.storageProofs);

        // update the state in the relay
        relay.updateProxyInfo(account.storageHash, blockNumber);
    }

    function updateStorageValue(RLPReader.RLPItem[] memory valueNode) internal {
        // leaf value, where the is the value of the latest branch node at index i
        uint byte0;
        bytes32 value;
        uint memPtr = valueNode[2].memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 > 127) {
            // leaf is double encoded when greater than 127
            valueNode[2].memPtr += 1;
            valueNode[2].len -= 1;
            value = bytes32(valueNode[2].toUint());
        } else {
            value = bytes32(byte0);
        }
        RLPReader.RLPItem[] memory keys = valueNode[0].toList();
        bytes32 slot = bytes32(keys[0].toUint());
        assembly {
            sstore(slot, value)
        }
    }

    /**
    * @dev Recursively set contract's storage based on the provided proof nodes
    * @param rlpProofNode the rlp encoded storage proof nodes, starting with the root node
    */
    function setStorageValues(bytes memory rlpProofNode) internal {
        RLPReader.RLPItem[] memory proofNode = rlpProofNode.toRlpItem().toList();

        if (RLPReader.isList(proofNode[1])) {
            RLPReader.RLPItem[] memory valuesAtNode = RLPReader.toList(proofNode[1]);
            if (valuesAtNode.length == 1) {
                // its an extension
                setStorageValues(valuesAtNode[0].toRlpBytes());
            } else {
                // its a branch
                // and a list of values [0..16] for the last branch node
                // loop through every value
                for (uint i = 0; i < 17; i++) {
                    // the value node either holds the [key, value]directly or another proofnode
                    RLPReader.RLPItem[] memory valueNode = RLPReader.toList(valuesAtNode[i]);
                    if (valueNode.length == 3) {
                        updateStorageValue(valueNode);
                    } else if (valueNode.length == 2) {
                        setStorageValues(valuesAtNode[i].toRlpBytes());
                    }
                }
            }
        } else {
            // its only one value
            updateStorageValue(proofNode);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
* @author Hamdi Allam [email protected]
* Please reach out with any questions or concerns
*/
pragma solidity 0.8.9;

library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START  = 0xb8;
    uint8 constant LIST_SHORT_START   = 0xc0;
    uint8 constant LIST_LONG_START    = 0xf8;
    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint len;
        uint memPtr;
    }

    struct Iterator {
        RLPItem item;   // Item that's being iterated over.
        uint nextPtr;   // Position of the next item in the list.
    }

    /*
    * @dev Returns the next element in the iteration. Reverts if it has not next element.
    * @param self The iterator.
    * @return The next element in the iteration.
    */
    function next(Iterator memory self) internal pure returns (RLPItem memory) {
        require(hasNext(self));

        uint ptr = self.nextPtr;
        uint itemLength = _itemLength(ptr);
        self.nextPtr = ptr + itemLength;

        return RLPItem(itemLength, ptr);
    }

    /*
    * @dev Returns true if the iteration has more elements.
    * @param self The iterator.
    * @return true if the iteration has more elements.
    */
    function hasNext(Iterator memory self) internal pure returns (bool) {
        RLPItem memory item = self.item;
        return self.nextPtr < item.memPtr + item.len;
    }

    /*
    * @param item RLP encoded bytes
    */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        uint memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
    * @dev Create an iterator. Reverts if item is not a list.
    * @param self The RLP item.
    * @return An 'Iterator' over the item.
    */
    function iterator(RLPItem memory self) internal pure returns (Iterator memory) {
        require(isList(self));

        uint ptr = self.memPtr + _payloadOffset(self.memPtr);
        return Iterator(self, ptr);
    }

    /*
    * @param the RLP item.
    */
    function rlpLen(RLPItem memory item) internal pure returns (uint) {
        return item.len;
    }

    /*
     * @param the RLP item.
     * @return (memPtr, len) pair: location of the item's payload in memory.
     */
    function payloadLocation(RLPItem memory item) internal pure returns (uint, uint) {
        uint offset = _payloadOffset(item.memPtr);
        uint memPtr = item.memPtr + offset;
        uint len = item.len - offset; // data length
        return (memPtr, len);
    }

    /*
    * @param the RLP item.
    */
    function payloadLen(RLPItem memory item) internal pure returns (uint) {
        (, uint len) = payloadLocation(item);
        return len;
    }

    /*
    * @param the RLP item containing the encoded list.
    */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
        require(isList(item));

        uint items = numItems(item);
        RLPItem[] memory result = new RLPItem[](items);

        uint memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint dataLen;
        for (uint i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr); 
            memPtr = memPtr + dataLen;
        }

        return result;
    }

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        if (item.len == 0) return false;

        uint8 byte0;
        uint memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START)
            return false;
        return true;
    }

    /*
     * @dev A cheaper version of keccak256(toRlpBytes(item)) that avoids copying memory.
     * @return keccak256 hash of RLP encoded bytes.
     */
    function rlpBytesKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        uint256 ptr = item.memPtr;
        uint256 len = item.len;
        bytes32 result;
        assembly {
            result := keccak256(ptr, len)
        }
        return result;
    }

    /*
     * @dev A cheaper version of keccak256(toBytes(item)) that avoids copying memory.
     * @return keccak256 hash of the item payload.
     */
    function payloadKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        (uint memPtr, uint len) = payloadLocation(item);
        bytes32 result;
        assembly {
            result := keccak256(memPtr, len)
        }
        return result;
    }

    /** RLPItem conversions into data types **/

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;
        
        uint ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    // any non-zero byte except "0x80" is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1);
        uint result;
        uint memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        // SEE Github Issue #5.
        // Summary: Most commonly used RLP libraries (i.e Geth) will encode
        // "0" as "0x80" instead of as "0". We handle this edge case explicitly
        // here.
        if (result == 0 || result == STRING_SHORT_START) {
            return false;
        } else {
            return true;
        }
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix
        uint256 intValue = toUint(item);
    return address(uint160(intValue));
    }

    function toUint(RLPItem memory item) internal pure returns (uint) {
        require(item.len > 0 && item.len <= 33);

        (uint memPtr, uint len) = payloadLocation(item);

        uint result;
        assembly {
            result := mload(memPtr)

            // shfit to the correct location if neccesary
            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
        }

        return result;
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint) {
        // one byte prefix
        require(item.len == 33);

        uint result;
        uint memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0);

        (uint memPtr, uint len) = payloadLocation(item);
        bytes memory result = new bytes(len);

        uint destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(memPtr, destPtr, len);
        return result;
    }

    /*
    * Private Helpers
    */

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) private pure returns (uint) {
        if (item.len == 0) return 0;

        uint count = 0;
        uint currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
           currPtr = currPtr + _itemLength(currPtr); // skip over an item
           count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint memPtr) private pure returns (uint) {
        uint itemLen;
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START)
            itemLen = 1;
        
        else if (byte0 < STRING_LONG_START)
            itemLen = byte0 - STRING_SHORT_START + 1;

        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte
                
                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        } 

        else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint memPtr) private pure returns (uint) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) 
            return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START))
            return 1;
        else if (byte0 < LIST_SHORT_START)  // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        else
            return byte0 - (LIST_LONG_START - 1) + 1;
    }

    /*
    * @param src Pointer to source
    * @param dest Pointer to destination
    * @param len Amount of memory to copy from the source
    */
    function copy(uint src, uint dest, uint len) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        if (len > 0) {
            // left over bytes. Mask is used to remove unwanted bytes from the word
            uint mask = 256 ** (WORD_SIZE - len) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask)) // zero out src
                let destpart := and(mload(dest), mask) // retrieve the bytes
                mstore(dest, or(destpart, srcpart))
            }
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

/**
 * @title RLPWriter
 * @dev helper functions to rlp-encode items
 * @notice adapted from https://github.com/bakaoh/solidity-rlp-encode/blob/master/contracts/RLPEncode.sol
 */
library RLPWriter {


    /**
    * @dev RLP encodes a series of bytes.
    * @param _item The bytes to encode.
    * @return The RLP encoded bytes.
    */
    function encodeBytes(bytes memory _item) internal pure returns (bytes memory) {
        bytes memory encoded;
        if (_item.length == 1 && uint8(_item[0]) <= 128) {
            encoded = _item;
        } else {
            encoded = concat(encodeLength(_item.length, 128), _item);
        }
        return encoded;
    }

    /**
     * @dev RLP encodes a list of RLP encoded byte byte strings.
     * @param _list The list of RLP encoded byte strings.
     * @return The RLP encoded list of items in bytes.
     */
    function encodeList(bytes[] memory _list) internal pure returns (bytes memory) {
        bytes memory list = flatten(_list);
        return concat(encodeLength(list.length, 192), list);
    }

    /**
    * @dev Encode the first byte, followed by the `len` in binary form if `length` is more than 55.
    * @param len The length of the string or the payload.
    * @param offset 128 if item is string, 192 if item is list.
    * @return RLP encoded bytes.
    */
    function encodeLength(uint len, uint offset) private pure returns (bytes memory) {
        bytes memory encoded;
        if (len < 56) {
            encoded = new bytes(1);
            encoded[0] = bytes32(len + offset)[31];
        } else {
            uint lenLen;
            uint i = 1;
            while (len / i != 0) {
                lenLen++;
                i *= 256;
            }

            encoded = new bytes(lenLen + 1);
            encoded[0] = bytes32(lenLen + offset + 55)[31];
            for (i = 1; i <= lenLen; i++) {
                encoded[i] = bytes32((len / (256 ** (lenLen - i))) % 256)[31];
            }
        }
        return encoded;
    }

    /**
    * @dev RLP encodes a uint.
    * @param self The uint to encode.
    * @return The RLP encoded uint in bytes.
    */
    function encodeUint(uint self) internal pure returns (bytes memory) {
        return encodeBytes(toBinary(self));
    }

    /**
    * @dev Encodes a keccak256 hash value
    * @param _hash The hash to encode.
    * @return The RLP encoded hash in bytes
    */
    function encodeKeccak256Hash(bytes32 _hash) internal pure returns (bytes memory) {
        bytes memory hashBytes = new bytes(32);
        assembly {
            mstore(add(hashBytes, 32), _hash)
        }
        return encodeBytes(hashBytes);
    }

    /**
    * @dev Encode integer in big endian binary form with no leading zeroes.
    * @notice TODO: This should be optimized with assembly to save gas costs.
    * @param _x The integer to encode.
    * @return RLP encoded bytes.
    */
    function toBinary(uint _x) internal pure returns (bytes memory) {
        bytes memory b = new bytes(32);
        assembly {
            mstore(add(b, 32), _x)
        }
        uint i;
        for (i = 0; i < 32; i++) {
            if (b[i] != 0) {
                break;
            }
        }
        bytes memory res = new bytes(32 - i);
        for (uint j = 0; j < res.length; j++) {
            res[j] = b[i++];
        }
        return res;
    }

    /**
 * @dev Copies a piece of memory to another location.
 * @notice From: https://github.com/Arachnid/solidity-stringutils/blob/master/src/strings.sol.
 * @param _dest Destination location.
 * @param _src Source location.
 * @param _len Length of memory to copy.
 */
    function _copy(uint _dest, uint _src, uint _len) private pure {
        uint dest = _dest;
        uint src = _src;
        uint len = _len;

        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /**
    * @dev Flattens a list of byte strings into one byte string.
    * @notice From: https://github.com/sammayo/solidity-rlp-encoder/blob/master/RLPEncode.sol.
    * @param _list List of byte strings to flatten.
    * @return The flattened byte string.
    */
    function flatten(bytes[] memory _list) private pure returns (bytes memory) {
        if (_list.length == 0) {
            return new bytes(0);
        }

        uint len;
        uint i;
        for (i = 0; i < _list.length; i++) {
            len += _list[i].length;
        }

        bytes memory flattened = new bytes(len);
        uint flattenedPtr;
        assembly {flattenedPtr := add(flattened, 0x20)}

        for (i = 0; i < _list.length; i++) {
            bytes memory item = _list[i];

            uint listPtr;
            assembly {listPtr := add(item, 0x20)}

            _copy(flattenedPtr, listPtr, item.length);
            flattenedPtr += _list[i].length;
        }

        return flattened;
    }

    /**
   * @dev Concatenates two bytes.
   * @notice From: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol.
   * @param _preBytes First byte string.
   * @param _postBytes Second byte string.
   * @return Both byte string combined.
   */
    function concat(bytes memory _preBytes, bytes memory _postBytes) private pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            tempBytes := mload(0x40)

            let length := mload(_preBytes)
            mstore(tempBytes, length)

            let mc := add(tempBytes, 0x20)
            let end := add(mc, length)

            for {
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            mc := end
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            mstore(0x40, and(
            add(add(end, iszero(add(length, mload(_preBytes)))), 31),
            not(31)
            ))
        }
        return tempBytes;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import './ProxyContract.sol';
import './GetProofLib.sol';
import {BeaconLightClient} from 'DendrETH/truth/eth/BeaconLightClient.sol';

contract RelayContract {
    event CompareStorageRoots (bytes32 srcAccountHash, bytes32 proxyAccountHash);
    struct ProxyContractInfo {
        // The root of storage trie of the contract.
        bytes32 storageRoot;
        // State of migration if successfull or not
        bool migrationState;
        // block number of the src contract it is currently synched with
        uint blockNumber;
    }

    mapping(address => ProxyContractInfo) proxyStorageInfos;
    mapping(uint => bytes32) srcContractStateRoots;
    uint latestBlockNr;
    uint latestDendrethBlockNr;

    // DendrETH instance deployed on Mumbai targeting Goerli
    address internal constant DENDRETH_INSTANCE = 0xA3418F79c98A3E496A5E97610a97f82daE364619;
    constructor() {
    }

    function getDendrETH() public pure returns (address) {
        return DENDRETH_INSTANCE;
    }

    /**
     * @dev Called by the proxy to update its state, only after migrationState validation
     */
    function updateProxyInfo(bytes32 _newStorage, uint _blockNumber) public {
        require(proxyStorageInfos[msg.sender].blockNumber < _blockNumber);
        proxyStorageInfos[msg.sender].storageRoot = _newStorage;
        proxyStorageInfos[msg.sender].migrationState = true;
        proxyStorageInfos[msg.sender].blockNumber = _blockNumber;
    }
    function updateProxyInfoLatest(bytes32 _newStorage) public {
        require(proxyStorageInfos[msg.sender].blockNumber < latestBlockNr);
        proxyStorageInfos[msg.sender].storageRoot = _newStorage;
        proxyStorageInfos[msg.sender].migrationState = true;
        proxyStorageInfos[msg.sender].blockNumber = latestBlockNr;
    }

    function addBlock(bytes32 _stateRoot, uint256 _blockNumber) public {
        srcContractStateRoots[_blockNumber] = _stateRoot;
        if (_blockNumber > latestBlockNr) latestBlockNr = _blockNumber;
    }

    function addBlockDendreth(uint256 _blockNumber) public {
        BeaconLightClient beacon = BeaconLightClient(DENDRETH_INSTANCE);
        bytes32 stateRoot = beacon.finalized_header_root();
        srcContractStateRoots[_blockNumber] = stateRoot;
        if (_blockNumber > latestBlockNr) latestBlockNr = _blockNumber;
    }

    /**
    * @dev return state root at the respective blockNumber
    */
    function getStateRoot(uint _blockNumber) public view returns (bytes32) {
        return srcContractStateRoots[_blockNumber];
    }
    
    
    function getLatestStateRoot() public view returns (bytes32) {
        return srcContractStateRoots[latestBlockNr];
    }

    function getStateRootDendreth() public view returns (bytes32) {
        BeaconLightClient beacon = BeaconLightClient(DENDRETH_INSTANCE);
        return beacon.finalized_header_root();
    }


    /**
    * @dev return the calling contract's storage root (only correct if stored by the contract before only!)
    */
    function getStorageRoot() public view returns (bytes32) {
        return proxyStorageInfos[msg.sender].storageRoot;
    }

    /**
    * @dev return migration state of passed proxy contract
    * @param _contractAddress address of proxy contract 
    */
    function getMigrationState(address _contractAddress) public view returns (bool) {
        return proxyStorageInfos[_contractAddress].migrationState;
    }

    /**
    * @dev return current synched block number of src chain from proxy contract
    * @param _proxyContractAddress address of proxy contract 
    */
    function getCurrentBlockNumber(address _proxyContractAddress) public view returns (uint) {
        return proxyStorageInfos[_proxyContractAddress].blockNumber;
    }

    function getLatestBlockNumber() public view returns (uint) {
        return latestBlockNr;
    }
    function getLatestDendrethBlockNumber() public view returns (uint) {
        return latestDendrethBlockNr;
    }

    function setLatestDendrethBlockNumber(uint number) public {
        latestDendrethBlockNr = number;
    }
    /**
    * @dev Used to access the Proxy's abi
    */
    function getProxy(address payable proxyAddress) internal pure returns (ProxyContract) {
        return ProxyContract(proxyAddress);
    }

    /**
    * @dev checks if the migration of the source contract to the proxy contract was successful
    * @param sourceAccountProof contains source contract account information and the merkle patricia proof of the account
    * @param proxyAccountProof contains proxy contract account information and the merkle patricia proof of the account
    * @param proxyChainBlockHeader latest block header of the proxy contract's chain
    * @param proxyAddress address from proxy contract
    * @param proxyChainBlockNumber block number from the proxy chain block header, this is needed because the blockNumber in the header is a hex string
    * @param srcChainBlockNumber block number from the src chain from which we take the stateRoot from the srcContract
    */
    function verifyMigrateContract(bytes memory sourceAccountProof, bytes memory proxyAccountProof, bytes memory proxyChainBlockHeader, address payable proxyAddress, uint proxyChainBlockNumber, uint srcChainBlockNumber) public {
        GetProofLib.BlockHeader memory blockHeader = GetProofLib.parseBlockHeader(proxyChainBlockHeader);

        // compare block header hashes
        bytes32 givenBlockHeaderHash = keccak256(proxyChainBlockHeader);
        bytes32 actualBlockHeaderHash = blockhash(proxyChainBlockNumber);
        require(givenBlockHeaderHash == actualBlockHeaderHash, 'Given proxy chain block header is faulty');

        bytes32 root = srcContractStateRoots[srcChainBlockNumber];
        
        // todo replace with dendreth
        // bytes32 root = getStateRootDendreth();

        // verify sourceAccountProof
        // validate that the proof was obtained for the source contract and the account's storage is part of the current state
        ProxyContract proxyContract = getProxy(proxyAddress);
        address sourceAddress = proxyContract.getSourceAddress();
        bytes memory path = GetProofLib.encodedAddress(sourceAddress);
        GetProofLib.GetProof memory getProof = GetProofLib.parseProof(sourceAccountProof);
        require(GetProofLib.verifyProof(getProof.account, getProof.accountProof, path, root), "Failed to verify the source account proof");
        GetProofLib.Account memory sourceAccount = GetProofLib.parseAccount(getProof.account);

        // verify proxyAccountProof
        // validate that the proof was obtained for the source contract and the account's storage is part of the current state
        path = GetProofLib.encodedAddress(proxyAddress);
        getProof = GetProofLib.parseProof(proxyAccountProof);
        require(GetProofLib.verifyProof(getProof.account, getProof.accountProof, path, blockHeader.storageRoot), "Failed to verify the proxy account proof");
        GetProofLib.Account memory proxyAccount = GetProofLib.parseAccount(getProof.account);

        emit CompareStorageRoots(sourceAccount.storageHash,proxyAccount.storageHash);

        // compare storageRootHashes
        require(sourceAccount.storageHash == proxyAccount.storageHash, 'storageHashes of the contracts dont match');

        // update proxy info -> complete migration
        proxyStorageInfos[proxyAddress].storageRoot = proxyAccount.storageHash;
        proxyStorageInfos[proxyAddress].migrationState = true;
        proxyStorageInfos[proxyAddress].blockNumber = srcChainBlockNumber;
    }
    function verifyMigrateContractOriginal(bytes memory sourceAccountProof, bytes memory proxyAccountProof, bytes memory proxyChainBlockHeader, address payable proxyAddress, uint proxyChainBlockNumber, uint srcChainBlockNumber) public {
        GetProofLib.BlockHeader memory blockHeader = GetProofLib.parseBlockHeader(proxyChainBlockHeader);

        // compare block header hashes
        bytes32 givenBlockHeaderHash = keccak256(proxyChainBlockHeader);
        bytes32 actualBlockHeaderHash = blockhash(proxyChainBlockNumber);
        require(givenBlockHeaderHash == actualBlockHeaderHash, 'Given proxy chain block header is faulty');

        // verify sourceAccountProof
        // validate that the proof was obtained for the source contract and the account's storage is part of the current state
        ProxyContract proxyContract = getProxy(proxyAddress);
        address sourceAddress = proxyContract.getSourceAddress();
        bytes memory path = GetProofLib.encodedAddress(sourceAddress);
        GetProofLib.GetProof memory getProof = GetProofLib.parseProof(sourceAccountProof);
        require(GetProofLib.verifyProof(getProof.account, getProof.accountProof, path, srcContractStateRoots[srcChainBlockNumber]), "Failed to verify the source account proof");
        GetProofLib.Account memory sourceAccount = GetProofLib.parseAccount(getProof.account);

        // verify proxyAccountProof
        // validate that the proof was obtained for the source contract and the account's storage is part of the current state
        path = GetProofLib.encodedAddress(proxyAddress);
        getProof = GetProofLib.parseProof(proxyAccountProof);
        require(GetProofLib.verifyProof(getProof.account, getProof.accountProof, path, blockHeader.storageRoot), "Failed to verify the proxy account proof");
        GetProofLib.Account memory proxyAccount = GetProofLib.parseAccount(getProof.account);

        emit CompareStorageRoots(sourceAccount.storageHash,proxyAccount.storageHash);

        // compare storageRootHashes
        require(sourceAccount.storageHash == proxyAccount.storageHash, 'storageHashes of the contracts dont match');

        // update proxy info -> complete migration
        proxyStorageInfos[proxyAddress].storageRoot = proxyAccount.storageHash;
        proxyStorageInfos[proxyAddress].migrationState = true;
        proxyStorageInfos[proxyAddress].blockNumber = srcChainBlockNumber;
    }
}