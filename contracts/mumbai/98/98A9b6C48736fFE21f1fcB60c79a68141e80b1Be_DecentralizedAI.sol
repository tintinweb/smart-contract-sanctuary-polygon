/**
 *Submitted for verification at polygonscan.com on 2023-04-22
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract DecentralizedAI {
    
    struct Model {
        address owner;
        string base_url;
        string code_link;
        uint256 price_per_token;
        uint256 rating_sum;
        uint256 rating_count;
        uint256 model_id;
    }
    
    mapping(uint256 => Model) models;
    mapping(uint256 => mapping(address => bool)) private_keys;
    
    event ModelRegistered(uint256 model_id, address owner, string base_url, string code_link, uint256 price);
    event ApiKeyGenerated(uint256 model_id, address indexed user, address indexed owner, uint256 api_key, string request_source, uint256 max_tokens);
    event ModelRated(uint256 model_id, address indexed user, address indexed owner, uint256 rating);
    
    uint256 public next_model_id = 1;
    
    function registerModel(string memory base_url, string memory code_link, uint256 price) public {
        uint256 model_id = next_model_id;
        next_model_id++;
        require(models[model_id].owner == address(0), "Model already registered");
        models[model_id] = Model(msg.sender, base_url, code_link, price, 0, 0, model_id);
        emit ModelRegistered(model_id, msg.sender, base_url, code_link, price);
    }

    function requestApiKey(uint256 model_id, address payable owner, uint256 max_tokens, string calldata request_source) public payable returns (uint256) {
        require(msg.value >= models[model_id].price_per_token * max_tokens, "Not enough tokens");
        require(models[model_id].owner == owner, "Invalid owner address");
        
        private_keys[model_id][msg.sender] = true;
        uint256 api_key = generateApiKey(model_id, msg.sender, owner);
        owner.transfer(msg.value * max_tokens);
        emit ApiKeyGenerated(model_id, msg.sender, owner, api_key, request_source, max_tokens);
        return api_key;
    }

    function rateModel(uint256 model_id, uint256 rating) public {
        require(private_keys[model_id][msg.sender], "API key not generated");
        require(rating >= 1 && rating <= 10, "Invalid rating value");
        
        Model storage model = models[model_id];
        model.rating_sum += rating;
        model.rating_count++;
        
        emit ModelRated(model_id, msg.sender, model.owner, rating);
    }
    
    function generateApiKey(uint256 model_id, address user, address owner) public view returns (uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, user, owner, model_id)));
        return rand;
    }
}