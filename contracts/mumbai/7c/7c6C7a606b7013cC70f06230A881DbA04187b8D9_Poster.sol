// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.9.0;
contract Poster {
event NewPost(address indexed user, string content, string indexed tag);
function post(string memory content, string memory tag) public {
emit NewPost(msg.sender, content, tag);
}
uint public count = 0; // state variable
  
  struct Contact {
    uint id;
    string name;
    string phone;
  }
  
  constructor() public {
    createContact('Zafar Saleem', '123123123');
  }
  
  mapping(uint => Contact) public contacts;
  
  function createContact(string memory _name, string memory _phone) public {
    count++;
    contacts[count] = Contact(count, _name, _phone);
  }
}