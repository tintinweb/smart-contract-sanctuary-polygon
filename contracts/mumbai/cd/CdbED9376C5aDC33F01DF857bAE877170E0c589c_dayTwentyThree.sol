/**
 *Submitted for verification at polygonscan.com on 2022-11-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract dayTwentyThree{

    struct Book{
        string title;
        string author;
        uint256 book_id;
    }

    Book[100] book;
    uint32 i = 1;

    function setBook(string memory _title, string memory _author, uint256 _bookId) public {
        book[i] = Book(_title, _author, _bookId);
        i++;
    }

    function getBook(uint32 _i) public view returns(string memory, string memory, uint256){
        return (book[_i].title, book[_i].author, book[_i].book_id);
    }
}