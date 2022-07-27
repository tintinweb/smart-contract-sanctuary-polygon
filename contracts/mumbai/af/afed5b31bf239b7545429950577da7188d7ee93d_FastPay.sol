/**
 *Submitted for verification at polygonscan.com on 2022-07-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract FastPay {

    struct Withdraw {
        uint8 v;
        bytes32 r;
        bytes32 s;
        string orderNo;
        address token;
        address merchant;
        uint256 merchantAmt;
        address proxy;
        uint256 proxyAmt;
        uint256 fee;
        uint256 deadLine;
    }


   
    function verifyFee(
        Withdraw memory withdraw
    ) view public returns (address) {
        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("CashSweep")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256("cashSweep(address merchant,uint256 merchantAmt,address proxy,uint256 proxyAmt,uint256 fee,uint256 deadLine)"),
                withdraw.merchant,
                withdraw.merchantAmt,
                withdraw.proxy,
                withdraw.proxyAmt,
                withdraw.fee,
                withdraw.deadLine
            )
        );

        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
        address signer = ecrecover(hash, withdraw.v, withdraw.r, withdraw.s);
       return signer;
       
    }

    function getTimes() view public returns(uint256) {
        return block.timestamp;
    }


}