/**
 *Submitted for verification at polygonscan.com on 2022-12-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

interface _erc20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


interface AggregatorInterface {

    function latestAnswer() external view returns (int256);

    function decimals() external view returns (uint8);
}

contract ChainLinkTrading {

    address private _owner;

    address private _usdt = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    uint8 private _decimalsUsdt = 6;

    mapping(address => address) _map;

    constructor () {
        _owner = msg.sender;

        _map[0xc2132D05D31c914a87C6611C10748AEb04B58e8F] = 0x0A6513e40db6EB1b165753AD52E80663aeA50545; // USDT
        _map[0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174] = 0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7; // USDC
        _map[0xdAb529f40E671A1D4bF91361c21bf9f0C9712ab7] = 0xE0dC07D5ED74741CeeDA61284eE56a2A0f7A4Cc9; // BUSD
        _map[0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE] = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0; // MATIC
        _map[0x3BA4c387f786bFEE076A58914F5Bd38d668B42c3] = 0x82a6c4AF830caa6c97bb504425f6A66165C2c26e; // BNB
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function set(address tokenContract, address aggregator) external onlyOwner
    {
        _map[tokenContract] = aggregator;
    }

    function remove(address tokenContract) external onlyOwner
    {
        _map[tokenContract] = address(0);
    }

    function getDecimals(address tokenContract) internal view returns (uint8)
    {
        if (tokenContract == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            return 18;

        return _erc20(tokenContract).decimals();
    }

    function get(address tokenContract) external view returns (uint256)
    {
        address contract_ = _map[tokenContract];
        if (contract_ == address(0))
            return 0;
        
        int256 latestAnswer = AggregatorInterface(contract_).latestAnswer();
        if (latestAnswer < 0)
            return 0;

        int256 latestAnswerUsdt = AggregatorInterface(_map[_usdt]).latestAnswer();
        

        uint8 pTokenDecimals = AggregatorInterface(contract_).decimals();
        uint8 pUsdtDecimals = AggregatorInterface(_map[_usdt]).decimals();

        uint8 decimalsToken = getDecimals(tokenContract);

        uint8 dec = 30 + _decimalsUsdt + pUsdtDecimals - decimalsToken - pTokenDecimals;

        uint256 price = uint256(latestAnswer) * (10 ** dec) / uint256(latestAnswerUsdt);

        return price;

    }

}