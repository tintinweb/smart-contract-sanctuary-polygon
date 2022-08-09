/**
 *Submitted for verification at polygonscan.com on 2022-08-09
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract YourContract {
    /* CONSTANTS */
    uint256 constant P =
        0xE96C6372AB55884E99242C8341393C43953A3C8C6F6D57B3B863C882DEFFC3B7;
    uint256 constant SMALL_G =
        3609472609450558415322054059839388445246177378959585025421325851028889817616;
    address payable constant owner =
        payable(0xB986AE15b82d88b81A10E9E2B7fa13A7b9254fF4);

    /* MODIFIERS */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /* UTILS */
    function stringToUint(string memory s)
        internal
        pure
        returns (uint256 result)
    {
        bytes memory b = bytes(s);
        uint256 i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint8 c = uint8(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }

    function substring(string memory str, uint256 startIndex)
        internal
        pure
        returns (string memory)
    {
        bytes memory strBytes = bytes(str);
        uint256 endIndex = strBytes.length;
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function verifyString(
        string memory message,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (address signer) {
        // The message header; we will fill in the length next
        string memory header = "\x19Ethereum Signed Message:\n000000";

        uint256 lengthOffset;
        uint256 length;
        assembly {
            // The first word of a string is its length
            length := mload(message)
            // The beginning of the base-10 message length in the prefix
            lengthOffset := add(header, 57)
        }

        // Maximum length we support
        require(length <= 999999);

        // The length of the message's length in base-10
        uint256 lengthLength = 0;

        // The divisor to get the next left-most message length digit
        uint256 divisor = 100000;

        // Move one digit of the message length to the right at a time
        while (divisor != 0) {
            // The place value at the divisor
            uint256 digit = length / divisor;
            if (digit == 0) {
                // Skip leading zeros
                if (lengthLength == 0) {
                    divisor /= 10;
                    continue;
                }
            }

            // Found a non-zero digit or non-leading zero digit
            lengthLength++;

            // Remove this digit from the message length's current value
            length -= digit * divisor;

            // Shift our base-10 divisor over
            divisor /= 10;

            // Convert the digit to its ASCII representation (man ascii)
            digit += 0x30;
            // Move to the next character and write the digit
            lengthOffset++;

            assembly {
                mstore8(lengthOffset, digit)
            }
        }

        // The null string requires exactly 1 zero (unskip 1 leading 0)
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }

        // Truncate the tailing zeros from the header
        assembly {
            mstore(header, lengthLength)
        }

        // Perform the elliptic curve recover operation
        bytes32 check = keccak256(abi.encodePacked(header, message));

        return ecrecover(check, v, r, s);
    }

    function calculate_result(
        uint256 one,
        uint256 two,
        uint256 id
    ) internal view returns (uint256) {
        return
            (((one + two) % P) % (processes[id].d - processes[id].z)) +
            processes[id].z;
    }

    function calculate_messages(string memory s1, string memory s2)
        internal
        pure
        returns (uint256)
    {
        string memory num_1_str = substring(s1, 14);
        uint256 num_1 = stringToUint(num_1_str);
        string memory num_2_str = substring(s2, 14);
        uint256 num_2 = stringToUint(num_2_str);
        require(num_1 == num_2);

        return num_1;
    }

    /* STATE */
    struct ProcessData {
        uint256 id;
        bool initiated;
        address alice;
        address bob;
        uint256 z;
        uint256 d;
        uint256 alice_encryption;
        uint256 bob_encryption;
        uint256 res;
    }

    struct Sig {
        string message;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    mapping(uint256 => ProcessData) processes;

    /* EVENTS */
    event Encrypted(uint256 indexed id, address indexed from, uint256 e);
    event Revealed(
        uint256 indexed id,
        address indexed from,
        uint256 coeff,
        uint256 rng
    );
    event Done(uint256 indexed id, uint256 result);

    /* LOGIC */
    function InitiateEncryption(
        uint256 id,
        address other,
        uint256 e,
        uint256 z,
        uint256 d
    ) public {
        require(!processes[id].initiated);

        processes[id].id = id;
        processes[id].initiated = true;
        processes[id].alice = msg.sender;
        processes[id].bob = other;
        processes[id].z = z;
        processes[id].d = d;
        processes[id].alice_encryption = e;

        emit Encrypted(id, msg.sender, e);
    }

    function AcceptEncryption(uint256 id, uint256 e) public {
        require(msg.sender == processes[id].bob);
        require(processes[id].initiated);

        processes[id].bob_encryption = e;

        emit Encrypted(id, msg.sender, e);
    }

    function Finish(
        uint256 id,
        uint256 coeff1,
        uint256 rng1,
        uint256 coeff2,
        uint256 rng2,
        Sig calldata s1,
        Sig calldata s2
    ) public {
        require(processes[id].initiated);
        require(msg.sender == processes[id].bob);

        uint256 num_1 = calculate_messages(s1.message, s2.message);
        processes[id].res = calculate_result(rng1, rng2, id);
        require(num_1 == processes[id].res);

        require(
            verifyString(s1.message, s1.v, s1.r, s1.s) == processes[id].alice
        );
        require(
            verifyString(s1.message, s2.v, s2.r, s2.s) == processes[id].bob
        );

        emit Revealed(id, processes[id].alice, coeff1, rng1);
        emit Revealed(id, processes[id].bob, coeff2, coeff2);
        emit Done(id, processes[id].res);
    }

    /* PAYMENT */
    function withdrawal(uint256 value) public onlyOwner {
        (bool sent, bytes memory data) = owner.call{value: value}("");
        require(sent);
    }

    receive() external payable {}

    fallback() external payable {}
}