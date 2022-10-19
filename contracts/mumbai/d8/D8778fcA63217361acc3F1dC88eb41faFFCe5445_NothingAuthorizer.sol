/**
 *Submitted for verification at polygonscan.com on 2022-10-19
*/

// File: @api3/airnode-protocol/contracts/authorizers/interfaces/IAuthorizerV0.sol


pragma solidity ^0.8.0;

interface IAuthorizerV0 {
    function isAuthorizedV0(
        bytes32 requestId,
        address airnode,
        bytes32 endpointId,
        address sponsor,
        address requester
    ) external view returns (bool);
}

// File: github/api3dao/airnode/packages/airnode-examples/contracts/coingecko-cross-chain-authorizer/NothingAuthorizer.sol


pragma solidity 0.8.9;


contract NothingAuthorizer is IAuthorizerV0 {
    function isAuthorizedV0(
        bytes32,
        address,
        bytes32,
        address,
        address
    ) external pure override returns (bool) {
        return false;
    }
}