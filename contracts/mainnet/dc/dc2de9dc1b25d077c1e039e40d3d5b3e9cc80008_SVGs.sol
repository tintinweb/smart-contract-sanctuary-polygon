/**
 *Submitted for verification at polygonscan.com on 2023-04-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SVGs {

    string private baseSVG;
    string private finishSVG;
    address private owner;
    string private longSVG;

    constructor (address newOwner){
        baseSVG='<svg xmlns="http://www.w3.org/2000/svg" height="720" width="720" viewBox="0 0 720 720" xml:space="preserve"><style>@import url(https://fonts.googleapis.com/css?family=Bebas+Neue);</style><foreignObject id="background" width="720" height="720"><style>#background{background:#b04aff;background:linear-gradient(360deg,#b04aff 0,#7a25ed 50%,#7100da 100%)}</style></foreignObject><text x="50%" y="40%" dominant-baseline="middle" text-anchor="middle" style="fill:#fff;font-family:CooperBlack;font-size:70px"><tspan style="font-size:26px">raise capital through</tspan> </text><text x="50%" y="48%" dominant-baseline="middle" text-anchor="middle" font-family="Bebas Neue" style="fill:#fff;font-size:40px"> <tspan> flashare.app <tspan style="font-size:100px"> /';
        finishSVG=' </tspan> </tspan> </text><text x="50%" y="95%" dominant-baseline="middle" text-anchor="middle" font-family="Bebas Neue" style="fill:#fff;font-size:25px">Flashare Name Service</text><text x="50%" y="90%" dominant-baseline="middle" text-anchor="middle" font-family="Bebas Neue" style="fill:#fff;font-size:40px;font-weight:700">FNS</text></svg>';
        longSVG = '<svg xmlns="http://www.w3.org/2000/svg" height="720" width="720" viewBox="0 0 720 720" xml:space="preserve"><style>@import url(https://fonts.googleapis.com/css?family=Bebas+Neue);</style><foreignObject id="background" width="720" height="720"><style>#background{background:#b04aff;background:linear-gradient(360deg,#b04aff 0,#7a25ed 50%,#7100da 100%)}</style></foreignObject><text x="50%" y="40%" dominant-baseline="middle" text-anchor="middle" style="fill:#fff;font-family:CooperBlack;font-size:70px"><tspan style="font-size:26px">raise capital through</tspan> </text><text x="50%" y="48%" dominant-baseline="middle" text-anchor="middle" font-family="Bebas Neue" style="fill:#fff;font-size:40px"> <tspan> flashare.app </tspan> </text><text x="50%" y="95%" dominant-baseline="middle" text-anchor="middle" font-family="Bebas Neue" style="fill:#fff;font-size:25px">Flashare Name Service</text><text x="50%" y="90%" dominant-baseline="middle" text-anchor="middle" font-family="Bebas Neue" style="fill:#fff;font-size:40px;font-weight:700">FNS</text></svg>';
        owner = newOwner;
    }

    function getBaseSVG()public view returns(string memory){
        return baseSVG;
    }

    function getFinishSVG()public view returns(string memory){
        return finishSVG;
    }

    function viewLongSVG()public view returns(string memory){
        return longSVG;
    }

    function changeBaseSVG(string memory base)external {
        require(msg.sender==owner,"only owner");
        baseSVG=base;
    }

    function changeFinishSVG(string memory finish)external {
        require(msg.sender==owner,"only owner");
        finishSVG=finish;
    }

    function changeLongSVG(string memory _longSVG)external{
        require(msg.sender==owner,"only owner");
        longSVG=_longSVG;
    }

}