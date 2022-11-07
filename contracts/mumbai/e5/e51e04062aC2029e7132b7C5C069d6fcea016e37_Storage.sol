//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
//import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
//import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Storage {
    string public data;
    event dataSet(string dats);
    function setData(string memory newData) public {
        data = newData;
        emit dataSet(data);
    }
    function getData() public view returns (string memory dats) {
        return data;
    }
}