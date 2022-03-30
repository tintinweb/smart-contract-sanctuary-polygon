/**
 *Submitted for verification at polygonscan.com on 2022-03-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface CallProxy{
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID
    ) external;
}

contract SourceChainAnyCall{
    //real one 0x37414a8662bC1D25be3ee51Fb27C2686e2490A89

    address private anycallcontractavax=0x37414a8662bC1D25be3ee51Fb27C2686e2490A89;
    address private owneraddress=0x4BBAaAf24f43416CD24CC006F092F050509ef94c;
    address private ftmsidecontract=0x976A603db8ea65ED2302f16e62faeAc8b3Ef4C8C;
    
    event NewMsg(string msg);
// /Swapin(bytes32,address,uint256)
    function step1_initiateAnyCallSimple(bytes32 _txhash, address _account, uint256 _amount) external {
        // emit NewMsg(_msg);
        if (msg.sender == owneraddress){
        CallProxy(anycallcontractavax).anyCall(
            ftmsidecontract,
            abi.encodeWithSignature("Swapin(bytes32,address,uint256)"
            ,_txhash,_account,_amount),
            address(0),
            250
            );        
        }
    }
}