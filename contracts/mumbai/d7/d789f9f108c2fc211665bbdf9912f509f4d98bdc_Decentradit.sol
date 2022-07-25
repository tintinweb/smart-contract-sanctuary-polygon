/**
 *Submitted for verification at polygonscan.com on 2022-07-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract Decentradit {

    event PostCreated (bytes32 indexed postId, address indexed postOwner, bytes32 contentId, bytes32 categoryId);
    event ContentAdded (bytes32 indexed contentId, string contentUri);
    event CategoryCreated (bytes32 indexed categoryId, string category);
    event Voted (bytes32 indexed postId, address indexed postOwner, address indexed voter, uint80 reputationPostOwner, uint80 reputationVoter, int40 postVotes, bool up, uint8 reputationAmount);

    struct post {
        address postOwner;
        bytes32 contentId;
        int40 votes;
        int40 voteUp;
        bytes32 categoryId;
    }

    constructor() {
        
    }

    mapping (address => mapping (bytes32 => uint80)) reputationRegistry;
    mapping (bytes32 => string) categoryRegistry;
    mapping (bytes32 => string) contentRegistry;
    mapping (bytes32 => post) postRegistry;
    mapping (address => mapping (bytes32 => int32)) voteRegistry;

    function createPost(string calldata _contentUri, bytes32 _categoryId) external {
        address _owner = msg.sender;
        bytes32 _contentId = keccak256(abi.encode(_contentUri));
        bytes32 _postId = keccak256(abi.encodePacked(_owner, _contentId));
        contentRegistry[_contentId] = _contentUri;
        postRegistry[_postId].postOwner = _owner;
        postRegistry[_postId].contentId = _contentId;
        postRegistry[_postId].categoryId = _categoryId;
        emit ContentAdded(_contentId, _contentUri);
        emit PostCreated (_postId, _owner, _contentId,_categoryId);
    }

    function voteUp(bytes32 _postId, uint8 _reputationAdded) external {
        address _voter = msg.sender;
        bytes32 _category = postRegistry[_postId].categoryId;
        address _contributor = postRegistry[_postId].postOwner;
        require (postRegistry[_postId].postOwner != _voter, "you cannot vote your own posts");
        require (voteRegistry[_voter][_postId] == 0, "Sender already voted in this post");
        require (validateReputationChange(_voter,_category,_reputationAdded)==true, "This address cannot add this amount of reputation points");
        postRegistry[_postId].votes += 1;
        postRegistry[_postId].voteUp += 1;
        reputationRegistry[_contributor][_category] += _reputationAdded;
        voteRegistry[_voter][_postId] = 1;
        emit Voted(_postId, _contributor, _voter, reputationRegistry[_contributor][_category], reputationRegistry[_voter][_category], postRegistry[_postId].votes, true, _reputationAdded);
    }

    function voteDown(bytes32 _postId, uint8 _reputationTaken) external {
        address _voter = msg.sender;
        bytes32 _category = postRegistry[_postId].categoryId;
        address _contributor = postRegistry[_postId].postOwner;
        require (voteRegistry[_voter][_postId] == 0, "Sender already voted in this post");
        require (validateReputationChange(_voter,_category,_reputationTaken)==true, "This address cannot take this amount of reputation points");
        postRegistry[_postId].votes >= 1 ? postRegistry[_postId].votes -= 1: postRegistry[_postId].votes = 0;
        reputationRegistry[_contributor][_category] >= _reputationTaken ? reputationRegistry[_contributor][_category] -= _reputationTaken: reputationRegistry[_contributor][_category] =0;
        voteRegistry[_voter][_postId] = 2;
        emit Voted(_postId, _contributor, _voter, reputationRegistry[_contributor][_category], reputationRegistry[_voter][_category], postRegistry[_postId].votes, false, _reputationTaken);
    }

    function claimResult(bytes32 _postId) external returns(bool) {
        address _voter = msg.sender;
        require (voteRegistry[_voter][_postId] == 0, "Sender not voted in this post yet");
        int40 up = postRegistry[_postId].voteUp;
        int40 down = postRegistry[_postId].votes - postRegistry[_postId].voteUp;
        int32 curVote = voteRegistry[_voter][_postId];
        if(up > down) {
            if(curVote == 1) {
                return true;
            } else {
                return false;
            }
        } else if(up < down) {
            if(curVote == 2) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    function validateReputationChange(address _sender, bytes32 _categoryId, uint8 _reputationAdded) internal view returns (bool _result){
        uint80 _reputation = reputationRegistry[_sender][_categoryId];
        if (_reputation < 2 ) {
            _reputationAdded == 1 ? _result = true: _result = false;
        }
        else {
            2**_reputationAdded <= _reputation ? _result = true: _result = false;
        }
    }

    function addCategory(string calldata _category) external {
        bytes32 _categoryId = keccak256(abi.encode(_category));
        categoryRegistry[_categoryId] = _category;
        emit CategoryCreated(_categoryId, _category);
    }
    
    function getContent(bytes32 _contentId) public view returns (string memory) {
        return contentRegistry[_contentId];
    }
    
    function getCategory(bytes32 _categoryId) public view returns(string memory) {   
        return categoryRegistry[_categoryId];
    }

    function getReputation(address _address, bytes32 _categoryID) public view returns(uint80) {   
        return reputationRegistry[_address][_categoryID];
    }

    function getPost(bytes32 _postId) public view returns(address, bytes32,  int40, bytes32) {   
        return (
            postRegistry[_postId].postOwner,
            postRegistry[_postId].contentId,
            postRegistry[_postId].votes,
            postRegistry[_postId].categoryId
        );
    }

}