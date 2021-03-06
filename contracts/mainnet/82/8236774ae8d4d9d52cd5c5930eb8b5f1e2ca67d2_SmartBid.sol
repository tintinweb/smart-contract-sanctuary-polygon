/**
 *Submitted for verification at polygonscan.com on 2022-07-13
*/

// SPDX-License-Identifier: MIT
interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function decimals() external view returns (uint8);
}

interface IERC1155 {   
    function uri(uint256 id) external view returns (string memory);
    function setUri(uint256 id) external view returns (string memory);
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {

  function add( uint256 a, uint256 b) internal  pure returns ( uint256 ) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub( uint256 a, uint256 b ) internal pure returns ( uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (
      uint256
    )
  {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

// @dev using 0.8.0.
// Note: If changing this, Safe Math has to be implemented!

pragma solidity 0.8.13;

contract SmartBid is  Ownable{
    using SafeMath for uint256;
    struct biddersInfo {
        address user;
        address tokenAddress;
        uint256 _bidAmount;
        uint256 tokenOwned;
        uint256 timeOut;
    }
    
    struct tokenInfo {
        IERC20 token;
        address[] NFTContractAddress;
        uint256[] URIRequireFromNFTs;
        uint256 multiplier;
    }

    struct CreateBid {
        address highestBidder;
        uint256 timeOut;
        uint256 mustNotExceed;
        uint256 initiialBiddingAmount;
        uint256 totalBidding;
        uint256 highestbid;
        uint256 numberOfRandomAddress;
        uint256 devPercentage;
        uint256 positionOneSharedPercentage;
        uint256 positionTwoSharedPercentage;
        uint256 positionThreeSharedPercentage;
        uint256 randomUserSharedPercentage;
    }
    
    mapping (uint256 => mapping (address => biddersInfo)) public bidders;
    mapping (uint256 => address[]) public projBidders;
    mapping (address => bool) public isAdminAddress;
    
    address public devAddress;
    address[] temporaryOtherLast3Address;
    
    CreateBid[] public request_data_in_Bidding;
    tokenInfo[] private request_token_info;
    
    event bidding(
        address indexed userAddress,
        uint256 pid,
        uint256 stakedAmount,
        uint256 Time
    );

    event luckyWinner(
        address indexed lWinner,
        uint256 pid,
        uint256 amount,
        uint time
    );
    
    event luckyWinnerWithReward(
        address indexed lWinner,
        uint256 pid,
        uint256 amount,
        uint time
    );

    event luckyWinnerWithoutReward(
        address indexed lWinner,
        uint256 pid,
        uint256 amount,
        uint time
    );
    
    event devClaim(
        address indexed sender,
        uint256 pid,
        uint256 amount,
        uint time
    );
    
    event distribute(
        address indexed firstBidder,
        uint256 firtBidderReward,
        address indexed secondBidder,
        uint256 secondBidderReward,
        address indexed thirdBidder,
        uint256 thirdBidderReward,
        uint time
    );
    
    event reset(uint256 pid);
    // percentage should be in this format
    // [ _devPercentage, _positionOneSharedPercentage, _positionTwoSharedPercentage, _positionThreeSharedPercentage, _randomUserSharedPercentage]
    
    constructor(
        IERC20 bidToken,
        address[] memory _NFTContractAddress,
        uint bidTimeOut,
        uint256[] memory _URIRequired,
        uint256 _multiplier,
        uint256 _mustNotExceed,
        uint256 _startBidWith,
        uint256 _numberOfRandomADDRToPick,
        uint256[5] memory percentages
        )
    {
           
        isAdminAddress[_msgSender()] = true;
        address dummyAddress = 0x0000000000000000000000000000000000000000;
        devAddress = _msgSender();
        request_data_in_Bidding.push(CreateBid({
            mustNotExceed : _mustNotExceed,
            highestBidder: dummyAddress,
            timeOut: block.timestamp.add(bidTimeOut),
            initiialBiddingAmount: _startBidWith,
            totalBidding: 0,
            highestbid: 0,
            numberOfRandomAddress : _numberOfRandomADDRToPick,
            devPercentage: (percentages[0] * 10 **  bidToken.decimals()),
            positionOneSharedPercentage: (percentages[1] * 10 **  bidToken.decimals()),
            positionTwoSharedPercentage: (percentages[2] * 10 **  bidToken.decimals()),
            positionThreeSharedPercentage: (percentages[3] * 10 **  bidToken.decimals()),
            randomUserSharedPercentage: (percentages[4] * 10 **  bidToken.decimals())
        }));
        tokenData(bidToken,_NFTContractAddress, _URIRequired, _multiplier);
    }
    
    modifier onlyAdmin() {
        require(isAdminAddress[_msgSender()], "Caller has to have an admin Priviledge");
        _;
    }
    
    function bidLength() external view returns (uint256) {
        return request_data_in_Bidding.length;
    }
    
    function multipleAdmin(address[] calldata _adminAddress, bool status) external onlyOwner {
        if (status == true) {
           for(uint256 i = 0; i < _adminAddress.length; i++) {
            isAdminAddress[_adminAddress[i]] = status;            
            } 
        } else{
            for(uint256 i = 0; i < _adminAddress.length; i++) {
                delete(isAdminAddress[_adminAddress[i]]);
            } 
        }
    }

    function tokenData(
        IERC20 bidToken,
        address[] memory _NFTContractAddress,
        uint256[] memory _URIRequired,
        uint256 _multiplier
        ) internal {
        request_token_info.push(tokenInfo({
            token : bidToken,
            NFTContractAddress : _NFTContractAddress,
            URIRequireFromNFTs : _URIRequired,
            multiplier : _multiplier
        }));
    }
    // percentage should be in this format
    // [ _devPercentage, _positionOneSharedPercentage, _positionTwoSharedPercentage, _positionThreeSharedPercentage, _randomUserSharedPercentage]
    
    function addBid(
        IERC20 bidToken,
        address[] memory _NFTContractAddress,
        uint256 _multiplier,
        uint256[] memory _URIRequired,
        uint256 _mustNotExceed,
        uint256 _startBidWith,
        uint _bidTimeOut,
        uint256 _numberOfRandomADDRToPick,
        uint256[5] memory percentages
        ) external onlyAdmin {            
        uint bidTimeOut = block.timestamp.add(_bidTimeOut);        
        request_data_in_Bidding.push(CreateBid({
            mustNotExceed : _mustNotExceed,
            highestBidder : 0x0000000000000000000000000000000000000000,
            timeOut: bidTimeOut,
            initiialBiddingAmount : _startBidWith,
            totalBidding : 0,
            highestbid : 0,
            numberOfRandomAddress : _numberOfRandomADDRToPick,
            devPercentage: (percentages[0] * 10 **  bidToken.decimals()),
            positionOneSharedPercentage: (percentages[1] * 10 **  bidToken.decimals()),
            positionTwoSharedPercentage: (percentages[2] * 10 **  bidToken.decimals()),
            positionThreeSharedPercentage: (percentages[3] * 10 **  bidToken.decimals()),
            randomUserSharedPercentage: (percentages[4] * 10 **  bidToken.decimals())
        }));
        tokenData(bidToken,_NFTContractAddress, _URIRequired, _multiplier);
    }

    // percentage should be in this format
    // [ _devPercentage, _positionOneSharedPercentage, _positionTwoSharedPercentage, _positionThreeSharedPercentage, _randomUserSharedPercentage]
    function emmergencyEditOfReward(uint256 pid, uint256 newNumberOfRandomness,  uint256[5] memory percentages) external onlyAdmin {
        CreateBid storage bid = request_data_in_Bidding[pid];
        bid.numberOfRandomAddress = newNumberOfRandomness;
        bid.devPercentage = percentages[0];
        bid.positionOneSharedPercentage = percentages[1];
        bid.positionTwoSharedPercentage = percentages[2];
        bid.positionThreeSharedPercentage = percentages[3];
        bid.randomUserSharedPercentage = percentages[4];
    }
    
    function resetBiddingProcess(uint256 pid, uint _bidTimeOut, uint256 _bidAmount, uint256 _mustNotExceed) public onlyAdmin {
        CreateBid storage bid = request_data_in_Bidding[pid];
        require(bid.totalBidding == 0, "Rigel: Distribute Reward First");
        require(block.timestamp > bid.timeOut, "RGP: CANT RESET BIDDING WHY IT STILL IN PROGRESS");        
        delete projBidders[pid];        
        bid.timeOut = _bidTimeOut;
        bid.initiialBiddingAmount = _bidAmount;
        bid.highestBidder = 0x0000000000000000000000000000000000000000;
        bid.mustNotExceed = _mustNotExceed;
        bid.totalBidding = 0;
        bid.highestbid = 0;
        emit reset(pid);
    }
    
    function submitBid(uint256 pid, address tokenContract, uint256 tokenOwned, uint256 amountToBidWith) public{
        CreateBid storage bid = request_data_in_Bidding[pid];
        tokenInfo memory info = request_token_info[pid];
        if (bid.totalBidding == 0) {
            require(amountToBidWith >= bid.initiialBiddingAmount, "BID AMOUNT MUST BE GREATER THAN initial bid amount");
        }        
        if (bid.totalBidding > 0) {
            require(amountToBidWith > bid.highestbid, "BID MUST BE GREATER THAN HIGHEST BID");
            require(amountToBidWith <= (bid.highestbid.add(bid.mustNotExceed)), "BID AMOUNT MUST BE LESS THAN OR EQUAL TO 2RGP");
            require(block.timestamp < bid.timeOut, "RGP: BIDDING TIME ELLAPSE");
        }
        if(tokenContract != address(0)) {
            require(tokenContract == info.NFTContractAddress[0] ||
            tokenContract == info.NFTContractAddress[1] ||
            tokenContract == info.NFTContractAddress[2],
            "Invalid NFT Contract Address given, use 0X index instead");
            require(getUri(pid, tokenContract, tokenOwned), "Token Provided not token require");
            require(IERC1155(tokenContract).balanceOf(_msgSender(), tokenOwned) != 0, "Balance is Zero user 0X index address instead");
        }
        info.token.transferFrom(_msgSender(), address(this), amountToBidWith);
        updatePool(pid, amountToBidWith, tokenContract, tokenOwned);
        projBidders[pid].push(_msgSender());
        emit bidding(_msgSender(), pid, amountToBidWith, block.timestamp);
    }

    function getUri(uint256 pid, address tContract,  uint256 tokenOwned) public view returns(bool WIHave) {
        tokenInfo memory info = request_token_info[pid];
        string memory token = IERC1155(tContract).uri(tokenOwned);
        //  ipfs://QmYvxtbtdo3qAAsCxeEY1Byjm32VfTH6HCec75KqxDxK3k/{id}.json
        string memory tokenSet1;
        uint256 len = info.URIRequireFromNFTs.length;
        uint256 lenAddr = info.NFTContractAddress.length.sub(1);
        uint256 j = 0;
        for(uint256 i; i < len; i++) {
            if(i > lenAddr) {
                tokenSet1 = IERC1155(info.NFTContractAddress[j]).setUri(info.URIRequireFromNFTs[i]);
                WIHave = _internalCheck(token, tokenSet1);
                if (WIHave) {break;}
                j++;
            } else {
                tokenSet1 = IERC1155(info.NFTContractAddress[i]).setUri(info.URIRequireFromNFTs[i]);
                WIHave = _internalCheck(token, tokenSet1);
                if (WIHave) {break;}
            }
        }
    }

    function _internalCheck(string memory token1, string memory token2) internal pure returns(bool status) {
        if (keccak256(abi.encodePacked(token1)) == keccak256(abi.encodePacked(token2))) {
            status = true;
        } else {
            status =false;
        }
    }
    
    function distributeRewardsWithRandomness(uint256 pid) public {
        CreateBid memory bid = request_data_in_Bidding[pid];
        require(bid.totalBidding > 0, "All distribution have been made");
        require(block.timestamp > bid.timeOut, "RGP: BIDDING IS STILL IN PROGRESS");
        (address FirstTBidder, address secondTBidder, address thirdTBidder) = Top3Bidders(pid);
        // (, , , , uint256 devShare, ) = position(pid);
        (,,, uint256 devShare , ,) = position(pid, FirstTBidder, secondTBidder, thirdTBidder);

        require(
            FirstTBidder == _msgSender() ||
            secondTBidder == _msgSender() ||
            thirdTBidder == _msgSender() ||
            devAddress == _msgSender(),
            "Rigel: NOT ELIGIBLE TO CALL"
        );
        (bool status, uint256 rem) = fundTopBidders(pid);
        if (status == true) {
            fundRand(pid, rem);
        }
        delete Have;
        emit devClaim(devAddress, pid, devShare, block.timestamp);
    }

    function DistributeRewardsWithOther3(uint256 pid) public {
        CreateBid storage bid = request_data_in_Bidding[pid];
        require(bid.totalBidding > 0, "All distribution have been made");
        require(block.timestamp > bid.timeOut, "RGP: BIDDING IS STILL IN PROGRESS");
        (address FirstTBidder, address secondTBidder, address thirdTBidder) = Top3Bidders(pid);
        (,,, uint256 devShare , ,) = position(pid, FirstTBidder, secondTBidder, thirdTBidder);
        require(
            FirstTBidder == _msgSender() ||
            secondTBidder == _msgSender() ||
            thirdTBidder == _msgSender() ||
            devAddress == _msgSender(),
            "Rigel: NOT ELIGIBLE TO CALL"
        );
        (bool status, uint256 rem) = fundTopBidders(pid);
        uint256 num = bid.numberOfRandomAddress;
        _fundOthers(pid, status, rem, num);

        delete temporaryOtherLast3Address;
        delete Have;
        emit devClaim(_msgSender(), pid, devShare, block.timestamp);
    }

    address[] Have;
    function _fundOthers(uint256 pid, bool status, uint256 rem, uint256 num) internal {

        tokenInfo memory info = request_token_info[pid];
        if (status) {
            uint256 projLength = projBidders[pid].length;
            for(uint256 i = projLength.sub(3 + 1); i >= projLength.sub(3 + num); i--) {
                temporaryOtherLast3Address.push(projBidders[pid][i]);
            }
            uint256 tempLength = temporaryOtherLast3Address.length;
            address[] memory without = new address[](tempLength);

            for (uint256 x; x < tempLength; x++) {
                biddersInfo memory bidder = bidders[pid][temporaryOtherLast3Address[x]];
                bool iHave = bidder.tokenOwned != 0;
                if (iHave) {
                    Have.push(temporaryOtherLast3Address[x]);
                } else {
                    without[x] = temporaryOtherLast3Address[x];
                }
            }
            uint256 hLength = Have.length;
            uint256 individual = rem.div(tempLength.add(hLength));

            for (uint256 j = 0; j < hLength; j++) {
                address wallet = Have[j];
                info.token.transfer(wallet, (individual.mul(2)));
                emit luckyWinnerWithReward(wallet, pid, rem, block.timestamp);
            }
            for (uint256 z = 0; z < without.length; z++) {
                address wallet = without[z];
                if (wallet != address(0)) {
                    info.token.transfer(wallet, individual);
                    emit luckyWinnerWithReward(wallet, pid, rem, block.timestamp);
                }
            }

        }
    }

    function fundRand(uint256 pid, uint256 remt) internal {
        tokenInfo memory info = request_token_info[pid];
        (address[] memory idHave) = ownedNFTForRand(pid);
        uint256 haveLength = Have.length;
        uint256 l = idHave.length.add(haveLength);

        uint256 individual = remt.div(l);

        if (haveLength > 0 ) {
            for (uint256 i = 0; i < haveLength; i++) {
                address wallet = Have[i];
                info.token.transfer(wallet, individual.mul(2));
                emit luckyWinnerWithReward(wallet, pid, individual.mul(2), block.timestamp);
            }
        }

        if (idHave.length > 0) {
            for (uint256 x = 0; x < idHave.length; x++) {
                if(idHave[x] != address(0)) {
                    address dwallet = idHave[x];
                    info.token.transfer(dwallet, individual);
                    emit luckyWinnerWithoutReward(dwallet, pid, individual, block.timestamp);
                }
            }
        }
    }

    function genExpand(uint256 pid) internal view returns(uint256[] memory expandedValues, address[] memory) {
        CreateBid memory bid = request_data_in_Bidding[pid];
        uint256 proj = projBidders[pid].length;
        expandedValues = new uint256[](bid.numberOfRandomAddress);
        address[] memory _wallet = new address[](bid.numberOfRandomAddress);
        for (uint256 i = 0; i < bid.numberOfRandomAddress; i++) {
            expandedValues[i] = uint256((keccak256(abi.encodePacked(block.difficulty, block.timestamp, proj, i)))).mod(proj.sub(3));
            _wallet[i] = projBidders[pid][expandedValues[i]];
        }
        return  (expandedValues, _wallet);
    }

    function ownedNFTForRand(uint256 pid) internal returns(address[] memory idHave) {
        ( , address[] memory ratedAddress) = genExpand(pid);
        uint256 lent = ratedAddress.length;

        for (uint256 i; i < lent; i++) {
            if(_checkBal(pid, ratedAddress[i]) != 0) {
                Have.push(ratedAddress[i]);
            }
        }

        idHave = new address[](lent.sub(Have.length));
        for (uint256 x; x < lent.sub(Have.length); x++) {
            if(_checkBal(pid, ratedAddress[x]) == 0) {
                idHave[x] = ratedAddress[x];
            }
        }

        return (idHave);
    }
    
    function position(
        uint256 pid,
        address FirstTBidder,
        address secondTBidder,
        address thirdTBidder
    ) public
        view
        returns
        (uint256 nPOne, uint256 nPTwo,  uint256 nPThree, uint256 _devShare, uint256 RandUser, uint256 divforRandUser) {
        CreateBid memory bid = request_data_in_Bidding[pid];
        tokenInfo memory info = request_token_info[pid];
        uint256 total = bid.totalBidding;
        uint256 inDecimals = (100 * 10 ** info.token.decimals());
        uint256 share = info.multiplier.mul(10 ** (info.token.decimals() - 2));
        _devShare = total.mul(bid.devPercentage).div(inDecimals);

        if( _checkBal(pid, FirstTBidder) != 0) {
            nPOne = (total.sub(_devShare)).mul(bid.positionOneSharedPercentage).div(inDecimals).add(
                (total.sub(_devShare)).mul(share).div(inDecimals)
            );
            total = (total.sub(_devShare)).sub(nPOne);
        } else {
            nPOne = total.mul(bid.positionOneSharedPercentage).div(inDecimals);
            total = (total.sub(_devShare)).sub(nPOne);
        }
        if(_checkBal(pid, secondTBidder) != 0) {
            nPTwo = total.mul(bid.positionTwoSharedPercentage).div(inDecimals).add(
                (total).mul(share).div(inDecimals)
            );
            total = (total).sub(nPTwo);
        } else {
            nPTwo = total.mul(bid.positionTwoSharedPercentage).div(inDecimals);
            total = total.sub(nPTwo);
        }
        if( _checkBal(pid, thirdTBidder) != 0) {
            nPThree = total.mul(bid.positionThreeSharedPercentage).div(inDecimals).add(
                (total).mul(share).div(inDecimals)
            );
            total = (total).sub(nPThree);
        } else {
            nPThree = total.mul(bid.positionThreeSharedPercentage).div(inDecimals);
            total = total.sub(nPThree);
        }

        RandUser = total;
        divforRandUser = (total.mul(bid.randomUserSharedPercentage).div(inDecimals));
    }

    function _checkBal(uint256 pid, address user) internal view returns (uint256 bal) {
        return bidders[pid][user].tokenOwned;
    }
    
    function fundTopBidders(uint256 pid) internal returns (bool, uint256 rem) {
        CreateBid storage bid = request_data_in_Bidding[pid];
        tokenInfo memory info = request_token_info[pid];
        (address FirstTBidder, address secondTBidder, address thirdTBidder) = Top3Bidders(pid);
        (uint256 nPOne, uint256 nPTwo,  uint256 nPThree, uint256 devShare , ,) = position(pid, FirstTBidder, secondTBidder, thirdTBidder);
        uint256 gtRem;
        if ((nPOne + nPTwo + nPThree + devShare) < bid.totalBidding) {
            gtRem = bid.totalBidding - (nPOne + nPTwo + nPThree + devShare);
            bid.totalBidding = bid.totalBidding.sub(gtRem + (nPOne + nPTwo + nPThree + devShare));
            info.token.transfer(FirstTBidder, nPOne);
            info.token.transfer(secondTBidder, nPTwo);
            info.token.transfer(thirdTBidder, nPThree);
            info.token.transfer(devAddress, devShare);
            emit distribute(FirstTBidder, nPOne, secondTBidder, nPTwo, thirdTBidder, nPThree, block.timestamp);
            return (true, gtRem);
        } else{
            return (false, (nPOne + nPTwo + nPThree + devShare));
        }
    }

    function requestToken(uint256 id) external view returns (address _token, address[] memory nftCont, uint256[] memory nftReq, uint256 _multiplier) {
        tokenInfo memory info = request_token_info[id];
        _token = address(info.token);
        nftCont = info.NFTContractAddress;
        nftReq = info.URIRequireFromNFTs;
        _multiplier = info.multiplier;
    }
        
    function updatePool(uint256 _pid, uint256 _quantity, address tokenContract, uint256 _tokenOwn) internal  {
        CreateBid storage bid = request_data_in_Bidding[_pid];
        biddersInfo storage bidder = bidders[_pid][_msgSender()];
        bid.highestbid = _quantity;
        bid.highestBidder = _msgSender();
        bid.totalBidding = bid.totalBidding.add(_quantity);        
        bidder._bidAmount = _quantity;
        bidder.tokenOwned = _tokenOwn;
        bidder.tokenAddress = tokenContract;
        bidder.timeOut = block.timestamp;
        bidder.user = _msgSender();
    }

    function Top3Bidders(uint256 pid) public view returns(address FirstTBidder, address secondTBidder, address thirdTBidder) {
        address user1 = projBidders[pid][projBidders[pid].length.sub(1)];
        address user2 = projBidders[pid][projBidders[pid].length.sub(2)];
        address user3 = projBidders[pid][projBidders[pid].length.sub(3)];
        return (user1, user2, user3);
    }
    
    function projID(uint256 _pid) public view returns(uint256) {
        return projBidders[_pid].length;
    }
    
    function getTopBid(uint256 _pid) public view returns (address, uint256, uint) {
        CreateBid storage bid = request_data_in_Bidding[_pid];
        return (bid.highestBidder, bid.highestbid, bid.timeOut);
    }
    
    function withdrawTokenFromContract(address tokenAddress, uint256 _amount, address _receiver) external onlyOwner {
        IERC20(tokenAddress).transfer(_receiver, _amount);
    }

    function setDev( address _devAddress) external onlyOwner () {
       devAddress = _devAddress;
    }
 
}