// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;
contract Library {
    constructor() {
        
    }
    struct Book {
        // this struct will store the details of the book
        uint256 id;
        string name;
        string author;
        uint256 year;
        bool isFinished;
    }
    
    Book[] private books;
    
    mapping(uint256 =>address) public bookToOwner; 
// this mapping will map the book id to the owner address


    event AddBook( address, uint);


    function addBook(string memory _name, string memory _author, uint256 _year,bool finished) external {
        //  this function will add a book to the library
        books.push(Book(books.length, _name, _author, _year,finished));
        bookToOwner[books.length-1] = msg.sender;
        emit AddBook(msg.sender, books.length-1);
    }
    
    function _getBooks(bool finished) private view returns(Book[] memory) {
        //  this function will return all the books in the library
        Book[] memory result = new Book[](books.length);
        uint256 counter = 0;
        for(uint256 i = 0; i < books.length; i++) {
            if(books[i].isFinished == finished && bookToOwner[i] == msg.sender) {
                result[counter] = books[i];
                counter++;
            }
        }
        Book[] memory result2 = new Book[](counter);
        for(uint256 i = 0; i < counter; i++) {
            result2[i] = result[i];
        }
        return result2;
    }

    function getUnfinishedBooks() external view returns(Book[] memory) {
        //  this function will return all the books in the library which are not finished   
        return _getBooks(false);
    }

    function getFinishedBooks() external view returns(Book[] memory) {
        // this function will return all the books in the library which are finished
        return _getBooks(true);
    }


    function setFinished( uint bookId, bool finished ) external {
        // this function will set the finished status of a book
        require(bookId < books.length, "Book does not exist");
        require(bookToOwner[bookId] == msg.sender, "You are not the owner of this book");
        books[bookId].isFinished = finished;
    }
        
}