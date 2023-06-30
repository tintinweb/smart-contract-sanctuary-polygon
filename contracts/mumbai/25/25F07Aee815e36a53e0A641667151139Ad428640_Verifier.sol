/**
 *Submitted for verification at polygonscan.com on 2023-06-29
*/

// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
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
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x00b1780b54b950212ceb3edb6a04fee16fbb81564100f07eb9b264a8b40c4564), uint256(0x293ee6829fb35559ce97e972327f0a0cac40763a579ffde3f72de859c8a73474));
        vk.beta = Pairing.G2Point([uint256(0x104a0858d3a1adc25738ec9d9bc5a139ab9369b5c6e4dc1f7fb2449f10638601), uint256(0x033272e708c48d31c927be25099a544dc51f0e1d143dce48d27bf6196fa92cfe)], [uint256(0x090bc43588f2b781fe1a1917193a313335e85176282bcbd269dcebf95ad32525), uint256(0x1ddca2c946eb1a266c2d66c69323b05367550c8a674ace15e62819c0e92f8aa3)]);
        vk.gamma = Pairing.G2Point([uint256(0x040ec3be7f4f0a21e14a24e737bf1886a71aaa8dc44c1701559fac4eadb565d7), uint256(0x2d9fbb0466e9babb65c803aea95291c91b679a3dcc1291dce33895eddba7a889)], [uint256(0x07112b6d8d6403fae646e50c87268dc3c6a6d4c7b01a83efc46e9ffee9522b67), uint256(0x19eb4f539fd9a38b15fe87225a54c2a281b22a831c552e555925672a79d64d45)]);
        vk.delta = Pairing.G2Point([uint256(0x188423a4d3f9eb2da99929bad5e43d0132807596494625efe5a3559a82dc9649), uint256(0x08cdff6d5d47b3fbaed976426cc32f90888273fd6e34e8fa7afd894ca5fc9657)], [uint256(0x2dc340bf0cfc3fe00c0abd3d561f350571fb4bb159b2272cffbc9d02bd24b5d8), uint256(0x208e19a0a4ee3504e8e11afbd14d25715f726f6d87d6af7de0a037f1135e61d9)]);
        vk.gamma_abc = new Pairing.G1Point[](11);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x146ec86f5af2fdbc4f11f3a1450e0bc6ad75a134ad60c56ed5aa15bc234aa087), uint256(0x0c5a8e428e4719c51e3157718c749707d5943839e57af6bfa2ef4474b62b9557));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x177ffbd891029247e8dc8f32a4499ab7047128c63595ed010fa4ebf22a2d70b4), uint256(0x26a8596ec3b1b3d5b4ad4574f7fe95c2ed19bd206cf474dd16eb528d271a7d2f));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x2a6c77a6174e841c04ad5775400400f25d8f04c8dcd7748fa47a660bbd039623), uint256(0x1430edf5bf0f509f1684d48c787d5419875af4272d62732c3c5d7e51f91972e9));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x1645e96d2f72d9395f24e9faa0477c0fda03642d1bfd2394a4fb9d70b50bf95e), uint256(0x0750146a227a3df3cf526461c8864f1a9690e347a9979b4147b7e31d736ad928));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x1a3c601603ec242a86f7cf3601b8770ada5acd56a5ec3ed4797684fd560270a9), uint256(0x1c5bff4ca749766f84f483ebc4abeb73f80d2dffcbccb9bbbb72315d3f1dd6d2));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x0e123b29e91ad2b9c127ce45a417d3de5639ed390e54c2d36bf38eead8a2d274), uint256(0x0197409c49b717371796ec6a96b972a72bb51b9dc34f4855c0c3738be71b8853));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x0a9feff1297bd1136037b31f03035e087e6227abc94cd8c709b725901c6c7a38), uint256(0x05410b3d13382b23cf09ce637a7e9d92efd7ba6b40809320f62b9f3cb35dfc41));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x2c5e703e4382fd5b4bad99a613612b68fc9a65a7e9b2494e68a38e65c36ebf55), uint256(0x061f185a39903e870d2943880bb0981026f7d3561a44f24d8b63e08d85d6d4fa));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x2eb74983afc4913b7c4bd4447d0b780d87fc5ec148cd198ef9bf483d0c5282ce), uint256(0x27a8c356e4c1cd34de95ba396425ef42503782b6f6cabac5a6df3d8c97bcce60));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x071c280daef9d998056b005b66ed6bc618c184a11fe4fb58c055e5a5a8aae601), uint256(0x0062b6bb33d9eab9c601094e8f7eea1b14840b6a931229369eca42b707dae5ca));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x1401f4a8a5beabea618f574f6b03305d20f97e76430852779bdcd7451d911ec9), uint256(0x1f0cc174c9f06a01b5215e3ce387c96f0958ad81aff47b85dd3b431a767887a2));
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
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
    function verifyTx(
            Proof memory proof, uint[10] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](10);
        
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}