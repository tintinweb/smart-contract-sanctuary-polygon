/**
 *Submitted for verification at polygonscan.com on 2023-04-24
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

    event RequestCreated(bytes32 indexed requestID, address indexed requester, string prompt, uint256 confirmations, uint256 modelTypeID, uint256 pricePerToken, uint256 maxTokens, uint256 totalPrice);
    event RequestFulfilled(bytes32 indexed requestID, address[] responders, string[] responses, uint256[] responseCounts, uint256 totalProfit);

    function createModelType(string memory name, string memory outputStructure) public returns (uint256) {
        uint256 modelTypeID = uint256(keccak256(abi.encodePacked(name, outputStructure)));
        require(bytes(modelTypes[modelTypeID].name).length == 0, "Model type already exists");
        modelTypes[modelTypeID] = ModelType(name, outputStructure);
        return modelTypeID;
    }

    function createRequest(string memory prompt, uint256 confirmations, uint256 modelTypeID, uint256 pricePerToken, uint256 maxTokens, uint256 totalPrice) public payable {
        bytes32 requestID = keccak256(abi.encodePacked(prompt, confirmations, modelTypeID, pricePerToken, maxTokens, totalPrice));
        require(requests[requestID].requester == address(0), "Request already exists");

        Request storage request = requests[requestID];
        request.requester = msg.sender;
        request.prompt = prompt;
        request.confirmations = confirmations;
        request.modelTypeID = modelTypeID;
        request.pricePerToken = pricePerToken;
        request.maxTokens = maxTokens;
        request.totalPrice = totalPrice;

        emit RequestCreated(requestID, msg.sender, prompt, confirmations, modelTypeID, pricePerToken, maxTokens, totalPrice);
    }

    function submitResponse(bytes32 requestID, string memory response) public {
        Request storage request = requests[requestID];
        require(request.requester != address(0), "Request does not exist");
        require(request.fulfilled == false, "Request already fulfilled");
        require(bytes(request.responses[msg.sender]).length == 0, "Response already submitted");

        request.responses[msg.sender] = response;
        request.responders.push(msg.sender);

        if (request.responders.length == request.confirmations) {
            request.fulfilled = true;

            string[] memory responses = new string[](request.confirmations);
            uint256[] memory responseCounts = new uint256[](request.confirmations);
            address[] memory responders = new address[](request.confirmations);

            for (uint256 i = 0; i < request.confirmations; i++) {
                address responder = request.responders[i];
                string memory responderResponse = request.responses[responder];
                responses[i] = responderResponse;
                responders[i] = responder;
                responseCounts[i] = 1;
                for (uint256 j = i + 1; j < request.confirmations; j++) {
                    if (keccak256(abi.encodePacked(responderResponse)) == keccak256(abi.encodePacked(request.responses[request.responders[j]]))) {
                        responseCounts[i]++;
                        responseCounts[j]++;
                    }
                }
            }
            uint256 maxCount = 0;
            for (uint256 i = 0; i < request.confirmations;) {
                uint256 profitPerResponder;
                if (request.pricePerToken > 0) {
                    require(request.maxTokens > 0, "Max tokens not specified");
                    require(request.maxTokens >= request.confirmations, "Max tokens less than confirmations");
                    profitPerResponder = request.pricePerToken / request.confirmations;
                } else {
                    require(request.totalPrice >= request.confirmations, "Total price less than confirmations");
                    profitPerResponder = request.totalPrice / request.confirmations;
                }

                uint256 totalProfit = 0;
                for (uint256 i = 0; i < request.confirmations; i++) {
                    if (responseCounts[i] == maxCount) {
                        totalProfit += profitPerResponder;
                    }
                }

                emit RequestFulfilled(requestID, responders, responses, responseCounts, totalProfit);
                for (uint256 i = 0; i < request.confirmations; i++) {
                    address responder = request.responders[i];
                    if (responseCounts[i] == maxCount) {
                        payable(responder).transfer(profitPerResponder);
                    }
                }
            }
        }
    }
}