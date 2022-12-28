/**
 *Submitted for verification at polygonscan.com on 2022-12-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

interface ERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract HoldingTokensSattlement {
    address public _cubixCoin;
    address public _admin;
    mapping(address => uint256) public _holdingTokensSattlement;

    event HoldingTokensSattlementDone(
        address indexed _address,
        uint256 _amount,
        uint256 _time
    );

    constructor(address _cubixCoinAddress) {
        _admin = msg.sender;
        _cubixCoin = _cubixCoinAddress;
    }

    modifier onlyOwner() {
        require(_admin == msg.sender, 'Ownable: caller is not the owner');
        _;
    }

    function setTokens(address[] calldata _address, uint256[] calldata _tokens)
        public
        onlyOwner
    {
        for (uint256 index = 0; index < _address.length; index++) {
            _holdingTokensSattlement[_address[index]] = _tokens[index];
        }
    }

    function claim() public virtual returns (bool) {
        require(_holdingTokensSattlement[msg.sender] > 0, 'Not found tokens');

        uint256 tokens = _holdingTokensSattlement[msg.sender];
        ERC20(_cubixCoin).transfer(msg.sender, tokens * 10**18);

        _holdingTokensSattlement[msg.sender] = 0;

        emit HoldingTokensSattlementDone(msg.sender, tokens, block.timestamp);

        return true;
    }

    function updateCubixCoinAddress(address newAddress)
        public
        virtual
        onlyOwner
    {
        require(newAddress != address(0), 'Error: address cannot be zero');
        _cubixCoin = newAddress;
    }

    function regainUnusedCubix(uint256 amount) public virtual onlyOwner {
        ERC20(_cubixCoin).transfer(_admin, amount);
    }

    function addTokensForGivenAddress(address[] calldata _address, uint256[] calldata amount)
        public
        virtual
        onlyOwner
    {
        for (uint256 index = 0; index < _address.length; index++) {
            _holdingTokensSattlement[_address[index]] = amount[index];        
        }
    }
}