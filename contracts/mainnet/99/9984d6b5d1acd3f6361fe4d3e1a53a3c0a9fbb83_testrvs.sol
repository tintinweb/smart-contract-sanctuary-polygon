/**
 *Submitted for verification at polygonscan.com on 2022-10-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract testrvs{

 function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s,uint nonces) public view virtual returns (address){
        require(deadline >= block.timestamp, 'NON: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                "0xe07dcf94c21bdc1bbdbeae29930d31d08a045b0ad05769fcc4a7fd39db6efbde",
                keccak256(abi.encode("0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9", owner, spender, value, nonces, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        return recoveredAddress;
    }
}