// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./Address.sol";
import "./Pausable.sol";
import "./AggregatorV3Interface.sol";
import "./IPreSale.sol";
import "./IAgoraCollection.sol";

contract AgoraMinting is  Ownable , Pausable{
    
    using Address for address payable;

    IPreSale private presaleContract;
    IAgoraCollection private collection;
    
    constructor(){
        presaleContract = IPreSale(0x47F2f2980a1E4C27F14E9Af1C6a8Dc75c02A1445);
        collection = IAgoraCollection(0xb88701468549554CC6E4D3Db70230277AC9955DD);
    }
    
    function presales(uint256 startIndex, uint256 endIndex) external payable {
        require(!paused(), "is on pause !");
        require(startIndex >= 0, "bad startIndex");
        require(endIndex > startIndex, "bad endIndex");
        for( uint256  i = startIndex; i < endIndex;i++ ){
            address userAddress = presaleContract.preSalesAddress(i);
            uint256 userCount = presaleContract.preSalesQuantity(i);
            collection.drop(userAddress,userCount);
        }
    }
 
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
         
}