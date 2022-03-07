pragma solidity ^0.5.0;

import "./Owner.sol";
import "./OracleInterface.sol";
import "./SafeMath.sol";

/**
 * @title Oracle
 * @dev accept query & send response data
 */
contract Oracle is OracleInterface, Owner{
    using SafeMath for uint;
    
    uint public MIN_FEE = 1000 szabo; // 调用服务最低费用
    uint public CALLBACK_GAS = 30000000; // 回调Gas
    
    // 查询事件，oracle后端服务会订阅该事件
    event QueryInfo(bytes32 queryId, address requester, uint fee, address callbackAddr, string callbackFUN, bytes queryData);

    /**
     * @dev 设置服务调用最低费用
     */
    function setRequestFee(uint minFee) public isOwner {
        MIN_FEE = minFee;
    }

    /**
     * @dev 提取合约内的以太币
     */
    function withdraw(address payable _account) public payable isOwner {
        require(address(this).balance > 10 szabo, "Insufficient balance!");
        _account.transfer(address(this).balance);
    }

    /**
     * @dev 接收客户端请求
     * @param queryId 请求id，回调时原值返回
     * @param callbackAddr 回调的合约地址
     * @param callbackFUN 回调合约的方法及参数，如getResponse(bytes32,uint64,uint256/bytes)，
     *        其中getResponse表示回调方法名，可自定义；
     *        bytes32类型参数指请求id，回调时会原值返回；
     *        uint64类型参数表示oracle服务状态码，1表示成功，0表示失败；
     *        第三个参数表示Oracle服务回调支持uint256/bytes两种类型的参数
     * @param queryData 请求数据，json格式，如{"url":"https://ethgasstation.info/api/ethgasAPI.json","responseParams":["fast"]}
     * @return bool true请求成功，false请求失败
     */
    function query(bytes32 queryId, address callbackAddr, string calldata callbackFUN, bytes calldata queryData) external payable returns(bool) {
        require(msg.value >= MIN_FEE, "Insufficient handling fee!");
        require(bytes(callbackFUN).length > 0, "Invalid callbackFUN!");
        require(queryData.length > 0, "Invalid queryData!");
        // 记录日志
        emit QueryInfo(queryId, msg.sender, msg.value, callbackAddr, callbackFUN, queryData);
        return true;
    }

    /**
     * @dev 将查询得到的结果（bytes类型）发送给客户端
     * @param queryId 查询请求id
     * @param callbackAddr 回调的合约地址
     * @param callbackFUN 回调合约的方法及参数
     * @param stateCode 查询结果状态码，1表示查询成功，0表示失败
     * @param respData 查询结果
     * @return bool true请求成功，false请求失败
     */
    function responseBytes(bytes32 queryId, address callbackAddr, string calldata callbackFUN, uint64 stateCode, bytes calldata respData) payable external isOwner returns(bool) {
        require(address(this).balance > CALLBACK_GAS, "Insufficient balance!");
        (bool success,) = callbackAddr.call.gas(CALLBACK_GAS)(abi.encodeWithSignature(callbackFUN, queryId, stateCode, respData));
        require(success,"call back failed!");
    }
    
    /**
     * @dev 将查询得到的结果（uint256类型）发送给客户端
     */
    function responseUint256(bytes32 queryId, address callbackAddr, string calldata callbackFUN, uint64 stateCode, uint256 respData) payable external isOwner returns(bool) {
        require(address(this).balance > CALLBACK_GAS, "Insufficient balance!");
        (bool success,) = callbackAddr.call.gas(CALLBACK_GAS)(abi.encodeWithSignature(callbackFUN, queryId, stateCode, respData));
        require(success);
    }
}