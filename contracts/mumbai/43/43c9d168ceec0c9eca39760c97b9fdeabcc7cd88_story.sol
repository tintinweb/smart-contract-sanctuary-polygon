/**
 *Submitted for verification at polygonscan.com on 2022-05-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract createActors{

    mapping(address =>book []) public booksOfAuthor;
    struct author{
        string name;
        string aboutAuthor;
        uint[] bookIdList;
    }

    struct reader{
        string name;
    }

    struct book{
        address authorId;
        uint bookId;
        string name;
        uint[] chapterIdList;
    }


    event HasReadBook(uint256 bookName, uint256 userName);
    event UserCreated(string userType, string userName, string aboutAuthor);
    event BookCreated(string bookName, string auhtor);
    
    uint bookId = 0;
    uint readerCount = 0;
    uint authorID = 0;
    mapping(uint => address) authorIDToAddress;
    mapping (address => author) public authorIdMapping;
    mapping (address => reader) public readerIdMapping;
    mapping (uint => book) public bookIdMapping;

    function createAuthor(string memory _name, string memory _aboutAuthor) public
    {
        //check if msg.sender is not in authorIdMapping
        authorIdMapping[msg.sender].name = _name;
        authorIdMapping[msg.sender].aboutAuthor = _aboutAuthor;
        authorIDToAddress[authorID] = msg.sender;
        authorID++;
        emit UserCreated("Author", _name, _aboutAuthor);
    }

    function createReader(string memory _name) public
    {
        // check if msg.sender is not in readerIdMapping
        readerIdMapping[msg.sender].name = _name;
        emit UserCreated("Reader", _name, "");
    }

    function createBook(string memory _name) public
    {
        // check if msg.sender exists in authorIdMapping
        //authorBookList[msg.sender][authorBookCount] = bookId;
        authorIdMapping[msg.sender].bookIdList.push(bookId);
        bookIdMapping[bookId].name = _name;
        bookIdMapping[bookId].authorId = msg.sender;
        bookIdMapping[bookId].bookId = bookId;
        bookId++;
        booksOfAuthor[msg.sender].push(bookIdMapping[bookId]);
        emit BookCreated(_name, authorIdMapping[msg.sender].name);
    }
    
    
    function getAllAuthors() view public returns (string[] memory )
    {
        string[] memory authourList = new string[](authorID);
        for (uint i  = 0; i < authorID; i++)
        {
            address _temp = authorIDToAddress[i];
            authourList[i] = authorIdMapping[_temp].name;
        }
        return authourList;
    }
    
    
    function getAllBooksOfAuthor() view public returns (string[] memory ) 
    {
        author memory focusAuthor = authorIdMapping[msg.sender];
        uint[] memory all_books_id = focusAuthor.bookIdList;
        string[] memory bookNameList = new string[](all_books_id.length);
        for (uint i = 0; i<all_books_id.length;i++){
            bookNameList[i] = bookIdMapping[i].name;
            }
        return bookNameList;
        
    }
    
    function getAllBooks() view public returns (book[] memory)
    {
        book[] memory allBooks = new book[](bookId);
        for (uint i = 0; i < bookId; i++)
            allBooks[i] = bookIdMapping[i];
        return allBooks;
    }
    
}

contract story is createActors {
    address owner;

    struct chapter {
        address author;
        uint bookId;
        string name;
        uint bounty;
        string content;
        bool authorPreference;
        string question;
        mapping (address => bool) votesCasted;
        mapping (address => uint) stake;
        address[] readers;
        uint chapterState;
        bool isResolved;
    }
    // get all chapters of a book
    
    uint chapterId = 0;
    mapping (uint => chapter) public ChapterMapping;
    event ChapterCreated(string chapterName, string authorName);

    function createChapter(uint _bookId, string memory _name, string memory _content, string memory _question,
    bool _authorPreference) public payable    {
        require(msg.value >= 0.1 ether,
        "keep a bounty");
        //uint chapterCount = bookIdMapping[_bookId].chapterIdList.length;
        bookIdMapping[_bookId].chapterIdList.push(chapterId);
        ChapterMapping[chapterId].author = msg.sender;
        ChapterMapping[chapterId].bookId = _bookId;
        ChapterMapping[chapterId].name = _name;
        ChapterMapping[chapterId].bounty = msg.value;
        ChapterMapping[chapterId].content = _content;
        ChapterMapping[chapterId].question = _question;
        ChapterMapping[chapterId].authorPreference = _authorPreference;
        chapterId++;
        emit ChapterCreated(_name, authorIdMapping[msg.sender].name);
    }

    function getAllChapterBooks(uint _bookId) public view returns (string[] memory returnChapterOfBook)
    {
        uint[] memory chaptersList = bookIdMapping[_bookId].chapterIdList;
        string[] memory chapterOfBook = new string[](chaptersList.length);
        for (uint i = 0; i < chaptersList.length; i++)
            chapterOfBook[i] = ChapterMapping[chaptersList[i]].name;
            
        return chapterOfBook;
    }
    
    
    function readChapter(uint _chapterId) public
    {
        // frontend how will the owner call readChapter !!!!
        //require(msg.sender == owner);
        //dont push again and again
        ChapterMapping[_chapterId].readers.push(msg.sender);
    }

    function payReaders(uint _chapterId ) public{ 
        //require(msg.sender == owner);
        require(ChapterMapping[_chapterId].chapterState == 0, "chapter is not new");

        uint bounty = (ChapterMapping[_chapterId].bounty * 5)/100;
        address[] memory readerList = ChapterMapping[_chapterId].readers;
        uint numberOfReaders = readerList.length;
        uint readersShare = bounty/numberOfReaders;
        for (uint i = 0; i < numberOfReaders; i++)
        {
            payable(readerList[i]).transfer(readersShare);
        }
        ChapterMapping[_chapterId].chapterState = 1; //readers have been paid
    }

    function voteForFollowup(uint _chapterId,bool _vote ) public payable{
        uint bounty = msg.value;
        require(bounty >= 0.001 ether && bounty <= 3 ether,"bounty amount needs to be within 0.001 ether to 3 ether");
        require( ChapterMapping[_chapterId].chapterState < 2, "Voting possible only on new chapters");
        
        if (_vote == true)
        {
            ChapterMapping[_chapterId].votesCasted[msg.sender] = true;
        }
        else
        {
            ChapterMapping[_chapterId].stake[msg.sender] = bounty;
        }
    }

    function createConsesus(uint _chapterId) internal view returns (bool,uint,uint)
    {
        bool winner = false;
        uint returnSum = 0;
        chapter storage focusChapter = ChapterMapping[_chapterId];

        // figure out propotion of winner

        uint totalTrueCount;
        uint totalFalseCount;
        uint totalTrueSum;
        uint totalFalseSum;

        for (uint i = 0; i < focusChapter.readers.length; i++)
        {
            address temp_ = focusChapter.readers[i];
            if (focusChapter.votesCasted[temp_] == true)
            {
                totalTrueCount++;
                totalTrueSum += focusChapter.stake[temp_];
            }
            else if (focusChapter.votesCasted[temp_] == false)
            {
                totalFalseCount++;
                totalFalseSum += focusChapter.stake[temp_];
            }

        }

        if (totalTrueSum > totalFalseSum)
        {
            winner = true;
            returnSum = totalTrueSum;
        }
        else if (totalFalseSum > totalTrueSum)
        {
            winner = false;
            returnSum = totalFalseSum;
        }
        else
        {
            if (totalTrueCount > totalFalseCount)
            {
                winner = true;
                returnSum = totalTrueSum;
            }
            else if (totalFalseCount > totalTrueCount)
            {
                winner = false;
                returnSum = totalFalseSum;
            }
            else
            {
                if (focusChapter.authorPreference == true)
                {
                    winner = true;
                    totalTrueSum = totalTrueSum;
                }
                else
                {
                    winner = false;
                    returnSum = totalFalseSum;
                }
            }
        }
        uint total_pool_author = (ChapterMapping[_chapterId].bounty * 95)/100;
        uint total_pool_betting = totalTrueSum + totalFalseSum;
        uint total_pool = total_pool_author + total_pool_betting;
        return (winner,total_pool,returnSum);
    }

    function makePayemntOnConsensus (uint _chapterId) public payable{
        chapter storage focusChapter = ChapterMapping[_chapterId];
        //this should work only if state is active and unresolved
        require(ChapterMapping[chapterId].chapterState == 0);
        
        ( bool winner, uint total_pool,uint returnSum) = createConsesus(_chapterId);
        ChapterMapping[_chapterId].chapterState = 2;
        require(!focusChapter.isResolved);

        for (uint i = 0; i < focusChapter.readers.length; i++)
        {
            address temp_ = focusChapter.readers[i];
            if (focusChapter.votesCasted[temp_] == winner)
            {
                uint stake = focusChapter.stake[temp_];
                uint toPay = (stake/returnSum)*total_pool;
                payable(temp_).transfer(toPay);
            }
        }
        ChapterMapping[_chapterId].chapterState = 3; //voters have been paid
        focusChapter.isResolved = true;
    }
}