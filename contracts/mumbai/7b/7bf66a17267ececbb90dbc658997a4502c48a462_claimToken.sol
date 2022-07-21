/**
 *Submitted for verification at polygonscan.com on 2022-07-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
    
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract claimToken is Context, Ownable {
    mapping(uint => bool) _blacklist; // blacklist by user_id

    struct UserClaim {
        bool exists;
        string claimKey; // Check when user_id call claim
        uint totalClaimed;
        uint claimable;
        string[] claimIds;
    }

    struct ClaimRequest {
        uint user_id;
        string claimKey;
        uint amount;
        string claimId;
    }

    mapping(address => mapping(uint256 => UserClaim)) _userClaims; // mapping token => user_id => claim object

    // Events
    event SetUserClaim(address tokenContract, uint user_id, uint amount, string claimId);
    event WithdrawToken(address tokenContract, uint amount);
    event UserClaimed(address tokenContract, uint user_id, uint amount);

    function getAmountToken(address _tokenContract) view public returns (uint) {
        return IERC20(_tokenContract).balanceOf(address(this));
    }

    // Rescue tokens
    function rescueBNB(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "insufficient BNB balance");
        payable(msg.sender).transfer(amount);
    }

    function rescueBEP20Tokens(address _tokenContract) external onlyOwner {
        IERC20(_tokenContract).transfer(msg.sender, IERC20(_tokenContract).balanceOf(address(this)));
    }
    
    function withdrawToken(address _tokenContract, uint _amount) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
        emit WithdrawToken(_tokenContract, _amount);
    }

    //Get and set amount claimable
    function getUserClaim(address _tokenContract, uint256 user_id) view public onlyOwner returns (UserClaim memory) {
        return _userClaims[_tokenContract][user_id];
    }

    function getUserClaimable(address _tokenContract, uint256 user_id) view public returns (uint) {
        if(!_userClaims[_tokenContract][user_id].exists){
            return 0;
        }
        uint tokenBalance = getAmountToken(_tokenContract);
        return _userClaims[_tokenContract][user_id].claimable > tokenBalance ? tokenBalance : _userClaims[_tokenContract][user_id].claimable;
    }

    function getTotalEarn(address _tokenContract, uint256 user_id) view public returns (uint) {
        if(!_userClaims[_tokenContract][user_id].exists){
            return 0;
        }
        uint claimable = getUserClaimable(_tokenContract, user_id);
        return claimable + _userClaims[_tokenContract][user_id].totalClaimed;
    }

    function addClaimable(address _tokenContract, uint user_id, uint amount, string memory claimId, string memory claimKey) public onlyOwner {
        uint tokenBalance = getAmountToken(_tokenContract);
        string[] memory claimIds;
        if(!_userClaims[_tokenContract][user_id].exists){
            UserClaim memory userClaim = UserClaim({
                exists: true,
                totalClaimed:0,
                claimable: 0,
                claimIds: claimIds,
                claimKey: claimKey
            });
            _userClaims[_tokenContract][user_id] = userClaim;
        }
        claimIds = _userClaims[_tokenContract][user_id].claimIds;
        require(_userClaims[_tokenContract][user_id].claimable + amount <= tokenBalance, "insufficient token balance");
        
        // Check duplicate claimID
        bool claimIdDuplicate = false;
        
        for (uint i = 0; i < claimIds.length - 1; i++) {
            //if(claimIds[i] == claimId){
            if(keccak256(bytes(claimIds[i])) == keccak256(bytes(claimId))){
                claimIdDuplicate = true;
                break;
            }
        }

        require(!claimIdDuplicate, "claimId duplicate");

        _userClaims[_tokenContract][user_id].claimKey = claimKey;
        _userClaims[_tokenContract][user_id].claimable = _userClaims[_tokenContract][user_id].claimable + amount;
        _userClaims[_tokenContract][user_id].claimIds.push(claimId);
        emit SetUserClaim(_tokenContract, user_id, amount, claimId);
    }

    function setUserClaimMulti(address _tokenContract, ClaimRequest[] memory claimRequests) public onlyOwner {
        require(claimRequests.length >= 1, "Invalid input data");
        for (uint i = 0; i < claimRequests.length - 1; i++) {
            addClaimable(_tokenContract, claimRequests[i].user_id, claimRequests[i].amount, claimRequests[i].claimId, claimRequests[i].claimKey);
        }
    }
    
    // claim

    function claim(address _tokenContract, uint user_id, string memory claimKey) public {
        require(!isBlacklist(user_id), "Blacklist: Address in blacklist");
        require(_userClaims[_tokenContract][user_id].exists, "User not in list claim");
        uint amount = getUserClaimable(_tokenContract, user_id);
        if(amount > 0){
            UserClaim memory userClaim = _userClaims[_tokenContract][user_id];
            require(keccak256(bytes(userClaim.claimKey)) == keccak256(bytes(claimKey)), "claim key not match!");
            // transfer
            IERC20 tokenContract = IERC20(_tokenContract);
            tokenContract.transfer(msg.sender, amount);
            // update info
            _userClaims[_tokenContract][user_id].claimable = 0;
            _userClaims[_tokenContract][user_id].totalClaimed = _userClaims[_tokenContract][user_id].totalClaimed + amount;
            emit UserClaimed(_tokenContract, user_id, amount);
        }
    }

    //blacklist
    function isBlacklist(uint user_id) view public returns (bool) {
        return _blacklist[user_id];
    }

    function setBlacklist(uint user_id, bool blacklist) public onlyOwner {
        _blacklist[user_id] = blacklist;
    }
}