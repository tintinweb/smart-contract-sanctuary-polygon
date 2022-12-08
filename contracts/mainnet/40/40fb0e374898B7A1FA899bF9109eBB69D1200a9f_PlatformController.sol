/**
 *Submitted for verification at polygonscan.com on 2022-12-08
*/

/**
 *Submitted for verification at hecoinfo.com on 2022-01-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

interface Platform {

    function platformWithdraw(address _tokenContract) external;
}

address constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

address constant PlatformAddress = 0xfE94035585cF6695446204682c4e3CB09Dc74041;

contract PlatformController {

    address[] _addresss;

    constructor () {
        _addresss.push(USDT);
    }

    function insert(address _tokenContract) external
    {
        _addresss.push(_tokenContract);
    }

    function platformWithdraw() external
    {
        for (uint i=0; i<_addresss.length; i++)
        {
            Platform(PlatformAddress).platformWithdraw(_addresss[i]);
        }
    }

}