/**
 *Submitted for verification at polygonscan.com on 2022-10-20
*/

pragma solidity ^0.8.4;

contract assetsContract{
    struct asset{
        string name;
        string owner;
        string dor;
        uint id;
        string status;
    }

    mapping(uint => asset) public Assets; //id should be unique in asset

    function saveAsset (string memory _name, string memory _owner, string memory _dor, uint _id, string memory _status) external{
            asset memory assetstr;
            assetstr.name = _name;
            assetstr.owner = _owner;
            assetstr.dor = _dor;
            assetstr.id = _id;
            assetstr.status = _status;

            Assets[assetstr.id] = assetstr;
    }

    function getAsset(uint _id) public view returns(asset memory){
        return Assets[_id];
    }

    function trackAsset(uint _id) public view returns(string memory){
        return Assets[_id].status;
    }
}