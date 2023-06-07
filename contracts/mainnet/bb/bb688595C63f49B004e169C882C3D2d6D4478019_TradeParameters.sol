/**
 *Submitted for verification at polygonscan.com on 2023-06-07
*/

pragma solidity ^0.8.0;

contract TradeParameters {
    struct UserParameters {
        uint256 topRange;
        uint256 bottomRange;
        uint256 token1TradeAmount;
        uint256 token2TradeAmount;
        address token1Address;
        address token2Address;
        string[] data;
    }

    mapping(address => UserParameters[]) public userParameters;

    modifier onlyOwner(address _walletAddress, uint256 _index) {
        require(msg.sender == _walletAddress, "Only the owner can call this function.");
        require(_index < userParameters[_walletAddress].length, "Invalid index.");
        _;
    }

    function addParameters(
        address _userAddress,
        uint256 _topRange,
        uint256 _bottomRange,
        uint256 _token1TradeAmount,
        uint256 _token2TradeAmount,
        address _token1Address,
        address _token2Address,
        string[] memory _data
    ) public {
        UserParameters memory parameters = UserParameters({
            topRange: _topRange,
            bottomRange: _bottomRange,
            token1TradeAmount: _token1TradeAmount,
            token2TradeAmount: _token2TradeAmount,
            token1Address: _token1Address,
            token2Address: _token2Address,
            data: _data
        });
        userParameters[_userAddress].push(parameters);
    }

    function updateParameters(
        address _userAddress,
        uint256 _index,
        uint256 _topRange,
        uint256 _bottomRange,
        uint256 _token1TradeAmount,
        uint256 _token2TradeAmount,
        address _token1Address,
        address _token2Address,
        string[] memory _data
    ) public onlyOwner(_userAddress, _index) {
        UserParameters storage parameters = userParameters[_userAddress][_index];
        parameters.topRange = _topRange;
        parameters.bottomRange = _bottomRange;
        parameters.token1TradeAmount = _token1TradeAmount;
        parameters.token2TradeAmount = _token2TradeAmount;
        parameters.token1Address = _token1Address;
        parameters.token2Address = _token2Address;
        parameters.data = _data;
    }

    function getParameters(address _userAddress, uint256 _index) public view returns (
        uint256 topRange,
        uint256 bottomRange,
        uint256 token1TradeAmount,
        uint256 token2TradeAmount,
        address token1Address,
        address token2Address,
        string[] memory data
    ) {
        UserParameters storage parameters = userParameters[_userAddress][_index];
        return (
            parameters.topRange,
            parameters.bottomRange,
            parameters.token1TradeAmount,
            parameters.token2TradeAmount,
            parameters.token1Address,
            parameters.token2Address,
            parameters.data
        );
    }

    function getParameterCount(address _userAddress) public view returns (uint256) {
        return userParameters[_userAddress].length;
    }
}