// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable no-inline-assembly */

/**
 * returned data from validateUserOp.
 * validateUserOp returns a uint256, with is created by `_packedValidationData` and parsed by `_parseValidationData`
 * @param aggregator - address(0) - the account validated the signature by itself.
 *              address(1) - the account failed to validate the signature.
 *              otherwise - this is an address of a signature aggregator that must be used to validate the signature.
 * @param validAfter - this UserOp is valid only after this timestamp.
 * @param validaUntil - this UserOp is valid only up to this timestamp.
 */
    struct ValidationData {
        address aggregator;
        uint48 validAfter;
        uint48 validUntil;
    }

//extract sigFailed, validAfter, validUntil.
// also convert zero validUntil to type(uint48).max
    function _parseValidationData(uint validationData) pure returns (ValidationData memory data) {
        address aggregator = address(uint160(validationData));
        uint48 validUntil = uint48(validationData >> 160);
        if (validUntil == 0) {
            validUntil = type(uint48).max;
        }
        uint48 validAfter = uint48(validationData >> (48 + 160));
        return ValidationData(aggregator, validAfter, validUntil);
    }

// intersect account and paymaster ranges.
    function _intersectTimeRange(uint256 validationData, uint256 paymasterValidationData) pure returns (ValidationData memory) {
        ValidationData memory accountValidationData = _parseValidationData(validationData);
        ValidationData memory pmValidationData = _parseValidationData(paymasterValidationData);
        address aggregator = accountValidationData.aggregator;
        if (aggregator == address(0)) {
            aggregator = pmValidationData.aggregator;
        }
        uint48 validAfter = accountValidationData.validAfter;
        uint48 validUntil = accountValidationData.validUntil;
        uint48 pmValidAfter = pmValidationData.validAfter;
        uint48 pmValidUntil = pmValidationData.validUntil;

        if (validAfter < pmValidAfter) validAfter = pmValidAfter;
        if (validUntil > pmValidUntil) validUntil = pmValidUntil;
        return ValidationData(aggregator, validAfter, validUntil);
    }

/**
 * helper to pack the return value for validateUserOp
 * @param data - the ValidationData to pack
 */
    function _packValidationData(ValidationData memory data) pure returns (uint256) {
        return uint160(data.aggregator) | (uint256(data.validUntil) << 160) | (uint256(data.validAfter) << (160 + 48));
    }

/**
 * helper to pack the return value for validateUserOp, when not using an aggregator
 * @param sigFailed - true for signature failure, false for success
 * @param validUntil last timestamp this UserOperation is valid (or zero for infinite)
 * @param validAfter first timestamp this UserOperation is valid
 */
    function _packValidationData(bool sigFailed, uint48 validUntil, uint48 validAfter) pure returns (uint256) {
        return (sigFailed ? 1 : 0) | (uint256(validUntil) << 160) | (uint256(validAfter) << (160 + 48));
    }

/**
 * keccak function over calldata.
 * @dev copy calldata into memory, do keccak and drop allocated memory. Strangely, this is more efficient than letting solidity do it.
 */
    function calldataKeccak(bytes calldata data) pure returns (bytes32 ret) {
        assembly {
            let mem := mload(0x40)
            let len := data.length
            calldatacopy(mem, data.offset, len)
            ret := keccak256(mem, len)
        }
    }

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable no-inline-assembly */

import {calldataKeccak} from "../core/Helpers.sol";

/**
 * User Operation struct
 * @param sender the sender account of this request.
     * @param nonce unique value the sender uses to verify it is not a replay.
     * @param initCode if set, the account contract will be created by this constructor/
     * @param callData the method call to execute on this account.
     * @param callGasLimit the gas limit passed to the callData method call.
     * @param verificationGasLimit gas used for validateUserOp and validatePaymasterUserOp.
     * @param preVerificationGas gas not calculated by the handleOps method, but added to the gas paid. Covers batch overhead.
     * @param maxFeePerGas same as EIP-1559 gas parameter.
     * @param maxPriorityFeePerGas same as EIP-1559 gas parameter.
     * @param paymasterAndData if set, this field holds the paymaster address and paymaster-specific data. the paymaster will pay for the transaction instead of the sender.
     * @param signature sender-verified signature over the entire request, the EntryPoint address and the chain ID.
     */
    struct UserOperation {

        address sender;
        uint256 nonce;
        bytes initCode;
        bytes callData;
        uint256 callGasLimit;
        uint256 verificationGasLimit;
        uint256 preVerificationGas;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        bytes paymasterAndData;
        bytes signature;
    }

/**
 * Utility functions helpful when working with UserOperation structs.
 */
library UserOperationLib {

    function getSender(UserOperation calldata userOp) internal pure returns (address) {
        address data;
        //read sender from userOp, which is first userOp member (saves 800 gas...)
        assembly {data := calldataload(userOp)}
        return address(uint160(data));
    }

    //relayer/block builder might submit the TX with higher priorityFee, but the user should not
    // pay above what he signed for.
    function gasPrice(UserOperation calldata userOp) internal view returns (uint256) {
    unchecked {
        uint256 maxFeePerGas = userOp.maxFeePerGas;
        uint256 maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
        if (maxFeePerGas == maxPriorityFeePerGas) {
            //legacy mode (for networks that don't support basefee opcode)
            return maxFeePerGas;
        }
        return min(maxFeePerGas, maxPriorityFeePerGas + block.basefee);
    }
    }

    function pack(UserOperation calldata userOp) internal pure returns (bytes memory ret) {
        address sender = getSender(userOp);
        uint256 nonce = userOp.nonce;
        bytes32 hashInitCode = calldataKeccak(userOp.initCode);
        bytes32 hashCallData = calldataKeccak(userOp.callData);
        uint256 callGasLimit = userOp.callGasLimit;
        uint256 verificationGasLimit = userOp.verificationGasLimit;
        uint256 preVerificationGas = userOp.preVerificationGas;
        uint256 maxFeePerGas = userOp.maxFeePerGas;
        uint256 maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
        bytes32 hashPaymasterAndData = calldataKeccak(userOp.paymasterAndData);

        return abi.encode(
            sender, nonce,
            hashInitCode, hashCallData,
            callGasLimit, verificationGasLimit, preVerificationGas,
            maxFeePerGas, maxPriorityFeePerGas,
            hashPaymasterAndData
        );
    }

    function hash(UserOperation calldata userOp) internal pure returns (bytes32) {
        return keccak256(pack(userOp));
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import {UserOperation} from "@account-abstraction/contracts/interfaces/UserOperation.sol";

// interface for modules to verify singatures signed over userOpHash
interface IAuthorizationModule {
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) external returns (uint256 validationData);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

contract ISignatureValidatorConstants {
    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 internal constant EIP1271_MAGIC_VALUE = 0x1626ba7e;
}

abstract contract ISignatureValidator is ISignatureValidatorConstants {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param _dataHash Arbitrary length data signed on behalf of address(this)
     * @param _signature Signature byte array associated with _data
     *
     * MUST return the bytes4 magic value 0x20c13b0b when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(
        bytes32 _dataHash,
        bytes memory _signature
    ) public view virtual returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */
import "./Base64.sol";
import {UserOperation} from "@account-abstraction/contracts/interfaces/UserOperation.sol";
import {BaseAuthorizationModule} from "./BaseAuthorizationModule.sol";

struct JPoint {
    uint256 x;
    uint256 y;
    uint256 z;
}


contract BananaVerificationModule is BaseAuthorizationModule {

    string public constant NAME = "Banana Verification Module";
    string public constant VERSION = "0.0.1";

    error NoOwnerRegisteredForSmartAccount(address smartAccount);
    error AlreadyInitedForSmartAccount(address smartAccount);
    error WrongSignatureLength();


    uint256 constant gx = 0x6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296;
    uint256 constant gy = 0x4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5;
    uint256 public constant pp = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF;
                          
    uint256 public constant nn = 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551;
    uint256 constant a = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC;
    uint256 constant b = 0x5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B;
    uint256 constant MOST_SIGNIFICANT = 0xc000000000000000000000000000000000000000000000000000000000000000;

    mapping(address => uint[2]) public smartAccountOwners;
    
    function initForSmartAccount(uint256[2] memory publicKey) external returns (address) {
        if (smartAccountOwners[msg.sender][0] != 0 && smartAccountOwners[msg.sender][1] != 0)
            revert AlreadyInitedForSmartAccount(msg.sender);
        smartAccountOwners[msg.sender] = publicKey;
        return address(this);
    }

    function validateUserOp(
        // bytes memory data,
        // uint256[2] memory publicKey,
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) external virtual returns (uint256) {

        // (bytes memory moduleSignature, ) = abi.decode(
        //     userOp.signature,
        //     (bytes, address)
        // );

         (uint r, uint s, bytes32 message, bytes32 clientDataJsonHash) = abi.decode(
            userOp.signature,
            (uint, uint, bytes32, bytes32)
        );

        string memory userOpHashHex = lower(toHex(userOpHash));

        bytes memory base64RequestId = bytes(Base64.encode(userOpHashHex));

        if (keccak256(base64RequestId) != clientDataJsonHash) return SIG_VALIDATION_FAILED;

        // validateUserOp gets a hash not prepended with 'x\x19Ethereum Signed Message:\n32'
        // so we have to do it manually
        // bytes32 ethSignedHash = userOpHash.toEthSignedMessageHash();
        return _validateSignature(uint(message), [r, s], smartAccountOwners[msg.sender]);
    }

    function _validateSignature(
        uint256 hashedMessage,
        uint256[2] memory rs,
        uint256[2] memory qValues
    ) internal virtual returns (uint256 sigValidationResult) {
        if (
            _verifySignature(
                hashedMessage,
                rs,
                qValues
            )
        ) {
            return 0;
        }
        return SIG_VALIDATION_FAILED;
    }

    // function validateUserOp(
    //     UserOperation calldata userOp,
    //     bytes32 userOpHash
    // ) external view virtual returns (uint256) {
    //     (bytes memory moduleSignature, ) = abi.decode(
    //         userOp.signature,
    //         (bytes, address)
    //     );
    //     // validateUserOp gets a hash not prepended with 'x\x19Ethereum Signed Message:\n32'
    //     // so we have to do it manually
    //    return 0;
    // }


    function isValidSignature(
        bytes32 ethSignedDataHash,
        bytes memory moduleSignature
    ) public view virtual override returns (bytes4) {
        return
            isValidSignatureForAddress(
                ethSignedDataHash,
                moduleSignature,
                msg.sender
            );
    }

    function isValidSignatureForAddress(
        bytes32 ethSignedDataHash,
        bytes memory moduleSignature,
        address smartAccount
    ) public view virtual returns (bytes4) {
        
        return bytes4(0xffffffff);
    }


    function toHex16(bytes16 data) 
        internal pure returns (bytes32 result) 
    {
        result =
            (bytes32(data) &
                0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000) |
            ((bytes32(data) &
                0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >>
                64);
        result =
            (result &
                0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000) |
            ((result &
                0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >>
                32);
        result =
            (result &
                0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000) |
            ((result &
                0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >>
                16);
        result =
            (result &
                0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000) |
            ((result &
                0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >>
                8);
        result =
            ((result &
                0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >>
                4) |
            ((result &
                0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >>
                8);
        result = bytes32(
            0x3030303030303030303030303030303030303030303030303030303030303030 +
                uint256(result) +
                (((uint256(result) +
                    0x0606060606060606060606060606060606060606060606060606060606060606) >>
                    4) &
                    0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) *
                7
        );
    }

    function toHex(bytes32 data) 
        public pure returns (string memory) 
    {
        return
            string(
                abi.encodePacked(
                    '0x',
                    toHex16(bytes16(data)),
                    toHex16(bytes16(data << 128))
                )
            );
    }

    function lower(string memory _base) 
        internal pure returns (string memory) 
    {
        bytes memory _baseBytes = bytes(_base);
        for (uint256 i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    function _lower(bytes1 _b1) 
        private pure returns (bytes1) 
    {
        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }

    /*
    * _verifySignature
    * @description - verifies that a public key has signed a given message
    * @param hashedMeassage - hashed message
    * @param rs - signature  R and S
    * @param qValues - public key coordinate X,Y
    */
    function _verifySignature(uint256 hashedMeassage, uint[2] memory rs, uint[2] memory qValues)
        internal returns (bool)
    {
        uint256 r = rs[0];
        uint256 s = rs[1];
        if (r >= nn || s >= nn) {
            return false;
        }

        uint w = _primemod(s, nn);

        uint u1 = mulmod(hashedMeassage, w, nn);
        uint u2 = mulmod(r, w, nn);

        uint x;
        uint y;

        (x, y) = scalarMultiplications(qValues[0], qValues[1], u1, u2);
        return (x == r);
    }

    /*
    * scalarMultiplications
    * @description - performs a number of EC operations required in te pk signature verification
    */
    function scalarMultiplications(uint X, uint Y, uint u1, uint u2) 
        internal returns(uint, uint)
    {
        uint x1;
        uint y1;
        uint z1;

        // uint x2;
        // uint y2;
        // uint z2;

        // (x1, y1, z1) = ScalarBaseMultJacobian(u1);
        // (x2, y2, z2) = ScalarMultJacobian(X, Y, u2);
        // (x1, y1, z1) = _jAdd(x1, y1, z1, x2, y2, z2);

        (x1, y1, z1) = ShamirMultJacobian(X, Y, u1, u2);


        return _affineFromJacobian(x1, y1, z1);
    }

    /*
    * Strauss Shamir trick for EC multiplication
    * https://stackoverflow.com/questions/50993471/ec-scalar-multiplication-with-strauss-shamir-method
    * we optimise on this a bit to do with 2 bits at a time rather than a single bit
    * the individual points for a single pass are precomputed
    * overall this reduces the number of additions while keeping the same number of doublings
    */
    function ShamirMultJacobian(uint X, uint Y, uint u1, uint u2) internal pure returns (uint, uint, uint) {
        uint x = 0;
        uint y = 0;
        uint z = 0;
        uint bits = 128;
        uint index = 0;
        // precompute the points
        JPoint[] memory points = _preComputeJacobianPoints(X, Y);

        while (bits > 0) {
            if (z > 0) {
                (x, y, z) = _modifiedJacobianDouble(x, y, z);
                (x, y, z) = _modifiedJacobianDouble(x, y, z);
            }
            index = ((u1 & MOST_SIGNIFICANT) >> 252) | ((u2 & MOST_SIGNIFICANT) >> 254);
            if (index > 0) {
                (x, y, z) = _jAdd(x, y, z, points[index].x, points[index].y, points[index].z);
            }
            u1 <<= 2;
            u2 <<= 2;
            bits--;
        }
        return (x, y, z);
    }

    function _preComputeJacobianPoints(uint X, uint Y) internal pure returns (JPoint[] memory points) {
        // JPoint[] memory u1Points = new JPoint[](4);
        // u1Points[0] = JPoint(0, 0, 0);
        // u1Points[1] = JPoint(gx, gy, 1); // u1
        // u1Points[2] = _jPointDouble(u1Points[1]);
        // u1Points[3] = _jPointAdd(u1Points[1], u1Points[2]);
        // avoiding this intermediate step by using it in a single array below
        // these are pre computed points for u1

        points = new JPoint[](16);
        points[0] = JPoint(0, 0, 0);
        points[1] = JPoint(X, Y, 1); // u2
        points[2] = _jPointDouble(points[1]);
        points[3] = _jPointAdd(points[1], points[2]);

        points[4] = JPoint(gx, gy, 1); // u1Points[1]
        points[5] = _jPointAdd(points[4], points[1]);
        points[6] = _jPointAdd(points[4], points[2]);
        points[7] = _jPointAdd(points[4], points[3]);

        points[8] = _jPointDouble(points[4]); // u1Points[2]
        points[9] = _jPointAdd(points[8], points[1]);
        points[10] = _jPointAdd(points[8], points[2]);
        points[11] = _jPointAdd(points[8], points[3]);

        points[12] = _jPointAdd(points[4], points[8]); // u1Points[3]
        points[13] = _jPointAdd(points[12], points[1]);
        points[14] = _jPointAdd(points[12], points[2]);
        points[15] = _jPointAdd(points[12], points[3]);

        return points;
    }

    function _jPointAdd(JPoint memory p1, JPoint memory p2) internal pure returns (JPoint memory) {
        uint x;
        uint y;
        uint z;
        (x, y, z) = _jAdd(p1.x, p1.y, p1.z, p2.x, p2.y, p2.z);
        return JPoint(x, y, z);
    }

    function _jPointDouble(JPoint memory p) internal pure returns (JPoint memory) {
        uint x;
        uint y;
        uint z;
        (x, y, z) = _modifiedJacobianDouble(p.x, p.y, p.z);
        return JPoint(x, y, z);
    }
 
    /*
    * ScalarMult
    * @description performs scalar multiplication of two elliptic curve points, based on golang
    * crypto/elliptic library
    */
    function ScalarMult(uint Bx, uint By, uint k)
        internal returns (uint, uint)
    {
        uint x = 0;
        uint y = 0;
        uint z = 0;
        (x, y, z) = ScalarMultJacobian(Bx, By, k);

        return _affineFromJacobian(x, y, z);
    }

    function ScalarMultJacobian(uint Bx, uint By, uint k)
        internal pure returns (uint, uint, uint)
    {
        uint Bz = 1;
        uint x = 0;
        uint y = 0;
        uint z = 0;

        while (k > 0) {
            if (k & 0x01 == 0x01) {
                (x, y, z) = _jAdd(Bx, By, Bz, x, y, z);
            }
            (Bx, By, Bz) = _modifiedJacobianDouble(Bx, By, Bz);
            k = k >> 1;
        }

        return (x, y, z);
    }

    function ScalarBaseMultJacobian(uint k)
        internal pure returns (uint, uint, uint)
    {
        return ScalarMultJacobian(gx, gy, k);
    }


    /* _affineFromJacobian
    * @desription returns affine coordinates from a jacobian input follows 
    * golang elliptic/crypto library
    */
    function _affineFromJacobian(uint x, uint y, uint z)
        internal returns(uint ax, uint ay)
    {
        if (z==0) {
            return (0, 0);
        }

        uint zinv = _primemod(z, pp);
        uint zinvsq = mulmod(zinv, zinv, pp);

        ax = mulmod(x, zinvsq, pp);
        ay = mulmod(y, mulmod(zinvsq, zinv, pp), pp);

    }
    /*
    * _jAdd
    * @description performs double Jacobian as defined below:
    * https://hyperelliptic.org/EFD/g1p/auto-code/shortw/jacobian-3/doubling/mdbl-2007-bl.op3
    */
    function _jAdd(uint p1, uint p2, uint p3, uint q1, uint q2, uint q3)
        internal pure returns(uint r1, uint r2, uint r3)    
    {
        if (p3 == 0) {
            r1 = q1;
            r2 = q2;
            r3 = q3;

            return (r1, r2, r3);

        } else if (q3 == 0) {
            r1 = p1;
            r2 = p2;
            r3 = p3;

            return (r1, r2, r3);
        }

        assembly {
            let pd := 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF
            let z1z1 := mulmod(p3, p3, pd) // Z1Z1 = Z1^2
            let z2z2 := mulmod(q3, q3, pd) // Z2Z2 = Z2^2

            let u1 := mulmod(p1, z2z2, pd) // U1 = X1*Z2Z2
            let u2 := mulmod(q1, z1z1, pd) // U2 = X2*Z1Z1

            let s1 := mulmod(p2, mulmod(z2z2, q3, pd), pd) // S1 = Y1*Z2*Z2Z2
            let s2 := mulmod(q2, mulmod(z1z1, p3, pd), pd) // S2 = Y2*Z1*Z1Z1

            let p3q3 := addmod(p3, q3, pd)

            if lt(u2, u1) {
                u2 := add(pd, u2) // u2 = u2+pd
            }
            let h := sub(u2, u1) // H = U2-U1

            let i := mulmod(0x02, h, pd)
            i := mulmod(i, i, pd) // I = (2*H)^2

            let j := mulmod(h, i, pd) // J = H*I
            if lt(s2, s1) {
                s2 := add(pd, s2) // u2 = u2+pd
            }
            let rr := mulmod(0x02, sub(s2, s1), pd) // r = 2*(S2-S1)
            r1 := mulmod(rr, rr, pd) // X3 = R^2

            let v := mulmod(u1, i, pd) // V = U1*I
            let j2v := addmod(j, mulmod(0x02, v, pd), pd)
            if lt(r1, j2v) {
                r1 := add(pd, r1) // X3 = X3+pd
            }
            r1 := sub(r1, j2v)

            // Y3 = r*(V-X3)-2*S1*J
            let s12j := mulmod(mulmod(0x02, s1, pd), j, pd)

            if lt(v, r1) {
                v := add(pd, v)
            }
            r2 := mulmod(rr, sub(v, r1), pd)

            if lt(r2, s12j) {
                r2 := add(pd, r2)
            }
            r2 := sub(r2, s12j)

            // Z3 = ((Z1+Z2)^2-Z1Z1-Z2Z2)*H
            z1z1 := addmod(z1z1, z2z2, pd)
            j2v := mulmod(p3q3, p3q3, pd)
            if lt(j2v, z1z1) {
                j2v := add(pd, j2v)
            }
            r3 := mulmod(sub(j2v, z1z1), h, pd)
        }
        return (r1, r2, r3);
    }

    // Point doubling on the modified jacobian coordinates
    // http://point-at-infinity.org/ecc/Prime_Curve_Modified_Jacobian_Coordinates.html
    function _modifiedJacobianDouble(uint x, uint y, uint z) 
        internal pure returns (uint x3, uint y3, uint z3)
    {
        assembly {
            let pd := 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF
            let z2 := mulmod(z, z, pd)
            let az4 := mulmod(0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC, mulmod(z2, z2, pd), pd)
            let y2 := mulmod(y, y, pd)
            let s := mulmod(0x04, mulmod(x, y2, pd), pd)
            let u := mulmod(0x08, mulmod(y2, y2, pd), pd)
            let m := addmod(mulmod(0x03, mulmod(x, x, pd), pd), az4, pd)
            let twos := mulmod(0x02, s, pd)
            let m2 := mulmod(m, m, pd)
            if lt(m2, twos) {
                m2 := add(pd, m2)
            }
            x3 := sub(m2, twos)
            if lt(s, x3) {
                s := add(pd, s)
            }
            y3 := mulmod(m, sub(s, x3), pd)
            if lt(y3, u) {
                y3 := add(pd, y3)
            }
            y3 := sub(y3, u)
            z3 := mulmod(0x02, mulmod(y, z, pd), pd)
        }
    }

    function _primemod(uint value, uint p)
        internal returns (uint ret)
    {
        ret = modexp(value, p-2, p);
        return ret;
    }

    // Wrapper for built-in BigNumber_modexp (contract 0x5) as described here. https://github.com/ethereum/EIPs/pull/198
    function modexp(uint _base, uint _exp, uint _mod) internal returns(uint ret) {
        assembly {
            if gt(_base, _mod) {
                _base := mod(_base, _mod)
            }
            // Free memory pointer is always stored at 0x40
            let freemem := mload(0x40)
            
            mstore(freemem, 0x20)
            mstore(add(freemem, 0x20), 0x20)
            mstore(add(freemem, 0x40), 0x20)

            mstore(add(freemem, 0x60), _base)
            mstore(add(freemem, 0x80), _exp)
            mstore(add(freemem, 0xa0), _mod)

            let success := call(1500, 0x5, 0, freemem, 0xc0, freemem, 0x20)
            switch success
            case 0 {
                revert(0x0, 0x0)
            } default {
                ret := mload(freemem) 
            }
        }        
    }

}

pragma solidity ^0.8.12;

library Base64 {
    bytes private constant base64stdchars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes private constant base64urlchars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

    function encode(string memory _str) internal pure returns (string memory) {
        bytes memory _bs = bytes(_str);
        uint256 rem = _bs.length % 3;

        uint256 res_length = ((_bs.length + 2) / 3) * 4 - ((3 - rem) % 3);
        bytes memory res = new bytes(res_length);

        uint256 i = 0;
        uint256 j = 0;

        for (; i + 3 <= _bs.length; i += 3) {
            (res[j], res[j + 1], res[j + 2], res[j + 3]) = encode3(
                uint8(_bs[i]),
                uint8(_bs[i + 1]),
                uint8(_bs[i + 2])
            );

            j += 4;
        }

        if (rem != 0) {
            uint8 la0 = uint8(_bs[_bs.length - rem]);
            uint8 la1 = 0;

            if (rem == 2) {
                la1 = uint8(_bs[_bs.length - 1]);
            }

            (bytes1 b0, bytes1 b1, bytes1 b2, bytes1 b3) = encode3(la0, la1, 0);
            res[j] = b0;
            res[j + 1] = b1;
            if (rem == 2) {
                res[j + 2] = b2;
            }
        }

        return string(res);
    }

    function encode3(
        uint256 a0,
        uint256 a1,
        uint256 a2
    )
        private
        pure
        returns (
            bytes1 b0,
            bytes1 b1,
            bytes1 b2,
            bytes1 b3
        )
    {
        uint256 n = (a0 << 16) | (a1 << 8) | a2;

        uint256 c0 = (n >> 18) & 63;
        uint256 c1 = (n >> 12) & 63;
        uint256 c2 = (n >> 6) & 63;
        uint256 c3 = (n) & 63;

        b0 = base64urlchars[c0];
        b1 = base64urlchars[c1];
        b2 = base64urlchars[c2];
        b3 = base64urlchars[c3];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IAuthorizationModule} from "../interfaces/IAuthorizationModule.sol";
import {ISignatureValidator} from "../interfaces/ISignatureValidator.sol";

abstract contract BaseAuthorizationModule is
    IAuthorizationModule,
    ISignatureValidator
{
    uint256 internal constant SIG_VALIDATION_FAILED = 1;
}