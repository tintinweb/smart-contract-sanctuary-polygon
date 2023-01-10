/**
 *Submitted for verification at polygonscan.com on 2023-01-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, 'SafeMath: subtraction overflow');
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SafeMath: division by zero');
        uint256 c = a / b;
        return c;
    }
}

interface ERC720 {
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function decimals() external view returns (uint8);
}

contract TokenAirdop {
    using SafeMath for uint256;

    uint256 public _id = 1;
    mapping(uint256 => address) public tokens;
    mapping(uint256 => address) public mangerAddress;
    address public ownerAddress;

    event AirDroped(address _address, address _token, uint256 _amount);


    function changeOwner(address _ownerAddress) public payable { 
        require(msg.sender == ownerAddress, "only owner");
        ownerAddress = _ownerAddress;
    }

    constructor() {
        ownerAddress = msg.sender;
        setTokenForAirdrop(address(0xA0E5c8b2B2e345C72f452880b2c164b944012907));
    }

    function setTokenForAirdrop(address _token) public payable {
        require(msg.sender == ownerAddress, "only owner");
        tokens[_id] = _token;
        mangerAddress[_id] = msg.sender;
        _id = _id.add(1);
    }

    function airdropChange(
        address _address,
        address _token,
        uint256 _airdropId
    ) public payable {
        require(
            msg.sender == mangerAddress[_airdropId],
            'Only manager can do change airdrop'
        );
        tokens[_airdropId] = _token;
        mangerAddress[_airdropId] = _address;
    }

    function airdrop(
        address[] calldata _address,
        uint256[] calldata _tokens,
        uint256 _airdropId
    ) public payable {
        require(
            msg.sender == mangerAddress[_airdropId],
            'Only manager can do airdrop'
        );
        uint256 decimals = ERC720(tokens[_airdropId]).decimals();

        for (uint256 index = 0; index < _address.length; index++) {
            _airdrop(
                _address[index],
                _tokens[index] * 10 ** decimals,
                _airdropId
            );
        }
    }

    function _airdrop(
        address _address,
        uint256 _tokens,
        uint256 _airdropId
    ) internal {
        require(
            _tokens <=
                ERC720(tokens[_airdropId]).allowance(
                    mangerAddress[_airdropId],
                    address(this)
                ),
            'approved balance is not enough'
        );
        ERC720(tokens[_airdropId]).transferFrom(
            mangerAddress[_airdropId],
            _address,
            _tokens
        );
        emit AirDroped(_address, tokens[_airdropId], _tokens);
    }
}