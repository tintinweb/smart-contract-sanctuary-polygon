/**
 *Submitted for verification at polygonscan.com on 2022-05-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.17 <8.10.0;

contract NFTDetails{

  struct Token{
    address _creator;
    address _owner;
    uint256 _price;
    uint256 _royality;
    uint256 _commission;
    string _tokenURI;
  }

  struct Sender{
    address _address;
    string _name;
    string _avatar;
  }

  struct NFTTransactions{
    Sender from;
    Sender to;
    uint256 time;
    uint256 price;
  }

  struct User{
        address _address;
        string _fullName;
        string _email;
        string _role;
        string _about;
        string _facebok;
        string _twitter;
        string _instagram;
        string _dribbble;
        string _header;
        string _avatar;
  }

  struct Activity{
      address _address;
      uint256 _price;
      uint256 _royality;
      uint256 _commission;
      uint256 _time;
      string _status;
  }

  struct Transaction{
    Sender _from;
    Sender _to;
    uint256 _id;
    uint256 _price;
    uint256 _time;
  }


  event Offer(uint offerId, uint id, address user, uint price, bool fulfilled, bool cancelled);
  event CreateUser(address _address, string _fullName, string _email, string _role, string _about);
  event SaleCancelled(uint offerId, uint id, address owner);
  event ClaimFunds(address user, uint amount);
  event BoughtNFT(uint256 _tokenId, uint256 _offerId, address winner);
}