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
        vk.alpha = Pairing.G1Point(uint256(0x231bc15b0f2a893326c0dd86780d21d0fa7e1db7112ba93117a531b4ba67bf54), uint256(0x2b7df7b89eb675b062198435d8623ccf0645351b0f14163b633b38f16a344975));
        vk.beta = Pairing.G2Point([uint256(0x1fd2864777315651a4561f9e5092c8bf3b16f9359192129667bf65be8ebb830a), uint256(0x13fd62d40c548f93f6f5aeb157e656eeed9a6ae89fe6884457a6892e7226e04d)], [uint256(0x04c6a61cbb3834a1bc44be92afaa0dda90ab5e8c25374e1e8d8b1bbf73d446cf), uint256(0x1e6eaedfd51c9cbab0335c80e55b5cc879c399bfab3cf70f0c96119f755dce3e)]);
        vk.gamma = Pairing.G2Point([uint256(0x0cafd3a3550e17c0861eff6a8b1db7e7dcc82139e3f6377e253008185fa81d27), uint256(0x00f7abbbb879e75d638e5a93e19d51794d03505d757354da2285644b8a983214)], [uint256(0x16ddcf2977d6521ca880cd3056dc98cf0f82482bda82e4804a684e85915a21a7), uint256(0x0bc7fda0c9409791597f05cc1a7bdbea971dfa63eeb9e1994c3445550d3f4307)]);
        vk.delta = Pairing.G2Point([uint256(0x2145a0b797442947d59bc5ad06314551423d1716d6e3579f3e3953367d056c64), uint256(0x2ac7dee978861f45770c7797465eca344b77536edd1946c5132fc27bb05cf8a7)], [uint256(0x0507b216d12f24d8c9a0ce40cd441d6b2ef741cb855ca4151f656b25a3bacc85), uint256(0x1a85fb9d25af3339af42bc1e04f8ac5e0a38227474a2b00814f934aeb41e6c05)]);
        vk.gamma_abc = new Pairing.G1Point[](10);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x283e4fbef640e3b4f49edc9204832dd9561daa8f0f13198e8a81373673d234fb), uint256(0x02daf3e394b25a564e670a1f6f60cf0471e24461f55464a47c801785bb4d65ce));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x15360bfa180ffb341cd6f63ea31cdfa924481c4282108e1ad6c1d829c22db3b7), uint256(0x2fdd2c99dc5438be1c3c99d06c3dcc0bdd1d6a777c5b94c3f9e13309d5588aac));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x2569a3d71af9ee53a7f8a0c90e34276eb09cc7836403901bbf31970e30647269), uint256(0x2e268fbbb6dadcd9c9c214216aaebfe0e6f51a9ec441ec3e310025ecd2f2ccd1));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x02356cfe089b7324a6ad187e5a450cd818b2b708eee7e2edd2d61a09d57e23d2), uint256(0x2925f13eda20262e61b9d8e8bf16603746752eb40f8c70018018b7f0fda56e1f));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x2752887b2d9988d225b35811dd352b33d5d663bf23f07d6928493ac17a2da437), uint256(0x1c0429c5f77f3ec4ca342541139b9ccc40351d3721895f28de27c3af447ec419));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x009fd09a606cbe030b748176092d5f3c2c889173bd13fe3955b75c655554265c), uint256(0x0dcd981fc75f8f92c378c276d784fe2ff08ca835f4e326dbce77a119148f5c88));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x09e0d20d9a881a396708f8d3fb305d9ea31601ff7ea93693e0acaa0e31253d47), uint256(0x201df6eb3e2c9a5b7afa6ca55be6303f536f5a2f074ff7dea44f5b4c2d8839b8));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x2c746860f7ca6ca965787838fa22157a2945571e02393aae10e166b99c8021ab), uint256(0x1a760952114ecf91be99a603fa5ed9984bf0ebc4fafbda4e5883431e1d0b760d));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x2ee6157dbe5350a4ecee335f6108e0dfdc9e07e3c193842b9353a30114715f03), uint256(0x2fee054e8c8decc522dfa07c1a4b75aa9ab5613b971f10a0e45fc8fb93c9f77e));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x1c2561602492ef11adc04dda0fb889478ee497d021ecb10e2ad0e1ef3c081627), uint256(0x185bbfec3e8eaae676e75571389f3c27e623b32b27ad34fa50d9ebea8bef234d));
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
            Proof memory proof, uint[9] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](9);
        
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