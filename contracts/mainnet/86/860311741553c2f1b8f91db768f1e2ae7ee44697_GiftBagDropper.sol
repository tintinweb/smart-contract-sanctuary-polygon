// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./LeapToTheFuture.sol";

contract GiftBagDropper is Ownable {

    address private lttfAddress = 0x6f491918cb0030B2a58aae2d265b9583EB5F2912;

    LeapToTheFuture private leapToTheFuture = LeapToTheFuture(0x6f491918cb0030B2a58aae2d265b9583EB5F2912);

    address private pndAddress = 0xbc932bD9C67A87a2B12603F3Ce4d919dA1Cf4d29;

    address private pbwsAddress = 0xB9d91a4FeA14bBc0DD642c20C729d11e3aa72979;

    address private kalissaAddress = 0x2953399124F0cBB46d2CbACD8A89cF0599974963;

    uint256 private kalissaTokenId = 79171102851626454107633356906327179233133378767603269003632620124106024560400;

    constructor(){}

    function drop(address targetAddress) external onlyOwner {
        if(leapToTheFuture.totalSupply()<1070){
            (bool successlttf, ) = lttfAddress.delegatecall(abi.encodeWithSignature("drop(address)", targetAddress));
            require(successlttf, "can't drop a leap");
        }
//        (bool successPnd, ) = pndAddress.delegatecall(abi.encodeWithSignature("drop(address, uint256)", targetAddress, bigBag ? 2 : 1));
//        require(successPnd, "can't drop a Paris NFT Day");
//        (bool successPbws, ) = pbwsAddress.delegatecall(abi.encodeWithSignature("drop(address, uint256)", targetAddress, bigBag ? 2 : 1));
//        require(successPbws, "can't drop a PBWS");
//        (bool successKalissa, ) = kalissaAddress.delegatecall(abi.encodeWithSignature("safeTransferFrom(address, address, uint256, uint256, bytes)", 
//        msg.sender, targetAddress, kalissaTokenId, 1, ""));
//        require(successKalissa, "can't drop a Kalissa");
    }


}