/**
 *Submitted for verification at polygonscan.com on 2023-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract createContract{
    animeContract[] public contractsList;
    address[] public contractAddressList;

    function createSampleContract() external {
        animeContract newContract=new animeContract("naruto");
        contractsList.push(newContract);
        contractAddressList.push(address(newContract));
        
    }

    function getContractAddress(uint n) external view returns(address){
        return contractAddressList[n];
    }
}

contract animeContract{
    string favorateAnime;
    constructor(string memory _favorateAnime){
        favorateAnime = _favorateAnime;
    }
    function returnAnimeName() public view returns(string memory){
        return favorateAnime;
    }

}