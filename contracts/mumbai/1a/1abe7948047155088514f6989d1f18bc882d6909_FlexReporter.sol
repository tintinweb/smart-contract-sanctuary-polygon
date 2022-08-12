/**
 *Submitted for verification at polygonscan.com on 2022-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

interface IFlex {
    function balanceOf(address account) external view returns (uint256);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function depositStake(uint256 _amount) external;
    function requestStakingWithdraw(uint256 _amount) external;
    function getCurrentTip(bytes32 _queryId) external view returns (uint256);
    function submitValue(bytes32 _queryId, bytes calldata _value, uint256 _nonce, bytes memory _queryData) external;
    function withdrawStake() external;
    
}

contract FlexReporter {
    IFlex public oracle;
    IFlex public autopay;
    IFlex public token;
    address public owner;
    uint256 public profitThreshold;//inTRB

    constructor(address _oracle, address _autopay, address _token, uint256 _profitThreshold){
        oracle = IFlex(_oracle);
        autopay = IFlex(_autopay);
        token = IFlex(_token);
        owner = msg.sender;
        profitThreshold = _profitThreshold;
    }

        modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
    
    function changeOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function depositStake(uint256 _amount) onlyOwner external{
        oracle.depositStake(_amount);
    }

    function requestStakingWithdraw(uint256 _amount) external onlyOwner {
        oracle.requestStakingWithdraw(_amount);
    }

    function submitValue(bytes32 _queryId, bytes memory _value, uint256 _nonce, bytes memory _queryData) onlyOwner external{
        uint256 _reward;
        _reward = autopay.getCurrentTip(_queryId);
        require(_reward > profitThreshold, "profit threshold not met");
        oracle.submitValue(_queryId,_value,_nonce,_queryData);
    }

    function submitValueBypass(bytes32 _queryId, bytes memory _value, uint256 _nonce, bytes memory _queryData) onlyOwner external{
        oracle.submitValue(_queryId,_value,_nonce,_queryData);
    }

    function transfer(address _to, uint256 _amount) external onlyOwner{
        token.transfer(_to,_amount);
    }

    function approve(uint256 _amount) external onlyOwner{
        token.approve(address(oracle), _amount);
    }

    function withdrawStake() onlyOwner external{
        oracle.withdrawStake();
    }

}