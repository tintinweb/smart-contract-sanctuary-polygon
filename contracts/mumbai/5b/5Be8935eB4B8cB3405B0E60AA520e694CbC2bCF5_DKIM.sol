// SPDX-License-Identifier: BSD-2-Clause
pragma solidity ^0.8.4;

/**
* @dev A library for working with mutable byte buffers in Solidity.
*
* Byte buffers are mutable and expandable, and provide a variety of primitives
* for appending to them. At any time you can fetch a bytes object containing the
* current contents of the buffer. The bytes object should not be stored between
* operations, as it may change due to resizing of the buffer.
*/
library Buffer {
    /**
    * @dev Represents a mutable buffer. Buffers have a current value (buf) and
    *      a capacity. The capacity may be longer than the current value, in
    *      which case it can be extended without the need to allocate more memory.
    */
    struct buffer {
        bytes buf;
        uint capacity;
    }

    /**
    * @dev Initializes a buffer with an initial capacity.
    * @param buf The buffer to initialize.
    * @param capacity The number of bytes of space to allocate the buffer.
    * @return The buffer, for chaining.
    */
    function init(buffer memory buf, uint capacity) internal pure returns(buffer memory) {
        if (capacity % 32 != 0) {
            capacity += 32 - (capacity % 32);
        }
        // Allocate space for the buffer data
        buf.capacity = capacity;
        assembly {
            let ptr := mload(0x40)
            mstore(buf, ptr)
            mstore(ptr, 0)
            let fpm := add(32, add(ptr, capacity))
            if lt(fpm, ptr) {
                revert(0, 0)
            }
            mstore(0x40, fpm)
        }
        return buf;
    }

    /**
    * @dev Initializes a new buffer from an existing bytes object.
    *      Changes to the buffer may mutate the original value.
    * @param b The bytes object to initialize the buffer with.
    * @return A new buffer.
    */
    function fromBytes(bytes memory b) internal pure returns(buffer memory) {
        buffer memory buf;
        buf.buf = b;
        buf.capacity = b.length;
        return buf;
    }

    function resize(buffer memory buf, uint capacity) private pure {
        bytes memory oldbuf = buf.buf;
        init(buf, capacity);
        append(buf, oldbuf);
    }

    /**
    * @dev Sets buffer length to 0.
    * @param buf The buffer to truncate.
    * @return The original buffer, for chaining..
    */
    function truncate(buffer memory buf) internal pure returns (buffer memory) {
        assembly {
            let bufptr := mload(buf)
            mstore(bufptr, 0)
        }
        return buf;
    }

    /**
    * @dev Appends len bytes of a byte string to a buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @param len The number of bytes to copy.
    * @return The original buffer, for chaining.
    */
    function append(buffer memory buf, bytes memory data, uint len) internal pure returns(buffer memory) {
        require(len <= data.length);

        uint off = buf.buf.length;
        uint newCapacity = off + len;
        if (newCapacity > buf.capacity) {
            resize(buf, newCapacity * 2);
        }

        uint dest;
        uint src;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Length of existing buffer data
            let buflen := mload(bufptr)
            // Start address = buffer address + offset + sizeof(buffer length)
            dest := add(add(bufptr, 32), off)
            // Update buffer length if we're extending it
            if gt(newCapacity, buflen) {
                mstore(bufptr, newCapacity)
            }
            src := add(data, 32)
        }

        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        unchecked {
            uint mask = (256 ** (32 - len)) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask))
                let destpart := and(mload(dest), mask)
                mstore(dest, or(destpart, srcpart))
            }
        }

        return buf;
    }

    /**
    * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
        return append(buf, data, data.length);
    }

    /**
    * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
    *      capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function appendUint8(buffer memory buf, uint8 data) internal pure returns(buffer memory) {
        uint off = buf.buf.length;
        uint offPlusOne = off + 1;
        if (off >= buf.capacity) {
            resize(buf, offPlusOne * 2);
        }

        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Address = buffer address + sizeof(buffer length) + off
            let dest := add(add(bufptr, off), 32)
            mstore8(dest, data)
            // Update buffer length if we extended it
            if gt(offPlusOne, mload(bufptr)) {
                mstore(bufptr, offPlusOne)
            }
        }

        return buf;
    }

    /**
    * @dev Appends len bytes of bytes32 to a buffer. Resizes if doing so would
    *      exceed the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @param len The number of bytes to write (left-aligned).
    * @return The original buffer, for chaining.
    */
    function append(buffer memory buf, bytes32 data, uint len) private pure returns(buffer memory) {
        uint off = buf.buf.length;
        uint newCapacity = len + off;
        if (newCapacity > buf.capacity) {
            resize(buf, newCapacity * 2);
        }

        unchecked {
            uint mask = (256 ** len) - 1;
            // Right-align data
            data = data >> (8 * (32 - len));
            assembly {
                // Memory address of the buffer data
                let bufptr := mload(buf)
                // Address = buffer address + sizeof(buffer length) + newCapacity
                let dest := add(bufptr, newCapacity)
                mstore(dest, or(and(mload(dest), not(mask)), data))
                // Update buffer length if we extended it
                if gt(newCapacity, mload(bufptr)) {
                    mstore(bufptr, newCapacity)
                }
            }
        }
        return buf;
    }

    /**
    * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chhaining.
    */
    function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
        return append(buf, bytes32(data), 20);
    }

    /**
    * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
        return append(buf, data, 32);
    }

    /**
     * @dev Appends a byte to the end of the buffer. Resizes if doing so would
     *      exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @param len The number of bytes to write (right-aligned).
     * @return The original buffer.
     */
    function appendInt(buffer memory buf, uint data, uint len) internal pure returns(buffer memory) {
        uint off = buf.buf.length;
        uint newCapacity = len + off;
        if (newCapacity > buf.capacity) {
            resize(buf, newCapacity * 2);
        }

        uint mask = (256 ** len) - 1;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Address = buffer address + sizeof(buffer length) + newCapacity
            let dest := add(bufptr, newCapacity)
            mstore(dest, or(and(mload(dest), not(mask)), data))
            // Update buffer length if we extended it
            if gt(newCapacity, mload(bufptr)) {
                mstore(bufptr, newCapacity)
            }
        }
        return buf;
    }
}

pragma solidity ^0.8.4;

library SHA1 {
    event Debug(bytes32 x);

    function sha1(bytes memory data) internal pure returns(bytes20 ret) {
        assembly {
            // Get a safe scratch location
            let scratch := mload(0x40)

            // Get the data length, and point data at the first byte
            let len := mload(data)
            data := add(data, 32)

            // Find the length after padding
            let totallen := add(and(add(len, 1), 0xFFFFFFFFFFFFFFC0), 64)
            switch lt(sub(totallen, len), 9)
            case 1 { totallen := add(totallen, 64) }

            let h := 0x6745230100EFCDAB890098BADCFE001032547600C3D2E1F0

            function readword(ptr, off, count) -> result {
                result := 0
                if lt(off, count) {
                    result := mload(add(ptr, off))
                    count := sub(count, off)
                    if lt(count, 32) {
                        let mask := not(sub(exp(256, sub(32, count)), 1))
                        result := and(result, mask)
                    }
                }
            }

            for { let i := 0 } lt(i, totallen) { i := add(i, 64) } {
                mstore(scratch, readword(data, i, len))
                mstore(add(scratch, 32), readword(data, add(i, 32), len))

                // If we loaded the last byte, store the terminator byte
                switch lt(sub(len, i), 64)
                case 1 { mstore8(add(scratch, sub(len, i)), 0x80) }

                // If this is the last block, store the length
                switch eq(i, sub(totallen, 64))
                case 1 { mstore(add(scratch, 32), or(mload(add(scratch, 32)), mul(len, 8))) }

                // Expand the 16 32-bit words into 80
                for { let j := 64 } lt(j, 128) { j := add(j, 12) } {
                    let temp := xor(xor(mload(add(scratch, sub(j, 12))), mload(add(scratch, sub(j, 32)))), xor(mload(add(scratch, sub(j, 56))), mload(add(scratch, sub(j, 64)))))
                    temp := or(and(mul(temp, 2), 0xFFFFFFFEFFFFFFFEFFFFFFFEFFFFFFFEFFFFFFFEFFFFFFFEFFFFFFFEFFFFFFFE), and(div(temp, 0x80000000), 0x0000000100000001000000010000000100000001000000010000000100000001))
                    mstore(add(scratch, j), temp)
                }
                for { let j := 128 } lt(j, 320) { j := add(j, 24) } {
                    let temp := xor(xor(mload(add(scratch, sub(j, 24))), mload(add(scratch, sub(j, 64)))), xor(mload(add(scratch, sub(j, 112))), mload(add(scratch, sub(j, 128)))))
                    temp := or(and(mul(temp, 4), 0xFFFFFFFCFFFFFFFCFFFFFFFCFFFFFFFCFFFFFFFCFFFFFFFCFFFFFFFCFFFFFFFC), and(div(temp, 0x40000000), 0x0000000300000003000000030000000300000003000000030000000300000003))
                    mstore(add(scratch, j), temp)
                }

                let x := h
                let f := 0
                let k := 0
                for { let j := 0 } lt(j, 80) { j := add(j, 1) } {
                    switch div(j, 20)
                    case 0 {
                        // f = d xor (b and (c xor d))
                        f := xor(div(x, 0x100000000000000000000), div(x, 0x10000000000))
                        f := and(div(x, 0x1000000000000000000000000000000), f)
                        f := xor(div(x, 0x10000000000), f)
                        k := 0x5A827999
                    }
                    case 1{
                        // f = b xor c xor d
                        f := xor(div(x, 0x1000000000000000000000000000000), div(x, 0x100000000000000000000))
                        f := xor(div(x, 0x10000000000), f)
                        k := 0x6ED9EBA1
                    }
                    case 2 {
                        // f = (b and c) or (d and (b or c))
                        f := or(div(x, 0x1000000000000000000000000000000), div(x, 0x100000000000000000000))
                        f := and(div(x, 0x10000000000), f)
                        f := or(and(div(x, 0x1000000000000000000000000000000), div(x, 0x100000000000000000000)), f)
                        k := 0x8F1BBCDC
                    }
                    case 3 {
                        // f = b xor c xor d
                        f := xor(div(x, 0x1000000000000000000000000000000), div(x, 0x100000000000000000000))
                        f := xor(div(x, 0x10000000000), f)
                        k := 0xCA62C1D6
                    }
                    // temp = (a leftrotate 5) + f + e + k + w[i]
                    let temp := and(div(x, 0x80000000000000000000000000000000000000000000000), 0x1F)
                    temp := or(and(div(x, 0x800000000000000000000000000000000000000), 0xFFFFFFE0), temp)
                    temp := add(f, temp)
                    temp := add(and(x, 0xFFFFFFFF), temp)
                    temp := add(k, temp)
                    temp := add(div(mload(add(scratch, mul(j, 4))), 0x100000000000000000000000000000000000000000000000000000000), temp)
                    x := or(div(x, 0x10000000000), mul(temp, 0x10000000000000000000000000000000000000000))
                    x := or(and(x, 0xFFFFFFFF00FFFFFFFF000000000000FFFFFFFF00FFFFFFFF), mul(or(and(div(x, 0x4000000000000), 0xC0000000), and(div(x, 0x400000000000000000000), 0x3FFFFFFF)), 0x100000000000000000000))
                }

                h := and(add(h, x), 0xFFFFFFFF00FFFFFFFF00FFFFFFFF00FFFFFFFF00FFFFFFFF)
            }
            ret := mul(or(or(or(or(and(div(h, 0x100000000), 0xFFFFFFFF00000000000000000000000000000000), and(div(h, 0x1000000), 0xFFFFFFFF000000000000000000000000)), and(div(h, 0x10000), 0xFFFFFFFF0000000000000000)), and(div(h, 0x100), 0xFFFFFFFF00000000)), and(h, 0xFFFFFFFF)), 0x1000000000000000000000000)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@ensdomains/solsha1/contracts/SHA1.sol";
import "@ensdomains/buffer/contracts/Buffer.sol";

library Algorithm {
    using Buffer for *;

    function checkSHA256(bytes memory data, string memory bodyHash) internal pure returns (bool) {
        bytes32 digest = sha256(data);
        return readBytes32(base64decode(bodyHash), 0) == digest;
    }

    function checkSHA1(bytes memory data, string memory bodyHash) internal pure returns (bool) {
        bytes20 digest = SHA1.sha1(data);
        return readBytes20(base64decode(bodyHash), 0) == digest;
    }

    function verifyRSASHA256(bytes memory modulus, bytes memory exponent, bytes memory data, string memory sig) internal view returns (bool) {
        // Recover the message from the signature
        bool ok;
        bytes memory result;
        (ok, result) = modexp(base64decode(sig), exponent, modulus);

        // Verify it ends with the hash of our data
        return ok && sha256(data) == readBytes32(result, result.length - 32);
    }

    function verifyRSASHA1(bytes memory modulus, bytes memory exponent, bytes memory data, string memory sig) internal view returns (bool) {
        // Recover the message from the signature
        bool ok;
        bytes memory result;
        (ok, result) = modexp(base64decode(sig), exponent, modulus);

        // Verify it ends with the hash of our data
        return ok && SHA1.sha1(data) == readBytes20(result, result.length - 20);
    }


    /**
    * @dev Computes (base ^ exponent) % modulus over big numbers.
    */
    function modexp(bytes memory base, bytes memory exponent, bytes memory modulus) internal view returns (bool success, bytes memory output) {
        uint size = (32 * 3) + base.length + exponent.length + modulus.length;

        Buffer.buffer memory input;
        input.init(size);

        input.appendBytes32(bytes32(base.length));
        input.appendBytes32(bytes32(exponent.length));
        input.appendBytes32(bytes32(modulus.length));
        input.append(base);
        input.append(exponent);
        input.append(modulus);

        output = new bytes(modulus.length);

        assembly {
            success := staticcall(gas(), 5, add(mload(input), 32), size, add(output, 32), mload(modulus))
        }
    }

    /*
    * @dev Returns the 32 byte value at the specified index of self.
    * @param self The byte string.
    * @param idx The index into the bytes
    * @return The specified 32 bytes of the string.
    */
    function readBytes32(bytes memory self, uint idx) internal pure returns (bytes32 ret) {
        require(idx + 32 <= self.length);
        assembly {
            ret := mload(add(add(self, 32), idx))
        }
    }

    /*
    * @dev Returns the 32 byte value at the specified index of self.
    * @param self The byte string.
    * @param idx The index into the bytes
    * @return The specified 32 bytes of the string.
    */
    function readBytes20(bytes memory self, uint idx) internal pure returns (bytes20 ret) {
        require(idx + 20 <= self.length);
        assembly {
            ret := and(mload(add(add(self, 32), idx)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000)
        }
    }

    bytes constant private base64stdchars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function base64decode(string memory str) internal pure returns (bytes memory) {
        bytes memory data = bytes(str);
        uint8[] memory decoding_table = new uint8[](256);

        for (uint8 t = 0; t < 64; t++) {
            decoding_table[uint8(base64stdchars[t])] = t;
        }

        if (data.length % 4 != 0) return "";
        uint output_length = data.length / 4 * 3;
        if (data[data.length - 1] == '=') output_length--;
        if (data[data.length - 2] == '=') output_length--;

        bytes memory decoded_data = new bytes(output_length);

        uint j = 0;
        for (uint i = 0; i < data.length;) {
            uint sextet_a = data[i] == '=' ? 0 & i++ : decoding_table[uint8(data[i++])];
            uint sextet_b = data[i] == '=' ? 0 & i++ : decoding_table[uint8(data[i++])];
            uint sextet_c = data[i] == '=' ? 0 & i++ : decoding_table[uint8(data[i++])];
            uint sextet_d = data[i] == '=' ? 0 & i++ : decoding_table[uint8(data[i++])];

            uint triple = (sextet_a << 3 * 6) + (sextet_b << 2 * 6) + (sextet_c << 1 * 6) + (sextet_d << 0 * 6);

            if (j < output_length) decoded_data[j++] = bytes1(bytes32(triple >> 2 * 8) & bytes1(0xFF));
            if (j < output_length) decoded_data[j++] = bytes1(bytes32(triple >> 1 * 8) & bytes1(0xFF));
            if (j < output_length) decoded_data[j++] = bytes1(bytes32(triple >> 0 * 8) & bytes1(0xFF));
        }
        return decoded_data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./utils/Strings.sol";
import "./Algorithm.sol";
import "./interfaces/IDKIMPublicKeyOracle.sol";

contract DKIM {
    using strings for *;
    IDKIMPublicKeyOracle oracle;

    constructor(address _oracle) {
        oracle = IDKIMPublicKeyOracle(_oracle);
    }

    uint private constant STATE_SUCCESS = 0;
    uint private constant STATE_PERMFAIL = 1;
    uint private constant STATE_TEMPFAIL = 2;

    struct Status {
        uint state; //验证的状态
        strings.slice message; //报错信息
    }

    struct Headers {
        uint len;
        uint signum;
        strings.slice[] name; //关键字
        strings.slice[] value; //关键字的值
        strings.slice[] signatures; //签名
    }

    struct SigTags {
        strings.slice d; //domain签名域标识符
        strings.slice i; //用户标识符
        strings.slice s; //服务类型，selector
        strings.slice b; //正文和标题的签名
        strings.slice bh; //正文哈希
        strings.slice cHeader; //对于header使用的规范化算法
        strings.slice cBody; //对于body使用的规划化算法。
        strings.slice aHash; //使用的哈希算法
        strings.slice aKey; //使用的秘钥类型：默认RSA
        strings.slice[] h; //可接受的哈希算法
        uint l; //规范算法里面的制定长度
    }

    function verify(
        string memory raw
    )
        public
        view
        returns (
            bool success,
            string memory from,
            string memory to,
            string memory subject,
            string memory body
        )
    {
        SigTags memory sigTags;
        Headers memory headers;
        strings.slice memory bodys;
        string memory bodyraw;
        Status memory status;
        string memory From;
        string memory To;
        string memory Subject;

        (headers, bodys, status) = parse(raw.toSlice());

        (From, To, Subject) = ParseHeader(headers); //分解header抽取from，to，subject

        strings.slice memory dkimSig = headers.signatures[0];

        (sigTags, status) = parseSigTags(dkimSig.copy()); //继续切分signatures放到sigTags；
        (status, bodyraw) = verifyBodyHash(bodys, sigTags); //验证内容的hash值，判断内容是否更改。

        status = verifySignature(headers, sigTags, dkimSig);
        if (status.state != STATE_SUCCESS) {
            return (false, status.message.toString(), "", "", "");
        } else {
            return (true, From, To, Subject, bodyraw);
        }
    }

    function ParseHeader(
        Headers memory headers
    ) internal pure returns (string memory, string memory, string memory) {
        strings.slice memory FromValue;
        strings.slice memory ToValue;
        strings.slice memory SubjectValue;

        for (uint i = 0; i <= headers.len; i++) {
            strings.slice memory From = "from".toSlice();
            strings.slice memory To = "to".toSlice();
            strings.slice memory Subject = "subject".toSlice();
            if (headers.name[i].equals(From)) {
                FromValue = headers.value[i];
                FromValue.split("<".toSlice());
                FromValue = FromValue.split(">".toSlice());
            } else if (headers.name[i].equals(To)) {
                ToValue = headers.value[i];
                ToValue.split(":".toSlice());
            } else if (headers.name[i].equals(Subject)) {
                SubjectValue = headers.value[i];
                SubjectValue.split(":".toSlice());
            }
        }
        return (
            FromValue.toString(),
            ToValue.toString(),
            SubjectValue.toString()
        );
    }

    function verifyBodyHash(
        strings.slice memory body,
        SigTags memory sigTags
    ) internal pure returns (Status memory, string memory) {
        //通过body的内容算出hash与bh进行验证。
        if (sigTags.l > 0 && body._len > sigTags.l) body._len = sigTags.l;
        string memory processedBody = processBody(body, sigTags.cBody);
        bool check = false;
        if (sigTags.aHash.equals("sha256".toSlice())) {
            check = Algorithm.checkSHA256(
                bytes(processedBody),
                sigTags.bh.toString()
            );
        } else {
            check = Algorithm.checkSHA1(
                bytes(processedBody),
                sigTags.bh.toString()
            );
        }
        return (
            check
                ? Status(STATE_SUCCESS, strings.slice(0, 0))
                : Status(STATE_PERMFAIL, "body hash did not verify".toSlice()),
            processedBody
        );
    }

    function verifySignature(
        Headers memory headers,
        SigTags memory sigTags,
        strings.slice memory signature
    ) internal view returns (Status memory) {
        (bytes memory modulus, bytes memory exponent) = oracle.getRSAKey(
            sigTags.d.toString(),
            sigTags.s.toString()
        );
        //通过body+header一起计算哈希与signuature进行验证。
        if (modulus.length == 0 || exponent.length == 0) {
            return Status(STATE_TEMPFAIL, "dns query error".toSlice());
        }

        bool check = false;
        string memory processedHeader = processHeader(
            headers,
            sigTags.h,
            sigTags.cHeader,
            signature
        );
        if (sigTags.aHash.equals("sha256".toSlice())) {
            check = Algorithm.verifyRSASHA256(
                modulus,
                exponent,
                bytes(processedHeader),
                sigTags.b.toString()
            );
        } else {
            check = Algorithm.verifyRSASHA1(
                modulus,
                exponent,
                bytes(processedHeader),
                sigTags.b.toString()
            );
        }
        return
            check
                ? Status(STATE_SUCCESS, strings.slice(0, 0))
                : Status(STATE_PERMFAIL, "signature did not verify".toSlice());
    }

    function parse(
        strings.slice memory all
    )
        internal
        pure
        returns (Headers memory, strings.slice memory, Status memory)
    {
        //将一个大的slice进行分割切片（以冒号，换行为分割点），把标题读完后剩下的就是body，
        strings.slice memory crlf = "\r\n".toSlice();
        strings.slice memory colon = ":".toSlice();
        strings.slice memory sp = "\x20".toSlice();
        strings.slice memory tab = "\x09".toSlice();
        strings.slice memory signame = "dkim-signature".toSlice();

        Headers memory headers = Headers(
            0,
            0,
            new strings.slice[](80),
            new strings.slice[](80),
            new strings.slice[](3)
        );
        strings.slice memory headerName = strings.slice(0, 0);
        strings.slice memory headerValue = strings.slice(0, 0);
        while (!all.empty()) {
            strings.slice memory part = all.split(crlf); //一行一行的读取的all里面的内容，读到内容给part ，all的lenth和指针向后顺延
            if (part.startsWith(sp) || part.startsWith(tab)) {
                headerValue._len += crlf._len + part._len;
            } else {
                if (headerName.equals(signame)) {
                    //读取到关键字dkim-signature，就将签名的内容放到header.signnature里面
                    headers.signatures[0] = headerValue;
                    headers.signum++;
                } else if (!headerName.empty()) {
                    headers.name[headers.len] = headerName;
                    headers.value[headers.len] = headerValue;
                    headers.len++;
                }
                headerName = toLowercase(part.copy().split(colon).toString())
                    .toSlice(); //冒号为分割，之前是name，之后为value；
                headerValue = part;
            }

            if (all.startsWith(crlf)) {
                //两个连续的换行符就代表读完了
                all._len -= 2;
                all._ptr += 2;
                return (
                    headers,
                    all,
                    Status(STATE_SUCCESS, strings.slice(0, 0))
                );
            }
        }
        return (
            headers,
            all,
            Status(STATE_PERMFAIL, "no header boundary found".toSlice())
        );
    }

    // @dev https://tools.ietf.org/html/rfc6376#section-3.5
    function parseSigTags(
        strings.slice memory signature
    ) internal pure returns (SigTags memory sigTags, Status memory status) {
        //将signature的内容进行切片，分类放入sigtag中，方便之后的验证。
        strings.slice memory sc = ";".toSlice();
        strings.slice memory eq = "=".toSlice();
        status = Status(STATE_SUCCESS, strings.slice(0, 0));

        signature.split(":".toSlice());
        while (!signature.empty()) {
            strings.slice memory value = signature.split(sc);
            strings.slice memory name = trim(value.split(eq));
            value = trim(value);

            if (name.equals("v".toSlice()) && !value.equals("1".toSlice())) {
                status = Status(
                    STATE_PERMFAIL,
                    "incompatible signature version".toSlice()
                );
                return (sigTags, status);
            } else if (name.equals("d".toSlice())) {
                sigTags.d = value;
            } else if (name.equals("i".toSlice())) {
                sigTags.i = value;
            } else if (name.equals("s".toSlice())) {
                sigTags.s = value;
            } else if (name.equals("c".toSlice())) {
                if (value.empty()) {
                    sigTags.cHeader = "simple".toSlice();
                    sigTags.cBody = "simple".toSlice();
                } else {
                    sigTags.cHeader = value.split("/".toSlice());
                    sigTags.cBody = value;
                    if (sigTags.cBody.empty()) {
                        sigTags.cBody = "simple".toSlice();
                    }
                }
            } else if (name.equals("a".toSlice())) {
                sigTags.aKey = value.split("-".toSlice());
                sigTags.aHash = value;
                if (sigTags.aHash.empty()) {
                    status = Status(
                        STATE_PERMFAIL,
                        "malformed algorithm name".toSlice()
                    );
                    return (sigTags, status);
                }
                if (
                    !sigTags.aHash.equals("sha256".toSlice()) &&
                    !sigTags.aHash.equals("sha1".toSlice())
                ) {
                    status = Status(
                        STATE_PERMFAIL,
                        "unsupported hash algorithm".toSlice()
                    );
                    return (sigTags, status);
                }
                if (!sigTags.aKey.equals("rsa".toSlice())) {
                    status = Status(
                        STATE_PERMFAIL,
                        "unsupported key algorithm".toSlice()
                    );
                    return (sigTags, status);
                }
            } else if (name.equals("bh".toSlice())) {
                sigTags.bh = value;
            } else if (name.equals("h".toSlice())) {
                bool signedFrom;
                (sigTags.h, signedFrom) = parseSigHTag(value);
                if (!signedFrom) {
                    status = Status(
                        STATE_PERMFAIL,
                        "From field not signed".toSlice()
                    );
                    return (sigTags, status);
                }
            } else if (name.equals("b".toSlice())) {
                sigTags.b = unfoldContinuationLines(value, true);
            } else if (name.equals("l".toSlice())) {
                sigTags.l = stringToUint(value.toString());
            }
        }

        if (
            sigTags.aKey.empty() ||
            sigTags.b.empty() ||
            sigTags.bh.empty() ||
            sigTags.d.empty() ||
            sigTags.s.empty() ||
            sigTags.h.length == 0
        ) {
            status = Status(STATE_PERMFAIL, "required tag missing".toSlice());
            return (sigTags, status);
        }
        if (sigTags.i.empty()) {
            // behave as though the value of i tag were "@d"
        } else if (!sigTags.i.endsWith(sigTags.d)) {
            status = Status(STATE_PERMFAIL, "domain mismatch".toSlice());
            return (sigTags, status);
        }
    }

    function parseSigHTag(
        strings.slice memory value
    ) internal pure returns (strings.slice[] memory, bool) {
        strings.slice memory colon = ":".toSlice();
        strings.slice memory from = "from".toSlice();
        strings.slice[] memory list = new strings.slice[](
            value.count(colon) + 1
        );
        bool signedFrom = false;

        for (uint i = 0; i < list.length; i++) {
            strings.slice memory h = toLowercase(
                trim(value.split(colon)).toString()
            ).toSlice();
            uint j = 0;
            for (; j < i; j++) if (list[j].equals(h)) break;
            if (j == i) list[i] = h;
            if (h.equals(from)) signedFrom = true;
        }
        return (list, signedFrom);
    }

    function processBody(
        strings.slice memory message,
        strings.slice memory method
    ) internal pure returns (string memory) {
        //对body内容进行处理，去掉空格，换行，制表符。
        if (method.equals("relaxed".toSlice())) {
            message = removeSPAtEndOfLines(message);
            message = removeWSPSequences(message);
        }
        message = ignoreEmptyLineAtEnd(message);
        // https://tools.ietf.org/html/rfc6376#section-3.4.3
        if (method.equals("simple".toSlice()) && message.empty()) {
            return "\r\n";
        }
        return message.toString();
    }

    function processHeader(
        Headers memory headers,
        strings.slice[] memory tags,
        strings.slice memory method,
        strings.slice memory signature
    ) internal pure returns (string memory) {
        //把header进行格式化处理。
        strings.slice memory crlf = "\r\n".toSlice();
        strings.slice memory colon = ":".toSlice();
        strings.slice[] memory processedHeader = new strings.slice[](
            tags.length + 1
        );
        bool isSimple = method.equals("simple".toSlice());

        for (uint j = 0; j < tags.length; j++) {
            if (tags[j].empty()) continue;
            strings.slice memory value = getHeader(headers, tags[j]);
            if (value.empty()) continue;

            if (isSimple) {
                processedHeader[j] = value;
                continue;
            }

            value.split(colon);
            value = unfoldContinuationLines(value, false);
            value = removeWSPSequences(value);
            value = trim(value);

            // Convert all header field names to lowercase
            strings.slice[] memory parts = new strings.slice[](2);
            parts[0] = tags[j];
            parts[1] = value;
            processedHeader[j] = colon.join(parts).toSlice();
        }

        if (isSimple) {
            processedHeader[processedHeader.length - 1] = signature;
        } else {
            signature.split(colon);
            // Remove signature value for "dkim-signature" header
            strings.slice memory beforeB = signature.split("b=".toSlice());
            if (signature.empty()) {
                signature = beforeB;
            } else {
                beforeB._len += 2;
                signature.split(";".toSlice());
                signature = beforeB.concat(signature).toSlice();
            }
            signature = unfoldContinuationLines(signature, false);
            signature = removeWSPSequences(signature);
            signature = trim(signature);

            processedHeader[processedHeader.length - 1] = "dkim-signature:"
                .toSlice()
                .concat(signature)
                .toSlice();
        }

        return joinNoEmpty(crlf, processedHeader);
    }

    // utils
    function getHeader(
        Headers memory headers,
        strings.slice memory headerName
    ) internal pure returns (strings.slice memory) {
        //用headername关键字例如b 、bh 等匹配找到对应的header.value
        for (uint i = 0; i < headers.len; i++) {
            if (headers.name[i].equals(headerName))
                return headers.value[i].copy();
        }
        return strings.slice(0, 0);
    }

    function toLowercase(
        string memory str
    ) internal pure returns (string memory) {
        //大写变小写
        bytes memory bStr = bytes(str);
        for (uint i = 0; i < bStr.length; i++) {
            if ((bStr[i] >= 0x41) && (bStr[i] <= 0x5a)) {
                bStr[i] = bytes1(uint8(bStr[i]) + 32);
            }
        }
        return string(bStr);
    }

    function tabToSp(string memory str) internal pure returns (string memory) {
        //把制表符TAB转化为空格SPace
        bytes memory bStr = bytes(str);
        for (uint i = 0; i < bStr.length; i++) {
            if (bStr[i] == 0x09) bStr[i] = 0x20;
        }
        return string(bStr);
    }

    function trim(
        strings.slice memory self
    ) internal pure returns (strings.slice memory) {
        //trim：修剪 除去开头和结尾的空格、制表符、换行符
        strings.slice memory sp = "\x20".toSlice();
        strings.slice memory tab = "\x09".toSlice();
        strings.slice memory crlf = "\r\n".toSlice();
        if (self.startsWith(crlf)) {
            self._len -= 2;
            self._ptr += 2;
        }
        while (self.startsWith(sp) || self.startsWith(tab)) {
            self._len -= 1;
            self._ptr += 1;
        }
        if (self.endsWith(crlf)) {
            self._len -= 2;
        }
        while (self.endsWith(sp) || self.endsWith(tab)) {
            self._len -= 1;
        }
        return self;
    }

    function removeSPAtEndOfLines(
        strings.slice memory value
    ) internal pure returns (strings.slice memory) {
        //去除末尾的空格
        if (!value.contains("\x20\r\n".toSlice())) return value;
        strings.slice memory sp = "\x20".toSlice();
        strings.slice memory crlf = "\r\n".toSlice();
        uint count = value.count(crlf);
        strings.slice[] memory parts = new strings.slice[](count + 1);
        for (uint j = 0; j < parts.length; j++) {
            parts[j] = value.split(crlf);
            while (parts[j].endsWith(sp)) {
                parts[j]._len -= 1;
            }
        }
        return crlf.join(parts).toSlice();
    }

    function removeWSPSequences(
        strings.slice memory value
    ) internal pure returns (strings.slice memory) {
        //去除空格和制表符
        bool containsTab = value.contains("\x09".toSlice()); //\x09制表符
        if (!value.contains("\x20\x20".toSlice()) && !containsTab) return value; // \x20空格
        if (containsTab) value = tabToSp(value.toString()).toSlice();
        strings.slice memory sp = "\x20".toSlice();
        uint count = value.count(sp);
        strings.slice[] memory parts = new strings.slice[](count + 1);
        for (uint j = 0; j < parts.length; j++) {
            parts[j] = value.split(sp);
        }
        return joinNoEmpty(sp, parts).toSlice();
    }

    function ignoreEmptyLineAtEnd(
        strings.slice memory value
    ) internal pure returns (strings.slice memory) {
        //无视最后的换行符
        strings.slice memory emptyLines = "\r\n\r\n".toSlice();
        while (value.endsWith(emptyLines)) {
            value._len -= 2;
        }
        return value;
    }

    function unfoldContinuationLines(
        strings.slice memory value,
        bool isTrim
    ) internal pure returns (strings.slice memory) {
        //删除换行符
        strings.slice memory crlf = "\r\n".toSlice();
        uint count = value.count(crlf); //count：在value中一共包含几个crlf 具体几个赋值给count；
        if (count == 0) return value;
        strings.slice[] memory parts = new strings.slice[](count + 1);
        for (uint i = 0; i < parts.length; i++) {
            parts[i] = value.split(crlf);
            if (isTrim) parts[i] = trim(parts[i]);
        }
        return "".toSlice().join(parts).toSlice();
    }

    function stringToUint(string memory s) internal pure returns (uint result) {
        //字符串转化成uint
        bytes memory b = bytes(s);
        uint i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint c = uint8(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }

    function joinNoEmpty(
        strings.slice memory self,
        strings.slice[] memory parts
    ) internal pure returns (string memory) {
        if (parts.length == 0) return "";
        //将一个slice和slice数组进行拼接成一个字符串。
        uint length = 0;
        uint i;
        for (i = 0; i < parts.length; i++)
            if (parts[i]._len > 0) {
                length += self._len + parts[i]._len;
            }
        length -= self._len;

        string memory ret = new string(length);
        uint retptr;
        assembly {
            retptr := add(ret, 32)
        }

        for (i = 0; i < parts.length; i++) {
            if (parts[i]._len == 0) continue;
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        //复制内存块，给一个地址和长度进行复制
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IDKIMPublicKeyOracle {
    function setPublicKey(
        string calldata domain,
        string calldata selector,
        bytes calldata modulus,
        bytes calldata exponent
    ) external;

    function getRSAKey(string memory domain, string memory selector)
        external
        view
        returns (bytes memory modulus, bytes memory exponent);
}

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len1) private pure {
        // Copy word-length chunks while possible
        for(; len1 >= 32; len1 -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len1) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (self & bytes16(0xffffffffffffffffffffffffffffffff) == 0) { //把 uint256 类型的最大值type(uint256).max转换为bytes32类型进行位与运算
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (self & bytes8(0xffffffffffffffff) == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (self & bytes4(0xffffffff) == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (self & bytes2(0xffff) == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (self & bytes1(0xff) == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint256 mask = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff; // uint(-1)
                if(shortest < 32) {
                  mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                uint256 diff = (a & mask) - (b & mask);
                if (diff != 0)
                    return int(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        uint i;
        for(i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}