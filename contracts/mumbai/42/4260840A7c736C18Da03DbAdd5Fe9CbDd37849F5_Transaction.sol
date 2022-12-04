/**
 *Submitted for verification at polygonscan.com on 2022-12-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Transaction {

    event SubmitTransaction(
        string adId,
        uint256 spendLimit,
       string imageUrl,
        string imagesize,
        string cta,
        string desc,
        bool status,
        string[] indexed personid,
        string  _clickTag,
        address _publisherId
    );
    event SettleTransaction(
        string adId,
        bool status
    );

    struct Transaction {
string adId;
uint256 spendLimit;
        string imageUrl;
        string imageSize;
        string cta;
        string desc;
        bool status;
        string[] personid;
        string clickTag;
        address publisherId;
    }
    
    mapping(string => Transaction) public transactions;

 
   

    constructor() {
        
    }

    function submitTransaction(
        string memory _adId,
        uint256 _spendLimit,
        string memory _imageUrl,
        string memory _imageSize,
        string memory _cta,
        string memory _desc,
        string[] calldata _personid,
        string memory _clickTag,
        address _publisherId
    ) public {

        transactions[_adId] = Transaction({
            adId:_adId,
            spendLimit:_spendLimit,
            imageUrl:_imageUrl,
            imageSize:_imageSize,
            cta:_cta,
            desc:_desc,
            status:true,
            personid:_personid,
            clickTag: _clickTag,
            publisherId:_publisherId
        });

        emit SubmitTransaction(_adId,_spendLimit,_imageUrl, _imageSize, _cta, _desc, true,_personid,_clickTag,_publisherId);
    }
    function settleTransaction(
        string memory _adId,
        uint256 _spendLimit
    ) public {

    Transaction storage someStruct = transactions[_adId];
    someStruct.status=false;
    someStruct.spendLimit=someStruct.spendLimit-_spendLimit;

    emit SettleTransaction(_adId,false);

    }

  
}