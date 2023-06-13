/**
 *Submitted for verification at polygonscan.com on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EternalJournalismV2 {
    address public owner;
    address public implementation;
    string public contractVersion;
    string public constant protest = "Eternal Journalism is also a protest to Ethereum's possible plans for ThePurge, which will potentially destroy contracts like Leeroy, social networks like Peepeth/Lens; and every important message written in the blockchain and their gas costs associated possibly without refunding.";
    
    mapping(string => Article) private articles;
    mapping(string => uint256) private articleUpdates;
    
    uint256 public articleCount;
    uint256 public updateCount;

    struct Article {
        string id;
        string title;
        string content;
        string ipfsHash;
        string url;
        uint256 timestamp;
        bool isFullArticle;
        bool isMultiPart;
        uint256 lastPartNumber;
        uint256 currentPartNumber;
    }

    event ArticleStored(string indexed id, string title, string content, string ipfsHash, string url, bool isFullArticle, bool isMultiPart, uint256 lastPartNumber);
    event ArticleUpdated(string indexed id, string content);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        contractVersion = "v2";
    }
    
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid new owner");
        owner = _newOwner;
    }
    
    function upgradeImplementation(address _newImplementation) external onlyOwner {
        require(_newImplementation != address(0), "Invalid new implementation address");
        implementation = _newImplementation;
    }
    
    function getArticle(string memory id) external view returns (string memory, string memory, string memory, string memory, string memory, uint256, bool, bool, uint256, uint256) {
        Article storage article = articles[id];
        return (article.id, article.title, article.content, article.ipfsHash, article.url, article.timestamp, article.isFullArticle, article.isMultiPart, article.lastPartNumber, article.currentPartNumber);
    }
    
    function getArticleUpdateCount(string memory id) external view returns (uint256) {
        return articleUpdates[id];
    }
    
    function getArticleCount() external view returns (uint256) {
        return articleCount;
    }
    
    function storeFullArticle(string memory id, string memory title, string memory content, string memory url, bool isMultiPart, uint256 lastPartNumber) external onlyOwner {
        require(!isArticleStored(id), "Article with the given ID already exists");
        require(!isMultiPart || (isMultiPart && lastPartNumber > 0), "Invalid last part number");
        articles[id] = Article(id, title, content, "", url, block.timestamp, true, isMultiPart, lastPartNumber, 0);
        articleCount++;
        emit ArticleStored(id, title, content, "", url, true, isMultiPart, lastPartNumber);
    }
    
    function storePartialArticle(string memory id, string memory title, string memory ipfsHash, string memory url) external onlyOwner {
        require(!isArticleStored(id), "Article with the given ID already exists");
        articles[id] = Article(id, title, "", ipfsHash, url, block.timestamp, false, false, 0, 0);
        articleCount++;
        emit ArticleStored(id, title, "", ipfsHash, url, false, false, 0);
    }
    
    function updateFullArticle(string memory id, string memory content) external onlyOwner {
        Article storage article = articles[id];
        require(isArticleStored(id), "Article with the given ID does not exist");
        require(article.isFullArticle, "Article is not a full article");

        if (article.isMultiPart) {
            require(article.currentPartNumber == article.lastPartNumber, "Multi-part article is still accepting parts");
        }

        require(keccak256(bytes(content)) != keccak256(bytes(article.content)), "Article content is identical");

        article.content = content;
        article.timestamp = block.timestamp;
        articleUpdates[id]++;
        updateCount++;
        
        emit ArticleUpdated(id, content);
    }
    
    function addArticlePart(string memory id, string memory content) external onlyOwner {
        Article storage article = articles[id];
        require(isArticleStored(id), "Article with the given ID does not exist");
        require(article.isFullArticle, "Article is not a full article");
        require(article.isMultiPart, "Article is not a multi-part article");
        require(article.currentPartNumber < article.lastPartNumber, "All parts of the article have been already added");

        article.content = string(abi.encodePacked(article.content, content));
        article.currentPartNumber++;
        article.timestamp = block.timestamp;
        articleUpdates[id]++;
        updateCount++;

        if (article.currentPartNumber == article.lastPartNumber) {
            article.isMultiPart = false;
        }
        
        emit ArticleUpdated(id, content);
    }
    
    function isArticleStored(string memory id) internal view returns (bool) {
        return bytes(articles[id].id).length != 0;
    }
}