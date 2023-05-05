// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract LedgerLens{

    struct Article {
        string title;
        address creator;
        string body;
        string ipfsImgUrl;
        uint256 creationTime; //Timestamp
    }

    mapping(address => Article[]) ArticlesByCreator;
    mapping(address => Article[]) ArticlesReadByUser;
    // mapping(Article => address[]) UsersReadingArticles;

    function addArticle(string memory _title,string memory _body,string memory _ipfsImgUrl ) public{
        ArticlesByCreator[msg.sender].push(Article(_title,msg.sender, _body, _ipfsImgUrl,block.timestamp));
    }

    function getArticle(address _creator) public view returns(Article[] memory){
        return ArticlesByCreator[_creator];
    }

    function addUserRead(string memory _title,string memory _body,uint256 _creationTime,string memory _ipfsImgUrl) public{
        ArticlesReadByUser[msg.sender].push(Article(_title,msg.sender, _body,_ipfsImgUrl,_creationTime));
    }

    function getUserRead() public view returns(Article[] memory){
        return ArticlesReadByUser[msg.sender];
    }

    // function addArticleRead() public{

    // }

    // function getArticleRead() public{

    // }

    // function tip() public{

    // }



}