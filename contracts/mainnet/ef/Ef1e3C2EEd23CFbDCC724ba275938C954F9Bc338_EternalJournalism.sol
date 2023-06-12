/**
 *Submitted for verification at polygonscan.com on 2023-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EternalJournalism {
    address public owner;
    address public implementation;
    
    mapping(string => Article) private articles;

    struct Article {
        string id;
        string title;
        string content;
        string ipfsHash;
        uint256 timestamp;
        bool isFullArticle;
    }

    event ArticleStored(string indexed id, string title, string content, string ipfsHash, bool isFullArticle);
    event ArticleUpdated(string indexed id, string content);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function upgradeImplementation(address _newImplementation) external onlyOwner {
        implementation = _newImplementation;
    }
    
    function getArticle(string memory id) external view returns (string memory, string memory, string memory, string memory, uint256, bool) {
        Article storage article = articles[id];
        return (article.id, article.title, article.content, article.ipfsHash, article.timestamp, article.isFullArticle);
    }
    
    function storeFullArticle(string memory id, string memory title, string memory content) external onlyOwner {
        require(!isArticleStored(id), "Article with the given ID already exists");
        articles[id] = Article(id, title, content, "", block.timestamp, true);
        emit ArticleStored(id, title, content, "", true);
    }
    
    function storePartialArticle(string memory id, string memory title, string memory ipfsHash) external onlyOwner {
        require(!isArticleStored(id), "Article with the given ID already exists");
        articles[id] = Article(id, title, "", ipfsHash, block.timestamp, false);
        emit ArticleStored(id, title, "", ipfsHash, false);
    }
    
    function updateArticle(string memory id, string memory content) external onlyOwner {
        Article storage article = articles[id];
        require(isArticleStored(id), "Article with the given ID does not exist");

        if (article.isFullArticle) {
            require(keccak256(bytes(content)) != keccak256(bytes(article.content)), "Article content is identical");
        } else {
            require(keccak256(bytes(content)) != keccak256(bytes(article.ipfsHash)), "Article content is identical");
        }

        article.content = content;
        article.timestamp = block.timestamp;
        
        emit ArticleUpdated(id, content);
    }
    
    function isArticleStored(string memory id) internal view returns (bool) {
        return bytes(articles[id].id).length != 0;
    }
}