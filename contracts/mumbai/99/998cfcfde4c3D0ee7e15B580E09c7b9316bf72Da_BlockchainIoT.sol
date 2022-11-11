/**
 *Submitted for verification at polygonscan.com on 2022-11-10
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract BlockchainIoT {
    address payable public ticketHolder;


    struct EndNodeDatum {
        uint sNo;
        uint256 deviceId;
        string deviceType;
        uint256 time;
        string data;
        string deviceOrigin;
    }

    mapping(uint => EndNodeDatum) endNodeData;
    uint dataCount=0;


    
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }


    
    function addData(
        uint256 deviceId,
        string memory deviceType,
        uint256 time,
        string memory data,
        string memory deviceOrigin
    ) 
    public payable returns (bool success) {

        endNodeData[dataCount] = EndNodeDatum({
         sNo: dataCount,
         deviceId: deviceId,
         deviceType:deviceType,
         time:time,
         data:data,
         deviceOrigin:deviceOrigin
        });

        dataCount += 1;

        success = true;

    }

    function getData(uint sNo) view public returns (EndNodeDatum memory){
        uint i;
        for(i=0;i<dataCount;i++){
            EndNodeDatum memory e = endNodeData[i];
            if(e.sNo  == sNo){
                return e;
         }
        }
        revert("No Data Found");
    }

    function findDataWithTime(uint256 time) public view returns(EndNodeDatum[] memory filteredData){
        EndNodeDatum[] memory tempData = new EndNodeDatum[](dataCount);
        uint count;
        for(uint i = 0; i<dataCount; i++){
        if (endNodeData[i].time == time) {
        tempData[count] = endNodeData[i];
        count += 1;
      }
        filteredData = new EndNodeDatum[](count);
        for(uint j = 0; j<count; j++){
        filteredData[j] = tempData[j];
    }
    }
    }

    function findDataWithValue(string memory value) public view returns(EndNodeDatum[] memory filteredData){
        EndNodeDatum[] memory tempData = new EndNodeDatum[](dataCount);
        uint count;
        for(uint i = 0; i<dataCount; i++){
        if (keccak256(abi.encodePacked(endNodeData[i].data)) == keccak256(abi.encodePacked(value))) {
        tempData[count] = endNodeData[i];
        count += 1;
      }
        filteredData = new EndNodeDatum[](count);
        for(uint j = 0; j<count; j++){
        filteredData[j] = tempData[j];
    }
    }
    }

    function findDataWithDeviceType(string memory deviceType) public view returns(EndNodeDatum[] memory filteredData){
        EndNodeDatum[] memory tempData = new EndNodeDatum[](dataCount);
        uint count;
        for(uint i = 0; i<dataCount; i++){
        if (keccak256(abi.encodePacked(endNodeData[i].deviceType)) == keccak256(abi.encodePacked(deviceType))) {
        tempData[count] = endNodeData[i];
        count += 1;
      }
        filteredData = new EndNodeDatum[](count);
        for(uint j = 0; j<count; j++){
        filteredData[j] = tempData[j];
    }
    }
    }

    function findDataWithDeviceOrigin(string memory source) public view returns(EndNodeDatum[] memory filteredData){
        EndNodeDatum[] memory tempData = new EndNodeDatum[](dataCount);
        uint count;
        for(uint i = 0; i<dataCount; i++){
        if (keccak256(abi.encodePacked(endNodeData[i].deviceOrigin)) == keccak256(abi.encodePacked(source))) {
        tempData[count] = endNodeData[i];
        count += 1;
      }
        filteredData = new EndNodeDatum[](count);
        for(uint j = 0; j<count; j++){
        filteredData[j] = tempData[j];
    }
    }
    }

    function findDataWithDeviceId(uint256 id) public view returns(EndNodeDatum[] memory filteredData){
        EndNodeDatum[] memory tempData = new EndNodeDatum[](dataCount);
        uint count;
        for(uint i = 0; i<dataCount; i++){
        if (endNodeData[i].deviceId == id) {
        tempData[count] = endNodeData[i];
        count += 1;
      }
        filteredData = new EndNodeDatum[](count);
        for(uint j = 0; j<count; j++){
        filteredData[j] = tempData[j];
    }
    }
    }

    function withdraw (uint _amount) public onlyOwner { 
        owner.transfer(_amount); 
    }

    function transfer(address payable _to, uint _amount) public onlyOwner { 
        _to.transfer(_amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    } 

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}