// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


contract VRFPizza{
    uint256 public slices;
    event IncreasePizza(bytes reqId, uint256 numSlices);


    constructor(uint256 _sliceCount)
    {
       slices = _sliceCount;
   }

   function eatSlice() external {
       require(slices > 1, "no slices left");
       slices -= 1;
   }

   function setPizzaSliceNumber(address addr) external {
    (bool success, bytes memory data) = addr.delegatecall(
            abi.encodeWithSignature("requestRandomWords()")
        );
        // requestRandomWords();

   }

   function refillSlice(address addr) external {

        (bool success, bytes memory reqId) = addr.delegatecall(
            abi.encodeWithSignature("lastRequestId()")
        );
        uint256 ureqId = bytesToUint(reqId);
        // uint256 reqId = this.lastRequestId();
        // (bool fulfilled, uint256[] memory numSlices)  = this.getRequestStatus(reqId);

        (bool fulfilled, bytes memory numSlices) = addr.delegatecall(
            abi.encodeWithSignature("getRequestStatus(uint256)",ureqId)
        );

        uint256 unumSlices = bytesToUint(numSlices);

        if (fulfilled) {
            emit IncreasePizza(reqId,unumSlices);
            slices += bytesToUint(numSlices);
        }
        
   }

   function pizzaVersion() external pure returns (uint256) {
       return 2;
   }

 function bytesToUint(bytes memory b) internal pure returns (uint256){
        uint256 number;
        for(uint i=0;i<b.length;i++){
            number = number + uint(uint8(b[i]))*(2**(8*(b.length-(i+1))));
        }
    return number;
}
   
}