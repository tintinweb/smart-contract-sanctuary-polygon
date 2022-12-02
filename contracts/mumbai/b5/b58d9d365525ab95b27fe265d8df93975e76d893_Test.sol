/**
 *Submitted for verification at polygonscan.com on 2022-12-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;


contract Test {
    uint256 public number;
    uint256 public value;
    mapping(address => bool) public whitelist;

    function setValue(uint256 _value) public {
        value = _value;
    }

    function setWhitelist(address _addr, bool _status) public {
        whitelist[_addr] = _status;
    }


    function add() public {
        number += 1;
        emit MsgSender(msg.sender);
        emit TxOrigin(tx.origin);
    }

    function addWhitelisted(address _addr) public {
        require(whitelist[_addr],"Not whitelisted");
        number += 1;
        emit MsgSender(msg.sender);
        emit TxOrigin(tx.origin);
    }

    function addParam(uint256 _num) public {
        number += _num;
        emit MsgSender(msg.sender);
        emit TxOrigin(tx.origin);
    }

    function addParamPayable() public payable {
        number += msg.value;
        emit MsgSender(msg.sender);
        emit TxOrigin(tx.origin);
    }

        function addParamPayableR() public payable {
        require(msg.value >= value);
        number += msg.value;
        emit MsgSender(msg.sender);
        emit TxOrigin(tx.origin);
    }

    function withdraw() public {
        payable(msg.sender).transfer(address(this).balance);
    }

    function emitterSender() public {
        emit MsgSender(msg.sender);
    }

    function emitterTxOrigin() public {
        emit TxOrigin(tx.origin);
    }

    event MsgSender(address);
    event TxOrigin(address);

}