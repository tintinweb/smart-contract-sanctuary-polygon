// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./erc20InterFace.sol";

contract TokenAirdrop {
    IERC20 public token; 

   struct whiteAddress {
    address userAddress;
    uint256 amount;

   }

    mapping(address => address) public registedContracts;
    //registed contracts by users address
    mapping(address => mapping(address => whiteAddress[])) public whiteList;
    // mapping with contract addresses to user address my its whitelist

    // events
    event contractRegisted( address indexed _contractAddress,address indexed _address);
     event registedWhiteAddress( address indexed _contractAddress,address indexed _address,uint256 indexed _amount);

    function registerContract(address _contractAddress) public returns (bool) {
        //before the we can charged to user to pay to use this project feature.
        require(registedContracts[_contractAddress] == address(0),"Contract alreday registed.");
        registedContracts[_contractAddress] = msg.sender;
        emit contractRegisted(_contractAddress, msg.sender);
        return true;
    }

    function addToWhiteList(address _contractAddress, address[] memory _addresses, uint256[] memory  _amount) public returns (bool){
        require(registedContracts[_contractAddress] != address(0),"This contract is not registed");
        require(registedContracts[_contractAddress] == msg.sender,"You are un authorized to access this contract");
        for (uint256 i = 0;i < _addresses.length;i++) {
            if (!isWhitelistedByContract(_contractAddress,_addresses[i])) {
                if(_amount[i]>0 && _addresses[i]!=address(0)){
                    whiteList[_contractAddress][msg.sender].push(whiteAddress(_addresses[i],_amount[i]));
                    emit registedWhiteAddress(_contractAddress,_addresses[i],_amount[i]);
                }
            }
        }
        return true;
    }

      function isWhitelistedByContract(address _contractAddress,address _user) public view returns (bool) {
        for (uint i = 0; i < whiteList[_contractAddress][msg.sender].length; i++) {
            if (whiteList[_contractAddress][msg.sender][i].userAddress == _user) {
                return true;
            }
        }
        return false;
     }
      function removeWhiteListedAddress(address _contractAddress,uint256 _index) public returns (bool) {
             delete whiteList[_contractAddress][msg.sender][_index];
             return true;
     }

    function getContractAddressWhiteListItem(address _contractAddress,uint256 _index) public view returns (address userAddress,uint256 amount) {
        return (whiteList[_contractAddress][msg.sender][_index].userAddress,whiteList[_contractAddress][msg.sender][_index].amount);
    }

    function airdropTokens(address _contractAddress) public returns (bool){
        require(registedContracts[_contractAddress] != address(0),"This contract is not registed");
        require(registedContracts[_contractAddress] == msg.sender,"You do not have any access to use airDrop for this contract address");
        require(whiteList[_contractAddress][msg.sender].length > 0,"You did not added any white list user to this contract address");
            token = IERC20(_contractAddress);
        for (uint256 i = 0;i < whiteList[_contractAddress][msg.sender].length;i++) {
            bool status =  token.transferFrom(msg.sender,whiteList[_contractAddress][msg.sender][i].userAddress,whiteList[_contractAddress][msg.sender][i].amount);
            if(status){
             delete whiteList[_contractAddress][msg.sender][i];
            }
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