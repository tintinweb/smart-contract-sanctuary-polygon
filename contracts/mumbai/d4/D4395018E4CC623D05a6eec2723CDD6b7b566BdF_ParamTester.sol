// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract ParamTester {

    struct Params {
        uint32  n32;
        uint256 n256;
        string   s;
        string[] sa;
    }

    Params public newParam;

    constructor() {

    }

    function sendBigNum(uint256 _n256) public {
        newParam.n256 = _n256;
    }

    function sendUints(uint256 _n256, uint32 _n32) public {
        newParam.n32 = _n32;
        newParam.n256 = _n256;
    }

    function sendStr(string memory _s) public {
        newParam.s = _s;
    }

    function sendStrArray(string[] memory _sa) public {
        Params memory _p = Params(0, 0, "", _sa);
        newParam = _p;
    }

    function sendAll(uint256 _n256, uint32 _n32, string memory _s, string[] memory _sa) public {
        Params memory _p = Params(_n32, _n256, _s, _sa);
        newParam = _p;
    }

    function getStrArray() public view returns(string[] memory) {
        string[] memory _sa = newParam.sa;
        return _sa;
    } 

    function getParam() public view returns(Params memory) {
        return newParam;
    }
}