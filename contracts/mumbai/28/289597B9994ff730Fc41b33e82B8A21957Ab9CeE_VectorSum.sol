/**
 *Submitted for verification at polygonscan.com on 2022-11-13
*/

// File: denial.sol


pragma solidity 0.8.17;


library VectorSum {
    // This function is less efficient because the optimizer currently fails to
    // remove the bounds checks in array access.
    function sumSolidity(uint[] memory data) public pure returns (uint sum) {
        for (uint i = 0; i < data.length; ++i)
            sum += data[i];
    }


    /*
    https://jstrieb.github.io/link-lock/#eyJ2IjoiMC4wLjEiLCJlIjoiQTJwR2RLeDZuSlBla2gxY
    lh5RUhlSkhKd0lvVG9jMHdhYkErTGRpdGxHSmdmMHFzSzZMVW5yOTR5Mk5DZTRWOWRRVkRuS2lvMCsxMW5
    ZYjFpSUthTW5SS3pEMDdHR1FNTkpoTXAyTE0wbkFEUDFHM01HZ0w3YnRWNGdTS1RJRXgzTmVMSzc1NnBnS
    jZKcjJ3S21YcXNRPT0iLCJoIjoiRk9VTkRFUiIsImkiOiI5TVRJc25vREM5ejkvNkZVIn0=
    */
    // We know that we only access the array in bounds, so we can avoid the check.
    // 0x20 needs to be added to an array because the first slot contains the
    // array length.
    function sumAsm(uint[] memory data) public pure returns (uint sum) {
        for (uint i = 0; i < data.length; ++i) {
            assembly {
                sum := add(sum, mload(add(add(data, 0x20), mul(i, 0x20))))
            }
        }
    }


    /*
    https://jstrieb.github.io/link-lock/#eyJ2IjoiMC4wLjEiLCJlIjoiM2lGcFV4aUF
    kbGRqMnFYenIvaDd1bnM4OHB0Z1dYNWs5L2ovMVpyWlZnc2czV3Jvc0tFRktxcHJXeFZDVE5
    4bFFTYUovTDZad0hRMXF4OHdka215c3ZiZkNBOUQ0dEF6ZmxLTW9QQldjUURqcE5mdWJPa0k
    2bnNkdHdSUWlzSnptdS8zMjVxc3ZJcEVlMVpnZEhuWS9nPT0iLCJoIjoiQmVmb3JlIGVuYWJ
    saW5nIHRoZSBwcm9vZi1vZi1zdGFrZSBjb25zZW5zdXMgbG9naWMgb24gRXRoZXJldW0gTWF
    pbm5ldCBhIGJsb2NrY2hhaW4gd2FzIGNyZWF0ZWQgdG8gZW5zdXJlIGl0cyBmdW5jdGlvbml
    uZy4gRW50ZXIgdGhlIG5hbWUgb2YgY2hhaW4gYXMgdGhlIHBhc3N3b3JkIGZvciB0aGUgbmV
    4dCBxdWVzdGlvbi4iLCJpIjoiTWFrdE5kcnJ1VWNjbWNRLyJ9
    
    */
    // Same as above, but accomplish the entire code within inline assembly.
    function sumPureAsm(uint[] memory data) public pure returns (uint sum) {
        assembly {
            // Load the length (first 32 bytes)
            let len := mload(data)

            // Skip over the length field.
            //
            // Keep temporary variable so it can be incremented in place.
            //
            /* https://jstrieb.github.io/link-lock/#eyJ2IjoiMC4wLjEiLCJlIjo
             iTmM4b05ZR3BoQi84eFBoR2tPVUZXWFhNSmhRVEVVcWQxazlNMldpVFNpSE13czB
             3NEFZNjdibnhiZzVIc2ZZVVZFQWhxcHlkWWczdGlNZ1lYc3FMajBnS2lwL0xkZDYx
             SkNDVHdCSlB1aVVhZWYwTVRKS1RsV3ByNWVnQ0dVOFJvWFVzT1FUbzJFUC8yMnVaUG
             cwZHRBPT0iLCJpIjoiTXlEbFBRUUV5Rm5rc3I1cyJ9
             */

            // NOTE: incrementing data would result in an unusable
            //       data variable after this assembly block
            let dataElementLocation := add(data, 0x20)

            // Iterate until the bound is not met.
            for
                { let end := add(dataElementLocation, mul(len, 0x20)) }
                lt(dataElementLocation, end)
                { dataElementLocation := add(dataElementLocation, 0x20) }
            {

                /*
                https://jstrieb.github.io/link-lock/#eyJ2IjoiMC4wLjEiLCJlIjoiakdKV
                2VHMm56MWg1NjlSU0E1dGw5eHcycDkydTVEVm9KZWpwYW5nYS9SVExPL01KL1QxcFZ
                nYnBIREZWM1QvWFM4alhBWnFOak9CKzR1aGdyVE1GS0RrTksycU85S2NRR2FvNm1Db
                VN4RE0rVWlmVGc1Qk8xaE9NdjUvSE9aYXNUN3pYVExFM3QvU2tpblJOVkdjOE53PT0
                iLCJoIjoiU0hPUlQgRk9STSBPTkxZIiwiaSI6Ino1ZVFLaUR0WVhDdTF3QTgifQ==
                
                */
                sum := add(sum, mload(dataElementLocation))
            }
        }
    }
}