/**
 *Submitted for verification at polygonscan.com on 2022-07-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "./Gravyard_0.sol";
// import "./Gravyard_1.sol";
// import "./Gravyard_2.sol";
// import "./Gravyard_3.sol";

interface IGravyard_0{
   function buyNFt(address _to, uint256 _tokenId) external payable returns(bool); 
}

interface IGravyard_1{
    function buyNFt(address _to, uint256 _tokenId) external payable returns(bool);
}

interface IGravyard_2{
    function buyNFt(address _to, uint256 _tokenId) external payable returns(bool);
}

interface IGravyard_3{
    function buyNFt(address _to, uint256 _tokenId) external payable returns(bool);
}


contract Buy {
    IGravyard_0 public g0;
    IGravyard_1 public g1;
    IGravyard_2 public g2;
    IGravyard_2 public g3;

    mapping(address => mapping(uint256 => bool)) public saleRecord;

    constructor(IGravyard_0 _g0, IGravyard_1 _g1, IGravyard_2 _g2, IGravyard_2 _g3){
        g0 = _g0;
        g1 = _g1;
        g2 = _g2;
        g3 = _g3;
    }

    function buyGrave(address _gravyard, address _to, uint256 _tokenId) external payable returns(bool){
        require(!saleRecord[_gravyard][_tokenId], "Token is already sold");
        if(_gravyard == address(g0))
        { 
            g0.buyNFt{value: msg.value}(_to, _tokenId);
            saleRecord[_gravyard][_tokenId] = true;
            return true;
        }
        else if(_gravyard == address(g1))
        {
            g1.buyNFt{value: msg.value}(_to, _tokenId);
            saleRecord[_gravyard][_tokenId] = true;
            return true;

        }
        else if(_gravyard == address(g2))
        {
            g2.buyNFt{value: msg.value}(_to, _tokenId);
            saleRecord[_gravyard][_tokenId] = true;
            return true;

        }
        else if(_gravyard == address(g3))
        {
            g3.buyNFt{value: msg.value}(_to, _tokenId);
            saleRecord[_gravyard][_tokenId] = true;
            return true;
        }
        else{
            return false;
        }
    }
}