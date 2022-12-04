/**
 *Submitted for verification at polygonscan.com on 2022-12-04
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

struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
}

contract Verifier9 {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x08a6062412a9b16463c90813db4eb7d10f9e0322e4f2f0ef7702b0dc25d8ccbb), uint256(0x24e92090e54e24e25fd05e198363900d2e52d569ea67ce91dd152a7b930a86a5));
        vk.beta = Pairing.G2Point([uint256(0x0b35652d8c44c88f0a5f24cf59c7e7092f546acffbe8283aefb565e7caa96cfd), uint256(0x132a35f9508e7f43ccd0eb1eb6c10ae20ccab862c3a0e86cf12375a500465ba1)], [uint256(0x0da2f259761a789139edcec0947a4c8d1c2d2dd8e14d4c4637418244f2b407b4), uint256(0x1c94ec7208d508cf15e02594f16a6e0a4bc54b3158ef12517e61c22020acb13e)]);
        vk.gamma = Pairing.G2Point([uint256(0x1d7f32ff70ec42fa0863cff52869590b08fd5a3cd7d3f8bd7f307af338303073), uint256(0x2f77bc4e0a4f84ae4efa96bc17f97f496abbc82f5a835a7a8b681bd90993dcd5)], [uint256(0x1e4ad550df1392703bafe678a4536f41238bf94773a472a1362730930357646c), uint256(0x21384ad39befcbc15256d9a634aafb714b641fe5e7f866b8993335fc4fdce2df)]);
        vk.delta = Pairing.G2Point([uint256(0x25240683bdbea4aed8eaeffa3ddd87fa89b80233e60931fcdbb2c66e1cad8424), uint256(0x2e8c0707b8013dabd6be4cac4764b2f22ec3f1aa397190e8df8b6846860c8909)], [uint256(0x1f4d2a8215396db6586066d04b3d270b2341ac723481b357f6073ab6269d08d6), uint256(0x2a323a7a043dcd34fef895d0c4d6133dcce4347fa58ddcdb25df98d856efd3e7)]);
        vk.gamma_abc = new Pairing.G1Point[](2);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x07da29b816a5ec19ca155eb71e589b9c7d8579e2a34db6234c67b7aabb0d3085), uint256(0x08c3c6b598a135c93e1e837891e7e1930bbc414dcf4083f7612bdf49d5f92b9b));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x2ce704000eb4c542db56c7c1bc0e39ba22ce6fefa5eb7e839ab07f000157ecb4), uint256(0x13a1b798dab47c18f5cf566d0510047a2f25b3bf1bf4e9f2155229b46cbb9ccc));
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
            Proof memory proof, uint[1] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](1);
        
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



contract Hackathon{

    address public verifier;

    bytes public verifierPubkey;

    address owner;

    struct Request {
        uint256 areaCode;
        address to;
        bytes numberHash;
    }

    mapping(address => Request) public requests;

    mapping(bytes32 => bool) public otpHash;

    mapping(address => bool) public verified;

    mapping(uint8 => address) public proofContract;

    event Requested(address,bytes);


    constructor(address v,bytes memory pubKey){
        owner = msg.sender;
        verifierPubkey = pubKey;
        verifier =v;
    }

    

    function changeVerifier(address _v,bytes memory _pubKey) external {
        require(msg.sender == owner);
        verifier = _v;
        verifierPubkey = _pubKey;
    }

    function changeProofContracts(uint8 series,address c) external {
        require(msg.sender == owner);
        proofContract[series] = c;

    }

    //[0x480fD103973357266813EcfcE9faABAbF3C4ca3A,0x0C79A89f8C84A39c98d48B15F11886470915C70b,0x6066b7414E0678aB2EfC46601BFC9ae45962048F,0x83A8bd6E00A84C8c63A47a552b0E5e02026c992D]

    function register(uint8 seriesNumber,Proof memory proof, uint[1] memory _areaCode,address _to,bytes memory hash) external {
        address v = proofContract[seriesNumber];
        require(Verifier9(v).verifyTx(proof,_areaCode));
        requests[msg.sender] =  Request(_areaCode[0],_to,hash);
        emit Requested(_to, hash);
    }

    function oTp(bytes32 _o) external {
        require(msg.sender == verifier);
        otpHash[_o] = true;
    }

    function verify(uint256 _otp,address user) external {
        require(otpHash[keccak256(abi.encodePacked(_otp))]);
        verified[user] = true;
    }
}