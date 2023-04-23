/**
 *Submitted for verification at polygonscan.com on 2023-04-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedAI {

    struct Model {
        string baseURL;
        string codeLink;
        string name;
        string outputType;
    }

    struct ModelType {
        string name;
        string outputStructure;
        bytes32 id;
    }

    struct Request {
        string prompt;
        uint256 confirmations;
        bytes32 modelTypeID;
        uint256 pricePerToken;
        uint256 maxTokens;
        uint256 seed;
    }

    mapping (address => Model) public models;
    mapping (bytes32 => ModelType) public modelTypes;

    Request[] public requests;

    event RequestSubmitted(uint256 indexed requestId, string prompt, uint256 confirmations, bytes32 modelTypeId, uint256 pricePerToken, uint256 maxTokens, uint256 seed);
    event ModelResponse(address indexed modelAddress, bytes response);

    function submitModel(string memory _baseURL, string memory _codeLink, string memory _name, string memory _outputType) public {
        Model storage model = models[msg.sender];
        model.baseURL = _baseURL;
        model.codeLink = _codeLink;
        model.name = _name;
        model.outputType = _outputType;
    }

    function createModelType(string memory _name, string memory _outputStructure) public returns (bytes32) {
        bytes32 id = keccak256(abi.encodePacked(_name, _outputStructure, block.prevrandao));
        modelTypes[id] = ModelType(_name, _outputStructure, id);
        return id;
    }

    function submitRequest(string memory _prompt, uint256 _confirmations, bytes32 _modelTypeID, uint256 _pricePerToken, uint256 _maxTokens) public {
        Request memory newRequest = Request(_prompt, _confirmations, _modelTypeID, _pricePerToken, _maxTokens, block.prevrandao);
        uint256 requestId = requests.length;
        emit RequestSubmitted(requestId, _prompt, _confirmations, _modelTypeID, _pricePerToken, _maxTokens, block.prevrandao);
        requests.push(newRequest);
    }

    function executeRequest(uint256 requestIndex, bytes memory _response) public {
        Request memory request = requests[requestIndex];
        ModelType memory modelType = modelTypes[request.modelTypeID];

        uint256 earnings = request.pricePerToken * request.maxTokens;
        uint256 numModels = 0;
        
        address[] memory modelAddresses = new address[](requests.length);

        for (uint256 i = 0; i < requests.length; i++) {
            if (requests[i].modelTypeID == request.modelTypeID) {
                Model memory model = models[msg.sender];
                if (bytes(model.baseURL).length > 0 && bytes(model.codeLink).length > 0) {
                    numModels++;
                    modelAddresses[numModels - 1] = msg.sender;
                    emit ModelResponse(msg.sender, _response);
                }
            }
        }

        require(numModels > 0, "No models available");

        uint256 earningsPerModel = earnings / numModels;

        for (uint256 i = 0; i < numModels; i++) {
            (bool success, ) = payable(modelAddresses[i]).call{value: earningsPerModel}("");
            require(success, "Transfer failed.");
        }
    }
}