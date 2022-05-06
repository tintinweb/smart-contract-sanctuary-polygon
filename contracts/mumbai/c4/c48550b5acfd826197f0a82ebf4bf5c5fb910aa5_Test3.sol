/**
 *Submitted for verification at polygonscan.com on 2022-05-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;


contract Test3 {

    mapping(uint256 => uint256[]) private _arr;

    function add(uint256 _epochId, uint256 _ideaId) external {
        require(_epochId != 0, "Invalid epochId");
        require(_ideaId != 0, "Invalid ideaId");
        _arr[_epochId].push(_ideaId);
    }

    function get(uint256 _epochId, uint256 index) external view returns (uint256) {
        return _arr[_epochId][index];
    }

    function del(uint256 _epochId) external {
        delete _arr[_epochId];
    }
}