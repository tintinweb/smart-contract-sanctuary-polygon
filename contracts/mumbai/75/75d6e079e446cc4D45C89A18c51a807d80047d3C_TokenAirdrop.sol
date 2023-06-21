// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./erc20InterFace.sol";

contract TokenAirdrop {
    IERC20 public token; 

    mapping(address => address) public registedContracts;
    //registed contracts by users address
    mapping(address => mapping(address => address[])) public whiteList;
    // mapping with contract addresses to user address my its whitelist

    // events
    event contractRegisted( address indexed _contractAddress,address indexed _address);

    function registerContract(address _contractAddress) public returns (bool) {
        //before the we can charged to user to pay to use this project feature.
        registedContracts[_contractAddress] = msg.sender;
        emit contractRegisted(_contractAddress, msg.sender);
        return true;
    }

    function addToWhiteLIst(address _contractAddress, address _address) public returns (bool){
        require(registedContracts[_contractAddress] != address(0),"This contract is not registed");
        require(registedContracts[_contractAddress] == msg.sender,"You are un authorized to access this contract");
        whiteList[_contractAddress][msg.sender].push(_address);
        return true;
    }

    function getContractAddressWhiteListItem(address _contractAddress,uint256 _index) public view returns (address) {
        return whiteList[_contractAddress][msg.sender][_index];
    }

    function airdropTokens(address _contractAddress, uint256 amount) public returns (bool){
        require(registedContracts[_contractAddress] == msg.sender,"You do not have any access to use airDrop for this contract address");
        require(whiteList[_contractAddress][msg.sender].length > 0,"You did not added any white list user to this contract address");
        for (uint256 i = 0;i < whiteList[_contractAddress][msg.sender].length;i++) {
            token = IERC20(_contractAddress);
            token.transferFrom(msg.sender,whiteList[_contractAddress][msg.sender][i],amount);
        }
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success);

    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}