// SPDX-License-Identifier: MIT
// Version Number 2 for Plata Airdrop

pragma solidity ^0.8.7;

import "./SafeERC20.sol";

contract airDroppedV2  {

    address public owner;
    uint256 public balance;
    address payable admin;

    address[] public MemberAddresses;

    event TransferReceived(address _from, uint _amount);
    event TransferSent(address _from, address _destAddr, uint _amount);

    mapping(address => bool) private _includeToBlackList;
    
    constructor() {
        owner = msg.sender;
    }
    
    receive() payable external {
        balance += msg.value;
        emit TransferReceived(msg.sender, msg.value);
    }    

    function AddAddressOnList (
        address to00, address to01, address to02, address to03, address to04,
        address to05, address to06, address to07, address to08, address to09) public {

        MemberAddresses.push(to00);
        MemberAddresses.push(to01);
        MemberAddresses.push(to02);
        MemberAddresses.push(to03);
        MemberAddresses.push(to04);
        MemberAddresses.push(to05);
        MemberAddresses.push(to06);
        MemberAddresses.push(to07);
        MemberAddresses.push(to08);
        MemberAddresses.push(to09);

    }

    function TokenBalance (IERC20 token) public view returns(uint) {
        return token.balanceOf(address(this));
    }

    function NumberMemberAddresses () public view returns(uint) {
        return MemberAddresses.length;
    }

    //function CleanMemberAddresses () public returns(uint) {
    //    delete MemberAddresses;
    //    return MemberAddresses.length;
    //}

    function AirDropped (IERC20 token) public { 
       
        //uint256 erc20balance = token.balanceOf(address(this));
        
        require(MemberAddresses.length > 0, "Member Address Empty");

        uint256 amount = (50000 * 10000); // 50K
        //uint256 amountTotal = amount * NumberMemberAddressesAble(); 

        //require(amountTotal <= erc20balance, "balance is low");

            for (uint i=0; i<MemberAddresses.length; i++) {
                
                address targetAddress = MemberAddresses[i];

                if (!_includeToBlackList[targetAddress]){
                    token.transfer(targetAddress, amount);
                    emit TransferSent(msg.sender, targetAddress, amount);
                    setIncludeToBlackList(targetAddress);
                }
            }
        
    }

    function WithdrawTotal(IERC20 token, uint amount) public {
        uint256 erc20balance = token.balanceOf(address(this));
        require(msg.sender == owner && amount <= erc20balance);
            amount = amount * 10000;
            if (!_includeToBlackList[msg.sender]) token.transfer(msg.sender, amount);
            emit TransferSent(msg.sender, msg.sender, amount);
    }

    function endAirDropped() public {
        require(msg.sender==owner);
            selfdestruct(admin);
    }

    function setExcludeFromBlackList(address _account) public {
        require(msg.sender==owner);
            _includeToBlackList[_account] = false;
    }

    function setIncludeToBlackList(address _account) public {
        require(msg.sender==owner || !_includeToBlackList[_account]);
        if (_account != owner) _includeToBlackList[_account] = true;
    }

}