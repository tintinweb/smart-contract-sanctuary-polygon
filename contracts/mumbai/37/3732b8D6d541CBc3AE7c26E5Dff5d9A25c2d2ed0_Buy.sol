/**
 *Submitted for verification at polygonscan.com on 2022-07-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Grav1{
   function buyNFt(address _to, uint256 _tokenId) external payable returns(bool); 
}

interface Grav2{
    function buyNFt(address _to, uint256 _tokenId) external payable returns(bool);
}

interface Grav3{
    function buyNFt(address _to, uint256 _tokenId) external payable returns(bool);
}

interface Grav4{
    function buyNFt(address _to, uint256 _tokenId) external payable returns(bool);
}


contract Buy {
    Grav1 public g1;
    Grav2 public g2;
    Grav3 public g3;
    Grav4 public g4;

    mapping(address => mapping(uint256 => bool)) public saleRecord;


    constructor (address _g1, address _g2, address _g3, address _g4) {
        g1=Grav1(_g1);
        g2=Grav2(_g2);
        g3=Grav3(_g3);
        g4=Grav4(_g4);
    }

    function buyGrave(address _gravyard, address _to, uint256 _tokenId) external payable returns(bool){
        require(!saleRecord[_gravyard][_tokenId], "Token is already sold");
        if(_gravyard == address(g1))
        {
            
            g1.buyNFt(_to, _tokenId);
            saleRecord[_gravyard][_tokenId] = true;
            return true;

        }
        else if(_gravyard == address(g2))
        {
            
            g2.buyNFt(_to, _tokenId);
            saleRecord[_gravyard][_tokenId] = true;
            return true;

        }
        else if(_gravyard == address(g3))
        {
            
            g3.buyNFt(_to, _tokenId);
            saleRecord[_gravyard][_tokenId] = true;
            return true;

        }
        else if(_gravyard == address(g4))
        {
          
            g4.buyNFt(_to, _tokenId);
            saleRecord[_gravyard][_tokenId] = true;
            return true;
        }else{
            return false;
        }
    }
}