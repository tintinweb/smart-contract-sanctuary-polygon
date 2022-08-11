/**
 *Submitted for verification at polygonscan.com on 2022-08-11
*/

pragma solidity >=0.4.22 <0.9.0;

// SPDX-License-Identifier: MIT
// Creating a contract
	contract Library {

// Declaring a structure
	struct Book {
	
	string name;
	string writer;
	uint id;
	string owner;
	address owner_adress;

}


// creating mapping

	mapping (address => Book) public addr;
	address[] public own_addr;
	


// Declaring a structure object
	Book book1;

//array define 
	Book[] public searchBook;


// Defining a function to set values
	function set_book_detail(string memory _name, string memory _writer, uint _id, string memory _owner, address owner_address) public {
	book1 = Book(_name, _writer, _id,_owner, owner_address);

	own_addr.push(owner_address);

	searchBook.push(book1);

	addr[owner_address]= book1;

}


	
// Defining function to print
// book1 details
	function get_details() public view returns (string memory,string memory, uint, string memory) {
	return (book1.name, book1.writer, book1.id, book1.owner);
	}

	function by_owner_address(address owner_address) public view returns (string memory,string memory, uint, string memory) {
	
	return (addr[owner_address].name, addr[owner_address].writer, addr[owner_address].id, addr[owner_address].owner);
	
	
	}
}