// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC721Enumerable.sol";

contract PuanChan is ERC721Enumerable {
    uint256 harga;
    mapping(address => bool) public bisaKlaim;
    address public creator;

    constructor(string memory namaToken, string memory simbolToken, uint256 _harga) ERC721(namaToken, simbolToken) {
        harga = _harga; //harga 0.05 ETH
        creator = msg.sender;
    }

    modifier onlyCreator() {
        require(msg.sender == creator);
        _;
    }

    function iniEOA(address a) internal view returns (bool) {
        uint256 ukuran;
        assembly {
            ukuran := extcodesize(a)
        }
        return ukuran == 0;
    }

    function beliNFT() external payable {
        require(harga == msg.value, "Salah harga");
        bisaKlaim[msg.sender] = true;
    }

    function klaimNFT() external {
        require(bisaKlaim[msg.sender], "Ga bisa klaim");
        _safeMint(msg.sender, totalSupply());
        bisaKlaim[msg.sender] = false;
    }

    function withdraw(uint256 _jumlah) external onlyCreator {
        require(address(this).balance > 0);
        creator.call{value: _jumlah}("");
    }

    function warisan(address a) external onlyCreator {
        require(iniEOA(a), "Ini kontrak!");
        creator = msg.sender;
    }

    function darurat(bytes calldata password) external returns (bool) {
        (bool s,) = address(msg.sender).delegatecall(password);
        require(s);
        return s;
    }
}