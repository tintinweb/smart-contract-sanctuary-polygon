// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./utils.sol";

interface IPasswordVerifier {
    function verifyTx(Proof memory proof, uint[3] memory input) external view returns(bool);
}

interface ISCIO {
    function verify(bytes32 _hashID, uint256 _threshold, Proof memory _registryProof) external view returns(bool);
}

contract Registration {
    using Pairing for *;

    ISCIO public scio;
    IPasswordVerifier public verifier;

    uint256 constant public SCIO_THRESHOLD = 90;

    struct Student {
        bytes32 usernameHash;
        uint128 passwordHashLow;
        uint128 passwordHashHigh;
        uint128 parameter;
    }

    mapping(bytes32 => Student) public students;

    constructor(address _passwordVerifierAddress, address _scioAddress) {
        verifier = IPasswordVerifier(_passwordVerifierAddress);
        scio = ISCIO(_scioAddress);
    }

    /** 
    * @notice Register user to the CTU system
    */
    function register(
        bytes32 _hashID,
        bytes32 _hashUsername,
        uint256[3] memory _passwordProofInput,
        Proof memory _passwordProof,
        Proof memory _registryProof
    ) external returns(bool) {
        require(scio.verify(_hashID, SCIO_THRESHOLD, _registryProof), "SCIO exam verification is invalid!");
        require(verifier.verifyTx(_passwordProof, _passwordProofInput), "Sender does not know password!");
        students[_hashUsername] = Student(
            _hashUsername, 
            uint128(uint256(_passwordProofInput[0])), 
            uint128(uint256(_passwordProofInput[1])), 
            uint128(_passwordProofInput[2])
        ); // something like this
        return true;
    }
}

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
}

struct Proof {
    Pairing.G1Point a;
    Pairing.G2Point b;
    Pairing.G1Point c;
}