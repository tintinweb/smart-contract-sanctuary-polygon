/**
 *Submitted for verification at polygonscan.com on 2022-04-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


contract delegate { 

    address public owner;

    address[] public stakers;
    address[] public swappers;
    address[] public stakerMultipleEpoch;


    mapping(address => uint16) public stakerMultipleEpochToSumDelegate;
    mapping(address => uint16) public stakerToSumDelegate;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    
    function addSwapper() public {
        if (IsNotRegisterSwapper(msg.sender)){
            swappers.push(msg.sender);
        }
    }

    function addStaker(uint16 _sum_delegate) public {
        require(_sum_delegate <= 1250);
        if (IsNotRegisterStacker(msg.sender) && IsNotRegisterMultiple(msg.sender)){
            stakers.push(msg.sender);
            stakerToSumDelegate[msg.sender] = _sum_delegate;

        }
    }

    function addStakerMultipleEpoch(uint16 _sum_delegate) public {
        require(_sum_delegate <= 1250);
        if (!IsNotRegisterStacker(msg.sender)){
            delStaker(msg.sender);
        }
        if (IsNotRegisterMultiple(msg.sender)){
            stakerMultipleEpoch.push(msg.sender);
            stakerMultipleEpochToSumDelegate[msg.sender] = _sum_delegate;
        }
    }

    function IsNotRegisterMultiple(address _msgSender) private view returns(bool){
        if(stakerMultipleEpochToSumDelegate[_msgSender]>0){
            return false;
        }
        else{
            return true;
        }

    }

    function IsNotRegisterSwapper(address _msgSender) private view returns(bool){
        uint i = IndexOf(_msgSender, swappers);

        if(i < swappers.length){
            return false;
        }
        else{
            return true;
        }

    }

    function IsNotRegisterStacker(address _msgSender) private view returns(bool){
        uint i = IndexOf(_msgSender, stakers);

        if(i < stakers.length){
            return false;
        }
        else{
            return true;
        }

    }

    function delStakerMultipleEpoch() public{

        uint i = IndexOf(msg.sender, stakerMultipleEpoch);
        uint len = stakerMultipleEpoch.length;

        stakerMultipleEpochToSumDelegate[msg.sender] = 0;

        if (i< len){
            
            if (len > 1){
                stakerMultipleEpoch[i] = stakerMultipleEpoch[len -1];
                stakerMultipleEpoch.pop();
            }
            else{
                delete stakerMultipleEpoch;
            }

            
        }
    }

    function delStaker(address _msgSender) private{

        uint i = IndexOf(_msgSender, stakers);
        uint len = stakers.length;

        stakerToSumDelegate[_msgSender] = 0;

        if (i< len){
            
            if (len > 1){
                stakers[i] = stakers[len -1];
                stakers.pop();
            }
            else{
                delete stakers;
            }

            
        }
    }

    function deleteStaker() public{

        uint i = IndexOf(msg.sender, stakers);
        uint len = stakers.length;

        stakerToSumDelegate[msg.sender] = 0;

        if (i< len){
            
            if (len > 1){
                stakers[i] = stakers[len -1];
                stakers.pop();
            }
            else{
                delete stakers;
            }

            
        }
    }

    function deleteSwapper() public{

        uint i = IndexOf(msg.sender, swappers);
        uint len = swappers.length;

        if (i< len){
            
            if (len > 1){
                swappers[i] = swappers[len -1];
                swappers.pop();
            }
            else{
                delete swappers;
            }

            
        }
    }

    function IndexOf(address addressToFind, address[] memory list) private pure returns(uint) {
        uint i = 0;
        uint len = list.length;
        while (i<len && list[i] != addressToFind) {
            i++;
        }
        return i;
    }

    function newEpoch() public onlyOwner {
        delete stakers;
        delete swappers;
    }

    function getStakers() public view returns (address[] memory, uint[] memory) {

        uint numberOfStakerMultipleEpoch = 0;

        for (uint i = 0; i<stakerMultipleEpoch.length; i++){
            numberOfStakerMultipleEpoch++;
        }

        uint len = stakers.length;

        address[] memory listStakerEpoch = new address[](numberOfStakerMultipleEpoch + len);
        uint[] memory listSumDelegate = new uint[](numberOfStakerMultipleEpoch + len);
        uint counter = 0;

        for (uint i = 0; i < len; i++){
            listStakerEpoch[counter] = stakers[i];
            listSumDelegate[counter] = stakerToSumDelegate[stakers[i]];
            counter++;

        }

        for (uint i = 0; i<stakerMultipleEpoch.length; i++){
            listStakerEpoch[counter] = stakerMultipleEpoch[i]; 
            listSumDelegate[counter] = stakerMultipleEpochToSumDelegate[stakerMultipleEpoch[i]];
            counter++;
        }

        return (listStakerEpoch,listSumDelegate);
    }

    function getSwappers() public view returns (address[] memory) {

        return swappers;
    }

}