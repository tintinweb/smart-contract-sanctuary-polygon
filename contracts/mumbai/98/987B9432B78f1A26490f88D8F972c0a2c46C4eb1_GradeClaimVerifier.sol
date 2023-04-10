//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/IGradeClaimVerifier.sol";

/// @title GradeClaimVerifier contract interface.
contract GradeClaimVerifier is IGradeClaimVerifier {
    using PairingLib for *;

    function verificationKey() internal pure returns (VerificationKey memory vk) {
        vk.alfa1 = PairingLib.G1Point(
        20491192805390485299153009773594534940189261866228447918068658471970481763042,
        9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = PairingLib.G2Point(
        [4252822878758300859123897981450591353533073413197771768651442665752259397132, 6375614351688725206403948262868962793625744043794305715222011528459656738731],
        [21847035105528745403288232691147584728191162732299865338377159692350059136679, 10505242626370262277552901082094356697409835680220590971873171140371331206856]
        );

        vk.gamma2 = PairingLib.G2Point(
        [11559732032986387107991004021392285783925812861821192530917403151452391805634, 10857046999023057135944570762232829481370756359578518086990519993285655852781],
        [4082367875863433681332203403145435568316851327593401208105741076214120093531, 8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );

        vk.delta2 = PairingLib.G2Point(
        [15910178723148358321363136113167011794832474507169662942681201201555078058358, 728295065907376479109860482420819092339933338424947255962922916389799410790],
        [7784006571998466095853268965264259942918795401698842518913760698714856938458, 17464920296666305438909488434645178837149497502495746541808161488102524431655]
        );

        vk.IC = new PairingLib.G1Point[](6);

    
        vk.IC[0] = PairingLib.G1Point(
            7362496364801315793696184153843974232951852611078885917932810756595301318698,
            21237922218630797152846006696319711665046164136786472140390119679725729865952
        );
        
        vk.IC[1] = PairingLib.G1Point(
            13160731461514665735531520409871883880619184838963515578483758508212686635370,
            21863220708116381108581729631571365487158136032768820412867363877305987416056
        );
        
        vk.IC[2] = PairingLib.G1Point(
            11546573965455705619096759290452233223349603526798277541743654194295066522329,
            13777640051972569642512234119683083448521223261192914142156221405927871843364
        );
        
        vk.IC[3] = PairingLib.G1Point(
            1680409684039837936459027540326362303722708692596813423118296130995776129830,
            2260054383516502283255822072532283655052015967094688986357172706285492267322
        );
        
        vk.IC[4] = PairingLib.G1Point(
            584044972401202003497156066828404909552959415589458861231385585780127624581,
            9919599790152630969993358862530562066842214089708433772487077577479760794697
        );
        
        vk.IC[5] = PairingLib.G1Point(
            11748668666887051675517770518129807684287931148982438320930570818592049508637,
            16698714620526868189501703908023802811240628598013600714013031099326440255270
        );
    }

    function verify(uint[5] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerificationKey memory vk = verificationKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        PairingLib.G1Point memory vk_x = PairingLib.G1Point(0, 0);
        for (uint i = 0; i < input.length; ) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = PairingLib.addition(vk_x, PairingLib.scalar_mul(vk.IC[i + 1], input[i]));
        
            unchecked {
                ++i;
            }
        }
        vk_x = PairingLib.addition(vk_x, vk.IC[0]);
        if (!PairingLib.pairingProd4(
            PairingLib.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }

    function verifyProof(
        uint256 gradeTreeRoot,
        uint256 nullifierHash,
        uint256 gradeThreshold,
        uint256 signal,
        uint256 externalNullifier,
        uint256[8] calldata _proof,
        uint256 /* merkleTreeDepth */
    ) external view override {
        signal = _hash(signal);
        externalNullifier = _hash(externalNullifier);

        // If the values are not in the correct range, the PairingLib contract will revert.
        Proof memory proof;
        proof.A = PairingLib.G1Point(_proof[0], _proof[1]);
        proof.B = PairingLib.G2Point([_proof[2], _proof[3]], [_proof[4], _proof[5]]);
        proof.C = PairingLib.G1Point(_proof[6], _proof[7]);

        if (verify([gradeTreeRoot, nullifierHash, gradeThreshold, signal, externalNullifier], proof) != 0) {
            revert InvalidProof();
        }
    }

    /// @dev Creates a keccak256 hash of a message compatible with the SNARK scalar modulus.
    /// @param message: Message to be hashed.
    /// @return Message digest.
    function _hash(uint256 message) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(message))) >> 8;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../libs/PairingLib.sol";

/// @title GradeClaimVerifier contract interface.
interface IGradeClaimVerifier {
    error InvalidProof();

    struct VerificationKey {
        PairingLib.G1Point alfa1;
        PairingLib.G2Point beta2;
        PairingLib.G2Point gamma2;
        PairingLib.G2Point delta2;
        PairingLib.G1Point[] IC;
    }

    struct Proof {
        PairingLib.G1Point A;
        PairingLib.G2Point B;
        PairingLib.G1Point C;
    }

    /// @dev Verifies whether a Semaphore proof is valid.
    /// @param gradeTreeRoot: Root of the grade tree.
    /// @param nullifierHash: Nullifier hash.
    /// @param signal: Semaphore signal.
    /// @param gradeThreshold: Proved lower bound for the user's grade. 
    /// @param externalNullifier: External nullifier.
    /// @param proof: Zero-knowledge proof.
    /// @param merkleTreeDepth: Depth of the tree.
    function verifyProof(
        uint256 gradeTreeRoot,
        uint256 nullifierHash,
        uint256 gradeThreshold,
        uint256 signal,
        uint256 externalNullifier,
        uint256[8] calldata proof,
        uint256 merkleTreeDepth
    ) external view;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

library PairingLib {
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
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
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
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
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

// TODO update to new Semaphore verifier:
// https://github.com/semaphore-protocol/semaphore/pull/96
// by using the following template:
// https://github.com/semaphore-protocol/semaphore/blob/main/packages/contracts/snarkjs-templates/verifier_groth16.sol.ejs