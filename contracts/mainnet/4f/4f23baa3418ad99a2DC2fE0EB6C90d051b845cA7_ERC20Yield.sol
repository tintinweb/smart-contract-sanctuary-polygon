/**
 *Submitted for verification at polygonscan.com on 2022-07-19
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

abstract contract Ownable {
    address public _owner; 
    constructor() { _owner = msg.sender; }
    modifier onlyOwner { require(_owner == msg.sender, "Ownable: caller is not the owner"); 
    _; 
    }
    function transferOwnership(address newOwner) external onlyOwner { _owner = newOwner; 
    }
}

interface iToken {
    function mintAsController(address to_, uint256 amount_) external;
}

interface iClec {
    function numberOfToken() external view returns (uint256);
    function balanceOf(address address_) external view returns (uint256);
    function ownerOf(uint256 tokenId_) external view returns (address);
}

contract ERC20Yield is Ownable {

    // Interfaces
    iToken public Token = iToken(0xCdb9225CDDC866Ccf9Bb282E769d749f10d6C83c);
    iClec public Clec = iClec(0xbfdAbd3f8082153D73C057d73273f3419679C20e);
    uint256 public start = 1658244900;
    uint256 public end = 1814796000;
    uint256 public yieldRatePerToken = 5 ether;
    mapping(uint256 => uint256) public tokenToLastClaimedTimestamp;
    event Claim(address to_, uint256[] tokenIds_, uint256 totalClaimed_);


    //Function//

    function setToken(address address_) external onlyOwner { 
        Token = iToken(address_); 
    }

    function setClec(address address_) external onlyOwner {
        Clec = iClec(address_);
    }

    function setEnd(uint256 end_) external onlyOwner { 
        end = end_; }

    function setYieldRatePerToken(uint256 yieldRatePerToken_) external onlyOwner {
        yieldRatePerToken = yieldRatePerToken_;
    }

    function claim(uint256[] calldata tokenIds_) external {
        // Make sure the sender owns all the tokens
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            require(msg.sender == Clec.ownerOf(tokenIds_[i]),
                "You are not the owner!");
        }

        // Calculate the total Pending Tokens to be claimed
        uint256 _pendingTokens = getPendingTokensMany(tokenIds_);
        
        // Set on all the tokens the new timestamp (which sets pending to 0)
        _updateTimestampOfTokens(tokenIds_);
        
        // Mint the total tokens for the msg.sender
        Token.mintAsController(msg.sender, _pendingTokens);

        // Emit claim of total tokens
        emit Claim(msg.sender, tokenIds_, _pendingTokens);
    }

    function claimToken(address address_) external { //address address_ instead of tokenids of
        uint256[] memory tokenIds_ = walletOfOwner(address_);

        // Make sure the sender owns all the tokens
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            require(msg.sender == Clec.ownerOf(tokenIds_[i]),
                "You are not the owner");
        }

        // Calculate the total Pending Tokens to be claimed
        uint256 _pendingTokens = getPendingTokensMany(tokenIds_);
        
        // Set on all the tokens the new timestamp (which sets pending to 0)
        _updateTimestampOfTokens(tokenIds_);
        
        // Mint the total tokens for the msg.sender
        Token.mintAsController(msg.sender, _pendingTokens);

        // Emit claim of total tokens
        emit Claim(msg.sender, tokenIds_, _pendingTokens);
    }

    //Internal View//

    function _getTimeCurrentOrEnded() internal view returns (uint256) {
        // Return block.timestamp if it's lower than yieldEndTime, otherwise
        // return yieldEndTime instead.
        return block.timestamp < end ?
            block.timestamp : end;
    }
    function _getTimestampOfToken(uint256 tokenId_) internal view returns (uint256) {
        // Here, since we have intrinsic token yield, we need to take that into account.
        // We return the yieldStartTime if SSTORE of tokenToLastClaimedTimestamp is 0
        return tokenToLastClaimedTimestamp[tokenId_] == 0 ? 
            start : tokenToLastClaimedTimestamp[tokenId_];
    }

    // Internal Timekeepers    
    function _updateTimestampOfTokens(uint256[] memory tokenIds_) internal { 
        uint256 _timeCurrentOrEnded = _getTimeCurrentOrEnded();
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            // Prevents duplicate setting of the same token in the same block
            require(tokenToLastClaimedTimestamp[tokenIds_[i]] != _timeCurrentOrEnded,
                "Unable to set timestamp duplication in the same block");

            tokenToLastClaimedTimestamp[tokenIds_[i]] = _timeCurrentOrEnded;
        }
    }

    //Public View//

    // Yield Accountants
    function getPendingTokens(uint256 tokenId_) public view 
    returns (uint256) {
        
        // First, grab the timestamp of the token
        uint256 _lastClaimedTimestamp = _getTimestampOfToken(tokenId_);

        // Then, we grab the timestamp to compare it with
        uint256 _timeCurrentOrEnded = _getTimeCurrentOrEnded();

        // Lastly, we calculate the time-units in seconds of elapsed time 
        uint256 _timeElapsed = _timeCurrentOrEnded - _lastClaimedTimestamp;

        // Now, calculate the pending yield
        return (_timeElapsed * yieldRatePerToken) / 1 days;
    }

    function getPendingTokensMany(uint256[] memory tokenIds_) public view returns (uint256) {
        uint256 _pendingTokens;
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            _pendingTokens += getPendingTokens(tokenIds_[i]);
        }
        return _pendingTokens;
    }

    function walletOfOwner(address address_) public view returns (uint256[] memory) {
        uint256 _balance = Clec.balanceOf(address_);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = Clec.numberOfToken();
        for (uint256 i = 0; i < _loopThrough; i++) {
            address _ownerOf = Clec.ownerOf(i);
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