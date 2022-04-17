//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;
 


contract Test { 

    function getAddr1() external pure returns (address) {
        return address(1);
    }

    event WhatAddress1(address a);
    function emitAddr1() external{ 
        emit WhatAddress1(address(1));
    }

    function getAddr2() external pure returns (address) {
        return address(2);
    }

    event WhatAddress2(address a);
    function emitAddr2() external{ 
        emit WhatAddress2(address(2));
    } 
 

    event SendETHEvent(address from, address to, uint256 amount);
    function pAddr(address payable from, address to) external{  
        (bool sent, bytes memory data) = to.call{value: from.balance}("");
        require(sent && (data.length == 0 || abi.decode(data, (bool))), "Err: Failure Calling"); 
        emit SendETHEvent(from, to, from.balance);
    }

}