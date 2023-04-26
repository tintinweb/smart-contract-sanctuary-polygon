/**
 *Submitted for verification at polygonscan.com on 2023-04-25
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedAI {
    struct ModelType {
        string name;
        string outputStructure;
    }

    struct Request {
        address requester;
        string prompt;
        uint256 confirmations;
        uint256 modelTypeID;
        uint256 pricePerToken;
        uint256 maxTokens;
        uint256 totalPrice;
        bool fulfilled;
        mapping(address => string) responses;
        address[] responders;
    }

    mapping(uint256 => ModelType) public modelTypes;
    mapping(bytes32 => Request) public requests;

    event RequestCreated(bytes32 indexed requestID, address indexed requester, string prompt, uint256 confirmations, uint256 modelTypeID, uint256 pricePerToken, uint256 maxTokens, uint256 totalPrice, uint256 seed);
    event RequestFulfilled(bytes32 indexed requestID, address[] responders, string[] responses, uint256[] responseCounts, uint256 totalProfit);

    function createModelType(string memory name, string memory outputStructure, uint256 modelTypeID) public {
        require(bytes(modelTypes[modelTypeID].name).length == 0, "Model type already exists");
        modelTypes[modelTypeID] = ModelType(name, outputStructure);
    }

    function createRequest(string memory prompt, uint256 confirmations, uint256 modelTypeID, uint256 pricePerToken, uint256 maxTokens, uint256 totalPrice) public payable returns (bytes32 requestID) {
        bytes32 requestID = keccak256(abi.encodePacked(prompt, confirmations, modelTypeID, pricePerToken, maxTokens, totalPrice));
        
        Request storage request = requests[requestID];
        request.requester = msg.sender;
        request.prompt = prompt;
        request.confirmations = confirmations;
        request.modelTypeID = modelTypeID;
        request.pricePerToken = pricePerToken;
        request.maxTokens = maxTokens;
        request.totalPrice = totalPrice;
        emit RequestCreated(requestID, msg.sender, prompt, confirmations, modelTypeID, pricePerToken, maxTokens, totalPrice, uint(block.number));

        return requestID;
    }
    
    function submitResponse(bytes32 requestID, string memory response) public {
        Request storage request = requests[requestID];
        require(request.requester != address(0), "Request does not exist");
        require(!request.fulfilled, "Request already fulfilled");
        
        request.responses[msg.sender] = response;
        request.responders.push(msg.sender);

        if (request.responders.length < request.confirmations) {
            return;
        }
        
        request.fulfilled = true;

        uint256 numResponses = request.responders.length;
        string[] memory responses = new string[](numResponses);
        uint256[] memory responseCounts = new uint256[](numResponses);
        address[] memory responders = new address[](numResponses);

        for (uint256 i = 0; i < numResponses; i++) {
            address responder = request.responders[i];
            string memory responderResponse = request.responses[responder];
            responses[i] = responderResponse;
            responders[i] = responder;
            responseCounts[i] = 1;
            for (uint256 j = i + 1; j < numResponses; j++) {
                if (keccak256(abi.encodePacked(responderResponse)) == keccak256(abi.encodePacked(request.responses[request.responders[j]]))) {
                    responseCounts[i]++;
                    responseCounts[j]++;
                }
            }
        }

        uint256 maxCount = 0;
        for (uint256 i = 0; i < numResponses; i++) {
            if (responseCounts[i] > maxCount) {
                maxCount = responseCounts[i];
            }
        }
        
        uint256 totalProfit;
        if (request.pricePerToken > 0) {
            require(request.maxTokens >= request.confirmations, "Max tokens less than confirmations");
            uint256 profitPerResponder = request.pricePerToken / request.confirmations;
            totalProfit = profitPerResponder * request.confirmations;
        } else {
            totalProfit = request.totalPrice;
        }
        
        emit RequestFulfilled(requestID, responders, responses, responseCounts, totalProfit);

        for (uint256 i = 0; i < numResponses; i++) {
            address responder = request.responders[i];
            if (responseCounts[i] == maxCount) {
                payable(responder).transfer(totalProfit / maxCount);
            }
        }
}
}