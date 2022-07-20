/**
 *Submitted for verification at polygonscan.com on 2022-07-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


abstract contract Ownable {
    address public owner; 
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

interface iToken {
    function mintAsController(address to_, uint256 amount_) external;
}

interface iOP {
    function totalSupply() external view returns (uint256);
    function balanceOf(address address_) external view returns (uint256);
    function ownerOf(uint256 tokenId_) external view returns (address);
}

contract SumoYield is Ownable {

    // Interfaces
    iToken public Token = iToken(0xCdb9225CDDC866Ccf9Bb282E769d749f10d6C83c); 
    function setToken(address address_) external onlyOwner { 
        Token = iToken(address_); 
    }

    iOP public OP = iOP(0xbfdAbd3f8082153D73C057d73273f3419679C20e);
    function setOP(address address_) external onlyOwner {
        OP = iOP(address_);
    }

    // Times
    uint256 public yieldStartTime = 1658301300; 
    uint256 public yieldEndTime = 1682863200; 
    function setYieldEndTime(uint256 yieldEndTime_) external onlyOwner { 
        yieldEndTime = yieldEndTime_; }

    // Yield Info
    uint256 public yieldRatePerToken = 5 ether;
    function setYieldRatePerToken(uint256 yieldRatePerToken_) external onlyOwner {
        yieldRatePerToken = yieldRatePerToken_;
    }

    // Yield Database
    mapping(uint256 => uint256) public tokenToLastClaimedTimestamp;

    // Events
    event Claim(address to_, uint256[] tokenIds_, uint256 totalClaimed_);

    // Internal Calculators
    function _getTimeCurrentOrEnded() internal view returns (uint256) {
        return block.timestamp < yieldEndTime ? 
            block.timestamp : yieldEndTime;
    }
    function _getTimestampOfToken(uint256 tokenId_) internal view returns (uint256) {
        return tokenToLastClaimedTimestamp[tokenId_] == 0 ? 
            yieldStartTime : tokenToLastClaimedTimestamp[tokenId_];
    }

    // Yield Accountants
    function getPendingTokens(uint256 tokenId_) public view 
    returns (uint256) {
        uint256 _lastClaimedTimestamp = _getTimestampOfToken(tokenId_);
        uint256 _timeCurrentOrEnded = _getTimeCurrentOrEnded();
        uint256 _timeElapsed = _timeCurrentOrEnded - _lastClaimedTimestamp;
        return (_timeElapsed * yieldRatePerToken) / 1 days;
    }
    function getPendingTokensMany(uint256[] memory tokenIds_) public
    view returns (uint256) {
        uint256 _pendingTokens;
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            _pendingTokens += getPendingTokens(tokenIds_[i]);
        }
        return _pendingTokens;
    }

    // Internal Timekeepers    
    function _updateTimestampOfTokens(uint256[] memory tokenIds_) internal { 
        uint256 _timeCurrentOrEnded = _getTimeCurrentOrEnded();
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            require(tokenToLastClaimedTimestamp[tokenIds_[i]] != _timeCurrentOrEnded,
                "Unable to set timestamp duplication in the same block");

            tokenToLastClaimedTimestamp[tokenIds_[i]] = _timeCurrentOrEnded;
        }
    }

    // Public Claim
    function claim(uint256[] calldata tokenIds_) external {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            require(msg.sender == OP.ownerOf(tokenIds_[i]),
                "You are not the owner!");
        }
        uint256 _pendingTokens = getPendingTokensMany(tokenIds_);
        

        _updateTimestampOfTokens(tokenIds_);
        

        Token.mintAsController(msg.sender, _pendingTokens);

        emit Claim(msg.sender, tokenIds_, _pendingTokens);
    }

    // Public View Functions for Helpers
    function walletOfOwner(address address_) public view returns (uint256[] memory) {
        uint256 _balance = OP.balanceOf(address_);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = OP.totalSupply();
        for (uint256 i = 0; i < _loopThrough; i++) {
            address _ownerOf = OP.ownerOf(i);
            if (_ownerOf == address(0) && _tokens[_balance - 1] == 0) {
                _loopThrough++;
            }
            if (_ownerOf == address_) {
                _tokens[_index++] = i;
            }
        }
        return _tokens;
    }
    function getPendingTokensOfAddress(address address_) public view returns (uint256) {
        uint256[] memory _walletOfAddress = walletOfOwner(address_);
        return getPendingTokensMany(_walletOfAddress);
    }
}