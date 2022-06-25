/**
 *Submitted for verification at polygonscan.com on 2022-06-24
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

interface IStrollManager {
    function checkTopUp(
        address _user,
        address _superToken,
        address _liquidityToken
    ) external view returns (uint256);

    function performTopUp(
        address _user,
        address _superToken,
        address _liquidityToken
    ) external;
}

contract GelatoStrollKeeper {

    IStrollManager public immutable strollManager;

    constructor(IStrollManager _strollManager) {
        strollManager = _strollManager;
    }

    function executor(address _user, address _superToken, address _liquidityToken) external {
        strollManager.performTopUp(_user, _superToken, _liquidityToken);
    }

    function checker(address _user, address _superToken, address _liquidityToken) external view returns(bool _canExec, bytes memory _execPayload) {
        if(strollManager.checkTopUp(_user, _superToken, _liquidityToken) > 0) {
            _canExec = true;
            _execPayload = abi.encodeWithSelector(GelatoStrollKeeper.executor.selector, _user, _superToken, _liquidityToken);
        }
    }
}