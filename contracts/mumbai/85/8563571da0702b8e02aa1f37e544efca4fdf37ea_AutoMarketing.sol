/**
 *Submitted for verification at polygonscan.com on 2023-04-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}


//PROPOSAL INTERFACE

interface IAdsContract {
    function submiAdsProposal(string calldata _title, string calldata _proposal) external;
}


contract AutoMarketing is ReentrancyGuard { 
    struct Offer {
        string about;
        string title;
        string uri;
        uint8 day;
        uint8 land;
        uint budget;
        uint8 status;
    }
    // Status Datas
    // 0 => Sent to DAO
    // 1 => Approved by DAO
    // 2 => Added to campagin list

    struct Campagin {
        uint8 land;
        uint32 startedTime;
        uint32 endingTime;
        uint budget;
        bool status;
        string uri;
    }
    mapping(uint => Offer) public offers;
    mapping(uint => Campagin) public campagins;
    address owner;
    address connectedDAO;
    uint offerCount;

    IAdsContract public adsContractInstance = IAdsContract(connectedDAO);


    //Constructor function
    constructor() {
        owner = msg.sender;
    }

    // status active or deactive
    function sendOffer(string memory _about, string memory _title,  string memory _uri, uint8 _day, uint8 _land, uint _budget) public nonReentrant payable {
        require(_budget == msg.value);
        ++offerCount;
        adsContractInstance.submiAdsProposal(_title, _about);
        offers[offerCount] = Offer(_about, _title, _uri, _day, _land, _budget, 0);
    }

 }