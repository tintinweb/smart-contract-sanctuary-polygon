/**
 *Submitted for verification at polygonscan.com on 2022-12-03
*/

// File: contracts/Article.sol



pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract Article {

    struct ArticleMeta {
        string cid;  
        address author; 
        uint validityScore;
    }

    struct AuthorMeta{
        address creater;
        uint validityScore;
    }

    mapping(int => ArticleMeta) public articles;
    mapping(address => AuthorMeta) public authors;
    int public artclCount = 0;


    constructor() {
        
    }

    function publishArticle( string memory _cid, address _creater) public{
        artclCount = artclCount + 1;
        articles[artclCount] = 
            ArticleMeta( _cid, _creater,0);
    }

    function addValidation(int256 _articleId, bool validate) public{
        address _author = articles[_articleId].author;

        if(validate){
          articles[_articleId].validityScore = articles[_articleId].validityScore + 1;
          authors[_author].validityScore = authors[_author].validityScore + 1 ;
        }else{
         articles[_articleId].validityScore = articles[_articleId].validityScore - 1;
         authors[_author].validityScore = authors[_author].validityScore -1;
        }

    }
}