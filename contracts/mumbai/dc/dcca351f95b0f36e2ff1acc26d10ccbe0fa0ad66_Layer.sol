/**
 *Submitted for verification at polygonscan.com on 2022-06-14
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

   

    
contract Layer {


    mapping(address => address) public referrer;

    event ReferrerAdded(address from,address to);


    ///
    function initUser(address to) external   {
        require(referrer[msg.sender] == address(0), 'Layer::addReferrer: alreday add!');
        require(referrer[to] != address(0), 'Layer::addReferrer: invalid referrer!');
        _addReferrer(msg.sender, to);
    }


    ///
    function _addReferrer(address from, address to) private {
        referrer[from] = to;
        emit ReferrerAdded(to, from);
    }

}