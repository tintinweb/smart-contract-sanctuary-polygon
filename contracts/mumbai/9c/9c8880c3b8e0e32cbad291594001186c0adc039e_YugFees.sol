/**
 *Submitted for verification at polygonscan.com on 2023-02-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IAdmin {
    function isValidAdmin(address adminAddress) external view returns (bool);
}

contract YugFees {

    address _admin;
    address public _treasury;

    mapping(uint64 => uint256) public _by_kind_request_fees;
    mapping(uint64 => uint256) public _by_kind_share_fees;


    constructor() {
    }

    function initialize(address admin) public {
        require(_admin == address(0) || IAdmin(_admin).isValidAdmin(msg.sender), "Unauthorized");
        _admin = admin;
    }

    function setTreasury(address treasury) public {
        require(IAdmin(_admin).isValidAdmin(msg.sender), "Unauthorized");
        _treasury = treasury;
    }

    function setFee(uint64 kind, uint256 fee_for_requesting, uint256 fee_for_sharing) public {
        require(IAdmin(_admin).isValidAdmin(msg.sender), "Unauthorized");
        _by_kind_request_fees[kind] = fee_for_requesting;
        _by_kind_share_fees[kind] = fee_for_sharing;
    }

    function findFee(uint64 kind) public view returns (address, uint256, uint256) {
        return (_treasury, _by_kind_request_fees[kind],  _by_kind_share_fees[kind]);
    }
}