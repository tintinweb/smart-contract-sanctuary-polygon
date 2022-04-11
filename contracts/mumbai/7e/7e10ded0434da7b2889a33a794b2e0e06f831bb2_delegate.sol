/**
 *Submitted for verification at polygonscan.com on 2022-04-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

struct Staker {
    address staker;
    uint16 sum_delegate;
    uint256 timeIndex;
}

struct Swapper {
    address swapper;
    uint256 timeIndex;
}

contract delegate { 

    address public owner;

    Staker[] public stakers;
    Swapper[] public swappers;
    address[] public stakerMultipleEpoch;

    uint256 public TimeIndex;

    mapping(address => uint16) public stakerMultipleEpochToSumDelegate;

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

    function addStaker(uint16 _sum_delegate) public {
        require(_sum_delegate <= 30000);
        stakers.push(Staker(msg.sender, _sum_delegate, TimeIndex));
    }

    function addStakerMultipleEpoch(uint16 _sum_delegate) public {
        require(_sum_delegate <= 30000);
        if (IsNotRegister(msg.sender)){
            stakerMultipleEpoch.push(msg.sender);
            stakerMultipleEpochToSumDelegate[msg.sender] = _sum_delegate;
        }
    }

    function IsNotRegister(address _msgSender) public view returns(bool){
        if(stakerMultipleEpochToSumDelegate[_msgSender]>0){
            return false;
        }
        else{
            return true;
        }

    }

    function delStakerMultipleEpoch() public{
        /* Soit
        * stakerMultipleEpochToSumDelegate[msg.sender] = 0;
        * et on ignore les staker avec 0 de délégué plus loin
        *
        * ou utilisation de la fonction indexOf pour le supprimer de la list, prbl c'est plus cher en gas : 
        * uint i = IndexOf(msg.sender);
        * stakerMultipleEpoch[i] = stakerMultipleEpoch[stakerMultipleEpoch.length -1];
        * stakerMultipleEpoch.pop();
        */

        uint i = IndexOf(msg.sender);
        stakerMultipleEpoch[i] = stakerMultipleEpoch[stakerMultipleEpoch.length -1];
        stakerMultipleEpoch.pop();
    }

    function IndexOf(address stakerToFind) public view returns(uint) {
        uint i = 0;
        uint len = stakerMultipleEpoch.length;
        while (stakerMultipleEpoch[i] != stakerToFind && i<len ) {
            i++;
        }
        return i;
    }

    function addSwapper() public {
        swappers.push(Swapper(msg.sender, TimeIndex));
    }

    function newEpoch() public onlyOwner {
        TimeIndex = block.timestamp;
    }

    function getStakers() public view returns (Staker[] memory) {

        uint numberOfStaker = 0;

        for (uint i = stakers.length - 1; i > 0; i--){
            if (stakers[i].timeIndex == TimeIndex) {
                numberOfStaker++;
                continue;
            }
            else if (numberOfStaker>0){
                break;
            }
        }

        for (uint i = 0; i<stakerMultipleEpoch.length; i++){
            numberOfStaker++;
        }

        Staker[] memory listStakerEpoch = new Staker[](numberOfStaker + 1);
        uint counter = 0;

        for (uint i = stakers.length - 1; i > 0; i--){
            if (stakers[i].timeIndex == TimeIndex) {
                listStakerEpoch[counter] = stakers[i];
                counter++;
                continue;
            }
            else if (listStakerEpoch.length>0){
                break;
            }
        }

        if (stakers[0].timeIndex == TimeIndex) {
            listStakerEpoch[counter] = stakers[0];
            counter++;

        }

        for (uint i = 0; i<stakerMultipleEpoch.length; i++){
            listStakerEpoch[counter] = Staker(stakerMultipleEpoch[i], stakerMultipleEpochToSumDelegate[stakerMultipleEpoch[i]], TimeIndex);
            counter++;
        }

        return listStakerEpoch;
    }

    function getSwappers() public view returns (Swapper[] memory) {

        uint numberOfSwapper = 0;

        for (uint i = swappers.length - 1; i > 0; i--){
            if (swappers[i].timeIndex == TimeIndex) {
                numberOfSwapper++;
                continue;
            }
            else if (numberOfSwapper>0){
                break;
            }
        }

        Swapper[] memory listSwapperEpoch = new Swapper[](numberOfSwapper + 1);
        uint counter = 0;

        for (uint i = swappers.length - 1; i > 0; i--){
            if (swappers[i].timeIndex == TimeIndex) {
                listSwapperEpoch[counter] = swappers[i];
                counter++;
                continue;
            }
            else if (listSwapperEpoch.length>0){
                break;
            }
        }

        if (swappers[0].timeIndex == TimeIndex) {
            listSwapperEpoch[counter] = swappers[0];
        }

        return listSwapperEpoch;
    }

}