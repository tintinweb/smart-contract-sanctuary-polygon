/*
 * SPDX-License-Identitifer:    GPL-3.0-or-later
 */
pragma experimental ABIEncoderV2;
pragma solidity 0.4.24;

import "../../../lib/ArrayUtils2.sol";

contract WhiteList  {
    using ArrayUtils2 for address[];
    address owner;
    mapping(address => bool) public whiteListAdded; 
    address[] internal whiteList; 

    event ParticipantAdded(address _participant);
    event ParticipantRemoved(address _participant);
    modifier onlyOwner() {
        require(msg.sender == owner, "NOT_THE_OWNER");
        _;
    }
    constructor(){
        owner = msg.sender;
    }
    function addParticipants(address[] _participant) onlyOwner public  {
        for (uint256 i = 0; i < _participant.length; i++) {
            _addParticipant(_participant[i]);
        }
    }

    function _addParticipant(address _participant) internal {
        require(whiteList.length < 20, "LIST FULL");
        require(!whiteListAdded[_participant], "ALREADY ADDED");

        whiteListAdded[_participant] = true;
        whiteList.push(_participant);
        emit ParticipantAdded(_participant);
    }

    function addParticipant(address _participant) onlyOwner public {
        _addParticipant(_participant);
    }
    
    function fromWhiteList(address _participant) view public returns(bool){
        return whiteListAdded[_participant];
    }

    function removeParticipant(address _participant) onlyOwner external {
        require(whiteListAdded[_participant], "ERROR_TOKEN_NOT_ADDED");
        whiteListAdded[_participant] = false;
        whiteList.deleteItem(_participant);
        emit ParticipantRemoved(_participant);
    }


}

pragma solidity ^0.4.24;

library ArrayUtils2 {
    function deleteItem(address[] storage self, address item)
        internal
        returns (bool)
    {
        uint256 length = self.length;
        for (uint256 i = 0; i < length; i++) {
            if (self[i] == item) {
                uint256 newLength = self.length - 1;
                if (i != newLength) {
                    self[i] = self[newLength];
                }

                delete self[newLength];
                self.length = newLength;

                return true;
            }
        }
    }
}