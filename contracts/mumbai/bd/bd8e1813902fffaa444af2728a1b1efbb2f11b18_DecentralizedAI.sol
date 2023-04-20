/**
 *Submitted for verification at polygonscan.com on 2023-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedAI {
    struct Model {
        bytes32 hash;
        string url;
        string code;
        uint256 price;
        address owner;
        uint256 reputation;
    }

    mapping(bytes32 => Model) public models;
    mapping(address => mapping(bytes32 => uint256)) public allowances;
    mapping(bytes32 => uint256) public ratings;

    event ModelAdded(bytes32 indexed id, bytes32 hash, string url, string code, uint256 price, address owner);
    event AllowanceGranted(address indexed user, bytes32 indexed modelId, uint256 amount);
    event ApiKeyGenerated(address indexed user, bytes32 indexed modelId, address indexed modelOwner, bytes32 apiKey);
    event ModelRated(bytes32 indexed modelId, uint256 rating);
    
    function addModel(bytes32 id, string calldata url, string calldata code, uint256 price) public {
        require(models[id].hash == bytes32(0), "Model already exists");
        bytes32 hash = keccak256(abi.encodePacked(url));
        models[id] = Model(hash, url, code, price, msg.sender, 0);
        emit ModelAdded(id, hash, url, code, price, msg.sender);
    }

    function grantAllowance(bytes32 modelId, uint256 amount) public {
        require(models[modelId].hash != bytes32(0), "Model does not exist");
        allowances[msg.sender][modelId] += amount;
        emit AllowanceGranted(msg.sender, modelId, amount);
    }

    function generateApiKey(bytes32 modelId, uint256 maxTokens, address modelOwner) public returns (bytes32) {
        require(maxTokens > 0, "Maximum tokens must be greater than zero");
        Model storage model = models[modelId];
        require(model.hash != bytes32(0), "Model does not exist");
        require(model.price <= maxTokens, "Not enough tokens");
        require(allowances[msg.sender][modelId] >= maxTokens, "Not enough allowance");
        if (modelOwner == address(0)) {
            modelOwner = selectModelOwner(modelId);
        }
        bytes32 apiKey = keccak256(abi.encodePacked(modelId, modelOwner, msg.sender));
        allowances[msg.sender][modelId] -= maxTokens;
        emit ApiKeyGenerated(msg.sender, modelId, modelOwner, apiKey);
        return apiKey;
    }

    function rateModel(bytes32 modelId, uint256 rating) public {
        require(models[modelId].hash != bytes32(0), "Model does not exist");
        require(rating >= 1 && rating <= 10, "Invalid rating");
        ratings[modelId] += rating;
        models[modelId].reputation++;
        emit ModelRated(modelId, rating);
    }

    function getModelReputation(bytes32 modelId) public view returns (uint256) {
        return models[modelId].reputation;
    }
    
    function selectModelOwner(bytes32 modelId) internal view returns (address) {
        uint256 totalReputation;
        for (uint256 i = 0; i < 256; i++) {
            totalReputation += models[bytes32(uint256(keccak256(abi.encodePacked(modelId, i))))].reputation;
        }
        uint256 random = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, totalReputation)));
        uint256 accumulatedReputation;
        for (uint256 i = 0; i < 256; i++) {
            accumulatedReputation += models[bytes32(uint256(keccak256(abi.encodePacked(modelId, i))))].reputation;
            if (accumulatedReputation >= random) {
                return models[bytes32(uint256(keccak256(abi.encodePacked(modelId, i))))].owner;
            }
        }
        revert("No model owner found");
    }
}