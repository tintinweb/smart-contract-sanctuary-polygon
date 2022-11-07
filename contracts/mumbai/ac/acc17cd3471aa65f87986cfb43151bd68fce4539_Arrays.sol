/**
 *Submitted for verification at polygonscan.com on 2022-11-07
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Arrays {
    string[5] shoplist;

    function updateElem(uint _numupd, string memory _productoupd) external returns (string memory) {
        shoplist[_numupd] = _productoupd;
        return "Update";
    }

    function deleteElem(uint _numdel) external returns (string memory) {
        delete shoplist[_numdel];
        return "Deleted";
    }

    function getLongList() external view returns (uint) {
        return shoplist.length;
    }

    function getElem(uint _numelem) external view returns (string memory) {
        return shoplist[_numelem];
    }

    function getList() external view returns (string[5] memory) {
        return shoplist;
    }
}