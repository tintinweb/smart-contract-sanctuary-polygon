// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./FxBaseChildTunnel.sol";


contract MyTokenContract is ERC20, Ownable, FxBaseChildTunnel {

    //Store user staking info, user tokens balance earned, last updated info
    mapping(address => uint256[]) userStakeInfo;
    mapping(address => uint256) public userBalance;
    mapping(address => uint256) public lastUpdated;

    uint256 public constant dailyReward = 5 ether;

    constructor(address _fxChild) FxBaseChildTunnel(_fxChild) ERC20("My Token Name", "MYTN"){
        _mint(address(this), 100 ether);
    }

    modifier updateBalance(address _address, uint256 _timestamp) {
        //Update user balance each time they process staking or unstaking (not claiming)

        //Store the user earned balance before reset with new time
        userBalance[_address] += earned(_address); 

        //update the new time
        lastUpdated[_address] = _timestamp; 
        _;       
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }


    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory data) internal override validateSender(sender){ 
        (address from, uint256[] memory tokenIds, uint256 timestamp, bool action) = abi.decode(data, (address,uint256[],uint256, bool));

        action? processStake(from, tokenIds, timestamp): processUnstake(from, tokenIds, timestamp);

    }


    function getUserStakedTokens(address _address) public view returns(uint256[] memory){
        return userStakeInfo[_address];
    }


    function getTotalBalance(address _address) public view returns(uint256) {
        //Display total balance claimed (in wallet) and earned in the contract
        return balanceOf(_address) + userBalance[_address] + earned(_address);

        
    }

    function processStake(address _address, uint256[] memory _tokenIds, uint256 _timestamp) private updateBalance(_address, _timestamp) {
        userStakeInfo[_address] = _tokenIds;

        //Increase the multipler or benefits

    }

    function processUnstake(address _address, uint256[] memory _tokenIds, uint256 _timestamp) private updateBalance(_address, _timestamp) {
        userStakeInfo[_address] = _tokenIds;
        if(userStakeInfo[_address].length == 0) {
            //Automatically claim all tokens for them
            claimTokenForUser(_address);
        }

        //Decrease the multipler or benefits
    }

    function earned(address _address) public view returns(uint256){
        return (dailyReward/86400) * (block.timestamp - lastUpdated[_address]);
    }

    function claimTokenForUser(address _address) private {
        lastUpdated[_address] = block.timestamp;
        _transfer(address(this), _address, userBalance[_address]);
        userBalance[_address] = 0;
    }

    function claimToken() public callerIsUser{ 
        lastUpdated[msg.sender] = block.timestamp;
        _transfer(address(this), msg.sender, userBalance[msg.sender]);
        userBalance[msg.sender] = 0;
    }

    function airdrop(address[] memory _addresses, uint256[] memory _amounts) public onlyOwner {
        require(_addresses.length == _amounts.length, "Number of addresses and token amounts is not equal");
        for (uint256 counter = 0; counter < _addresses.length; counter ++) {
            userBalance[_addresses[counter]] += _amounts[counter];
        }
    }

    function withdrawTokens(address _to, uint256 _amount) public onlyOwner {
        _transfer(address(this), _to, _amount);
    }
    
    
}